# WORLDS

An original open-world adventure project built with Godot 4, targeting Android first and PC later.

## Current gameplay prototype

- Procedural rolling terrain, winding river valley, and a small instanced forest.
- Stylized humanoid character with a basic walk cycle and third-person camera.
- Keyboard movement, multitouch movement controls, jump, interaction, and camera drag.
- Basic day/night cycle.
- Survival interactions: drink from the river, gather wild berries, and rest at camp.
- World Memory experiment: awaken a stone to reveal a glowing trail.
- Local autosave for position, survival values, world time, berries, and memory activation.
- Experimental two-phone LAN co-op: one device hosts and one joins over the same Wi-Fi; player positions and basic shared world interactions synchronize through ENet/UDP.
- Quality presets and selectable frame-rate caps, with an adaptive low-cost profile.

This is still a development prototype. It is not a finished or store-ready game. The LAN path needs testing on two physical phones, and the character, environment, interaction design, and survival systems still need substantial work.

## LAN co-op test

1. Connect both Android phones to the same Wi-Fi network.
2. On the first phone, press **CREATE WORLD** and note the displayed local IP address.
3. On the second phone, enter that IP and press **JOIN WORLD**.
4. Move both players and test shared berries, the campsite, and World Memory.

See [LAN playtest guide](docs/LAN_PLAYTEST_AR.md) for conditions and current limits.

## Performance and size targets

- Android initial installation target: at most 700 MB.
- Optional world packs are intended to remain separate from the initial installation; the planning ceiling for installed optional content is 2 GB.
- Frame-rate caps: 20, 30, 45, 60, 90, and 120 FPS. These are caps, not guaranteed frame rates.
- Compatibility renderer with quality options based on object density, shadows, and fog.

See [Performance and size targets](docs/PERFORMANCE_AND_SIZE_TARGETS.md). Optional downloadable world packs are not available yet.

## Open the project

1. Install Godot 4.3 or a compatible Godot 4 release.
2. Download this repository as a ZIP or clone it.
3. In Godot, choose **Import** and select the folder containing `project.godot`.
4. Open `scenes/main.tscn` and press **Run Project**.

## Android build status

The repository has an Android debug export workflow. CI export success only proves the package was produced; it does not prove that the app launches, stays responsive, or connects on physical phones. This LAN build is being validated separately. No test APK is being designated as the final game build.

