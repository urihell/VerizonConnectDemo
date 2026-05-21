# Verizon Connect Demo (VDD) — Comprehensive Summary

## Overview

The **Verizon Connect Demo (VDD)** is a Salesforce Agentforce demo showcasing AI-driven fleet GPS device lifecycle management. The fictional customer is **Black Rock Paving**, a New Jersey paving company deploying **33 VDD-400 GPS tracking units** across their heavy equipment fleet (dump trucks, excavators, pavers, pickup trucks, and a semi truck).

The demo runs as a **10-minute guided walkthrough** through 3 phases — delivery coordination, post-install onboarding, and proactive health monitoring — each powered by an Agentforce topic with 3 sequential GenAI functions backed by Apex invocable methods.

**Salesforce Org:** `verizon-connect-bj550e` (storm-5d2b9a266ed2d8.my.salesforce.com)
**Project Directory:** `VerizonConnectDemo/force-app/main/default/`

---

## Architecture

### Agentforce Component Hierarchy

```
Bot: VDD_Fleet_Agent (InternalCopilot / Employee Agent)
└── BotVersion: v1
    └── GenAiPlanner: VDD_Fleet_Agent (ReAct)
        ├── GenAiPlugin: VDD_Delivery_Coordination (Topic)
        │   ├── GenAiFunction: VDD_Get_Delivery_Details → VDD_GetDeliveryDetails.cls
        │   ├── GenAiFunction: VDD_Collect_Install_Dates → VDD_CollectInstallDates.cls
        │   └── GenAiFunction: VDD_Create_Installer_Work_Order → VDD_CreateInstallerWorkOrder.cls
        │
        ├── GenAiPlugin: VDD_Post_Install_Onboarding (Topic)
        │   ├── GenAiFunction: VDD_Get_Install_Status → VDD_GetInstallStatus.cls
        │   ├── GenAiFunction: VDD_Confirm_Telemetry → VDD_ConfirmTelemetry.cls
        │   └── GenAiFunction: VDD_Send_Onboarding_Message → VDD_SendOnboardingMessage.cls
        │
        └── GenAiPlugin: VDD_Proactive_Health_Monitor (Topic)
            ├── GenAiFunction: VDD_Get_Threshold_Breach → VDD_GetThresholdBreach.cls
            ├── GenAiFunction: VDD_Diagnose_Asset_Health → VDD_DiagnoseAssetHealth.cls
            └── GenAiFunction: VDD_Create_Replacement_Case → VDD_CreateReplacementCase.cls
```

### Agent Configuration

- **Bot Type:** `InternalCopilot` (Employee Agent)
- **Agent Template:** `EmployeeCopilot__AgentforceEmployeeAgent`
- **Planner:** `AiCopilot__ReAct`
- **Tone:** Casual
- **Role:** "You are the VDD Fleet Agent for Verizon Connect. You manage VDD-400 GPS device lifecycle: delivery coordination, post-install telemetry verification, and proactive health monitoring. Your goal is zero fleet downtime."
- **Company Context:** "Verizon Connect provides GPS fleet tracking solutions including the VDD-400 device. We help businesses monitor vehicles and equipment in real-time, optimize routes, and ensure maximum fleet uptime."
- **Context Variables:** ContactId, EndUserId, EndUserLanguage, RoutableId, VoiceCallId — mapped across Text, WhatsApp, Facebook, Line, EmbeddedMessaging, AppleBusinessChat, Custom channels.

### Supporting Infrastructure

| Component | Purpose |
|-----------|---------|
| SMS Channel `TEXT_US_12019086942` | Outbound/inbound SMS on +12019086942 |
| ConversationMessageDefinition `VDD_Delivery_Notification` | SMS template for delivery confirmation |
| Record-Triggered Flows (4) | Automate responses to Shipment/Asset status changes |
| Screen Flow Quick Actions (4) | Demo entry points on Shipment and Asset record pages |
| LWC Components (2) | Custom UI for shipment and product request tracking |
| Custom Lightning Pages (3) | Record pages for Asset, ProductRequest, Shipment |
| Permission Set `VDD_Fleet_Agent_Access` | Grants all VDD field/object/class access |

