# WORLDS — Project Status

Last updated: 2026-11-06

## Current milestone: Android Wi-Fi co-op playtest build

### Implemented
- Godot 4.3 project using the GL Compatibility renderer for Android.
- 512 × 512 metre procedural starter region split into four terrain tiles. The planned 4 × 4 km streamed world is not implemented.
- River valley, forest, grass, rocks, shoreline details, day/night lighting, sky and simple drifting clouds.
- Third-person player, mobile joystick, multitouch camera drag, sprint, jump, interaction and editable touch-button layout.
- Starter village, simple NPCs and wildlife, gathering, survival needs, crafting/building, World Memory discovery and local autosave.
- Main menu and project logo, saved player name, in-game menu shortcut, responsive menu sizing, settings and navigation.
- Journey objectives now show live distance to the river crossing, nearest villager and memory stone; gameplay smoke test verifies the waypoint distance.
- Four selectable explorer outfit color styles (Forest Scout, River Wanderer, Amber Trail, Midnight Pine), saved locally and synchronized to other LAN players.
- Quality presets, FPS caps, camera controls, touch sizing/opacity, master volume and performance readout.
- Direct Wi-Fi LAN host/join using ENet/UDP port 24560. The host displays and can copy its local IP.
- Player movement and display names plus basic shared resources/building state synchronize.
- Session capacity is configured for 1 host + up to 7 guests; the current automated multiplayer smoke test exercises one host and one guest.

### Latest validation
- Latest source commit tested: `bb552632d57669feea869181e2d619b96309feaa`.
- Godot 4.3 import/parse, main-scene, gameplay, persistence, LAN host/client, movement, shared gathering, outfit synchronization and journey waypoint checks: **passed** in GitHub Actions run [42245921756](https://github.com/loayh523-lab/WORLDS/actions/runs/42245921756).
- Android debug APK export for this exact commit: **in progress** at the time of this update.
- The previous successful debug APK was 24,051,277 bytes as a workflow artifact ZIP; this is not the installed APK size.
- No physical Android install or two-phone Wi-Fi test has been performed.

### Still not complete / not verified
- The planned 4 × 4 km world and dynamic chunk streaming.
- Final production-quality character, animal, village and environment art.
- Deeper NPC schedules, expanded wildlife/ecology, weather, seasons, audio and fuller gameplay progression.
- Persistent hosted worlds and robust reconnect/session recovery.
- Public server browser, internet matchmaking, accounts and dedicated online servers are deferred; current scope is Wi-Fi LAN only.
- Real two-phone Wi-Fi testing and device-specific performance, thermal, battery and touch profiling.
- Final release signing and store-ready release build.

## APK content audit — 2026-11-06

The APK built from commit `bb552632d57669feea869181e2d619b96309feaa` was downloaded and inspected directly:
- APK file size: 24,292,960 bytes (about 23.17 MiB).
- GitHub Actions artifact ZIP: 24,051,994 bytes (contains the APK).
- APK contains 92 entries; the Godot ARM64 native library is the dominant payload.
- Project source tree contains only 17 tracked files. The game payload in `assets/` is only the original SVG logo; there is no imported library of production 3D character, environment, vegetation, animal, texture, animation or audio assets.
- The current world is primarily generated from primitive meshes and procedural code. This is a functional prototype, not the agreed high-quality visual target.
- Do not interpret APK size as evidence of visual completeness. Do not inflate package size with dummy or duplicate files.

Required art/content milestone before calling the game visually advanced:
1. Create and integrate a coherent, original 3D player character and real animation set.
2. Replace placeholder vegetation, rocks, buildings and wildlife with consistent quality 3D assets and proper materials.
3. Add terrain materials, foliage variation, water, sky/weather effects and environment audio.
4. Profile texture/model memory and APK size on Android; use compressed textures, LODs and asset bundles appropriately.
5. Verify the visual result in actual Android gameplay, not only automated scene tests.

## Test APK
A debug test APK was generated from an earlier tested source commit. The newest source includes journey waypoint guidance and is being rebuilt. Any APK shared from this project is a prototype for installation/playtesting, not a finished or store-ready release. The host phone must remain in the game during a Wi-Fi session; closing the host ends the session.
