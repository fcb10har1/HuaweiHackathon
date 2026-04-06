# Message Contract

Communication protocol between the phone app (Android) and the watch app (HarmonyOS).

## Overview

All messages are exchanged over the Huawei phone-watch messaging bridge. Each message is a JSON object with a `type` field that identifies the message and an optional `payload` object containing message-specific data.

```json
{
  "type": "MESSAGE_TYPE",
  "payload": { ... }
}
```

---

## Watch → Phone Messages

| Type | Description | Payload |
|------|-------------|---------|
| `PING` | Heartbeat / connectivity check from watch | `{}` |
| `REQUEST_NEXT_STEP` | Watch requests the next arrival checklist step | `{}` |
| `REQUEST_CONTEXT_ALERT` | Watch requests the current context-aware alert | `{ "location": string }` |
| `REQUEST_CONVO_OPTIONS` | Watch requests conversation assist phrase options | `{ "locale": string }` |

---

## Phone → Watch Messages

| Type | Description | Payload |
|------|-------------|---------|
| `PONG` | Heartbeat response to a PING | `{}` |
| `ARRIVAL_STEP` | Next step in the arrival checklist | `{ "stepIndex": number, "title": string, "description": string, "riskLevel": "LOW" \| "MEDIUM" \| "HIGH" }` |
| `CONTEXT_ALERT` | Context-aware cultural or legal alert | `{ "alertId": string, "message": string, "riskLevel": "LOW" \| "MEDIUM" \| "HIGH" }` |
| `CONVO_OPTIONS` | Conversation assist phrase options | `{ "phrases": string[] }` |
| `ERROR` | Error response for any failed request | `{ "code": string, "message": string }` |

---

## Message Types Reference

| Constant | Direction | Purpose |
|----------|-----------|---------|
| `PING` | Watch → Phone | Heartbeat / connectivity check |
| `PONG` | Phone → Watch | Heartbeat response |
| `REQUEST_NEXT_STEP` | Watch → Phone | Request next arrival checklist step |
| `ARRIVAL_STEP` | Phone → Watch | Deliver next arrival checklist step |
| `REQUEST_CONTEXT_ALERT` | Watch → Phone | Request current context alert |
| `CONTEXT_ALERT` | Phone → Watch | Deliver context-aware alert |
| `REQUEST_CONVO_OPTIONS` | Watch → Phone | Request conversation phrase options |
| `CONVO_OPTIONS` | Phone → Watch | Deliver conversation phrase options |
| `ERROR` | Phone → Watch | Signal a processing error |
