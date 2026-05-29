# Verizon Connect — 10-Minute Logistics Demo Plan

**Source call:** Plaud — *05-18 Verizon Connect Meeting: Demo Day Planning, Field Service, and Asset Management* (32m 03s)
**Date of call:** 2026-05-18 13:00
**Demo target:** Week of June 1, 2026 (RFP submissions due Fri May 22; demos start Mon May 25)
**Format:** Remote
**Slot owned by Uriel:** 10-minute "Logistics" section, runs after RevCloud (pricing/products → order created → asset created)

---

## Where the logistics block sits in the broader story
- RevCloud handles deal close, pricing, asset creation, order, and inventory amendments to the sales view.
- Logistics block picks up immediately after RevCloud "stops" — i.e., asset has been created and the install needs to happen.
- Bridge moment: a **product request** / **product transfer** is generated from the closed deal so equipment can move from warehouse → van or warehouse → site.

---

## Customer pain points being addressed
- Terrible end-to-end asset management and visibility today.
- They don't know how many assets a customer has, how many are live, or the IMEI until the device hits the biller.
- Needs to look seamless across RevCloud → Field Service → installed/connected asset.

---

## Recommended 10-minute storyline (proposed by Uriel, validated on the call)

1. **Pick up from RevCloud handoff** — deal closed, asset created, inventory amended.
2. **Product Transfer** kicks off automatically (deal close → product transfer to van or site).
3. **Asset lifecycle visibility** — show the asset record with current status/location as it moves.
4. **Carrier integration trigger** — when shipment status flips to *Delivered*, automation fires.
5. **Autonomous Scheduling Agent (Agentforce)** texts the customer to schedule install.
   - Show the inbound SMS on Uriel's phone.
   - Quick back-and-forth → "Got it. Scheduled."
6. **Fast-forward** past mobile app / Gantt (no time to show them).
7. **Land on the installed asset record** — connected, showing health metrics, end-to-end visibility achieved.
8. **Optional stretch:** quick Agentforce capability moment if time allows.

> Decision: do **not** show the work order or the Gantt — saves time and keeps focus on asset visibility, which is the real pain point.

---

## Field Service capabilities to lean on (out of the box)
- **Service Appointments + Gantt** — dispatch and schedule installs (won't show Gantt, but underpins the demo).
- **Product Item, Product Transfer, Product Request** — warehouse, trucks, sites, serialized inventory, transfers between locations.
- **Shipment object** — placeholder out of the box; needs integration to be useful.
- **Asset record** — the hero object for visibility and lifecycle.
- **Early Permitted Start + Due Date** on Service Appointments — drives auto-scheduling against shipment ETA.
- **Record-triggered Flow** — pushes Early Start / Due Date when a carrier ETA changes (e.g., storm delay).

---

## Integration angle (mention briefly, do not deep-dive)
- Out of the box, the Shipment object is unlinked — needs carrier integration.
- Two viable paths to call out:
  - **Zenkraft** (now owned by Bring) — aggregates carrier APIs (UPS, FedEx, etc.) into Salesforce; supports label printing, rate shopping, tracking, and append-to-record. Good standalone option.
  - **MuleSoft** — API-based polling against carrier endpoints; Speaker 2 wants to confirm with Steve which path Verizon Connect prefers.
- Punchline: tracking ID flows in → status changes to *Delivered* → automation triggers scheduling. No installer shows up before the box arrives.

---

## Agentic moment (the big "wow")
- When shipment delivers, **Autonomous Scheduling Agent** texts the customer.
- Customer picks a slot conversationally; agent confirms.
- This is the agentic capability Speaker 2 specifically called out as "real" and worth showing in 10 minutes.
- Reschedule path (storm / late carrier) also a candidate if time permits — agent re-offers slots.

---

## Bullets to send Speaker 2 for review (per their ask)
- [ ] Start point: RevCloud has closed the deal and amended inventory; asset created.
- [ ] Show product transfer auto-generated (warehouse → van OR warehouse → site).
- [ ] Show asset lifecycle status update as it moves through transfer.
- [ ] Show shipment record + carrier integration concept (Zenkraft or MuleSoft).
- [ ] Trigger: shipment status = *Delivered* fires autonomous scheduling agent.
- [ ] Show inbound SMS to customer + agentic scheduling exchange.
- [ ] Skip mobile app + Gantt for time.
- [ ] Land on installed asset record — connected, health metrics visible.
- [ ] Optional: quick Agentforce capability flex if time allows.

---

## Open items / decisions needed
- [ ] **Speaker 2** to confirm whether Verizon Connect installs are performed by **third-party** vendors vs. in-house technicians.
- [ ] **Speaker 2** to confirm shipping model — **shipped** to site vs. **picked up** at depot (likely a mix; bulk may be third-party).
- [ ] **Steve** to weigh in on **MuleSoft vs. Zenkraft** for carrier integration in the demo.
- [ ] **Org choice**: build in the shared **RevCloud org** or in **Uriel's own SDO**?
  - Uriel's preference: own SDO (cleaner, RevCloud + Field Service historically conflicted under CPQ; unsure of current state since RevCloud is now part of core).
  - Will attempt RevCloud org if feasible.
- [ ] If demoing in separate orgs, use **consistent asset naming** so the story still feels seamless.
- [ ] Confirm whether Verizon Connect demo is a single-shot screening or a first round before a deeper demo (Speaker 2's read: likely a first round but they're skipping the usual qualification step, so make it count).

---

## Notes on timing pressure
- Less than two weeks of working time; this week is short for some, next week is short due to Memorial Day.
- Tiffany still working dry-run date.
- Demo dry-runs need to happen before the week of June 1.
