# Message Contract

Communication protocol between the phone app (Android) and the watch app (HarmonyOS).

## Overview

All messages are exchanged over the Huawei phone-watch messaging bridge. Each message is a JSON object with a `type` field that identifies the message and a `payload` object.

```json
{
  "type": "MESSAGE_TYPE",
  "payload": { ... }
}
```

---

## Watch → Phone Messages

| Type | Description | Payload Schema |
|------|-------------|----------------|
| `PING` | Heartbeat from watch | `{}` |
| `REQUEST_NEXT_STEP` | Request next checklist step | `{ "country": string, "currentStepIndex": number }` |
| `REQUEST_CONTEXT_ALERT` | Request alert for current location | `{ "locationType": string }` |
| `REQUEST_CONVO_OPTIONS` | Request phrases for context | `{ "context": string, "locale": string }` |

### Watch → Phone Examples

**REQUEST_NEXT_STEP**
```json
{
  "type": "REQUEST_NEXT_STEP",
  "payload": {
    "country": "Japan",
    "currentStepIndex": 0
  }
}
```

**REQUEST_CONTEXT_ALERT**
```json
{
  "type": "REQUEST_CONTEXT_ALERT",
  "payload": {
    "locationType": "temple"
  }
}
```

---

## Phone → Watch Messages

| Type | Description | Payload Schema |
|------|-------------|----------------|
| `PONG` | Heartbeat response | `{}` |
| `ARRIVAL_STEP` | A checklist step | `{ "stepIndex": number, "title": string, "description": string, "riskLevel": "NORM" \| "SENSITIVE" \| "LEGAL" }` |
| `CONTEXT_ALERT` | A cultural/legal alert | `{ "alertId": string, "message": string, "riskLevel": "NORM" \| "SENSITIVE" \| "LEGAL" }` |
| `CONVO_OPTIONS` | Suggested phrases | `{ "phrases": string[] }` |
| `ERROR` | Error notification | `{ "code": string, "message": string }` |

### Phone → Watch Examples

**ARRIVAL_STEP**
```json
{
  "type": "ARRIVAL_STEP",
  "payload": {
    "stepIndex": 1,
    "title": "Immigration Queue",
    "description": "Have your passport and landing card ready. Follow the floor markings.",
    "riskLevel": "NORM"
  }
}
```

**CONTEXT_ALERT**
```json
{
  "type": "CONTEXT_ALERT",
  "payload": {
    "alertId": "temple_shoes",
    "message": "Remove shoes before entering the main hall. Pointing feet at the Buddha is disrespectful.",
    "riskLevel": "SENSITIVE"
  }
}
```

**CONVO_OPTIONS**
```json
{
  "type": "CONVO_OPTIONS",
  "payload": {
    "phrases": [
      "How much to the airport?",
      "Please use the meter.",
      "Keep the change."
    ]
  }
}
```

---

## Risk Levels

| Level | Haptic Feedback | Description |
|-------|-----------------|-------------|
| `NORM` | None | General cultural information or etiquette. |
| `SENSITIVE` | 2x Soft Pulse | High social sensitivity. Mistakes cause offense. |
| `LEGAL` | 3x Firm Buzz | Legal requirement. Mistakes may lead to fines/arrest. |
