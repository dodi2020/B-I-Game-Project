# task.md

## Core Foundation
- [x] Initialize Godot project and set window resolution for 2D pixel art.
- [x] Create folder structure for scripts, scenes, assets, and UI.
- [x] Setup the Global GameState Autoload.

## Player Mechanics
- [x] Create Player scene with CharacterBody2D.
- [x] Code basic physics (gravity, run, jump).
- [x] Add basic placeholder animations.

## Combat System
- [x] Create Health component for player and enemies.
- [x] Implement primary cursor sword attack (hitbox setup).
- [x] Implement downward strike and bounce logic using raycasts.

## Enemy AI
- [x] Create base Enemy scene.
- [x] Build patrol logic for the standard computer virus enemy.
- [x] Add death logic and Data Cookie drop spawning.

## Pickups and Interactables
- [x] Create Data Cookie pickup scene.
- [x] Create Health Restore pickup scene.
- [x] Create Upgrade/Extension pickup scene (supports VPN Tunnel, Ad Blocker, Incognito Cloak, Auto Fill).

## Upgrade Implementation
- [x] VPN Tunnel: Implement dash movement logic.
- [x] Ad Blocker: Implement temporary invincibility shield.
- [x] Incognito Cloak: Implement enemy detection avoidance.
- [x] Auto Fill: Implement pull logic for distant items.

## World and Level Design
- [x] Setup base TileMapLayer for the first zone.
- [x] Create zone transition areas to move between rooms.
- [x] Implement a dynamic camera that follows the player but respects room bounds.

## Controls and Tutorial Setup
- [x] Create a playable Tutorial Level scene guiding player mechanics.
- [x] Configure boot settings to launch the Tutorial scene first.
- [x] Standardize movement input using WASD and Space bar controls.
- [x] Code bi-directional look-checking (W/S) states for future gameplay use.
- [x] Refactor Player constants to modular @export variables for Inspector tuning.

## The Offline Mini Game
- [x] Create a separate scene for the No Internet screen.
- [x] Build the endless runner mechanics with the crocodile and cacti.
- [x] Add logic to spawn and collect Cookies in this mode.
- [x] Add the WiFi Password goal to trigger a respawn back to the main game.

## UI, NPC, and Story
- [ ] Build the main HUD (Health, Data Cookies).
- [ ] Create the Memory Log UI to read story files.
- [ ] Build a basic pause menu.
- [ ] Create the Bluetooth helper NPC scene.
- [ ] Implement a shop menu where Cookies can buy hints and items.
- [ ] Code the Alt F2 half screen glitch using a CanvasLayer and custom shader.
- [ ] Create the quest logic to fix the broken screen with the helper.
- [ ] Create a Keybind settings menu for custom keyboard layouts (remapping controls).
