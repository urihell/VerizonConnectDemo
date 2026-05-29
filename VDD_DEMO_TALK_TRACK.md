# VDD Fleet Service — 10-Minute Demo Talk Track

> **Audience:** Verizon Connect — fleet operations & service leadership
> **Slot:** ~10 minutes, immediately following the Revenue Cloud segment
> **Persona on screen:** Black Rock Paving — a VC fleet customer (Jim Stone, owner, Old Bridge NJ) with **33 VDD-400 GPS units** going into heavy equipment
> **Org:** `verizon-connect-bj550e` · **SMS channel:** 974 (+1-201-908-6974)
> **Source of truth:** `VDD_DEMO_HANDOFF.md`

---

## The story this demo tells

Three value pillars, each landed by a live action — and each one quantifiable:

| Pillar | The moment | The value |
|--------|-----------|-----------|
| **Zero-touch dispatch** | Delivery → scheduled install with no dispatcher | Capacity redeployed; humans handle exceptions, not routine |
| **Scheduling on the customer's terms** | Customer books over SMS, in plain words | Faster time-to-live = faster time-to-revenue on the subscription |
| **Service that moves first** | A failing device opens its own case | Uptime protected = truck rolls avoided, churn avoided |

Underneath all three: **one platform, one customer record** — the same record you just saw in Revenue Cloud, carried from order to end-of-life. That continuity is the implicit win; the three pillars are the explicit ones.

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
> "We just watched the *commercial* side — Black Rock Paving signed for 33 VDD-400 units and the subscriptions riding on them, all quoted and closed in Revenue Cloud. But for a fleet business, the deal isn't really won when the order closes. It's won when all 33 devices are **installed, live, and reporting** — and it stays won every month they keep reporting.
>
> Everything in between — getting devices in the ground and keeping them healthy — is where service either protects that revenue or quietly erodes it. So let me show you that stretch, on one platform, on the *same* customer record you just saw. Three moments do the heavy lifting: getting devices installed **without a dispatcher in the middle**, scheduling **on the customer's terms**, and catching a failing device **before the customer ever feels it**."

**🖱 DO:** Land on the **Black Rock Paving** Account record (or the VDD-400 Shipment list).

**👀 SHOW:** The account — devices, the open shipment. "Real customer, real hardware in motion, one record."

> *Presenter note: This picks up the baton from Revenue Cloud and plants the three value pillars as outcomes, not problems. Don't linger — momentum into Phase 1.*

---

## Beat 1 — Delivery Coordination · `1:00 – 4:00`  ·  Pillar: **Zero-touch dispatch**

**The point:** Hardware physically arrives, and an **Agentforce agent** — not a CSR, not a dispatch queue — coordinates the install and stands up the work order itself. The work-order-and-scheduling layer most telematics shops bolt on by hand is simply *built in here*.

**🗣 SAY:**
> "The shipment of units just landed at Black Rock's yard. Watch what one click sets in motion."

**🖱 DO:** Open **Shipments → SP-0002** → click **"Confirm Shipment Delivery"** → click through the screen flow.

**🗣 SAY (while it runs):**
> "Behind that button, Field Service just did the unglamorous-but-critical work: five product transfers received, the device assets cascaded from *Shipped* to *Delivered*, the shipment closed out, the product request marked received. No spreadsheet, no swivel-chair between systems — the inventory and asset records reconcile themselves."

**👀 SHOW:** The success toast: *"5 product transfers received, 5 assets updated to Delivered."*

**🗣 SAY:**
> "And the moment that shipment flipped to *Delivered*, the platform reached out to the customer on its own."

