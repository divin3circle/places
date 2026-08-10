// generate-itinerary — Supabase Edge Function
//
// Proxies OpenAI so the API key stays server-side (set as the `OPENAI_API_KEY`
// secret; never shipped in the app). The app POSTs structured inputs; this builds
// the prompt + a strict JSON schema (with placeName grounded to the allowed names),
// calls OpenAI once (non-streaming), and returns a GeneratedItinerary JSON that
// matches the app's Swift Codable shape.
//
// Deploy:  supabase functions deploy generate-itinerary
// Secret:  supabase secrets set OPENAI_API_KEY=sk-...
// Invoke:  requires the project's anon key in the `apikey` + `Authorization` headers.

const OPENAI_URL = "https://api.openai.com/v1/chat/completions";
const MODEL = "gpt-4o-mini";

const ACTIVITY_KINDS = [
  "wildlife", "sightseeing", "foodAndDining", "lodging",
  "transport", "culture", "shopping", "relaxation",
];

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface ReqConfig {
  travelers: number;
  hasKids: boolean;
  durationDays: number;
  durationLabel: string;
  multipleCountries: boolean;
  expectation: string;
}
interface ReqBody {
  mode: "generate" | "refine";
  config: ReqConfig;
  placeNames: string[];
  instruction?: string | null;
  current?: unknown | null;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

function itinerarySchema(placeNames: string[]) {
  return {
    type: "object",
    additionalProperties: false,
    properties: {
      title: { type: "string" },
      summary: { type: "string" },
      rationale: { type: "string" },
      days: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          properties: {
            title: { type: "string" },
            subtitle: { type: "string" },
            activities: {
              type: "array",
              items: {
                type: "object",
                additionalProperties: false,
                properties: {
                  kind: { type: "string", enum: ACTIVITY_KINDS },
                  title: { type: "string" },
                  description: { type: "string" },
                  // Hard grounding: only real, mappable places.
                  placeName: { type: "string", enum: placeNames },
                },
                required: ["kind", "title", "description", "placeName"],
              },
            },
          },
          required: ["title", "subtitle", "activities"],
        },
      },
    },
    required: ["title", "summary", "rationale", "days"],
  };
}

function systemPrompt(c: ReqConfig): string {
  const lines = [
    "You are a warm, expert East-Africa travel concierge for the Places app.",
    "Design a practical, exciting day-by-day itinerary.",
    "Use ONLY the provided place names for each activity's placeName.",
    "",
    "Trip details:",
    `- Travelers: ${c.travelers}`,
    `- Traveling with kids: ${c.hasKids ? "yes" : "no"}`,
    `- Duration: ${c.durationLabel} (${c.durationDays} days)`,
    c.multipleCountries
      ? "- Scope: may span multiple East-African countries"
      : "- Scope: keep to a single country",
  ];
  if (c.expectation.trim().length > 0) {
    lines.push(`- Traveler's wish: "${c.expectation}"`);
  }
  return lines.join("\n");
}

function userPrompt(body: ReqBody): string {
  const names = body.placeNames.join(", ");
  if (body.mode === "refine") {
    return [
      "Here is the current itinerary to revise (JSON):",
      JSON.stringify(body.current),
      "",
      `Apply this change: ${body.instruction ?? ""}.`,
      "Return the COMPLETE updated itinerary (every day) in the required format.",
      `Use ONLY these exact place names for placeName: ${names}`,
    ].join("\n");
  }
  return [
    `Create a ${body.config.durationDays}-day itinerary now, based on the trip details.`,
    `Produce exactly ${body.config.durationDays} day(s), each with 2–4 activities.`,
    `Use ONLY these exact place names for placeName: ${names}`,
  ].join("\n");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) return json({ error: "Server misconfigured: missing OPENAI_API_KEY" }, 500);

  let body: ReqBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }
  if (!body?.config || !Array.isArray(body?.placeNames) || body.placeNames.length === 0) {
    return json({ error: "Missing config or placeNames" }, 400);
  }

  const openaiBody = {
    model: MODEL,
    messages: [
      { role: "system", content: systemPrompt(body.config) },
      { role: "user", content: userPrompt(body) },
    ],
    response_format: {
      type: "json_schema",
      json_schema: {
        name: "itinerary",
        strict: true,
        schema: itinerarySchema(body.placeNames),
      },
    },
  };

  let res: Response;
  try {
    res = await fetch(OPENAI_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(openaiBody),
    });
  } catch (e) {
    return json({ error: `Upstream request failed: ${e}` }, 502);
  }

  if (!res.ok) {
    const text = await res.text();
    return json({ error: `OpenAI error ${res.status}: ${text}` }, 502);
  }

  const data = await res.json();
  const content = data?.choices?.[0]?.message?.content;
  if (typeof content !== "string") {
    return json({ error: "OpenAI returned no content" }, 502);
  }

  let itinerary: unknown;
  try {
    itinerary = JSON.parse(content);
  } catch {
    return json({ error: "OpenAI returned malformed JSON" }, 502);
  }

  // Shape matches the app's GeneratedItinerary Codable — return it directly.
  return json(itinerary, 200);
});
