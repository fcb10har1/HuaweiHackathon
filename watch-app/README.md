# ArrivalRitual — Watch App

A fully standalone HarmonyOS wearable app that guides travellers through cultural norms, arrival steps, and real-time conversation assist. No phone required.

## Prerequisites

- [DevEco Studio](https://developer.huawei.com/consumer/en/deveco-studio/) 5.0 or later
- HarmonyOS SDK (API level 6.0.1 / SDK 21)
- A HarmonyOS-compatible smartwatch or emulator
- An [OpenAI API key](https://platform.openai.com/api-keys) (for LLM alerts, Whisper transcription, and phrase generation)
- A [Google Places API key](https://console.cloud.google.com/google/maps-apis/credentials) with the **Places API (New)** enabled

## Setup

### 1. Clone and open

```bash
git clone https://github.com/fcb10har1/HuaweiHackathon.git
```

Open DevEco Studio → **Open** → select the `watch-app/` directory.  
Let DevEco Studio sync the Hvigor project.

### 2. Configure API keys

The file `entry/build-profile.json5` holds your API keys and is **gitignored** so keys are never accidentally committed.

Copy the provided template and fill in your keys:

```bash
cp watch-app/entry/build-profile.json5.example watch-app/entry/build-profile.json5
```

Then open `watch-app/entry/build-profile.json5` and fill in both keys:

```json5
"buildProfileFields": {
  "OPENAI_API_KEY": "sk-...",         // ← your OpenAI key
  "GOOGLE_PLACES_API_KEY": "AIza..."  // ← your Google Places key
}
```

> **Never commit `build-profile.json5`** — it is in `.gitignore`. The `.example` file (with empty strings) is what gets committed.

### 3. Build and run

Connect a HarmonyOS watch or start a wearable emulator, then click **Run** in DevEco Studio.

---

## Project Structure

```
watch-app/
├── entry/
│   ├── build-profile.json5.example   ← committed template (empty keys)
│   ├── build-profile.json5           ← your local copy with real keys (gitignored)
│   └── src/main/
│       ├── ets/
│       │   ├── common/
│       │   │   ├── Types.ets         — shared types, country list, helpers
│       │   │   └── Config.ets        — reads API keys from BuildProfile
│       │   ├── services/
│       │   │   ├── StorageService.ets       — persist trips to device preferences
│       │   │   ├── CountryDataService.ets   — load country JSON packs from rawfile
│       │   │   ├── LlmService.ets           — OpenAI (alerts, phrases, Whisper)
│       │   │   ├── PlacesService.ets        — Google Places venue detection
│       │   │   ├── LocationService.ets      — GPS polling
│       │   │   └── AlertCooldownService.ets — 1-hour cooldown per location type
│       │   └── pages/
│       │       ├── Index.ets           — trip list (home screen)
│       │       ├── AddTripCountry.ets  — select country for new trip
│       │       ├── AddTripDates.ets    — pick departure + return dates
│       │       ├── TripHome.ets        — active trip screen + GPS polling loop
│       │       ├── ArrivalSteps.ets    — offline step-by-step arrival checklist
│       │       ├── ConvoAssist.ets     — useful phrases + 5-second mic recording
│       │       ├── SpeechResult.ets    — transcription + bilingual reply suggestions
│       │       ├── ContextAlert.ets    — full-screen cultural/legal push alert
│       │       └── TripEnded.ets       — farewell screen when trip date passes
│       └── resources/
│           └── rawfile/countries/     — bundled JSON packs (ae, id, in, jp, kh, la, my, sg, th, vn)
```

## Features

| Feature | Works offline? | Data source |
|---|---|---|
| Trip management (add/delete) | ✅ Yes | Device storage |
| Arrival Steps checklist | ✅ Yes | Bundled JSON |
| Useful Phrases | ✅ Partial | JSON (always) + LLM extras (when online) |
| Speech Assist (mic → replies) | ❌ Needs internet | OpenAI Whisper + GPT |
| Location-based cultural alerts | ❌ Needs internet | Google Places + LLM (JSON fallback offline) |

## Supported Countries

UAE · Indonesia · India · Japan · Cambodia · Laos · Malaysia · Singapore · Thailand · Vietnam

## Communication

This app is **fully standalone** — it does not require a companion phone app or Huawei WearEngine. All logic runs on the watch.
