# SpArc — Semicircle FSM Rotation, Action Combat Camera & Cooldown HUD

**Version:** 2.9.2  
**Authors:** Gemini (Tiger) & Anya (5cr3am1ng5oul)  
**Compatibility:** World of Warcraft: Retail / Midnight (`12.0.1`, `12.1.5`, `12.1.7`) & The War Within (`11.2.7`)  
**Source Repository:** [https://github.com/nakesreong/SpArc](https://github.com/nakesreong/SpArc)  
**License:** MIT

***

## Overview & Origin Story

**SpArc** (_Spell Arc_) is a modular, data-driven rotation helper where **your rotation logic is described in human-readable Markdown (`.md`) pseudocode**, while the **Lua core acts purely as the execution, simulation, and rendering engine**.

### Why SpArc Was Created
The idea grew out of my old custom **WeakAuras rotation helper**, originally built for playing **Shadow Priest in Solo Shuffle**. Now that WeakAuras is no longer viable under modern World of Warcraft 12.x (Midnight) restrictions—and because I wanted my own tailored **Action Combat Camera** quality-of-life features without constantly patching third-party camera mods after every update—**SpArc** was born as a standalone, all-in-one addon.

### AI-Driven Philosophy & Evolving Architecture
*   **AI-Driven by Design:** SpArc is built around an **AI-driven workflow**. It expects either a willingness to collaborate with an AI (Gemini, ChatGPT, Claude) to craft, tune, and debug your rotation, or the desire to write `.md` pseudocode yourself.
*   **Honest Living Architecture:** Because I don't personally main every single class and spec in World of Warcraft, it is impossible to anticipate every niche class mechanic upfront. Instead, SpArc's engine and unified aura architecture are actively evolving step by step as new specs and interactions are tested in live content.

### Core Highlights
*   **Zero Hardcoded Class Logic:** Every spell definition, SpellID list, resource cost/gain, unified aura tracker (`AURA_ID`, stacks, duration, pandemic timers), channel protection policy, defensive save, and burst cooldown is compiled live from editable `.md` text.
*   **Unified WeakAuras-Style Aura Engine:** Buffs, DoTs, debuff stacks, procs, and burst windows are all treated as unified auras (`target.aura(KEY_OR_ID).rem`, `.stacks`, `player.aura(KEY_OR_ID).rem`), inspectable by spell key or numeric Wowhead Aura SpellID.
*   **World of Warcraft 12.x (Midnight) Ready:** Built from the ground up with safe `issecretvalue()` guards and native `C_AssistedCombat` / `C_Spell` / `C_UnitAuras` integration, preventing secret-value and combat taint errors.
*   **Dynamic Keybind Resolution:** Automatically resolves hotkeys across standard Blizzard Action Bars, **Bartender4** (`BT4Button`), **ElvUI**, and Mouselook click-casting slots (`M1`, `M2`, `SM1`, `SM2`, `CM1`, `CM2`, `AM1`, `AM2`).
*   **Bilingual Modular Control Center:** Every subsystem operates as an independent module with its own configuration tab, master enable toggle, live preview (`/sparc`), and instant one-click switching between **English (`EN`)** and **Russian (`RU`)**.

***

## Architecture & Modules

### 1\. Rotation Presets (56 Built-In Profiles)

Ships with **56 pre-built rotation presets** covering all **13 World of Warcraft classes** (PvE / Mythic+ Cleave, Raid Single-Target Boss, PvP Arena/BG, Delves, and Hero Talent variations):

*   **AUTO Mode:** Automatically switches between PvE, Raid Boss, and PvP presets based on your current instance, encounter, or arena state.
*   **MANUAL Mode:** Lock any built-in or custom preset for specialized encounters, speedruns, or testing.
*   **Custom Presets:** Create, duplicate, customize, or delete unlimited presets per class directly in the UI.

### 2\. Markdown (`.MD`) Pseudocode Editor & AI Prompt Generator

A full in-game code editor that compiles `.md` rotation rules on the fly without reloading the UI:

*   **Live FSM Compiler:** Parses `SPELL_BOOK`, `CHANNEL_POLICY`, `TRACKERS`, `EMERGENCY_SAVE`, and `ROTATION_QUEUE` blocks into an executable priority queue.
*   **Built-In AI Prompt Generator:** Click **AI Prompt (Ctrl+C)** to copy a complete compiler specification prompt. Paste it into **Gemini**, **ChatGPT**, or **Claude** alongside any **Icy Veins** or **Wowhead** class guide, and paste the generated `.md` code straight back into SpArc.

### 3\. Semicircle Rotation Arc (Predictive Queue)

Displays your upcoming spell rotation along a customizable semicircle arc above your character:

*   **Primary Slot #1 (`10 o'clock`):** Enlarged, high-visibility active recommendation with live keybind badge, radial GCD/cooldown sweep, and proc glow.
*   **Predictive Queue (`Slots #2 to #6`):** Simulates upcoming GCD state transitions—tracking virtual cooldowns, charge consumption, aura/DoT application, debuff stacks, and resource generation/spending across the next 3 to 6 steps.
*   **Press Bounce Animation:** Optional tactile scale feedback (`-20% -> +20%`) when the recommended spell is cast.
*   **Full Geometry Control:** Customize arc radius, spread angle (`60°` to `180°`), vertical offset, primary/queue icon scales, and queue length.

### 4\. Defensive Saves & Offensive Cooldowns Wings

Flanks your central HUD with dedicated cooldown tracking wings driven by your `.md` preset:

*   **Left Wing (`TRACK_SAVES`):** Tracks up to 4 defensive cooldowns. Ready abilities display a crisp green border; proc-enhanced heals/saves (such as Feral Druid's instant *Regrowth* under *Predatory Swiftness*) light up with a golden proc glow when active; abilities on cooldown desaturate with a precision spiral and timer.
*   **Right Wing (`TRACK_CDS`):** Tracks up to 4 major offensive/burst cooldowns with golden readiness borders.
*   **Center Emergency Save Alert (`RETURN EMERGENCY`):** Displays a high-priority central alert when player health drops below your configured HP threshold (`15%` to `50%`) and a defensive save is ready.

### 5\. Dual-Direction Castbar & Channel Clip Advisor

A precision castbar engineered for caster and melee-weaver specs:

*   **Normal Casts:** Fill from **Left to Right** (`0% -> 100%`).
*   **Channeled Spells:** Drain from **Right to Left** (`100% -> 0%`).
*   **Smart Channel Interrupt Detection:** Distinguishes between **protected channels** (`PROTECT_CHANNEL`, e.g., _Void Torrent_, _Ray of Frost_ — displays `[DO NOT CLIP]`) and **interruptible filler channels** (`INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY`, e.g., _Mind Flay_ — flashes `CLIP FILLER -> PRESS [KEY]!` the instant a higher-priority spell comes off cooldown or procs).

### 6\. Standalone Action Combat Camera (Mouselook)

A lightweight, zero-bloat replacement for external action-camera addons that locks camera mouselook during gameplay and eliminates the stuck center hardware cursor bug in WoW 12.x:

*   **Configurable Camera & Interact Keybinds:**
    *   **Unlock Cursor on Hold (`onHold`):** Temporarily frees the mouse cursor while held (default `G`) and immediately relocks on release.
    *   **Toggle Camera Lock (`onPress`):** Permanently unlocks or locks the camera on press (default `` ` ``).
    *   **Target / NPC Interact Key (`INTERACTTARGET`):** Configurable interact keybind that automatically adapts to your character's native game binding (e.g., `E` or `C`).
*   **Crosshair & `@mouseover` / `@cursor` Synchronization:** Renders a customizable center reticle (with live preview while the Combat Camera tab is open) and synchronizes `CursorCenteredYPos` and deferred `CursorFreelookCentering` so `@mouseover` and `@cursor` macros hit the exact crosshair height without exposing the OS hardware cursor.
*   **Direct Mouselook Click-Casting:** Routes `LMB`, `RMB`, and `Shift / Ctrl / Alt + LMB/RMB` directly to `Bartender4` (`:Keybind`) or `ActionButton1..8` while camera mouselook is active.
*   **Smart UI Auto-Unlock:** Automatically frees the cursor whenever bags, maps, quest dialogs, merchant windows, settings panels, or ground-targeted AoE reticles (`SpellIsTargeting()`) are open.

### 7\. SpellBook Wrapper Macro Generator (`/sparc macro`)

Created to quickly generate **wrapper macro templates** around your active SpellBook spells (**Class** and **Specialization** tabs):

*   **Why It Exists:** This module does **not** magically write complex class macros for you—instead, it generates clean, standardized wrapper templates (`#showtooltip`, `/stopmacro [flying]`, `/cast [@target] SpellName`) to take the tedium out of setting up a character. On all of my characters, every single spell is cast through safety wrappers like these (for example, to prevent accidentally dismounting mid-air when pressing combat keys—because my hands are clumsy and my fingers don't always listen!).
*   **Smart Naming & Overflow:** Automatically names Class spells `<class_initial><N>` (`d1, d2...`) and Spec spells `<spec_initial><class_initial><N>` (`fd1, sp1...`), filling **Character Macros** (`30` slots) first and overflowing into **General Account Macros** (`120` slots) without overwriting existing macros.

### 8\. SpellBook Telemetry & Rotation Debugger

An integrated diagnostic suite for rotation authors and AI-assisted troubleshooting:

*   Compares live player SpellBook state, action bar slot assignments, aura timers/stacks, and cooldown/usability flags against the active FSM evaluation tree.
*   Captures manual or automated diagnostic snapshots that you can paste directly to your AI assistant to diagnose why a spell did or did not trigger.

### 9\. Per-Character Profiles & Automatic Keybind Conflict Resolution

Full multi-character profile management modeled after ElvUI and Plater:

*   **Per-Character Profiles:** Automatically creates and maintains an isolated profile (`Character - Realm`) for each character alongside a shared `Default` profile. Supports one-click profile switching, copying settings between profiles, resetting, and deletion.
*   **Automatic Conflict Detection:** Monitors `UPDATE_BINDINGS` in real time. If any key used by SpArc (`onHold`, `onPress`, or `Interact`) is bound to an action bar slot or command in the game's Keybindings menu or another addon (such as Bartender4), SpArc automatically clears its internal bind to prevent keybind collisions.

***

## Markdown (`.MD`) Pseudocode Example

```markdown
# TITLE: 5. Druid: Feral — PvE / Mythic+ / Raid (Midnight 12.0+)
# CLASS: DRUID
# SPEC: Feral
# MODE: PVE

## SPELL_BOOK
SPELL RAKE = ID:1822 | AURA_ID:155722 | AURA_UNIT:target | AURA_DUR:15 | NAME:"Rake" | CD:0 | COST:35 | CP:+1
SPELL RIP = ID:1079 | AURA_ID:1079 | AURA_UNIT:target | AURA_DUR:24 | NAME:"Rip" | CD:0 | COST:20 | SPENDER:TRUE
SPELL THRASH = ID:106830 | AURA_ID:405233 | AURA_UNIT:target | AURA_DUR:15 | NAME:"Thrash" | CD:0 | COST:40 | CP:+1
SPELL FEROCIOUS_BITE = ID:22568 | NAME:"Ferocious Bite" | CD:0 | COST:25 | SPENDER:TRUE
SPELL SHRED = ID:5221 | NAME:"Shred" | CD:0 | COST:40 | CP:+1 | FILLER:TRUE
SPELL TIGERS_FURY = ID:5217 | AURA_ID:5217 | AURA_UNIT:player | AURA_DUR:15 | NAME:"Tiger's Fury" | CD:30 | ENERGY:+50
SPELL BERSERK = ID:106951,102543 | AURA_ID:106951 | AURA_UNIT:player | AURA_DUR:15 | NAME:"Berserk","Incarnation: Avatar of Ashamane" | CD:120
SPELL CONVOKES_SPIRITS = ID:391528 | NAME:"Convoke the Spirits" | CD:60
SPELL REGROWTH = ID:8936 | AURA_ID:69369 | AURA_UNIT:player | AURA_DUR:12 | NAME:"Regrowth","Predatory Swiftness" | CD:0

## CHANNEL_POLICY
PROTECT_CHANNEL: CONVOKES_SPIRITS

## TRACKERS
TRACK_SAVES: SURVIVAL_INSTINCTS, BARKSKIN, REGROWTH, RENEWAL
TRACK_CDS: BERSERK, CONVOKES_SPIRITS, TIGERS_FURY, FERAL_FRENZY

## EMERGENCY_SAVE
IF player.hp_percent <= 35 AND READY(SURVIVAL_INSTINCTS) THEN
    RETURN EMERGENCY(SURVIVAL_INSTINCTS)
ELSE IF player.hp_percent <= 50 AND player.aura(69369).rem > 0 AND READY(REGROWTH) THEN
    RETURN EMERGENCY(REGROWTH)
END IF

## ROTATION_QUEUE
1. IF READY(TIGERS_FURY) AND player.energy <= 50 THEN RETURN TIGERS_FURY
2. IF target.aura(RAKE).rem <= 3 AND USABLE(RAKE) THEN RETURN RAKE
3. IF READY(BERSERK) THEN RETURN BERSERK
4. IF player.cp >= 5 AND target.aura(RIP).rem <= 5 AND USABLE(RIP) THEN RETURN RIP
5. IF player.cp >= 5 AND USABLE(FEROCIOUS_BITE) THEN RETURN FEROCIOUS_BITE
6. IF target.aura(THRASH).rem <= 3 AND USABLE(THRASH) THEN RETURN THRASH
7. DEFAULT: RETURN SHRED
```

***

## Slash Commands

*   `/sparc` or `/sa` — Open the SpArc Control Center.
*   `/sparc macro` — Open the SpellBook Wrapper Macro Generator tab.
*   `/sparc cam` — Open the Action Combat Camera configuration tab.
*   `/sparc profiles` — Open the Per-Character Profiles tab.
*   `/sparc fixcursor` — Flush hardware cursor and freelook centering CVars.
*   `/sparc test` — Toggle live HUD preview mode (`ON` / `OFF`).
*   `/sparc debug` — Capture a telemetry snapshot and open the Debugger tab.
*   `/sparc en` | `/sparc ru` — Switch interface language between English and Russian.
*   `/sparc auto` | `/sparc pve` | `/sparc boss` | `/sparc pvp` — Switch active rotation mode.

***

## Source Code & Issue Tracker

*   **GitHub Repository:** [https://github.com/nakesreong/SpArc](https://github.com/nakesreong/SpArc)
