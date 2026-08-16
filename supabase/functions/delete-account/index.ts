// delete-account — Supabase Edge Function
//
// Permanently deletes the signed-in user's account and data. Backs the in-app
// "Delete Account" flow required by App Store Guideline 5.1.1(v). Authenticates
// with the caller's JWT (never trusts a client-supplied user id), then uses the
// service role to remove the avatar files, the profile row, and the auth user.
// token_balances / token_ledger have ON DELETE CASCADE on auth.users(id), so they
// clear automatically when the user is deleted.
//
// Deploy:  supabase functions deploy delete-account
// Invoke:  POST with the user's access token in `Authorization` and the anon key
//          in `apikey`. No body required.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Identify the caller from their JWT — the only user we're allowed to delete.
  const authHeader = req.headers.get("Authorization") ?? "";
  const { data: userData, error: userErr } = await admin.auth.getUser(
    authHeader.replace("Bearer ", ""),
  );
  if (userErr || !userData?.user) return json({ error: "Unauthorized" }, 401);
  const userId = userData.user.id;

  // 1) Best-effort: remove the user's avatar files (avatars/<uid>/*.jpg).
  try {
    const { data: files } = await admin.storage.from("avatars").list(userId);
    if (files && files.length) {
      await admin.storage
        .from("avatars")
        .remove(files.map((f) => `${userId}/${f.name}`));
    }
  } catch (_) {
    // Non-fatal: proceed with account deletion even if storage cleanup fails.
  }

  // 2) Best-effort: delete the profile row explicitly (in case the FK lacks
  //    ON DELETE CASCADE). token_balances / token_ledger cascade on step 3.
  await admin.from("profiles").delete().eq("id", userId);

  // 3) Delete the auth user itself — this is the account deletion, and cascades
  //    any remaining ON DELETE CASCADE rows.
  const { error: delErr } = await admin.auth.admin.deleteUser(userId);
  if (delErr) return json({ error: `Delete failed: ${delErr.message}` }, 500);

  return json({ ok: true });
});
