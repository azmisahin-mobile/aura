# AURA Core Architecture Specification (v1.0)

## 1. Domain Driven Design (DDD) Context
AURA is an context-aware audio aggregation engine. It does not store audio; it routes existing open streams based on real-time biological/environmental state.

## 2. Core Entities
- **AuraState**: The calculated biological/environmental state. Enum: `[chill, energy, focus]`.
- **AudioStream**: The resolved data object representing an active audio source.
  - `name` (String)
  - `url` (String - must be playable stream e.g., .mp3, .m3u8, .aac)
  - `provider` (String - e.g., 'RadioBrowser', 'Piped')

## 3. Interfaces & Contracts
### IContextEngine
Responsible for listening to hardware sensors and emitting `AuraState` transitions.
- `Stream<AuraState> get stateStream;`

### IAudioProvider
A unified interface for any external audio source (Radio, YouTube via Piped, Local).
- `Future<List<AudioStream>> fetchStreams(AuraState state);`

## 4. State Management (BLoC)
The BLoC listens to `IContextEngine`. Upon state transition:
1. Calls `IAudioProvider.fetchStreams(newState)`.
2. Selects a stream.
3. Passes the URL to the AudioPlayer instance.
4. Emits `AuraActiveState` to the UI.

## 5. Network Protocol
Direct REST calls to open APIs. No wrapper SDKs unless officially maintained by the provider.
- Primary Radio Node: `https://de1.api.radio-browser.info/json/stations/search`
