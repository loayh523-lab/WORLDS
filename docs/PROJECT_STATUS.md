# WORLDS — Project Status

Last updated: 2026-11-06

## Current milestone: first 3D gameplay slice

### Implemented in the repository
- Godot 4 project configuration with the GL Compatibility renderer, landscape mobile orientation, and keep-screen-on setting.
- Procedural rolling terrain with collision, a winding river valley, and a deterministic forest using MultiMesh instances.
- A stylized humanoid placeholder character with a basic walk cycle.
- Third-person orbit camera, keyboard movement, jump, touch controls, and camera drag.
- Basic day/night lighting and sky-color cycle (20 real minutes per in-game day).
- Relaxed early survival needs: food, water, and rest decrease slowly.
- Drink from the river, gather limited wild berries, and rest at the campsite to advance time to morning.
- First World Memory experiment: awaken the memory stone to reveal a glowing trail across the landscape.
- Local autosave and restore for player position, survival needs, world time, berry servings, and memory activation.
- GitHub Actions headless import and short scene smoke test. Main-branch checks have passed; the autosave branch will be verified by its pull-request check.

### Not implemented yet
- Final character models, polished animations, customization, and production-quality art.
- Detailed terrain materials, grass, rocks, water effects, and multiple finished biomes.
- Animals, fish, weather, seasons, and deeper environmental simulation.
- Full survival balance, inventory, crafting, flexible non-grid building, and permanent player structures.
- Persistent, shared world-memory effects and the complete progression design.
- Accounts, cross-device cloud saves, matchmaking, LAN, and online multiplayer.
- Android export configuration, APK build, and physical-device performance testing.
- iOS and Windows builds.

## Next milestones

1. **Validate this branch:** pass the Godot import and scene smoke test with the local-save changes.
2. **Device validation:** import and run the project in Godot on Android; adjust touch layout, camera feel, and performance on the target phone.
3. **World presentation:** improve terrain materials, shoreline, vegetation variety, trees, rocks, and the first distinct secondary area.
4. **Core loop:** make exploration lead to meaningful decisions and discoveries rather than repetitive resource collection.
5. **World Memory:** evolve the current glowing-trail proof of concept into a small loop where a meaningful player action changes a place and leaves a trace that can guide or help later visitors.
6. **Living world:** add a few animal behaviors and weather changes, then assess performance before scaling up.
7. **Survival and construction:** balance food, water, rest, inventory, and intuitive non-grid building so these support exploration instead of becoming chores.
8. **Multiplayer design:** prototype LAN and online architecture only after the single-player slice is stable.
9. **Android release path:** configure export templates and Android tooling, then test installation, frame rate, touch controls, thermals, and memory use on real devices.

## Development rules

- Android is the first target; touch input and performance matter from the start.
- Keep the presentation natural and fully 3D, not voxel or pixel-art.
- Prefer a small number of polished, testable systems over many unfinished menus.
- A passing CI smoke test is not the same as a real-device test.
- Do not label the project multiplayer-ready or APK-ready until those parts exist and are verified.
