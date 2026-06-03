# implementation_plan.md

## 1. Project Architecture
The game will use a 2D side scrolling perspective using Godot 4.6.x features. We will structure the game around independent, reusable scenes. Global data like player health, data cookies, and unlocked upgrades will be managed by an Autoload singleton script.

## 2. Core Systems
* Player Controller: We will use a CharacterBody2D node for the player. A state machine script will handle states like idle, run, jump, fall, attack, and abilities.
* Combat and Interaction: We will use Area2D nodes for hitboxes (the cursor sword) and hurtboxes. The downward strike bounce will use raycasts to detect enemies below the player.
* World Building: Levels will be built using TileMapLayer nodes. The aesthetic will use glitch effects and bright neon colors on dark backgrounds via CanvasItem shaders.
* Upgrades: The browser extensions will be boolean flags in our global state. When unlocked, they will enable new states in the player state machine (like the VPN Tunnel dash).
* Scene Management: We will create a portal system to load and unload different browser zones (social media feed, digital archive, deep web) to keep memory usage low.
* Death and Respawn (The No Internet Protocol): When health reaches zero the player is sent to an offline screen. Here they play an endless runner mini game where a crocodile jumps over cacti. The player must survive long enough to find the WiFi Password to reconnect. Collision with cacti has a configurable toggle: either reset all the way to 0 meters and reboot, or deduct a set meter penalty (e.g. 50 meters) with brief visual flashing invincibility frames. The scene utilizes a customizable, dual-layer parallax scrolling background (slow far cyber-stars and faster medium floating folder panes) that reacts dynamically to the runner's speed to deliver a highly premium cybernetic sense of depth.
* Economy: Data Cookies are collected in the main world from defeated foes and during the offline crocodile game. They are used to buy map updates, health items, and hints.
* The Helper System: A Bluetooth companion character that the player can buy hints from using Cookies.

## 3. Data and Save System
We will use a JSON or ConfigFile system to save the game. It will track the player's current zone, total data cookies, boss defeat status, and unlocked memory logs.

## 4. Story and Glitch Events
* The Alt F2 Glitch: A major story event where an attempt to close a window goes wrong. The player presses Alt F2 instead and it corrupts exactly half of the screen. The player must use the Bluetooth helper to find a way to fix this visual glitch.

## 5. Controls and Tutorial System
* Input Controls: Standardized keyboard bindings using WASD for movement (A/D for horizontal, W/S for looking up/down and crouching) and Space bar for jumping. Active features use Shift (Dash) and Tab (Shield).
* Look Tracking: Bi-directional gaze states (`is_looking_up`, `is_looking_down`) track player intent for crouching stealth, downward plummets, and future look-based interactions (such as camera offsets or vertical attacks).
* The Tutorial: A dedicated starting scene introduces players to the controls, upgrades, and currency mechanics in a safe practice environment prior to loading the main zones.

## 6. Script Design Guidelines
* Modular Exports: All script tuning parameters (movement speeds, gravity, jump force, durations, cooldowns, damage, and health stats) must be declared with `@export` keywords. This permits modular editing directly inside the Godot Inspector without modifying core codebase files.
