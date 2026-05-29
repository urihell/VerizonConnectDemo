# Verizon Connect Demo — Action Items

> **Source:** 05-29 Verizon Connect Dry Run (Plaud, 1h29m)
> **Next regroup:** Thursday **2026-06-04** (Fridays jammed) + async sidebars
> **Demo target:** week of 2026-06-01
> **Owner of this list:** Uriel · **Org:** `verizon-connect-bj550e`
> Companion docs: `VDD_DEMO_TALK_TRACK.md` · `VDD_DEMO_HANDOFF.md`

Legend: 🔴 high (emphasized in dry run) · 🟡 medium · 🟢 nice-to-have · ⏳ blocked/needs sync

---

## A. My beats — build/talk-track changes (owned)

- [ ] 🔴 **Make onboarding multi-device, not 1:1.** Reflect a ~10-device order; click into one device as the example. Avoid the "installed 50, showing 1" trap. *(Tiffany)* — talk track now narrates this (Beat 2 note) + message reads "your devices"; **still TODO: the org data / build so the screen actually shows a multi-device order.**
- [x] ✅ **Reword the post-install outbound message to be generic/plural** — done. `VDD_SendOnboardingMessage` now leads with *"your Verizon Connect fleet devices have been installed and are reporting in"* (deployed + talk track Beat 2). *(explicit ask)*
- [x] ✅ **Offer a clear next step in that message: book training / access a training page** — done. Message now points to *"book a training session or visit your training page at connect.verizon.com/fleet/training"* (deployed). *(explicit ask)* — note: the destination page itself is item below.
- [ ] 🔴 **Reconcile the device count.** Current track says **33 units** — dry run is moving to **~7 vehicles / 9 assets** for cohesion with Chris's Revenue Cloud org. Pick the number, update talk track + data. ⏳ *needs Chris sync (item C1)*
- [ ] 🔴 **Fix the failure mode in Beat 3.** Real Reveal/BT-400 runs on **vehicle power (OBD-II), not its own battery.** Decouple the sim from "device battery" → use signal loss / power-feed fault / no-ping instead. Hardware-savvy audience will fixate if wrong. *(Steven)* ⏳ *confirm mode with Steven/Kurt (item C3)* — talk track language is already neutralized + flagged (Beat 3 note); **still TODO: change the actual build (`VDD_SimulateBatteryFailure` / diagnosis) once the mode is confirmed.**
- [x] ✅ **Rework the battery/device-issue customer outreach message (Beat 3)** — done. `VDD_CreateReplacementCase` now reassures *"our team is already on it"* AND offers next actions: *reply YES to confirm replacement / CALL for a specialist / ask a question* (deployed + talk track Beat 3). Replaced the old dead-end *"no action needed from you."* *(explicit ask)* — agent-side handling of the YES/CALL reply is not built yet (talk-track-only for now).
- [ ] 🔴 **Build the training destination the CTA points to** (a training page / booking action). Drives adoption/stickiness ("nobody knows how to use it"); make it feel distinct from install coordination. *(Tiffany + explicit ask)*
- [x] ✅ **Add the revenue-recognition talk track at install** — done (talk track Beat 2 transition): install-confirmed = billing-on; today revenue leaks when devices ship but sit uninstalled. *(Tiffany)*
- [x] ✅ **Add the VIN-rollup aside** — done (talk track Beat 2 presenter note): asset → vehicle → VIN rolls up to Revenue Cloud; keep quoting-VIN separate from serial-to-VIN mapping. *(team / your offer)*
- [x] ✅ **Add the vehicle-identity call-out** — done (talk track Beat 3 presenter note): vehicle name to customer, serial to diagnostician, VIN as the key. *(Fred + Steven)*
- [x] ✅ **Drop the outbound-voice idea** from the battery→RMA bridge (not available yet) — keep text only. *(scratched live in dry run)*
- [ ] 🟢 **Keep the "3 install time-preferences → ~70% land first time" framing** — it landed well. *(no change, just retain)*

## B. My open question to resolve
- [ ] 🔴 **Decide how many Agentforce use cases I show** (all vs. one or two). Raised in dry run, **never answered.** Bring a recommendation to 6/04.

## C. Coordination / sync items (I drive or co-own)
- [ ] 🔴 **C1 — Sync with Chris offline** on asset/line-item details so both orgs are cohesive (~7 vehicles / 9 assets, hardware+software lines).
- [ ] 🟡 **C2 — Headless tie-in with Steven.** My shipping-tracker LWC (esp. history view) is the candidate to voice as a "headless / API-behind-every-click" example; Steven may build a **live LWC shipping tracker** at the front and allude to it during my logistics beat. Coordinate so they connect.
- [ ] 🔴 **C3 — Reconcile battery-vs-vehicle-power** narrative with Kurt + Steven so my Beat 3 failure and Kurt's BT-400 RMA troubleshooting are consistent.
- [ ] 🟡 **C4 — Slack placement (still being ideated).** My idea: Chatter/Slack post on the record when the failure fires. Bring an option to 6/04.

## D. Team-level items to track (not mine, but affect my flow)
- [ ] 🟡 Rename opportunity → **"Reveal for BlackRock Paving"** (no "Agentforce" in the name). *(Chris)*
- [ ] 🟡 Relabel "inventory management" → **"order and asset management."** *(Chris)*
- [ ] 🟡 Quote line items = **hardware + software bundle** (one-time + recurring rolled up). *(Chris)*
- [ ] 🔴 **VIN handling approach** — Chris researches best practice (Samsara, Ford clean rooms, template/portal upload, guided selling via year/make/model); Kathleen then decides voiceover vs. in-flow. *(Chris → Kathleen)*
- [ ] 🟡 RMA realism: tweak BT-400 troubleshooting (multimeter/continuity; soften the "haul another 12V battery" step). *(Kurt)*
- [ ] 🟡 Add **RMA insights → Tableau Next → Slack PM question → OEM recall** close (voiceover / light build, **no new screen**). *(Kurt/Steven)*
- [ ] 🟡 Agentforce differentiators (architecture, **observability, guardrails**) on **Slide 25** — counter "you're just an LLM/Anthropic." *(Linda)*
- [ ] 🟢 Decide **VIBES placement** (lean front-end) — must-include, client already uses it. *(Steven)*
- [ ] 🟢 Decide **MuleSoft** inclusion + placement. *(Kathleen/Tiffany)*
- [ ] 🟢 Consider weaving in **promotion-stacking** pain lightly (out-of-RFP differentiator, CSG flagged 2–3x). *(team)*

---

## Pre-demo dry-run checklist (operational)
- [ ] Run `VDD_ResetDemo.runReset()` (Anonymous Apex) before each run.
- [ ] Confirm Shipment **SP-0002 = In Transit**, VDD-400 = **Shipped**, Semi Truck = **Purchased**.
- [ ] End stale MessagingSessions for Jim Stone on the **974** channel.
- [ ] Confirm **VDD Fleet Service Agent — V2 Active**.
- [ ] Have Salesforce-side SMS records ready to show (physical text may not dispatch).
