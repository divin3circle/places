const TOKEN_PACKS: Record<string, number> = {
  tokens_25: 25, tokens_75: 75, tokens_200: 200, tokens_500: 500,
};
const SUB_GRANTS: Record<string, { amount: number; reason: string }> = {
  pro_weekly: { amount: 50, reason: "grant_weekly" },
  pro_monthly: { amount: 500, reason: "grant_monthly" },
  pro_annual: { amount: 6000, reason: "grant_annual" },
  pro_lifetime: { amount: 1000, reason: "grant_lifetime" },
};

export function grantForProduct(productId: string):
  { amount: number; reason: string } | null {
  if (productId in SUB_GRANTS) return SUB_GRANTS[productId];
  if (productId in TOKEN_PACKS) {
    return { amount: TOKEN_PACKS[productId], reason: "grant_topup" };
  }
  return null;
}

/** Subscriptions + lifetime unlock the `pro` plan; token packs don't. */
export function planForProduct(productId: string): string | null {
  return productId in SUB_GRANTS ? "pro" : null;
}
