# SpArc v2.9.0 — Changelog / Список изменений

## 🇬🇧 English — What's New in v2.9.0

### ✨ 1. New Module (Tab 9): SpellBook Wrapper Macro Generator (`/sparc macro`)
* **Automated Class & Spec Macro Generation:** Scans your active SpellBook (**Class** tab and **Active Specialization** tab), automatically filtering out passives, sub-ranks, mounts, and non-combat utility spells.
* **Customizable Macro Templates:** Generates target-safe wrapper macros (`#showtooltip`, `/stopmacro [flying]`, `/cast [@target] SpellName`, or one-click switch to `[@mouseover,harm,nodead][@target]`).
* **Smart Naming & Overflow Policy:**
  * Names Class spells `<class_initial><N>` (e.g., `m1, m2...`, `p1, p2...`, `w1, w2...`) and Specialization spells `<spec_initial><class_initial><N>` (e.g., `fm1, fm2...`, `sp1, sp2...`).
  * Fills **Character Macros** first (up to `30` slots) and automatically overflows into **General Account Macros** (up to `120` slots).
  * **100% Safe:** Never overwrites or deletes existing user macros, and skips spells that are already present in your macros.

### ❄️ 2. Midnight (12.x) Frost Mage Overhaul & Target Debuff Stack Engine
* **Target Debuff Stack Tracking (`# TARGET_DEBUFF` & `STACKS:+N / -N`):**
  * Added `# TARGET_DEBUFF: ID:... | NAME:"..."` header support and `STACKS:+N`, `STACKS:-N`, and `CONSUMES_STACKS:true` spell properties.
  * Tracks live target debuff stacks (such as Frost Mage's *Freezing / Обледенение* shatter stacks) via `C_UnitAuras` with predictive simulation across all 5 lookahead steps in the rotation queue.
* **Midnight 12.x Spell Transformation Support (`OVERRIDE_OF`):**
  * Added `OVERRIDE_OF:<BASE_KEY>` and `C_Spell.GetOverrideSpell` tracking for abilities that temporarily transform a base spell button in Midnight 12.x (e.g., *Comet Storm* overriding *Ray of Frost*, *Glacial Spike* overriding *Frostbolt*).
* **Multi-Charge & Haste-Scaled Cooldown Engine:**
  * Added `CHARGES(KEY) >= N` FSM condition support and dynamic `UnitSpellHaste` scaling for multi-charge cooldowns (*Flurry*, *Mind Blast*, *Tentacle Slam*).
  * Fixed a post-cast `C_AssistedCombat` 50ms cache race condition where casting a charge ability (*Flurry*) could immediately refund a simulated charge on the next frame.
* **Updated Built-In Frost Mage Presets (`MAGE_04_FROST_PVE`, `MAGE_05_FROST_PVP`):** Rebuilt for the World of Warcraft: Midnight (12.x) Icy Veins priority list (*Comet Storm -> Ray of Frost + Flurry -> Frozen Orb -> Glacial Spike -> 4-stack/Fingers of Frost Ice Lance -> Frostbolt*).

### ⏱️ 3. HUD Cooldown & GCD Radial Sweep + Single-Icon Press Bounce
* **Native Cooldown & GCD Clock Sweep:** Enabled Blizzard's radial cooldown spiral and glowing edge (`SetDrawSwipe(true)` + `SetDrawEdge(true)`) across all semicircle rotation queue icons and side cooldown wings, complete with a haste-accurate GCD tracker under Midnight's combat `SECRET` restrictions.
* **Precision Single-Icon Press Feedback ("Spring" Bounce):**
  * Fixed the `-20% -> +20%` press-bounce animation so it only animates the **single pressed spell icon** (the active slot being executed) rather than bouncing all repeated filler copies in the queue simultaneously.
  * Prevented hard-cast spells (*Frostbolt*, *Vampiric Touch*, *Mind Blast*) from triggering a second bounce or phantom GCD when their cast finishes (`UNIT_SPELLCAST_SUCCEEDED`).
  * Added `GetMacroSpell` resolution for macro slots on action bar press hooks.

### 🤖 4. Preset Management & Universal AI Prompt Specification
* **Delete / Reset Preset Button:** Added a **Delete Preset** button in Tab 1 (`Rotation Presets`) to remove custom presets or restore built-in presets to factory defaults.
* **Complete AI Compiler Prompt (`Tab 2 -> AI Prompt (Ctrl+C)`):** Rewrote the built-in AI prompt in both English and Russian with the complete 6-section SpArc `.MD` compiler specification so **Gemini**, **ChatGPT**, or **Claude** can convert any **Icy Veins** or **Wowhead** rotation guide into a ready-to-import `.MD` profile.

### 🛠️ 5. Bug Fixes & Combat Lockdown Safety
* Fixed an `ADDON_ACTION_BLOCKED` taint warning when `ApplyCombatCameraBindings` was triggered during combat lockdown; camera override bindings are now safely deferred until `PLAYER_REGEN_ENABLED`.

---

## 🇷🇺 Русский — Что нового в версии v2.9.0

### ✨ 1. Новый модуль (Вкладка 9): Макросогенератор обвязок по книге заклинаний (`/sparc macro`)
* **Автоматическое сканирование книги заклинаний:** Сканирует активные вкладки **«Класс»** и **«Специализация»**, автоматически отсеивая пассивки, саб-ранги, маунтов и мирные способности.
* **Настраиваемый шаблон макросов:** Генерирует готовые боевые макросы-обвязки (`#showtooltip`, `/stopmacro [flying]`, `/cast [@target] Название`, либо переключение в один клик на шаблон с `[@mouseover,harm,nodead][@target]`).
* **Умная схема именования и авто-перелив в Общие макросы:**
  * Классовые заклинания получают имена `<1-я буква класса><N>` (`m1, m2...`, `p1, p2...`, `w1, w2...`), а спековые — `<1-я буква спека><1-я буква класса><N>` (`fm1, fm2...`, `sp1, sp2...`).
  * Сначала заполняет **Макросы персонажа** (до `30` слотов), а при нехватке места автоматически продолжает создание в **Общих макросах аккаунта** (до `120` слотов).
  * **Безопасность 100%:** Никогда не перезаписывает и не удаляет существующие макросы игрока и пропускает спеллы, для которых уже есть макрос.

### ❄️ 2. Полная переработка Фрост Мага под Midnight (12.x) и движок стаков дебаффов
* **Трекинг стаков дебаффа на цели (`# TARGET_DEBUFF` и `STACKS:+N / -N`):**
  * Добавлена директива шапки `# TARGET_DEBUFF: ID:... | NAME:"..."` и флаги спеллов `STACKS:+N`, `STACKS:-N`, `CONSUMES_STACKS:true`.
  * Отслеживает реальные стаки дебаффа на цели (например, *«Обледенение» / «Freezing»* у Мага Льда) через `C_UnitAuras` и симулирует их накопление и трату на 5 шагов вперёд в очереди ротации.
* **Поддержка комбо-замен кнопок Midnight 12.x (`OVERRIDE_OF`):**
  * Добавлен флаг `OVERRIDE_OF:<БАЗОВЫЙ_КЛЮЧ>` и проверка `C_Spell.GetOverrideSpell` для заклинаний, временно заменяющих базовую кнопку (например, *«Кометная буря»* поверх *«Морозного луча»* и *«Ледовый шип»* поверх *«Ледяной стрелы»*).
* **Точный учёт зарядов и Скорости (`UnitSpellHaste`):**
  * Добавлено условие `CHARGES(KEY) >= N` для компилятора `.MD` и пересчёт времени отката зарядов с учётом текущей Скорости персонажа (*«Шквал»*, *«Взрыв разума»*, *«Темное сокрушение»*).
  * Исправлена гонка таймингов (race condition) с кэшем `C_AssistedCombat` в первые 50 мс после каста, из-за которой *«Шквал»* мог оставаться в подсказке после ухода на КД.
* **Обновлены пресеты Мага Льда (`MAGE_04_FROST_PVE`, `MAGE_05_FROST_PVP`)** строго по гайду Icy Veins для патча Midnight 12.x.

### ⏱️ 3. Радиальные часики ГКД / КД и точечная «пружинка» нажатия
* **Эффект ГКД и КД по колоде подсказок:** На всех иконках дуги ротации и боковых крыльев включена родная близзовская круговая шторка перезарядки со светящейся гранью (`SetDrawSwipe` + `SetDrawEdge`) и синхронный трекер ГКД (с обходом боевых `SECRET`-ограничений Midnight).
* **Точечная «пружинка» нажатия (как на экшен-барах):**
  * Анимация сжатия-отскока (`-20% -> +20%`) теперь срабатывает **только на одной нажимаемой иконке** (первом совпавшем слоте очереди), а не на всех одинаковых филлерах в очереди сразу.
  * Убрано ложное повторное срабатывание пружинки и ГКД в момент завершения длинного каста (`UNIT_SPELLCAST_SUCCEEDED` после `UNIT_SPELLCAST_START`).
  * Добавлено распознавание заклинаний внутри макро-слотов через `GetMacroSpell`.

### 🤖 4. Управление пресетами и новая спецификация промпта для ИИ
* **Кнопка «Удалить пресет»:** Во вкладке `Пресеты ротаций` добавлена кнопка удаления кастомных пресетов (или сброса встроенного пресета к заводскому коду).
* **Универсальный промпт для ИИ (`Псевдокод .MD и ИИ -> Промпт для ИИ (Ctrl+C)`):** Полностью переписан встроенный промпт (на русском и английском) со всеми правилами компилятора SpArc `.MD`, чтобы **Gemini**, **ChatGPT** или **Claude** могли сходу написать ротацию с **Icy Veins / Wowhead** для любого класса и спека.

### 🛠️ 5. Исправления ошибок и защита от Taint в бою
* Исправлена ошибка `[ADDON_ACTION_BLOCKED]` при попытке обновления оверрайд-биндов Боевой Камеры в бою (`InCombatLockdown()`); применение биндов теперь безопасно откладывается до выхода из боя (`PLAYER_REGEN_ENABLED`).
