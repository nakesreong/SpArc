# SpArc — FSM Rotation Queue, UnitFrames, Metro Nameplates, MSBT & Action Camera

**Version:** 2.9.7  
**Authors:** Gemini (Tiger) & Anya (5cr3am1ng5oul)  
**Compatibility:** World of Warcraft: Retail / Midnight (`12.0.1`, `12.1.5`, `12.1.7`) & The War Within (`11.2.7`)  
**Source Repository:** [https://github.com/nakesreong/SpArc](https://github.com/nakesreong/SpArc)  
**License:** MIT

***

## Overview

**SpArc** (_Spell Arc_) is a lightweight, all-in-one combat HUD built for **World of Warcraft 12.x (Midnight)**. Your rotation logic lives in human-readable **Markdown (`.md`) pseudocode**, while the Lua engine handles **Hybrid Assisted Combat + Lookahead Simulation, UnitFrames, Metro Nameplates, MSBT Scrolling Combat Text, Smart Tab-Targeting, and Action Camera** in a single high-FPS addon.

* **AI-Ready by Design:** Copy the built-in **AI Prompt** (`Ctrl+C`) to let **Gemini**, **ChatGPT**, or **Claude** turn any Wowhead / Icy Veins guide into a custom `.md` preset, or edit `.md` rules live in-game.
* **Midnight 12.x Native:** Built from the ground up with `issecretvalue()` guards, C++ StatusBar secret-value rendering, and cast-correlated multi-target DoT tracking.

***

## Core Modules (All-in-One)

* **1. Hybrid Rotation Queue & `.MD` Compiler:** Slot `#1` syncs with Blizzard's Assisted Combat (`+` instant `.md` Interrupts, Stealth Openers, and `COMBO_STRIKES` checks), while Slots `#2..#5` simulate cooldowns, charges, procs, and resources ahead of time. Includes curated `.md` presets (Shadow Priest, Frost Mage, Assassination Rogue, Arms Warrior, Feral & Balance Druid, Enhancement Shaman, Windwalker Monk, Survival Hunter) and unlimited custom `.md` profiles.
* **2. Rotation Arc, Castbar & Resource Bar:** Customizable 3–6 icon arc (`+180°` dome to `-180°` bowl) flanked by **Defensive Saves (`TRACK_SAVES`)**, **Burst Cooldowns (`TRACK_CDS`)**, a **Dual-Direction Castbar** with Channel Clip Alerts, and an auto-detected **Class Resource Bar** (`BAR 0..100` & `PIPS 1..10`).
* **3. UnitFrames Suite:** Clean dark-graphite unitframes (`Player`, `Target`, `Target-of-Target`, `Focus`, `Pet`, `Party 1–4`, `Boss 1–5`) with circular portraits or flat Metro bars, role badges, aura trackers, range fade, and 1-click Blizzard/ElvUI frame suppression.
* **4. Metro Nameplates & Smart Tab-Targeting:** Flat nameplates that auto-sync DoT colors from your `.md` preset, stack on packs, fade by distance (`20–60 yd`), filter out guardian/minor pets on `Tab`, and highlight priority **Boss / InterruptCasting `[TAB!]`** targets.
* **5. Movable MSBT Scroll Zones & Combat Text:** Drag-and-drop **Incoming** and **Outgoing** scroll arcs (`Outward Arc`, `Straight Up`, `Fountain Wave`) with AoE tick filtering and clean target-overhead numbers.
* **6. Action Combat Camera & Edit Mode:** Mouselook lock with `onHold` (`G`), `onPress` (`` ` ``), and `Interact` (`E`) keys, crosshair `@mouseover`/`@cursor` targeting, safe out-of-combat form/shield/imbue cancel, and native **Blizzard Edit Mode** drag movers.
* **7. Macro Generator, Telemetry & Profiles:** One-click `/stopmacro [flying]` SpellBook macro generator (`/sparc macro`), 15-module Contract Self-Test & Telemetry Debugger (`/sparc debug`), per-character profiles, and instant **EN / RU** localization.

***

## Credits & Inspiration

* **MSBT & NameplateSCT** (movable scroll arcs) · **Plater & Threat Plates** (DoT-colored nameplates) · **WeakAuras & Hekili** (predictive rotation HUD) · **ConsolePort & Combat Mode** (action reticle camera) · **ElvUI** (dark-graphite aesthetic & profiles).

> *«Special thanks for the inspiration to the creators of MSBT, Plater, WeakAuras, Hekili, Combat Mode & ElvUI — their finest ideas live on under this single high-FPS roof.»*

***

## Markdown (`.MD`) Example

```markdown
# PROFILE: 9. Hunter: Survival (Midnight 12.x)
# CLASS: HUNTER | SPEC: Survival | MODE: PVE

## SPELL_BOOK
SPELL MUZZLE = ID:187707 | NAME:"Muzzle" | CD:15 | INTERRUPT:true
SPELL COORDINATED_ASSAULT = ID:1250646,360952 | BURST:10 | BOSS:true | NAME:"Takedown","Coordinated Assault" | CD:90
SPELL FURY_OF_THE_EAGLE = ID:1261193,203415 | NAME:"Boomstick","Fury of the Eagle" | CD:45 | LOCK_CHANNEL:true
SPELL WILDFIRE_BOMB = ID:259495 | AURA_ID:269747 | AURA_UNIT:target | AURA_DUR:6 | NAME:"Wildfire Bomb" | CD:18 | CHARGES:2
SPELL KILL_COMMAND = ID:259489 | AURA_ID:260286 | AURA_UNIT:player | AURA_DUR:10 | NAME:"Kill Command" | CD:6 | CHARGES:2 | GAIN:15
SPELL MONGOOSE_BITE = ID:186270,259387 | NAME:"Raptor Strike","Mongoose Bite" | CD:0 | SPENDER:true | COST:30

## TRACKERS
TRACK_SAVES: EXHILARATION, SURVIVAL_OF_THE_FITTEST, ASPECT_OF_THE_TURTLE
TRACK_CDS: COORDINATED_ASSAULT, FURY_OF_THE_EAGLE, WILDFIRE_BOMB
TRACK_DOTS: WILDFIRE_BOMB, SERPENT_STING

## ROTATION_QUEUE
IF target.casting_interruptible AND READY(MUZZLE) THEN
    RETURN CAST(MUZZLE)
ELSE IF BOSS AND READY(COORDINATED_ASSAULT) THEN
    RETURN CAST(COORDINATED_ASSAULT)
ELSE IF CHARGES(WILDFIRE_BOMB) >= 2 AND READY(WILDFIRE_BOMB) THEN
    RETURN CAST(WILDFIRE_BOMB)
ELSE IF player.aura(TIP_OF_THE_SPEAR).stacks == 0 AND READY(KILL_COMMAND) THEN
    RETURN CAST(KILL_COMMAND)
ELSE IF READY(WILDFIRE_BOMB) THEN
    RETURN CAST(WILDFIRE_BOMB)
ELSE IF READY(FURY_OF_THE_EAGLE) THEN
    RETURN CAST(FURY_OF_THE_EAGLE)
ELSE IF USABLE(MONGOOSE_BITE) THEN
    RETURN CAST(MONGOOSE_BITE)
ELSE
    RETURN CAST(KILL_COMMAND)
END IF
```

***

## Slash Commands

* `/sparc` or `/sa` — Open the SpArc Control Center.
* `/sparc editmode` — Toggle drag & arrow-key nudge movers for all HUD & UnitFrame widgets.
* `/sparc uf` | `/sparc np` | `/sparc ct` | `/sparc msbt` | `/sparc cam` — Open module tabs directly.
* `/sparc macro` — Open the SpellBook Wrapper Macro Generator.
* `/sparc debug` | `/sparc selftest` — Run the 15-module Contract Self-Test & Telemetry Debugger.
* `/sparc en` | `/sparc ru` — Switch language between English and Russian.
