export type Mode = "generate" | "refine";
export type Backend = "cloud" | "local";

/** Token cost for an AI action. Cloud is the paid path; local is near-free. */
export function costForAction(mode: Mode, backend: Backend): number {
  if (backend === "local") return mode === "generate" ? 2 : 1;
  return mode === "generate" ? 8 : 5;
}
