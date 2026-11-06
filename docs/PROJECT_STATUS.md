# WORLDS — Project Status

Last updated: 2026-11-06

## Current milestone: Android co-op gameplay prototype

### Implemented in the current development branch
- Godot 4 project using the GL Compatibility renderer.
- Landscape mobile orientation and keep-screen-on setting.
- Procedural rolling terrain with collision, river valley, and instanced forest.
- Stylized placeholder character, walking animation, third-person follow camera.
- Keyboard and touch movement; gameplay buttons use TouchScreenButton to support simultaneous touches.
- Camera dragging and interaction.
- Basic day/night cycle and early survival interactions.
- Local save/restore for player position, survival values, world time, berry servings, and World Memory.
- Experimental LAN host/join flow for two phones on the same Wi-Fi.
- Position/facing synchronization, remote player placeholders, disconnect handling, and initial shared world interaction synchronization.
- Android Internet permission for ENet/UDP LAN traffic.
- Quality profiles and 20–120 FPS caps; Auto adjusts tree density, shadows, and fog based on observed frame rate.

### Not implemented or not verified yet
- Successful two-physical-phone LAN test and router compatibility.
- Reconnection, host migration, session recovery, and robust packet-loss behavior.
- Full authoritative multiplayer for all inventory, survival, building, and world changes.
- Player identities, accounts, chat, invitations, moderation, and online matchmaking.
- Final character models, polished animation, audio, and production environment art.
- Animals, weather, seasons, multiple completed biomes, crafting, and non-grid building.
- Downloadable world packs and an in-game content library.
- Physical-device performance, thermal, RAM, and battery profiling across low/mid/high devices.
- Production signing and a release APK.

## Size and performance targets

- Initial Android installation must remain below 700 MB.
- Optional downloadable worlds remain separate from the base installation; total optional content target is up to 2 GB after user selection.
- FPS caps are configurable at 20, 30, 45, 60, 90, and 120. Actual FPS depends on the device and cannot be guaranteed by a cap.
- Low, Balanced, High, Ultra, and adaptive quality modes are available in the prototype. These need device validation.

## Next milestones

1. Pass the Godot import and scene smoke test for the LAN branch.
2. Pass Android export with Internet permission and enforce the 700 MB APK ceiling.
3. Install and test the build on two physical Android phones on the same Wi-Fi.
4. Fix any touch, network, orientation, or startup failures found on device.
5. Improve character art, terrain materials, trees, rocks, shoreline, and water.
6. Expand authoritative synchronization to all relevant player and world state.
7. Add optional world-pack download and mounting, with explicit size and storage checks.
8. Profile frame time, RAM, heat, and battery on representative low-, mid-, and high-tier Android devices.
9. Only then prepare a final test build for the user.

## Development rules

- Do not call LAN complete until two actual phones have connected and interacted successfully.
- Do not promise 20–120 FPS on every device; expose caps and adaptive quality, then measure.
- Keep the initial installation below 700 MB; optional worlds must be separately downloaded and consented to.
- CI export is not a substitute for launch and gameplay testing on real phones.
- No public test APK is the final deliverable until the complete playtest milestone is ready.
