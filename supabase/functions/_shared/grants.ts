const TOKEN_PACKS: Record<string, number> = {
  tokens_99_25: 25, token_199_75: 75, token_449_200: 200, token_999_500: 500,
};
const SUB_GRANTS: Record<string, { amount: number; reason: string }> = {
  piea_149_1w: { amount: 50, reason: "grant_weekly" },
  piea_249_1m: { amount: 500, reason: "grant_monthly" },
  piea_999_1y: { amount: 6000, reason: "grant_annual" },
  piea_pro_lifetime: { amount: 1000, reason: "grant_lifetime" },
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