---

## Demo Flow — 10-Minute Walkthrough

### Initial State (After Reset)

| Record | Status |
|--------|--------|
| Shipment SP-0002 | In Transit |
| VDD-400 GPS Tracker | Shipped |
| DC-200 Dashcam, Antenna, Harness, SIM Card | Shipped |
| Semi Truck | Purchased |
| Dump Truck, Excavator, Paver, Pickup Truck | Installed |
| 28 Fleet Expansion Assets | Installed |
| Warehouse ProductItem Quantities | 100 each |
| Destination ProductItem Quantities | 0 each |

### Phase 1: Delivery Coordination

**Entry Point:** Navigate to Shipment SP-0002 → Click **"Confirm Shipment Delivery"** quick action button.

**What Happens:**

1. **VDD_ConfirmShipmentDelivery** (Apex Quick Action):
   - Sets Shipment SP-0002 status to `Delivered`, records `ActualDeliveryDate`
   - Sets all 5 ProductTransfers to `IsReceived = true`
   - Cascades 5 VDD device Assets (Tracker, Dashcam, SIM, Harness, Antenna) from `Shipped` → `Delivered`
   - Returns success message: "Delivery confirmed! ... The Delivery Coordination agent will contact the customer to schedule installation."

2. **VDD_Delivery_SMS_Notification** (Record-Triggered Flow — fires on Shipment Status = 'Delivered'):
   - Looks up ProductRequest via `$Record.Product_Request__c`
   - Finds Contact with MobilePhone via ProductRequest → AccountId
   - Finds MessagingEndUser via Contact
   - Sends outbound SMS via `sendConversationMessages` action using `VDD_Delivery_Notification` template
   - **SMS text:** "Hi {CustomerName}, your fleet equipment has been delivered to {ShipToName}. Here's what arrived: {EquipmentSummary}. To schedule your professional installation, please reply with 3 preferred dates and times (Morning, Afternoon, or Evening). For example: 'June 2 Morning, June 4 Afternoon, June 5 Morning.' Our installer will do their best to accommodate one of your preferred times. — Verizon Connect"

3. **VDD_Asset_Delivered_Trigger** (Record-Triggered Flow — fires on Asset Status = 'Delivered'):
   - Creates Task alerting the agent to coordinate delivery

4. **Customer (Jim Stone) replies** with 3 preferred install dates via SMS → Agent uses **Delivery Coordination** topic:
   - **Step 1 — Get Delivery Details:** Retrieves asset info, customer contact, device serial/ESN, vehicle name, delivery address
   - **Step 2 — Collect Install Dates:** Extracts 3 date/time preferences from customer message (e.g., "June 2 Morning, June 4 Afternoon, June 5 Morning"), creates Task + Chatter post logging preferences
   - **Step 3 — Create Installer Work Order:** Creates WorkOrder with 6 custom fields (Preferred_Date_1__c through Preferred_Time_3__c), creates linked ServiceAppointment scheduled to first preferred slot, assigns to *New Jersey service territory

### Phase 2: Post-Install Onboarding

**Entry Point:** Navigate to VDD-400 Asset record → Click **"Complete Installation"** quick action button.

**What Happens:**

1. **VDD_CompleteInstallation** (Apex Quick Action):
   - Sets Asset status to `Installed`, sets `InstallDate` to today
   - Creates baseline AssetAttribute records with healthy telemetry:
     - GPS_Accuracy: 2.5 meters
     - Cellular_Signal_Strength: -68 dBm
     - Battery_Voltage: 12.6V
     - Device_ESN: VDD400-2024-00542
     - Last_Ping: current timestamp
   - Creates RecordsetFltrCritMonitor for battery threshold monitoring (< 11.8V)

