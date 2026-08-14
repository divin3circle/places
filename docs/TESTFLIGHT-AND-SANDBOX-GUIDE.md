# TestFlight, Sandbox Payments & Free Trial — "Places in East Africa"

How to get friends testing the app (including buying tokens/Pro **for free**, no real money) and how to confirm the 3-day free trial in App Store Connect.

---

## Part 1 — The key idea: TestFlight purchases are automatically FREE (sandbox)

Any build installed through **TestFlight** runs its in-app purchases against Apple's **sandbox**, not production. That means:

- Testers use their **own normal Apple ID** — **no sandbox account needed on their end** (the `+sandbox` accounts we made earlier were only for Xcode/device dev builds, **not** TestFlight).
- They see a real purchase sheet that says **"[Environment: Sandbox]"** and are **never charged real money**.
- The purchase still fires our RevenueCat webhook → **tokens/Pro get credited** just like production. So the full flow is testable end-to-end.

> ⚠️ **Expected sandbox quirk:** subscriptions **auto-renew very fast** in sandbox/TestFlight (weekly ≈ every 3 min, annual ≈ every hour) and stop after a few cycles. So a tester who buys weekly Pro will see Pro renew repeatedly and their **token balance climb quickly** — that's normal sandbox behavior and does **not** happen in production. Testers can cancel the sub in **Settings → Apple Account → Subscriptions** (or the TestFlight app) to stop the renewals.

---

## Part 2 — Add testers in App Store Connect

First: make sure a build has been uploaded and finished **Processing** (TestFlight tab shows it).

### A. Internal testers (fastest — no review, up to 100)
1. Anyone you add here must first be a member of your team: **Users and Access** → **+** → invite them with a role (e.g. **App Manager** or **Developer**), or use existing members.
2. **TestFlight** tab → **Internal Testing** → **+** next to a group (or "App Store Connect Users") → select the people → they get an email invite.
3. They install the **TestFlight** app from the App Store, accept, and install your build. **Available immediately** — no Apple review.

*Use this for yourself + close friends you can add as team members.*

### B. External testers (up to 10,000 — needs a quick Beta App Review)
1. **TestFlight** tab → **External Testing** → **+** → create a group (e.g. "Friends").
2. Add the build to the group.
3. Fill the required **Test Information**: beta app description, feedback email (`sylusabel1@gmail.com`), and (if it asks) what to test.
4. Add testers two ways:
   - **By email:** enter each friend's email → they get an invite.
   - **Public link:** toggle **Enable Public Link** → share the URL with anyone; they self-enroll (cap the number if you want).
5. Submit the group for **Beta App Review** (lighter than full App Store review; usually approved in a few hours to a day). After approval, invites go out and friends can install.

*Use this for friends who aren't on your team.*

### What to tell your testers
> Install the **TestFlight** app → open my invite → install **Places in East Africa**. Sign in with your Apple ID. To try buying tokens or Pro, tap through the purchase — it'll say **Sandbox** and **won't charge you**. You may see the subscription "renew" a lot; that's normal test behavior.

Ask them to test: **Sign in with Apple → generate an itinerary (spends tokens) → buy a token pack (balance rises) → buy Pro (badge + unlocks) → Restore Purchases → try the weekly plan's 3-day free trial.**

---

## Part 3 — Confirm the 3-day free trial on the Weekly subscription (in ASC)

The trial is created **once, in App Store Connect** on the weekly product. RevenueCat + the app already read it automatically (the paywall shows "Start 3-day free trial" when it's live and the user is eligible).

### Steps
1. Your app → left sidebar under **MONETIZATION** → **Subscriptions**.
2. Open the subscription group **`places_pro`** → open the **Weekly** subscription (`piea_149_1w`).
3. Make sure it already has a **base price** set and a localized display name (required before an offer).
4. Find the **Subscription Prices** area → **Introductory Offers** → **Create Introductory Offer** (the **+**).
5. Configure:
   - **Countries or Regions:** All (or your launch markets)
   - **Start Date:** today (or your launch date) · **End Date:** None (ongoing)
   - **Offer Type:** **Free**
   - **Duration:** **3 Days**
   - **Eligibility:** **New Subscribers** (intro offers apply only to users who haven't subscribed before)
6. **Save.**

### How to verify it's working
- **In the app / TestFlight:** open the paywall → the **Weekly** row shows a green **"3-day free trial"** and the CTA becomes **"Start 3-day free trial."** (If it doesn't show, the offer isn't active yet or the tester previously used a trial.)
- **In sandbox/TestFlight:** starting the weekly plan begins the free trial, then sandbox-accelerates into renewals — all free.

### Notes
- **RevenueCat: no change needed** — it reads the StoreKit intro offer automatically.
- The offer + subscription must be **submitted with your app** (first submission reviews them together). In the version page's **In-App Purchases** section, make sure all products are selected to submit.
- Only **new** subscribers see the trial; someone who already subscribed (even in sandbox) may not — test with a fresh Apple ID if you want to see it.

---

## Quick checklist
- [ ] Build uploaded + processed
- [ ] Internal testers added (instant) — for you + close friends
- [ ] External group + Beta App Review submitted — for other friends
- [ ] Told testers: purchases are free (Sandbox), rapid renewals are normal
- [ ] Weekly `piea_149_1w` → **Free · 3 Days · New Subscribers** intro offer created
- [ ] All IAPs/subscriptions selected to submit with the version
