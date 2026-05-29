# VDD Fleet Service — 10-Minute Demo Talk Track

> **Audience:** Verizon Connect (fleet telematics prospect evaluating Salesforce Field Service + Agentforce)
> **Slot:** ~10 minutes, immediately following the Revenue Cloud segment
> **Persona on screen:** Black Rock Paving — a VC fleet customer (Jim Stone, owner, Old Bridge NJ) with **33 VDD-400 GPS units** going into heavy equipment
> **Org:** `verizon-connect-bj550e` · **SMS channel:** 974 (+1-201-908-6974)
> **Source of truth:** `VerizonConnectDemo/VDD_DEMO_HANDOFF.md` (master branch)

---

## How to use this doc

Each beat has three lanes:
- **🗣 SAY** — the spoken track (say it close to verbatim; it's timed)
- **🖱 DO** — the click / action you take
- **👀 SHOW** — what the audience should be looking at while you talk

Timing markers are cumulative. Total budget: **10:00**. Phase 3 is the hero — protect its time.

> **⚠️ Pre-flight (do this BEFORE the meeting, not on stage):**
> 1. Run `VDD_ResetDemo.runReset()` via Anonymous Apex.
> 2. Confirm: Shipment **SP-0002 = In Transit**, VDD-400 Tracker = **Shipped**, Semi Truck = **Purchased**.
> 3. End any stale MessagingSession for Jim Stone on the **974** channel (zombie sessions block SMS).
> 4. Confirm agent **VDD Fleet Service Agent — Version 2 = Active** in Agentforce Studio.
> 5. SMS may not physically dispatch in a demo org — plan to **show the Salesforce records**, not a phone.

---

## Beat 0 — Frame & Revenue Cloud Handoff · `0:00 – 1:00`

**🗣 SAY:**
> "So we just watched the *commercial* side — Black Rock Paving signed for 33 VDD-400 units and the subscriptions that ride on them, all quoted and closed in Revenue Cloud. But for Verizon Connect, the deal isn't won when the order closes — it's won when all 33 devices are **installed, live, and reporting**, and it stays won as long as they keep reporting.
>
> That gap — from *order* to *healthy installed asset* to *the day a device starts to fail* — is exactly where the RFP was thin: no real work-order layer, a light scheduling story, and nothing on proactive device health. So that's what I want to show you. One platform, one agent, carrying those same 33 devices the rest of the way. Let me start on Black Rock Paving's account."

**🖱 DO:** Land on the **Black Rock Paving** Account record (or the VDD-400 Shipment list — your call).

**👀 SHOW:** The account/relationship — devices, the open shipment. Sets "this is a real customer with real hardware in motion."

> *Presenter note: This explicitly picks up the baton from Revenue Cloud and names the RFP gaps you're about to close. Don't linger — momentum into Phase 1.*

---

## Beat 1 — Delivery Coordination · `1:00 – 4:00`

**The point:** The hardware physically arrives, and an **Agentforce agent** — not a CSR, not a queue — coordinates the install over SMS and stands up the work order. This is the work-order + scheduling layer the RFP was missing.

**🗣 SAY:**
> "The shipment of 33 units just landed at Black Rock's yard. Watch what one click sets in motion."

**🖱 DO:** Open **Shipments → SP-0002** → click **"Confirm Shipment Delivery"** → click through the screen flow.

**🗣 SAY (while it runs):**
> "Behind that button, Field Service just did the unglamorous-but-critical work: five product transfers received, the device assets cascaded from *Shipped* to *Delivered*, the shipment closed out, and the product request marked received. No spreadsheet, no swivel-chair between systems."

**👀 SHOW:** The success toast: *"5 product transfers received, 5 assets updated to Delivered."*

**🗣 SAY:**
> "And the moment that shipment flipped to *Delivered*, a flow fired an SMS straight to Jim, the fleet owner."

**🖱 DO:** Navigate to **Messaging Sessions** (or Jim Stone's activity) to show the outbound SMS record.

**👀 SHOW:** The outbound message:
> *"Hi Jim, your VDD-400 GPS Tracking Unit + 4 accessories have been delivered to Black Rock Paving. Reply with 3 preferred install dates/times…"*

> *Presenter note: Acknowledge it out loud — "in production this lands on Jim's phone; here I'll show you the Salesforce side."*

**🗣 SAY:**
> "Now Jim replies the way a busy contractor actually texts —" *(read it as you trigger it)* — **"June 2 morning, June 4 afternoon, June 5 morning."** "No portal, no app download. And here's the part that matters for you:"

**🖱 DO:** Trigger / show Jim's inbound reply → the **VDD Fleet Service Agent** picks it up on the 974 channel.

**🗣 SAY:**
> "The agent doesn't just log a note. It reads those three windows, and because no work order exists yet, it **creates one** — with a work order line for each vehicle pulled from the shipment's asset hierarchy — records all three preferences, schedules a service appointment to the first slot, and texts Jim back a confirmation with his WO number. The agent owns the work-order lifecycle end to end."

**🖱 DO / 👀 SHOW (rapid, ~30s):**
- **Work Order** → the WOLIs (one per vehicle) + the three preferred dates
- **Service Appointment** → scheduled to the first window
- **Chatter / Task** → the logged activity trail

**🗣 SAY (transition):**
> "Order to scheduled install — no human dispatcher touched it. That's gap one closed. Now let's get a device live."

---

## Beat 2 — Post-Install Onboarding · `4:00 – 6:00`

**The point:** The install is done; the agent **verifies the device is actually healthy** and onboards the customer. Telemetry, not assumptions.

**🗣 SAY:**
> "The installer's on site, device wired into the truck. They mark it complete —"

**🖱 DO:** Open **Assets → VDD-400 GPS Tracking Unit** → click **"Complete Installation."**

**🗣 SAY (while it runs):**
> "— and that one action sets the asset to *Installed* and writes the device's first real telemetry baseline: GPS accuracy, cellular signal, battery voltage, ESN, last ping. It also stands up a live threshold monitor on the battery. Remember that monitor — it matters in a minute."

**👀 SHOW:** Refresh the Asset → status **Installed** → the **Asset Attributes** related list (GPS 2.5m, signal -68 dBm, battery 12.6V).

**🗣 SAY:**
> "Now the onboarding agent takes over automatically. It confirms the install, reads every telemetry attribute, and checks each one against threshold — GPS under 5 meters, signal above -85, battery above 11.8 volts. All green. It returns **'All Systems Go'** and sends Jim a welcome with his fleet dashboard link."

**🖱 DO / 👀 SHOW:** The **Activity timeline** → onboarding task with the telemetry summary.

**🗣 SAY (transition):**
> "So you've confirmed — with data, not a checkbox — that this device is earning its subscription on day one. But the real test of a fleet platform isn't day one. It's day ninety, when a battery starts to go."

---

## Beat 3 — Proactive Health Monitoring · `6:00 – 9:00` · 🎯 HERO BEAT

**The point:** The differentiated moment. The device starts failing, and the agent **opens a case and notifies the customer before the customer notices** — protecting uptime, the subscription, and the relationship. This is the proactive-maintenance story the RFP had *nothing* on.

**🗣 SAY:**
> "Fast-forward a few weeks. That battery starts to drift. In most telematics shops, here's what happens: nothing — until Jim calls in angry because a truck went dark on a job site. Watch what happens here instead."

**🖱 DO:** On the same **VDD-400** asset → click **"Simulate Battery Failure."**

**🗣 SAY (while it runs):**
> "I'm simulating the battery dropping to 11.4 volts — just under threshold. That trips the monitor we created at install. No human is watching this dashboard. The agent is."

**👀 SHOW:** Pause for a beat — let the breach fire and the agent run.

**🗣 SAY:**
> "The health-monitor agent wakes up on the breach. Step one: it identifies *what* tripped and *whose* device — Jim Stone, the semi truck. Step two: it pulls the full telemetry picture and diagnoses it — 0.4 volts under threshold, severity **Warning**, recommendation: preventive battery replacement within two weeks. Step three —" *(let this land)* — "it opens a service case and texts Jim that you're **already on it**."

**🖱 DO / 👀 SHOW:**
- The newly created **Case** → diagnosis, severity, recommended action
- The **Chatter feed / customer notification** → the proactive outreach

**🗣 SAY (the money line — slow down):**
> "Verizon Connect detected the failure, diagnosed it, and reached out to the customer — **before Jim ever knew there was a problem.** No truck went dark. No angry call. No churned subscription. That's the difference between selling a tracking device and being the partner that keeps a fleet running. And every step you just watched was the agent — your team's capacity goes to the exceptions, not the routine."

---

## Beat 4 — Recap & Tie-Off · `9:00 – 10:00`

**🗣 SAY:**
> "So in ten minutes we carried those 33 devices the whole way — and we closed the three gaps your RFP flagged:
> - **The work-order layer** — the agent created and scheduled the install, no dispatcher required.
> - **The scheduling story** — over SMS, in the customer's own words.
> - **Proactive device health** — a failing battery became a case before it became a complaint.
>
> One platform — Field Service for the assets and the work, Agentforce for the intelligence, all on the customer record you already saw in Revenue Cloud. Same data, order through end-of-life. That's the device lifecycle Verizon Connect runs on Salesforce. Where would you want to go deeper — the scheduling and dispatch side, or the proactive health engine?"

**👀 SHOW:** Back on the **Black Rock Paving Account** — devices, the work order, the case all hanging off one record.

> *Presenter note: End on a question that hands them the next-step choice. It turns the demo into a discovery conversation and surfaces which arc to expand in the follow-up.*

---

## One-Glance Run Sheet

| Time | Beat | Click | Land the line |
|------|------|-------|---------------|
| 0:00 | Frame | Account / Shipment list | "Deal's won when 33 devices report — and stay reporting." |
| 1:00 | Delivery | SP-0002 → **Confirm Shipment Delivery** | Agent creates the WO + schedules install over SMS |
| 4:00 | Onboarding | VDD-400 → **Complete Installation** | Telemetry verified — "All Systems Go," not a checkbox |
| 6:00 | **Health** 🎯 | VDD-400 → **Simulate Battery Failure** | "We knew before Jim did." Case opened proactively |
| 9:00 | Recap | Black Rock Paving Account | Closed all 3 RFP gaps on one platform |

## If you're running long (cut order)
1. Trim Beat 2 detail — show telemetry attributes, skip the threshold-by-threshold read.
2. Compress Beat 1's "after" tour to just the Work Order (drop SA + Chatter).
3. Never cut Beat 3. It's the reason you're in the room.

## Landmines (from the handoff)
- **Reset first**, every time. A dirty org breaks Beat 1 silently.
- **Stale 974 sessions** for Jim block the SMS — clear them pre-flight.
- **Work Orders are NOT created at Confirm Delivery** — the *agent* creates them on Jim's reply. By design; don't go hunting for a WO too early.
- SMS records live in Salesforce; **don't promise a physical text** will arrive.