2. **VDD_Asset_Installed_Trigger** (Record-Triggered Flow) fires → Agent uses **Post-Install Onboarding** topic:
   - **Step 1 — Get Install Status:** Confirms asset is installed, retrieves customer/vehicle details
   - **Step 2 — Confirm Telemetry:** Reads AssetAttribute records, evaluates GPS accuracy (threshold: > 5m), signal strength (threshold: < -85 dBm), battery voltage (threshold: < 11.8V). Returns "All Systems Go" or "Issues Detected"
   - **Step 3 — Send Onboarding Message:** Creates Task simulating welcome SMS with telemetry summary and fleet dashboard link: `https://connect.verizon.com/fleet/BRP-NJ-001`

### Phase 3: Proactive Health Monitoring

**Entry Point:** On VDD-400 Asset record → Click **"Simulate Battery Failure"** quick action button.

**What Happens:**

1. **VDD_SimulateBatteryFailure** (Apex Quick Action):
   - Degrades Battery_Voltage AssetAttribute to 11.4V (below 11.8V threshold)
   - Deletes and recreates the RecordsetFltrCritMonitor to force threshold re-evaluation
   - Sets `Last_Ping__c` on the Asset to current timestamp

2. **VDD_Threshold_Breach_Trigger** (Record-Triggered Flow) fires → Agent uses **Proactive Health Monitor** topic:
   - **Step 1 — Get Threshold Breach:** Identifies breached monitor, affected asset, customer, vehicle
   - **Step 2 — Diagnose Asset Health:** Full diagnostic from all AssetAttribute values. Evaluates severity (Low/Warning/Critical based on how far below threshold). Returns diagnosis, recommended actions
   - **Step 3 — Create Replacement Case:** Creates proactive Case with diagnostic details, sets priority based on severity, creates notification Task. **Key message: "We detected the issue before you even knew about it."**

---

## All Files

### Apex Classes (17 classes + tests)

| Class | Purpose | Invocable? |
|-------|---------|------------|
| `VDD_ConfirmShipmentDelivery` | Quick Action: marks shipment delivered, cascades statuses | Yes |
| `VDD_GetDeliveryDetails` | Topic 1 Step 1: retrieves delivery/device/customer info | Yes |
| `VDD_CollectInstallDates` | Topic 1 Step 2: extracts 3 date/time prefs, logs them | Yes |
| `VDD_CreateInstallerWorkOrder` | Topic 1 Step 3: creates WorkOrder + ServiceAppointment | Yes |
| `VDD_GetInstallStatus` | Topic 2 Step 1: reads install status and customer info | Yes |
| `VDD_ConfirmTelemetry` | Topic 2 Step 2: evaluates AssetAttribute telemetry | Yes |
| `VDD_SendOnboardingMessage` | Topic 2 Step 3: creates welcome Task with dashboard link | Yes |
| `VDD_GetThresholdBreach` | Topic 3 Step 1: identifies breached threshold monitor | Yes |
| `VDD_DiagnoseAssetHealth` | Topic 3 Step 2: full diagnostic from attributes | Yes |
| `VDD_CreateReplacementCase` | Topic 3 Step 3: creates proactive Case + notification | Yes |
| `VDD_ConfirmDelivery` | Quick Action: sets single Asset to Delivered | Yes |
| `VDD_CompleteInstallation` | Quick Action: sets Installed, creates attributes/monitor | Yes |
| `VDD_SimulateBatteryFailure` | Quick Action: degrades battery, triggers breach | Yes |
| `VDD_ResetDemo` | Full demo reset (38 assets, all generated records) | Yes |
| `VDD_ShipmentLookupCtrl` | LWC controller for shipment tracking | No |
| `VDD_TimelineCtrl` | LWC controller for asset timeline | No |
| `VDD_HealthCtrl` | LWC controller for asset health | No |

Each class has a corresponding `*Test.cls` test class.

### Flows (8 flows)

