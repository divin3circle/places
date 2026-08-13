import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { costForAction } from "./cost.ts";

Deno.test("cloud generation costs 8", () => {
  assertEquals(costForAction("generate", "cloud"), 8);
});
Deno.test("cloud iteration costs 5", () => {
  assertEquals(costForAction("refine", "cloud"), 5);
});
Deno.test("local generation costs 2", () => {
  assertEquals(costForAction("generate", "local"), 2);
});
Deno.test("local iteration costs 1", () => {
  assertEquals(costForAction("refine", "local"), 1);
});
