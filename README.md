# SpArc — Semicircle FSM Rotation, Action Combat Camera & Cooldown HUD

**Version:** 2.8.0  
**Authors:** Gemini (Tiger) & Anya (5cr3am1ng5oul)  
**Compatibility:** World of Warcraft: Retail / Midnight (`12.0.1`, `12.1.5`) & The War Within (`11.2.7`)  
**Source Repository:** [https://github.com/nakesreong/SpArc](https://github.com/nakesreong/SpArc)  
**License:** MIT

---

## Overview

**SpArc** (*Spell Arc*) is a modular, data-driven Finite State Machine (FSM) rotation visualizer, cooldown tracker, dual-direction castbar, and standalone Action Combat Camera (Mouselook) suite for World of Warcraft.

Unlike traditional rotation helpers that hardcode thousands of lines of rigid Lua class scripts, **SpArc** compiles human-readable **Markdown (`.md`) pseudocode profiles** directly in-game:

* **Zero Hardcoded Class Logic:** Every spell definition, SpellID list, resource cost/gain, channel protection policy, defensive save, offensive burst cooldown, and priority transition is compiled live from editable `.md` text.
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
* **Custom Presets:** Create, duplicate, and customize unlimited presets per class directly in the UI.

### 2. Markdown (`.MD`) Pseudocode Editor & AI Prompt Generator
A full in-game code editor that compiles `.md` rotation rules on the fly without reloading the UI:
* **Live FSM Compiler:** Parses `SPELL_BOOK`, `CHANNEL_INTERRUPT`, `TRACKERS`, `EMERGENCY_SAVE`, and `ROTATION_FSM` blocks into an executable priority queue.
* **Built-In AI Prompt Generator:** Click **AI Prompt (Ctrl+C)** to copy a structured specification prompt. Paste it into **Gemini** or **ChatGPT** alongside any **Icy Veins** or **Wowhead** class guide, and paste the generated `.md` code straight back into SpArc.

### 3. Semicircle Rotation Arc (Predictive Queue)
Displays your upcoming spell rotation along a customizable semicircle arc above your character:
* **Primary Slot #1 (`10 o'clock`):** Enlarged, high-visibility active recommendation with live keybind badge and proc glow.
* **Predictive Queue (`Slots #2 to #6`):** Simulates upcoming GCD state transitions—tracking virtual cooldowns, charge consumption, DoT application, and resource generation/spending across the next 3 to 6 steps.
* **Press Bounce Animation:** Optional tactile scale feedback (`-20% -> +20%`) when the recommended spell is cast.
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
* **Smart Channel Interrupt Detection:** Distinguishes between **protected channels** (`PROTECTED_CHANNELS`, e.g., *Void Torrent* — displays `[DO NOT CLIP]`) and **interruptible filler channels** (`INTERRUPTIBLE_CHANNELS`, e.g., *Mind Flay* — flashes `CLIP FILLER -> PRESS [KEY]!` the instant a higher-priority spell comes off cooldown or procs).

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

---

## Markdown (`.MD`) Pseudocode Example

```markdown
# TITLE: Priest: Shadow — PvE / Mythic+
# CLASS: PRIEST
# MODE: PVE

## SPELL_BOOK
SPELL TENTACLE_SLAM = ID:1227280,205385,457042 | NAME:"Shadow Crash","Tentacle Slam" | CD:15 | CHARGES:2 | INSANITY:+15 | DOTS:TRUE
SPELL VAMPIRIC_TOUCH = ID:34914 | NAME:"Vampiric Touch" | CD:0 | INSANITY:+6 | DOTS:TRUE
SPELL VOID_TORRENT = ID:263165 | NAME:"Void Torrent" | CD:45 | INSANITY:+35 | GRANTS_MFI:TRUE
SPELL DEVOURING_PLAGUE = ID:335467 | NAME:"Devouring Plague" | CD:0 | COST:50 | GRANTS_MFI:TRUE | SPENDER:TRUE
SPELL MIND_BLAST = ID:8092 | NAME:"Mind Blast" | CD:7.5 | CHARGES:2 | INSANITY:+12
SPELL SW_DEATH = ID:32379 | NAME:"Shadow Word: Death" | CD:10 | CHARGES:2 | INSANITY:+10 | EXECUTE:20
SPELL MIND_FLAY_INSANITY = ID:391403 | NAME:"Mind Flay: Insanity" | CD:0 | INSANITY:+12 | PROC:TRUE
SPELL MIND_FLAY = ID:15407 | NAME:"Mind Flay" | CD:0 | INSANITY:+12 | FILLER:TRUE

## CHANNEL_INTERRUPT
INTERRUPTIBLE_CHANNELS: MIND_FLAY
PROTECTED_CHANNELS: VOID_TORRENT, MIND_FLAY_INSANITY

## TRACKERS
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, PSYFIEND

## EMERGENCY_SAVE
IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
ELSE IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
END IF

## ROTATION_FSM
1. IF NOT target.dots_active AND READY(TENTACLE_SLAM) THEN RETURN TENTACLE_SLAM
2. IF NOT target.dots_active THEN RETURN VAMPIRIC_TOUCH
3. IF PROC(MIND_FLAY_INSANITY) THEN RETURN MIND_FLAY_INSANITY
4. IF player.insanity >= 50 OR USABLE(DEVOURING_PLAGUE) THEN RETURN DEVOURING_PLAGUE
5. IF READY(VOID_TORRENT) THEN RETURN VOID_TORRENT
6. IF target.hp_percent < 20 AND READY(SW_DEATH) THEN RETURN SW_DEATH
7. IF CHARGES(MIND_BLAST) >= 1 THEN RETURN MIND_BLAST
8. DEFAULT: RETURN MIND_FLAY
```

---

## Slash Commands

* `/sparc` or `/sa` — Open the SpArc Control Center.
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