| Flow | Type | Trigger |
|------|------|---------|
| `VDD_Delivery_SMS_Notification` | Record-Triggered (After Save) | Shipment.Status = 'Delivered' |
| `VDD_Asset_Delivered_Trigger` | Record-Triggered (After Save) | Asset.Status = 'Delivered' |
| `VDD_Asset_Installed_Trigger` | Record-Triggered (After Save) | Asset.Status = 'Installed' |
| `VDD_Threshold_Breach_Trigger` | Record-Triggered | RecordsetFltrCritMonitor threshold breach |
| `VDD_Confirm_Shipment_Delivery_Action` | Screen Flow (Quick Action) | Shipment record page button |
| `VDD_Confirm_Delivery_Action` | Screen Flow (Quick Action) | Asset record page button |
| `VDD_Complete_Installation_Action` | Screen Flow (Quick Action) | Asset record page button |
| `VDD_Simulate_Battery_Failure_Action` | Screen Flow (Quick Action) | Asset record page button |

### GenAI Metadata

| Component | File |
|-----------|------|
| Planner | `genAiPlanners/VDD_Fleet_Agent.genAiPlanner-meta.xml` |
| Plugin: Delivery Coordination | `genAiPlugins/VDD_Delivery_Coordination.genAiPlugin-meta.xml` |
| Plugin: Post-Install Onboarding | `genAiPlugins/VDD_Post_Install_Onboarding.genAiPlugin-meta.xml` |
| Plugin: Proactive Health Monitor | `genAiPlugins/VDD_Proactive_Health_Monitor.genAiPlugin-meta.xml` |
| 9 GenAI Functions | `genAiFunctions/VDD_*` (each with input/output schema.json) |

### Bot Definition

| File | Content |
|------|---------|
| `bots/VDD_Fleet_Agent/VDD_Fleet_Agent.bot-meta.xml` | Bot config, context variables, messaging channel mappings |
| `bots/VDD_Fleet_Agent/v1.botVersion-meta.xml` | Agent role, company context, planner reference, dialogs |

### Other Components

| Component | Files |
|-----------|-------|
| Conversation Message Definition | `conversationMessageDefinitions/VDD_Delivery_Notification` |
| Permission Set | `permissionsets/VDD_Fleet_Agent_Access` |
| Quick Actions | `quickActions/Asset.VDD_*`, `quickActions/Shipment.VDD_*` |
| LWC Components | `lwc/vddProductRequestTracker/`, `lwc/vddShipmentTracker/` |
| Lightning Pages | `flexipages/VDD_Asset_Record_Page`, `VDD_ProductRequest_Record_Page`, `VDD_Shipment_Record_Page` |

### Custom Fields

| Object | Field | Type | Purpose |
|--------|-------|------|---------|
| Asset | Device_ESN__c | Text | Electronic Serial Number |
| Asset | Last_Ping__c | DateTime | Last telemetry ping timestamp |
| WorkOrder | Preferred_Date_1__c | Date | Customer's 1st preferred install date |
| WorkOrder | Preferred_Time_1__c | Text | Morning/Afternoon/Evening |
| WorkOrder | Preferred_Date_2__c | Date | Customer's 2nd preferred install date |
| WorkOrder | Preferred_Time_2__c | Text | Morning/Afternoon/Evening |
| WorkOrder | Preferred_Date_3__c | Date | Customer's 3rd preferred install date |
| WorkOrder | Preferred_Time_3__c | Text | Morning/Afternoon/Evening |
| ServiceAppointment | Preferred_Date_1__c | Date | Same 6 fields mirrored |
| ServiceAppointment | Preferred_Time_1__c | Text | on ServiceAppointment |
| ServiceAppointment | Preferred_Date_2__c | Date | for scheduling |
| ServiceAppointment | Preferred_Time_2__c | Text | coordination |
| ServiceAppointment | Preferred_Date_3__c | Date | with field |
| ServiceAppointment | Preferred_Time_3__c | Text | service |
| Shipment | Product_Request__c | Lookup(ProductRequest) | Direct link to ProductRequest (used by SMS flow) |

---

## Key Record IDs

