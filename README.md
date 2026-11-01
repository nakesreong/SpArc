# SpArc — FSM Rotation Queue, Metro Nameplates, Action Combat Camera & Cooldown HUD

**Version:** 2.9.4  
**Authors:** Gemini (Tiger) & Anya (5cr3am1ng5oul)  
**Compatibility:** World of Warcraft: Retail / Midnight (`12.0.1`, `12.1.5`, `12.1.7`) & The War Within (`11.2.7`)  
**Source Repository:** [https://github.com/nakesreong/SpArc](https://github.com/nakesreong/SpArc)  
**License:** MIT

***

## Overview & Origin Story

**SpArc** (_Spell Arc_) is a modular, data-driven rotation helper where **your rotation logic is written in human-readable Markdown (`.md`) pseudocode**, while the **Lua core runs the evaluation, state simulation, and HUD rendering**.

### Why SpArc Was Created

The idea grew out of my old custom **WeakAuras rotation helper**, originally built for playing **Shadow Priest in Solo Shuffle**. Now that WeakAuras is no longer viable under modern World of Warcraft 12.x (Midnight) restrictions—and because I wanted my own tailored **Action Combat Camera** and **Nameplates** quality-of-life features without constantly patching third-party mods after every update—**SpArc** was born as a standalone, all-in-one addon.

### AI-Driven Philosophy & Evolving Architecture

*   **AI-Driven by Design:** SpArc is built around an **AI-driven workflow**. It expects either a willingness to collaborate with an AI (Gemini, ChatGPT, Claude) to craft, tune, and debug your rotation, or the desire to write `.md` pseudocode yourself.
*   **Honest Living Architecture:** Because I don't personally main every single class and spec in World of Warcraft, it is impossible to anticipate every niche class mechanic upfront. Instead, SpArc's engine and unified aura architecture are actively evolving step by step as new specs and interactions are tested in live content.

### Core Highlights

*   **Zero Hardcoded Class Logic:** Spell definitions, SpellID lists, resource costs/gains, tracked auras (`AURA_ID`, stacks, duration, pandemic timers), channel policies, defensive saves, and burst cooldowns are compiled directly from editable `.md` text.
*   **Flexible Rotation Queue Geometry (Dome, Flat Line, or Bowl):** Bend the rotation queue anywhere from `-180°` (an inverted bowl curve under your character) through `0°` (a straight horizontal line) to `+180°` (an overhead semicircle dome), with three slot ordering modes (`0-1-2-3-4` Left-to-Right, `4-3-2-1-0` Mirrored Right-to-Left, and `3-1-0-2-4` Center-Out), adjustable primary border thickness (`0–6 px`), opacity (`20–100%`), and full-screen vertical offset.
*   **Metro Tile Nameplates with `.MD` DoT Auto-Sync:** Minimalist flat nameplates that change color dynamically based on active DoTs and debuffs across all nearby enemies. Automatically pulls tracked DoT IDs from your active `.md` rotation preset (`TRACK_DOTS` / `target.aura(...)`), supports multi-aura `AND` combo rules, shows player levels and class colors (with a dark cherry tint for friendly Death Knights so they don't look like hostile enemies), marks quest NPCs (`!`), and asks before disabling conflicting nameplate addons (`ElvUI NamePlates` / `Plater`).
*   **Dual-Direction Castbar & Secondary Class Resource Bar:** Castbar with channel-clipping alerts paired with a universal secondary resource bar underneath (Insanity with a 50-Insanity Devouring Plague threshold tick, Combo Points, Astral Power, Maelstrom, Chi, Holy Power, Soul Shards, Arcane Charges, Essence, Runes, Rage, Focus, and Energy).
*   **Action Combat Camera & Out-of-Combat Form Unshift:** Mouselook camera lock with configurable `onHold` / `onPress` / `Interact` keys, crosshair-synced `@mouseover` / `@cursor` targeting, click-casting (`LMB`/`RMB`), and an optional setting to automatically cancel Shadowform or Druid shapeshift forms when pressing Interact (`E`) or Hold Cursor (`G`) out of combat on the ground (safely ignored while flying).
*   **World of Warcraft 12.x (Midnight) Ready:** Built with `issecretvalue()` guards, C++ StatusBar secret pass-through, and cast/event-correlated multi-target aura tracking so combat restrictions in 12.x do not break the HUD or throw taint errors.
*   **ElvUI-Style Isolated Character Profiles & Bilingual UI (`EN` / `RU`):** Every character gets an isolated profile (`Character - Realm`) storing HUD geometry, camera binds, and nameplate DoT color rules, with full profile copying, reset, and one-click switching between **English (`EN`)** and **Russian (`RU`)**.

***

## Architecture & Modules

### 1\. Rotation Presets (56 Built-In Profiles)

Includes **56 built-in rotation presets** covering all **13 World of Warcraft classes** (PvE / Mythic+ Cleave, Raid Single-Target Boss, PvP Arena/BG, Delves, and Hero Talent variations):

*   **AUTO Mode:** Switches between PvE, Raid Boss, and PvP presets automatically based on your current instance, encounter, or arena state.
*   **MANUAL Mode:** Lock any built-in or custom preset for specific encounters or testing.
*   **Burst (`BOSS:true`) & PvP (`PVP:true`) Toggles:** Enable or disable automatic boss cooldowns and PvP abilities in the rotation queue directly from the Rotation Presets tab.
*   **Custom Presets:** Create, duplicate, edit, or delete presets per class in the UI.

### 2\. Markdown (`.MD`) Pseudocode Editor & AI Prompt Generator

An in-game editor that compiles `.md` rotation rules on the fly without reloading the UI:

*   **Live FSM Compiler:** Parses `SPELL_BOOK`, `CHANNEL_POLICY`, `TRACKERS`, `EMERGENCY_SAVE`, and `ROTATION_QUEUE` blocks into an executable priority queue.
*   **Built-In AI Prompt Generator:** Click **AI Prompt (Ctrl+C)** to copy the compiler specification prompt, give it to **Gemini**, **ChatGPT**, or **Claude** together with an **Icy Veins** or **Wowhead** guide, and paste the resulting `.md` preset into SpArc.

### 3\. Rotation Arc (Semicircle / Flat Line / Bowl Queue)

Displays your upcoming spell queue with customizable curvature and icon ordering:

*   **Three Slot Ordering Modes:**
    *   `0-1-2-3-4 (Left)`: Reads left-to-right like text, with Primary Slot `#1` on the left.
    *   `4-3-2-1-0 (Mirror)`: Reversed right-to-left layout.
    *   `3-1-0-2-4 (Center)`: Places Primary Slot `#1` dead-center and alternates upcoming queue slots outward to the left and right.
*   **Continuous Curvature (`-180°` to `+180°`):** Set negative angles for a downward bowl curve under your character, `0°` for a flat horizontal bar, or positive angles for an upward dome.
*   **Predictive Queue (`Slots #2 to #6`):** Simulates upcoming GCD state transitions—tracking virtual cooldowns, charge consumption, DoT application, debuff stacks, and resource changes across 3 to 6 steps.
*   **Visual Controls:** Customize arc radius/width, screen-relative vertical offset, primary and queue icon scales, primary border thickness (`0–6 px`), overall arc opacity (`20–100%`), and optional press-bounce feedback (`-20% -> +20%`).

### 4\. Defensive Saves & Offensive Cooldowns Wings

Flanks your central HUD with cooldown tracking wings defined in your `.md` preset:

*   **Left Wing (`TRACK_SAVES`):** Tracks up to 4 defensive cooldowns with green readiness borders, golden proc highlights (such as Feral Druid's instant _Regrowth_ under _Predatory Swiftness_), and cooldown spirals.
*   **Right Wing (`TRACK_CDS`):** Tracks up to 4 offensive/burst cooldowns with golden readiness borders.
*   **Center Emergency Save Alert (`RETURN EMERGENCY`):** Shows a central alert when player health drops below your configured HP threshold (`15%` to `50%`) and a defensive save is ready.

### 5\. Dual-Direction Castbar & Secondary Resource Tracker

A castbar and class resource display positioned together for caster and melee specs:

*   **Castbar Direction:** Normal casts fill **Left to Right** (`0% -> 100%`); channeled spells drain **Right to Left** (`100% -> 0%`).
*   **Channel Clip Advisor:** Distinguishes between **protected channels** (`PROTECT_CHANNEL`, e.g., _Void Torrent_, _Ray of Frost_ — displays `[DO NOT CLIP]`) and **interruptible filler channels** (`INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY`, e.g., _Mind Flay_ — flashes `CLIP FILLER -> PRESS [KEY]!` when a higher-priority spell comes ready).
*   **Secondary Resource Bar:** Automatically detects and renders your active spec's primary/secondary combat resource underneath the castbar—segmented pills for Combo Points, Chi, Holy Power, Soul Shards, Arcane Charges, Essence, and Runes, or a smooth progress bar for Insanity (with a golden tick mark at 50 Insanity), Astral Power, Maelstrom, Rage, Focus, and Energy.

### 6\. Standalone Action Combat Camera (Mouselook)

Locks camera mouselook during gameplay and prevents the stuck center hardware cursor bug in WoW 12.x:

*   **Configurable Camera & Interact Keybinds:**
    *   **Unlock Cursor on Hold (`onHold`):** Frees the mouse cursor while held (default `G`) and relocks on release.
    *   **Toggle Camera Lock (`onPress`):** Unlocks or locks the camera on press (default `` ` ``).
    *   **Target / NPC Interact Key (`INTERACTTARGET`):** Configurable interact keybind (default `E`).
*   **Out-of-Combat Form Unshift (Disabled by Default):** Optional toggle for Shadow Priests and Druids that cancels Shadowform or ground shapeshift forms when pressing Interact (`E`) or Hold Cursor (`G`) out of combat so you can talk to NPCs or inspect your character in human/elf form—while checking `[flying]` so it never drops you out of Flight Form mid-air.
*   **Crosshair & `@mouseover` / `@cursor` Synchronization:** Renders a customizable center reticle and synchronizes `CursorCenteredYPos` and `CursorFreelookCentering` so `@mouseover` and `@cursor` actions align with the crosshair.
*   **Mouselook Click-Casting & Smart UI Auto-Unlock:** Routes `LMB`/`RMB` (+`Shift`/`Ctrl`/`Alt`) to action slots `1..8` while camera mouselook is active, and frees the cursor automatically whenever bags, maps, quest dialogs, merchant windows, or ground-targeting reticles are open.

### 7\. Metro Tile Nameplates & Dynamic DoT Color Rules

Clean, flat Windows Metro-style nameplates built to work reliably under WoW 12.x combat restrictions:

*   **Auto-Synced DoT Color Rules from `.MD`:** Pulls tracked DoT SpellIDs directly from your active `.md` rotation preset (`TRACK_DOTS` and `target.aura(...)` rules) and assigns distinct high-contrast colors to single DoTs and multi-DoT combinations (`AND` rules separated by commas, e.g., `34914, 589` for _Vampiric Touch + Shadow Word: Pain_).
*   **Multi-Target 12.x Combat Tracking:** Tracks single-target casts, hard-casts when switching targets mid-cast, and AoE/spread DoTs (_Tentacle Slam / Shadow Crash_, _Sunfire_, _Primal Wrath_, _Thrash_, _Crimson Tempest_, _Twin Moons_) across all neighboring enemy nameplates.
*   **Player Levels, Class Icons & Dark Cherry Friendly DKs:** Displays player level on both friendly and hostile players, attaches a left class icon square on hostile players, colors friendly players by class (using a deep dark cherry `#7A0F2E` for friendly Death Knights so they never blend in with red hostile bars), and marks quest targets with a golden `!` badge.
*   **Interruptible Castbar & Conflict Prompt:** Shows an integrated castbar underneath each nameplate (glowing gold on interruptible casts, grey on uninterruptible). If `ElvUI NamePlates` or `Plater` is enabled, SpArc asks which nameplate system you want to use instead of silently disabling your other addons.

### 8\. SpellBook Wrapper Macro Generator (`/sparc macro`)

Generates standardized wrapper macro templates around your active SpellBook spells (**Class** and **Specialization** tabs):

*   **Why It Exists:** Instead of writing complex class macros, it creates clean safety wrappers (`#showtooltip`, `/stopmacro [flying]`, `/cast [@target] SpellName`) to save time when setting up a character. On all of my characters, spells are cast through wrappers like these so pressing combat buttons while flying never dismounts me mid-air.
*   **Smart Naming & Overflow:** Names Class spells `<class_initial><N>` (`d1, d2...`) and Spec spells `<spec_initial><class_initial><N>` (`fd1, sp1...`), filling **Character Macros** (`30` slots) first and overflowing into **General Account Macros** (`120` slots) without overwriting existing macros.

### 9\. SpellBook Telemetry & Rotation Debugger

An integrated diagnostic tab for rotation authors and AI-assisted troubleshooting:

*   Compares live SpellBook state, action bar slot assignments, aura timers/stacks, and cooldown/usability flags against the active FSM evaluation tree.
*   Captures diagnostic snapshots that can be pasted into an AI assistant to see why a rule did or did not trigger.

### 10\. Isolated Character Profiles (`ElvUI`-Style)

Full multi-character profile management:

*   **Complete Profile Isolation:** Automatically creates an isolated profile (`Character - Realm`) for each character alongside a shared `Default` profile. Every profile stores its own HUD layout, arc curvature, camera keybinds, and nameplate DoT color rules.
*   **Copy, Switch & Reset:** Switch active profiles at any time, copy settings from another character's profile into your current profile (with a toggle to include or exclude Nameplate DoT Aura Rules), or reset to defaults.
*   **Automatic Keybind Conflict Detection:** Monitors `UPDATE_BINDINGS` in real time and clears internal camera binds if that key is bound to an action bar slot in WoW or Bartender4.

***

## Markdown (`.MD`) Pseudocode Example

```
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
TRACK_DOTS: RAKE, RIP, THRASH

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
*   `/sparc np` — Open the Metro Tile Nameplates & Aura Color Rules tab.
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
