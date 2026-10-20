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
3. **Side Cooldown Wings (`TRACK_SAVES` & `TRACK_CDS`) & Center Emergency Save (`RETURN EMERGENCY`):**
   - **Left Wing (4 Defensive Saves):** Displays up to 4 defensive cooldowns (glowing green border when ready, desaturated with cooldown spiral & timer when on cooldown). Can be toggled on/off in Tab 3 (`showSavesWing`).
   - **Right Wing (4 Offensive Cooldowns):** Displays up to 4 major offensive/burst cooldowns on the right side. Can be toggled on/off in Tab 3 (`showCDsWing`).
   - **Center Emergency Save:** Flashes a large central alert (`СЕЙВ!`) when Player HP drops below the configured threshold (`<= 25%`). Can be toggled on/off in Tab 3 (`showEmergencySave`).

---

## 📝 How to Add Defensive Saves & Offensive CDs in `.MD` Pseudocode

Every aspect of the side wings and emergency save is controlled directly inside your `.md` profile (Tab 2):

```markdown
## SPELL_BOOK (Declare your spells with SpellID, names, and cooldowns)
SPELL DISPERSION = ID:47585 | NAME:"Dispersion","Слияние с тьмой" | CD:90 | ICON:237563
SPELL DESPERATE_PRAYER = ID:19236 | NAME:"Desperate Prayer","Молитва отчаяния" | CD:90 | ICON:237550
SPELL VAMPIRIC_EMBRACE = ID:15286 | NAME:"Vampiric Embrace","Объятия вампира" | CD:120 | ICON:136230
SPELL FADE = ID:586 | NAME:"Fade","Уход в тень" | CD:30 | ICON:135994
SPELL POWER_INFUSION = ID:10060 | NAME:"Power Infusion","Придание сил" | CD:120 | ICON:135939
SPELL VOID_ERUPTION = ID:228260 | NAME:"Void Eruption","Извержение Бездны" | CD:120 | ICON:537079

## TRACKERS (Left Wing = up to 4 Defensive Saves | Right Wing = up to 4 Offensive CDs)
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, PSYFIEND

## EMERGENCY_SAVE (Center Alert when HP drops below threshold)
IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
ELSE IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
END IF
```

---

## 💬 Slash Commands

- `/sparc` or `/sa` — Open the **SpArc Control Center** (4 Tabs: *Presets (55)*, *Markdown .MD Editor & AI Prompt*, *Visual HUD Settings*, *Telemetry & SpellBook Debugger*).
- `/sa test` — Toggle live preview mode of all HUD elements.
- `/sa debug` — Open the SpellBook vs Bartender4 vs SpArc Telemetry Auditor.
- `/sa auto` | `/sa pve` | `/sa boss` | `/sa pvp` — Switch active profile mode.
- `/sa import` — Jump straight to the `.md` pseudocode editor & AI prompt tab.
