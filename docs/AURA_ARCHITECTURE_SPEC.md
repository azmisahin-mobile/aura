# AURA Core Architecture Specification (v1.7)

## 1. Domain Driven Design (DDD) Context
AURA is an context-aware audio aggregation engine. It does not store audio; it routes existing open streams based on real-time biological, environmental, and cultural state.

## 2. Core Engines
### DeviceContextEngine
Responsible for listening to hardware sensors and emitting `AuraState` transitions.
- **Hysteresis Filter:** To prevent rapid state switching (e.g., during running), an accelerometer state must be stable for at least 5 consecutive frames before a transition is triggered.
- **Cultural Location:** Uses Reverse Geocoding via `geocoding` package to identify the user's country and append cultural tags to the audio search.

### AuraMemoryEngine
Acts as the brain of the app. It generates a dynamic list of tags based on:
1. Biological State (Focus, Chill, Energy)
2. Weather (Clear, Rain, Snow)
3. Time of Day (Morning, Night)
4. Cultural Context (Turkey, Germany, etc.)

## 3. Playback Architecture
To support OS-level lock screen controls and background play:
- Streams are loaded into a `ConcatenatingAudioSource` (Playlist).
- An intelligent buffer is configured (10s min, 60s max) to prevent dropouts on unstable cellular networks.
- DJ Crossfade is simulated using Smart Fade In/Out on a single `AudioPlayer` instance to prevent breaking the mobile OS MediaSession bindings.

## 4. Network Protocol
Direct REST calls to open APIs. Race Condition technique is used to find the fastest active node (ApiResolverEngine).
- Primary Node: `all.api.radio-browser.info` (DNS Discovery)