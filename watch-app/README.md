# ArrivalRitual Watch App

HarmonyOS wearable application for the ArrivalRitual project, built with ArkTS and the Hvigor build system.

## Prerequisites

- [DevEco Studio](https://developer.huawei.com/consumer/en/deveco-studio/) 4.0 or later
- HarmonyOS SDK
- A HarmonyOS-compatible smartwatch or emulator

## Project Structure

```
watch-app/
├── AppScope/          # App-level resources and metadata
├── entry/             # Main wearable app module
│   └── src/
│       ├── main/      # ArkTS source code and resources
│       ├── mock/      # Mock data for development
│       ├── test/      # Unit tests
│       └── ohosTest/  # HarmonyOS integration tests
├── hvigor/            # Hvigor build system plugins
├── build-profile.json5
├── code-linter.json5
├── hvigorfile.ts
├── oh-package.json5
└── oh-package-lock.json5
```

## Setup

1. Open DevEco Studio.
2. Select **Open** and choose the `watch-app/` directory.
3. Let DevEco Studio sync the Hvigor project.
4. Connect a HarmonyOS device or start an emulator.
5. Click **Run** to deploy the app.

## Communication

The watch app communicates with the phone app via the Huawei phone-watch messaging bridge. See [`../docs/message-contract.md`](../docs/message-contract.md) for the full message protocol.
