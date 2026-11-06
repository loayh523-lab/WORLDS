# WORLDS — Project Status

Last updated: 2026-11-06

## Current milestone: first 3D gameplay slice

### Implemented in the repository
- Godot 4 project configuration with GL Compatibility renderer, landscape mobile orientation, and keep-screen-on setting.
- Procedural rolling terrain with collision, a winding river valley, and a deterministic forest using MultiMesh instances.
- A stylized humanoid placeholder character with a basic walk cycle.
- Third-person orbit camera, keyboard movement, jump, touch controls, and camera drag.
- Basic day/night lighting and sky-color cycle (20 real minutes per in-game day).
- Relaxed early survival needs: food, water, and rest decrease slowly.
- Drink from the river, gather limited wild berries, and rest at the campsite to advance time to morning.
- First World Memory experiment: awaken the memory stone to reveal a glowing trail across the landscape.
- Local autosave and restore for player position, survival needs, world time, berry servings, and memory activation.
- GitHub Actions headless import and short scene smoke test.
- Android debug APK workflow; successful CI export has been recorded, but physical-device testing is still required.

### Not implemented yet
- Final character models, polished animations, customization, and production-quality art.
- Detailed terrain materials, grass, rocks, water effects, and multiple finished biomes.
- Animals, fish, weather, seasons, and deeper environmental simulation.
- Full survival balance, inventory, crafting, flexible non-grid building, and permanent player structures.
- Persistent, shared world-memory effects and the complete progression design.
- Accounts, cross-device cloud saves, matchmaking, LAN, and online multiplayer.
- Physical Android installation, performance, thermal, and touch-control testing.
- iOS and Windows builds.

## Next milestones

1. Validate the local-save branch with the Godot import and scene smoke test.
2. Build a fresh APK containing local saving and verify installation and controls on a physical Android device.
3. Improve terrain materials, shoreline, vegetation variety, trees, rocks, and the first distinct secondary area.
4. Make exploration lead to meaningful decisions and discoveries rather than repetitive resource collection.
5. Evolve World Memory into a small loop where a meaningful player action changes a place and leaves a trace that can guide or help later visitors.
6. Add a few animal behaviors and weather changes, then assess performance before scaling up.
7. Balance food, water, rest, inventory, crafting, and intuitive non-grid building so these support exploration instead of becoming chores.
8. Prototype LAN and online architecture only after the single-player slice is stable.
9. Configure iOS and Windows builds after the Android experience is stable.

## Development rules

- Android is the first target; touch input and performance matter from the start.
- Keep the presentation natural and fully 3D, not voxel or pixel-art.
- Prefer a small number of polished, testable systems over many unfinished menus.
- A passing CI smoke test is not the same as a real-device test.
- Do not label the project multiplayer-ready or release-ready until those parts exist and are verified.
