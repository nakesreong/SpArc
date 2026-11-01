# SpArc — FSM Rotation Queue, Metro Nameplates, MSBT Combat Text & Action Camera

**Version:** 2.9.5  
**Authors:** Gemini (Tiger) & Anya (5cr3am1ng5oul)  
**Compatibility:** World of Warcraft: Retail / Midnight (`12.0.1`, `12.1.5`, `12.1.7`) & The War Within (`11.2.7`)  
**Source Repository:** [https://github.com/nakesreong/SpArc](https://github.com/nakesreong/SpArc)  
**License:** MIT

***

## Overview & Origin Story

**SpArc** (_Spell Arc_) is a modular, all-in-one combat HUD where **your rotation logic is written in human-readable Markdown (`.md`) pseudocode**, while the **Lua core handles state simulation, HUD rendering, nameplates, scrolling combat text, and camera control**.

The idea grew out of my old custom **WeakAuras rotation helper** built for **Shadow Priest in Solo Shuffle**. Now that WeakAuras is no longer viable under World of Warcraft 12.x (Midnight) restrictions—and because I wanted my own tailored **Action Combat Camera**, **Nameplates**, and **MSBT-style Combat Text** without constantly patching five different third-party mods after every game update—**SpArc** was born as a single high-FPS addon.

* **AI-Driven by Design:** Use the built-in **AI Prompt Generator** (`Ctrl+C`) to let **Gemini**, **ChatGPT**, or **Claude** convert any Icy Veins / Wowhead guide into an editable `.md` rotation preset, or write `.md` rules yourself.
* **Living Architecture:** Built for **Midnight 12.x** (`issecretvalue()` guards and cast-correlated multi-target aura tracking) and actively evolving as new specs and interactions are tested in live content.

***

## Core Modules (11-in-1)

* **1. Rotation Presets & `.MD` Editor:** **56 built-in presets** across all 13 classes with `AUTO` (`PvE / Boss / PvP`) switching, one-click `BOSS` & `PVP` cooldown toggles, and a live in-game `.md` compiler.
* **2. Rotation Arc & Cooldown Wings:** Bend your predictive 3–6 icon spell queue into an overhead dome (`+180°`), flat bar (`0°`), or bowl curve (`-180°`) with three ordering modes (`Left`, `Mirror`, `Center`), flanked by **Left Defensive Saves (`TRACK_SAVES`)**, **Right Burst Cooldowns (`TRACK_CDS`)**, and a **Center Emergency Save Alert**.
* **3. Dual-Direction Castbar & Class Resource Bar:** Casts fill `Left -> Right`, channels drain `Right -> Left`, with smart **Channel Clip Alerts** (`[DO NOT CLIP]` vs `CLIP FILLER -> PRESS [KEY]!`) and an auto-detected secondary resource bar underneath (Insanity, Combo Points, Chi, Holy Power, Soul Shards, Runes, Essence, Arcane Charges, Astral Power, Maelstrom, Rage, Focus, Energy).
* **4. Metro Tile Nameplates & Distance Fade:** Clean flat nameplates that auto-sync tracked DoTs from your `.md` preset, recolor enemy bars by single or multi-DoT (`AND`) combinations, stack in a vertical ladder on packs, and smoothly fade distant targets (`20–60 yd`).
* **5. Movable MSBT Scroll Zones & Tactile Combat Text:** Drag-and-drop **Incoming** and **Outgoing** scroll zones (`MSBT Outward Arc`, `Straight Up`, or `Fountain Wave`), soft compact yellow numbers high above your target, Smart AoE periodic tick filtering (`3+` targets), and complete suppression of noisy center-screen banners.
* **6. Action Combat Camera (Mouselook):** Locks camera mouselook with customizable `onHold` (`G`), `onPress` (`` ` ``), and `Interact` (`E`) keys, crosshair `@mouseover` / `@cursor` alignment, `LMB` / `RMB` click-casting, and optional out-of-combat form unshifting (safe while flying).
* **7. Wrapper Macro Generator, Telemetry & Profiles:** One-click `/stopmacro [flying]` SpellBook macro generator (`/sparc macro`), live rotation debugger (`/sparc debug`), **ElvUI-style isolated character profiles**, and instant **English (`EN`) / Russian (`RU`)** UI switching.

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
# TITLE: 5. Druid: Feral — PvE / Mythic+ / Raid (Midnight 12.0+)
# CLASS: DRUID | SPEC: Feral | MODE: PVE

## SPELL_BOOK
SPELL RAKE = ID:1822 | AURA_ID:155722 | AURA_UNIT:target | AURA_DUR:15 | NAME:"Rake" | CD:0 | COST:35 | CP:+1
SPELL RIP = ID:1079 | AURA_ID:1079 | AURA_UNIT:target | AURA_DUR:24 | NAME:"Rip" | CD:0 | COST:20 | SPENDER:TRUE
SPELL TIGERS_FURY = ID:5217 | AURA_ID:5217 | AURA_UNIT:player | AURA_DUR:15 | NAME:"Tiger's Fury" | CD:30 | ENERGY:+50
SPELL BERSERK = ID:106951,102543 | AURA_ID:106951 | AURA_UNIT:player | AURA_DUR:15 | NAME:"Berserk" | CD:120
SPELL FEROCIOUS_BITE = ID:22568 | NAME:"Ferocious Bite" | CD:0 | COST:25 | SPENDER:TRUE
SPELL SHRED = ID:5221 | NAME:"Shred" | CD:0 | COST:40 | CP:+1 | FILLER:TRUE

## TRACKERS
TRACK_SAVES: SURVIVAL_INSTINCTS, BARKSKIN, REGROWTH, RENEWAL
TRACK_CDS: BERSERK, CONVOKES_SPIRITS, TIGERS_FURY, FERAL_FRENZY
TRACK_DOTS: RAKE, RIP, THRASH

## ROTATION_QUEUE
1. IF READY(TIGERS_FURY) AND player.energy <= 50 THEN RETURN TIGERS_FURY
2. IF target.aura(RAKE).rem <= 3 AND USABLE(RAKE) THEN RETURN RAKE
3. IF READY(BERSERK) THEN RETURN BERSERK
4. IF player.cp >= 5 AND target.aura(RIP).rem <= 5 AND USABLE(RIP) THEN RETURN RIP
5. IF player.cp >= 5 AND USABLE(FEROCIOUS_BITE) THEN RETURN FEROCIOUS_BITE
6. DEFAULT: RETURN SHRED
```

***

## Slash Commands

* `/sparc` or `/sa` — Open the SpArc Control Center.
* `/sparc msbt` — Unlock & drag MSBT scroll zones with your mouse.
* `/sparc ct` — Open the Combat Text & Distance Fade tab.
* `/sparc np` — Open the Metro Tile Nameplates & DoT Color Rules tab.
* `/sparc cam` — Open the Action Combat Camera tab.
* `/sparc macro` — Open the SpellBook Wrapper Macro Generator tab.
* `/sparc profiles` — Open the Per-Character Profiles tab.
* `/sparc debug` — Capture a telemetry snapshot and open the Debugger tab.
* `/sparc en` | `/sparc ru` — Switch interface language between English and Russian.
