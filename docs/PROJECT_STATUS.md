# WORLDS — Project Status

Last updated: 2026-11-06

## Current milestone: first 3D world prototype

### Implemented in the repository
- Godot 4 project configuration and a main 3D scene.
- Procedural rolling terrain with a basic collision surface.
- A winding river valley made from simple geometry.
- A small deterministic forest built with MultiMesh instances.
- A third-person placeholder character and follow camera.
- Keyboard movement and jump.
- On-screen touch controls with press/release state tracking.
- Camera drag input on the upper-right part of the screen.
- A basic day/night lighting and sky-color cycle.
- A GitHub Actions workflow for headless project import and a short scene smoke test.

### Not implemented yet
- A finished human character model, animations, and character customization.
- Detailed materials, terrain textures, grass, rocks, and multiple biomes.
- Animals, fish, and interactive environmental life.
- Hunger, thirst, sleep, inventory, crafting, and building.
- The distinctive world-memory mechanic and its progression rules.
- Save/load, account systems, matchmaking, LAN, and online multiplayer.
- Android export configuration and a tested APK.

## Next milestones

1. **Validate the foundation:** inspect the GitHub Actions result, resolve any Godot errors, then run the project on an Android device and adjust touch layout and performance.
2. **Improve the playable slice:** camera feel, character visuals, natural terrain materials, water appearance, vegetation variety, and a second distinct area.
3. **Build the core loop:** exploration and discovery should lead to meaningful player choices, not repetitive resource collection.
4. **Prototype the unique identity:** define and test the world-memory system with a small, understandable example before expanding the world.
5. **Add living-world systems:** animals, weather, day/night consequences, and balanced food/water/rest needs.
6. **Add construction and progression:** intuitive non-grid building, useful crafting, and persistent player-made places.
7. **Plan multiplayer:** choose LAN and online architecture only after the single-player vertical slice is stable. Multiplayer and servers are not present in the current prototype.
8. **Prepare Android builds:** configure export templates and Android tooling, then test APK installation, frame rate, touch controls, thermals, and memory use on real devices.

## Development rules

- Keep Android as the first target and design for touch from the start.
- Keep the world stylized-natural and fully 3D; do not switch to voxel or pixel-art presentation.
- Prefer readable systems and small testable milestones over adding many unfinished menus.
- Do not call a feature complete until it has been run and tested.
- Do not describe the prototype as multiplayer or APK-ready until those parts exist and are verified.
