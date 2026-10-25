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

    NAV_1 = "Rotation Presets",
    NAV_2 = ".MD Code & AI",
    NAV_3 = "Rotation Arc",
    NAV_4 = "Saves & CDs Wings",
    NAV_5 = "Dual Castbar",
    NAV_6 = "Combat Camera",
    NAV_7 = "Telemetry & Debug",
    NAV_8 = "Profiles",
    NAV_9 = "Macro Generator",

    MOD_ENABLE = "Enable",
    MOD_ENABLE_SAVES = "Enable Left Saves Wing",
    MOD_ENABLE_CDS = "Enable Right CDs Wing",
    TOP_TEST_HUD = "Test HUD: %s",
    TOP_FIX_CURSOR = "Reset Cursor",

    M3_TITLE = "Rotation Arc (Semicircle Queue)",
    M3_GRP_GEO = "Arc Geometry & Position",
    M3_GRP_ICONS = "Queue Icons & Scaling",
    M3_GRP_FEEDBACK = "Press Animation & Feedback",
    CK_PRESS_FEEDBACK = "Animate icon press feedback (-20% -> +20% bounce) on exact spell cast",

    M4_TITLE = "Defensive Saves & Offensive Cooldowns Wings",
    M4_GRP_POS = "Wings Position & Visibility",
    M4_GRP_EMERG = "Emergency Low-HP Save Alert (Center Screen)",

    M5_TITLE = "Dual-Direction Castbar & Filler Clipping",
    M5_GRP_SIZE = "Castbar Dimensions & Offset",
    M5_GRP_CLIP = "Channeled Filler Clipping Alert",

    M6_TITLE = "Action Combat Camera (Mouselook)",
    M6_GRP_KEYS = "Camera & Interact Keybinds (Auto-clears if bound in WoW / Bartender4)",
    M6_HOLD_LABEL = "Unlock Cursor while held (onHold):",
    M6_TOGGLE_LABEL = "Unlock / Lock Camera permanently (onPress):",
    M6_INTERACT_LABEL = "Interact with Target / NPC (INTERACTTARGET):",
    M6_BIND_WAIT = "Press key... (ESC)",
    M6_RESET_KEY = "Default",
    M6_UNBIND_KEY = "Clear",
    M6_NOT_BOUND = "Not Bound",
    M6_FIX_BTN = "Flush Hardware Cursor (/sparc fixcursor)",
    M6_GRP_CROSS = "Center Reticle / Crosshair (Live Preview while open)",
    SL_CAM_CROSS_Y = "Crosshair Vertical Height Y (px)",
    SL_CAM_CROSS_SCALE = "Crosshair Scale",
    M6_GRP_CLICK = "Mouselook Click-Casting (Bartender4 / ActionBars)",
    CK_CAM_CLICKCAST = "Bind LMB/RMB (+Shift/Ctrl/Alt) to Action Slots 1..8 while camera is locked",

    M7_TITLE = "Live SpellBook & Rotation Telemetry",

    M8_TITLE = "Character Profiles (Per-Character HUD, Camera & Keybinds)",
    M8_GRP_CUR = "Current Character & Active Profile",
    M8_CUR_SUMMARY = "Character: |cffffd100%s|r   •   Active Profile: |cff00ff96%s|r\nProfile Keys:  onHold = |cffffd100[%s]|r   |   onPress = |cffffd100[%s]|r   |   Interact = |cffffd100[%s]|r",
    M8_RESET_BTN = "Reset Current Profile",
    M8_CHAR_PROF_BTN = "Use Character Profile",
    M8_DEF_PROF_BTN = "Use 'Default' Profile",
    M8_GRP_LIST = "All Saved Profiles (Switch, Copy Settings, or Delete)",
    M8_DETAILS_HEADER = "Selected Profile: |cffffd100%s|r\n\n"
      .. "• Hold Cursor (onHold): |cff00ccff%s|r\n"
      .. "• Toggle Camera (onPress): |cff00ccff%s|r\n"
      .. "• Interact Key: |cff00ccff%s|r\n"
      .. "• Crosshair Y / Scale: |cff00ff00%d px / %.2f|r\n"
      .. "• Arc Radius / Spread: |cff00ff00%d px / %d°|r\n\n"
      .. "|cffaaaaaaEach character automatically uses its own profile (like ElvUI & Plater). If you bind any SpArc key in WoW or Bartender4, SpArc automatically drops the conflicting bind.|r",
    M8_ACTIVATE_BTN = "Switch to Selected Profile",
    M8_COPY_BTN = "Copy Selected -> Current Profile",
    M8_DELETE_BTN = "Delete Selected Profile",
    MSG_PROF_SWITCHED = "|cffa335eeSpArc:|r Switched active profile to |cff00ff96%s|r.",
    MSG_PROF_COPIED = "|cffa335eeSpArc:|r Copied settings from |cffffd100%s|r into |cff00ff96%s|r.",
    MSG_PROF_RESET = "|cffa335eeSpArc:|r Profile |cff00ff96%s|r reset to defaults.",
    MSG_PROF_DELETED = "|cffa335eeSpArc:|r Deleted profile |cffff6060%s|r.",
    MSG_BIND_CONFLICT_CLEARED = "|cffa335eeSpArc:|r Key |cffffd100[%s]|r is bound to '|cff00ccff%s|r' in game/addon — SpArc bind automatically cleared.",
    MSG_INTERACT_AUTO_ADAPTED = "|cffa335eeSpArc:|r Key |cffffd100[%s]|r is used by '|cff00ccff%s|r' — Interact key in SpArc automatically set to |cff00ff96[%s]|r.",

    M9_TITLE = "SpellBook Wrapper Macro Generator (Class & Spec)",
    M9_GRP_INFO = "Naming Scheme & Macro Slot Capacity",
    M9_SUMMARY_TEXT = "Class (%s): |cffffd100%s|r   •   Spec (%s): |cff00ff96%s|r\nCharacter Macros: |cff00ff96%d / %d|r   •   General (Account) Macros (Overflow): |cff00ccff%d / %d|r",
    M9_GRP_TPL = "Macro Template (use 'spell' or '%s' for Spell Name) & SpellBook Filters",
    M9_TPL_DEFAULT_BTN = "Default [@target]",
    M9_TPL_MO_BTN = "[@mouseover] + Target",
    CK_M9_SKIP_EXISTING = "Skip spells that already exist in macros",
    CK_M9_INC_CLASS = "Include General Class Spells (w1, p1, r1, d1...)",
    CK_M9_INC_SPEC = "Include Active Spec Spells (sp1, ar1, fd1, aw1...)",
    M9_GRP_PREVIEW = "SpellBook Scan Preview & Generation Log",
    M9_PREVIEW_BTN = "Rescan SpellBook Preview",
    M9_GENERATE_BTN = "Generate Wrapper Macros Now",
    M9_OPEN_MACROS_BTN = "Open /m Window",
    M9_PREVIEW_HEADER = "|cffffd100SpellBook Scan:|r Found |cffffffff%d|r active spells  ->  Will create: |cff00ff96%d Character|r + |cff00ccff%d General|r  |  Skipped: |cffaaaaaa%d|r",
    M9_OVERFLOW_WARN = "Warning: %d spell(s) will not fit (both Character and General macro tabs are full).",
    M9_ALREADY_HAS = "already in",
    M9_SLOTS_FULL = "Character & General macro slots are full!",
    M9_ERR_COMBAT = "Cannot create macros while in combat! Leave combat and try again.",
    MSG_M9_DONE = "|cffa335eeSpArc Macro Generator:|r Created |cff00ff96%d Character|r and |cff00ccff%d General|r macros (Skipped existing: |cffaaaaaa%d|r).",

    P1_SUMMARY = "Total Presets: |cffffd100%d|r  |  Your Class (%s): |cff00ff00%d|r  |  Active: |cffa335ee%s|r (%s)",
    FILTER_CLASS = "Filter: Only %s (%d)",
    FILTER_ALL = "Filter: All Classes (%d)",
    MODE_AUTO = "Mode: AUTO (PvE/Boss/PvP)",
    MODE_MANUAL = "Mode: Manual Preset",
    NEW_PRESET_BTN = "+ New Preset",
    DEL_PRESET_BTN = "Delete Preset",
    NEW_PRESET_TITLE = "%d. Custom %s #%d",
    MSG_PRESET_DELETED = "|cffa335eeSpArc:|r Deleted preset: |cffff6060%s|r",
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
    CK_COMBAT_CAM = "Enable SpArc Combat Camera Module (replaces CombatMode; G = hold cursor, ` = toggle)",
    CK_CAM_CROSSHAIR = "Show Combat Camera Center Crosshair when camera is locked",
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
    MSG_CAM_TOGGLE = "|cffa335eeSpArc:|r Combat Camera Module: %s",
    MSG_CURSOR_FIXED = "|cffa335eeSpArc:|r Hardware cursor & freelook centering CVars flushed.",
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

    NAV_1 = "Пресеты ротаций",
    NAV_2 = "Псевдокод .MD и ИИ",
    NAV_3 = "Дуга ротации",
    NAV_4 = "Крылья Сейвов и КД",
    NAV_5 = "Двойной Кастбар",
    NAV_6 = "Боевая Камера",
    NAV_7 = "Телеметрия и Дебаг",
    NAV_8 = "Профили",
    NAV_9 = "Макросогенератор",

    MOD_ENABLE = "Включить",
    MOD_ENABLE_SAVES = "Включить левое крыло сейвов",
    MOD_ENABLE_CDS = "Включить правое крыло бурстов/КД",
    TOP_TEST_HUD = "Тест HUD: %s",
    TOP_FIX_CURSOR = "Сброс курсора",

    M3_TITLE = "Дуга ротации (Полукруг очереди заклинаний)",
    M3_GRP_GEO = "Геометрия и положение дуги",
    M3_GRP_ICONS = "Масштаб и количество иконок",
    M3_GRP_FEEDBACK = "Отклик нажатия кнопок",
    CK_PRESS_FEEDBACK = "Имитировать нажатие иконки (-20% -> +20% размера) при прожиме спелла",

    M4_TITLE = "Боковые крылья Сейвов и Бурстов (КД)",
    M4_GRP_POS = "Положение и видимость крыльев",
    M4_GRP_EMERG = "Экстренный сейв в центре экрана (при низком ХП)",

    M5_TITLE = "Двунаправленный Кастбар и Контроль Филлера",
    M5_GRP_SIZE = "Размеры и отступы кастбара",
    M5_GRP_CLIP = "Индикация прерывания потокового филлера",

    M6_TITLE = "Боевая Камера (Удержание камеры / Mouselook)",
    M6_GRP_KEYS = "Клавиши камеры и взаимодействия (авто-сброс при конфликте с игрой/аддонами)",
    M6_HOLD_LABEL = "Отвязать курсор при удержании (onHold):",
    M6_TOGGLE_LABEL = "Отвязать / привязать камеру насовсем (onPress):",
    M6_INTERACT_LABEL = "Взаимодействие с целью / НПЦ (Interact):",
    M6_BIND_WAIT = "Нажми клавишу... (ESC)",
    M6_RESET_KEY = "По умолч.",
    M6_UNBIND_KEY = "Снять",
    M6_NOT_BOUND = "Не назначено",
    M6_FIX_BTN = "Сбросить аппаратный курсор (/sparc fixcursor)",
    M6_GRP_CROSS = "Прицел камеры в центре экрана (показывается вживую при настройке)",
    SL_CAM_CROSS_Y = "Высота прицела по Y (px)",
    SL_CAM_CROSS_SCALE = "Масштаб прицела",
    M6_GRP_CLICK = "Боевой клик-каст мыши (Mouselook Click-Casting)",
    CK_CAM_CLICKCAST = "Перехватывать ЛКМ/ПКМ (+Shift/Ctrl/Alt) под способности 1..8 при зажатой камере",

    M7_TITLE = "Телеметрия книги заклинаний и отладка ротации",

    M8_TITLE = "Профили персонажей (Индивидуальные бинды, Боевая Камера и HUD)",
    M8_GRP_CUR = "Текущий персонаж и активный профиль",
    M8_CUR_SUMMARY = "Персонаж: |cffffd100%s|r   •   Активный профиль: |cff00ff96%s|r\nБинды профиля:  onHold = |cffffd100[%s]|r   |   onPress = |cffffd100[%s]|r   |   Interact = |cffffd100[%s]|r",
    M8_RESET_BTN = "Сбросить текущий профиль",
    M8_CHAR_PROF_BTN = "Профиль этого персонажа",
    M8_DEF_PROF_BTN = "Общий профиль (Default)",
    M8_GRP_LIST = "Список всех профилей (Переключение, Копирование как в ElvUI/Plater, Удаление)",
    M8_DETAILS_HEADER = "Выбранный профиль: |cffffd100%s|r\n\n"
      .. "• Отвязать курсор (onHold): |cff00ccff%s|r\n"
      .. "• Камера вкл/выкл (onPress): |cff00ccff%s|r\n"
      .. "• Клавиша взаимодействия (Interact): |cff00ccff%s|r\n"
      .. "• Прицел (Высота Y / Масштаб): |cff00ff00%d px / %.2f|r\n"
      .. "• Дуга ротации (Радиус / Угол): |cff00ff00%d px / %d°|r\n\n"
      .. "|cffaaaaaaУ каждого персонажа автоматически свой профиль (например, E на присте и C на варе). Если ты забиндишь кнопку SpArc в настройках игры или Bartender4 — бинд в SpArc автоматически снимется без конфликта.|r",
    M8_ACTIVATE_BTN = "Переключиться на выбранный профиль",
    M8_COPY_BTN = "Скопировать из выбранного в текущий",
    M8_DELETE_BTN = "Удалить выбранный профиль",
    MSG_PROF_SWITCHED = "|cffa335eeSpArc:|r Активный профиль переключён на |cff00ff96%s|r.",
    MSG_PROF_COPIED = "|cffa335eeSpArc:|r Настройки скопированы из профиля |cffffd100%s|r в |cff00ff96%s|r.",
    MSG_PROF_RESET = "|cffa335eeSpArc:|r Профиль |cff00ff96%s|r сброшен к значениям по умолчанию.",
    MSG_PROF_DELETED = "|cffa335eeSpArc:|r Профиль |cffff6060%s|r удалён.",
    MSG_BIND_CONFLICT_CLEARED = "|cffa335eeSpArc:|r Клавиша |cffffd100[%s]|r занята действием «|cff00ccff%s|r» в игре/аддоне — бинд в SpArc автоматически снят.",
    MSG_INTERACT_AUTO_ADAPTED = "|cffa335eeSpArc:|r Клавиша |cffffd100[%s]|r занята («|cff00ccff%s|r») — клавиша Interact в SpArc автоматически переключена на |cff00ff96[%s]|r.",

    M9_TITLE = "Макросогенератор (Авто-генерация обвязок по всей книге заклинаний)",
    M9_GRP_INFO = "Схема именования и свободные слоты макросов",
    M9_SUMMARY_TEXT = "Класс (%s): |cffffd100%s|r   •   Спек (%s): |cff00ff96%s|r\nМакросы персонажа: |cff00ff96%d / %d|r   •   Общие макросы (при нехватке места): |cff00ccff%d / %d|r",
    M9_GRP_TPL = "Шаблон макроса ('spell' или '%s' = имя спелла) и фильтры спеллбука",
    M9_TPL_DEFAULT_BTN = "Шаблон [@target]",
    M9_TPL_MO_BTN = "[@mouseover] + Цель",
    CK_M9_SKIP_EXISTING = "Пропускать спеллы, для которых уже есть макрос",
    CK_M9_INC_CLASS = "Общие классовые спеллы (w1, p5, r1, d1...)",
    CK_M9_INC_SPEC = "Спеллы специализации (sp1, ar1, fd1, aw1...)",
    M9_GRP_PREVIEW = "Предпросмотр спеллбука и лог генерации макросов",
    M9_PREVIEW_BTN = "Обновить список спеллов",
    M9_GENERATE_BTN = "Сгенерировать макросы сейчас",
    M9_OPEN_MACROS_BTN = "Открыть окно /m",
    M9_PREVIEW_HEADER = "|cffffd100Сканирование спеллбука:|r Найдено |cffffffff%d|r активных спеллов  ->  Будет создано: |cff00ff96%d Персонажа|r + |cff00ccff%d Общих|r  |  Пропущено: |cffaaaaaa%d|r",
    M9_OVERFLOW_WARN = "Внимание: %d спелл(ов) не поместятся (заполнены и личные, и общие макросы).",
    M9_ALREADY_HAS = "уже есть в",
    M9_SLOTS_FULL = "Слоты макросов персонажа и общих макросов полностью заняты!",
    M9_ERR_COMBAT = "Нельзя создавать макросы в бою! Выйдите из боя и нажмите снова.",
    MSG_M9_DONE = "|cffa335eeSpArc Макросогенератор:|r Создано макросов персонажа: |cff00ff96%d|r, общих макросов: |cff00ccff%d|r (Пропущено существующих: |cffaaaaaa%d|r).",

    P1_SUMMARY = "Всего пресетов: |cffffd100%d|r  |  Для вашего класса (%s): |cff00ff00%d|r  |  Активный: |cffa335ee%s|r (%s)",
    FILTER_CLASS = "Фильтр: Только %s (%d)",
    FILTER_ALL = "Фильтр: Все классы (%d)",
    MODE_AUTO = "Режим: AUTO (ПвЕ/Босс/ПвП)",
    MODE_MANUAL = "Режим: Ручной пресет",
    NEW_PRESET_BTN = "+ Новый пресет",
    DEL_PRESET_BTN = "Удалить пресет",
    NEW_PRESET_TITLE = "%d. Кастомный %s #%d",
    MSG_PRESET_DELETED = "|cffa335eeSpArc:|r Пресет удалён: |cffff6060%s|r",
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
    CK_COMBAT_CAM = "Включить модуль Combat Camera в SpArc (замена CombatMode; G = курсор при зажатии, ` = вкл/выкл)",
    CK_CAM_CROSSHAIR = "Показывать прицел Combat Camera в центре экрана при зажатой камере",
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
    MSG_CAM_TOGGLE = "|cffa335eeSpArc:|r Модуль Combat Camera: %s",
    MSG_CURSOR_FIXED = "|cffa335eeSpArc:|r Аппаратный курсор и CVar центрирования камеры сброшены.",
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

