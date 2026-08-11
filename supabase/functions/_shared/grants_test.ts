import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { grantForProduct, planForProduct } from "./grants.ts";

Deno.test("weekly grants 50", () => {
  assertEquals(grantForProduct("pro_weekly"), { amount: 50, reason: "grant_weekly" });
});
Deno.test("annual grants 6000", () => {
  assertEquals(grantForProduct("pro_annual"), { amount: 6000, reason: "grant_annual" });
});
Deno.test("token pack grants its size", () => {
  assertEquals(grantForProduct("tokens_200"), { amount: 200, reason: "grant_topup" });
});
Deno.test("lifetime grants 1000", () => {
  assertEquals(grantForProduct("pro_lifetime"), { amount: 1000, reason: "grant_lifetime" });
});
Deno.test("unknown product → null", () => {
  assertEquals(grantForProduct("nope"), null);
});
Deno.test("subscription products map to pro plan", () => {
  assertEquals(planForProduct("pro_monthly"), "pro");
  assertEquals(planForProduct("tokens_25"), null);
});
