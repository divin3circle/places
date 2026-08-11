// trip-intel — Supabase Edge Function
//
// A trip-context "tool" the app plugs into itinerary generation: given a
// destination (+ optional month) it returns structured local context — weather,
// getting around, money, price level, best time. STATIC for now; the contract is
// what matters, so we can swap in real dynamic sources (weather API, FX, etc.)
// later without touching the app.
//
// Deploy:  supabase functions deploy trip-intel
// Invoke:  requires the project's anon key in `apikey` + `Authorization` headers.

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

interface Intel {
  weatherSummary: string;
  gettingAround: string;
  currencyTips: string;
  priceLevel: string; // budget | moderate | premium
  bestTime: string;
}

const DEFAULT: Intel = {
  weatherSummary:
    "Warm days with cool mornings and evenings; short rains Nov–Dec and long rains Mar–May.",
  gettingAround:
    "Domestic flights link major parks; matatus and ride-hailing (Bolt/Uber) cover cities; safaris use a 4x4 with a driver-guide.",
  currencyTips:
    "Cards work in cities and lodges; carry some cash and use M-Pesa for small payments. USD is widely quoted for tourism.",
  priceLevel: "moderate",
  bestTime:
    "Jun–Oct (dry, peak wildlife) and Dec–Feb; the long rains (Mar–May) are quieter and greener.",
};

const REGIONS: Record<string, Partial<Intel>> = {
  kenya: {
    bestTime:
      "Jul–Oct for the Great Migration in the Maasai Mara; Dec–Feb is also excellent.",
  },
  tanzania: {
    bestTime:
      "Jun–Oct dry season; Jan–Feb for calving in the southern Serengeti.",
  },
  uganda: {
    weatherSummary:
      "Green and humid; two drier windows (Jun–Aug, Dec–Feb) are best for gorilla trekking.",
  },
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  let body: { destination?: string; month?: string } = {};
  try {
    body = await req.json();
  } catch {
    // Tolerate an empty body — return the default region.
  }

  const destination = String(body?.destination ?? "East Africa");
  const key = destination.toLowerCase();
  const region = Object.keys(REGIONS).find((k) => key.includes(k));
  const intel: Intel = { ...DEFAULT, ...(region ? REGIONS[region] : {}) };

  return json({ destination, month: body?.month ?? null, ...intel });
});
