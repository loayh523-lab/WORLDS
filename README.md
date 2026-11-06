# WORLDS

An original open-world adventure project built with Godot 4, targeting Android first and PC later.

## Current prototype

The repository contains an early 3D playable-scene prototype:
- Procedural rolling terrain, a winding river valley, and a small forest.
- Instanced tree meshes to reduce scene-object overhead.
- A stylized humanoid placeholder with a basic walk cycle and a separate orbit camera.
- Keyboard movement, jump, touch movement controls, and camera drag.
- A basic day/night cycle (one in-game day is 20 real minutes).
- Early survival interactions: drink from the river, gather wild berries, and rest at a campsite.
- A first experiment with the **World Memory** idea: awaken a memory stone to reveal a glowing trail through the landscape.

These systems are prototypes, not a finished game. The final character art, polished environments, animals, weather, deeper survival, building, persistent world changes, saves, and multiplayer are not implemented yet.

## Open the project

1. Install Godot 4.3 or a compatible Godot 4 release.
2. Download this repository as a ZIP or clone it.
3. In Godot, choose **Import** and select the folder containing `project.godot`.
4. Open `scenes/main.tscn` and press **Run Project**.

## Controls

- Keyboard: WASD to move, Space to jump, E to interact.
- Touch: use the on-screen directional buttons, Jump, and Use.
- Camera: drag in the upper-right area of the screen. On desktop, hold the right mouse button and move the mouse.

## Automated checks

GitHub Actions runs a headless project import and a short main-scene smoke test on pushes and pull requests to `main`. A successful check confirms that the project imports and the scene starts in the CI environment. It does not prove performance or usability on a physical phone.

## Android status

No Android APK has been built or tested yet. Android export still needs to be configured and tested on the target device.

See [Project Status](docs/PROJECT_STATUS.md) for implemented features and next milestones, and [Gameplay Vision (Arabic)](docs/GAMEPLAY_VISION_AR.md) for the evolving game identity.