| Record | ID |
|--------|-----|
| **Shipment SP-0002** | `0OBaj0000004tXNGAY` |
| **ProductRequest PR-0003** | `0TSaj0000009V4bGAE` |
| **Jim Stone Contact** | `003aj00001jKXWrAAO` |
| **Jim Stone MessagingEndUser** | `0PAaj00000C1J3JGAV` |
| **Jim Stone MobilePhone** | `+17814900336` |
| **Black Rock Paving Account** | `001aj00002sRTnPAAW` |
| **VDD-400 Tracker Asset** | `02iaj000002m5XJAAY` |
| Semi Truck Asset | `02iaj000002m5VhAAI` |
| Dump Truck Asset | `02iaj000002m5fNAAQ` |
| Excavator Asset | `02iaj000002m5gzAAA` |
| Paver Asset | `02iaj000002m5kDAAQ` |
| Pickup Truck Asset | `02iaj000002m5lpAAA` |
| Dashcam Asset | `02iaj000002m5YvAAI` |
| SIM Card Asset | `02iaj000002m5aXAAQ` |
| Harness Asset | `02iaj000002m5c9AAA` |
| Antenna Asset | `02iaj000002m5dlAAA` |
| SMS Channel (MessagingChannel) | `0Mjaj000001uMgPCAU` |
| SMS Channel Developer Name | `TEXT_US_12019086942` |
| SMS Channel Number | `+12019086942` |
| Warehouse Location | `131aj000000WVtWAAW` |
| Destination Location (Fleet Yard) | `131aj000000WfrFAAS` |
| Product: VDD-400 GPS | `01taj00000SBBCvAAP` |
| Product: DC-200 Dashcam | `01taj00000SBBMbAAP` |
| Product: External GPS Antenna | `01taj00000SBBPpAAP` |
| Product: OBD-II Y-Harness | `01taj00000SB7dyAAD` |
| Product: IoT SIM Card | `01taj00000SBBODAA5` |
| ProductRequestLineItem: GPS | `0Twaj0000004x4jCAA` |
| ProductRequestLineItem: Dashcam | `0Twaj0000004x4kCAA` |
| ProductRequestLineItem: Antenna | `0Twaj0000004x4lCAA` |
| ProductRequestLineItem: Harness | `0Twaj0000004x4mCAA` |
| ProductRequestLineItem: SIM | `0Twaj0000004x4nCAA` |
| 28 Fleet Expansion Assets | `02iaj000002mfAzAAI` through `02iaj000002mfBQAAY` |
| Service Territory (*New Jersey) | Queried by name at runtime |
| Org Alias | `verizon-connect-bj550e` |

---

## Demo Reset

The **VDD_ResetDemo** class (`@InvocableMethod`) restores the entire demo to initial state. It can be triggered via an Agentforce action or directly via Anonymous Apex:

```apex
VDD_ResetDemo.runReset();
```

### Reset Steps (in order):

1. **Reset 38 Asset Statuses** — Semi Truck → Purchased; 5 VDD devices → Shipped; 4 vehicles + 28 fleet → Installed
2. **Delete Tasks** — All VDD-prefixed tasks
3. **Delete Service Appointments** — Linked to VDD Work Orders
4. **Delete Work Orders** — VDD-related
5. **Delete Cases** — VDD-related
6. **Delete AssetAttributes** — All attributes on VDD assets
7. **Delete Monitors** — RecordsetFltrCritMonitor on VDD-400 tracker
8. **Clear Tracker Fields** — InstallDate and Last_Ping__c on VDD-400
9. **Reset Shipment SP-0002** — Status → "In Transit", clear ActualDeliveryDate
10. **Delete & Recreate ProductTransfers** — Must delete/recreate because Salesforce locks records once `IsReceived = true`. Creates 5 new transfers (GPS, Dashcam, Antenna, Harness, SIM) × 33 units each
11. **Reset Warehouse ProductItem Quantities** — Set to 100 each
12. **Reset Destination ProductItem Quantities** — Set to 0 each
13. **Delete VDD Chatter Posts** — On all VDD asset feeds
14. **End Open MessagingSessions** — For Jim Stone's messaging user

---

## SMS Infrastructure

### Outbound SMS Flow: VDD_Delivery_SMS_Notification

**Trigger:** Shipment record saved with Status = 'Delivered' (RecordAfterSave)

