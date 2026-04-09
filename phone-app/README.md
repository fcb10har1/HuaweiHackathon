# ArrivalRitual — Phone Controller App (Android)

## Stack
- **Platform**: Android (minSdk 26, targetSdk 35)
- **Language**: Kotlin
- **UI**: Jetpack Compose + Material 3
- **State**: ViewModel + StateFlow
- **Navigation**: Navigation Compose

## Folder Structure
```
phone-app/
├── build.gradle.kts
├── settings.gradle.kts
├── gradle/libs.versions.toml
└── app/src/main/
    ├── AndroidManifest.xml
    └── java/com/arrivalritual/controller/
        ├── MainActivity.kt                     # Host + bottom nav
        ├── navigation/NavGraph.kt              # Route constants
        ├── model/TravelModels.kt               # Enums + data classes
        ├── viewmodel/AppViewModel.kt           # All state + actions
        └── ui/
            ├── theme/Theme.kt                  # Dark colour scheme
            ├── components/CommonComponents.kt  # Shared UI primitives
            └── screens/
                ├── CountrySelectionScreen.kt
                ├── StartJourneyScreen.kt
                ├── SimulateTriggersScreen.kt
                └── DebugPanelScreen.kt
```

## Run
1. Open `phone-app/` in Android Studio Hedgehog+
2. Sync Gradle
3. Run on emulator API 26+ or physical Android device

## Demo Flow
```
Country Selection → pick Japan/Thailand/India/UAE
Start Journey → tap 🚀 Start Journey
Simulator → tap Airport / Temple / Taxi / Immigration
  → Temple/Immigration activates camera-lift detection badge
  → Event log builds in real time
Debug Panel → inspect all live state, toggle watch, force alerts
```
