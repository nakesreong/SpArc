# SpArc — Semicircle FSM Rotation, Action Combat Camera & Cooldown HUD

**Version:** 2.9.1  
**Authors:** Gemini (Tiger) & Anya (5cr3am1ng5oul)  
**Compatibility:** World of Warcraft: Retail / Midnight (`12.0.1`, `12.1.5`, `12.1.7`) & The War Within (`11.2.7`)  
**Source Repository:** [https://github.com/nakesreong/SpArc](https://github.com/nakesreong/SpArc)  
**License:** MIT

---

## Overview

**SpArc** (*Spell Arc*) is a modular, data-driven Finite State Machine (FSM) rotation visualizer, cooldown tracker, dual-direction castbar, SpellBook wrapper macro generator, and standalone Action Combat Camera (Mouselook) suite for World of Warcraft.

Unlike traditional rotation helpers that hardcode thousands of lines of rigid Lua class scripts, **SpArc** compiles human-readable **Markdown (`.md`) pseudocode profiles** directly in-game:

* **Zero Hardcoded Class Logic:** Every spell definition, SpellID list, resource cost/gain, target debuff stack rule, channel protection policy, defensive save, offensive burst cooldown, and priority transition is compiled live from editable `.md` text.
* **World of Warcraft 12.x (Midnight) Ready:** Built from the ground up with safe `issecretvalue()` guards and native `C_AssistedCombat` / `C_Spell` integration, preventing secret-value taint errors in modern combat restrictions.
* **Dynamic Keybind Resolution:** Automatically resolves hotkeys across standard Blizzard Action Bars, **Bartender4** (`BT4Button`), **ElvUI**, and Mouselook click-casting slots (`M1`, `M2`, `SM1`, `SM2`, `CM1`, `CM2`, `AM1`, `AM2`).
* **Modular ElvUI-Style Control Center:** Every subsystem operates as an independent module with its own dedicated configuration tab, master enable toggle, and live on-screen preview (`/sparc`).
* **Bilingual Interface:** Instant one-click switching between **English (`EN`)** and **Russian (`RU`)** directly in the top header bar.

---

## Architecture & Modules

### 1. Rotation Presets (55 Built-In Profiles)
Ships with **55 pre-built rotation presets** covering all **13 World of Warcraft classes** (PvE / Mythic+ Cleave, Raid Single-Target Boss, PvP Arena/BG, Delves, and Hero Talent variations):
* **AUTO Mode:** Automatically switches between PvE, Raid Boss, and PvP presets based on your current instance, encounter, or arena state.
* **MANUAL Mode:** Lock any built-in or custom preset for specialized encounters, speedruns, or testing.
* **Custom Presets:** Create, duplicate, customize, or delete unlimited presets per class directly in the UI.

### 2. Markdown (`.MD`) Pseudocode Editor & AI Prompt Generator
A full in-game code editor that compiles `.md` rotation rules on the fly without reloading the UI:
* **Live FSM Compiler:** Parses `SPELL_BOOK`, `CHANNEL_POLICY`, `TRACKERS`, `EMERGENCY_SAVE`, and `ROTATION_QUEUE` blocks into an executable priority queue.
* **Built-In AI Prompt Generator:** Click **AI Prompt (Ctrl+C)** to copy a complete 6-section compiler specification prompt. Paste it into **Gemini**, **ChatGPT**, or **Claude** alongside any **Icy Veins** or **Wowhead** class guide, and paste the generated `.md` code straight back into SpArc.

### 3. Semicircle Rotation Arc (Predictive Queue)
Displays your upcoming spell rotation along a customizable semicircle arc above your character:
* **Primary Slot #1 (`10 o'clock`):** Enlarged, high-visibility active recommendation with live keybind badge, radial GCD/cooldown sweep, and proc glow.
* **Predictive Queue (`Slots #2 to #6`):** Simulates upcoming GCD state transitions—tracking virtual cooldowns, charge consumption, DoT application, target debuff stacks, and resource generation/spending across the next 3 to 6 steps.
* **Press Bounce Animation:** Optional tactile scale feedback (`-20% -> +20%`) on the exact pressed spell icon when cast.
* **Full Geometry Control:** Customize arc radius, spread angle (`60°` to `180°`), vertical offset, primary/queue icon scales, and queue length.

### 4. Defensive Saves & Offensive Cooldowns Wings
Flanks your central HUD with dedicated cooldown tracking wings driven by your `.md` preset:
* **Left Wing (`TRACK_SAVES`):** Tracks up to 4 defensive cooldowns. Ready abilities display a crisp green border; abilities on cooldown desaturate with a precision cooldown spiral and timer.
* **Right Wing (`TRACK_CDS`):** Tracks up to 4 major offensive/burst cooldowns with golden readiness borders.
* **Center Emergency Save Alert (`RETURN EMERGENCY`):** Displays a high-priority central alert when player health drops below your configured HP threshold (`15%` to `50%`) and a defensive save is ready.

### 5. Dual-Direction Castbar & Channel Clip Advisor
A precision castbar engineered for caster and melee-weaver specs:
* **Normal Casts:** Fill from **Left to Right** (`0% -> 100%`).
* **Channeled Spells:** Drain from **Right to Left** (`100% -> 0%`).
* **Smart Channel Interrupt Detection:** Distinguishes between **protected channels** (`PROTECT_CHANNEL`, e.g., *Ray of Frost*, *Void Torrent* — displays `[DO NOT CLIP]`) and **interruptible filler channels** (`INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY`, e.g., *Mind Flay* — flashes `CLIP FILLER -> PRESS [KEY]!` the instant a higher-priority spell comes off cooldown or procs).

### 6. Standalone Action Combat Camera (Mouselook)
A lightweight, zero-bloat replacement for external action-camera addons that locks camera mouselook during gameplay and eliminates the stuck center hardware cursor bug in WoW 12.x:
* **Configurable Camera & Interact Keybinds:**
  * **Unlock Cursor on Hold (`onHold`):** Temporarily frees the mouse cursor while held (default `G`) and immediately relocks on release.
  * **Toggle Camera Lock (`onPress`):** Permanently unlocks or locks the camera on press (default `` ` ``).
  * **Target / NPC Interact Key (`INTERACTTARGET`):** Configurable interact keybind that automatically adapts to your character's native game binding (e.g., `E` or `C`).
* **Crosshair & `@mouseover` / `@cursor` Synchronization:** Renders a customizable center reticle (with live preview while the Combat Camera tab is open) and synchronizes `CursorCenteredYPos` and deferred `CursorFreelookCentering` so `@mouseover` and `@cursor` macros hit the exact crosshair height without exposing the OS hardware cursor.
* **Direct Mouselook Click-Casting:** Routes `LMB`, `RMB`, and `Shift / Ctrl / Alt + LMB/RMB` directly to `Bartender4` (`:Keybind`) or `ActionButton1..8` while camera mouselook is active.
* **Smart UI Auto-Unlock:** Automatically frees the cursor whenever bags, maps, quest dialogs, merchant windows, settings panels, or ground-targeted AoE reticles (`SpellIsTargeting()`) are open.

### 7. SpellBook Telemetry & Rotation Debugger
An integrated diagnostic suite for rotation authors and theorycrafters:
* Compares live player SpellBook state, action bar slot assignments, and cooldown/usability flags against the active FSM evaluation tree.
* Captures manual or automated diagnostic snapshots for rapid troubleshooting.

### 8. Per-Character Profiles & Automatic Keybind Conflict Resolution
Full multi-character profile management modeled after ElvUI and Plater:
* **Per-Character Profiles:** Automatically creates and maintains an isolated profile (`Character - Realm`) for each character alongside a shared `Default` profile. Supports one-click profile switching, copying settings between profiles, resetting, and deletion.
* **Automatic Conflict Detection:** Monitors `UPDATE_BINDINGS` in real time. If any key used by SpArc (`onHold`, `onPress`, or `Interact`) is bound to an action bar slot or command in the game's Keybindings menu or another addon (such as Bartender4), SpArc automatically clears its internal bind to prevent keybind collisions.

### 9. SpellBook Wrapper Macro Generator (`/sparc macro`)
Automatically scans your active SpellBook (**Class** and **Specialization** tabs) and generates target-safe wrapper macros (`#showtooltip`, `/stopmacro [flying]`, `/cast [@target] SpellName`):
* Names Class spells `<class_initial><N>` (`m1, m2...`) and Spec spells `<spec_initial><class_initial><N>` (`fm1, sp1...`).
* Fills **Character Macros** (`30` slots) first and automatically overflows into **General Account Macros** (`120` slots) without ever overwriting existing user macros.

---

## Slash Commands

* `/sparc` or `/sa` — Open the SpArc Control Center.
* `/sparc macro` — Open the SpellBook Wrapper Macro Generator tab.
* `/sparc cam` — Open the Action Combat Camera configuration tab.
* `/sparc profiles` — Open the Per-Character Profiles tab.
* `/sparc fixcursor` — Flush hardware cursor and freelook centering CVars.
* `/sparc test` — Toggle live HUD preview mode (`ON` / `OFF`).
* `/sparc debug` — Capture a telemetry snapshot and open the Debugger tab.
* `/sparc en` | `/sparc ru` — Switch interface language between English and Russian.
* `/sparc auto` | `/sparc pve` | `/sparc boss` | `/sparc pvp` — Switch active rotation mode.

---

## Source Code & Issue Tracker

* **GitHub Repository:** [https://github.com/nakesreong/SpArc](https://github.com/nakesreong/SpArc)
