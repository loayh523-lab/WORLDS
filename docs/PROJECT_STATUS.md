# WORLDS — Project Status

Last updated: 2026-11-06

## Current milestone: Android co-op gameplay prototype

### Implemented in the current development branch
- Godot 4 project using the GL Compatibility renderer.
- Landscape mobile orientation and keep-screen-on setting.
- Procedural rolling terrain with collision, river valley, and instanced forest.
- Procedural playable terrain area expanded to 512 × 512 metres, with broader rolling hills and a wider winding river valley.
- Instanced environmental detail: up to 750 varied broadleaf trees, 190 snow-zone pine trees, 4,200 grass instances, and 260 scattered rocks; quality presets scale their visible density together.
- Added 260 instanced riverbank pebbles and 180 reed stems along both sides of the winding river to give the shoreline more natural detail without creating hundreds of separate scene nodes.
- Early biome distinction: a green central valley, dry eastern dunes, and a colder northern mountain zone with snow coloring and pine trees. These are starter biome regions, not a finished multi-continent world.
- Stylized placeholder character, walking animation, third-person follow camera.
- Keyboard movement plus a two-finger-friendly virtual analog joystick for mobile movement; the right side remains available for camera drag.
- Touch actions for interaction, sprint, and jump, with simultaneous-touch input.
- Adjustable camera sensitivity and touch-button scale; drag-to-reposition action buttons, reset layout, and save the chosen layout locally.
- Scrollable in-game performance/settings panel with live FPS, frame-time (ms/frame), and process-memory readout.
- Camera controls include adjustable sensitivity, follow distance, and field of view; touch buttons include adjustable size and opacity.
- Building mode shows a placement preview, marks river/overlap/start-camp invalid zones, supports 15-degree rotation steps, and disables recipes that cannot currently be afforded.
- Harvestable wood, stone, and fiber nodes now include 48 deterministic extra spawn candidates distributed across the wider region, while avoiding the river and starting camp area.
- LAN build requests now carry the guest's selected rotation to the host; automated gameplay checks cover affordability, invalid placement not consuming supplies, and rotation persistence.
- Smooth horizontal acceleration/deceleration and a sprint speed tier.
- Basic day/night cycle and early survival interactions.
- Collectible wood, stone, and fiber resource deposits with depletion visuals.
- Shared material inventory and recipe-based placement for campfires, storage crates, and simple wood shelters.
- Host-authoritative LAN resource collection and structure placement; new guests receive the shared inventory, remaining resource amounts, and built structures.
- Local persistence for player position, survival values, world time, berry servings, resource depletion, shared inventory, placed structures, control layout, and World Memory.
- Automated gameplay smoke test verifies resource collection, material costs, placement, and save-file persistence.
- Automated LAN smoke test verifies player movement and that a guest gathering a resource updates the host and guest shared state.
- Experimental LAN host/join flow for two phones on the same Wi-Fi.
- Deer roaming and flee destinations are constrained to the temperate valley and steered to remain on their current riverbank; gameplay smoke checks cover habitat bounds and river-crossing regression.
- Position/facing synchronization, remote player placeholders, disconnect handling, and initial shared world interaction synchronization.
- Android Internet permission for ENet/UDP LAN traffic.
- Quality profiles and 20–120 FPS caps; Auto adjusts tree density, shadows, and fog based on observed frame rate.

### Not implemented or not verified yet
- Physical-device verification of the new analog joystick, button editing, and touch hit areas across different aspect ratios.
- Successful two-physical-phone LAN test and router compatibility.
- Reconnection, host migration, session recovery, and robust packet-loss behavior.
- Full authoritative multiplayer for survival values, all resource types, crafting recipes, structure interaction/destruction, and every persistent world change.
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

1. Complete the Godot import, scene, gameplay, and shared-resource LAN smoke tests.
2. Pass Android export with Internet permission and enforce the 700 MB APK ceiling.
3. Install and test the build on two physical Android phones on the same Wi-Fi.
4. Fix any touch, network, orientation, or startup failures found on device.
5. Continue improving character art, terrain materials, trees, rocks, shoreline, and water; the first instanced pebble and reed shoreline pass is now in place.
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
