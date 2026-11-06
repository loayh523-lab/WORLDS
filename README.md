# WORLDS

An original 3D open-world adventure prototype built with Godot 4.3, targeting Android first.

## Current prototype
- Procedural 512 × 512 metre starter region with hills, river valley, forest, dryland and snowy highland areas.
- Third-person player with mobile joystick, independent camera drag, sprint, jump and interaction controls.
- Stylized player details, simple NPCs and wildlife, village landmarks, day/night cycle and drifting cloud layer.
- Survival needs, berry/resource gathering, crafting, building, local autosave and the World Memory discovery.
- Main menu, player naming, logo, settings, performance presets, FPS caps, camera and touch-control customization.
- Experimental Wi-Fi co-op: one phone hosts and other phones join by entering the host's local IP. ENet/UDP, player movement/name synchronization and basic shared world state.
- Session capacity configured for 1 host + up to 7 guests; physical testing is still pending.

## Play together over Wi-Fi
1. Connect both Android phones to the same Wi-Fi network.
2. On the host phone choose **PLAY WITH A FRIEND** → **CREATE WORLD**.
3. Press **COPY HOST IP**.
4. On the second phone choose **PLAY WITH A FRIEND**, enter the host IP, then press **JOIN WORLD**.
5. See [the Arabic Wi-Fi playtest guide](docs/LAN_PLAYTEST_AR.md) for connection troubleshooting.

This is direct local-network play only. Public server lists, internet matchmaking, dedicated servers, accounts, and cloud-hosted persistent worlds are deferred. The host phone must remain in the session; closing the host ends the session.

## World and prototype limits
The current map is 512 × 512 metres, split into four terrain tiles. The planned 4 × 4 km world and dynamic streaming are not implemented. The project is not a finished or store-ready game. Final art, deeper NPC/animal behaviour, weather, seasons, sound, wider gameplay progression, and physical-device validation remain outstanding.

## Performance
- Android-first GL Compatibility renderer.
- Quality presets and selectable 20/30/45/60/90/120 FPS caps. A cap is not a guarantee of achieved FPS.
- The target performance on a Helio G99 has not been measured on a physical device.
- See [performance and size targets](docs/PERFORMANCE_AND_SIZE_TARGETS.md).

## Open the project
1. Install Godot 4.3.
2. Download or clone this repository.
3. Import the folder containing `project.godot`.
4. Open `scenes/main.tscn` and run the project.

The GitHub Actions workflow can validate project import, gameplay/LAN smoke tests, and export an Android debug APK. A successful CI build does not prove real-device launch, performance, or Wi-Fi connectivity.
