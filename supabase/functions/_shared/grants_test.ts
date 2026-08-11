import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { grantForProduct, planForProduct } from "./grants.ts";

Deno.test("weekly grants 50", () => {
  assertEquals(grantForProduct("piea_149_1w"), { amount: 50, reason: "grant_weekly" });
});
Deno.test("annual grants 6000", () => {
  assertEquals(grantForProduct("piea_999_1y"), { amount: 6000, reason: "grant_annual" });
});
Deno.test("token pack grants its size", () => {
  assertEquals(grantForProduct("token_449_200"), { amount: 200, reason: "grant_topup" });
});
Deno.test("lifetime grants 1000", () => {
  assertEquals(grantForProduct("piea_pro_lifetime"), { amount: 1000, reason: "grant_lifetime" });
});
Deno.test("unknown product → null", () => {
  assertEquals(grantForProduct("nope"), null);
});
Deno.test("subscription products map to pro plan", () => {
  assertEquals(planForProduct("piea_249_1m"), "pro");
  assertEquals(planForProduct("tokens_99_25"), null);
});
