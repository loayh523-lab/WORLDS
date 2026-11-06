# WORLDS — Project Status

Last updated: 2026-11-06

## Current milestone: Android-first playable prototype

### Implemented
- Godot 4.3 project using the GL Compatibility renderer for broad Android support.
- 512 × 512 metre procedural starter region, split into four 256m terrain tiles (not the planned 4 × 4 km streamed world).
- River valley, forests, grass, rocks, shoreline details, day/night lighting, sky and simple drifting clouds.
- Third-person player, mobile virtual joystick, multitouch camera drag, sprint, jump, interact, and editable touch-button layout.
- Starter village, simple NPCs, wildlife, gathering, berries, survival needs, crafting/building, World Memory discovery, and local autosave.
- Main menu with project logo, player name, continue, Wi-Fi co-op, and settings.
- Quality presets, FPS caps, camera controls, touch sizing/opacity, master volume, and live performance readout.
- Direct Wi-Fi LAN host/join using ENet/UDP port 24560.
- LAN session capacity configured for 1 host + up to 7 guests. Player names are synchronized; basic player movement and shared world state are replicated.
- Wi-Fi host IP display and copy control.

### Current Wi-Fi test flow
1. Both Android phones join the same Wi-Fi network.
2. First phone: Play with a Friend → Create World → Copy Host IP.
3. Second phone: Play with a Friend → enter IP → Join World.
4. Both enter the same locally hosted session.

### Not complete / not verified
- The 4 × 4 km world and dynamic chunk streaming.
- Final production-quality character, animal, village, and environment art.
- Deeper NPC schedules, expanded wildlife/ecology, weather, seasons, and audio.
- Full inventory/item-use progression and persistent hosted worlds.
- Public server browser, internet matchmaking, accounts, and dedicated online servers (explicitly deferred).
- Real two-phone Wi-Fi testing, device-specific performance/thermal profiling, and final release signing.
- Latest menu/LAN changes still require fresh Godot and Android CI validation before an APK can be shared.

## Build honesty
Previous CI runs passed for earlier commits, including gameplay/LAN smoke checks and Android debug export. Those results do not validate the latest commits. No physical two-phone test has been performed. The project remains a prototype and the current map is 512 × 512 metres.
