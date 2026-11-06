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
- Quality presets, FPS caps, camera controls, touch sizing/opacity, master volume and performance readout.
- Direct Wi-Fi LAN host/join using ENet/UDP port 24560. The host displays and can copy its local IP.
- Player movement and display names plus basic shared resources/building state synchronize.
- Session capacity is configured for 1 host + up to 7 guests; the current automated multiplayer smoke test exercises one host and one guest.

### Latest validation
- Latest source commit tested: `16201742fc4b5d2223cb4c4321e606d1ff1f7d46`.
- Godot 4.3 import/parse, main-scene, gameplay, persistence, LAN host/client, movement, shared gathering and player-name checks: **passed** in GitHub Actions run [42244508777](https://github.com/loayh523-lab/WORLDS/actions/runs/42244508777).
- Android debug APK export: **passed** in GitHub Actions run [42244508907](https://github.com/loayh523-lab/WORLDS/actions/runs/42244508907).
- Debug APK size: 24,288,864 bytes (about 23.2 MiB).
- The APK was structurally checked as a valid Android package. It has not been installed or physically tested on an Android phone.

### Still not complete / not verified
- The planned 4 × 4 km world and dynamic chunk streaming.
- Final production-quality character, animal, village and environment art.
- Deeper NPC schedules, expanded wildlife/ecology, weather, seasons, audio and fuller gameplay progression.
- Persistent hosted worlds and robust reconnect/session recovery.
- Public server browser, internet matchmaking, accounts and dedicated online servers are deferred; current scope is Wi-Fi LAN only.
- Real two-phone Wi-Fi testing and device-specific performance, thermal, battery and touch profiling.
- Final release signing and store-ready release build.

## Test APK
A debug test APK was generated from the latest tested source commit. It is a prototype for installation/playtesting, not a finished or store-ready release. The host phone must remain in the game during a Wi-Fi session; closing the host ends the session.
