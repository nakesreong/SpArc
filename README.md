# SpArc — FSM Rotation Queue (.MD), Metro Nameplates, MSBT & Action Combat Camera

**Version:** 2.9.5  
**Authors:** Gemini (Tiger) & Anya (5cr3am1ng5oul)  
**Compatibility:** World of Warcraft: Retail / Midnight (`12.0.1`, `12.1.5`, `12.1.7`) & The War Within (`11.2.7`)  
**Source Repository:** [https://github.com/nakesreong/SpArc](https://github.com/nakesreong/SpArc)  
**License:** MIT

***

## Overview (EN)

**SpArc** (*Spell Arc*) is an all-in-one, high-FPS combat interface for **World of Warcraft 12.x (Midnight)**. It replaces a stack of heavy, conflicting combat addons with a single modular engine where your rotation logic is written in human-readable **Markdown (`.md`) pseudocode**, paired with **Metro DoT Nameplates**, **Movable MSBT Scroll Zones**, and a standalone **Action Combat Camera**.

### Key Features

* **`.MD` Rotation Queue & AI Prompt Generator:** Includes **56 built-in presets** across all 13 classes. Bend your rotation queue into an overhead dome (`+180°`), flat bar (`0°`), or under-character bowl (`-180°`) with flanking **Defensive Saves** and **Burst Cooldown Wings**. Generate new `.md` rotations with Gemini, ChatGPT, or Claude in one click.
* **Metro Tile Nameplates & Distance Fade:** Flat, zero-lag nameplates that automatically pull tracked DoTs from your active `.md` preset, recolor bars by single or multi-DoT (`AND`) combinations, stack vertically on packs, and smoothly fade distant targets (`20–60 yd`).
* **Movable MSBT Scroll Zones & Tactile Target Numbers:** Drag-and-drop **Incoming** and **Outgoing** scrolling combat text zones (`MSBT Outward Arc`, `Straight Up`, or `Fountain Wave`), soft compact yellow damage numbers high above your target, Smart AoE periodic tick filtering, and complete suppression of center-screen banner clutter.
* **Action Combat Camera (Mouselook):** Locks camera mouselook with customizable `onHold` (`G`), `onPress` (`` ` ``), and `Interact` (`E`) keys, crosshair `@mouseover`/`@cursor` alignment, `LMB`/`RMB` click-casting, and optional out-of-combat form unshifting.
* **Dual-Direction Castbar, Class Resource Bar & Macro Generator:** Castbar with filler-channel clip alerts, universal secondary resource bar (Insanity, Combo Points, Chi, Holy Power, Runes, Essence, etc.), SpellBook wrapper macro generator (`/sparc macro`), and **ElvUI-style isolated character profiles** with instant `EN / RU` language switching.

### Standing on the Shoulders of Giants (Inspiration & Credits)

* **MikScrollingBattleText (MSBT) & NameplateSCT:** for the concept of separated, movable side-screen incoming/outgoing scroll arcs and tactile number fountains.
* **Plater Nameplates & Threat Plates:** for smart health bar recoloring by DoT combinations, vertical anti-overlap stacking, and smooth distance fading.
* **WeakAuras & Hekili:** for the central predictive rotation queue and flanking defensive/offensive cooldown wings.
* **ConsolePort & Combat Mode:** for turning the classic MMO camera into true action-RPG combat with a reticle and one-button targeting.
* **ElvUI & WindTools:** for the clean dark-graphite UI aesthetic, isolated character profiles, and suppression of noisy default banners.

> *«Special thanks for the inspiration to the creators of MSBT, Plater, WeakAuras, Hekili, Combat Mode & ElvUI — their finest ideas live on under this single high-FPS roof.»*

***

## Описание на русском (RU)

**SpArc** (*Spell Arc*) — единый высокопроизводительный боевой интерфейс для **World of Warcraft 12.x (Midnight)** без просадок FPS. Он объединяет под одной крышей визуализатор ротаций на базе человекочитаемого **псевдокода Markdown (`.md`)**, минималистичные **неймплейты Metro**, собственный движок **подвижных зон боевого текста MSBT** и **Боевую Камеру (Action Camera)**.

### Главные возможности

* **Дуга ротации на базе `.MD` и ИИ-генератор:** **56 встроенных пресетов** для всех 13 классов. Настраиваемый изгиб очереди от чаши под персонажем (`-180°`) и прямой линии (`0°`) до купола (`+180°`), боковые «крылья» сейвов и бурстов, а также встроенный генератор промптов для Gemini / ChatGPT.
* **Неймплейты Metro и фейдинг по дальности:** Плоские плитки без фризов, которые сами подтягивают ID ваших дотов из активного `.md`-пресета, перекрашивают полоски ХП по одиночным дотам и их комбинациям (`И`), раздвигаются лесенкой на паках и плавно становятся прозрачнее вдалеке (`20–60 м`).
* **Подвижные зоны MSBT и мягкая «хаптика» над целью:** Перетаскиваемые мышкой боковые зоны **Входящего** и **Исходящего** текста (`Дуга MSBT`, `Прямо вверх`, `Волна`), аккуратные неяркие жёлтые цифры урона высоко над целью, умный АоЕ-фильтр тиков дотов на паках (`3+` врагов) и полное подавление спам-баннеров посреди экрана.
* **Боевая Камера (Mouselook):** Привязка камеры к мыши с прицелом, таргетингом и взаимодействием по кнопке (`E`), освобождением курсора при удержании (`G`), клик-кастом (`ЛКМ`/`ПКМ`) и опциональным снятием облика Тьмы/Друида вне боя на земле.
* **Двунаправленный кастбар, ресурс, макросы и профили:** Кастбар с подсказкой прерывания потокового филлера, универсальная полоска ресурса класса, генератор макросов-обвязок (`/sparc macro`), изолированные профили персонажей и мгновенное переключение языка `RU / EN` в правом верхнем углу окна.

### Благодарности за вдохновение

* **MikScrollingBattleText (MSBT) & NameplateSCT:** за идею разнесённых по краям экрана подвижных дуг входящего/исходящего текста и тактильного фонтана цифр.
* **Plater Nameplates & Threat Plates:** за концепцию умной перекраски полосок здоровья по комбинациям дотов, раздвижение лесенкой и фейдинг дальних целей.
* **WeakAuras & Hekili:** за идею центральной очереди ротации и боковых «крыльев» сейвов и кулдаунов.
* **ConsolePort & Combat Mode:** за превращение классической камеры в полноценный экшен с прицелом и таргетингом по кнопке.
* **ElvUI & WindTools:** за строгую графитовую эстетику интерфейса, систему изолированных профилей и подавление лишних стандартных баннеров.

> *«Отдельное спасибо за вдохновение авторам легендарных аддонов: MSBT, Plater, WeakAuras, Hekili, Combat Mode и ElvUI — мы собрали ваши лучшие идеи под одной крышей с любовью к чистым фреймам и высокому FPS».*

***

## Slash Commands / Команды чата

* `/sparc` — Open Control Center / Открыть центр управления
* `/sparc msbt` — Unlock & drag MSBT scroll zones / Двигать зоны текста MSBT
* `/sparc ct` — Combat Text & Distance Fade settings / Настройки боевого текста и дальности
* `/sparc np` — Metro Nameplates & DoT Colors / Неймплейты Metro и цвета дотов
* `/sparc cam` — Action Combat Camera / Боевая Камера и клавиши
* `/sparc macro` — SpellBook Wrapper Macro Generator / Макросогенератор
* `/sparc prof` — Character Profiles / Профили персонажей
* `/sparc debug` — SpellBook & Rotation Telemetry / Телеметрия и отладка
* `/sparc ru` | `/sparc en` — Switch UI language / Переключить язык интерфейса
