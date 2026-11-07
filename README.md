# SpArc — FSM Rotation Queue, UnitFrames, Metro Nameplates, MSBT Combat Text & Action Camera

**Version:** 2.9.6  
**Authors:** Gemini (Tiger) & Anya (5cr3am1ng5oul)  
**Compatibility:** World of Warcraft: Retail / Midnight (`12.0.1`, `12.1.5`, `12.1.7`) & The War Within (`11.2.7`)  
**Source Repository:** [https://github.com/nakesreong/SpArc](https://github.com/nakesreong/SpArc)  
**License:** MIT

***

## Overview & Origin Story

**SpArc** (_Spell Arc_) is a modular, all-in-one combat HUD where **your rotation logic is written in human-readable Markdown (`.md`) pseudocode**, while the **Lua core handles state simulation, HUD rendering, unitframes, nameplates, scrolling combat text, and camera control**.

The idea grew out of my old custom **WeakAuras rotation helper** built for **Shadow Priest in Solo Shuffle**. Now that WeakAuras is no longer viable under World of Warcraft 12.x (Midnight) restrictions—and because I wanted my own tailored **Action Combat Camera**, **UnitFrames**, **Nameplates**, and **MSBT-style Combat Text** without constantly patching five different third-party mods after every game update—**SpArc** was born as a single high-FPS addon.

* **AI-Driven by Design:** Use the built-in **AI Prompt Generator** (`Ctrl+C`) to let **Gemini**, **ChatGPT**, or **Claude** convert any Icy Veins / Wowhead guide into an editable `.md` rotation preset, or write `.md` rules yourself.
* **Living Architecture:** Built for **Midnight 12.x** (`issecretvalue()` guards and cast-correlated multi-target aura tracking) and actively evolving as new specs and interactions are tested in live content.

***

## Core Modules (12-in-1)

* **1. Rotation Presets & `.MD` Editor:** Curated built-in presets (Shadow Priest, Frost Mage, Assassination Rogue, Arms Warrior, Feral & Balance Druid, Enhancement Shaman, Windwalker Monk with `COMBO_STRIKES: true` weaving) plus unlimited custom `.MD` profiles with `AUTO` (`PvE / Boss / PvP`) switching and a live in-game `.md` compiler.
* **2. Rotation Arc & Cooldown Wings:** Bend your predictive 3–6 icon spell queue into an overhead dome (`+180°`), flat bar (`0°`), or bowl curve (`-180°`) with three ordering modes (`Left`, `Mirror`, `Center`), flanked by **Left Defensive Saves (`TRACK_SAVES`)**, **Right Burst Cooldowns (`TRACK_CDS`)**, and a **Center Emergency Save Alert**.
* **3. Dual-Direction Castbar & Class Resource Bar:** Casts fill `Left -> Right`, channels drain `Right -> Left`, with smart **Channel Clip Alerts** (`[DO NOT CLIP]` vs `CLIP FILLER -> PRESS [KEY]!`) and an auto-detected secondary resource bar underneath (`BAR 0..100` vs `PIPS 1..10`).
* **4. UnitFrames Suite (Player, Target, Castbar, ToT, Focus, Pet, Party 1..4 & Boss 1..5):** Circular-portrait or Metro-square unitframes with class/reaction coloring, target DoT/buff tracking, role badges, and 1-click Blizzard/ElvUI UnitFrame suppression.
* **5. Metro Tile Nameplates & Distance Fade:** Clean flat nameplates that auto-sync tracked DoTs from your `.md` preset, recolor enemy bars by single or multi-DoT (`AND`) combinations, stack in a vertical ladder on packs, and smoothly fade distant targets (`20–60 yd`).
* **6. Movable MSBT Scroll Zones & Tactile Combat Text:** Drag-and-drop **Incoming** and **Outgoing** scroll zones (`MSBT Outward Arc`, `Straight Up`, or `Fountain Wave`), soft compact yellow numbers high above your target, Smart AoE periodic tick filtering (`3+` targets), and complete suppression of noisy center-screen banners.
* **7. Action Combat Camera (Mouselook) & Blizzard Edit Mode Integration:** Locks camera mouselook with customizable `onHold` (`G`), `onPress` (`` ` ``), and `Interact` (`E`) keys, crosshair `@mouseover` / `@cursor` alignment, `LMB` / `RMB` click-casting, and native drag/nudge movers inside Blizzard's Edit Mode.
* **8. Wrapper Macro Generator, Telemetry/Contract Debugger & Profiles:** One-click `/stopmacro [flying]` SpellBook macro generator (`/sparc macro`), live rotation & module contract debugger (`/sparc debug` / `/sparc selftest`), **ElvUI-style isolated character profiles**, and instant **English (`EN`) / Russian (`RU`)** UI switching.

***

## Standing on the Shoulders of Giants (Inspiration & Credits)

* **MikScrollingBattleText (MSBT) & NameplateSCT:** for the concept of separated, movable side-screen incoming/outgoing scroll arcs and tactile number fountains.
* **Plater Nameplates & Threat Plates:** for smart health bar recoloring by DoT combinations, vertical anti-overlap stacking, and smooth distance fading.
* **WeakAuras & Hekili:** for the central predictive rotation queue and flanking defensive/offensive cooldown wings.
* **ConsolePort & Combat Mode:** for turning the classic MMO camera into true action-RPG combat with a reticle and one-button targeting.
* **ElvUI & WindTools:** for the clean dark-graphite UI aesthetic, isolated character profiles, and suppression of noisy default banners.

> *«Special thanks for the inspiration to the creators of MSBT, Plater, WeakAuras, Hekili, Combat Mode & ElvUI — their finest ideas live on under this single high-FPS roof.»*  
> *«Отдельное спасибо за вдохновение авторам легендарных аддонов: MSBT, Plater, WeakAuras, Hekili, Combat Mode и ElvUI — мы собрали ваши лучшие идеи под одной крышей с любовью к чистым фреймам и высокому FPS.»*

***

## Markdown (`.MD`) Pseudocode Example

```markdown
# TITLE: 8. Monk: Windwalker — PvE / Mythic+ / Raid (Midnight 12.x)
# CLASS: MONK | SPEC: Windwalker | MODE: PVE | COMBO_STRIKES: true

## SPELL_BOOK
SPELL STRIKE_OF_THE_WINDLORD = ID:392983 | NAME:"Strike of the Windlord" | CD:30 | SPENDER:true | COST:40
SPELL RISING_SUN_KICK = ID:107428 | AURA_ID:115804 | AURA_UNIT:target | AURA_DUR:10 | CD:10 | SPENDER:true | COST:40
SPELL FISTS_OF_FURY = ID:113656 | CD:24 | SPENDER:true | COST:60 | LOCK_CHANNEL:true
SPELL SPINNING_CRANE_KICK = ID:101546 | AURA_ID:325202 | AURA_UNIT:player | CD:0 | SPENDER:true | COST:40
SPELL BLACKOUT_KICK = ID:100784 | AURA_ID:116768 | AURA_UNIT:player | CD:0 | SPENDER:true | COST:20
SPELL TIGER_PALM = ID:100780 | AURA_ID:202090 | AURA_UNIT:player | AURA_DUR:20 | CD:0 | GAIN:40

## TRACKERS
TRACK_SAVES: TOUCH_OF_KARMA, FORTIFYING_BREW, EXPEL_HARM, VIVIFY
TRACK_CDS: INVOKE_XUEN, STORM_EARTH_AND_FIRE, STRIKE_OF_THE_WINDLORD, CELESTIAL_CONDUIT, TOUCH_OF_DEATH
TRACK_DOTS: MARK_OF_THE_CRANE, RISING_SUN_KICK

## ROTATION_QUEUE
IF target.casting_interruptible AND READY(SPEAR_HAND_STRIKE) THEN
    RETURN CAST(SPEAR_HAND_STRIKE)
ELSE IF READY(STRIKE_OF_THE_WINDLORD) THEN
    RETURN CAST(STRIKE_OF_THE_WINDLORD)
ELSE IF READY(RISING_SUN_KICK) THEN
    RETURN CAST(RISING_SUN_KICK)
ELSE IF READY(FISTS_OF_FURY) THEN
    RETURN CAST(FISTS_OF_FURY)
ELSE IF player.chi <= 3 AND READY(TIGER_PALM) THEN
    RETURN CAST(TIGER_PALM)
ELSE
    RETURN CAST(BLACKOUT_KICK)
END IF
```

***

## Slash Commands

* `/sparc` or `/sparkarc` — Open the SpArc Control Center.
* `/sparc editmode` or `/sparc move` — Toggle drag & arrow-key nudge movers for all HUD & UnitFrame widgets.
* `/sparc uf` — Open the UnitFrames Suite tab.
* `/sparc msbt` — Unlock & drag MSBT scroll zones with your mouse.
* `/sparc ct` — Open the Combat Text & Distance Fade tab.
* `/sparc np` — Open the Metro Tile Nameplates & DoT Color Rules tab.
* `/sparc cam` — Open the Action Combat Camera tab.
* `/sparc macro` — Open the SpellBook Wrapper Macro Generator tab.
* `/sparc profiles` — Open the Per-Character Profiles tab.
* `/sparc debug` / `/sparc selftest` — Run the 15-module Contract Self-Test and open the Telemetry & Debug Radar tab.
* `/sparc en` | `/sparc ru` — Switch interface language between English and Russian.
