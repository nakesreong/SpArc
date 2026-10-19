# ⚡ SpArc — Semicircle FSM Rotation, Castbar & Cooldown HUD

**Authors:** **Gemini (Tiger)** & **Anya (5cr3am1ng5oul)**  
**Compatibility:** World of Warcraft: Retail / Midnight (`12.0.1`, `12.1.5`) & The War Within (`11.2.7`)  
**License:** MIT

---

## ✨ What is SpArc?

**SpArc** (*ShadowPriest · Spark · Arc*) is a **100% data-driven, pseudocode-powered Finite State Machine (FSM) Rotation & Cooldown Visualizer** for World of Warcraft.

Unlike traditional rotation addons that hardcode thousands of lines of Lua class logic, **SpArc** is a pure **Markdown (`.md`) Pseudocode Visualizer**:
- **Zero Hardcoded Class Logic:** Every spell, macro mapping, resource cost/gain, channel interrupt policy, defensive save, offensive cooldown, and priority transition is defined in human-readable `.md` pseudocode profiles.
- **AI-Ready (Gemini / ChatGPT):** Includes a built-in AI Prompt Generator in `/sparc` — ask your **Gemini** or **ChatGPT** to convert any **Icy Veins / Wowhead** guide into the `SpArc .MD` format and paste it directly into the in-game editor!
- **55 Built-In Presets (10 per Class / Active Selection):** Ships with 55 pre-configured presets across all 13 WoW classes (including 10 specialized Priest presets for Shadow PvE, Boss, PvP, Archon, Voidweaver, Delves, Speedrun, Discipline, and Holy).
- **Smart Channel Interrupt Detection:** Knows the difference between a **protected channel** (e.g., *Void Torrent* — never clip!) and an **interruptible filler channel** (e.g., *Mind Flay* — flashes `⚡ ПРЕРВИ!` as soon as any higher-priority spell comes off cooldown or procs!).

---

## 🎯 HUD Architecture

1. **Top Semicircle Rotation Queue (`10 o'clock` clockwise):**
   - **Slot #1 (`10 o'clock`, 150% scale, glowing):** The immediate spell to press right now, with live Bartender4 / CombatMode keybind resolution (`M1`, `M2`, `SM1`, `SM2`, `R`, `SE`, `SR`, etc.).
   - **Slots #2–#5 (`11 -> 12 -> 1 -> 2 o'clock`):** Predictive FSM queue simulating upcoming GCD state transitions (DoT application, Insanity/Resource generation & spending, charge consumption, and proc chains).
2. **Dual-Direction Custom Castbar:**
   - **Normal Casts:** Fills **Left → Right** (`0% → 100%`).
   - **Channeled Spells:** Drains **Right → Left** (`100% → 0%`) and displays live channel protection (`🔒 КАНАЛ`) or filler-interrupt alerts (`⚡ ПРЕРВИ ФИЛЛЕР!`).
3. **Cooldown & Emergency Save Tracker:**
   - **Center Emergency Save:** Flashes at the center of the screen when Player HP drops below the configured threshold (`<= 25%`).
   - **Left Wing:** Tracks 4 Defensive Saves (ready vs. desaturated with cooldown spiral & timer).
   - **Right Wing:** Tracks 4 Offensive DPS Cooldowns near the target unit frame.

---

## 💬 Slash Commands

- `/sparc` or `/sa` — Open the **SpArc Control Center** (3 Tabs: *Presets (55)*, *Markdown .MD Editor & AI Prompt*, *Visual HUD Settings*).
- `/sa test` — Toggle live preview mode of all HUD elements.
- `/sa auto` | `/sa pve` | `/sa boss` | `/sa pvp` — Switch active profile mode.
- `/sa import` — Jump straight to the `.md` pseudocode editor & AI prompt tab.
