# WORLDS

An original open-world adventure project built with Godot 4, targeting Android first and PC later.

## Current playable slice

The repository contains an early 3D gameplay prototype:
- Procedural rolling terrain, a winding river valley, and a small forest.
- Instanced tree meshes to keep the early environment lightweight.
- A stylized humanoid placeholder with a basic walk cycle and a third-person orbit camera.
- Keyboard and touch movement, jump, camera drag, and interaction.
- A gradual day/night cycle (one in-game day lasts 20 real minutes).
- Slow survival-need changes for food, water, and rest.
- Early interactions: drink from the river, gather limited wild berries, and rest at a campsite to reach morning.
- The first **World Memory** experiment: awaken a memory stone to reveal a glowing trail through the landscape.
- Local autosave for player position, needs, world time, remaining berries, and the awakened memory state.

These systems are prototypes, not a finished game. Production character art, polished environments, animals, weather, multiple finished biomes, inventory, crafting, flexible building, persistent shared world changes, and multiplayer remain future work.

## Open the project

1. Install Godot 4.3 or a compatible Godot 4 release.
2. Download this repository as a ZIP or clone it.
3. In Godot, choose **Import** and select the folder containing `project.godot`.
4. Open `scenes/main.tscn` and press **Run Project**.

## Controls

- Keyboard: WASD to move, Space to jump, E to interact.
- Touch: use the on-screen directional buttons, Jump, and Use.
- Camera: drag in the upper-right area of the screen. On desktop, hold the right mouse button and move the mouse.

## Saving

Progress is stored locally in Godot's `user://worlds_save.cfg`. The prototype autosaves periodically and when the app loses focus or closes. This local save does not sync between devices or support online accounts.

## Automated checks

GitHub Actions runs a headless project import and a short main-scene smoke test on pushes and pull requests to `main`. A successful check confirms that the project imports and the scene starts in the CI environment. It does not prove performance or usability on a physical phone.

## Android status

A debug APK can be produced by the Android workflow. It is a test build, not a store-ready release. Installation, performance, and controls still need physical-device testing.

See [Project Status](docs/PROJECT_STATUS.md) for implemented features and the next milestones.