**🖱 DO:** Navigate to **Messaging Sessions** (or Jim Stone's activity) to show the outbound SMS record.

**👀 SHOW:** The outbound message:
> *"Hi Jim, your VDD-400 GPS Tracking Unit + 4 accessories have been delivered to Black Rock Paving. Reply with 3 preferred install dates/times…"*

> *Presenter note: Acknowledge it — "in production this lands on Jim's phone; here I'll show you the Salesforce side."*

**🗣 SAY:**
> "Now Jim replies the way a busy contractor actually communicates —" *(read it as you trigger it)* — **"June 2 morning, June 4 afternoon, June 5 morning."** "No portal, no app to download, no callback queue. Text, in his own words. And here's the part that matters for your operation:"

**🖱 DO:** Trigger / show Jim's inbound reply → the **VDD Fleet Service Agent** picks it up on the 974 channel.

**🗣 SAY:**
> "The agent doesn't just log a note. It reads those three windows, and because no work order exists yet, it **creates one** — with a line for each vehicle pulled from the shipment's asset hierarchy — records all three preferences, schedules a service appointment to the first slot for the installer, and texts Jim back his work-order number. The agent owns that whole lifecycle."

**🖱 DO / 👀 SHOW (rapid, ~30s):**
- **Work Order** → the lines (one per vehicle) + the three preferred dates
- **Service Appointment** → scheduled to the first window, routed to the field installer
- **Chatter / Task** → the logged activity trail

**🗣 SAY (transition — land the value):**
> "Order to a scheduled install — and not one dispatcher, queue, or spreadsheet touched it. That's headcount you redeploy onto the jobs that actually need a human. Now let's get a device live."

---

## Beat 2 — Post-Install Onboarding · `4:00 – 6:00`  ·  Pillar: **Asset health, proven not assumed**

**The point:** Install done; the platform **verifies the device is actually healthy from live telemetry** and onboards the customer. The asset's condition is data, not a closed task.

**🗣 SAY:**
> "The installer's on site, device wired into the truck. They mark it complete —"

**🖱 DO:** Open **Assets → VDD-400 GPS Tracking Unit** → click **"Complete Installation."**

**🗣 SAY (while it runs):**
> "— and that one action sets the asset to *Installed* and writes the device's first real telemetry baseline: GPS accuracy, cellular signal, battery voltage, ESN, last ping. It also stands up a live threshold monitor on the battery. Remember that monitor — it matters in a minute."

**👀 SHOW:** Refresh the Asset → status **Installed** → the **Asset Attributes** related list (GPS 2.5m, signal -68 dBm, battery 12.6V).

**🗣 SAY:**
> "Now the onboarding agent takes over automatically. It confirms the install, reads every telemetry attribute, checks each against threshold — all green, **'All Systems Go.'** Then it texts Jim that **his fleet devices are installed and reporting in** — and hands him the next step: **book a training session** so his crew is actually using what they're paying for. That's adoption, and adoption is what makes the subscription stick."

**🖱 DO / 👀 SHOW:** The **Activity timeline** → onboarding task with the telemetry summary + the training call-to-action.

> *Presenter note (multi-device): the message reads "your devices," plural — I click into ONE device as the example, but narrate it across the whole order. Never let it look like a 1:1 "installed 50, showing 1" screen.*
> *Presenter note (VIN rollup): on the asset page, call out that each asset → vehicle → **VIN rolls up to Revenue Cloud** — the linking key they care about, captured once, not re-keyed.*

**🗣 SAY (transition — land the revenue value):**
> "And notice *when* this happened: the moment install is confirmed, **you can start billing.** Today that revenue leaks — devices ship, sit half-installed in a yard, and the meter never starts. Here, install-confirmed *is* revenue-on. These devices are earning their subscription from day one. But the real test of a fleet platform isn't day one — it's day ninety, when a device starts to fail in the field."

---

## Beat 3 — Proactive Health Monitoring · `6:00 – 9:00` · 🎯 HERO BEAT  ·  Pillar: **Service that moves first**

**The point:** The differentiated moment. A device starts failing, and the platform **opens a case and notifies the customer before the customer notices** — protecting uptime, the subscription, and the relationship. This is the leap from *selling a device* to *guaranteeing the outcome the device promises*.

**🗣 SAY:**
> "Fast-forward a few weeks. That battery starts to drift. In most telematics operations, here's what happens next: nothing — until Jim calls in angry because a truck went dark on a job site. Watch what happens here instead."

**🖱 DO:** On the same **VDD-400** asset → click **"Simulate Battery Failure."**

> *⚠️ Presenter note (realism — pending Steven/Kurt): the real Reveal/BT-400 runs on **vehicle power via OBD-II**, not its own battery. Half the audience knows the hardware. Reframe the trip as a **power-feed fault / signal loss / no-ping**, not a "device battery." Keep it consistent with Kurt's RMA troubleshooting. Update once the failure mode is confirmed.*

**🗣 SAY (while it runs):**
> "I'm simulating the device dropping below its health threshold — it stops reporting the way it should. That trips the monitor we created at install. No human is watching this dashboard. The platform is."

**👀 SHOW:** Pause for a beat — let the breach fire and the agent run.

**🗣 SAY:**
> "The health-monitor agent wakes up on the breach. Step one: it identifies *what* tripped and *whose* device — Jim Stone, the semi truck. Step two: it pulls the full telemetry picture, diagnoses it, sets a severity, and recommends an action. Step three —" *(let this land)* — "it opens a service case and texts Jim that the **team's already on it** — *and* it hands him a next move right there in the thread: **reply YES to confirm the replacement, reply CALL for a specialist, or just ask a question.** The customer isn't a spectator to a notification — he's one tap from resolution, and the agent takes it from there."

**🖱 DO / 👀 SHOW:**
- The newly created **Case** → diagnosis, severity, recommended action
- The **customer notification** → "team's on it" + the reply options (confirm / call / ask)

> *Presenter note (identity): which identifier you use depends on the audience — **vehicle name** ("semi truck #7") when you talk to the customer, **device serial** for a Reveal diagnostician, **VIN** as the key that links them. Call it out; the screen already carries all three.*

**🗣 SAY (the money line — slow down):**
> "Verizon Connect detected the failure, diagnosed it, and reached out to the customer — **before Jim ever knew there was a problem.** No truck went dark. No angry call. No churned subscription. That's the difference between selling a tracking device and being the partner that keeps a fleet running. And every step you just watched was the agent — your team's capacity goes to the exceptions, not the routine."

---

## Beat 4 — Recap & Tie-Off · `9:00 – 10:00`

> *⚠️ Presenter note (device count): the exact fleet size is being reconciled with Chris's Revenue Cloud org (~7 vehicles / 9 assets vs. the current 33). Say "the whole fleet" until the number is locked — don't quote a count that contradicts the quoting demo.*

**🗣 SAY:**
> "So in ten minutes we carried that whole fleet the whole way — and three things happened that a tracking platform alone can't do:
> - Devices went from *delivered* to a *scheduled install* with **no dispatcher in the loop** — capacity you redeploy.
> - The customer booked **in his own words, over text** — no portal, no friction, faster time-to-live, which means faster time-to-revenue on every subscription.
> - A failing device became a **case before it became a complaint** — a truck that didn't go dark, a call that didn't come in hot, and a subscription that didn't churn.
>
> One platform — Field Service for the assets and the work, Agentforce for the intelligence — all hanging off the same customer record you saw in Revenue Cloud. Order through end-of-life, one source of truth. Where do you want to go deeper — the dispatch-and-scheduling engine, or the proactive health side?"

**👀 SHOW:** Back on the **Black Rock Paving Account** — devices, the work order, the case all hanging off one record.

> *Presenter note: End on a question that hands them the next-step choice. It turns the demo into a discovery conversation and surfaces which arc to expand in the follow-up.*

---

## One-Glance Run Sheet

| Time | Beat | Click | Land the line |
|------|------|-------|---------------|
| 0:00 | Frame | Account / Shipment list | "Deal's won when 33 devices report — and stay reporting." |
| 1:00 | Delivery | SP-0002 → **Confirm Shipment Delivery** | Scheduled install, zero dispatchers — capacity back |
| 4:00 | Onboarding | VDD-400 → **Complete Installation** | Health proven by live telemetry, not a checkbox |
| 6:00 | **Health** 🎯 | VDD-400 → **Simulate Battery Failure** | "We knew before Jim did." Uptime + subscription protected |
| 9:00 | Recap | Black Rock Paving Account | Three outcomes, one record, order → end-of-life |

## If you're running long (cut order)
1. Trim Beat 2 detail — show telemetry attributes, skip the threshold-by-threshold read.
2. Compress Beat 1's "after" tour to just the Work Order (drop SA + Chatter).
3. Never cut Beat 3. It's the reason you're in the room.

## Landmines (from the handoff)
- **Reset first**, every time. A dirty org breaks Beat 1 silently.
- **Stale 974 sessions** for Jim block the SMS — clear them pre-flight.
- **Work Orders are NOT created at Confirm Delivery** — the *agent* creates them on Jim's reply. By design; don't go hunting for a WO too early.
- SMS records live in Salesforce; **don't promise a physical text** will arrive.
