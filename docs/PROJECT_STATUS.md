# WORLDS — Project Status

Last updated: 2026-11-06

## Current milestone: Android co-op gameplay prototype

### Implemented in the current development branch
- Godot 4 project using the GL Compatibility renderer.
- Landscape mobile orientation and keep-screen-on setting.
- Procedural rolling terrain with collision, river valley, and instanced forest.
- Procedural playable terrain area expanded to 512 × 512 metres, with broader rolling hills and a wider winding river valley.
- The current 512 × 512 metre terrain surface is split into four 256 × 256 metre render/collision tiles; this is not yet dynamic chunk streaming and does not make the world 4 × 4 km.
- Added a timber crossing over the river, a stone approach from the village, a roofed river pavilion with benches and willow trees, and a marked Valleywatch Overlook reached by a stone path.
- Expanded the settlement with a working well, two produce stalls, and eight villagers that can be approached for short dialogue; their behaviour is still simple wandering, not full daily schedules or an economy.
- Added a buildable timber cabin with an open entrance, interior bed and room layout; proximity enables a rest interaction, and cabin placement is included in local save/load and shared build synchronization.
- Added a journey objective that guides the player toward gathering materials and building a cabin, then directs them toward the river crossing and villagers.
- Added live HUD bars for food, water, rest, and sprint energy. Sprint energy drains while running, recovers while walking/standing, and is saved locally.
- Added landmark dots to the map for the village well, river crossing, pavilion, and lookout; added safe world-edge clamping and recovery if the player falls below the terrain.
- Improved mobile control feedback with a MOVE label; movement direction is factored into a testable function, and camera drag ignores the map, settings, network, and build panels.
- Added lightweight filmic colour grading to the world environment; it is not a replacement for final materials, character art, or lighting polish.
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
- Added a first procedural settlement with five homes, a dirt lane, windows, doors, chimneys and lanterns, plus eight villagers who wander near their home area.
- Expanded local fauna with rabbits, foxes and wild boars alongside the existing deer. These are early stylized prototypes, not final-quality character assets or full ecological simulation.
- Position/facing synchronization, remote player placeholders, disconnect handling, and initial shared world interaction synchronization.
- Android Internet permission for ENet/UDP LAN traffic.
- Quality profiles and 20–120 FPS caps; Auto adjusts tree density, shadows, and fog based on observed frame rate.

### Not implemented or not verified yet
- Physical-device verification of the analog joystick, sprint energy, button editing, camera drag, and touch hit areas across different Android aspect ratios.
- Successful two-physical-phone LAN test and router compatibility; current passing tests are automated host/client runs only.
- Reconnection, host migration, session recovery, and robust packet-loss behavior.
- Full authoritative multiplayer for survival values, all resource types, crafting recipes, structure interaction/destruction, and every persistent world change.
- Player identities, accounts, chat, invitations, moderation, and online matchmaking.
- Final character models, polished animation, audio, and production environment art.
- Full animal ecology (livestock, birds, pets, taming, breeding), weather and seasonal simulation, farms, multiple completed villages/biomes, advanced crafting, and freeform building.
- Downloadable world packs and an in-game content library.
- Physical-device performance, thermal, RAM, and battery profiling across low/mid/high devices. The 60 FPS target on the Helio G99 remains unverified on a physical phone.
- Production signing and a release APK.

## Size and performance targets

- Keep the Android base installation sensibly optimized, but prioritize complete gameplay and visual quality over an arbitrary size ceiling; 700 MB was an early planning reference, not a reason to cut core content.
- Optional downloadable world packs are a future option, not implemented yet.
- FPS caps are configurable at 20, 30, 45, 60, 90, and 120. Actual FPS depends on the device and cannot be guaranteed by a cap.
- Low, Balanced, High, Ultra, and adaptive quality modes are available in the prototype. These need device validation.

## Next milestones

1. Finish validation of the latest Godot gameplay, movement, cabin, village, and LAN automated tests.
2. Complete a real touch-control and gameplay pass on an Android phone, including the Helio G99 performance/thermal target.
3. Test host/join, movement, dialogue, gathering, building, survival, disconnects, and save behaviour on two physical phones.
4. Modularize the large main script before adding more world systems, while preserving the passing regression tests.
5. Choose and implement the game's distinctive core gameplay loop rather than expanding content without a clear identity.
6. Build real chunk streaming and expand beyond the current 512 × 512 metre prototype toward the planned 4 × 4 km world.
7. Replace placeholder characters and procedural blockout buildings with polished, original production assets; add finished sound and environmental ambience.
8. Add deeper NPC schedules, animal ecology, farming, advanced crafting, weather, and richer survival systems.
9. Complete multiplayer authority/recovery and device profiling before the final test build.

## Development rules

- Do not call LAN complete until two actual phones have connected and interacted successfully.
- Do not promise 20–120 FPS on every device; expose caps and adaptive quality, then measure.
- Optimize the base installation and keep optional world packs separate where practical, without sacrificing agreed core gameplay quality.
- CI export is not a substitute for launch and gameplay testing on real phones.
- No public test APK is the final deliverable until the complete playtest milestone is ready.
