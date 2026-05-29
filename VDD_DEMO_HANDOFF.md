# Verizon Connect Demo (VDD) — Complete Demo Handoff Document

> **Last Updated:** 2026-05-29
> **Org Alias:** `verizon-connect-bj550e`
> **Org URL:** `https://storm-5d2b9a266ed2d8.my.salesforce.com`
> **Agent:** VDD Fleet Service Agent (Builder 2.0 / Agent Script — Version 2 Active)
> **SMS Channel:** +1-201-908-6974 (974 channel, `0Mjaj000001uWavCAE`)
> **Customer:** Black Rock Paving (Jim Stone, +17814900336)

---

## Executive Summary

The VDD demo showcases **Agentforce-powered fleet GPS device lifecycle management** for Verizon Connect. A fictional customer (Black Rock Paving, NJ) has 33 VDD-400 GPS tracking units deployed across their heavy equipment fleet. The demo walks through 3 phases — each triggered by a button click and handled by an Agentforce agent topic over SMS:

1. **Delivery Coordination** — Confirm shipment delivery → SMS sent to customer → Customer replies with install dates → Agent creates Work Order and records preferences
2. **Post-Install Onboarding** — Mark device installed → Agent verifies telemetry → Sends onboarding welcome
3. **Proactive Health Monitoring** — Simulate battery failure → Agent detects breach → Diagnoses issue → Creates replacement case

**Total demo time:** ~10 minutes

---

## Pre-Demo Checklist

Before starting, ensure the demo is in a clean state:

1. **Reset the demo** — Navigate to any Asset record → Run `VDD_ResetDemo.runReset()` via Anonymous Apex, or use the reset action if available
2. **Verify initial state:**
   - Shipment SP-0002 = "In Transit"
   - VDD-400 GPS Tracker asset = "Shipped"
   - Semi Truck asset = "Purchased"
   - Other vehicles (Dump Truck, Excavator, Paver, Pickup) = "Installed"
3. **Verify no stale messaging sessions** — Check that Jim Stone has no open/active MessagingSession records on the 974 channel. Stale sessions block outbound SMS.
4. **Verify the agent is active** — VDD Fleet Service Agent, Version 2 (Active) in Agentforce Builder 2.0

---

## Phase 1: Delivery Coordination

### What It Demonstrates
- Automated shipment confirmation with cascading status updates
- Outbound SMS notification to customer
- AI agent conversation over SMS for installation scheduling
- Work Order and WOLI creation by the agent
- Service Appointment scheduling

### Click Path

#### Step 1: Navigate to the Shipment
1. Open **App Launcher** → search "Shipments" → click **Shipments** tab
2. Find and click **SP-0002** (Shipment to Black Rock Paving)
3. Note the current status: **In Transit**

#### Step 2: Confirm the Delivery
1. On the Shipment SP-0002 record page, click the **"Confirm Shipment Delivery"** button (top-right action area)
2. A screen flow opens — click through to confirm
3. **What happens behind the scenes** (`VDD_ConfirmShipmentDelivery` Apex):
   - 5 ProductTransfers marked as received
   - 5 device assets (VDD-400 Tracker, DC-200 Dashcam, SIM Card, Harness, Antenna) cascade from "Shipped" → "Delivered"
   - Shipment status → "Delivered" with ActualDeliveryDate set
   - Product Request status → "Received"
4. The button returns a success message: "Shipment to Black Rock Paving confirmed. 5 product transfers received. 5 assets updated to Delivered."

#### Step 3: SMS is Sent Automatically
- When the Shipment status changes to "Delivered", the **VDD_Delivery_SMS_Notification** record-triggered flow fires automatically
- The flow looks up the Contact (Jim Stone) via the Product Request → Account, finds his MessagingEndUser on the 974 channel, and sends an outbound SMS
- **SMS content:** "Hi Jim, your VDD-400 GPS Tracking Unit + 4 accessories have been delivered to Black Rock Paving. Reply with 3 preferred install dates/times (Morning, Afternoon, Evening). Example: 'Jun 2 AM, Jun 4 PM, Jun 5 AM' — Verizon Connect"

