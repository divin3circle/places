import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { grantForProduct, planForProduct } from "../_shared/grants.ts";

// RevenueCat sends the app_user_id (we set it to the Supabase user id) and the
// product identifier. Auth: a shared secret in the Authorization header,
// configured in the RevenueCat webhook UI and stored as REVENUECAT_WEBHOOK_AUTH.
Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  if ((req.headers.get("Authorization") ?? "") !== Deno.env.get("REVENUECAT_WEBHOOK_AUTH")) {
    return new Response("Unauthorized", { status: 401 });
  }

  const payload = await req.json().catch(() => null);
  const event = payload?.event;
  if (!event) return new Response("No event", { status: 400 });

  const userId: string | undefined = event.app_user_id;
  const productId: string | undefined = event.product_id;
  const type: string = event.type ?? "";
  if (!userId) return new Response("No app_user_id", { status: 400 });

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const GRANTING = ["INITIAL_PURCHASE", "RENEWAL", "NON_RENEWING_PURCHASE"];
  const REVOKING = ["CANCELLATION", "EXPIRATION", "SUBSCRIPTION_PAUSED"];

  if (GRANTING.includes(type) && productId) {
    const grant = grantForProduct(productId);
    if (grant) {
      // Lifetime is granted per calendar month; use the period as ref so the
      // monthly cron (Task 6) won't double-grant the purchase month.
      const ref = grant.reason === "grant_lifetime"
        ? new Date().toISOString().slice(0, 7) // YYYY-MM
        : (event.transaction_id ?? null);
      await admin.rpc("grant_tokens", {
        p_user: userId, p_amount: grant.amount, p_reason: grant.reason, p_ref: ref,
      });
    }
    const plan = planForProduct(productId);
    if (plan) {
      await admin.from("profiles").update({
        plan, plan_product: productId, rc_customer_id: userId,
        pro_expires_at: event.expiration_at_ms
          ? new Date(event.expiration_at_ms).toISOString() : null,
      }).eq("id", userId);
    }
  } else if (REVOKING.includes(type)) {
    // Keep purchased tokens; drop pro access. (Lifetime does not expire.)
    if (productId !== "piea_pro_lifetime") {
      await admin.from("profiles").update({ plan: "free", plan_product: null })
        .eq("id", userId);
    }
  }
  // REFUND/chargeback clawback of unspent grant is handled in a follow-up;
  // RevenueCat sends CANCELLATION for refunds which already revokes access.

  return new Response("ok", { status: 200 });
});