SpArc.AIPromptTemplate_EN = [[Hello Gemini / ChatGPT / Claude!
Please look up the latest rotation guide on Icy Veins or Wowhead for World of Warcraft: Midnight (12.x) and compile a ready-to-import rotation profile for the SpArc addon strictly in the SpArc .MD pseudocode format described below.

====================================================================
1. TARGET CHARACTER & CONTENT
====================================================================
• Class & Spec: [INSERT CLASS & SPEC, e.g., Frost Mage / Spellslinger]
• Hero Talents / Build: [OPTIONAL, e.g., Spellslinger / Frostfire / Default Icy Veins]
• Content Mode: [PvE Mythic+ Cleave / Raid Boss Single Target / PvP Arena]

====================================================================
2. HOW THE SPARC .MD COMPILER WORKS (STRICT SYNTAX RULES)
====================================================================
SpArc compiles a Markdown (.MD) document into a 5-step lookahead Finite State Machine (FSM).
Output ONLY a single raw code block following these exact 6 sections:

SECTION A — HEADER METADATA:
# PROFILE: <Preset Title>
# CLASS: <WARRIOR | PALADIN | HUNTER | ROGUE | PRIEST | DEATHKNIGHT | SHAMAN | MAGE | WARLOCK | MONK | DRUID | DEMONHUNTER | EVOKER>
# SPEC: <Spec Name>
# MODE: <PVE | BOSS | PVP>
# TARGET_DEBUFF: ID:<id1,id2> | NAME:"Russian Name","English Name"
  (Optional: include # TARGET_DEBUFF only if the rotation tracks a stacking debuff on the target, such as Frost Mage's Freezing / Обледенение).

SECTION B — ## SPELL_BOOK:
Every spell used anywhere in the profile (rotation, saves, cooldowns, emergency) MUST be declared here, one per line:
SPELL <KEY> = ID:<id1,id2> | NAME:"Russian Name","English Name" | CD:<sec> | ICON:<FileDataID> [| optional flags]
• Always provide BOTH official Russian and English spell names in NAME:"...","..." and all relevant SpellIDs (including talent/hero-talent overrides) in ID:... so SpArc resolves the spell on any WoW client locale and Bartender4/ElvUI action bar.
• Supported optional flags (separated by ` | `):
  - `CD:<seconds>` : Base cooldown in seconds (`0` if none).
  - `CHARGES:<N>` : Max charges for multi-charge abilities (e.g., `CHARGES:2`).
  - `GAIN:<N>` : Primary resource generated on cast (0..100 scale).
  - `COST:<N> | SPENDER:true` : Primary resource cost; marks ability as a resource spender.
  - `DOTS:true` : Applies or refreshes main target DoTs (satisfies `target.has_dots`).
  - `STACKS:+N` : Generates +N stacks of `TARGET_DEBUFF` on the target (e.g., `STACKS:+2`).
  - `STACKS:-N | CONSUMES_STACKS:true` : Consumes N stacks of `TARGET_DEBUFF` when cast without a proc (e.g., `STACKS:-4 | CONSUMES_STACKS:true`).
  - `PROC_ONLY:true` : Only castable when glowing (`IsSpellOverlayed`) or active as a temporary spell override.
  - `OVERRIDE_OF:<BASE_KEY>` : For Midnight 12.x combo/transformation spells that temporarily replace another spell on the same button (e.g., `COMET_STORM` has `OVERRIDE_OF:RAY_OF_FROST`, `GLACIAL_SPIKE` has `OVERRIDE_OF:FROSTBOLT`).
  - `GRANTS:<PROC_KEY>` : Casting this spell guarantees a proc of `<PROC_KEY>`.
  - `EXECUTE:true` : Execute ability (usable below 20% target HP or on proc).
  - `LOCK_CHANNEL:true` : High-priority channeled spell that must NEVER be clipped early.
  - `FILLER_INTERRUPTIBLE:true` : Channeled filler spell that SHOULD be interrupted when a higher-priority spell becomes ready.
  - `ICON:<FileDataID>` : Numeric WoW icon texture ID (use `134400` if unknown).

SECTION C — ## CHANNEL_POLICY:
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: <KEY1, KEY2 or NONE>
PROTECT_CHANNEL: <KEY1, KEY2 or NONE>

SECTION D — ## TRACKERS (Side HUD Wings — up to 4 keys each, all declared in SPELL_BOOK):
TRACK_SAVES: <DEFENSIVE_1>, <DEFENSIVE_2>, <DEFENSIVE_3>, <DEFENSIVE_4>
TRACK_CDS: <OFFENSIVE_CD_1>, <OFFENSIVE_CD_2>, <OFFENSIVE_CD_3>, <OFFENSIVE_CD_4>

SECTION E — ## EMERGENCY_SAVE (Center low-HP alert):
IF player.hp_percent <= 25 AND READY(<DEFENSIVE_KEY>) THEN
    RETURN EMERGENCY(<DEFENSIVE_KEY>)
END IF

SECTION F — ## ROTATION_QUEUE (Top-to-Bottom Priority FSM):
Use `IF <condition> THEN` / `ELSE IF <condition> THEN` / `ELSE` / `END IF` with `RETURN CAST(<KEY>)` on the line inside each branch.
• Allowed condition primitives ONLY (combinable with `AND` / `OR`):
  - `READY(KEY)` / `NOT READY(KEY)` — spell is off cooldown (or has >= 1 charge).
  - `USABLE(KEY)` — spell is off cooldown AND player has enough resource/mana/target state to cast it.
  - `PROC(KEY)` / `NOT PROC(KEY)` — spell has an active proc overlay or active `OVERRIDE_OF` button transformation.
  - `CHARGES(KEY) >= N` (supports `>=`, `<=`, `==`, `>`, `<`) — current charge count.
  - `target.has_dots` / `NOT target.has_dots` — target has active DoTs from a `DOTS:true` spell.
  - `target.debuff_stacks >= N` (or `target.freezing_stacks >= N`) — current stacks of `TARGET_DEBUFF`.
• Always end with an unconditional `ELSE` -> `RETURN CAST(<FILLER_KEY>)` and `END IF`.

====================================================================
3. REFERENCE EXAMPLE (FROST MAGE — MIDNIGHT 12.x)
====================================================================
# PROFILE: Mage: Frost — Raid Boss / ST (Icy Veins Midnight)
# CLASS: MAGE
# SPEC: Frost
# MODE: BOSS
# TARGET_DEBUFF: ID:1221389,1246769,228358 | NAME:"Обледенение","Freezing","Зимняя стужа"

## SPELL_BOOK
SPELL RAY_OF_FROST = ID:205021 | NAME:"Морозный луч","Ray of Frost" | CD:30 | STACKS:+4 | LOCK_CHANNEL:true | ICON:135845
SPELL COMET_STORM = ID:153595,448601 | NAME:"Кометная буря","Comet Storm" | CD:30 | STACKS:+2 | PROC_ONLY:true | OVERRIDE_OF:RAY_OF_FROST | ICON:1035046
SPELL GLACIAL_SPIKE = ID:199786,448604 | NAME:"Ледовый шип","Glacial Spike" | CD:0 | STACKS:-4 | CONSUMES_STACKS:true | PROC_ONLY:true | OVERRIDE_OF:FROSTBOLT | ICON:1392548
SPELL FLURRY = ID:44614,228354 | NAME:"Шквал","Flurry" | CD:30 | CHARGES:2 | STACKS:+3 | ICON:135847
SPELL FROZEN_ORB = ID:84714,198149 | NAME:"Мерзлая сфера","Ледяной шар","Frozen Orb" | CD:45 | STACKS:+3 | ICON:629077
SPELL ICE_LANCE = ID:30455 | NAME:"Ледяное копье","Ice Lance" | CD:0 | STACKS:-4 | CONSUMES_STACKS:true | ICON:135844
SPELL FROSTBOLT = ID:116 | NAME:"Ледяная стрела","Frostbolt" | CD:0 | STACKS:+1 | ICON:135846
SPELL ICE_BLOCK = ID:45438,414658 | NAME:"Ледяная глыба","Ice Block" | CD:240 | ICON:135841
SPELL ICE_BARRIER = ID:11426 | NAME:"Ледяная преграда","Ice Barrier" | CD:25 | ICON:135843
SPELL MIRROR_IMAGE = ID:55342 | NAME:"Зеркальное изображение","Mirror Image" | CD:120 | ICON:135994
SPELL GREATER_INVIS = ID:110959,66 | NAME:"Великая невидимость","Greater Invisibility","Невидимость" | CD:120 | ICON:132220
SPELL COUNTERSPELL = ID:2139 | NAME:"Антимагия","Counterspell" | CD:24 | ICON:135856

## CHANNEL_POLICY
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: NONE
PROTECT_CHANNEL: RAY_OF_FROST

## TRACKERS
TRACK_SAVES: ICE_BLOCK, ICE_BARRIER, MIRROR_IMAGE, GREATER_INVIS
TRACK_CDS: RAY_OF_FROST, FROZEN_ORB, FLURRY, COUNTERSPELL

## EMERGENCY_SAVE
IF player.hp_percent <= 20 AND READY(ICE_BLOCK) THEN
    RETURN EMERGENCY(ICE_BLOCK)
ELSE IF player.hp_percent <= 35 AND READY(ICE_BARRIER) THEN
    RETURN EMERGENCY(ICE_BARRIER)
END IF

## ROTATION_QUEUE
IF PROC(COMET_STORM) THEN
    RETURN CAST(COMET_STORM)
ELSE IF READY(RAY_OF_FROST) AND NOT READY(FLURRY) THEN
    RETURN CAST(RAY_OF_FROST)
ELSE IF READY(FLURRY) THEN
    RETURN CAST(FLURRY)
ELSE IF READY(RAY_OF_FROST) THEN
    RETURN CAST(RAY_OF_FROST)
ELSE IF READY(FROZEN_ORB) THEN
    RETURN CAST(FROZEN_ORB)
ELSE IF PROC(GLACIAL_SPIKE) THEN
    RETURN CAST(GLACIAL_SPIKE)
ELSE IF PROC(ICE_LANCE) OR target.freezing_stacks >= 4 THEN
    RETURN CAST(ICE_LANCE)
ELSE
    RETURN CAST(FROSTBOLT)
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
  MAGE_04_FROST_PVE = "14. Mage: Frost — PvE Cleave (Midnight)",
  MAGE_05_FROST_PVP = "15. Mage: Frost — ST / Boss / PvP (Midnight)",

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

SpArc.PROFILE_SCHEMA_VERSION = 12

---------------------------------------------------------------------------------------
--                  AI PROMPT TEMPLATE (FOR GEMINI / CHATGPT)                        --
---------------------------------------------------------------------------------------
SpArc.AIPromptTemplate = [[Привет, Gemini / ChatGPT / Claude!
Сходи, пожалуйста, на Icy Veins или Wowhead, изучи актуальный гайд по ротации для World of Warcraft: Midnight (12.x) и напиши мне готовый профиль ротации для аддона SpArc строго на языке псевдокода SpArc .MD по правилам ниже.

====================================================================
1. ПАРАМЕТРЫ ПЕРСОНАЖА И КОНТЕНТА
====================================================================
• Класс и спек: [УКАЖИ КЛАСС И СПЕК, например: Маг Льда / Frost Mage]
• Героические таланты / билд: [ПО ЖЕЛАНИЮ, например: Заклинатель (Spellslinger) / Стандарт с Icy Veins]
• Тип контента: [PvE Мифик+ (Клив/АоЕ) / Босс (Соло-таргет) / PvP Арена]

====================================================================
2. ПРАВИЛА КОМПИЛЯТОРА SPARC .MD (СТРОГАЯ СПЕЦИФИКАЦИЯ)
====================================================================
Аддон SpArc напрямую компилирует текстовый .MD-профиль в конечный автомат (FSM) и просчитывает очередь ротации на 5 шагов вперёд (с симуляцией КД, зарядов, ресурса, дот и стаков дебаффа).
Выведи В ОТВЕТЕ ТОЛЬКО ОДИН кодовый блок без лишнего текста, строго соблюдая структуру из 6 секций:

СЕКЦИЯ А — МЕТАДАННЫЕ ПРОФИЛЯ (ШАПКА):
# PROFILE: <Название пресета>
# CLASS: <WARRIOR | PALADIN | HUNTER | ROGUE | PRIEST | DEATHKNIGHT | SHAMAN | MAGE | WARLOCK | MONK | DRUID | DEMONHUNTER | EVOKER>
# SPEC: <Английское название спека, например: Frost, Shadow, Retribution>
# MODE: <PVE | BOSS | PVP>
# TARGET_DEBUFF: ID:<id1,id2> | NAME:"Русское название","English Name"
  (Опционально: добавляй строку # TARGET_DEBUFF только если ротация строит и тратит стакающийся дебафф на цели — например, «Обледенение» / «Freezing» у Фрост Мага).

СЕКЦИЯ Б — ## SPELL_BOOK (КНИГА ЗАКЛИНАНИЙ):
Каждое заклинание, которое используется в очереди ротации, крыльях КД или экстренных сейвах, ОБЯЗАТЕЛЬНО объявляется отдельной строкой:
SPELL <КЛЮЧ_КАПСОМ> = ID:<id1,id2> | NAME:"Русское имя","English Name" | CD:<сек> | ICON:<FileDataID> [| доп. флаги]
• В поле NAME всегда пиши И русское, И английское официальное название спелла через запятую в кавычках, а в ID перечисляй все актуальные SpellID (включая ID талантов-замен), чтобы SpArc автоматически нашёл кнопку на панелях Bartender4 / ElvUI на любом клиенте.
• Доступные флаги поведения (разделяются через ` | `):
  - `CD:<секунды>` — базовое время восстановления (`0`, если без КД).
  - `CHARGES:<N>` — максимум зарядов, если у спелла 2+ заряда (например, `CHARGES:2`).
  - `GAIN:<N>` — сколько основного ресурса генерирует каст (по шкале 0..100).
  - `COST:<N> | SPENDER:true` — сколько ресурса тратит спелл (помечает способность как спендер).
  - `DOTS:true` — спелл вешает или обновляет основные доты на цели (делает `target.has_dots = true`).
  - `STACKS:+N` — каст добавляет `+N` стаков `TARGET_DEBUFF` на цель (например, `STACKS:+2`).
  - `STACKS:-N | CONSUMES_STACKS:true` — каст поглощает `N` стаков `TARGET_DEBUFF`, если нажат без прока (например, `STACKS:-4 | CONSUMES_STACKS:true` у Ледяного копья).
  - `PROC_ONLY:true` — спелл доступен ТОЛЬКО при свечении прока (`IsSpellOverlayed`) или временной подмене кнопки.
  - `OVERRIDE_OF:<БАЗОВЫЙ_КЛЮЧ>` — для комбо-заклинаний Midnight 12.x, в которые временно превращается базовая кнопка (например, `COMET_STORM` имеет `OVERRIDE_OF:RAY_OF_FROST`, а `GLACIAL_SPIKE` имеет `OVERRIDE_OF:FROSTBOLT`).
  - `GRANTS:<КЛЮЧ_ПРОКА>` — каст этого спелла гарантированно даёт прок `<КЛЮЧ_ПРОКА>`.
  - `EXECUTE:true` — экзекут-способность (активна при ХП цели < 20% или по проку).
  - `LOCK_CHANNEL:true` — приоритетный потоковый каст (канал), который НЕЛЬЗЯ прерывать раньше времени.
  - `FILLER_INTERRUPTIBLE:true` — потоковый филлер (например, Пытка разума), который НУЖНО обрывать при откате любого приоритетного КД/прока.
  - `ICON:<FileDataID>` — числовой ID текстуры иконки WoW (если не уверен, ставь `134400`).

СЕКЦИЯ В — ## CHANNEL_POLICY (ПОЛИТИКА ПОТОКОВЫХ КАСТОВ):
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: <КЛЮЧ1, КЛЮЧ2 или NONE>
PROTECT_CHANNEL: <КЛЮЧ1, КЛЮЧ2 или NONE>

СЕКЦИЯ Г — ## TRACKERS (БОКОВЫЕ КРЫЛЬЯ ХУДА — по 4 спелла из SPELL_BOOK):
TRACK_SAVES: <СЕЙВ_1>, <СЕЙВ_2>, <СЕЙВ_3>, <СЕЙВ_4>
TRACK_CDS: <БУРСТ_1>, <БУРСТ_2>, <БУРСТ_3>, <БУРСТ_4>

СЕКЦИЯ Д — ## EMERGENCY_SAVE (ЭКСТРЕННЫЙ СЕЙВ В ЦЕНТРЕ ЭКРАНА ПРИ НИЗКОМ ХП):
IF player.hp_percent <= 25 AND READY(<КЛЮЧ_СЕЙВА>) THEN
    RETURN EMERGENCY(<КЛЮЧ_СЕЙВА>)
END IF

СЕКЦИЯ Е — ## ROTATION_QUEUE (ПРИОРИТЕТЫ РОТАЦИИ СВЕРХУ ВНИЗ):
Строится строго конструкцией `IF <условие> THEN` / `ELSE IF <условие> THEN` / `ELSE` / `END IF`, внутри каждой ветки на следующей строке пишется `RETURN CAST(<КЛЮЧ>)`.
• Разрешённые условия (можно комбинировать через `AND` и `OR`):
  - `READY(KEY)` / `NOT READY(KEY)` — спелл откатился (или имеет >= 1 заряда).
  - `USABLE(KEY)` — спелл откатился И хватает ресурса/маны/условий для каста.
  - `PROC(KEY)` / `NOT PROC(KEY)` — активен прок (свечение кнопки) или активна подмена `OVERRIDE_OF`.
  - `CHARGES(KEY) >= N` (поддерживаются `>=`, `<=`, `==`, `>`, `<`) — проверка числа зарядов.
  - `target.has_dots` / `NOT target.has_dots` — висят ли на цели доты от спелла с флагом `DOTS:true`.
  - `target.debuff_stacks >= N` (или `target.freezing_stacks >= N`) — текущее число стаков `TARGET_DEBUFF` на цели.
• В самом конце ОБЯЗАТЕЛЬНО должна быть ветка `ELSE` -> `RETURN CAST(<КЛЮЧ_ФИЛЛЕРА>)` и закрывающий `END IF`.

====================================================================
3. ЭТАЛОННЫЙ ПРИМЕР (МАГ ЛЬДА — MIDNIGHT 12.x)
====================================================================
# PROFILE: Маг: Лед — Босс / СТ (Icy Veins Midnight)
# CLASS: MAGE
# SPEC: Frost
# MODE: BOSS
# TARGET_DEBUFF: ID:1221389,1246769,228358 | NAME:"Обледенение","Freezing","Зимняя стужа"

## SPELL_BOOK
SPELL RAY_OF_FROST = ID:205021 | NAME:"Морозный луч","Ray of Frost" | CD:30 | STACKS:+4 | LOCK_CHANNEL:true | ICON:135845
SPELL COMET_STORM = ID:153595,448601 | NAME:"Кометная буря","Comet Storm" | CD:30 | STACKS:+2 | PROC_ONLY:true | OVERRIDE_OF:RAY_OF_FROST | ICON:1035046
SPELL GLACIAL_SPIKE = ID:199786,448604 | NAME:"Ледовый шип","Glacial Spike" | CD:0 | STACKS:-4 | CONSUMES_STACKS:true | PROC_ONLY:true | OVERRIDE_OF:FROSTBOLT | ICON:1392548
SPELL FLURRY = ID:44614,228354 | NAME:"Шквал","Flurry" | CD:30 | CHARGES:2 | STACKS:+3 | ICON:135847
SPELL FROZEN_ORB = ID:84714,198149 | NAME:"Мерзлая сфера","Ледяной шар","Frozen Orb" | CD:45 | STACKS:+3 | ICON:629077
SPELL ICE_LANCE = ID:30455 | NAME:"Ледяное копье","Ice Lance" | CD:0 | STACKS:-4 | CONSUMES_STACKS:true | ICON:135844
SPELL FROSTBOLT = ID:116 | NAME:"Ледяная стрела","Frostbolt" | CD:0 | STACKS:+1 | ICON:135846
SPELL ICE_BLOCK = ID:45438,414658 | NAME:"Ледяная глыба","Ice Block" | CD:240 | ICON:135841
SPELL ICE_BARRIER = ID:11426 | NAME:"Ледяная преграда","Ice Barrier" | CD:25 | ICON:135843
SPELL MIRROR_IMAGE = ID:55342 | NAME:"Зеркальное изображение","Mirror Image" | CD:120 | ICON:135994
SPELL GREATER_INVIS = ID:110959,66 | NAME:"Великая невидимость","Greater Invisibility","Невидимость" | CD:120 | ICON:132220
SPELL COUNTERSPELL = ID:2139 | NAME:"Антимагия","Counterspell" | CD:24 | ICON:135856

## CHANNEL_POLICY
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: NONE
PROTECT_CHANNEL: RAY_OF_FROST

## TRACKERS
TRACK_SAVES: ICE_BLOCK, ICE_BARRIER, MIRROR_IMAGE, GREATER_INVIS
TRACK_CDS: RAY_OF_FROST, FROZEN_ORB, FLURRY, COUNTERSPELL

## EMERGENCY_SAVE
IF player.hp_percent <= 20 AND READY(ICE_BLOCK) THEN
    RETURN EMERGENCY(ICE_BLOCK)
ELSE IF player.hp_percent <= 35 AND READY(ICE_BARRIER) THEN
    RETURN EMERGENCY(ICE_BARRIER)
END IF

## ROTATION_QUEUE
IF PROC(COMET_STORM) THEN
    RETURN CAST(COMET_STORM)
ELSE IF READY(RAY_OF_FROST) AND NOT READY(FLURRY) THEN
    RETURN CAST(RAY_OF_FROST)
ELSE IF READY(FLURRY) THEN
    RETURN CAST(FLURRY)
ELSE IF READY(RAY_OF_FROST) THEN
    RETURN CAST(RAY_OF_FROST)
ELSE IF READY(FROZEN_ORB) THEN
    RETURN CAST(FROZEN_ORB)
ELSE IF PROC(GLACIAL_SPIKE) THEN
    RETURN CAST(GLACIAL_SPIKE)
ELSE IF PROC(ICE_LANCE) OR target.freezing_stacks >= 4 THEN
    RETURN CAST(ICE_LANCE)
ELSE
    RETURN CAST(FROSTBOLT)
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
SPELL VOID_ERUPTION = ID:228260,391109,194249 | NAME:"Вхождение в Бездну","Облик Бездны","Извержение Бездны","Темное вознесение","Voidform","Void Eruption","Dark Ascension" | MACRO:"Dps","1_to_2" | SLOT:49 | KEY:"1" | CD:120 | ICON:537079
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
local PRIEST_DISC_SPELLBOOK_MD = [[
## SPELL_BOOK (Discipline Priest)
SPELL PENANCE = ID:47540,47758 | NAME:"Исповедь","Penance" | CD:9 | CHARGES:2 | ICON:135937
SPELL MIND_BLAST = ID:8092,450983 | NAME:"Взрыв разума","Выброс Бездны","Mind Blast","Void Blast" | CD:15 | CHARGES:1 | ICON:136224
SPELL SHADOW_WORD_PAIN = ID:589,204197 | NAME:"Слово Тьмы: Боль","Очищение зла","Shadow Word: Pain","Purge the Wicked" | CD:0 | DOTS:true | ICON:136207
SPELL SHADOW_WORD_DEATH = ID:32379 | NAME:"Слово Тьмы: Смерть","Shadow Word: Death" | CD:10 | EXECUTE:true | ICON:136149
SPELL HALO = ID:120517,120644,122121 | NAME:"Сияние","Божественная звезда","Halo","Divine Star" | CD:40 | ICON:632352
SPELL PSYFIEND = ID:34433,123040,451235 | NAME:"Исчадие Тьмы","Подчиняющий разум","Призрак Бездны","Shadowfiend","Mindbender","Voidwraith" | CD:60 | ICON:136199
SPELL SMITE = ID:585 | NAME:"Кара","Smite" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:135924
SPELL POWER_INFUSION = ID:10060 | NAME:"Придание сил","Power Infusion" | CD:120 | ICON:135939
SPELL RAPTURE = ID:47536,472433 | NAME:"Вознесение","Проповедь","Rapture","Evangelism" | CD:90 | ICON:135940
SPELL PAIN_SUPPRESSION = ID:33206 | NAME:"Подавление боли","Pain Suppression" | CD:180 | ICON:135936
SPELL DESPERATE_PRAYER = ID:19236 | NAME:"Молитва отчаяния","Desperate Prayer" | CD:90 | ICON:237550
SPELL FADE = ID:586 | NAME:"Уход в тень","Fade" | CD:30 | ICON:135994
SPELL POWER_WORD_SHIELD = ID:17 | NAME:"Слово силы: Щит","Power Word: Shield" | CD:7.5 | ICON:135940
]]

RegisterPreset("PRIEST_08_DISC_PVE", "PRIEST", "8. ДЦ: PvE Искупление вины (Atonement)", "PVE", [[
# PROFILE: 8. ДЦ: PvE Искупление вины (Atonement)
# CLASS: PRIEST
# SPEC: Discipline
# MODE: PVE
]] .. PRIEST_DISC_SPELLBOOK_MD .. [[
TRACK_SAVES: PAIN_SUPPRESSION, DESPERATE_PRAYER, POWER_WORD_SHIELD, FADE
TRACK_CDS: POWER_INFUSION, PSYFIEND, RAPTURE, HALO
IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
ELSE IF player.hp_percent <= 25 AND READY(PAIN_SUPPRESSION) THEN
    RETURN EMERGENCY(PAIN_SUPPRESSION)
END IF
IF NOT target.has_dots AND READY(SHADOW_WORD_PAIN) THEN
    RETURN CAST(SHADOW_WORD_PAIN)
ELSE IF READY(PSYFIEND) THEN
    RETURN CAST(PSYFIEND)
ELSE IF READY(PENANCE) THEN
    RETURN CAST(PENANCE)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF USABLE(SHADOW_WORD_DEATH) AND READY(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(HALO) THEN
    RETURN CAST(HALO)
ELSE
    RETURN CAST(SMITE)
END IF
]])

-- #9: PRIEST — Discipline PvP Arena
RegisterPreset("PRIEST_09_DISC_PVP", "PRIEST", "9. ДЦ: PvP Арена (Ассист и Экзекут)", "PVP", [[
# PROFILE: 9. ДЦ: PvP Арена (Ассист и Экзекут)
# CLASS: PRIEST
# SPEC: Discipline
# MODE: PVP
]] .. PRIEST_DISC_SPELLBOOK_MD .. [[
TRACK_SAVES: PAIN_SUPPRESSION, DESPERATE_PRAYER, POWER_WORD_SHIELD, FADE
TRACK_CDS: POWER_INFUSION, PSYFIEND, RAPTURE, PENANCE
IF player.hp_percent <= 25 AND READY(PAIN_SUPPRESSION) THEN
    RETURN EMERGENCY(PAIN_SUPPRESSION)
ELSE IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
END IF
IF USABLE(SHADOW_WORD_DEATH) AND READY(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF NOT target.has_dots AND READY(SHADOW_WORD_PAIN) THEN
    RETURN CAST(SHADOW_WORD_PAIN)
ELSE IF READY(PENANCE) THEN
    RETURN CAST(PENANCE)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(PSYFIEND) THEN
    RETURN CAST(PSYFIEND)
ELSE
    RETURN CAST(SMITE)
END IF
]])

-- #10: PRIEST — Holy PvE DPS/Filler
local PRIEST_HOLY_SPELLBOOK_MD = [[
## SPELL_BOOK (Holy Priest)
SPELL HOLY_FIRE = ID:14914 | NAME:"Священный огонь","Holy Fire" | CD:10 | CHARGES:1 | DOTS:true | ICON:135972
SPELL HOLY_WORD_CHASTISE = ID:88625 | NAME:"Слово Света: Наказание","Holy Word: Chastise" | CD:60 | CHARGES:1 | ICON:135886
SPELL SHADOW_WORD_DEATH = ID:32379 | NAME:"Слово Тьмы: Смерть","Shadow Word: Death" | CD:10 | EXECUTE:true | ICON:136149
SPELL SHADOW_WORD_PAIN = ID:589 | NAME:"Слово Тьмы: Боль","Shadow Word: Pain" | CD:0 | DOTS:true | ICON:136207
SPELL HALO = ID:120517,122121 | NAME:"Сияние","Божественная звезда","Halo","Divine Star" | CD:40 | ICON:632352
SPELL SMITE = ID:585 | NAME:"Кара","Smite" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:135924
SPELL APOTHEOSIS = ID:200183 | NAME:"Апофеоз","Apotheosis" | CD:120 | ICON:1060983
SPELL DIVINE_HYMN = ID:64843 | NAME:"Божественный гимн","Divine Hymn" | CD:180 | ICON:237540
SPELL GUARDIAN_SPIRIT = ID:47788 | NAME:"Оберегающий дух","Guardian Spirit" | CD:180 | ICON:237542
SPELL POWER_INFUSION = ID:10060 | NAME:"Придание сил","Power Infusion" | CD:120 | ICON:135939
SPELL DESPERATE_PRAYER = ID:19236 | NAME:"Молитва отчаяния","Desperate Prayer" | CD:90 | ICON:237550
SPELL FADE = ID:586 | NAME:"Уход в тень","Fade" | CD:30 | ICON:135994
]]

RegisterPreset("PRIEST_10_HOLY_PVE", "PRIEST", "10. Холи: PvE Урон в окно исцеления", "PVE", [[
# PROFILE: 10. Холи: PvE Урон в окно исцеления
# CLASS: PRIEST
# SPEC: Holy
# MODE: PVE
]] .. PRIEST_HOLY_SPELLBOOK_MD .. [[
TRACK_SAVES: GUARDIAN_SPIRIT, DESPERATE_PRAYER, DIVINE_HYMN, FADE
TRACK_CDS: POWER_INFUSION, APOTHEOSIS, HOLY_WORD_CHASTISE, HALO
IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
ELSE IF player.hp_percent <= 25 AND READY(GUARDIAN_SPIRIT) THEN
    RETURN EMERGENCY(GUARDIAN_SPIRIT)
END IF
IF READY(HOLY_WORD_CHASTISE) THEN
    RETURN CAST(HOLY_WORD_CHASTISE)
ELSE IF READY(HOLY_FIRE) THEN
    RETURN CAST(HOLY_FIRE)
ELSE IF USABLE(SHADOW_WORD_DEATH) AND READY(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(HALO) THEN
    RETURN CAST(HALO)
ELSE
    RETURN CAST(SMITE)
END IF
]])

-- ====================================================================================
-- 11..55: CROSS-CLASS PRESET LIBRARY (Real Spec Spellbooks & FSM Queues for all 12 Classes)
-- ====================================================================================

local MAGE_ARCANE_MD = [[
## SPELL_BOOK (Arcane Mage)
SPELL ARCANE_SURGE = ID:365350 | NAME:"Чародейский выброс","Arcane Surge" | CD:90 | ICON:4667417
SPELL TOUCH_OF_THE_MAGI = ID:321507 | NAME:"Касание мага","Touch of the Magi" | CD:45 | ICON:135753
SPELL ARCANE_ORB = ID:153626 | NAME:"Чародейская сфера","Arcane Orb" | CD:20 | CHARGES:1 | ICON:651090
SPELL ARCANE_BARRAGE = ID:44425 | NAME:"Чародейский обстрел","Arcane Barrage" | CD:3 | ICON:236205
SPELL ARCANE_MISSILES = ID:5143 | NAME:"Чародейские стрелы","Arcane Missiles" | CD:0 | PROC_ONLY:true | ICON:136096
SPELL SHIFTING_POWER = ID:382440 | NAME:"Переходящая сила","Shifting Power" | CD:60 | ICON:3636843
SPELL EVOCATION = ID:12051 | NAME:"Прилив сил","Evocation" | CD:90 | ICON:136075
SPELL ARCANE_BLAST = ID:30451 | NAME:"Чародейская вспышка","Arcane Blast" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:135735
SPELL ICE_BLOCK = ID:45438,414658 | NAME:"Ледяная глыба","Холодная хватка","Ice Block","Ice Cold" | CD:240 | ICON:135841
SPELL MIRROR_IMAGE = ID:55342 | NAME:"Зеркальное изображение","Mirror Image" | CD:120 | ICON:135994
SPELL ALTER_TIME = ID:342245,108978 | NAME:"Путешествие во времени","Alter Time" | CD:60 | ICON:609811
SPELL PRISMATIC_BARRIER = ID:235450,11426 | NAME:"Призматический барьер","Ледяная преграда","Prismatic Barrier","Ice Barrier" | CD:25 | ICON:135991
TRACK_SAVES: ICE_BLOCK, MIRROR_IMAGE, ALTER_TIME, PRISMATIC_BARRIER
TRACK_CDS: ARCANE_SURGE, TOUCH_OF_THE_MAGI, EVOCATION, SHIFTING_POWER
IF player.hp_percent <= 25 AND READY(ICE_BLOCK) THEN
    RETURN EMERGENCY(ICE_BLOCK)
ELSE IF player.hp_percent <= 25 AND READY(PRISMATIC_BARRIER) THEN
    RETURN EMERGENCY(PRISMATIC_BARRIER)
END IF
IF PROC(ARCANE_MISSILES) AND READY(ARCANE_MISSILES) THEN
    RETURN CAST(ARCANE_MISSILES)
ELSE IF READY(TOUCH_OF_THE_MAGI) THEN
    RETURN CAST(TOUCH_OF_THE_MAGI)
ELSE IF READY(ARCANE_SURGE) THEN
    RETURN CAST(ARCANE_SURGE)
ELSE IF READY(ARCANE_ORB) THEN
    RETURN CAST(ARCANE_ORB)
ELSE IF READY(SHIFTING_POWER) THEN
    RETURN CAST(SHIFTING_POWER)
ELSE IF READY(ARCANE_BARRAGE) THEN
    RETURN CAST(ARCANE_BARRAGE)
ELSE
    RETURN CAST(ARCANE_BLAST)
END IF
]]

local MAGE_FIRE_MD = [[
## SPELL_BOOK (Fire Mage)
SPELL COMBUSTION = ID:190319 | NAME:"Возгорание","Combustion" | CD:120 | ICON:135824
SPELL FIRE_BLAST = ID:108853 | NAME:"Огненный взрыв","Fire Blast" | CD:12 | CHARGES:3 | ICON:135807
SPELL PHOENIX_FLAMES = ID:257541 | NAME:"Пламя феникса","Phoenix Flames" | CD:25 | CHARGES:3 | ICON:135813
SPELL PYROBLAST = ID:11366,2120 | NAME:"Огненная глыба","Огненный столб","Pyroblast","Flamestrike" | CD:0 | ICON:135808
SPELL METEOR = ID:153561 | NAME:"Метеор","Meteor" | CD:45 | ICON:1033911
SPELL SCORCH = ID:2948 | NAME:"Ожог","Scorch" | CD:0 | EXECUTE:true | ICON:135827
SPELL SHIFTING_POWER = ID:382440 | NAME:"Переходящая сила","Shifting Power" | CD:60 | ICON:3636843
SPELL FIREBALL = ID:133 | NAME:"Огненный шар","Fireball" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:135812
SPELL ICE_BLOCK = ID:45438,414658 | NAME:"Ледяная глыба","Холодная хватка","Ice Block","Ice Cold" | CD:240 | ICON:135841
SPELL MIRROR_IMAGE = ID:55342 | NAME:"Зеркальное изображение","Mirror Image" | CD:120 | ICON:135994
SPELL ALTER_TIME = ID:342245,108978 | NAME:"Путешествие во времени","Alter Time" | CD:60 | ICON:609811
SPELL BLAZING_BARRIER = ID:235313 | NAME:"Пылающий барьер","Blazing Barrier" | CD:25 | ICON:135789
TRACK_SAVES: ICE_BLOCK, MIRROR_IMAGE, ALTER_TIME, BLAZING_BARRIER
TRACK_CDS: COMBUSTION, METEOR, SHIFTING_POWER, FIRE_BLAST
IF player.hp_percent <= 25 AND READY(ICE_BLOCK) THEN
    RETURN EMERGENCY(ICE_BLOCK)
ELSE IF player.hp_percent <= 25 AND READY(BLAZING_BARRIER) THEN
    RETURN EMERGENCY(BLAZING_BARRIER)
END IF
IF PROC(PYROBLAST) AND READY(PYROBLAST) THEN
    RETURN CAST(PYROBLAST)
ELSE IF USABLE(SCORCH) AND READY(SCORCH) THEN
    RETURN CAST(SCORCH)
ELSE IF READY(METEOR) THEN
    RETURN CAST(METEOR)
ELSE IF READY(FIRE_BLAST) THEN
    RETURN CAST(FIRE_BLAST)
ELSE IF READY(PHOENIX_FLAMES) THEN
    RETURN CAST(PHOENIX_FLAMES)
ELSE IF READY(SHIFTING_POWER) THEN
    RETURN CAST(SHIFTING_POWER)
ELSE
    RETURN CAST(FIREBALL)
END IF
]]

local MAGE_FROST_SPELLBOOK_MD = [[
## SPELL_BOOK (Frost Mage — Midnight 12.x Overhaul)
TARGET_DEBUFF: NAME:"Обледенение","Замерзание","Freezing","Зимняя стужа","Winter's Chill"
SPELL RAY_OF_FROST = ID:205021 | NAME:"Луч холода","Ray of Frost" | CD:60 | CHARGES:1 | STACKS:+3 | LOCK_CHANNEL:true | ICON:1698700
SPELL COMET_STORM = ID:153595,455396 | NAME:"Кометная буря","Comet Storm" | CD:30 | STACKS:+2 | PROC_ONLY:true | OVERRIDE_OF:RAY_OF_FROST | ICON:1033912
SPELL GLACIAL_SPIKE = ID:199786,257537 | NAME:"Ледниковый шип","Черная стрела","Glacial Spike","Ebonbolt" | CD:0 | STACKS:+2 | PROC_ONLY:true | OVERRIDE_OF:FROSTBOLT | ICON:1394891
SPELL FLURRY = ID:44614 | NAME:"Шквал","Flurry" | CD:30 | CHARGES:2 | STACKS:+2 | ICON:135859
SPELL FROZEN_ORB = ID:84714 | NAME:"Ледяной шар","Мерзлая сфера","Frozen Orb" | CD:60 | STACKS:+2 | ICON:629077
SPELL ICE_LANCE = ID:30455 | NAME:"Ледяное копье","Ice Lance" | CD:0 | CONSUMES_STACKS:true | STACKS:-4 | ICON:135844
SPELL BLIZZARD = ID:190356,1248829 | NAME:"Снежная буря","Blizzard" | CD:8 | ICON:135857
SPELL FROSTBOLT = ID:431044,116 | NAME:"Ледяная стрела","Стрела ледяного огня","Frostbolt","Frostfire Bolt" | CD:0 | STACKS:+1 | ICON:135846
SPELL SHIFTING_POWER = ID:382440 | NAME:"Переходящая сила","Shifting Power" | CD:60 | ICON:3636843
SPELL ICE_BLOCK = ID:45438,414658 | NAME:"Ледяная глыба","Холодная хватка","Ice Block","Ice Cold" | CD:240 | CHARGES:2 | ICON:135841
SPELL ICE_BARRIER = ID:11426,235313,431038 | NAME:"Ледяная преграда","Пылающая преграда","Пылающий барьер","Ice Barrier","Blazing Barrier" | CD:25 | CHARGES:1 | ICON:135988
SPELL ALTER_TIME = ID:342245,108978 | NAME:"Манипуляции со временем","Путешествие во времени","Alter Time" | CD:60 | ICON:609811
SPELL COLD_SNAP = ID:235219,55342 | NAME:"Холодная хватка","Зеркальное изображение","Cold Snap","Mirror Image" | CD:120 | ICON:135865

## CHANNEL_POLICY (Ray of Frost — главный КД, прерывать нельзя!)
PROTECT_CHANNEL: RAY_OF_FROST

## TRACKERS
TRACK_SAVES: ICE_BLOCK, ICE_BARRIER, ALTER_TIME, COLD_SNAP
TRACK_CDS: RAY_OF_FROST, FROZEN_ORB, FLURRY, COMET_STORM

## EMERGENCY_SAVE
IF player.hp_percent <= 25 AND READY(ICE_BLOCK) THEN
    RETURN EMERGENCY(ICE_BLOCK)
ELSE IF player.hp_percent <= 25 AND READY(ICE_BARRIER) THEN
    RETURN EMERGENCY(ICE_BARRIER)
END IF
]]

local MAGE_FROST_MD = MAGE_FROST_SPELLBOOK_MD .. [[
## ROTATION_QUEUE (Midnight 12.x — Cleave / Mythic+ / Open World)
IF PROC(COMET_STORM) AND READY(COMET_STORM) THEN
    RETURN CAST(COMET_STORM)
ELSE IF PROC(GLACIAL_SPIKE) AND READY(GLACIAL_SPIKE) THEN
    RETURN CAST(GLACIAL_SPIKE)
ELSE IF PROC(FLURRY) AND READY(FLURRY) THEN
    RETURN CAST(FLURRY)
ELSE IF CHARGES(RAY_OF_FROST) >= 2 AND READY(RAY_OF_FROST) THEN
    RETURN CAST(RAY_OF_FROST)
ELSE IF READY(FROZEN_ORB) THEN
    RETURN CAST(FROZEN_ORB)
ELSE IF READY(RAY_OF_FROST) THEN
    RETURN CAST(RAY_OF_FROST)
ELSE IF READY(FLURRY) THEN
    RETURN CAST(FLURRY)
ELSE IF PROC(ICE_LANCE) AND READY(ICE_LANCE) THEN
    RETURN CAST(ICE_LANCE)
ELSE IF target.freezing_stacks >= 4 AND READY(ICE_LANCE) THEN
    RETURN CAST(ICE_LANCE)
ELSE IF READY(BLIZZARD) THEN
    RETURN CAST(BLIZZARD)
ELSE
    RETURN CAST(FROSTBOLT)
END IF
]]

local MAGE_FROST_ST_MD = MAGE_FROST_SPELLBOOK_MD .. [[
## ROTATION_QUEUE (Midnight 12.x — Single Target / Leveling / PvP)
IF PROC(COMET_STORM) AND READY(COMET_STORM) THEN
    RETURN CAST(COMET_STORM)
ELSE IF PROC(GLACIAL_SPIKE) AND READY(GLACIAL_SPIKE) THEN
    RETURN CAST(GLACIAL_SPIKE)
ELSE IF READY(RAY_OF_FROST) THEN
    RETURN CAST(RAY_OF_FROST)
ELSE IF READY(FLURRY) THEN
    RETURN CAST(FLURRY)
ELSE IF READY(FROZEN_ORB) THEN
    RETURN CAST(FROZEN_ORB)
ELSE IF PROC(ICE_LANCE) AND READY(ICE_LANCE) THEN
    RETURN CAST(ICE_LANCE)
ELSE IF target.freezing_stacks >= 4 AND READY(ICE_LANCE) THEN
    RETURN CAST(ICE_LANCE)
ELSE IF PROC(BLIZZARD) AND READY(BLIZZARD) THEN
    RETURN CAST(BLIZZARD)
ELSE
    RETURN CAST(FROSTBOLT)
END IF
]]

local WARLOCK_AFF_MD = [[
## SPELL_BOOK (Affliction Warlock)
SPELL SUMMON_DARKGLARE = ID:205180 | NAME:"Призыв созерцателя тьмы","Summon Darkglare" | CD:120 | ICON:1416161
SPELL SOUL_ROT = ID:386997 | NAME:"Гниение души","Soul Rot" | CD:60 | ICON:3636850
SPELL VILE_TAINT = ID:278350,48181 | NAME:"Поганая скверна","Блуждающий дух","Vile Taint","Haunt" | CD:20 | DOTS:true | ICON:2065628
SPELL UNSTABLE_AFFLICTION = ID:316099 | NAME:"Нестабильное колдовство","Unstable Affliction" | CD:0 | DOTS:true | ICON:136228
SPELL AGONY = ID:980 | NAME:"Агония","Agony" | CD:0 | DOTS:true | ICON:136139
SPELL CORRUPTION = ID:172,27243 | NAME:"Порча","Семя порчи","Corruption","Seed of Corruption" | CD:0 | DOTS:true | ICON:136118
SPELL MALEFIC_RAPTURE = ID:324536 | NAME:"Пагубный восторг","Malefic Rapture" | CD:0 | ICON:3528291
SPELL SHADOW_BOLT = ID:686,198590 | NAME:"Стрела Тьмы","Похищение души","Shadow Bolt","Drain Soul" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:136197
SPELL UNENDING_RESOLVE = ID:104773 | NAME:"Твердая решимость","Unending Resolve" | CD:180 | ICON:136150
SPELL DARK_PACT = ID:108416 | NAME:"Темный пакт","Dark Pact" | CD:60 | ICON:538538
SPELL MORTAL_COIL = ID:6789 | NAME:"Лик тлена","Mortal Coil" | CD:45 | ICON:136145
SPELL DRAIN_LIFE = ID:234153 | NAME:"Похищение жизни","Drain Life" | CD:0 | ICON:136169
TRACK_SAVES: UNENDING_RESOLVE, DARK_PACT, MORTAL_COIL, DRAIN_LIFE
TRACK_CDS: SUMMON_DARKGLARE, SOUL_ROT, VILE_TAINT, MALEFIC_RAPTURE
IF player.hp_percent <= 25 AND READY(UNENDING_RESOLVE) THEN
    RETURN EMERGENCY(UNENDING_RESOLVE)
ELSE IF player.hp_percent <= 25 AND READY(DARK_PACT) THEN
    RETURN EMERGENCY(DARK_PACT)
END IF
IF NOT target.has_dots AND READY(VILE_TAINT) THEN
    RETURN CAST(VILE_TAINT)
ELSE IF NOT target.has_dots AND READY(AGONY) THEN
    RETURN CAST(AGONY)
ELSE IF READY(SOUL_ROT) THEN
    RETURN CAST(SOUL_ROT)
ELSE IF READY(SUMMON_DARKGLARE) THEN
    RETURN CAST(SUMMON_DARKGLARE)
ELSE IF READY(VILE_TAINT) THEN
    RETURN CAST(VILE_TAINT)
ELSE IF PROC(SHADOW_BOLT) THEN
    RETURN CAST(SHADOW_BOLT)
ELSE IF READY(MALEFIC_RAPTURE) THEN
    RETURN CAST(MALEFIC_RAPTURE)
ELSE
    RETURN CAST(SHADOW_BOLT)
END IF
]]

local WARLOCK_DEMO_MD = [[
## SPELL_BOOK (Demonology Warlock)
SPELL SUMMON_TYRANT = ID:265187 | NAME:"Призыв демонического тирана","Summon Demonic Tyrant" | CD:60 | ICON:2065628
SPELL CALL_DREADSTALKERS = ID:104316 | NAME:"Зов зловещих охотников","Call Dreadstalkers" | CD:20 | ICON:1378282
SPELL SUMMON_VILEFIEND = ID:264119,111898 | NAME:"Призыв мерзкого стража","Гримуар: страж Скверны","Summon Vilefiend","Grimoire: Felguard" | CD:45 | ICON:132182
SPELL HAND_OF_GULDAN = ID:105174 | NAME:"Рука Гул'дана","Hand of Gul'dan" | CD:0 | ICON:575588
SPELL DEMONBOLT = ID:264178 | NAME:"Демоническая стрела","Demonbolt" | CD:0 | CHARGES:2 | ICON:1035048
SPELL IMPLOSION = ID:196277 | NAME:"Имплозия","Implosion" | CD:0 | ICON:136218
SPELL SHADOW_BOLT = ID:686 | NAME:"Стрела Тьмы","Shadow Bolt" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:136197
SPELL UNENDING_RESOLVE = ID:104773 | NAME:"Твердая решимость","Unending Resolve" | CD:180 | ICON:136150
SPELL DARK_PACT = ID:108416 | NAME:"Темный пакт","Dark Pact" | CD:60 | ICON:538538
SPELL MORTAL_COIL = ID:6789 | NAME:"Лик тлена","Mortal Coil" | CD:45 | ICON:136145
SPELL DRAIN_LIFE = ID:234153 | NAME:"Похищение жизни","Drain Life" | CD:0 | ICON:136169
TRACK_SAVES: UNENDING_RESOLVE, DARK_PACT, MORTAL_COIL, DRAIN_LIFE
TRACK_CDS: SUMMON_TYRANT, SUMMON_VILEFIEND, CALL_DREADSTALKERS, DEMONBOLT
IF player.hp_percent <= 25 AND READY(UNENDING_RESOLVE) THEN
    RETURN EMERGENCY(UNENDING_RESOLVE)
ELSE IF player.hp_percent <= 25 AND READY(DARK_PACT) THEN
    RETURN EMERGENCY(DARK_PACT)
END IF
IF PROC(DEMONBOLT) AND READY(DEMONBOLT) THEN
    RETURN CAST(DEMONBOLT)
ELSE IF READY(CALL_DREADSTALKERS) THEN
    RETURN CAST(CALL_DREADSTALKERS)
ELSE IF READY(SUMMON_VILEFIEND) THEN
    RETURN CAST(SUMMON_VILEFIEND)
ELSE IF READY(SUMMON_TYRANT) THEN
    RETURN CAST(SUMMON_TYRANT)
ELSE IF READY(HAND_OF_GULDAN) THEN
    RETURN CAST(HAND_OF_GULDAN)
ELSE
    RETURN CAST(SHADOW_BOLT)
END IF
]]

local WARLOCK_DESTRO_MD = [[
## SPELL_BOOK (Destruction Warlock)
SPELL SUMMON_INFERNAL = ID:1122 | NAME:"Призыв инфернала","Summon Infernal" | CD:120 | ICON:136219
SPELL IMMOLATE = ID:348,445468,152108 | NAME:"Жертвенный огонь","Увядание","Катаклизм","Immolate","Wither","Cataclysm" | CD:0 | DOTS:true | ICON:135817
SPELL CONFLAGRATE = ID:17962 | NAME:"Поджигание","Conflagrate" | CD:12 | CHARGES:2 | ICON:135809
SPELL CHAOS_BOLT = ID:116858,42223 | NAME:"Стрела Хаоса","Огненный ливень","Chaos Bolt","Rain of Fire" | CD:0 | ICON:236291
SPELL SHADOWBURN = ID:17877 | NAME:"Ожог Тьмы","Shadowburn" | CD:12 | EXECUTE:true | ICON:136191
SPELL CHANNEL_DEMONFIRE = ID:196447,80240 | NAME:"Направленный демонический огонь","Нанесение хаоса","Channel Demonfire","Havoc" | CD:25 | ICON:135799
SPELL INCINERATE = ID:29722 | NAME:"Испепеление","Incinerate" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:135789
SPELL UNENDING_RESOLVE = ID:104773 | NAME:"Твердая решимость","Unending Resolve" | CD:180 | ICON:136150
SPELL DARK_PACT = ID:108416 | NAME:"Темный пакт","Dark Pact" | CD:60 | ICON:538538
SPELL MORTAL_COIL = ID:6789 | NAME:"Лик тлена","Mortal Coil" | CD:45 | ICON:136145
SPELL DRAIN_LIFE = ID:234153 | NAME:"Похищение жизни","Drain Life" | CD:0 | ICON:136169
TRACK_SAVES: UNENDING_RESOLVE, DARK_PACT, MORTAL_COIL, DRAIN_LIFE
TRACK_CDS: SUMMON_INFERNAL, CHANNEL_DEMONFIRE, CONFLAGRATE, SHADOWBURN
IF player.hp_percent <= 25 AND READY(UNENDING_RESOLVE) THEN
    RETURN EMERGENCY(UNENDING_RESOLVE)
ELSE IF player.hp_percent <= 25 AND READY(DARK_PACT) THEN
    RETURN EMERGENCY(DARK_PACT)
END IF
IF NOT target.has_dots AND READY(IMMOLATE) THEN
    RETURN CAST(IMMOLATE)
ELSE IF USABLE(SHADOWBURN) AND READY(SHADOWBURN) THEN
    RETURN CAST(SHADOWBURN)
ELSE IF READY(SUMMON_INFERNAL) THEN
    RETURN CAST(SUMMON_INFERNAL)
ELSE IF READY(CHANNEL_DEMONFIRE) THEN
    RETURN CAST(CHANNEL_DEMONFIRE)
ELSE IF READY(CONFLAGRATE) THEN
    RETURN CAST(CONFLAGRATE)
ELSE IF READY(CHAOS_BOLT) THEN
    RETURN CAST(CHAOS_BOLT)
ELSE
    RETURN CAST(INCINERATE)
END IF
]]

local PALADIN_RET_MD = [[
## SPELL_BOOK (Retribution Paladin)
SPELL AVENGING_WRATH = ID:31884,231895 | NAME:"Гнев карателя","Крестовый поход","Avenging Wrath","Crusade" | CD:120 | ICON:135875
SPELL WAKE_OF_ASHES = ID:255937 | NAME:"Испепеляющий след","Wake of Ashes" | CD:30 | ICON:1112937
SPELL EXECUTION_SENTENCE = ID:343527,343721 | NAME:"Смертный приговор","Последний расчет","Execution Sentence","Final Reckoning" | CD:30 | ICON:461859
SPELL DIVINE_TOLL = ID:375576 | NAME:"Божественный благовест","Divine Toll" | CD:60 | ICON:3578227
SPELL FINAL_VERDICT = ID:383328,85256,53385 | NAME:"Окончательный приговор","Вердикт храмовника","Божественная буря","Final Verdict","Templar's Verdict","Divine Storm" | CD:0 | ICON:461860
SPELL HAMMER_OF_WRATH = ID:24275 | NAME:"Молот гнева","Hammer of Wrath" | CD:7.5 | EXECUTE:true | ICON:613533
SPELL BLADE_OF_JUSTICE = ID:184575 | NAME:"Клинок справедливости","Blade of Justice" | CD:10 | ICON:1360760
SPELL JUDGMENT = ID:20271 | NAME:"Правосудие","Judgment" | CD:10 | CHARGES:2 | ICON:135959
SPELL CRUSADER_STRIKE = ID:35395,406834 | NAME:"Удар воина Света","Удары храмовника","Crusader Strike","Templar Strikes" | CD:0 | CHARGES:2 | FILLER_INTERRUPTIBLE:true | ICON:135891
SPELL DIVINE_SHIELD = ID:642 | NAME:"Божественный щит","Divine Shield" | CD:300 | ICON:524354
SPELL SHIELD_OF_VENGEANCE = ID:184662,403876 | NAME:"Щит возмездия","Божественная защита","Shield of Vengeance","Divine Protection" | CD:90 | ICON:571555
SPELL LAY_ON_HANDS = ID:633 | NAME:"Возложение рук","Lay on Hands" | CD:420 | ICON:135928
SPELL BLESSING_OF_PROTECTION = ID:1022 | NAME:"Благословение защиты","Blessing of Protection" | CD:300 | ICON:135964
TRACK_SAVES: DIVINE_SHIELD, SHIELD_OF_VENGEANCE, LAY_ON_HANDS, BLESSING_OF_PROTECTION
TRACK_CDS: AVENGING_WRATH, WAKE_OF_ASHES, DIVINE_TOLL, EXECUTION_SENTENCE
IF player.hp_percent <= 25 AND READY(DIVINE_SHIELD) THEN
    RETURN EMERGENCY(DIVINE_SHIELD)
ELSE IF player.hp_percent <= 25 AND READY(LAY_ON_HANDS) THEN
    RETURN EMERGENCY(LAY_ON_HANDS)
END IF
IF USABLE(HAMMER_OF_WRATH) AND READY(HAMMER_OF_WRATH) THEN
    RETURN CAST(HAMMER_OF_WRATH)
ELSE IF READY(EXECUTION_SENTENCE) THEN
    RETURN CAST(EXECUTION_SENTENCE)
ELSE IF READY(WAKE_OF_ASHES) THEN
    RETURN CAST(WAKE_OF_ASHES)
ELSE IF READY(DIVINE_TOLL) THEN
    RETURN CAST(DIVINE_TOLL)
ELSE IF READY(BLADE_OF_JUSTICE) THEN
    RETURN CAST(BLADE_OF_JUSTICE)
ELSE IF READY(JUDGMENT) THEN
    RETURN CAST(JUDGMENT)
ELSE IF READY(FINAL_VERDICT) THEN
    RETURN CAST(FINAL_VERDICT)
ELSE
    RETURN CAST(CRUSADER_STRIKE)
END IF
]]

local PALADIN_PROT_MD = [[
## SPELL_BOOK (Protection Paladin)
SPELL AVENGERS_SHIELD = ID:31935 | NAME:"Щит мстителя","Avenger's Shield" | CD:15 | ICON:135874
SPELL SHIELD_OF_THE_RIGHTEOUS = ID:53600 | NAME:"Щит праведника","Shield of the Righteous" | CD:1 | ICON:236265
SPELL JUDGMENT = ID:275779,20271 | NAME:"Правосудие","Judgment" | CD:6 | CHARGES:2 | ICON:135959
SPELL BLESSED_HAMMER = ID:204019,53595 | NAME:"Благословенный молот","Молот праведника","Blessed Hammer","Hammer of the Righteous" | CD:6 | CHARGES:3 | FILLER_INTERRUPTIBLE:true | ICON:135975
SPELL CONSECRATION = ID:26573 | NAME:"Освящение","Consecration" | CD:4.5 | ICON:135926
SPELL HAMMER_OF_WRATH = ID:24275 | NAME:"Молот гнева","Hammer of Wrath" | CD:7.5 | EXECUTE:true | ICON:613533
SPELL DIVINE_TOLL = ID:375576 | NAME:"Божественный благовест","Divine Toll" | CD:60 | ICON:3578227
SPELL AVENGING_WRATH = ID:31884 | NAME:"Гнев карателя","Avenging Wrath" | CD:120 | ICON:135875
SPELL ARDENT_DEFENDER = ID:31850 | NAME:"Ревностный защитник","Ardent Defender" | CD:120 | ICON:135870
SPELL GUARDIAN_OF_ANCIENT_KINGS = ID:86659 | NAME:"Защитник древних королей","Guardian of Ancient Kings" | CD:180 | ICON:409594
SPELL DIVINE_SHIELD = ID:642 | NAME:"Божественный щит","Divine Shield" | CD:300 | ICON:524354
SPELL LAY_ON_HANDS = ID:633 | NAME:"Возложение рук","Lay on Hands" | CD:420 | ICON:135928
TRACK_SAVES: ARDENT_DEFENDER, GUARDIAN_OF_ANCIENT_KINGS, DIVINE_SHIELD, LAY_ON_HANDS
TRACK_CDS: AVENGING_WRATH, DIVINE_TOLL, AVENGERS_SHIELD, SHIELD_OF_THE_RIGHTEOUS
IF player.hp_percent <= 25 AND READY(ARDENT_DEFENDER) THEN
    RETURN EMERGENCY(ARDENT_DEFENDER)
ELSE IF player.hp_percent <= 25 AND READY(LAY_ON_HANDS) THEN
    RETURN EMERGENCY(LAY_ON_HANDS)
END IF
IF USABLE(HAMMER_OF_WRATH) AND READY(HAMMER_OF_WRATH) THEN
    RETURN CAST(HAMMER_OF_WRATH)
ELSE IF READY(DIVINE_TOLL) THEN
    RETURN CAST(DIVINE_TOLL)
ELSE IF READY(AVENGERS_SHIELD) THEN
    RETURN CAST(AVENGERS_SHIELD)
ELSE IF READY(JUDGMENT) THEN
    RETURN CAST(JUDGMENT)
ELSE IF READY(CONSECRATION) THEN
    RETURN CAST(CONSECRATION)
ELSE
    RETURN CAST(BLESSED_HAMMER)
END IF
]]

local HUNTER_BM_MD = [[
## SPELL_BOOK (Beast Mastery Hunter)
SPELL BESTIAL_WRATH = ID:19574 | NAME:"Звериный гнев","Bestial Wrath" | CD:90 | ICON:132127
SPELL CALL_OF_THE_WILD = ID:359844,321530 | NAME:"Зов дикой природы","Кровопролитие","Call of the Wild","Bloodshed" | CD:120 | ICON:4667418
SPELL BARBED_SHOT = ID:217200 | NAME:"Раздирающий выстрел","Barbed Shot" | CD:12 | CHARGES:2 | DOTS:true | ICON:2058007
SPELL KILL_COMMAND = ID:34026 | NAME:"Команда 'Взять!'","Команда \"Взять!\"","Kill Command" | CD:7.5 | CHARGES:2 | ICON:132176
SPELL KILL_SHOT = ID:53351 | NAME:"Убийственный выстрел","Kill Shot" | CD:10 | EXECUTE:true | ICON:236174
SPELL MULTI_SHOT = ID:2643 | NAME:"Залп","Multi-Shot" | CD:0 | ICON:132330
SPELL COBRA_SHOT = ID:193455 | NAME:"Выстрел кобры","Cobra Shot" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:461114
SPELL ASPECT_OF_THE_TURTLE = ID:186265 | NAME:"Дух черепахи","Aspect of the Turtle" | CD:180 | ICON:132199
SPELL EXHILARATION = ID:109304 | NAME:"Живость","Exhilaration" | CD:120 | ICON:461117
SPELL SURVIVAL_OF_THE_FITTEST = ID:264735 | NAME:"Выживает сильнейший","Survival of the Fittest" | CD:180 | ICON:136094
SPELL FEIGN_DEATH = ID:5384 | NAME:"Притвориться мертвым","Feign Death" | CD:30 | ICON:132293
TRACK_SAVES: ASPECT_OF_THE_TURTLE, EXHILARATION, SURVIVAL_OF_THE_FITTEST, FEIGN_DEATH
TRACK_CDS: BESTIAL_WRATH, CALL_OF_THE_WILD, BARBED_SHOT, KILL_COMMAND
IF player.hp_percent <= 25 AND READY(EXHILARATION) THEN
    RETURN EMERGENCY(EXHILARATION)
ELSE IF player.hp_percent <= 25 AND READY(ASPECT_OF_THE_TURTLE) THEN
    RETURN EMERGENCY(ASPECT_OF_THE_TURTLE)
END IF
IF USABLE(KILL_SHOT) AND READY(KILL_SHOT) THEN
    RETURN CAST(KILL_SHOT)
ELSE IF READY(BARBED_SHOT) THEN
    RETURN CAST(BARBED_SHOT)
ELSE IF READY(BESTIAL_WRATH) THEN
    RETURN CAST(BESTIAL_WRATH)
ELSE IF READY(CALL_OF_THE_WILD) THEN
    RETURN CAST(CALL_OF_THE_WILD)
ELSE IF READY(KILL_COMMAND) THEN
    RETURN CAST(KILL_COMMAND)
ELSE
    RETURN CAST(COBRA_SHOT)
END IF
]]

local HUNTER_MM_MD = [[
## SPELL_BOOK (Marksmanship Hunter)
SPELL TRUESHOT = ID:288613 | NAME:"Меткий выстрел","Trueshot" | CD:120 | ICON:132329
SPELL VOLLEY = ID:260243 | NAME:"Беглый огонь","Volley" | CD:45 | ICON:132222
SPELL RAPID_FIRE = ID:257044 | NAME:"Быстрая стрельба","Rapid Fire" | CD:20 | ICON:132208
SPELL AIMED_SHOT = ID:19434 | NAME:"Прицельный выстрел","Aimed Shot" | CD:12 | CHARGES:2 | ICON:135130
SPELL KILL_SHOT = ID:53351 | NAME:"Убийственный выстрел","Kill Shot" | CD:10 | EXECUTE:true | ICON:236174
SPELL ARCANE_SHOT = ID:185358,257620 | NAME:"Чародейский выстрел","Залп","Arcane Shot","Multi-Shot" | CD:0 | ICON:132218
SPELL STEADY_SHOT = ID:56641 | NAME:"Верный выстрел","Steady Shot" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:132213
SPELL ASPECT_OF_THE_TURTLE = ID:186265 | NAME:"Дух черепахи","Aspect of the Turtle" | CD:180 | ICON:132199
SPELL EXHILARATION = ID:109304 | NAME:"Живость","Exhilaration" | CD:120 | ICON:461117
SPELL SURVIVAL_OF_THE_FITTEST = ID:264735 | NAME:"Выживает сильнейший","Survival of the Fittest" | CD:180 | ICON:136094
SPELL FEIGN_DEATH = ID:5384 | NAME:"Притвориться мертвым","Feign Death" | CD:30 | ICON:132293
TRACK_SAVES: ASPECT_OF_THE_TURTLE, EXHILARATION, SURVIVAL_OF_THE_FITTEST, FEIGN_DEATH
TRACK_CDS: TRUESHOT, VOLLEY, RAPID_FIRE, AIMED_SHOT
IF player.hp_percent <= 25 AND READY(EXHILARATION) THEN
    RETURN EMERGENCY(EXHILARATION)
ELSE IF player.hp_percent <= 25 AND READY(ASPECT_OF_THE_TURTLE) THEN
    RETURN EMERGENCY(ASPECT_OF_THE_TURTLE)
END IF
IF USABLE(KILL_SHOT) AND READY(KILL_SHOT) THEN
    RETURN CAST(KILL_SHOT)
ELSE IF READY(VOLLEY) THEN
    RETURN CAST(VOLLEY)
ELSE IF READY(RAPID_FIRE) THEN
    RETURN CAST(RAPID_FIRE)
ELSE IF READY(AIMED_SHOT) THEN
    RETURN CAST(AIMED_SHOT)
ELSE IF PROC(ARCANE_SHOT) AND READY(ARCANE_SHOT) THEN
    RETURN CAST(ARCANE_SHOT)
ELSE
    RETURN CAST(STEADY_SHOT)
END IF
]]

local HUNTER_SURV_MD = [[
## SPELL_BOOK (Survival Hunter)
SPELL COORDINATED_ASSAULT = ID:360952 | NAME:"Согласованная атака","Coordinated Assault" | CD:120 | ICON:2032587
SPELL WILDFIRE_BOMB = ID:259495 | NAME:"Дикий огонь","Wildfire Bomb" | CD:18 | CHARGES:2 | DOTS:true | ICON:2065634
SPELL KILL_COMMAND = ID:259489,34026 | NAME:"Команда 'Взять!'","Команда \"Взять!\"","Kill Command" | CD:6 | CHARGES:2 | ICON:132176
SPELL FLANKING_STRIKE = ID:269751,203415 | NAME:"Фланговый удар","Ярость орла","Flanking Strike","Fury of the Eagle" | CD:30 | ICON:236184
SPELL EXPLOSIVE_SHOT = ID:212431 | NAME:"Разрывной выстрел","Explosive Shot" | CD:30 | ICON:236178
SPELL KILL_SHOT = ID:53351 | NAME:"Убийственный выстрел","Kill Shot" | CD:10 | EXECUTE:true | ICON:236174
SPELL MONGOOSE_BITE = ID:259387,186270 | NAME:"Укус мангуста","Удар ящера","Mongoose Bite","Raptor Strike" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:1376045
SPELL ASPECT_OF_THE_TURTLE = ID:186265 | NAME:"Дух черепахи","Aspect of the Turtle" | CD:180 | ICON:132199
SPELL EXHILARATION = ID:109304 | NAME:"Живость","Exhilaration" | CD:120 | ICON:461117
SPELL SURVIVAL_OF_THE_FITTEST = ID:264735 | NAME:"Выживает сильнейший","Survival of the Fittest" | CD:180 | ICON:136094
SPELL FEIGN_DEATH = ID:5384 | NAME:"Притвориться мертвым","Feign Death" | CD:30 | ICON:132293
TRACK_SAVES: ASPECT_OF_THE_TURTLE, EXHILARATION, SURVIVAL_OF_THE_FITTEST, FEIGN_DEATH
TRACK_CDS: COORDINATED_ASSAULT, FLANKING_STRIKE, WILDFIRE_BOMB, EXPLOSIVE_SHOT
IF player.hp_percent <= 25 AND READY(EXHILARATION) THEN
    RETURN EMERGENCY(EXHILARATION)
ELSE IF player.hp_percent <= 25 AND READY(ASPECT_OF_THE_TURTLE) THEN
    RETURN EMERGENCY(ASPECT_OF_THE_TURTLE)
END IF
IF USABLE(KILL_SHOT) AND READY(KILL_SHOT) THEN
    RETURN CAST(KILL_SHOT)
ELSE IF READY(WILDFIRE_BOMB) THEN
    RETURN CAST(WILDFIRE_BOMB)
ELSE IF READY(FLANKING_STRIKE) THEN
    RETURN CAST(FLANKING_STRIKE)
ELSE IF READY(EXPLOSIVE_SHOT) THEN
    RETURN CAST(EXPLOSIVE_SHOT)
ELSE IF READY(KILL_COMMAND) THEN
    RETURN CAST(KILL_COMMAND)
ELSE
    RETURN CAST(MONGOOSE_BITE)
END IF
]]

local ROGUE_ASSA_MD = [[
## SPELL_BOOK (Assassination Rogue)
SPELL DEATHMARK = ID:360194 | NAME:"Метка смерти","Deathmark" | CD:120 | ICON:4667421
SPELL KINGSBANE = ID:385627 | NAME:"Погибель королей","Kingsbane" | CD:60 | DOTS:true | ICON:1373906
SPELL GARROTE = ID:703 | NAME:"Гаррота","Garrote" | CD:6 | DOTS:true | ICON:132297
SPELL RUPTURE = ID:1943 | NAME:"Рваная рана","Rupture" | CD:0 | DOTS:true | ICON:132302
SPELL ENVENOM = ID:32645 | NAME:"Отравление","Envenom" | CD:0 | ICON:132287
SPELL FAN_OF_KNIVES = ID:51723,121411 | NAME:"Веер клинков","Кровавый вихрь","Fan of Knives","Crimson Tempest" | CD:0 | ICON:236273
SPELL MUTILATE = ID:1329,381623 | NAME:"Расправа","Внезапный удар","Mutilate","Ambush" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:132304
SPELL CLOAK_OF_SHADOWS = ID:31224 | NAME:"Плащ теней","Cloak of Shadows" | CD:120 | ICON:136177
SPELL EVASION = ID:5277 | NAME:"Ускользание","Evasion" | CD:120 | ICON:136205
SPELL CRIMSON_VIAL = ID:185311 | NAME:"Алый фиал","Crimson Vial" | CD:30 | ICON:1373900
SPELL FEINT = ID:1966 | NAME:"Уловка","Feint" | CD:15 | CHARGES:2 | ICON:132294
TRACK_SAVES: CLOAK_OF_SHADOWS, EVASION, CRIMSON_VIAL, FEINT
TRACK_CDS: DEATHMARK, KINGSBANE, GARROTE, ENVENOM
IF player.hp_percent <= 25 AND READY(CRIMSON_VIAL) THEN
    RETURN EMERGENCY(CRIMSON_VIAL)
ELSE IF player.hp_percent <= 25 AND READY(EVASION) THEN
    RETURN EMERGENCY(EVASION)
END IF
IF NOT target.has_dots AND READY(GARROTE) THEN
    RETURN CAST(GARROTE)
ELSE IF READY(DEATHMARK) THEN
    RETURN CAST(DEATHMARK)
ELSE IF READY(KINGSBANE) THEN
    RETURN CAST(KINGSBANE)
ELSE IF READY(GARROTE) THEN
    RETURN CAST(GARROTE)
ELSE IF READY(ENVENOM) THEN
    RETURN CAST(ENVENOM)
ELSE
    RETURN CAST(MUTILATE)
END IF
]]

local ROGUE_OUTLAW_MD = [[
## SPELL_BOOK (Outlaw Rogue)
SPELL ADRENALINE_RUSH = ID:13750 | NAME:"Выброс адреналина","Adrenaline Rush" | CD:180 | ICON:136206
SPELL BLADE_FLURRY = ID:13877 | NAME:"Шквал клинков","Blade Flurry" | CD:30 | ICON:132350
SPELL ROLL_THE_BONES = ID:315508 | NAME:"Бросок костей","Roll the Bones" | CD:45 | ICON:1373910
SPELL BETWEEN_THE_EYES = ID:315341 | NAME:"Выстрел промеж глаз","Between the Eyes" | CD:45 | ICON:1373901
SPELL KILLING_SPREE = ID:51690,381989 | NAME:"Череда убийств","Продолжительная отповедь","Killing Spree","Keep It Rolling" | CD:90 | ICON:236277
SPELL DISPATCH = ID:2098 | NAME:"Устранение","Dispatch" | CD:0 | ICON:132292
SPELL PISTOL_SHOT = ID:185763 | NAME:"Выстрел из пистоли","Pistol Shot" | CD:0 | ICON:1373909
SPELL SINISTER_STRIKE = ID:193315,8676 | NAME:"Коварный удар","Внезапный удар","Sinister Strike","Ambush" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:136189
SPELL CLOAK_OF_SHADOWS = ID:31224 | NAME:"Плащ теней","Cloak of Shadows" | CD:120 | ICON:136177
SPELL EVASION = ID:5277 | NAME:"Ускользание","Evasion" | CD:120 | ICON:136205
SPELL CRIMSON_VIAL = ID:185311 | NAME:"Алый фиал","Crimson Vial" | CD:30 | ICON:1373900
SPELL FEINT = ID:1966 | NAME:"Уловка","Feint" | CD:15 | CHARGES:2 | ICON:132294
TRACK_SAVES: CLOAK_OF_SHADOWS, EVASION, CRIMSON_VIAL, FEINT
TRACK_CDS: ADRENALINE_RUSH, ROLL_THE_BONES, BLADE_FLURRY, BETWEEN_THE_EYES
IF player.hp_percent <= 25 AND READY(CRIMSON_VIAL) THEN
    RETURN EMERGENCY(CRIMSON_VIAL)
ELSE IF player.hp_percent <= 25 AND READY(EVASION) THEN
    RETURN EMERGENCY(EVASION)
END IF
IF READY(ROLL_THE_BONES) THEN
    RETURN CAST(ROLL_THE_BONES)
ELSE IF READY(BLADE_FLURRY) THEN
    RETURN CAST(BLADE_FLURRY)
ELSE IF READY(BETWEEN_THE_EYES) THEN
    RETURN CAST(BETWEEN_THE_EYES)
ELSE IF PROC(PISTOL_SHOT) AND READY(PISTOL_SHOT) THEN
    RETURN CAST(PISTOL_SHOT)
ELSE IF READY(DISPATCH) THEN
    RETURN CAST(DISPATCH)
ELSE
    RETURN CAST(SINISTER_STRIKE)
END IF
]]

local ROGUE_SUB_MD = [[
## SPELL_BOOK (Subtlety Rogue)
SPELL SHADOW_BLADES = ID:121471 | NAME:"Теневые клинки","Shadow Blades" | CD:90 | ICON:576309
SPELL SHADOW_DANCE = ID:185313 | NAME:"Танец теней","Shadow Dance" | CD:60 | CHARGES:2 | ICON:236279
SPELL SYMBOLS_OF_DEATH = ID:212283 | NAME:"Символы смерти","Symbols of Death" | CD:30 | ICON:132303
SPELL SECRET_TECHNIQUE = ID:280719 | NAME:"Тайный прием","Secret Technique" | CD:45 | ICON:2065626
SPELL RUPTURE = ID:1943 | NAME:"Рваная рана","Rupture" | CD:0 | DOTS:true | ICON:132302
SPELL EVISCERATE = ID:196819,319175 | NAME:"Потрошение","Черный порох","Eviscerate","Black Powder" | CD:0 | ICON:132292
SPELL SHADOWSTRIKE = ID:185438 | NAME:"Удар Тьмы","Shadowstrike" | CD:0 | ICON:1373912
SPELL BACKSTAB = ID:53,197835 | NAME:"Удар в спину","Шквал сюрикэнов","Backstab","Shuriken Storm" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:132090
SPELL CLOAK_OF_SHADOWS = ID:31224 | NAME:"Плащ теней","Cloak of Shadows" | CD:120 | ICON:136177
SPELL EVASION = ID:5277 | NAME:"Ускользание","Evasion" | CD:120 | ICON:136205
SPELL CRIMSON_VIAL = ID:185311 | NAME:"Алый фиал","Crimson Vial" | CD:30 | ICON:1373900
SPELL FEINT = ID:1966 | NAME:"Уловка","Feint" | CD:15 | CHARGES:2 | ICON:132294
TRACK_SAVES: CLOAK_OF_SHADOWS, EVASION, CRIMSON_VIAL, FEINT
TRACK_CDS: SHADOW_BLADES, SHADOW_DANCE, SYMBOLS_OF_DEATH, SECRET_TECHNIQUE
IF player.hp_percent <= 25 AND READY(CRIMSON_VIAL) THEN
    RETURN EMERGENCY(CRIMSON_VIAL)
ELSE IF player.hp_percent <= 25 AND READY(EVASION) THEN
    RETURN EMERGENCY(EVASION)
END IF
IF READY(SYMBOLS_OF_DEATH) THEN
    RETURN CAST(SYMBOLS_OF_DEATH)
ELSE IF READY(SECRET_TECHNIQUE) THEN
    RETURN CAST(SECRET_TECHNIQUE)
ELSE IF READY(SHADOWSTRIKE) THEN
    RETURN CAST(SHADOWSTRIKE)
ELSE IF READY(EVISCERATE) THEN
    RETURN CAST(EVISCERATE)
ELSE
    RETURN CAST(BACKSTAB)
END IF
]]

local WARRIOR_FURY_MD = [[
## SPELL_BOOK (Fury Warrior)
SPELL RECKLESSNESS = ID:1719 | NAME:"Безрассудство","Recklessness" | CD:90 | ICON:458972
SPELL AVATAR = ID:107574 | NAME:"Аватара","Avatar" | CD:90 | ICON:613534
SPELL RAVAGER = ID:228920,227847,385059 | NAME:"Опустошитель","Вихрь клинков","Ярость Одина","Ravager","Bladestorm","Odyn's Fury" | CD:45 | ICON:236303
SPELL RAMPAGE = ID:184367 | NAME:"Буйство","Rampage" | CD:0 | ICON:132352
SPELL EXECUTE = ID:5308,280735 | NAME:"Казнь","Execute" | CD:0 | EXECUTE:true | ICON:135358
SPELL BLOODTHIRST = ID:23881 | NAME:"Кровожадность","Bloodthirst" | CD:4.5 | ICON:136012
SPELL RAGING_BLOW = ID:85288 | NAME:"Яростный выпад","Raging Blow" | CD:8 | CHARGES:2 | ICON:589119
SPELL WHIRLWIND = ID:190411,1680,1464 | NAME:"Вихрь","Мощный удар","Whirlwind","Slam" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:132369
SPELL ENRAGED_REGENERATION = ID:184364 | NAME:"Безудержное восстановление","Enraged Regeneration" | CD:120 | ICON:132345
SPELL RALLYING_CRY = ID:97462,383762 | NAME:"Ободряющий клич","Горестная невосприимчивость","Rallying Cry","Bitter Immunity" | CD:180 | ICON:132351
SPELL SPELL_REFLECTION = ID:23920 | NAME:"Отражение заклинаний","Spell Reflection" | CD:25 | ICON:132361
SPELL IMPENDING_VICTORY = ID:202168 | NAME:"Верная победа","Impending Victory" | CD:25 | ICON:589768
TRACK_SAVES: ENRAGED_REGENERATION, RALLYING_CRY, SPELL_REFLECTION, IMPENDING_VICTORY
TRACK_CDS: RECKLESSNESS, AVATAR, RAVAGER, BLOODTHIRST
IF player.hp_percent <= 25 AND READY(ENRAGED_REGENERATION) THEN
    RETURN EMERGENCY(ENRAGED_REGENERATION)
ELSE IF player.hp_percent <= 25 AND READY(IMPENDING_VICTORY) THEN
    RETURN EMERGENCY(IMPENDING_VICTORY)
END IF
IF PROC(EXECUTE) AND READY(EXECUTE) THEN
    RETURN CAST(EXECUTE)
ELSE IF USABLE(EXECUTE) AND READY(EXECUTE) THEN
    RETURN CAST(EXECUTE)
ELSE IF READY(RAVAGER) THEN
    RETURN CAST(RAVAGER)
ELSE IF READY(RAMPAGE) THEN
    RETURN CAST(RAMPAGE)
ELSE IF READY(BLOODTHIRST) THEN
    RETURN CAST(BLOODTHIRST)
ELSE IF READY(RAGING_BLOW) THEN
    RETURN CAST(RAGING_BLOW)
ELSE
    RETURN CAST(WHIRLWIND)
END IF
]]

local WARRIOR_ARMS_MD = [[
## SPELL_BOOK (Arms Warrior — Slayer / Colossus)
SPELL COLOSSUS_SMASH = ID:167105,262161,436358 | NAME:"Удар колосса","Миротворец","Сокрушение","Colossus Smash","Warbreaker","Demolish" | MACRO:"M1" | SLOT:1 | KEY:"M1" | CD:45 | CHARGES:1 | ICON:132355
SPELL BLADESTORM = ID:227847,389774,228920 | NAME:"Вихрь клинков","Опустошитель","Bladestorm","Ravager" | MACRO:"M2" | SLOT:2 | KEY:"M2" | CD:90 | CHARGES:1 | ICON:236303
SPELL EXECUTE = ID:163201,5308,281000 | NAME:"Казнь","Execute" | MACRO:"SM1" | SLOT:3 | KEY:"SM1" | CD:0 | CHARGES:1 | EXECUTE:true | ICON:135358
SPELL SWEEPING_STRIKES = ID:260708 | NAME:"Размашистые удары","Sweeping Strikes" | MACRO:"SM2","R" | SLOT:4 | KEY:"SM2" | CD:30 | CHARGES:1 | ICON:132366
SPELL REND = ID:772,384318,376079 | NAME:"Кровопускание","Громогласный рык","Копье чемпиона","Rend","Thunderous Roar","Champion's Spear" | MACRO:"R" | SLOT:8 | KEY:"R" | CD:0 | CHARGES:1 | DOTS:true | ICON:132155
SPELL AVATAR = ID:107574 | NAME:"Аватара","Avatar" | MACRO:"3","SM2" | SLOT:27 | KEY:"3" | CD:90 | CHARGES:1 | ICON:613534
SPELL MORTAL_STRIKE = ID:12294 | NAME:"Смертельный удар","Mortal Strike" | MACRO:"E" | SLOT:9 | KEY:"E" | CD:6 | CHARGES:1 | ICON:132355
SPELL OVERPOWER = ID:7384 | NAME:"Превосходство","Overpower" | MACRO:"Q" | SLOT:11 | KEY:"Q" | CD:12 | CHARGES:2 | ICON:132223
SPELL CLEAVE = ID:845 | NAME:"Рассекающий удар","Cleave" | MACRO:"1" | SLOT:25 | KEY:"1" | CD:4.5 | CHARGES:1 | ICON:132338
SPELL SLAM = ID:1680,1464,6343 | NAME:"Вихрь","Мощный удар","Удар грома","Whirlwind","Slam","Thunder Clap" | MACRO:"1","M2","SQ" | SLOT:26 | KEY:"SQ" | CD:0 | CHARGES:1 | DOTS:true | FILLER_INTERRUPTIBLE:true | ICON:132369
SPELL DIE_BY_THE_SWORD = ID:118038 | NAME:"Бой насмерть","Die by the Sword" | MACRO:"CM1" | SLOT:5 | KEY:"CM1" | CD:120 | CHARGES:1 | ICON:132336
SPELL RALLYING_CRY = ID:97462,383762 | NAME:"Ободряющий клич","Горестная невосприимчивость","Rallying Cry","Bitter Immunity" | MACRO:"CM2","C" | SLOT:6 | KEY:"CM2" | CD:180 | CHARGES:1 | ICON:132351
SPELL SPELL_REFLECTION = ID:23920 | NAME:"Отражение заклинаний","Spell Reflection" | MACRO:"AM1" | SLOT:7 | KEY:"AM1" | CD:25 | CHARGES:1 | ICON:132361
SPELL IMPENDING_VICTORY = ID:202168 | NAME:"Верная победа","Impending Victory" | MACRO:"SE","2" | SLOT:10 | KEY:"SE" | CD:25 | CHARGES:1 | ICON:589768
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
ELSE IF NOT target.has_dots AND READY(REND) THEN
    RETURN CAST(REND)
ELSE IF READY(COLOSSUS_SMASH) THEN
    RETURN CAST(COLOSSUS_SMASH)
ELSE IF READY(MORTAL_STRIKE) THEN
    RETURN CAST(MORTAL_STRIKE)
ELSE IF READY(SWEEPING_STRIKES) THEN
    RETURN CAST(SWEEPING_STRIKES)
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

local WARRIOR_PROT_MD = [[
## SPELL_BOOK (Protection Warrior)
SPELL AVATAR = ID:107574 | NAME:"Аватара","Avatar" | CD:90 | ICON:613534
SPELL DEMOLISH_ROAR = ID:436358,384318,228920 | NAME:"Сокрушение","Громогласный рык","Опустошитель","Demolish","Thunderous Roar","Ravager" | CD:45 | ICON:611420
SPELL SHIELD_SLAM = ID:23922 | NAME:"Мощный удар щитом","Shield Slam" | CD:9 | ICON:134951
SPELL THUNDER_CLAP = ID:6343,435222 | NAME:"Удар грома","Громовой удар","Thunder Clap","Thunder Blast" | CD:6 | ICON:136105
SPELL EXECUTE = ID:5308,163201 | NAME:"Казнь","Execute" | CD:0 | EXECUTE:true | ICON:135358
SPELL REVENGE = ID:6572 | NAME:"Реванш","Revenge" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:132353
SPELL SHIELD_BLOCK = ID:2565 | NAME:"Блок щитом","Shield Block" | CD:16 | CHARGES:2 | ICON:132110
SPELL IGNORE_PAIN = ID:190456 | NAME:"Стойкость к боли","Ignore Pain" | CD:1 | ICON:1377132
SPELL SHIELD_WALL = ID:871 | NAME:"Глухая оборона","Shield Wall" | CD:210 | ICON:132362
SPELL LAST_STAND = ID:12975 | NAME:"Ни шагу назад","Last Stand" | CD:180 | ICON:135871
SPELL SPELL_REFLECTION = ID:23920 | NAME:"Отражение заклинаний","Spell Reflection" | CD:25 | ICON:132361
SPELL IMPENDING_VICTORY = ID:202168 | NAME:"Верная победа","Impending Victory" | CD:25 | ICON:589768
TRACK_SAVES: SHIELD_WALL, LAST_STAND, SPELL_REFLECTION, IMPENDING_VICTORY
TRACK_CDS: AVATAR, DEMOLISH_ROAR, SHIELD_BLOCK, IGNORE_PAIN
IF player.hp_percent <= 25 AND READY(SHIELD_WALL) THEN
    RETURN EMERGENCY(SHIELD_WALL)
ELSE IF player.hp_percent <= 25 AND READY(LAST_STAND) THEN
    RETURN EMERGENCY(LAST_STAND)
END IF
IF READY(SHIELD_SLAM) THEN
    RETURN CAST(SHIELD_SLAM)
ELSE IF READY(THUNDER_CLAP) THEN
    RETURN CAST(THUNDER_CLAP)
ELSE IF READY(DEMOLISH_ROAR) THEN
    RETURN CAST(DEMOLISH_ROAR)
ELSE
    RETURN CAST(REVENGE)
END IF
]]

local DRUID_BAL_MD = [[
## SPELL_BOOK (Balance Druid)
SPELL CELESTIAL_ALIGNMENT = ID:194223,102560 | NAME:"Парад планет","Воплощение: избранный Элуны","Celestial Alignment","Incarnation: Chosen of Elune" | CD:120 | ICON:571586
SPELL CONVOKE_THE_SPIRITS = ID:391528,205636 | NAME:"Созыв духов","Сила природы","Convoke the Spirits","Force of Nature" | CD:60 | ICON:3636838
SPELL MOONFIRE = ID:8921 | NAME:"Лунный огонь","Moonfire" | CD:0 | DOTS:true | ICON:136096
SPELL SUNFIRE = ID:93402 | NAME:"Солнечный огонь","Sunfire" | CD:0 | DOTS:true | ICON:236216
SPELL STARSURGE = ID:78674 | NAME:"Звездный поток","Starsurge" | CD:0 | ICON:135730
SPELL STARFALL = ID:191034 | NAME:"Звездопад","Starfall" | CD:0 | ICON:236168
SPELL STARFIRE = ID:194153 | NAME:"Звездный огонь","Starfire" | CD:0 | ICON:135753
SPELL WRATH = ID:190984 | NAME:"Гнев","Wrath" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:136006
SPELL BARKSKIN = ID:22812 | NAME:"Дубовая кожа","Barkskin" | CD:60 | ICON:136097
SPELL RENEWAL = ID:108238 | NAME:"Обновление","Renewal" | CD:90 | ICON:136059
SPELL BEAR_FORM = ID:5487 | NAME:"Облик медведя","Bear Form" | CD:0 | ICON:132276
TRACK_SAVES: BARKSKIN, RENEWAL, BEAR_FORM
TRACK_CDS: CELESTIAL_ALIGNMENT, CONVOKE_THE_SPIRITS, STARSURGE, STARFALL
IF player.hp_percent <= 25 AND READY(RENEWAL) THEN
    RETURN EMERGENCY(RENEWAL)
ELSE IF player.hp_percent <= 25 AND READY(BARKSKIN) THEN
    RETURN EMERGENCY(BARKSKIN)
END IF
IF NOT target.has_dots AND READY(MOONFIRE) THEN
    RETURN CAST(MOONFIRE)
ELSE IF READY(CONVOKE_THE_SPIRITS) THEN
    RETURN CAST(CONVOKE_THE_SPIRITS)
ELSE IF READY(STARSURGE) THEN
    RETURN CAST(STARSURGE)
ELSE IF READY(STARFIRE) THEN
    RETURN CAST(STARFIRE)
ELSE
    RETURN CAST(WRATH)
END IF
]]

local DRUID_FERAL_MD = [[
## SPELL_BOOK (Feral Druid)
SPELL BERSERK = ID:106951,102543 | NAME:"Берсерк","Воплощение: аватара Пеплошкурой","Berserk","Incarnation: Avatar of Ashamane" | CD:120 | ICON:132127
SPELL TIGERS_FURY = ID:5217 | NAME:"Тигриное неистовство","Tiger's Fury" | CD:30 | ICON:132242
SPELL CONVOKE_THE_SPIRITS = ID:391528,391888 | NAME:"Созыв духов","Адаптивный рой","Convoke the Spirits","Adaptive Swarm" | CD:60 | ICON:3636838
SPELL RAKE = ID:1822 | NAME:"Глубокая рана","Rake" | CD:0 | DOTS:true | ICON:132122
SPELL RIP = ID:1079,285381 | NAME:"Разорвать","Первобытный гнев","Rip","Primal Wrath" | CD:0 | DOTS:true | ICON:132152
SPELL FEROCIOUS_BITE = ID:22568 | NAME:"Свирепый укус","Ferocious Bite" | CD:0 | ICON:132187
SPELL BRUTAL_SLASH = ID:202028,106785 | NAME:"Жестокий удар когтями","Размах","Brutal Slash","Swipe" | CD:8 | CHARGES:3 | ICON:132140
SPELL SHRED = ID:5221 | NAME:"Полоснуть","Shred" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:136231
SPELL SURVIVAL_INSTINCTS = ID:61336 | NAME:"Инстинкты выживания","Survival Instincts" | CD:180 | CHARGES:2 | ICON:236169
SPELL BARKSKIN = ID:22812 | NAME:"Дубовая кожа","Barkskin" | CD:60 | ICON:136097
SPELL RENEWAL = ID:108238 | NAME:"Обновление","Renewal" | CD:90 | ICON:136059
TRACK_SAVES: SURVIVAL_INSTINCTS, BARKSKIN, RENEWAL
TRACK_CDS: BERSERK, TIGERS_FURY, CONVOKE_THE_SPIRITS, BRUTAL_SLASH
IF player.hp_percent <= 25 AND READY(SURVIVAL_INSTINCTS) THEN
    RETURN EMERGENCY(SURVIVAL_INSTINCTS)
ELSE IF player.hp_percent <= 25 AND READY(BARKSKIN) THEN
    RETURN EMERGENCY(BARKSKIN)
END IF
IF NOT target.has_dots AND READY(RAKE) THEN
    RETURN CAST(RAKE)
ELSE IF READY(TIGERS_FURY) THEN
    RETURN CAST(TIGERS_FURY)
ELSE IF READY(CONVOKE_THE_SPIRITS) THEN
    RETURN CAST(CONVOKE_THE_SPIRITS)
ELSE IF PROC(FEROCIOUS_BITE) AND READY(FEROCIOUS_BITE) THEN
    RETURN CAST(FEROCIOUS_BITE)
ELSE IF READY(BRUTAL_SLASH) THEN
    RETURN CAST(BRUTAL_SLASH)
ELSE IF READY(RIP) THEN
    RETURN CAST(RIP)
ELSE
    RETURN CAST(SHRED)
END IF
]]

local SHAMAN_ELE_MD = [[
## SPELL_BOOK (Elemental Shaman)
SPELL STORMKEEPER = ID:191634 | NAME:"Хранитель бурь","Stormkeeper" | CD:60 | ICON:839977
SPELL ASCENDANCE = ID:114050,198067 | NAME:"Перерождение","Элементаль огня","Ascendance","Fire Elemental" | CD:150 | ICON:135791
SPELL PRIMORDIAL_WAVE = ID:375982,188389 | NAME:"Первозданная волна","Огненный шок","Primordial Wave","Flame Shock" | CD:30 | DOTS:true | ICON:3578231
SPELL LAVA_BURST = ID:51505 | NAME:"Выброс лавы","Lava Burst" | CD:8 | CHARGES:2 | ICON:237582
SPELL EARTH_SHOCK = ID:8042,117014,61882 | NAME:"Земной шок","Удар стихий","Землетрясение","Earth Shock","Elemental Blast","Earthquake" | CD:0 | ICON:136026
SPELL CHAIN_LIGHTNING = ID:188443 | NAME:"Цепная молния","Chain Lightning" | CD:0 | ICON:136015
SPELL LIGHTNING_BOLT = ID:188196 | NAME:"Молния","Lightning Bolt" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:136048
SPELL ASTRAL_SHIFT = ID:108271 | NAME:"Астральный сдвиг","Astral Shift" | CD:120 | ICON:538565
SPELL EARTH_ELEMENTAL = ID:198103 | NAME:"Элементаль земли","Earth Elemental" | CD:300 | ICON:136024
SPELL NATURES_SWIFTNESS = ID:378081,108281 | NAME:"Природная стремительность","Наставления предков","Nature's Swiftness","Ancestral Guidance" | CD:60 | ICON:136076
TRACK_SAVES: ASTRAL_SHIFT, EARTH_ELEMENTAL, NATURES_SWIFTNESS
TRACK_CDS: ASCENDANCE, STORMKEEPER, PRIMORDIAL_WAVE, LAVA_BURST
IF player.hp_percent <= 25 AND READY(ASTRAL_SHIFT) THEN
    RETURN EMERGENCY(ASTRAL_SHIFT)
END IF
IF NOT target.has_dots AND READY(PRIMORDIAL_WAVE) THEN
    RETURN CAST(PRIMORDIAL_WAVE)
ELSE IF READY(STORMKEEPER) THEN
    RETURN CAST(STORMKEEPER)
ELSE IF PROC(LAVA_BURST) AND READY(LAVA_BURST) THEN
    RETURN CAST(LAVA_BURST)
ELSE IF READY(EARTH_SHOCK) THEN
    RETURN CAST(EARTH_SHOCK)
ELSE IF READY(LAVA_BURST) THEN
    RETURN CAST(LAVA_BURST)
ELSE
    RETURN CAST(LIGHTNING_BOLT)
END IF
]]

local SHAMAN_ENH_MD = [[
## SPELL_BOOK (Enhancement Shaman)
SPELL FERAL_SPIRIT = ID:51533 | NAME:"Дух дикого зверя","Feral Spirit" | CD:90 | ICON:237577
SPELL DOOM_WINDS = ID:384352,114051 | NAME:"Ветра рока","Перерождение","Doom Winds","Ascendance" | CD:60 | ICON:136022
SPELL PRIMORDIAL_WAVE = ID:375982,188389 | NAME:"Первозданная волна","Огненный шок","Primordial Wave","Flame Shock" | CD:30 | DOTS:true | ICON:3578231
SPELL TEMPEST_LB = ID:188196,452201,188443 | NAME:"Молния","Буря","Цепная молния","Lightning Bolt","Tempest","Chain Lightning" | CD:0 | ICON:136048
SPELL STORMSTRIKE = ID:17364 | NAME:"Удар бури","Stormstrike" | CD:7.5 | ICON:132314
SPELL LAVA_LASH = ID:60103 | NAME:"Вскипание лавы","Lava Lash" | CD:10 | ICON:236289
SPELL ICE_STRIKE = ID:342240,187874 | NAME:"Ледяной клинок","Сокрушающая молния","Ice Strike","Crash Lightning" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:462327
SPELL ASTRAL_SHIFT = ID:108271 | NAME:"Астральный сдвиг","Astral Shift" | CD:120 | ICON:538565
SPELL EARTH_ELEMENTAL = ID:198103 | NAME:"Элементаль земли","Earth Elemental" | CD:300 | ICON:136024
TRACK_SAVES: ASTRAL_SHIFT, EARTH_ELEMENTAL
TRACK_CDS: FERAL_SPIRIT, DOOM_WINDS, PRIMORDIAL_WAVE, STORMSTRIKE
IF player.hp_percent <= 25 AND READY(ASTRAL_SHIFT) THEN
    RETURN EMERGENCY(ASTRAL_SHIFT)
END IF
IF PROC(TEMPEST_LB) AND READY(TEMPEST_LB) THEN
    RETURN CAST(TEMPEST_LB)
ELSE IF READY(FERAL_SPIRIT) THEN
    RETURN CAST(FERAL_SPIRIT)
ELSE IF READY(DOOM_WINDS) THEN
    RETURN CAST(DOOM_WINDS)
ELSE IF READY(PRIMORDIAL_WAVE) THEN
    RETURN CAST(PRIMORDIAL_WAVE)
ELSE IF READY(STORMSTRIKE) THEN
    RETURN CAST(STORMSTRIKE)
ELSE IF READY(LAVA_LASH) THEN
    RETURN CAST(LAVA_LASH)
ELSE
    RETURN CAST(ICE_STRIKE)
END IF
]]

local DK_UNHOLY_MD = [[
## SPELL_BOOK (Unholy Death Knight)
SPELL DARK_TRANSFORMATION = ID:63560 | NAME:"Темное превращение","Dark Transformation" | CD:45 | ICON:237524
SPELL APOCALYPSE = ID:275699 | NAME:"Апокалипсис","Apocalypse" | CD:45 | ICON:1392565
SPELL UNHOLY_ASSAULT = ID:207289,455395 | NAME:"Нечестивый натиск","Воскрешение мерзости","Unholy Assault","Raise Abomination" | CD:90 | ICON:236148
SPELL OUTBREAK = ID:77575 | NAME:"Вспышка болезни","Outbreak" | CD:0 | DOTS:true | ICON:237514
SPELL SOUL_REAPER = ID:343294 | NAME:"Жнец душ","Soul Reaper" | CD:6 | EXECUTE:true | ICON:606552
SPELL FESTERMIGHT = ID:85948 | NAME:"Разложение","Festering Strike" | CD:0 | ICON:237517
SPELL SCOURGE_STRIKE = ID:55090,207311 | NAME:"Удар Плети","Стискивающие тени","Scourge Strike","Clawing Shadows" | CD:0 | ICON:135776
SPELL DEATH_COIL = ID:47541,207317 | NAME:"Лик смерти","Эпидемия","Death Coil","Epidemic" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:136145
SPELL ANTI_MAGIC_SHELL = ID:48707 | NAME:"Антимагический панцирь","Anti-Magic Shell" | CD:60 | ICON:136120
SPELL ICEBOUND_FORTITUDE = ID:48792 | NAME:"Незыблемость льда","Icebound Fortitude" | CD:120 | ICON:237525
SPELL LICHBORNE = ID:49039 | NAME:"Перерождение","Lichborne" | CD:120 | ICON:136187
SPELL DEATH_STRIKE = ID:49998 | NAME:"Удар смерти","Death Strike" | CD:0 | ICON:237517
TRACK_SAVES: ANTI_MAGIC_SHELL, ICEBOUND_FORTITUDE, LICHBORNE, DEATH_STRIKE
TRACK_CDS: DARK_TRANSFORMATION, APOCALYPSE, UNHOLY_ASSAULT, SOUL_REAPER
IF player.hp_percent <= 25 AND READY(ICEBOUND_FORTITUDE) THEN
    RETURN EMERGENCY(ICEBOUND_FORTITUDE)
ELSE IF player.hp_percent <= 25 AND READY(DEATH_STRIKE) THEN
    RETURN EMERGENCY(DEATH_STRIKE)
END IF
IF NOT target.has_dots AND READY(OUTBREAK) THEN
    RETURN CAST(OUTBREAK)
ELSE IF USABLE(SOUL_REAPER) AND READY(SOUL_REAPER) THEN
    RETURN CAST(SOUL_REAPER)
ELSE IF READY(DARK_TRANSFORMATION) THEN
    RETURN CAST(DARK_TRANSFORMATION)
ELSE IF READY(APOCALYPSE) THEN
    RETURN CAST(APOCALYPSE)
ELSE IF READY(FESTERMIGHT) THEN
    RETURN CAST(FESTERMIGHT)
ELSE IF READY(SCOURGE_STRIKE) THEN
    RETURN CAST(SCOURGE_STRIKE)
ELSE
    RETURN CAST(DEATH_COIL)
END IF
]]

local DK_FROST_MD = [[
## SPELL_BOOK (Frost Death Knight)
SPELL PILLAR_OF_FROST = ID:51271 | NAME:"Ледяной столп","Pillar of Frost" | CD:45 | ICON:458718
SPELL EMPOWER_RUNE_WEAPON = ID:47568 | NAME:"Усиление рунического оружия","Empower Rune Weapon" | CD:120 | ICON:135372
SPELL REMORSELESS_WINTER = ID:196770 | NAME:"Беспощадность зимы","Remorseless Winter" | CD:20 | ICON:538770
SPELL REAPERS_MARK = ID:439843,279302 | NAME:"Метка жнеца","Вызывающий дрожь взрыв","Reaper's Mark","Frostwyrm's Fury" | CD:45 | ICON:136188
SPELL OBLITERATE = ID:49020 | NAME:"Уничтожение","Obliterate" | CD:0 | ICON:135771
SPELL HOWLING_BLAST = ID:49184 | NAME:"Воющий ветер","Howling Blast" | CD:0 | DOTS:true | ICON:237530
SPELL FROST_STRIKE = ID:49143,207230 | NAME:"Ледяной удар","Ледяная коса","Frost Strike","Frostscythe" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:237520
SPELL ANTI_MAGIC_SHELL = ID:48707 | NAME:"Антимагический панцирь","Anti-Magic Shell" | CD:60 | ICON:136120
SPELL ICEBOUND_FORTITUDE = ID:48792 | NAME:"Незыблемость льда","Icebound Fortitude" | CD:120 | ICON:237525
SPELL LICHBORNE = ID:49039 | NAME:"Перерождение","Lichborne" | CD:120 | ICON:136187
SPELL DEATH_STRIKE = ID:49998 | NAME:"Удар смерти","Death Strike" | CD:0 | ICON:237517
TRACK_SAVES: ANTI_MAGIC_SHELL, ICEBOUND_FORTITUDE, LICHBORNE, DEATH_STRIKE
TRACK_CDS: PILLAR_OF_FROST, EMPOWER_RUNE_WEAPON, REAPERS_MARK, REMORSELESS_WINTER
IF player.hp_percent <= 25 AND READY(ICEBOUND_FORTITUDE) THEN
    RETURN EMERGENCY(ICEBOUND_FORTITUDE)
ELSE IF player.hp_percent <= 25 AND READY(DEATH_STRIKE) THEN
    RETURN EMERGENCY(DEATH_STRIKE)
END IF
IF PROC(HOWLING_BLAST) AND READY(HOWLING_BLAST) THEN
    RETURN CAST(HOWLING_BLAST)
ELSE IF READY(REMORSELESS_WINTER) THEN
    RETURN CAST(REMORSELESS_WINTER)
ELSE IF READY(PILLAR_OF_FROST) THEN
    RETURN CAST(PILLAR_OF_FROST)
ELSE IF READY(REAPERS_MARK) THEN
    RETURN CAST(REAPERS_MARK)
ELSE IF READY(OBLITERATE) THEN
    RETURN CAST(OBLITERATE)
ELSE
    RETURN CAST(FROST_STRIKE)
END IF
]]

local DK_BLOOD_MD = [[
## SPELL_BOOK (Blood Death Knight)
SPELL DANCING_RUNE_WEAPON = ID:49028 | NAME:"Танцующее руническое оружие","Dancing Rune Weapon" | CD:120 | ICON:135277
SPELL ABOMINATION_LIMB = ID:383269,439843 | NAME:"Рука поганища","Метка жнеца","Abomination Limb","Reaper's Mark" | CD:120 | ICON:3578196
SPELL MARROWREND = ID:195182 | NAME:"Дробление хребта","Marrowrend" | CD:0 | ICON:1380368
SPELL BLOOD_BOIL = ID:50842 | NAME:"Вскипание крови","Blood Boil" | CD:7.5 | CHARGES:2 | DOTS:true | ICON:237513
SPELL DEATH_AND_DECAY = ID:43265 | NAME:"Смерть и разложение","Death and Decay" | CD:30 | CHARGES:2 | ICON:136144
SPELL DEATH_STRIKE = ID:49998 | NAME:"Удар смерти","Death Strike" | CD:0 | ICON:237517
SPELL HEART_STRIKE = ID:206930 | NAME:"Удар в сердце","Heart Strike" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:135675
SPELL VAMPIRIC_BLOOD = ID:55233 | NAME:"Кровь вампира","Vampiric Blood" | CD:90 | ICON:136168
SPELL ICEBOUND_FORTITUDE = ID:48792 | NAME:"Незыблемость льда","Icebound Fortitude" | CD:120 | ICON:237525
SPELL ANTI_MAGIC_SHELL = ID:48707 | NAME:"Антимагический панцирь","Anti-Magic Shell" | CD:60 | ICON:136120
SPELL LICHBORNE = ID:49039 | NAME:"Перерождение","Lichborne" | CD:120 | ICON:136187
TRACK_SAVES: VAMPIRIC_BLOOD, ICEBOUND_FORTITUDE, ANTI_MAGIC_SHELL, LICHBORNE
TRACK_CDS: DANCING_RUNE_WEAPON, ABOMINATION_LIMB, DEATH_AND_DECAY, BLOOD_BOIL
IF player.hp_percent <= 30 AND READY(VAMPIRIC_BLOOD) THEN
    RETURN EMERGENCY(VAMPIRIC_BLOOD)
ELSE IF player.hp_percent <= 25 AND READY(DEATH_STRIKE) THEN
    RETURN EMERGENCY(DEATH_STRIKE)
END IF
IF READY(BLOOD_BOIL) THEN
    RETURN CAST(BLOOD_BOIL)
ELSE IF READY(DEATH_AND_DECAY) THEN
    RETURN CAST(DEATH_AND_DECAY)
ELSE IF READY(MARROWREND) THEN
    RETURN CAST(MARROWREND)
ELSE IF READY(DEATH_STRIKE) THEN
    RETURN CAST(DEATH_STRIKE)
ELSE
    RETURN CAST(HEART_STRIKE)
END IF
]]

local MONK_WW_MD = [[
## SPELL_BOOK (Windwalker Monk)
SPELL STORM_EARTH_FIRE = ID:137639 | NAME:"Буря, земля и огонь","Storm, Earth, and Fire" | CD:90 | CHARGES:2 | ICON:136038
SPELL INVOKE_XUEN = ID:123904 | NAME:"Призыв Сюэня, Белого Тигра","Invoke Xuen, the White Tiger" | CD:120 | ICON:620832
SPELL STRIKE_OF_THE_WINDLORD = ID:392983 | NAME:"Удар Владыки Ветра","Strike of the Windlord" | CD:30 | ICON:1381297
SPELL FISTS_OF_FURY = ID:113656 | NAME:"Неистовые кулаки","Fists of Fury" | CD:24 | LOCK_CHANNEL:true | ICON:627608
SPELL WHIRLING_DRAGON_PUNCH = ID:152175 | NAME:"Удар крутящегося дракона","Whirling Dragon Punch" | CD:24 | ICON:988197
SPELL RISING_SUN_KICK = ID:107428 | NAME:"Удар восходящего солнца","Rising Sun Kick" | CD:10 | ICON:606551
SPELL TOUCH_OF_DEATH = ID:322109 | NAME:"Смертельное касание","Touch of Death" | CD:180 | EXECUTE:true | ICON:606543
SPELL BLACKOUT_KICK = ID:100784,101546 | NAME:"Нокаутирующий удар","Танцующий журавль","Blackout Kick","Spinning Crane Kick" | CD:3 | ICON:574575
SPELL TIGER_PALM = ID:100780 | NAME:"Лапа тигра","Tiger Palm" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:606552
SPELL TOUCH_OF_KARMA = ID:122470 | NAME:"Закон кармы","Touch of Karma" | CD:90 | ICON:651728
SPELL FORTIFYING_BREW = ID:115203 | NAME:"Укрепляющий отвар","Fortifying Brew" | CD:120 | ICON:436270
SPELL DIFFUSE_MAGIC = ID:122783,122278 | NAME:"Распыление магии","Смягчение удара","Diffuse Magic","Dampen Harm" | CD:90 | ICON:775460
TRACK_SAVES: TOUCH_OF_KARMA, FORTIFYING_BREW, DIFFUSE_MAGIC
TRACK_CDS: INVOKE_XUEN, STORM_EARTH_FIRE, STRIKE_OF_THE_WINDLORD, FISTS_OF_FURY
IF player.hp_percent <= 25 AND READY(TOUCH_OF_KARMA) THEN
    RETURN EMERGENCY(TOUCH_OF_KARMA)
ELSE IF player.hp_percent <= 25 AND READY(FORTIFYING_BREW) THEN
    RETURN EMERGENCY(FORTIFYING_BREW)
END IF
IF USABLE(TOUCH_OF_DEATH) AND READY(TOUCH_OF_DEATH) THEN
    RETURN CAST(TOUCH_OF_DEATH)
ELSE IF READY(STRIKE_OF_THE_WINDLORD) THEN
    RETURN CAST(STRIKE_OF_THE_WINDLORD)
ELSE IF READY(FISTS_OF_FURY) THEN
    RETURN CAST(FISTS_OF_FURY)
ELSE IF READY(RISING_SUN_KICK) THEN
    RETURN CAST(RISING_SUN_KICK)
ELSE IF READY(WHIRLING_DRAGON_PUNCH) THEN
    RETURN CAST(WHIRLING_DRAGON_PUNCH)
ELSE IF READY(BLACKOUT_KICK) THEN
    RETURN CAST(BLACKOUT_KICK)
ELSE
    RETURN CAST(TIGER_PALM)
END IF
]]

local MONK_BM_MD = [[
## SPELL_BOOK (Brewmaster Monk)
SPELL EXPLODING_KEG = ID:325153,387184 | NAME:"Взрывающийся бочонок","Оружие ордена","Exploding Keg","Weapons of Order" | CD:60 | ICON:1247262
SPELL KEG_SMASH = ID:121253 | NAME:"Удар бочонком","Keg Smash" | CD:8 | CHARGES:2 | ICON:629483
SPELL BLACKOUT_KICK = ID:205523,100784 | NAME:"Нокаутирующий удар","Blackout Kick" | CD:4 | ICON:574575
SPELL BREATH_OF_FIRE = ID:115181 | NAME:"Пламенное дыхание","Breath of Fire" | CD:15 | DOTS:true | ICON:615339
SPELL RISING_SUN_KICK = ID:107428 | NAME:"Удар восходящего солнца","Rising Sun Kick" | CD:10 | ICON:606551
SPELL TIGER_PALM = ID:100780,322729 | NAME:"Лапа тигра","Танцующий журавль","Tiger Palm","Spinning Crane Kick" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:606552
SPELL PURIFYING_BREW = ID:119582 | NAME:"Очищающий отвар","Purifying Brew" | CD:15 | CHARGES:2 | ICON:132794
SPELL CELESTIAL_BREW = ID:322507 | NAME:"Целебный отвар","Celestial Brew" | CD:45 | ICON:1360979
SPELL FORTIFYING_BREW = ID:115203 | NAME:"Укрепляющий отвар","Fortifying Brew" | CD:180 | ICON:436270
TRACK_SAVES: FORTIFYING_BREW, CELESTIAL_BREW, PURIFYING_BREW
TRACK_CDS: EXPLODING_KEG, KEG_SMASH, BREATH_OF_FIRE, RISING_SUN_KICK
IF player.hp_percent <= 25 AND READY(CELESTIAL_BREW) THEN
    RETURN EMERGENCY(CELESTIAL_BREW)
ELSE IF player.hp_percent <= 25 AND READY(FORTIFYING_BREW) THEN
    RETURN EMERGENCY(FORTIFYING_BREW)
END IF
IF READY(KEG_SMASH) THEN
    RETURN CAST(KEG_SMASH)
ELSE IF READY(BLACKOUT_KICK) THEN
    RETURN CAST(BLACKOUT_KICK)
ELSE IF READY(BREATH_OF_FIRE) THEN
    RETURN CAST(BREATH_OF_FIRE)
ELSE IF READY(RISING_SUN_KICK) THEN
    RETURN CAST(RISING_SUN_KICK)
ELSE IF READY(EXPLODING_KEG) THEN
    RETURN CAST(EXPLODING_KEG)
ELSE
    RETURN CAST(TIGER_PALM)
END IF
]]

local DH_HAVOC_MD = [[
## SPELL_BOOK (Havoc Demon Hunter)
SPELL METAMORPHOSIS = ID:191427 | NAME:"Метаморфоза","Metamorphosis" | CD:180 | ICON:1247264
SPELL THE_HUNT = ID:370965 | NAME:"Охота","The Hunt" | CD:90 | ICON:3578201
SPELL ESSENCE_BREAK = ID:258860 | NAME:"Сокрушение сущности","Essence Break" | CD:40 | ICON:136189
SPELL EYE_BEAM = ID:198013 | NAME:"Пронзающий взгляд","Eye Beam" | CD:40 | LOCK_CHANNEL:true | ICON:1305156
SPELL IMMOLATION_AURA = ID:258920 | NAME:"Обжигающий жар","Immolation Aura" | CD:30 | CHARGES:2 | ICON:1344650
SPELL BLADE_DANCE = ID:188499,210152 | NAME:"Танец клинков","Смертоносный взмах","Blade Dance","Death Sweep" | CD:9 | ICON:1305149
SPELL SIGIL_OF_FLAME = ID:204596 | NAME:"Печать огня","Sigil of Flame" | CD:30 | ICON:1418287
SPELL CHAOS_STRIKE = ID:162794,201427 | NAME:"Удар Хаоса","Аннигиляция","Chaos Strike","Annihilation" | CD:0 | ICON:1305152
SPELL FELBLADE = ID:232893,195072,162243 | NAME:"Клинок Скверны","Рывок Скверны","Укус демона","Felblade","Fel Rush","Demon's Bite" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:1344648
SPELL BLUR = ID:198589 | NAME:"Затуманивание","Blur" | CD:60 | ICON:1305150
SPELL NETHERWALK = ID:196555 | NAME:"Путь Пустоты","Netherwalk" | CD:180 | ICON:1344653
SPELL DARKNESS = ID:196718 | NAME:"Мрак","Darkness" | CD:180 | ICON:1305154
TRACK_SAVES: BLUR, NETHERWALK, DARKNESS
TRACK_CDS: METAMORPHOSIS, THE_HUNT, EYE_BEAM, ESSENCE_BREAK
IF player.hp_percent <= 25 AND READY(BLUR) THEN
    RETURN EMERGENCY(BLUR)
ELSE IF player.hp_percent <= 25 AND READY(NETHERWALK) THEN
    RETURN EMERGENCY(NETHERWALK)
END IF
IF READY(EYE_BEAM) THEN
    RETURN CAST(EYE_BEAM)
ELSE IF READY(ESSENCE_BREAK) THEN
    RETURN CAST(ESSENCE_BREAK)
ELSE IF READY(BLADE_DANCE) THEN
    RETURN CAST(BLADE_DANCE)
ELSE IF READY(THE_HUNT) THEN
    RETURN CAST(THE_HUNT)
ELSE IF READY(IMMOLATION_AURA) THEN
    RETURN CAST(IMMOLATION_AURA)
ELSE IF READY(SIGIL_OF_FLAME) THEN
    RETURN CAST(SIGIL_OF_FLAME)
ELSE IF READY(CHAOS_STRIKE) THEN
    RETURN CAST(CHAOS_STRIKE)
ELSE
    RETURN CAST(FELBLADE)
END IF
]]

local DH_VENG_MD = [[
## SPELL_BOOK (Vengeance Demon Hunter)
SPELL FIERY_BRAND = ID:204021 | NAME:"Огненное клеймо","Fiery Brand" | CD:60 | ICON:1344647
SPELL FEL_DEVASTATION = ID:212084 | NAME:"Опустошение Скверны","Fel Devastation" | CD:40 | LOCK_CHANNEL:true | ICON:1450243
SPELL IMMOLATION_AURA = ID:258920 | NAME:"Обжигающий жар","Immolation Aura" | CD:15 | ICON:1344650
SPELL SIGIL_OF_FLAME = ID:204596 | NAME:"Печать огня","Sigil of Flame" | CD:30 | CHARGES:2 | ICON:1418287
SPELL SPIRIT_BOMB = ID:247454,228477 | NAME:"Духовная бомба","Раскалывание душ","Spirit Bomb","Soul Cleave" | CD:0 | ICON:1035052
SPELL FRACTURE = ID:263642,203782 | NAME:"Разлом","Иссечение","Fracture","Shear" | CD:4.5 | CHARGES:2 | FILLER_INTERRUPTIBLE:true | ICON:1388001
SPELL DEMON_SPIKES = ID:203720 | NAME:"Демонические шипы","Demon Spikes" | CD:20 | CHARGES:2 | ICON:1344645
SPELL METAMORPHOSIS = ID:187827 | NAME:"Метаморфоза","Metamorphosis" | CD:180 | ICON:1247265
TRACK_SAVES: METAMORPHOSIS, FIERY_BRAND, DEMON_SPIKES
TRACK_CDS: FEL_DEVASTATION, SIGIL_OF_FLAME, IMMOLATION_AURA, SPIRIT_BOMB
IF player.hp_percent <= 25 AND READY(METAMORPHOSIS) THEN
    RETURN EMERGENCY(METAMORPHOSIS)
ELSE IF player.hp_percent <= 35 AND READY(DEMON_SPIKES) THEN
    RETURN EMERGENCY(DEMON_SPIKES)
END IF
IF READY(FEL_DEVASTATION) THEN
    RETURN CAST(FEL_DEVASTATION)
ELSE IF READY(IMMOLATION_AURA) THEN
    RETURN CAST(IMMOLATION_AURA)
ELSE IF READY(SIGIL_OF_FLAME) THEN
    RETURN CAST(SIGIL_OF_FLAME)
ELSE IF READY(SPIRIT_BOMB) THEN
    RETURN CAST(SPIRIT_BOMB)
ELSE
    RETURN CAST(FRACTURE)
END IF
]]

local EVOKER_DEV_MD = [[
## SPELL_BOOK (Devastation Evoker)
SPELL DRAGONRAGE = ID:375087 | NAME:"Ярость дракона","Dragonrage" | CD:120 | ICON:4622455
SPELL FIRE_BREATH = ID:357208,382266 | NAME:"Огненное дыхание","Fire Breath" | CD:30 | ICON:4622458
SPELL ETERNITY_SURGE = ID:359073,382411 | NAME:"Выброс вечности","Eternity Surge" | CD:30 | ICON:4622456
SPELL SHATTERING_STAR = ID:370452 | NAME:"Раскалывающая звезда","Shattering Star" | CD:20 | ICON:4622473
SPELL DISINTEGRATE = ID:356995,357211 | NAME:"Дезинтеграция","Погребальный костер","Disintegrate","Pyre" | CD:0 | LOCK_CHANNEL:true | ICON:4622453
SPELL LIVING_FLAME = ID:361469,362969 | NAME:"Живое пламя","Лазурный удар","Living Flame","Azure Strike" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:4622464
SPELL OBSIDIAN_SCALES = ID:363916 | NAME:"Обсидиановая чешуя","Obsidian Scales" | CD:90 | CHARGES:2 | ICON:4622468
SPELL RENEWING_BLAZE = ID:374348 | NAME:"Обновляющее пламя","Renewing Blaze" | CD:90 | ICON:4622471
SPELL HOVER = ID:358267 | NAME:"Парение","Hover" | CD:35 | CHARGES:2 | ICON:4622462
TRACK_SAVES: OBSIDIAN_SCALES, RENEWING_BLAZE, HOVER
TRACK_CDS: DRAGONRAGE, FIRE_BREATH, ETERNITY_SURGE, SHATTERING_STAR
IF player.hp_percent <= 25 AND READY(RENEWING_BLAZE) THEN
    RETURN EMERGENCY(RENEWING_BLAZE)
ELSE IF player.hp_percent <= 25 AND READY(OBSIDIAN_SCALES) THEN
    RETURN EMERGENCY(OBSIDIAN_SCALES)
END IF
IF READY(DRAGONRAGE) THEN
    RETURN CAST(DRAGONRAGE)
ELSE IF READY(FIRE_BREATH) THEN
    RETURN CAST(FIRE_BREATH)
ELSE IF READY(ETERNITY_SURGE) THEN
    RETURN CAST(ETERNITY_SURGE)
ELSE IF READY(SHATTERING_STAR) THEN
    RETURN CAST(SHATTERING_STAR)
ELSE IF READY(DISINTEGRATE) THEN
    RETURN CAST(DISINTEGRATE)
ELSE
    RETURN CAST(LIVING_FLAME)
END IF
]]

local EVOKER_AUG_MD = [[
## SPELL_BOOK (Augmentation Evoker)
SPELL BREATH_OF_EONS = ID:403631 | NAME:"Дыхание эонов","Breath of Eons" | CD:120 | ICON:5199621
SPELL EBON_MIGHT = ID:395152 | NAME:"Черная мощь","Ebon Might" | CD:30 | ICON:5199625
SPELL PRESCIENCE = ID:409311 | NAME:"Предвидение","Prescience" | CD:12 | CHARGES:2 | ICON:5199639
SPELL FIRE_BREATH = ID:357208,382266 | NAME:"Огненное дыхание","Fire Breath" | CD:30 | ICON:4622458
SPELL UPHEAVAL = ID:396286,408092 | NAME:"Сдвиг земли","Upheaval" | CD:40 | ICON:5199646
SPELL ERUPTION = ID:395160 | NAME:"Извержение","Eruption" | CD:0 | ICON:5199626
SPELL LIVING_FLAME = ID:361469,362969 | NAME:"Живое пламя","Лазурный удар","Living Flame","Azure Strike" | CD:0 | FILLER_INTERRUPTIBLE:true | ICON:4622464
SPELL OBSIDIAN_SCALES = ID:363916 | NAME:"Обсидиановая чешуя","Obsidian Scales" | CD:90 | CHARGES:2 | ICON:4622468
SPELL RENEWING_BLAZE = ID:374348 | NAME:"Обновляющее пламя","Renewing Blaze" | CD:90 | ICON:4622471
SPELL HOVER = ID:358267 | NAME:"Парение","Hover" | CD:35 | CHARGES:2 | ICON:4622462
TRACK_SAVES: OBSIDIAN_SCALES, RENEWING_BLAZE, HOVER
TRACK_CDS: BREATH_OF_EONS, EBON_MIGHT, FIRE_BREATH, UPHEAVAL
IF player.hp_percent <= 25 AND READY(RENEWING_BLAZE) THEN
    RETURN EMERGENCY(RENEWING_BLAZE)
ELSE IF player.hp_percent <= 25 AND READY(OBSIDIAN_SCALES) THEN
    RETURN EMERGENCY(OBSIDIAN_SCALES)
END IF
IF READY(PRESCIENCE) THEN
    RETURN CAST(PRESCIENCE)
ELSE IF READY(EBON_MIGHT) THEN
    RETURN CAST(EBON_MIGHT)
ELSE IF READY(FIRE_BREATH) THEN
    RETURN CAST(FIRE_BREATH)
ELSE IF READY(UPHEAVAL) THEN
    RETURN CAST(UPHEAVAL)
ELSE IF READY(ERUPTION) THEN
    RETURN CAST(ERUPTION)
ELSE
    RETURN CAST(LIVING_FLAME)
END IF
]]

local SPEC_PRESET_BODY = {
  MAGE_01_ARCANE_PVE   = MAGE_ARCANE_MD,
  MAGE_02_ARCANE_BOSS  = MAGE_ARCANE_MD,
  MAGE_03_FIRE_PVE     = MAGE_FIRE_MD,
  MAGE_04_FROST_PVE    = MAGE_FROST_MD,
  MAGE_05_FROST_PVP    = MAGE_FROST_ST_MD,
  WARLOCK_01_AFF_PVE   = WARLOCK_AFF_MD,
  WARLOCK_02_AFF_BOSS  = WARLOCK_AFF_MD,
  WARLOCK_03_DEMO_PVE  = WARLOCK_DEMO_MD,
  WARLOCK_04_DESTRO_PVE= WARLOCK_DESTRO_MD,
  WARLOCK_05_DESTRO_PVP= WARLOCK_DESTRO_MD,
  PALADIN_01_RET_PVE   = PALADIN_RET_MD,
  PALADIN_02_RET_BOSS  = PALADIN_RET_MD,
  PALADIN_03_RET_PVP   = PALADIN_RET_MD,
  PALADIN_04_PROT_PVE  = PALADIN_PROT_MD,
  HUNTER_01_BM_PVE     = HUNTER_BM_MD,
  HUNTER_02_BM_BOSS    = HUNTER_BM_MD,
  HUNTER_03_MM_PVE     = HUNTER_MM_MD,
  HUNTER_04_SURV_PVP   = HUNTER_SURV_MD,
  ROGUE_01_ASSA_PVE    = ROGUE_ASSA_MD,
  ROGUE_02_OUTLAW_PVE  = ROGUE_OUTLAW_MD,
  ROGUE_03_SUB_BOSS    = ROGUE_SUB_MD,
  ROGUE_04_SUB_PVP     = ROGUE_SUB_MD,
  WARRIOR_01_FURY_PVE  = WARRIOR_FURY_MD,
  WARRIOR_02_ARGS_BOSS = WARRIOR_ARMS_MD,
  WARRIOR_03_ARMS_PVP  = WARRIOR_ARMS_MD,
  WARRIOR_04_PROT_PVE  = WARRIOR_PROT_MD,
  DRUID_01_BAL_PVE     = DRUID_BAL_MD,
  DRUID_02_BAL_BOSS    = DRUID_BAL_MD,
  DRUID_03_FERAL_PVE   = DRUID_FERAL_MD,
  DRUID_04_FERAL_PVP   = DRUID_FERAL_MD,
  SHAMAN_01_ELE_PVE    = SHAMAN_ELE_MD,
  SHAMAN_02_ELE_BOSS   = SHAMAN_ELE_MD,
  SHAMAN_03_ENH_PVE    = SHAMAN_ENH_MD,
  SHAMAN_04_ENH_PVP    = SHAMAN_ENH_MD,
  DK_01_UNHOLY_PVE     = DK_UNHOLY_MD,
  DK_02_FROST_PVE      = DK_FROST_MD,
  DK_03_BLOOD_PVE      = DK_BLOOD_MD,
  MONK_01_WW_PVE       = MONK_WW_MD,
  MONK_02_WW_PVP       = MONK_WW_MD,
  MONK_03_BM_PVE       = MONK_BM_MD,
  DH_01_HAVOC_PVE      = DH_HAVOC_MD,
  DH_02_HAVOC_PVP      = DH_HAVOC_MD,
  DH_03_VENG_PVE       = DH_VENG_MD,
  EVOKER_01_DEV_PVE    = EVOKER_DEV_MD,
  EVOKER_02_AUG_PVE    = EVOKER_AUG_MD,
}

local OTHER_CLASS_PRESETS = {
  { "MAGE_01_ARCANE_PVE", "MAGE", "11. Маг: Тайная магия — PvE (Icy Veins)", "PVE" },
  { "MAGE_02_ARCANE_BOSS", "MAGE", "12. Маг: Тайная магия — Босс СТ", "BOSS" },
  { "MAGE_03_FIRE_PVE", "MAGE", "13. Маг: Огонь — PvE / Мифик+", "PVE" },
  { "MAGE_04_FROST_PVE", "MAGE", "14. Маг: Лёд — PvE Cleave (Midnight)", "PVE" },
  { "MAGE_05_FROST_PVP", "MAGE", "15. Маг: Лёд — СТ / Босс / PvP (Midnight)", "PVP" },

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

for _, info in ipairs(OTHER_CLASS_PRESETS) do
  local id, cls, title, mode = info[1], info[2], info[3], info[4]
  local specTag = id:match("^[^_]+_%d+_([^_]+)") or mode
  local headerMD = string.format(
    "# PROFILE: %s\n# CLASS: %s\n# SPEC: %s\n# MODE: %s\n",
    title, cls, specTag, mode
  )
  local bodyMD = SPEC_PRESET_BODY[id] or WARRIOR_ARMS_MD
  RegisterPreset(id, cls, title, mode, headerMD .. bodyMD)
end

-- Legacy compatibility map for PVE / BOSS / PVP quick mode keys
SpArc.DefaultMarkdownProfiles = {
  ["PVE"]  = SpArc.BuiltInPresets["PRIEST_01_SHADOW_PVE"].md,
  ["BOSS"] = SpArc.BuiltInPresets["PRIEST_02_SHADOW_BOSS"].md,
  ["PVP"]  = SpArc.BuiltInPresets["PRIEST_03_SHADOW_PVP"].md,
}
