# 🤖 AI Collaboration & Roadmap Handover

## Project State: AURA v1.0.0
- **Context:** An invisible, zero-UI audio engine for mobile.
- **Completed:** Accelerometer-based state detection, Raw HTTP Radio Provider, BLoC logic, Auto CI/CD.

## Future Sprint: AURA v1.1.0 (Next AI's Mission)
1. **GPS Integration:**
   - Implement `Geolocator` to calculate real-time speed.
   - If `speed > 20 km/h`, force switch to "High-Energy/Road" mode.
2. **Piped API Logic:**
   - Create a fallback provider for YouTube Audio streams when Radio-Browser is unstable.
3. **Smart Fading:**
   - Implement volume fading between state transitions for a seamless "aura" experience.

## Technical Rules
- **No Heavy SDKs:** Use raw HTTP calls where possible.
- **Spec-First:** Always update `docs/AURA_ARCHITECTURE_SPEC.md` before coding.
- **Zero-UI:** Avoid adding buttons, lists, or search bars. The app must "feel" the user.
