---------------------------------------------------------------------------------------
--  SpArc/Locale.lua — Bilingual Localization System (EN / RU) & AI Prompt Templates
--                     Automatically detects WoW client locale (GetLocale()), with
--                     instant in-game language toggle in the Control Center header.
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc or _G.SparkArc or {}
_G.SpArc = SpArc
_G.SparkArc = SpArc

local GetLocale = _G.GetLocale

function SpArc:GetActiveLang()
  local db = _G.SpArcDB
  local pref = db and db.visual and db.visual.lang
  if pref == "RU" or pref == "EN" then
    return pref
  end
  local loc = (GetLocale and GetLocale()) or "enUS"
  if loc == "ruRU" then
    return "RU"
  end
  return "EN"
end

function SpArc:IsRU()
  return SpArc:GetActiveLang() == "RU"
end

local STRINGS = {
  EN = {
    WINDOW_TITLE = "|cffa335eeSpArc v%s|r — Semicircle FSM Rotation & Cooldown HUD (.MD & AI)",
    WINDOW_SUBTITLE = "Authors: |cffffd100Gemini (Tiger) & Anya (5cr3am1ng5oul)|r  •  SpellID + Bartender4 Keybind Resolver",
    LANG_BTN = "Lang: EN",

    TAB_1 = "1. Presets (55)",
    TAB_2 = "2. .MD Editor & AI",
    TAB_3 = "3. Visual & HUD",
    TAB_4 = "4. Telemetry / Debug",

    P1_SUMMARY = "Total Presets: |cffffd100%d|r  |  Your Class (%s): |cff00ff00%d|r  |  Active: |cffa335ee%s|r (%s)",
    FILTER_CLASS = "Filter: Only %s (%d)",
    FILTER_ALL = "Filter: All Classes (%d)",
    MODE_AUTO = "Mode: AUTO (PvE/Boss/PvP)",
    MODE_MANUAL = "Mode: Manual Preset",
    NEW_PRESET_BTN = "+ New Preset",
    NEW_PRESET_TITLE = "%d. Custom %s #%d",
    PREFIX_ACTIVE = "|cff00ff00[ACTIVE]|r ",
    PREFIX_SELECTED = "|cffffd100[>]|r ",

    DETAILS_BODY = "|cffffd100%s|r\n\n"
      .. "• Class / Mode: |cff00ccff%s (%s)|r\n"
      .. "• FSM Rotation Rules: |cff00ff00%d|r\n"
      .. "• Left Wing Saves (TRACK_SAVES): |cff00ff00%s|r\n"
      .. "• Right Wing CDs (TRACK_CDS): |cff00ff00%s|r\n"
      .. "• Interruptible Filler: |cffff40a0%s|r\n"
      .. "• Protected Channel: |cff40d0ff%s|r\n\n"
      .. "|cffaaaaaaAll rotation logic, side wings, and emergency alerts are compiled live from editable .MD pseudocode with zero hardcoded class logic.|r",
    NONE_STR = "none",

    ACTIVATE_BTN = "Set as Active Preset",
    OPEN_MD_BTN = "Edit .MD Pseudocode / AI ->",
    TEST_HUD_BTN = "Preview HUD on Screen (ON/OFF)",
    MSG_ACTIVATED = "|cffa335eeSpArc:|r Activated preset: |cffffd100%s|r",

    AI_BANNER_PREFIX = "AI Helper: ",
    AI_PROMPT_BTN = "AI Prompt (Ctrl+C)",
    AI_BACK_BTN = "<- Back to .MD Code",
    AI_STATUS_COPY = "|cff00ff00Copy this prompt (Ctrl+C), paste it into Gemini or ChatGPT with an Icy Veins / Wowhead guide, and paste the result back into the .MD editor:|r",
    EDITOR_STATUS = "Preset: |cffffd100%s|r  |  FSM Rules: |cff00ff00%d|r  |  Left Saves: |cff00ff00%d|r  |  Right CDs: |cff00ff00%d|r",
    SAVE_MD_BTN = "Save .MD to Preset",
    RESET_MD_BTN = "Reset Preset to Default",
    MSG_MD_SAVED = "|cffa335eeSpArc:|r .MD pseudocode saved and compiled for |cffffd100%s|r!",

    V_HEADER = "Configure Semicircle Rotation Arc, Side Cooldown Wings, Castbar & Minimap Button:",
    SL_ARC_RADIUS = "Semicircle Arc Radius (px)",
    SL_ARC_SPREAD = "Semicircle Arc Spread Angle (°)",
    SL_PRIMARY_SCALE = "Primary Slot #1 Scale",
    SL_QUEUE_SCALE = "Queue Slots (#2..#6) Scale",
    SL_QUEUE_LEN = "Number of Arc Icons (3..6)",
    SL_ARC_OFFSET_Y = "Arc Vertical Offset Y (px)",
    SL_CB_WIDTH = "Castbar Width (px)",
    SL_CB_OFFSET_Y = "Castbar Vertical Offset Y (px)",
    SL_EMERG_HP = "Emergency Save HP Threshold (%)",
    SL_WINGS_Y = "Side Wings Vertical Offset Y (px)",

    CK_SAVES_WING = "Show Left Defensive Saves Wing (defined by TRACK_SAVES in .MD)",
    CK_CDS_WING = "Show Right Offensive Cooldowns Wing (defined by TRACK_CDS in .MD)",
    CK_EMERG_SAVE = "Show Center Emergency Save Alert on Low HP (RETURN EMERGENCY in .MD)",
    CK_ALWAYS_CDS = "Always show enabled Side Wings even out of combat & with no target",
    CK_INTERRUPT = "Flash 'CLIP CHANNEL!' when a higher-priority spell comes ready during filler channel",
    CK_CASTBAR = "Show Dual-Direction SpArc Castbar (Left->Right cast / Right->Left channel)",
    CK_MINIMAP = "Show SpArc Minimap Button (Left-Click: Settings, Right-Click: Telemetry)",
    CK_TEST_MODE = "Test / Preview Mode (display full rotation arc, wings, and castbar right now)",

    TEL_HEADER = "|cffffd100Telemetry & Debugger:|r compares SpArc queue decisions against live SpellBook & Bartender4 state",
    TEL_SNAP_BTN = "Capture Snapshot Now",
    TEL_COPY_BTN = "Select All (Ctrl+C)",
    TEL_CLEAR_BTN = "Clear Log & BugSack",
    TEL_TOGGLE = "Log ON",

    HUD_SAVE_ALERT = "SAVE!",
    HUD_CLIP_BANNER = "CLIP CAST!",
    HUD_CHANNEL_BANNER = "CHANNEL...",
    HUD_CB_CLIP = "CLIP FILLER -> PRESS [%s]!",
    HUD_CB_PROTECTED = " [DO NOT CLIP]",
    HUD_TEST_CHANNEL = "Mind Flay (Filler Channel <-)",
    HUD_TEST_CAST = "Vampiric Touch (Normal Cast ->)",

    MM_TT_TITLE = "|cffa335eeSpArc v%s|r — Semicircle Rotation & Cooldown HUD",
    MM_TT_LEFT = "|cffffd100Left-Click:|r Open Presets, .MD Editor & Settings",
    MM_TT_RIGHT = "|cffffd100Right-Click:|r Open SpellBook Telemetry Debugger",
    MM_TT_SHIFT = "|cffffd100Shift + Left-Click:|r Toggle HUD Test Preview (ON/OFF)",
    MM_TT_DRAG = "|cffaaaaaaHold Left-Click: Drag button around Minimap|r",

    MSG_TEST_TOGGLE = "|cffa335eeSpArc:|r HUD Test Preview: %s",
    MSG_ON = "|cff00ff00ON|r",
    MSG_OFF = "|cffff4040OFF|r",
  },

  RU = {
    WINDOW_TITLE = "|cffa335eeSpArc v%s|r — Визуализатор FSM-ротаций (.MD Псевдокод, ИИ & Телеметрия)",
    WINDOW_SUBTITLE = "Авторы: |cffffd100Gemini (Tiger) & Anya (5cr3am1ng5oul)|r  •  SpellID + Bartender4 Keybind Resolver",
    LANG_BTN = "Язык: RU",

    TAB_1 = "1. Пресеты (55)",
    TAB_2 = "2. Импорт .MD и ИИ",
    TAB_3 = "3. Визуал и HUD",
    TAB_4 = "4. Телеметрия / Дебаг",

    P1_SUMMARY = "Всего пресетов: |cffffd100%d|r  |  Для вашего класса (%s): |cff00ff00%d|r  |  Активный: |cffa335ee%s|r (%s)",
    FILTER_CLASS = "Фильтр: Только %s (%d)",
    FILTER_ALL = "Фильтр: Все классы (%d)",
    MODE_AUTO = "Режим: AUTO (ПвЕ/Босс/ПвП)",
    MODE_MANUAL = "Режим: Ручной пресет",
    NEW_PRESET_BTN = "+ Новый пресет",
    NEW_PRESET_TITLE = "%d. Кастомный %s #%d",
    PREFIX_ACTIVE = "|cff00ff00[АКТИВЕН]|r ",
    PREFIX_SELECTED = "|cffffd100[>]|r ",

    DETAILS_BODY = "|cffffd100%s|r\n\n"
      .. "• Класс / Режим: |cff00ccff%s (%s)|r\n"
      .. "• Правил ротации в автомате: |cff00ff00%d|r\n"
      .. "• Крыло сейвов слева (TRACK_SAVES): |cff00ff00%s|r\n"
      .. "• Крыло бурстов справа (TRACK_CDS): |cff00ff00%s|r\n"
      .. "• Прерываемый филлер: |cffff40a0%s|r\n"
      .. "• Защищённый канал: |cff40d0ff%s|r\n\n"
      .. "|cffaaaaaaВся логика ротации, боковых крыльев КД и экстренного сейва компилируется напрямую из текстового .MD псевдокода без хардкода!|r",
    NONE_STR = "нет",

    ACTIVATE_BTN = "Сделать активным пресетом",
    OPEN_MD_BTN = "Открыть псевдокод .MD / ИИ ->",
    TEST_HUD_BTN = "Тест HUD на экране (ВКЛ/ВЫКЛ)",
    MSG_ACTIVATED = "|cffa335eeSpArc:|r Активирован пресет: |cffffd100%s|r",

    AI_BANNER_PREFIX = "ИИ-Подсказка: ",
    AI_PROMPT_BTN = "Промпт для ИИ (Ctrl+C)",
    AI_BACK_BTN = "<- Вернуться к .MD коду",
    AI_STATUS_COPY = "|cff00ff00Скопируйте этот промпт (Ctrl+C), отправьте своему Gemini или ChatGPT вместе с гайдом с Icy Veins / Wowhead и вставьте ответ обратно в редактор .MD:|r",
    EDITOR_STATUS = "Пресет: |cffffd100%s|r  |  Правил FSM: |cff00ff00%d|r  |  Сейвов слева: |cff00ff00%d|r  |  КД справа: |cff00ff00%d|r",
    SAVE_MD_BTN = "Сохранить .MD в пресет",
    RESET_MD_BTN = "Сброс пресета по умолч.",
    MSG_MD_SAVED = "|cffa335eeSpArc:|r Псевдокод .MD сохранён и скомпилирован для |cffffd100%s|r!",

    V_HEADER = "Настройки полукруга ротации, боковых крыльев сейвов/КД, кастбара и миникарты:",
    SL_ARC_RADIUS = "Радиус полукруга ротации (px)",
    SL_ARC_SPREAD = "Угол раскрытия полукруга (°)",
    SL_PRIMARY_SCALE = "Масштаб главной иконки #1",
    SL_QUEUE_SCALE = "Масштаб очереди (#2..#6)",
    SL_QUEUE_LEN = "Кол-во иконок в дуге (3..6)",
    SL_ARC_OFFSET_Y = "Смещение дуги по Y (px)",
    SL_CB_WIDTH = "Ширина кастбара (px)",
    SL_CB_OFFSET_Y = "Смещение кастбара по Y (px)",
    SL_EMERG_HP = "Порог ХП экстренного сейва (%)",
    SL_WINGS_Y = "Высота крыльев сейвов/КД по Y (px)",

    CK_SAVES_WING = "Показывать левое крыло сейвов (строка TRACK_SAVES в .MD псевдокоде)",
    CK_CDS_WING = "Показывать правое крыло бурстов и КД (строка TRACK_CDS в .MD псевдокоде)",
    CK_EMERG_SAVE = "Показывать экстренный сейв в центре при низком ХП (RETURN EMERGENCY в .MD)",
    CK_ALWAYS_CDS = "Всегда показывать включенные крылья сейвов/КД (даже вне боя и без цели)",
    CK_INTERRUPT = "Подсвечивать 'ПРЕРВИ КАСТ!', когда во время филлера (Пытка разума) откатился спелл",
    CK_CASTBAR = "Показывать двойной кастбар SpArc (слева->направо каст / справа->налево потоковый)",
    CK_MINIMAP = "Показывать иконку-кнопку SpArc у миникарты (ЛКМ — настройки, ПКМ — телеметрия)",
    CK_TEST_MODE = "Тестовый режим (показать превью всей дуги, кастбара и крыльев прямо сейчас)",

    TEL_HEADER = "|cffffd100Телеметрия и Дебаг:|r сравнивает выбор SpArc с реальным ответом книги заклинаний и панелей Bartender4",
    TEL_SNAP_BTN = "Снять слепок сейчас",
    TEL_COPY_BTN = "Выделить всё (Ctrl+C)",
    TEL_CLEAR_BTN = "Очистить лог и BugSack",
    TEL_TOGGLE = "Сбор ВКЛ",

    HUD_SAVE_ALERT = "СЕЙВ!",
    HUD_CLIP_BANNER = "ПРЕРВИ КАСТ!",
    HUD_CHANNEL_BANNER = "КАНАЛ...",
    HUD_CB_CLIP = "ПРЕРВИ ФИЛЛЕР -> ЖМИ [%s]!",
    HUD_CB_PROTECTED = " [НЕ ПРЕРЫВАЙ]",
    HUD_TEST_CHANNEL = "Пытка разума (Филлер <-)",
    HUD_TEST_CAST = "Прикосновение вампира (Каст ->)",

    MM_TT_TITLE = "|cffa335eeSpArc v%s|r — Rotation & Cooldown HUD",
    MM_TT_LEFT = "|cffffd100ЛКМ:|r Открыть окно настроек, .MD псевдокода и пресетов",
    MM_TT_RIGHT = "|cffffd100ПКМ:|r Открыть Телеметрию / Дебаг книги заклинаний",
    MM_TT_SHIFT = "|cffffd100Shift + ЛКМ:|r Тестовый режим HUD (ВКЛ/ВЫКЛ)",
    MM_TT_DRAG = "|cffaaaaaaЗажать ЛКМ: Перетащить кнопку вокруг миникарты|r",

    MSG_TEST_TOGGLE = "|cffa335eeSpArc:|r Тестовый режим: %s",
    MSG_ON = "|cff00ff00ВКЛ|r",
    MSG_OFF = "|cffff4040ВЫКЛ|r",
  },
}

