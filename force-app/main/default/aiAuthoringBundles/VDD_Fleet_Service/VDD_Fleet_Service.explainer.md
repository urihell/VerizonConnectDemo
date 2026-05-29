# VDD_Fleet_Service — Agent Explainer

> Source: `VDD_Fleet_Service.agent` (629 lines, retrieved from `udabby@vzconnect26.demo`)

## What this agent does

`VDD_Fleet_Service` is a **purpose-built SMS agent** for the lifecycle of Verizon Connect's **VDD-400 GPS tracking unit** — the device installed in a fleet customer's vehicle to track location, battery, signal, etc.

It is **not** a general service agent like `VDD_Fleet_Service_Agent` (which has 12 topics covering orders, cases, accounts, reservations, etc.). This one does **three jobs and three jobs only**, plus two safety rails.

## Architecture: router + 5 subagents

```
                    ┌──────────────────────────┐
SMS reply ─────────▶│  agent_router (start)    │
                    │  Reads first message,    │
                    │  picks one of 5 subagents│
                    └──────┬───────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌───────────────┐ ┌───────────────┐ ┌──────────────────────┐
│ delivery_     │ │ post_install_ │ │ proactive_health_    │
│ coordination  │ │ onboarding    │ │ monitor              │
│ (pre-install) │ │ (post-install)│ │ (alert-triggered)    │
└───────────────┘ └───────────────┘ └──────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                                     ▼
┌───────────────┐                  ┌──────────────────────┐
│ off_topic     │                  │ ambiguous_question   │
│ (redirect)    │                  │ (ask for clarity)    │
└───────────────┘                  └──────────────────────┘
```

The router uses **keyword heuristics** in its instructions:

- Dates / times / morning / afternoon / AM / PM → **delivery coordination**
- "Onboarding", "set up", "dashboard", "telemetry", "GPS signal" → **post-install onboarding**
- Threshold breach alert OR "health/battery/signal/alerts" → **proactive health monitor**
- Off-topic OR ambiguous → safety subagents

## Three core subagents

### 1. delivery_coordination — *before* the device is installed

**Trigger:** Customer texts back to a "your VDD-400 has shipped" notification with their preferred install dates/times.

**3-step flow:**

1. `apex://VDD_GetDeliveryDetails` — looks up the most recently delivered VDD-400 for this contact, captures customer + device + vehicle + delivery address
2. `apex://VDD_CollectInstallDates` — logs the 3 preferred date/time pairs as a Task
3. `apex://VDD_CreateInstallerWorkOrder` — creates the Work Order + Service Appointment for the 3rd-party installer with all 3 preferences

**Output:** "Got it [Name]! WO-12345 is set up. Your installer will reach out to confirm one of your preferred slots."

### 2. post_install_onboarding — *after* the device is installed

**Trigger:** Customer texts back to an "onboarding" notification after install is complete.

**3-step flow:**

1. `apex://VDD_GetInstallStatus` — confirms install + pulls customer/device/vehicle
2. `apex://VDD_ConfirmTelemetry` — reads `AssetAttribute` records to verify GPS accuracy, signal strength, battery voltage, ping rate are healthy → returns `telemetryStatus = "All Systems Go"` or `"Issues Detected"`
3. `apex://VDD_SendOnboardingMessage` — sends welcome SMS with telemetry summary + dashboard link

**Output:** "Welcome [Name]! Your VDD-400 in [Vehicle] is reporting [status]. Dashboard: connect.verizon.com/fleet"

### 3. proactive_health_monitor — *autonomous* device-failure response

**Trigger:** Either (a) Salesforce's `RecordsetFltrCritMonitor` flips an asset's `IsWithinThreshold` to false (e.g., battery drops, GPS hasn't pinged in 24h), or (b) customer asks about device health.

**3-step flow:**

1. `apex://VDD_GetThresholdBreach` — identifies which threshold tripped, on which asset, for which customer
2. `apex://VDD_DiagnoseAssetHealth` — reads all `AssetAttribute` values, returns diagnosis + severity (Critical/Warning/Low) + recommended action
3. `apex://VDD_CreateReplacementCase` — opens a service case and texts the customer "we're already on it"

**This is the differentiated capability** — proactive service. The agent doesn't wait for the customer to complain; the threshold-monitor flow fires the agent before the customer notices the device is failing.

## Two safety rails

- **off_topic** — politely redirects without answering general questions. Has a hardcoded jailbreak guardrail (don't reveal system prompts, don't summarize the conversation, etc.)
- **ambiguous_question** — asks for clarification, doesn't invoke any action

## Key technical details

- **No verification topic** — this agent operates on identity from the `MessagingEndUser.ContactId` linked variable (the SMS sender's Salesforce Contact). No email/code verification; the channel itself is the auth.
- **All actions are Apex** (`apex://VDD_*`), not Flow. That's why it published cleanly when our `_AS` build did not — Apex actions take primitive types only, so the publish API has nothing to choke on.
- **State** is held in 40+ mutable variables, namespaced by phase: `delivery_*`, `install_*`, `breach_*`. Each subagent fills its own bucket.
- **Subagents, not topics**. This is an Agentforce **multi-agent** pattern: the router uses `@utils.transition to @subagent.X` instead of `@topic.X`. Each subagent is a focused mini-agent with its own LLM context.

## Apex action inventory

| Action | Subagent | Purpose |
|---|---|---|
| `VDD_GetDeliveryDetails` | delivery_coordination | Look up the customer's most recently delivered VDD-400 |
| `VDD_CollectInstallDates` | delivery_coordination | Save 3 preferred install date/time pairs as a Task |
| `VDD_CreateInstallerWorkOrder` | delivery_coordination | Create WO + Service Appointment with all 6 prefs |
| `VDD_GetInstallStatus` | post_install_onboarding | Confirm install + pull customer/vehicle/asset |
| `VDD_ConfirmTelemetry` | post_install_onboarding | Read AssetAttribute records, return telemetry status |
| `VDD_SendOnboardingMessage` | post_install_onboarding | Send welcome SMS with telemetry summary + dashboard link |
| `VDD_GetThresholdBreach` | proactive_health_monitor | Identify which threshold tripped, on which asset |
| `VDD_DiagnoseAssetHealth` | proactive_health_monitor | Read all attributes, return diagnosis + severity |
| `VDD_CreateReplacementCase` | proactive_health_monitor | Open proactive service case, notify customer |

## TL;DR

Three SMS conversations, each fully automated end-to-end:

1. *"What dates work for install?"* → creates work order
2. *"All set, send me the dashboard"* → verifies device, sends welcome
3. *(threshold breach fires silently)* → diagnoses device, opens replacement case, notifies customer

It's a textbook example of **agent-as-state-machine** with deterministic 3-step flows per intent and Apex back-ends doing the actual data work.
