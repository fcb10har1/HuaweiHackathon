# System Architecture

## Overview

ArrivalRitual is a two-component system: an Android phone app that acts as the main controller and data processor, and a HarmonyOS watch app that serves as the wearable interface. The two components communicate through the Huawei phone-watch messaging bridge.

```
┌─────────────────────┐        Messaging Bridge        ┌─────────────────────┐
│     phone-app       │ ◄────────────────────────────► │     watch-app       │
│  (Android / Kotlin) │                                 │ (HarmonyOS / ArkTS) │
└─────────────────────┘                                 └─────────────────────┘
   Controller & Logic                                     Wearable Interface
```

---

## Components

### phone-app (Android Controller)

- **Role**: Main controller and processing engine.
- **Responsibilities**:
  - Stores all travel data, arrival checklists, and cultural alert content.
  - Processes GPS and timezone signals to determine the user's current context.
  - Responds to requests from the watch app and pushes proactive alerts.
  - Manages app state with Jetpack ViewModel and StateFlow.
- **Tech stack**: Kotlin, Jetpack Compose, Material 3, Navigation Compose.

### watch-app (HarmonyOS Wearable Interface)

- **Role**: Wearable user interface.
- **Responsibilities**:
  - Displays arrival checklist steps, context alerts, and conversation assist prompts.
  - Captures user input (crown press, gesture detection).
  - Sends request messages to the phone app and renders the responses.
  - Delivers haptic feedback based on risk level.
- **Tech stack**: ArkTS, DevEco Studio, Hvigor build system.

---

## Messaging Bridge

All communication between the phone app and the watch app passes through the Huawei phone-watch messaging bridge (Huawei Wearable Engine / HiLink). Messages are JSON objects identified by a `type` field.

See [`message-contract.md`](message-contract.md) for the full list of message types and payloads.

### Communication Flow

```
Watch                          Phone
  │                              │
  │── REQUEST_NEXT_STEP ────────►│
  │◄─ ARRIVAL_STEP ──────────────│
  │                              │
  │── REQUEST_CONTEXT_ALERT ────►│
  │◄─ CONTEXT_ALERT ─────────────│
  │                              │
  │── REQUEST_CONVO_OPTIONS ────►│
  │◄─ CONVO_OPTIONS ─────────────│
  │                              │
  │── PING ─────────────────────►│
  │◄─ PONG ──────────────────────│
```

---

## Data Flow

1. The phone app detects location (GPS / timezone) and updates internal state.
2. The watch app sends a request (e.g. `REQUEST_NEXT_STEP`) triggered by user interaction.
3. The phone app processes the request against its stored data and responds with the appropriate message (e.g. `ARRIVAL_STEP`).
4. The watch app renders the response and triggers haptic feedback based on the risk level.
