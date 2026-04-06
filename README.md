# ArrivalRitual

> **Helping you navigate any new country confidently** — real-time, context-aware cultural and legal guidance delivered silently through your wrist before mistakes happen.

---

## What Is This?

ArrivalRitual is a smartwatch app that activates the moment you land in a new country. Using GPS + timezone detection, it delivers three things silently through your wrist — no phone needed:

| Feature | Description |
|---|---|
| **Arrival Checklist** | GPS-triggered step-by-step immigration procedures, offline-ready |
| **Convo Assist** | Press crown → microphone captures speech → AI surfaces the right phrase instantly |
| **Social Risk + Local Radar** | Passive location awareness, gesture-triggered risk alerts, camera lift detection |

---

## Two Apps, One System

| App | Platform | Role |
|---|---|---|
| `watch-app/` | HarmonyOS Wearable (ArkTS / DevEco Studio) | **The experience** — wrist-first guidance |
| `phone-app/` | Android (Kotlin + Jetpack Compose) | **The controller** — setup, country selection, simulation |

---

## Demo Flow

```
Presenter (Phone)                        Traveller (Watch)
─────────────────                        ─────────────────
1. Pick destination (e.g. Japan)   →     Country loaded
2. Start Journey                   →     "You've arrived in 🇯🇵 Japan"
3. Trigger: Airport                →     Arrival Checklist begins (haptic on each step)
4. Trigger: Temple                 →     Risk Radar activates (triple pulse = legal)
5. Trigger: Taxi                   →     Convo Assist ready (press crown to record)
6. [Gesture] Camera lift           →     Red warning screen + 3 buzzes
```

---

## Quick Start

### Watch App
1. Install **DevEco Studio 4.0+** from developer.huawei.com
2. Open `watch-app/` as a project
3. Connect a HarmonyOS wearable emulator
4. Run the `entry` module

### Phone App
1. Install **Android Studio Hedgehog** or later
2. Open `phone-app/` as a project
3. Sync Gradle
4. Run on Android emulator (API 26+) or physical device

---

## Risk Classification System

| Level | Signal | Haptic | Example |
|---|---|---|---|
| 🟢 Norm | Visible on tap only | None | Tipping culture |
| 🟡 Sensitivity | Double soft tap | 2× soft pulse | Remove shoes |
| 🔴 Legal | Firm triple pulse | 3× firm buzz | Photography banned |

---

## Sensors Used

- **GPS** — country/location detection, geofence zones
- **Microphone** — on-demand language capture (crown press)
- **Haptics** — timed delivery, risk classification pulses
- **Accelerometer** — detect pauses/movement changes
- **Gyroscope** — camera-lift gesture detection

---

## Scenarios Included (Mock Data)

| Scenario | Country | Key Alerts |
|---|---|---|
| Airport | Japan | Declare food, bow greeting, queue respect |
| Temple | Thailand | Remove shoes, no pointing feet, dress code |
| Taxi | India | Confirm meter, cash preferred, confirm fare |
| Immigration | UAE | Modest dress, photography rules, queueing |