**Flow Steps:**
1. **Get Product Request** — Uses `$Record.Product_Request__c` (direct lookup field on Shipment)
2. **Get Contact** — Finds Contact where AccountId matches ProductRequest.AccountId AND MobilePhone is not null
3. **Get Messaging User** — Finds MessagingEndUser where ContactId matches the Contact
4. **Decision: Messaging User Found?** — If yes, continue; if no, end
5. **Add User to Collection** — Adds MessagingEndUser.Id to collection variable
6. **Send Delivery SMS** — `sendConversationMessages` action with:
   - `messageDefinitionName`: VDD_Delivery_Notification
   - `requestType`: SendNotificationMessages
   - `messagingEndUserIds`: collection from step 5
   - `CustomerName`: Contact.FirstName
   - `ShipToName`: $Record.ShipToName
   - `CompanyName`: "Verizon Connect"
   - `EquipmentSummary`: "33x VDD-400 GPS Tracking Units, 33x DC-200 Dual Dashcams, 33x External GPS Antennas, 33x OBD-II Y-Harnesses, 33x IoT SIM Cards"

### Conversation Message Definition: VDD_Delivery_Notification

**Type:** Notification
**Format:** Text
**Constants:** CustomerName, ShipToName, CompanyName, EquipmentSummary (+ Image: SDO_SFS_Dummy_Image)

**Template:**
```
Hi {CustomerName}, your fleet equipment has been delivered to {ShipToName}.
Here's what arrived: {EquipmentSummary}. To schedule your professional
installation, please reply with 3 preferred dates and times (Morning,
Afternoon, or Evening). For example: "June 2 Morning, June 4 Afternoon,
June 5 Morning." Our installer will do their best to accommodate one of
your preferred times. — {CompanyName}
```

### Critical Note: sendConversationMessages Constants

The `sendConversationMessages` flow action requires **ALL** ConversationMessageDefinition constants to be passed as explicit `inputParameters` in the flow. Template default values are **NOT** used at runtime — if a constant is not passed as an input parameter, the action fails with "Required parameter is missing." This was a key lesson learned during development.

### SMS Delivery Status

The SMS flow successfully creates MessagingSession records in Salesforce. However, actual carrier delivery (physical text message arriving on the phone) depends on the org's SMS number provisioning with the telecom provider. In demo org environments, the Salesforce-side records are created correctly but the physical message may not dispatch. For demo purposes, the SMS notification is visible via MessagingSession records in the Salesforce UI.

---

## GenAI Function Schemas

Each GenAI function has input/output schema files in Salesforce Lightning format (NOT standard JSON Schema). Key conventions:

- Input fields use `"copilotAction:isUserInput": true`
- Output fields use `"copilotAction:isDisplayable": true` and `"copilotAction:isUsedByPlanner": true`
- Lightning types: `lightning__textType`, `lightning__integerType`, `lightning__booleanType`, `lightning__numberType`, `lightning__dateType`
- Each function's `.genAiFunction-meta.xml` maps inputs/outputs via `mappingAttributes` that connect schema fields to Apex @InvocableVariable fields

### Topic 1: Delivery Coordination

**VDD_Get_Delivery_Details**
- Input: `assetId` (text)
- Outputs: `customerName`, `customerPhone`, `customerEmail`, `serialNumber`, `deviceESN`, `assetName`, `accountName`, `vehicleName`, `deliveryAddress`, `assetId`, `accountId`, `contactId`

**VDD_Collect_Install_Dates**
- Inputs: `contactId`, `assetId`, `customerName`, `serialNumber`, `preferredDate1`, `preferredTime1`, `preferredDate2`, `preferredTime2`, `preferredDate3`, `preferredTime3`
- Outputs: Same 6 date/time values passed through + `confirmationMessage`, `success`

**VDD_Create_Installer_Work_Order**
- Inputs: `assetId`, `accountId`, `serialNumber`, `deviceESN`, `vehicleName`, `customerName`, `customerPhone`, `deliveryAddress`, `preferredDate1`, `preferredTime1`, `preferredDate2`, `preferredTime2`, `preferredDate3`, `preferredTime3`
- Outputs: `workOrderNumber`, `workOrderId`, `serviceAppointmentId`, `confirmationMessage`, `success`