function SpArc:L(key)
  local lang = SpArc:GetActiveLang()
  local tbl = STRINGS[lang] or STRINGS.EN
  return tbl[key] or STRINGS.EN[key] or key
end

SpArc.AIPromptHeader_EN =
  "Ask Gemini or ChatGPT to convert any Icy Veins / Wowhead rotation guide "
  .. "into SpArc .MD pseudocode and paste it straight into this editor!"

SpArc.AIPromptHeader_RU =
  "Попросите своего Gemini или ChatGPT написать вам ротацию с Icy Veins / Wowhead "
  .. "на псевдокоде в формате SpArc .MD и засуньте её сюды!"

SpArc.AIPromptTemplate_EN = [[Hello Gemini / ChatGPT! Please write a rotation profile from Icy Veins / Wowhead for the SpArc addon (World of Warcraft: Midnight 12.x) strictly following the SpArc .MD pseudocode format below.

Class & Spec: [INSERT CLASS & SPEC, e.g., Shadow Priest]
Content Mode: [PvE Mythic+ Cleave / Raid Boss Single Target / PvP Arena]

Use strictly the following SpArc .MD syntax (output only the markdown code block):

# PROFILE: Preset Title
# CLASS: PRIEST (or MAGE, WARLOCK, PALADIN, HUNTER, ROGUE, WARRIOR, DRUID, SHAMAN, DEATHKNIGHT, MONK, DEMONHUNTER, EVOKER)
# SPEC: Shadow
# MODE: PVE (or BOSS, PVP)

## SPELL_BOOK (Declare spells with SpellIDs, localized names, optional macro names, base CD, charges, resource gain/cost, and behavior flags)
SPELL TENTACLE_SLAM = ID:1227280,205385,457042 | NAME:"Tentacle Slam","Shadow Crash" | CD:15 | CHARGES:2 | GAIN:15 | DOTS:true | ICON:136201
SPELL VAMPIRIC_TOUCH = ID:34914 | NAME:"Vampiric Touch" | CD:0 | GAIN:6 | DOTS:true | ICON:135978
SPELL VOID_TORRENT = ID:263165 | NAME:"Void Torrent" | CD:45 | GAIN:35 | GRANTS:MIND_FLAY_INSANITY | LOCK_CHANNEL:true | ICON:1386551
SPELL DEVOURING_PLAGUE = ID:335467 | NAME:"Devouring Plague","Shadow Word: Madness" | COST:50 | GRANTS:MIND_FLAY_INSANITY | SPENDER:true | ICON:252997
SPELL MIND_BLAST = ID:450983,8092 | NAME:"Mind Blast","Void Blast" | CD:7.5 | CHARGES:2 | GAIN:15 | ICON:136224
SPELL VOID_BOLT = ID:1242173,205448 | NAME:"Void Volley","Void Bolt" | CD:6 | GAIN:10 | PROC_ONLY:true | ICON:1386548
SPELL SHADOW_WORD_DEATH = ID:32379 | NAME:"Shadow Word: Death" | CD:10 | GAIN:10 | EXECUTE:true | ICON:136149
SPELL MIND_FLAY_INSANITY = ID:391403 | NAME:"Mind Flay: Insanity" | GAIN:16 | PROC_ONLY:true | ICON:136208
SPELL MIND_FLAY = ID:15407 | NAME:"Mind Flay" | GAIN:12 | FILLER_INTERRUPTIBLE:true | ICON:136208
SPELL POWER_INFUSION = ID:10060 | NAME:"Power Infusion" | CD:120 | ICON:135939
SPELL VOID_ERUPTION = ID:228260,391109 | NAME:"Void Eruption","Dark Ascension" | CD:120 | ICON:537079
SPELL PSYFIEND = ID:34433,451235 | NAME:"Shadowfiend","Voidwraith" | CD:60 | ICON:136199
SPELL DISPERSION = ID:47585 | NAME:"Dispersion" | CD:90 | ICON:237563
SPELL DESPERATE_PRAYER = ID:19236 | NAME:"Desperate Prayer" | CD:90 | ICON:237550
SPELL VAMPIRIC_EMBRACE = ID:15286 | NAME:"Vampiric Embrace" | CD:120 | ICON:136230
SPELL FADE = ID:586 | NAME:"Fade" | CD:30 | ICON:135994

## CHANNEL_POLICY (Which channeled spells should flash 'CLIP CAST!' when a higher-priority spell comes ready, and which channels must never be clipped)
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT

## TRACKERS (Optional Side Cooldown Wings: up to 4 Defensive Saves on the left via TRACK_SAVES, and up to 4 Offensive Burst CDs on the right via TRACK_CDS)
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, PSYFIEND

## EMERGENCY_SAVE (Center Screen Alert when Player HP drops below threshold)
IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
ELSE IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
END IF

## ROTATION_QUEUE (FSM Priority Rules evaluated top-to-bottom; supported conditions: NOT target.has_dots, target.has_dots, READY(X), NOT READY(X), USABLE(X), PROC(X), AND)
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF PROC(VOID_BOLT) AND READY(VOID_BOLT) THEN
    RETURN CAST(VOID_BOLT)
ELSE IF PROC(DEVOURING_PLAGUE) AND USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF PROC(MIND_FLAY_INSANITY) THEN
    RETURN CAST(MIND_FLAY_INSANITY)
ELSE IF PROC(SHADOW_WORD_DEATH) AND READY(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE
    RETURN CAST(MIND_FLAY)
END IF]]

function SpArc:GetAIPromptHeader()
  if SpArc:IsRU() then
    return SpArc.AIPromptHeader_RU
  end
  return SpArc.AIPromptHeader_EN
end

function SpArc:GetAIPromptTemplate()
  if SpArc:IsRU() then
    return SpArc.AIPromptTemplate or SpArc.AIPromptTemplate_EN
  end
  return SpArc.AIPromptTemplate_EN
end

local EN_PRESET_TITLES = {
  PRIEST_01_SHADOW_PVE = "1. Priest: Shadow — PvE / Mythic+ (Icy Veins Cleave)",
  PRIEST_02_SHADOW_BOSS = "2. Priest: Shadow — Raid Boss / Single Target",
  PRIEST_03_SHADOW_PVP = "3. Priest: Shadow — PvP Arena / Battleground",
  PRIEST_04_SHADOW_ARCHON = "4. Priest: Shadow — Archon Hero Talents (Halo)",
  PRIEST_05_SHADOW_VOIDWEAVER = "5. Priest: Shadow — Voidweaver Hero Talents",
  PRIEST_06_SHADOW_DELVES = "6. Priest: Shadow — Solo Delves & Labyrinth",
  PRIEST_07_SHADOW_SPEEDRUN = "7. Priest: Shadow — Raid Speedrun (Instant Burst)",
  PRIEST_08_DISC_PVE = "8. Priest: Discipline — PvE Atonement DPS",
  PRIEST_09_DISC_PVP = "9. Priest: Discipline — PvP Arena (Assist & Execute)",
  PRIEST_10_HOLY_PVE = "10. Priest: Holy — PvE Chastise & Holy Fire DPS",

  MAGE_01_ARCANE_PVE = "11. Mage: Arcane — PvE (Icy Veins)",
  MAGE_02_ARCANE_BOSS = "12. Mage: Arcane — Raid Boss ST",
  MAGE_03_FIRE_PVE = "13. Mage: Fire — PvE / Mythic+",
  MAGE_04_FROST_PVE = "14. Mage: Frost — PvE Cleave",
  MAGE_05_FROST_PVP = "15. Mage: Frost — PvP Arena",

  WARLOCK_01_AFF_PVE = "16. Warlock: Affliction — PvE",
  WARLOCK_02_AFF_BOSS = "17. Warlock: Affliction — Raid Boss",
  WARLOCK_03_DEMO_PVE = "18. Warlock: Demonology — PvE",
  WARLOCK_04_DESTRO_PVE = "19. Warlock: Destruction — PvE",
  WARLOCK_05_DESTRO_PVP = "20. Warlock: Destruction — PvP Arena",

  PALADIN_01_RET_PVE = "21. Paladin: Retribution — PvE / Mythic+",
  PALADIN_02_RET_BOSS = "22. Paladin: Retribution — Raid Boss ST",
  PALADIN_03_RET_PVP = "23. Paladin: Retribution — PvP Arena",
  PALADIN_04_PROT_PVE = "24. Paladin: Protection — Tank Mythic+",

  HUNTER_01_BM_PVE = "25. Hunter: Beast Mastery — PvE",
  HUNTER_02_BM_BOSS = "26. Hunter: Beast Mastery — Raid Boss",
  HUNTER_03_MM_PVE = "27. Hunter: Marksmanship — PvE",
  HUNTER_04_SURV_PVP = "28. Hunter: Survival — PvP Arena",

  ROGUE_01_ASSA_PVE = "29. Rogue: Assassination — PvE",
  ROGUE_02_OUTLAW_PVE = "30. Rogue: Outlaw — Mythic+",
  ROGUE_03_SUB_BOSS = "31. Rogue: Subtlety — Raid Boss",
  ROGUE_04_SUB_PVP = "32. Rogue: Subtlety — PvP Arena",

  WARRIOR_01_FURY_PVE = "33. Warrior: Fury — PvE / Mythic+",
  WARRIOR_02_ARGS_BOSS = "34. Warrior: Arms — Raid Boss ST",
  WARRIOR_03_ARMS_PVP = "35. Warrior: Arms — PvP Arena",
  WARRIOR_04_PROT_PVE = "36. Warrior: Protection — Tank",

  DRUID_01_BAL_PVE = "37. Druid: Balance — PvE / Mythic+",
  DRUID_02_BAL_BOSS = "38. Druid: Balance — Raid Boss ST",
  DRUID_03_FERAL_PVE = "39. Druid: Feral — PvE",
  DRUID_04_FERAL_PVP = "40. Druid: Feral — PvP Arena",

  SHAMAN_01_ELE_PVE = "41. Shaman: Elemental — PvE / Mythic+",
  SHAMAN_02_ELE_BOSS = "42. Shaman: Elemental — Raid Boss ST",
  SHAMAN_03_ENH_PVE = "43. Shaman: Enhancement — PvE",
  SHAMAN_04_ENH_PVP = "44. Shaman: Enhancement — PvP Arena",

  DK_01_UNHOLY_PVE = "45. Death Knight: Unholy — PvE",
  DK_02_FROST_PVE = "46. Death Knight: Frost — Mythic+",
  DK_03_BLOOD_PVE = "47. Death Knight: Blood — Tank",

  MONK_01_WW_PVE = "48. Monk: Windwalker — PvE",
  MONK_02_WW_PVP = "49. Monk: Windwalker — PvP Arena",
  MONK_03_BM_PVE = "50. Monk: Brewmaster — Tank",

  DH_01_HAVOC_PVE = "51. Demon Hunter: Havoc — PvE",
  DH_02_HAVOC_PVP = "52. Demon Hunter: Havoc — PvP Arena",
  DH_03_VENG_PVE = "53. Demon Hunter: Vengeance — Tank",

  EVOKER_01_DEV_PVE = "54. Evoker: Devastation — PvE",
  EVOKER_02_AUG_PVE = "55. Evoker: Augmentation — Mythic+",
}

function SpArc:GetPresetDisplayTitle(pr)
  if not pr then return "" end
  if SpArc:IsRU() then
    return pr.title or pr.id or ""
  end
  if pr.id and EN_PRESET_TITLES[pr.id] then
    return EN_PRESET_TITLES[pr.id]
  end
  local t = pr.title or pr.id or ""
  t = t:gsub("Кастомный", "Custom")
  t = t:gsub("ПвЕ / Мифик%+", "PvE / Mythic+")
  t = t:gsub("Босс / СТ", "Raid Boss / ST")
  t = t:gsub("ПвП Арена", "PvP Arena")
  return t
end

---------------------------------------------------------------------------------------
--  SpArc/Presets.lua — 55 Built-in Markdown (.md) Presets (10 Priest + 45 Cross-Class)
--                      & AI Prompt Generator (Gemini / ChatGPT -> SpArc .MD)
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc or _G.SparkArc or {}
_G.SpArc = SpArc
_G.SparkArc = SpArc

SpArc.PROFILE_SCHEMA_VERSION = 6

---------------------------------------------------------------------------------------
--                  AI PROMPT TEMPLATE (FOR GEMINI / CHATGPT)                        --
---------------------------------------------------------------------------------------
SpArc.AIPromptHeaderText =
  "Попросите своего Gemini или ChatGPT написать вам ротацию с Icy Veins / Wowhead "
  .. "на псевдокоде в формате SpArc .MD и засуньте её сюды!"

SpArc.AIPromptTemplate = [[Привет, Gemini / ChatGPT! Напиши мне профиль ротации с Icy Veins для аддона SpArc (World of Warcraft) строго в формате псевдокода SpArc .MD.

Класс и спек: [УКАЖИ КЛАСС И СПЕК, например: Жрец Тьмы / Shadow Priest]
Тип контента: [PvE Мифик+ / Босс СТ / PvP Арена]

Используй строго следующий синтаксис SpArc .MD (без лишнего текста вне блока):

# PROFILE: Название пресета
# CLASS: PRIEST (или MAGE, WARLOCK, PALADIN, HUNTER, ROGUE, WARRIOR, DRUID, SHAMAN, DEATHKNIGHT, MONK, DEMONHUNTER, EVOKER)
# SPEC: Shadow
# MODE: PVE (или BOSS, PVP)

## SPELL_BOOK (описание спеллов: ID, русские/англ имена, макросы, КД, генерация/трата ресурса, флаги)
SPELL TENTACLE_SLAM = ID:205385,457042,1234796 | NAME:"Мощный удар щупальцем","Темное сокрушение" | MACRO:"M2","sp3" | CD:15 | GAIN:15 | DOTS:true | ICON:136201
SPELL VAMPIRIC_TOUCH = ID:34914 | NAME:"Прикосновение вампира" | MACRO:"sp1pvp","sp1" | CD:0 | GAIN:6 | DOTS:true | ICON:135978
SPELL VOID_TORRENT = ID:263165 | NAME:"Поток бездны" | MACRO:"SM2" | CD:45 | GAIN:35 | GRANTS:MIND_FLAY_INSANITY | LOCK_CHANNEL:true | ICON:1386551
SPELL DEVOURING_PLAGUE = ID:335467 | NAME:"Слово Тьмы: Безумие","Всепожирающая чума" | MACRO:"sp4" | COST:50 | GRANTS:MIND_FLAY_INSANITY | SPENDER:true | ICON:252997
SPELL MIND_BLAST = ID:450983,8092 | NAME:"Выброс Бездны","Взрыв разума" | MACRO:"M1" | CD:7.5 | CHARGES:2 | GAIN:15 | ICON:136224
SPELL MIND_FLAY_INSANITY = ID:391403 | NAME:"Пытка разума: безумие" | MACRO:"sp8" | GAIN:16 | PROC_ONLY:true | ICON:136208
SPELL MIND_FLAY = ID:15407 | NAME:"Пытка разума" | MACRO:"sp8" | GAIN:12 | FILLER_INTERRUPTIBLE:true | ICON:136208

## CHANNEL_POLICY (какие потоковые касты МОЖНО и НУЖНО прерывать при откате КД/проке, а какие НЕЛЬЗЯ)
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT

## TRACKERS (Боковые крылья по 4 иконки: слева защитные сейвы TRACK_SAVES, справа бурсты и КД TRACK_CDS; каждый ключ должен быть объявлен выше в SPELL_BOOK)
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, PSYFIEND

## EMERGENCY_SAVE (Экстренный сейв в центре экрана, когда ХП падает ниже порога)
IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
ELSE IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
END IF

## ROTATION_QUEUE (приоритеты конечного автомата сверху вниз; доступные условия: NOT target.has_dots, target.has_dots, READY(X), NOT READY(X), USABLE(X), PROC(X), AND)
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF PROC(VOID_BOLT) AND READY(VOID_BOLT) THEN
    RETURN CAST(VOID_BOLT)
ELSE IF PROC(VOID_BLAST) AND READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF PROC(DEVOURING_PLAGUE) AND USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF PROC(MIND_FLAY_INSANITY) THEN
    RETURN CAST(MIND_FLAY_INSANITY)
ELSE IF PROC(SHADOW_WORD_DEATH) AND READY(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(HALO) THEN
    RETURN CAST(HALO)
ELSE
    RETURN CAST(MIND_FLAY)
END IF]]

---------------------------------------------------------------------------------------
--             SHARED SPELL_BOOK BLOCK FOR PRIEST PRESETS (.MD FORMAT)               --
---------------------------------------------------------------------------------------
local PRIEST_SHADOW_SPELLBOOK_MD = [[
## SPELL_BOOK (Декларация спеллов без хардкода)
SPELL TENTACLE_SLAM = ID:1227280,205385,457042,1234796 | NAME:"Мощный удар щупальцем","Темное сокрушение","Shadow Crash","Tentacle Slam" | MACRO:"M1","M2","sp3" | SLOT:1 | KEY:"M1" | CD:15 | CHARGES:2 | GAIN:15 | DOTS:true | ICON:136201
SPELL VAMPIRIC_TOUCH = ID:34914 | NAME:"Прикосновение вампира","Vampiric Touch" | MACRO:"sp1pvp","sp1" | SLOT:64 | KEY:"SR" | CD:0 | CHARGES:1 | GAIN:6 | DOTS:true | ICON:135978
SPELL VOID_TORRENT = ID:263165 | NAME:"Поток бездны","Поток Бездны","Void Torrent" | MACRO:"SM1","SM2" | SLOT:3 | KEY:"SM1" | CD:45 | CHARGES:1 | GAIN:35 | GRANTS:MIND_FLAY_INSANITY | LOCK_CHANNEL:true | ICON:1386551
SPELL DEVOURING_PLAGUE = ID:335467 | NAME:"Слово Тьмы: Безумие","Всепожирающая чума","Shadow Word: Madness","Devouring Plague" | MACRO:"sp4" | SLOT:63 | KEY:"R" | CD:0 | COST:50 | GRANTS:MIND_FLAY_INSANITY | SPENDER:true | ICON:252997
SPELL MIND_BLAST = ID:450983,8092 | NAME:"Выброс Бездны","Взрыв разума","Void Blast","Mind Blast" | MACRO:"M2","M1","M1_2" | SLOT:2 | KEY:"M2" | CD:7.5 | CHARGES:1 | GAIN:15 | ICON:136224
SPELL VOID_BOLT = ID:1242173,205448 | NAME:"Залп Бездны","Стрела Бездны","Void Volley","Void Bolt" | MACRO:"M2","1_to_2","Dps" | SLOT:2 | KEY:"M2" | CD:6 | GAIN:10 | PROC_ONLY:true | ICON:1386548
SPELL SHADOW_WORD_DEATH = ID:32379 | NAME:"Слово Тьмы: Смерть","Shadow Word: Death" | MACRO:"SM2","SM1" | SLOT:4 | KEY:"SM2" | CD:10 | GAIN:10 | EXECUTE:true | ICON:136149
SPELL MIND_FLAY_INSANITY = ID:391403 | NAME:"Пытка разума: безумие","Mind Flay: Insanity" | MACRO:"sp8" | SLOT:10 | KEY:"SE" | CD:0 | GAIN:16 | PROC_ONLY:true | ICON:136208
SPELL MIND_FLAY = ID:15407,391403 | NAME:"Пытка разума","Mind Flay" | MACRO:"sp8" | SLOT:10 | KEY:"SE" | CD:0 | GAIN:12 | FILLER_INTERRUPTIBLE:true | ICON:136208
SPELL VOID_ERUPTION = ID:228260,391109 | NAME:"Облик Бездны","Извержение Бездны","Темное вознесение","Voidform","Void Eruption","Dark Ascension" | MACRO:"1_to_2" | SLOT:61 | KEY:"B3" | CD:120 | ICON:537079
SPELL POWER_INFUSION = ID:10060 | NAME:"Придание сил","Power Infusion" | MACRO:"1_to_2" | SLOT:11 | KEY:"Q" | CD:120 | ICON:135939
SPELL HALO = ID:120644,122121,120517 | NAME:"Сияние","Божественная звезда","Halo","Divine Star" | MACRO:"S1" | SLOT:53 | KEY:"S1" | CD:60 | GAIN:10 | ICON:632352
SPELL PSYFIEND = ID:34433,211522,375901,451235,200174 | NAME:"Исчадие Тьмы","Ментальный демон","Игры разума","Призрак Бездны","Shadowfiend","Psyfiend" | MACRO:"pvptal" | SLOT:67 | KEY:"T" | CD:60 | ICON:136199
SPELL DISPERSION = ID:47585 | NAME:"Слияние с тьмой","Слияние с Тьмой","Dispersion" | MACRO:"CM2" | SLOT:6 | KEY:"CM2" | CD:90 | ICON:237563
SPELL DESPERATE_PRAYER = ID:19236 | NAME:"Молитва отчаяния","Desperate Prayer" | MACRO:"CM1" | SLOT:5 | KEY:"CM1" | CD:90 | ICON:237550
SPELL VAMPIRIC_EMBRACE = ID:15286 | NAME:"Объятия вампира","Vampiric Embrace" | MACRO:"AM1" | SLOT:7 | KEY:"AM1" | CD:120 | ICON:136230
SPELL FADE = ID:586,8122 | NAME:"Уход в тень","Ментальный крик","Fade","Psychic Scream" | MACRO:"p2","p12","p4" | SLOT:71 | KEY:"Z" | CD:30 | ICON:135994
SPELL POWER_WORD_SHIELD = ID:17 | NAME:"Слово силы: Щит","Power Word: Shield" | MACRO:"H_Shield","p4" | SLOT:62 | KEY:"SB3" | CD:7.5 | ICON:135940
SPELL SILENCE = ID:15487 | NAME:"Безмолвие","Silence" | MACRO:"F" | SLOT:65 | KEY:"F" | CD:45 | ICON:458230
SPELL PSYCHIC_HORROR = ID:64044 | NAME:"Глубинный ужас","Psychic Horror" | MACRO:"p2vp","M3" | SLOT:12 | KEY:"SQ" | CD:45 | ICON:237568
]]

---------------------------------------------------------------------------------------
--             55 BUILT-IN PRESETS (10 FOR PRIEST + 45 ACROSS ALL CLASSES)           --
---------------------------------------------------------------------------------------
SpArc.BuiltInPresetOrder = {}
SpArc.BuiltInPresets = {}

local function RegisterPreset(id, classTag, title, mode, mdBody)
  SpArc.BuiltInPresetOrder[#SpArc.BuiltInPresetOrder + 1] = id
  SpArc.BuiltInPresets[id] = {
    id = id,
    class = classTag,
    title = title,
    mode = mode,
    md = mdBody,
  }
end

-- ====================================================================================
-- 1..10: PRIEST (10 Presets for Anya's Priest!)
-- ====================================================================================

-- #1: PRIEST — Shadow PvE (M+ / AoE / Cleave / Open World)
RegisterPreset("PRIEST_01_SHADOW_PVE", "PRIEST", "1. ШП: PvE / Мифик+ (Icy Veins Cleave)", "PVE", [[
# PROFILE: 1. ШП: PvE / Мифик+ (Icy Veins Cleave)
# CLASS: PRIEST
# SPEC: Shadow
# MODE: PVE
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
## CHANNEL_POLICY (Пытка разума — филлер, прерывается всегда при откате/проке!)
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT

## TRACKERS
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, PSYFIEND

## EMERGENCY_SAVE
IF player.hp_percent <= 20 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
ELSE IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
ELSE IF player.hp_percent <= 25 AND READY(VAMPIRIC_EMBRACE) THEN
    RETURN EMERGENCY(VAMPIRIC_EMBRACE)
END IF

## ROTATION_QUEUE
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF PROC(VOID_BOLT) AND READY(VOID_BOLT) THEN
    RETURN CAST(VOID_BOLT)
ELSE IF PROC(VOID_BLAST) AND READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF PROC(DEVOURING_PLAGUE) AND USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF PROC(MIND_FLAY_INSANITY) THEN
    RETURN CAST(MIND_FLAY_INSANITY)
ELSE IF PROC(SHADOW_WORD_DEATH) AND READY(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF PROC(MIND_BLAST) AND READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(HALO) THEN
    RETURN CAST(HALO)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- #2: PRIEST — Shadow Boss (Single-Target Raid Boss)
RegisterPreset("PRIEST_02_SHADOW_BOSS", "PRIEST", "2. ШП: Босс / Рейд (Icy Veins СТ)", "BOSS", [[
# PROFILE: 2. ШП: Босс / Рейд (Icy Veins СТ)
# CLASS: PRIEST
# SPEC: Shadow
# MODE: BOSS
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
## CHANNEL_POLICY (Пытка разума прерывается мгновенно, Поток бездны защищён)
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT

## TRACKERS
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, PSYFIEND

## EMERGENCY_SAVE
IF player.hp_percent <= 20 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
ELSE IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
END IF

## ROTATION_QUEUE
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF PROC(VOID_BOLT) AND READY(VOID_BOLT) THEN
    RETURN CAST(VOID_BOLT)
ELSE IF PROC(VOID_BLAST) AND READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF PROC(DEVOURING_PLAGUE) AND USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF PROC(MIND_FLAY_INSANITY) THEN
    RETURN CAST(MIND_FLAY_INSANITY)
ELSE IF PROC(SHADOW_WORD_DEATH) AND READY(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(HALO) THEN
    RETURN CAST(HALO)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- #3: PRIEST — Shadow PvP (Arena / BG / World PvP)
RegisterPreset("PRIEST_03_SHADOW_PVP", "PRIEST", "3. ШП: PvP / Арена (Бурст и Экзекут)", "PVP", [[
# PROFILE: 3. ШП: PvP / Арена (Бурст и Экзекут)
# CLASS: PRIEST
# SPEC: Shadow
# MODE: PVP
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
## CHANNEL_POLICY
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT

## TRACKERS
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, PSYFIEND, SILENCE

## EMERGENCY_SAVE
IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
ELSE IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
ELSE IF player.hp_percent <= 25 AND READY(VAMPIRIC_EMBRACE) THEN
    RETURN EMERGENCY(VAMPIRIC_EMBRACE)
END IF

## ROTATION_QUEUE
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF PROC(VOID_BOLT) AND READY(VOID_BOLT) THEN
    RETURN CAST(VOID_BOLT)
ELSE IF PROC(VOID_BLAST) AND READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF PROC(MIND_FLAY_INSANITY) THEN
    RETURN CAST(MIND_FLAY_INSANITY)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- #4: PRIEST — Shadow Archon (Halo / Mind Flay: Insanity Priority)
RegisterPreset("PRIEST_04_SHADOW_ARCHON", "PRIEST", "4. ШП: Архонт (Приоритет Сияния и Безумия)", "PVE", [[
# PROFILE: 4. ШП: Архонт (Приоритет Сияния и Безумия)
# CLASS: PRIEST
# SPEC: Shadow (Archon)
# MODE: PVE
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT, MIND_FLAY_INSANITY
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, HALO, PSYFIEND
IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
END IF
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF READY(HALO) THEN
    RETURN CAST(HALO)
ELSE IF PROC(VOID_BOLT) AND READY(VOID_BOLT) THEN
    RETURN CAST(VOID_BOLT)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF PROC(MIND_FLAY_INSANITY) THEN
    RETURN CAST(MIND_FLAY_INSANITY)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- #5: PRIEST — Shadow Voidweaver (Void Torrent / Entropic Rift Priority)
RegisterPreset("PRIEST_05_SHADOW_VOIDWEAVER", "PRIEST", "5. ШП: Ткач Бездны (Энтропийский разлом)", "PVE", [[
# PROFILE: 5. ШП: Ткач Бездны (Энтропийский разлом)
# CLASS: PRIEST
# SPEC: Shadow (Voidweaver)
# MODE: PVE
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_TORRENT, VOID_ERUPTION, PSYFIEND
IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
END IF
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF PROC(VOID_BLAST) AND READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF PROC(MIND_FLAY_INSANITY) THEN
    RETURN CAST(MIND_FLAY_INSANITY)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- #6: PRIEST — Shadow Delves / Solo Survival
RegisterPreset("PRIEST_06_SHADOW_DELVES", "PRIEST", "6. ШП: Вылазки / Соло (Повышенный сейв)", "PVE", [[
# PROFILE: 6. ШП: Вылазки / Соло (Повышенный сейв)
# CLASS: PRIEST
# SPEC: Shadow
# MODE: PVE
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, POWER_WORD_SHIELD
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, PSYFIEND
IF player.hp_percent <= 35 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
ELSE IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
END IF
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF PROC(MIND_FLAY_INSANITY) THEN
    RETURN CAST(MIND_FLAY_INSANITY)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- #7: PRIEST — Shadow Legacy Raid Speedrun (Ny'alotha / Instant Burst)
RegisterPreset("PRIEST_07_SHADOW_SPEEDRUN", "PRIEST", "7. ШП: Ни'алота / Фарм рейдов (Мгновенный урон)", "PVE", [[
# PROFILE: 7. ШП: Ни'алота / Фарм рейдов (Мгновенный урон)
# CLASS: PRIEST
# SPEC: Shadow
# MODE: PVE
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, HALO
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF READY(HALO) THEN
    RETURN CAST(HALO)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- #8: PRIEST — Discipline PvE Atonement DPS
RegisterPreset("PRIEST_08_DISC_PVE", "PRIEST", "8. ДЦ: PvE Искупление вины (Atonement)", "PVE", [[
# PROFILE: 8. ДЦ: PvE Искупление вины (Atonement)
# CLASS: PRIEST
# SPEC: Discipline
# MODE: PVE
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
TRACK_SAVES: DESPERATE_PRAYER, FADE, POWER_WORD_SHIELD, VAMPIRIC_EMBRACE
TRACK_CDS: POWER_INFUSION, PSYFIEND, HALO, VOID_ERUPTION
IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(HALO) THEN
    RETURN CAST(HALO)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- #9: PRIEST — Discipline PvP Arena
RegisterPreset("PRIEST_09_DISC_PVP", "PRIEST", "9. ДЦ: PvP Арена (Ассист и Экзекут)", "PVP", [[
# PROFILE: 9. ДЦ: PvP Арена (Ассист и Экзекут)
# CLASS: PRIEST
# SPEC: Discipline
# MODE: PVP
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
TRACK_SAVES: DESPERATE_PRAYER, FADE, POWER_WORD_SHIELD, VAMPIRIC_EMBRACE
TRACK_CDS: POWER_INFUSION, PSYFIEND, SILENCE, PSYCHIC_HORROR
IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- #10: PRIEST — Holy PvE DPS/Filler
RegisterPreset("PRIEST_10_HOLY_PVE", "PRIEST", "10. Холи: PvE Урон в окно исцеления", "PVE", [[
# PROFILE: 10. Холи: PvE Урон в окно исцеления
# CLASS: PRIEST
# SPEC: Holy
# MODE: PVE
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
TRACK_SAVES: DESPERATE_PRAYER, FADE, POWER_WORD_SHIELD, VAMPIRIC_EMBRACE
TRACK_CDS: POWER_INFUSION, HALO, PSYFIEND, VOID_ERUPTION
IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(HALO) THEN
    RETURN CAST(HALO)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- ====================================================================================
-- 11..55: CROSS-CLASS PRESET LIBRARY (45 Presets across the other 12 WoW Classes = 55 Total)
-- ====================================================================================
local OTHER_CLASS_PRESETS = {
  { "MAGE_01_ARCANE_PVE", "MAGE", "11. Маг: Тайная магия — PvE (Icy Veins)", "PVE" },
  { "MAGE_02_ARCANE_BOSS", "MAGE", "12. Маг: Тайная магия — Босс СТ", "BOSS" },
  { "MAGE_03_FIRE_PVE", "MAGE", "13. Маг: Огонь — PvE / Мифик+", "PVE" },
  { "MAGE_04_FROST_PVE", "MAGE", "14. Маг: Лёд — PvE Cleave", "PVE" },
  { "MAGE_05_FROST_PVP", "MAGE", "15. Маг: Лёд — PvP Арена", "PVP" },

  { "WARLOCK_01_AFF_PVE", "WARLOCK", "16. Чернокнижник: Колдовство — PvE", "PVE" },
  { "WARLOCK_02_AFF_BOSS", "WARLOCK", "17. Чернокнижник: Колдовство — Босс", "BOSS" },
  { "WARLOCK_03_DEMO_PVE", "WARLOCK", "18. Чернокнижник: Демонология — PvE", "PVE" },
  { "WARLOCK_04_DESTRO_PVE", "WARLOCK", "19. Чернокнижник: Разрушение — PvE", "PVE" },
  { "WARLOCK_05_DESTRO_PVP", "WARLOCK", "20. Чернокнижник: Разрушение — PvP", "PVP" },

  { "PALADIN_01_RET_PVE", "PALADIN", "21. Паладин: Воздаяние — PvE / Мифик+", "PVE" },
  { "PALADIN_02_RET_BOSS", "PALADIN", "22. Паладин: Воздаяние — Босс СТ", "BOSS" },
  { "PALADIN_03_RET_PVP", "PALADIN", "23. Паладин: Воздаяние — PvP Арена", "PVP" },
  { "PALADIN_04_PROT_PVE", "PALADIN", "24. Паладин: Защита — Танк Мифик+", "PVE" },

  { "HUNTER_01_BM_PVE", "HUNTER", "25. Охотник: Повелитель зверей — PvE", "PVE" },
  { "HUNTER_02_BM_BOSS", "HUNTER", "26. Охотник: Повелитель зверей — Босс", "BOSS" },
  { "HUNTER_03_MM_PVE", "HUNTER", "27. Охотник: Стрельба — PvE", "PVE" },
  { "HUNTER_04_SURV_PVP", "HUNTER", "28. Охотник: Выживание — PvP", "PVP" },

  { "ROGUE_01_ASSA_PVE", "ROGUE", "29. Разбойник: Ликвидация — PvE", "PVE" },
  { "ROGUE_02_OUTLAW_PVE", "ROGUE", "30. Разбойник: Головорез — Мифик+", "PVE" },
  { "ROGUE_03_SUB_BOSS", "ROGUE", "31. Разбойник: Скрытность — Босс", "BOSS" },
  { "ROGUE_04_SUB_PVP", "ROGUE", "32. Разбойник: Скрытность — PvP Арена", "PVP" },

  { "WARRIOR_01_FURY_PVE", "WARRIOR", "33. Воин: Неистовство — PvE / Мифик+", "PVE" },
  { "WARRIOR_02_ARGS_BOSS", "WARRIOR", "34. Воин: Оружие — Босс СТ", "BOSS" },
  { "WARRIOR_03_ARMS_PVP", "WARRIOR", "35. Воин: Оружие — PvP Арена", "PVP" },
  { "WARRIOR_04_PROT_PVE", "WARRIOR", "36. Воин: Защита — Танк", "PVE" },

  { "DRUID_01_BAL_PVE", "DRUID", "37. Друид: Баланс — PvE / Мифик+", "PVE" },
  { "DRUID_02_BAL_BOSS", "DRUID", "38. Друид: Баланс — Босс СТ", "BOSS" },
  { "DRUID_03_FERAL_PVE", "DRUID", "39. Друид: Сила зверя — PvE", "PVE" },
  { "DRUID_04_FERAL_PVP", "DRUID", "40. Друид: Сила зверя — PvP", "PVP" },

  { "SHAMAN_01_ELE_PVE", "SHAMAN", "41. Шаман: Стихии — PvE / Мифик+", "PVE" },
  { "SHAMAN_02_ELE_BOSS", "SHAMAN", "42. Шаман: Стихии — Босс СТ", "BOSS" },
  { "SHAMAN_03_ENH_PVE", "SHAMAN", "43. Шаман: Совершенствование — PvE", "PVE" },
  { "SHAMAN_04_ENH_PVP", "SHAMAN", "44. Шаман: Совершенствование — PvP", "PVP" },

  { "DK_01_UNHOLY_PVE", "DEATHKNIGHT", "45. Рыцарь смерти: Нечестивость — PvE", "PVE" },
  { "DK_02_FROST_PVE", "DEATHKNIGHT", "46. Рыцарь смерти: Лёд — Мифик+", "PVE" },
  { "DK_03_BLOOD_PVE", "DEATHKNIGHT", "47. Рыцарь смерти: Кровь — Танк", "PVE" },

  { "MONK_01_WW_PVE", "MONK", "48. Монах: Танцующий с ветром — PvE", "PVE" },
  { "MONK_02_WW_PVP", "MONK", "49. Монах: Танцующий с ветром — PvP", "PVP" },
  { "MONK_03_BM_PVE", "MONK", "50. Монах: Хмелевар — Танк", "PVE" },

  { "DH_01_HAVOC_PVE", "DEMONHUNTER", "51. Охотник на демонов: Истребление — PvE", "PVE" },
  { "DH_02_HAVOC_PVP", "DEMONHUNTER", "52. Охотник на демонов: Истребление — PvP", "PVP" },
  { "DH_03_VENG_PVE", "DEMONHUNTER", "53. Охотник на демонов: Месть — Танк", "PVE" },

  { "EVOKER_01_DEV_PVE", "EVOKER", "54. Пробудитель: Опустошение — PvE", "PVE" },
  { "EVOKER_02_AUG_PVE", "EVOKER", "55. Пробудитель: Насыщатель — Мифик+", "PVE" },
}

local WARRIOR_ARMS_SPELLBOOK_MD = [[
## SPELL_BOOK (Arms Warrior — Slayer / Colossus)
SPELL COLOSSUS_SMASH = ID:167105,262161,436358 | NAME:"Удар колосса","Миротворец","Сокрушение","Colossus Smash","Warbreaker","Demolish" | MACRO:"M1" | SLOT:1 | KEY:"M1" | CD:45 | CHARGES:1 | ICON:132355
SPELL BLADESTORM = ID:227847,389774,228920 | NAME:"Вихрь клинков","Опустошитель","Bladestorm","Ravager" | MACRO:"M2" | SLOT:2 | KEY:"M2" | CD:90 | CHARGES:1 | ICON:236303
SPELL EXECUTE = ID:163201,5308,281000 | NAME:"Казнь","Execute" | MACRO:"SM1" | SLOT:3 | KEY:"SM1" | CD:0 | CHARGES:1 | EXECUTE:true | ICON:135358
SPELL SWEEPING_STRIKES = ID:260708 | NAME:"Размашистые удары","Sweeping Strikes" | MACRO:"SM2","R" | SLOT:4 | KEY:"SM2" | CD:30 | CHARGES:1 | ICON:132366
SPELL AVATAR = ID:107574 | NAME:"Аватара","Avatar" | MACRO:"3","SM2" | SLOT:27 | KEY:"3" | CD:90 | CHARGES:1 | ICON:613534
SPELL MORTAL_STRIKE = ID:12294 | NAME:"Смертельный удар","Mortal Strike" | MACRO:"E" | SLOT:9 | KEY:"E" | CD:6 | CHARGES:1 | ICON:132355
SPELL OVERPOWER = ID:7384 | NAME:"Превосходство","Overpower" | MACRO:"Q" | SLOT:11 | KEY:"Q" | CD:12 | CHARGES:2 | ICON:132223
SPELL CLEAVE = ID:845,1680 | NAME:"Рассекающий удар","Вихрь","Cleave","Whirlwind" | MACRO:"1" | SLOT:25 | KEY:"1" | CD:4.5 | CHARGES:1 | ICON:132338
SPELL SLAM = ID:1464,6343 | NAME:"Мощный удар","Удар грома","Slam","Thunder Clap" | MACRO:"SQ" | SLOT:12 | KEY:"SQ" | CD:0 | CHARGES:1 | FILLER_INTERRUPTIBLE:true | ICON:132340
SPELL DIE_BY_THE_SWORD = ID:118038 | NAME:"Бой насмерть","Die by the Sword" | MACRO:"CM1" | SLOT:5 | KEY:"CM1" | CD:120 | CHARGES:1 | ICON:132336
SPELL RALLYING_CRY = ID:97462,383762 | NAME:"Ободряющий клич","Горестная невосприимчивость","Rallying Cry","Bitter Immunity" | MACRO:"CM2","C" | SLOT:6 | KEY:"CM2" | CD:180 | CHARGES:1 | ICON:132351
SPELL SPELL_REFLECTION = ID:23920 | NAME:"Отражение заклинаний","Spell Reflection" | MACRO:"AM1" | SLOT:7 | KEY:"AM1" | CD:25 | CHARGES:1 | ICON:132361
SPELL IMPENDING_VICTORY = ID:202168 | NAME:"Верная победа","Impending Victory" | MACRO:"SE","2" | SLOT:10 | KEY:"SE" | CD:25 | CHARGES:1 | ICON:589768
]]

local WARRIOR_ARMS_ROTATION_MD = [[
TRACK_SAVES: DIE_BY_THE_SWORD, RALLYING_CRY, SPELL_REFLECTION, IMPENDING_VICTORY
TRACK_CDS: AVATAR, COLOSSUS_SMASH, BLADESTORM, SWEEPING_STRIKES
IF player.hp_percent <= 25 AND READY(DIE_BY_THE_SWORD) THEN
    RETURN EMERGENCY(DIE_BY_THE_SWORD)
ELSE IF player.hp_percent <= 25 AND READY(IMPENDING_VICTORY) THEN
    RETURN EMERGENCY(IMPENDING_VICTORY)
END IF
IF PROC(EXECUTE) AND READY(EXECUTE) THEN
    RETURN CAST(EXECUTE)
ELSE IF USABLE(EXECUTE) AND READY(EXECUTE) THEN
    RETURN CAST(EXECUTE)
ELSE IF READY(SWEEPING_STRIKES) THEN
    RETURN CAST(SWEEPING_STRIKES)
ELSE IF READY(COLOSSUS_SMASH) THEN
    RETURN CAST(COLOSSUS_SMASH)
ELSE IF READY(MORTAL_STRIKE) THEN
    RETURN CAST(MORTAL_STRIKE)
ELSE IF READY(BLADESTORM) THEN
    RETURN CAST(BLADESTORM)
ELSE IF READY(OVERPOWER) THEN
    RETURN CAST(OVERPOWER)
ELSE IF READY(CLEAVE) THEN
    RETURN CAST(CLEAVE)
ELSE
    RETURN CAST(SLAM)
END IF
]]

for _, info in ipairs(OTHER_CLASS_PRESETS) do
  local id, cls, title, mode = info[1], info[2], info[3], info[4]
  local headerMD = string.format(
    "# PROFILE: %s\n# CLASS: %s\n# SPEC: %s\n# MODE: %s\n# Tip / Подсказка: paste an Icy Veins rotation generated via Gemini / ChatGPT in Tab 2!\n",
    title, cls, mode, mode
  )
  local templateMD
  if cls == "WARRIOR" then
    templateMD = headerMD .. WARRIOR_ARMS_SPELLBOOK_MD .. WARRIOR_ARMS_ROTATION_MD
  else
    templateMD = headerMD .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, PSYFIEND
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]]
  end
  RegisterPreset(id, cls, title, mode, templateMD)
end

-- Legacy compatibility map for PVE / BOSS / PVP quick mode keys
SpArc.DefaultMarkdownProfiles = {
  ["PVE"]  = SpArc.BuiltInPresets["PRIEST_01_SHADOW_PVE"].md,
  ["BOSS"] = SpArc.BuiltInPresets["PRIEST_02_SHADOW_BOSS"].md,
  ["PVP"]  = SpArc.BuiltInPresets["PRIEST_03_SHADOW_PVP"].md,
}
