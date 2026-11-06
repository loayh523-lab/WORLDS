# WORLDS

An original open-world adventure project built with Godot 4, targeting Android first and PC later.

## Current prototype

The repository contains a first playable-scene prototype with:
- Procedurally generated rolling terrain.
- A winding river valley and a small forest.
- Instanced tree meshes to reduce scene-object overhead.
- A third-person placeholder character and follow camera.
- Keyboard movement, touch movement buttons, jump, and camera drag on the upper-right area of the screen.
- A basic day/night cycle (one in-game day is 20 real minutes).
- Godot 4.3-compatible project settings using the GL Compatibility renderer.

This is an early prototype, not the complete game. The character art, polished environments, animals, survival systems, building, save data, multiplayer, and production assets are not implemented yet.

## Open the project

1. Install Godot 4.3 or a compatible Godot 4 release.
2. Download this repository as a ZIP or clone it.
3. In Godot, choose **Import** and select the folder containing `project.godot`.
4. Open `scenes/main.tscn` and press **Run Project**.

## Controls

- Keyboard: WASD to move, Space to jump.
- Touch: use the on-screen directional buttons and Jump button.
- Camera: drag in the upper-right area of the screen. On desktop, hold the right mouse button and move the mouse.

## Automated checks

GitHub Actions runs a headless project import and a short main-scene smoke test on pushes and pull requests to `main`. This checks project loading; it is not an Android build or a substitute for testing on a real phone.

## Android status

No Android APK has been built or tested yet. Android export still needs to be configured and tested after the scene is validated in Godot and on a real device.

See [Project Status](docs/PROJECT_STATUS.md) for implemented features and the next development milestones.