### Topic 2: Post-Install Onboarding

**VDD_Get_Install_Status**
- Input: `assetId`
- Outputs: `assetName`, `serialNumber`, `vehicleName`, `installDate`, `customerName`, `customerPhone`, `customerEmail`, `assetStatus`, `isInstalled`

**VDD_Confirm_Telemetry**
- Input: `assetId`
- Outputs: `gpsAccuracy`, `signalStrength`, `batteryVoltage`, `telemetryStatus`, `deviceESN`, `lastPing`, `diagnosticSummary`

**VDD_Send_Onboarding_Message**
- Inputs: `contactId`, `assetId`, `customerName`, `telemetryStatus`
- Outputs: `confirmationMessage`, `success`

### Topic 3: Proactive Health Monitor

**VDD_Get_Threshold_Breach**
- Input: `assetId`
- Outputs: `assetName`, `customerName`, `customerPhone`, `breachedThreshold`, `vehicleName`, `assetId`, `accountId`, `contactId`

**VDD_Diagnose_Asset_Health**
- Input: `assetId`
- Outputs: `diagnosis`, `severity`, `recommendedAction`, `gpsAccuracy`, `signalStrength`, `batteryVoltage`, `lastPing`

**VDD_Create_Replacement_Case**
- Inputs: `assetId`, `accountId`, `contactId`, `diagnosis`, `severity`, `recommendedAction`
- Outputs: `caseNumber`, `caseId`, `confirmationMessage`, `success`

---

## Telemetry Thresholds

| Metric | AssetAttribute Name | Healthy Value | Threshold | Breach Direction |
|--------|-------------------|---------------|-----------|-----------------|
| GPS Accuracy | GPS_Accuracy | 2.5 meters | > 5.0 meters | Above = bad |
| Cellular Signal | Cellular_Signal_Strength | -68 dBm | < -85 dBm | Below = bad |
| Battery Voltage | Battery_Voltage | 12.6V | < 11.8V | Below = bad |

The battery failure simulation sets Battery_Voltage to **11.4V** (0.4V below threshold).

---

## Permission Set: VDD_Fleet_Agent_Access

**License:** Salesforce

### Field Permissions (read/write)
- `Asset.Device_ESN__c`, `Asset.Last_Ping__c`
- `ProductTransfer.ShipmentTrackingNumber`, `ProductTransfer.ShipmentStatus`, `ProductTransfer.ShipmentExpectedDeliveryDate`
- `WorkOrder.Preferred_Date_1__c` through `Preferred_Time_3__c` (6 fields)
- `ServiceAppointment.Preferred_Date_1__c` through `Preferred_Time_3__c` (6 fields)

### Object Permissions
- `AssetAttribute` — Create, Read, Edit, View All
- `RecordsetFltrCritMonitor` — Create, Read, Edit, View All

### Apex Class Access (17 classes)
All VDD_* Apex classes listed in the classes table above.

---

## Deployment Sequence

Deploy bottom-up respecting dependencies:

```bash
# 1. Apex Classes (no dependencies)
sf project deploy start --source-dir force-app/main/default/classes --target-org verizon-connect-bj550e

# 2. GenAI Functions (depend on Apex)
sf project deploy start --source-dir force-app/main/default/genAiFunctions --target-org verizon-connect-bj550e

# 3. GenAI Plugins (depend on Functions)
sf project deploy start --source-dir force-app/main/default/genAiPlugins --target-org verizon-connect-bj550e

# 4. GenAI Planner (depends on Plugins)
sf project deploy start --source-dir force-app/main/default/genAiPlanners --target-org verizon-connect-bj550e

# 5. Bot + BotVersion (depends on Planner)
sf project deploy start --source-dir force-app/main/default/bots --target-org verizon-connect-bj550e

# 6. Flows, Quick Actions, LWC, Pages, Permission Sets
sf project deploy start --source-dir force-app/main/default/flows --target-org verizon-connect-bj550e
sf project deploy start --source-dir force-app/main/default/quickActions --target-org verizon-connect-bj550e
sf project deploy start --source-dir force-app/main/default/lwc --target-org verizon-connect-bj550e
sf project deploy start --source-dir force-app/main/default/flexipages --target-org verizon-connect-bj550e
sf project deploy start --source-dir force-app/main/default/permissionsets --target-org verizon-connect-bj550e

# 7. Conversation Message Definition
sf project deploy start --source-dir force-app/main/default/conversationMessageDefinitions --target-org verizon-connect-bj550e

# 8. Assign Permission Set
sf org assign permset --name VDD_Fleet_Agent_Access --target-org verizon-connect-bj550e
```

