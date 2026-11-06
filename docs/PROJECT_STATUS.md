# WORLDS — Project Status

Last updated: 2026-11-06

## Current milestone: first 3D playable slice

### Implemented in the repository
- Godot 4 project configuration and a main 3D scene.
- Procedural rolling terrain with a collision surface.
- A winding river valley and a small deterministic forest using MultiMesh instances.
- A stylized humanoid placeholder character with a basic walk cycle.
- A separate orbit camera; camera drag and character-facing movement.
- Keyboard movement and jump.
- On-screen touch controls for movement, jump, and interaction.
- A basic day/night lighting and sky-color cycle (20 real minutes per in-game day).
- Early survival interactions: drink near the river, gather limited wild berries, and rest at the campsite to advance time to morning.
- First World Memory experiment: interact with the memory stone to reveal a glowing trail across the landscape.
- GitHub Actions headless import and scene smoke test. The latest checked code change passed the automated run.

### Not implemented yet
- Final character models, polished animations, customization, and production-quality art.
- Detailed terrain materials, grass, rocks, water effects, and multiple finished biomes.
- Animals, fish, weather, seasons, and deeper environmental simulation.
- Full survival balance, inventory, crafting, building, and permanent player structures.
- Persistent, shared world-memory effects and the complete progression design.
- Save/load, accounts, matchmaking, LAN, and online multiplayer.
- Android export configuration, APK build, and physical-device performance testing.

## Next milestones

1. **Device validation:** import and run the project in Godot on Android; adjust touch layout, camera feel, and performance on the target phone.
2. **World presentation:** improve terrain materials, shoreline, vegetation variety, trees, rocks, and the first distinct secondary area.
3. **Core loop:** make exploration lead to meaningful decisions and discoveries rather than repetitive resource collection.
4. **World Memory:** test a small loop in which a player's meaningful action changes a place and leaves a trace that can guide or help later visitors. The current glowing trail is only a visual proof of concept.
5. **Living world:** add a few animal behaviors and weather changes, then assess performance before scaling up.
6. **Survival and construction:** balance food, water, rest, inventory, and intuitive non-grid building so these support exploration instead of becoming chores.
7. **Multiplayer design:** prototype LAN and online architecture only after the single-player slice is stable.
8. **Android release path:** configure export templates and Android tooling, then test installation, frame rate, touch controls, thermals, and memory use on real devices.

## Development rules

- Android is the first target; touch input and performance matter from the start.
- Keep the presentation natural and fully 3D, not voxel or pixel-art.
- Prefer a small number of polished, testable systems over many unfinished menus.
- A passing CI smoke test is not the same as a real-device test.
- Do not label the project multiplayer-ready or APK-ready until those parts exist and are verified.