> **Demo Tip:** You can show the SMS notification in Salesforce by navigating to the Messaging Sessions list or the Contact record's activity feed. In demo orgs, the physical text may not dispatch, but the Salesforce records are created.

#### Step 4: Customer Replies (Agent Conversation)
- Jim Stone replies via SMS with 3 preferred installation dates, e.g.: *"June 2 morning, June 4 afternoon, June 5 morning"*
- The **VDD Fleet Service Agent** picks up the message on the 974 channel
- The **delivery_coordination** subagent activates and calls `VDD_UpdateDeliveryPreferences`:
  - **If no Work Order exists** (new flow): Auto-creates a Work Order with WOLIs (one per vehicle, derived from the shipment's asset hierarchy), links it to the ProductRequest
  - Updates the Work Order with the 3 date/time preferences
  - Creates or updates a Service Appointment scheduled to the first preferred slot
  - Logs a Task and Chatter post for visibility
  - Ends the messaging session
  - Replies to the customer with confirmation: "Your installation preferences have been recorded on Work Order WO-XXXXX..."

#### What to Show After Phase 1
- Navigate to the **Product Request** → show the linked Work Order
- Open the **Work Order** → show WOLIs (one per vehicle), the preferred dates, the description
- Open the **Service Appointment** → show the scheduled appointment window
- Check the **Asset's Chatter feed** → show the logged activity

---

## Phase 2: Post-Install Onboarding

### What It Demonstrates
- Automated device installation confirmation
- Telemetry baseline creation (AssetAttributes)
- AI-driven telemetry verification
- Customer onboarding with dashboard access

### Click Path

#### Step 1: Navigate to the VDD-400 Asset
1. Open **App Launcher** → search "Assets" → click **Assets** tab
2. Find and click the **VDD-400 GPS Tracking Unit** asset
3. Note the current status: **Delivered** (from Phase 1)

#### Step 2: Complete the Installation
1. Click the **"Complete Installation"** button on the Asset record page
2. **What happens** (`VDD_CompleteInstallation` Apex):
   - Asset status → "Installed", InstallDate set to today
   - Creates baseline **AssetAttribute** records:
     - GPS_Accuracy: 2.5 meters (healthy)
     - Cellular_Signal_Strength: -68 dBm (healthy)
     - Battery_Voltage: 12.6V (healthy)
     - Device_ESN: VDD400-2024-00542
     - Last_Ping: current timestamp
   - Creates **RecordsetFltrCritMonitor** for battery threshold monitoring (< 11.8V)

#### Step 3: Agent Runs Onboarding (3 steps)
The **VDD_Asset_Installed_Trigger** flow fires → Agent's **post_install_onboarding** subagent activates:

1. **Get Install Status** (`VDD_GetInstallStatus`): Confirms the asset is installed, retrieves customer/vehicle details
2. **Confirm Telemetry** (`VDD_ConfirmTelemetry`): Reads all AssetAttribute records, evaluates against thresholds:
   - GPS Accuracy: 2.5m ✓ (threshold > 5.0m)
   - Signal Strength: -68 dBm ✓ (threshold < -85 dBm)
   - Battery Voltage: 12.6V ✓ (threshold < 11.8V)
   - Returns: **"All Systems Go"**
3. **Send Onboarding Message** (`VDD_SendOnboardingMessage`): Creates a Task with welcome message including telemetry summary and fleet dashboard link

#### What to Show After Phase 2
- Refresh the **Asset record** → status now "Installed"
- Show the **Asset Attributes** related list → GPS, signal, battery readings
- Show the **Activity timeline** → onboarding task with telemetry summary

---

## Phase 3: Proactive Health Monitoring

### What It Demonstrates
- Real-time threshold monitoring on IoT device attributes
- AI-driven autonomous diagnostics
- Proactive case creation before customer reports an issue
- "We knew before you did" moment

### Click Path

#### Step 1: Simulate a Battery Failure
1. Still on the **VDD-400 GPS Tracking Unit** asset record
2. Click the **"Simulate Battery Failure"** button
3. **What happens** (`VDD_SimulateBatteryFailure` Apex):
   - Battery_Voltage AssetAttribute degraded from 12.6V → **11.4V** (below 11.8V threshold)
   - RecordsetFltrCritMonitor deleted and recreated to force threshold re-evaluation
   - Last_Ping timestamp updated

#### Step 2: Agent Detects and Responds (3 steps)
The **VDD_Threshold_Breach_Trigger** flow fires → Agent's **proactive_health_monitor** subagent activates:

1. **Get Threshold Breach** (`VDD_GetThresholdBreach`): Identifies which threshold was breached (Battery_Voltage), the affected asset, customer (Jim Stone), and vehicle (Semi Truck)
2. **Diagnose Asset Health** (`VDD_DiagnoseAssetHealth`): Full diagnostic from all AssetAttribute values. Evaluates severity:
   - 11.4V is 0.4V below 11.8V threshold → **Warning** severity
   - Recommends: "Schedule preventive battery replacement within 2 weeks"
3. **Create Replacement Case** (`VDD_CreateReplacementCase`): Creates a proactive Case with diagnostic details, sends customer an SMS notification that the team is already on it

#### What to Show After Phase 3
- Open the newly created **Case** → show diagnostic details, severity, recommended action
- Show the **Asset's Chatter feed** → proactive notification
- **Key talking point:** "We detected the battery issue and opened a case before the customer even knew about it — that's proactive fleet management."

---

## Architecture Overview

### Agent Definition (Builder 2.0 — Agent Script)

The agent is built using the **Agent Script DSL** and lives at:
`aiAuthoringBundles/VDD_Fleet_Service_Agent/VDD_Fleet_Service_Agent.agent`

```
VDD Fleet Service Agent (AgentforceServiceAgent)
├── agent_router (start_agent)
│   └── Routes based on message intent → delivery, onboarding, health, escalation, off-topic
│
├── delivery_coordination (subagent)
│   └── update_delivery_preferences → apex://VDD_UpdateDeliveryPreferences
│       Creates WO + WOLIs if needed, updates preferences, ends session
│
├── post_install_onboarding (subagent)
│   ├── get_install_status → apex://VDD_GetInstallStatus
│   ├── confirm_telemetry → apex://VDD_ConfirmTelemetry
│   └── send_onboarding_message → apex://VDD_SendOnboardingMessage
│
├── proactive_health_monitor (subagent)
│   ├── get_threshold_breach → apex://VDD_GetThresholdBreach
│   ├── diagnose_asset_health → apex://VDD_DiagnoseAssetHealth
│   └── create_replacement_case → apex://VDD_CreateReplacementCase
│
├── escalation (subagent) → @utils.escalate
├── off_topic (subagent) → Redirect to relevant topics
└── ambiguous_question (subagent) → Ask for clarification
```

### SMS Flow

```
Confirm Delivery Button
  → VDD_ConfirmShipmentDelivery (Apex)
    → Shipment.Status = "Delivered"
      → VDD_Delivery_SMS_Notification (Record-Triggered Flow)
        → Finds Contact via ProductRequest → Account
        → Finds MessagingEndUser on 974 channel
        → Sends SMS via sendConversationMessages
          → Customer replies
            → VDD Fleet Service Agent activates
              → delivery_coordination subagent
                → VDD_UpdateDeliveryPreferences (Apex)
                  → Creates WO + WOLIs (if needed)
                  → Updates preferences
                  → Creates Service Appointment
                  → Ends session
```

### Key Apex Classes

| Class | Purpose | Called By |
|-------|---------|-----------|
| `VDD_ConfirmShipmentDelivery` | Confirms delivery: transfers, assets, shipment status, PR status | Confirm Delivery button |
| `VDD_UpdateDeliveryPreferences` | Agent action: creates WO + WOLIs if needed, updates date preferences, ends session | Agent (delivery_coordination) |
| `VDD_GetInstallStatus` | Gets install status and customer details | Agent (post_install_onboarding) |
| `VDD_ConfirmTelemetry` | Reads AssetAttributes, evaluates telemetry health | Agent (post_install_onboarding) |
| `VDD_SendOnboardingMessage` | Creates welcome Task with dashboard link | Agent (post_install_onboarding) |
| `VDD_GetThresholdBreach` | Identifies breached threshold and affected asset | Agent (proactive_health_monitor) |
| `VDD_DiagnoseAssetHealth` | Full diagnostic from all attributes | Agent (proactive_health_monitor) |
| `VDD_CreateReplacementCase` | Creates proactive Case + notification | Agent (proactive_health_monitor) |
| `VDD_CompleteInstallation` | Sets asset to Installed, creates attributes/monitor | Complete Installation button |
| `VDD_SimulateBatteryFailure` | Degrades battery, triggers threshold breach | Simulate Battery Failure button |
| `VDD_BuildEquipmentSummary` | Generates equipment list for SMS text | SMS flow |
| `VDD_ResetDemo` | Full demo reset (all records to initial state) | Admin action / Anonymous Apex |

### Record-Triggered Flows

| Flow | Trigger | What It Does |
|------|---------|--------------|
| `VDD_Delivery_SMS_Notification` | Shipment.Status → "Delivered" | Sends SMS to customer via 974 channel |
| `VDD_Asset_Delivered_Trigger` | Asset.Status → "Delivered" | Creates alert Task |
| `VDD_Asset_Installed_Trigger` | Asset.Status → "Installed" | Triggers onboarding agent topic |
| `VDD_Threshold_Breach_Trigger` | RecordsetFltrCritMonitor breach | Triggers proactive health agent topic |

---

## Key Record IDs

| Record | ID |
|--------|-----|
| Shipment SP-0002 | `0OBaj0000004tXNGAY` |
| Product Request PR-0003 | `0TSaj0000009V4bGAE` |
| Jim Stone (Contact) | `003aj00001jKXWrAAO` |
| Jim Stone (MessagingEndUser on 974) | `0PAaj00000C2cezGAB` |
| Jim Stone MobilePhone | `+17814900336` |
| Black Rock Paving (Account) | `001aj00002sRTnPAAW` |
| VDD-400 Tracker (Asset) | `02iaj000002m5XJAAY` |
| Semi Truck (Asset) | `02iaj000002m5VhAAI` |
| SMS Channel 974 | `0Mjaj000001uWavCAE` |
| SMS Channel 942 (legacy, not in use) | `0Mjaj000001uMgPCAU` |

---

## Two SMS Channels — Important Distinction

| Channel | Number | ID | Status |
|---------|--------|----|--------|
| 974 | +1-201-908-6974 | `0Mjaj000001uWavCAE` | **ACTIVE** — Used by agent and SMS flow |
| 942 | +1-201-908-6942 | `0Mjaj000001uMgPCAU` | Legacy — Referenced in some docs but NOT in use |

The SMS notification flow (`VDD_Delivery_SMS_Notification`) looks up Jim Stone's MessagingEndUser on the **974 channel**. The agent is also routed on the **974 channel**. All references to the 942 channel in older documentation are outdated.

---

## Telemetry Thresholds

| Metric | Healthy Value | Threshold | Breach Triggers When |
|--------|---------------|-----------|---------------------|
| GPS Accuracy | 2.5 meters | > 5.0 meters | Above threshold |
| Cellular Signal | -68 dBm | < -85 dBm | Below threshold |
| Battery Voltage | 12.6V | < 11.8V | Below threshold |

Battery failure simulation sets voltage to **11.4V** (0.4V below threshold).

---

## Demo Reset

Run this to restore the demo to its initial state:

```apex
VDD_ResetDemo.runReset();
```

### What Gets Reset (in order):
1. 38 asset statuses restored (Semi Truck → Purchased, 5 devices → Shipped, others → Installed)
2. All VDD Tasks deleted
3. Service Appointments deleted
4. Work Orders deleted
5. Cases deleted
6. AssetAttributes deleted
7. Threshold Monitors deleted
8. Tracker fields cleared (InstallDate, Last_Ping)
9. Shipment SP-0002 → "In Transit", ActualDeliveryDate cleared
10. ProductTransfers deleted and recreated (platform locks received records)
11. Warehouse ProductItem quantities → 100
12. Destination ProductItem quantities → 0
13. VDD Chatter posts deleted
14. Open MessagingSessions ended

---

## Known Issues & Tips

### 1. Stale Messaging Sessions Block SMS
If an active MessagingSession exists for Jim Stone on the 974 channel with zero conversation entries (zombie session), outbound SMS notifications will fail silently. Check for and end stale sessions before running the demo.

### 2. SMS May Not Physically Dispatch in Demo Orgs
The SMS flow creates correct Salesforce records (MessagingSession, ConversationEntry) but actual carrier delivery depends on SMS number provisioning. In demo orgs, show the SMS records in Salesforce rather than on a physical phone.

### 3. ProductTransfer Platform Lock
Once `IsReceived = true`, records cannot be toggled back. Demo reset deletes and recreates them.

### 4. Work Order Creation Timing
Work Orders are **NOT** created during the Confirm Delivery step. They are created by the agent when the customer replies with scheduling preferences. This is by design — the agent owns the WO lifecycle.

### 5. Agent Version
The agent is built in **Agentforce Builder 2.0** using Agent Script. To view/edit: open Agentforce Studio → VDD Fleet Service Agent → Version 2 (Active). The `.agent` file is at `aiAuthoringBundles/VDD_Fleet_Service_Agent/`.

### 6. Delivery Name Confusion
The agent has an instruction to verify contact names from the user's profile before interpreting scheduling preferences. This prevents the agent from confusing month names (e.g., "June") with the customer's name.

---

## Files Reference

### Project Root
`/workspace/VerizonConnectDemo/force-app/main/default/`

### Key Directories
| Directory | Content |
|-----------|---------|
| `classes/` | All VDD_* Apex classes and tests |
| `flows/` | Record-triggered flows and screen flow quick actions |
| `aiAuthoringBundles/VDD_Fleet_Service_Agent/` | Agent Script (.agent file) + bundle XML |
| `genAiPlugins/` | Legacy GenAI topic definitions (also deployed) |
| `genAiFunctions/` | Legacy GenAI function definitions |
| `conversationMessageDefinitions/` | SMS notification template |
| `lwc/` | Custom Lightning Web Components |
| `flexipages/` | Custom record pages |
| `permissionsets/` | VDD_Fleet_Agent_Access permission set |

---

## Deployment Notes

The agent uses **Agent Script (Builder 2.0)**. To publish changes:

1. Edit the `.agent` file at `aiAuthoringBundles/VDD_Fleet_Service_Agent/VDD_Fleet_Service_Agent.agent`
2. Publish: `sf agent publish authoring-bundle --api-name VDD_Fleet_Service_Agent -o verizon-connect-bj550e --json`
3. Activate: `sf agent activate --api-name VDD_Fleet_Service_Agent -o verizon-connect-bj550e`

For Apex/Flow/metadata changes: `sf project deploy start --source-dir <path> -o verizon-connect-bj550e`

> **Important:** Use `sf agent publish authoring-bundle`, NOT `sf project deploy start`, for the Agent Script file.

---

## Quick Reference: Demo Click Path (TL;DR)

```
RESET → VDD_ResetDemo.runReset()

PHASE 1 — Delivery Coordination
  Navigate to: Shipments → SP-0002
  Click: "Confirm Shipment Delivery"
  Watch: SMS sent automatically to Jim Stone
  Simulate: Jim replies "June 2 morning, June 4 afternoon, June 5 morning"
  Show: Work Order created by agent → WOLIs → Service Appointment → Chatter

PHASE 2 — Post-Install Onboarding
  Navigate to: Assets → VDD-400 GPS Tracking Unit
  Click: "Complete Installation"
  Watch: Agent verifies telemetry → "All Systems Go" → Sends onboarding welcome
  Show: AssetAttributes → Activity Timeline → Onboarding Task

PHASE 3 — Proactive Health Monitoring
  Navigate to: Same VDD-400 asset
  Click: "Simulate Battery Failure"
  Watch: Agent detects breach → Diagnoses → Creates replacement Case → Notifies customer
  Show: Case with diagnostics → "We knew before you did" 🎯
```