---

## Known Issues & Lessons Learned

### 1. sendConversationMessages Requires Explicit Constants
The `sendConversationMessages` flow action does NOT use ConversationMessageDefinition default values at runtime. Every constant must be passed as an explicit `inputParameter` in the flow, or it fails with "Required parameter is missing."

### 2. ProductTransfer Platform Lock
Once `IsReceived = true` on a ProductTransfer, Salesforce locks the record and it cannot be updated back to `false`. The demo reset must **delete and recreate** ProductTransfers instead of updating them.

### 3. ServiceAppointment.EarliestStartTime (NOT EarliestStartDate)
The API field name is `EarliestStartTime` (DateTime type), not `EarliestStartDate`. Using the wrong name causes a compile error.

### 4. ProductItem Negative Quantity
When ProductTransfers are received, warehouse ProductItem quantities decrease. If warehouse quantities are below the transfer amount (33 units), the platform throws "Product Item quantity can't be negative." The reset sets warehouse quantities to 100 each.

### 5. SMS Flow Lookup Chain
The original flow used a 4-hop lookup: Shipment → ProductTransfer → ProductRequest → Contact → MessagingEndUser. This was fragile because the ProductTransfer lookup could fail in-transaction. Simplified to 3-hop using a direct `Product_Request__c` lookup field on Shipment.

### 6. SMS Carrier Delivery in Demo Orgs
The SMS flow works correctly at the Salesforce level (creates MessagingSession records), but actual carrier delivery depends on the org's SMS number provisioning. In demo orgs, physical text messages may not dispatch even though Salesforce records are created correctly.

---

## Equipment Bundle (Per Shipment)

| Product | Quantity | Description |
|---------|----------|-------------|
| VDD-400 GPS Tracking Unit | 33 | Primary GPS tracker device |
| DC-200 Dual Dashcam | 33 | Front/rear camera system |
| External GPS Antenna | 33 | Windshield-mount antenna |
| OBD-II Y-Harness | 33 | Vehicle diagnostic port wiring |
| IoT SIM Card (CAT-M1) | 33 | Cellular connectivity |

**Total: 165 items** across 5 product lines, all shipped in Shipment SP-0002.

---

## Fleet Assets (38 total)

### Original 10 Assets
| Asset | Type | Initial Status |
|-------|------|---------------|
| Semi Truck (Peterbilt 389) | Vehicle | Purchased |
| Dump Truck | Vehicle | Installed |
| Excavator (CAT 320) | Vehicle | Installed |
| Paver (Bomag BF 300) | Vehicle | Installed |
| Pickup Truck (F-250) | Vehicle | Installed |
| VDD-400 GPS Tracking Unit | Device | Shipped |
| DC-200 Dual Dashcam | Device | Shipped |
| IoT SIM Card (CAT-M1) | Device | Shipped |
| OBD-II Y-Harness | Device | Shipped |
| External GPS Antenna | Device | Shipped |

### Fleet Expansion (28 additional assets)
28 additional fleet vehicles, all at `Installed` status. IDs: `02iaj000002mfAzAAI` through `02iaj000002mfBQAAY`.

---

## Service Territory

The Work Orders and Service Appointments are assigned to the **\*New Jersey** service territory (queried by name at runtime with `IsActive = true`). The service appointment window defaults to a 2-hour install slot based on the customer's first preferred time:
- **Morning** → 8:00 AM
- **Afternoon** → 1:00 PM
- **Evening** → 5:00 PM
