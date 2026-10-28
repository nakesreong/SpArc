---------------------------------------------------------------------------------------
--  SpArc/Presets.lua — Bilingual Localization System (EN / RU), AI Prompt Templates
--                      & 4 Active Class Rotation Profiles (Shadow Priest, Frost Mage,
--                      Assassination Rogue, Arms Warrior) with AoE & Misc Support.
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

    TAB_1 = "1. Presets (4)",
    TAB_2 = "2. .MD Editor & AI",
    TAB_3 = "3. Visual & HUD",
    TAB_4 = "4. Telemetry / Debug",

    NAV_1 = "Rotation Presets",
    NAV_2 = ".MD Code & AI",
    NAV_3 = "Rotation Arc",
    NAV_4 = "Saves & CDs Wings",
    NAV_5 = "Castbar & Resource",
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

    M5_TITLE = "Dual-Direction Castbar & Secondary Resource Tracker",
    M5_GRP_SIZE = "Castbar Dimensions & Offset",
    M5_GRP_CLIP = "Channeled Filler Clipping Alert",
    M5_GRP_RES = "Secondary Resource Tracker Under Castbar (Insanity / Combo Points)",
    CK_RES_ENABLE = "Show Secondary Class Resource Tracker under Castbar (Insanity, Combo Points, etc.)",
    CK_RES_ALWAYS = "Always show Resource Bar even out of combat & with no target",
    SL_RES_WIDTH = "Resource Bar Width (px)",
    SL_RES_HEIGHT = "Resource Bar Height (px)",
    SL_RES_OFFSET_X = "Resource Bar Horizontal Offset X (px)",
    SL_RES_OFFSET_Y = "Resource Bar Vertical Offset Y (px)",
    SL_RES_SCALE = "Resource Bar Scale",

    M6_TITLE = "Action Combat Camera (Mouselook)",
    M6_GRP_KEYS = "Camera & Interact Keybinds (Auto-clears if bound in WoW / Bartender4)",
    M6_HOLD_LABEL = "Unlock Cursor while held (onHold):",
    M6_TOGGLE_LABEL = "Unlock / Lock Camera permanently (onPress):",
    M6_INTERACT_LABEL = "Target by Crosshair & Interact (Target + Interact):",
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
    HUD_RANGE_BANNER = "OUT OF RANGE!",
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

    TAB_1 = "1. Пресеты (4)",
    TAB_2 = "2. Импорт .MD и ИИ",
    TAB_3 = "3. Визуал и HUD",
    TAB_4 = "4. Телеметрия / Дебаг",

    NAV_1 = "Пресеты ротаций",
    NAV_2 = "Псевдокод .MD и ИИ",
    NAV_3 = "Дуга ротации",
    NAV_4 = "Крылья Сейвов и КД",
    NAV_5 = "Кастбар и Ресурс",
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

    M5_TITLE = "Двунаправленный Кастбар и Трекер Доп. Ресурса",
    M5_GRP_SIZE = "Размеры и отступы кастбара",
    M5_GRP_CLIP = "Индикация прерывания потокового филлера",
    M5_GRP_RES = "Трекер доп. ресурса под кастбаром (Безумие / Приёмы серии)",
    CK_RES_ENABLE = "Включить трекер доп. ресурса под кастбаром (Безумие, Приёмы серии + Энергия и др.)",
    CK_RES_ALWAYS = "Всегда показывать панель ресурса (даже вне боя и без цели)",
    SL_RES_WIDTH = "Ширина панели ресурса (px)",
    SL_RES_HEIGHT = "Высота панели ресурса (px)",
    SL_RES_OFFSET_X = "Смещение ресурса по X (px)",
    SL_RES_OFFSET_Y = "Смещение ресурса по Y (px)",
    SL_RES_SCALE = "Масштаб панели ресурса",

    M6_TITLE = "Боевая Камера (Удержание камеры / Mouselook)",
    M6_GRP_KEYS = "Клавиши камеры и взаимодействия (авто-сброс при конфликте с игрой/аддонами)",
    M6_HOLD_LABEL = "Отвязать курсор при удержании (onHold):",
    M6_TOGGLE_LABEL = "Отвязать / привязать камеру насовсем (onPress):",
    M6_INTERACT_LABEL = "Таргет по прицелу и Взаимодействие (Target + Interact):",
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
    HUD_RANGE_BANNER = "ДАЛЕКО!",
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
• Content Mode: [PvE Universal ST + AoE / Raid Boss / PvP Arena]

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

SECTION B — ## SPELL_BOOK:
Every spell used anywhere in the profile (rotation, saves, cooldowns, emergency, misc/buffs) MUST be declared here, one per line:
SPELL <KEY> = ID:<id1,id2> | NAME:"Russian Name","English Name" | CD:<sec> | ICON:<FileDataID> [| optional flags]
• Supported optional flags (separated by ` | `):
  - `CD:<seconds>` : Base cooldown in seconds (`0` if none).
  - `CHARGES:<N>` : Max charges for multi-charge abilities (e.g., `CHARGES:2`).
  - `GAIN:<N>` : Primary resource generated on cast (0..100 scale; for Combo Point classes 1 CP = 20).
  - `COST:<N> | SPENDER:true` : Primary resource cost (for 4+ CP spenders use `COST:80 | SPENDER:true`).
  - `BURST:<sec>` : Marks ability as a burst window cooldown lasting `<sec>` seconds (enables `player.in_burst`).
  - `AURA_ID:<id1,id2> | AURA_DUR:<sec> | AURA_UNIT:<target|player>` : WeakAuras-style aura metadata! Any DoT, debuff, stackable aura, or player buff is queried uniformly via `target.aura(KEY).rem`, `target.aura(KEY).stacks`, `player.aura(KEY).rem`, `player.aura(KEY).stacks` (or standalone `AURA <KEY> = ID:<id1,id2> | AURA_UNIT:target | NAME:"..."`).
  - `STACKS:+N` / `STACKS:-N | CONSUMES_STACKS:true` : Generates or consumes target aura stacks in lookahead simulation.
  - `PROC_ONLY:true` : Only castable when glowing (`IsSpellOverlayed`) or active as a temporary spell override.
  - `OVERRIDE_OF:<BASE_KEY>` : For combo/transformation spells that replace another spell.
  - `GRANTS:<PROC_KEY>` : Casting this spell guarantees a proc of `<PROC_KEY>`.
  - `EXECUTE:true` : Execute ability (usable below 20% target HP or on proc).
  - `LOCK_CHANNEL:true` / `FILLER_INTERRUPTIBLE:true` : Channel protection or interrupt policy.
  - `ICON:<FileDataID>` : Numeric WoW icon texture ID.

SECTION C — ## CHANNEL_POLICY:
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: <KEY1, KEY2 or NONE>
PROTECT_CHANNEL: <KEY1, KEY2 or NONE>

SECTION D — ## TRACKERS:
TRACK_SAVES: <DEFENSIVE_1>, <DEFENSIVE_2>, <DEFENSIVE_3>, <DEFENSIVE_4>
TRACK_CDS: <OFFENSIVE_CD_1>, <OFFENSIVE_CD_2>, <OFFENSIVE_CD_3>, <OFFENSIVE_CD_4>

SECTION E — ## EMERGENCY_SAVE:
IF player.hp_percent <= 25 AND READY(<DEFENSIVE_KEY>) THEN
    RETURN EMERGENCY(<DEFENSIVE_KEY>)
END IF

SECTION F — ## ROTATION_QUEUE (Top-to-Bottom Priority FSM):
Use `IF <condition> THEN` / `ELSE IF <condition> THEN` / `ELSE` / `END IF` with `RETURN CAST(<KEY>)` inside each branch.
• Allowed condition primitives (combinable with `AND` / `OR`):
  - `READY(KEY)` / `NOT READY(KEY)` — spell is off cooldown (or has >= 1 charge).
  - `USABLE(KEY)` — spell is off cooldown AND player has enough resource/mana/target state.
  - `PROC(KEY)` / `NOT PROC(KEY)` — spell has an active proc overlay or active `OVERRIDE_OF` transformation.
  - `target.aura(KEY_OR_ID).rem <= 1` / `target.aura(KEY_OR_ID).rem > 0` — WeakAuras-style remaining duration (in seconds) of aura `KEY` or numeric Wowhead SpellID on `target` (`0` if absent).
  - `target.aura(KEY_OR_ID).stacks >= N` — current stack count of aura `KEY` or numeric SpellID on `target`.
  - `player.aura(KEY_OR_ID).rem > 0` / `player.aura(KEY_OR_ID).stacks >= N` — remaining duration or stack count of buff/debuff on `player`.
  - `player.in_burst` / `NOT player.in_burst` — any `BURST:<sec>` cooldown is currently active.
  - `player.energy <= N` / `player.combo_points <= N` / `player.insanity >= N` — current player resource check.
  - `enemies >= N` (or `AOE`, `CLEAVE`, `SINGLE_TARGET`) — number of nearby enemies in combat range.
  - `player.stealthed` / `NOT player.stealthed` — player is currently in Stealth.
  - `player.in_combat` / `NOT player.in_combat` — player is currently in combat.
  - `target.can_pick_pocket` — stealthed, humanoid/undead/demon NPC target in 10yd range not yet pick-pocketed.
  - `CHARGES(KEY) >= N` — current charge count.
• Always end with an unconditional `ELSE` -> `RETURN CAST(<FILLER_KEY>)` and `END IF`.]]

SpArc.AIPromptTemplate = [[Привет, Gemini / ChatGPT / Claude!
Сходи, пожалуйста, на Icy Veins или Wowhead, изучи актуальный гайд по ротации для World of Warcraft: Midnight (12.x) и напиши мне готовый профиль ротации для аддона SpArc строго на языке псевдокода SpArc .MD по правилам ниже.

====================================================================
1. ПАРАМЕТРЫ ПЕРСОНАЖА И КОНТЕНТА
====================================================================
• Класс и спек: [УКАЖИ КЛАСС И СПЕК, например: Друид Сила зверя / Разбойник Ликвидация / Воин Оружие / Маг Льда / Жрец Тьмы]
• Героические таланты / билд: [ПО ЖЕЛАНИЮ]
• Тип контента: [Универсальный СТ + АоЕ (с авто-определением числа врагов рядом и подхватом бурста)]

====================================================================
2. ПРАВИЛА КОМПИЛЯТОРА SPARC .MD (СТРОГАЯ СПЕЦИФИКАЦИЯ)
====================================================================
Аддон SpArc напрямую компилирует текстовый .MD-профиль в конечный автомат (FSM) и просчитывает очередь ротации на 5 шагов вперёд.
Выведи В ОТВЕТЕ ТОЛЬКО ОДИН кодовый блок без лишнего текста, строго соблюдая структуру из 6 секций:

СЕКЦИЯ А — МЕТАДАННЫЕ ПРОФИЛЯ (ШАПКА):
# PROFILE: <Название пресета>
# CLASS: <WARRIOR | PALADIN | HUNTER | ROGUE | PRIEST | DEATHKNIGHT | SHAMAN | MAGE | WARLOCK | MONK | DRUID | DEMONHUNTER | EVOKER>
# SPEC: <Английское название спека, например: Feral, Frost, Shadow, Assassination, Arms>
# MODE: <PVE | BOSS | PVP>

СЕКЦИЯ Б — ## SPELL_BOOK (КНИГА ЗАКЛИНАНИЙ И АУР):
Каждое заклинание и аура (включая урон, доты, стаки, сейвы, КД, баффы и инвиз/misc), которые используются в профиле, ОБЯЗАТЕЛЬНО объявляются отдельной строкой:
SPELL <КЛЮЧ_КАПСОМ> = ID:<id1,id2> | NAME:"Русское имя","English Name" | CD:<сек> | ICON:<FileDataID> [| доп. флаги]
AURA <КЛЮЧ_КАПСОМ> = ID:<id1,id2> | AURA_UNIT:<target|player> | AURA_DUR:<сек> | NAME:"Русское имя","English Name"
• Доступные флаги поведения (разделяются через ` | `):
  - `CD:<секунды>` — базовое время восстановления (`0`, если без КД).
  - `CHARGES:<N>` — максимум зарядов, если у спелла 2+ заряда.
  - `GAIN:<N>` — сколько ресурса генерирует каст (0..100; для комбо-поинтов 1 КП = 20).
  - `COST:<N> | SPENDER:true` — сколько ресурса тратит спелл (для финишеров от 4+ КП ставь `COST:80 | SPENDER:true`).
  - `BURST:<секунды>` — помечает способность как бурст-окно длительностью `<секунды>` (включает `player.in_burst`).
  - `AURA_ID:<id1,id2> | AURA_DUR:<секунды> | AURA_UNIT:<target|player>` — единая система аур (как в WeakAuras)! В игре доты, дебаффы со стаками и баффы — это всё ауры с ID с Wowhead, временем (`rem`) и стаками (`stacks`). Если ID ауры совпадает с ID спелла, достаточно `AURA_DUR:<сек>`.
  - `STACKS:+N` / `STACKS:-N | CONSUMES_STACKS:true` — генерация и трата стаков ауры на цели в симуляции очереди.
  - `PROC_ONLY:true` — спелл доступен ТОЛЬКО при свечении прока (`IsSpellOverlayed`) или активной подмене `OVERRIDE_OF`.
  - `OVERRIDE_OF:<БАЗОВЫЙ_КЛЮЧ>` — для комбо-заклинаний, заменяющих базовую кнопку.
  - `GRANTS:<КЛЮЧ_ПРОКА>` — каст гарантированно даёт прок `<КЛЮЧ_ПРОКА>`.
  - `EXECUTE:true` — экзекут-способность (активна при ХП цели < 20% или по проку).
  - `LOCK_CHANNEL:true` / `FILLER_INTERRUPTIBLE:true` — защита канала или разрешение прерывать потоковый филлер.
  - `ICON:<FileDataID>` — числовой ID текстуры иконки WoW.

СЕКЦИЯ В — ## CHANNEL_POLICY:
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: <КЛЮЧ1, КЛЮЧ2 или NONE>
PROTECT_CHANNEL: <КЛЮЧ1, КЛЮЧ2 или NONE>

СЕКЦИЯ Г — ## TRACKERS (БОКОВЫЕ КРЫЛЬЯ ХУДА):
TRACK_SAVES: <СЕЙВ_1>, <СЕЙВ_2>, <СЕЙВ_3>, <СЕЙВ_4>
TRACK_CDS: <БУРСТ_1>, <БУРСТ_2>, <БУРСТ_3>, <БУРСТ_4>

СЕКЦИЯ Д — ## EMERGENCY_SAVE (ЭКСТРЕННЫЙ СЕЙВ В ЦЕНТРЕ ЭКРАНА):
IF player.hp_percent <= 25 AND READY(<КЛЮЧ_СЕЙВА>) THEN
    RETURN EMERGENCY(<КЛЮЧ_СЕЙВА>)
END IF

СЕКЦИЯ Е — ## ROTATION_QUEUE (ПРИОРИТЕТЫ РОТАЦИИ СВЕРХУ ВНИЗ):
Строится строго конструкцией `IF <условие> THEN` / `ELSE IF <условие> THEN` / `ELSE` / `END IF`, внутри каждой ветки пишется `RETURN CAST(<КЛЮЧ>)`.
• Разрешённые условия (можно комбинировать через `AND` и `OR`):
  - `READY(KEY)` / `NOT READY(KEY)` — спелл откатился (или имеет >= 1 заряда).
  - `USABLE(KEY)` — спелл откатился И хватает ресурса/маны/условий.
  - `PROC(KEY)` / `NOT PROC(KEY)` — активен прок (свечение кнопки) или подмена `OVERRIDE_OF`.
  - `target.aura(KEY_OR_ID).rem <= 1` / `target.aura(KEY_OR_ID).rem > 0` — единая проверка времени ауры (доты, дебаффа или баффа на цели) по ключу или прямо по числовому ID с Wowhead (если ауры нет — `rem` равен `0`, поэтому `rem <= 1` покрывает и первое наложение, и обновление на последней секунде!).
  - `target.aura(KEY_OR_ID).stacks >= N` — проверка числа стаков ауры на цели.
  - `player.aura(KEY_OR_ID).rem > 0` / `player.aura(KEY_OR_ID).stacks >= N` — проверка времени или стаков ауры (баффа/бурста/дебаффа) на самом игроке.
  - `player.in_burst` / `NOT player.in_burst` — активно ли любое бурст-окно (`BURST:<сек>`).
  - `player.energy <= N` / `player.combo_points <= N` / `player.insanity >= N` — проверка ресурсов игрока.
  - `enemies >= N` (или `AOE`, `CLEAVE`, `SINGLE_TARGET`) — количество врагов рядом в радиусе боя (как в WeakAuras по неймплейтам и дистанции).
  - `player.stealthed` / `NOT player.stealthed` — находится ли персонаж в Незаметности (Stealth).
  - `player.in_combat` / `NOT player.in_combat` — находится ли персонаж в бою.
  - `target.can_pick_pocket` — игрок в инвизе, цель — гуманоид/нежить/демон в радиусе 10м с ещё не обчищенными карманами.
  - `CHARGES(KEY) >= N` — проверка числа зарядов.
• В самом конце ОБЯЗАТЕЛЬНО должна быть ветка `ELSE` -> `RETURN CAST(<КЛЮЧ_ФИЛЛЕРА>)` и закрывающий `END IF`.]]

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
  PRIEST_01_SHADOW_PVE = "1. Priest: Shadow (ST / AoE)",
  MAGE_04_FROST_PVE    = "2. Mage: Frost (ST / AoE)",
  ROGUE_01_ASSA_PVE    = "3. Rogue: Assassination (ST / AoE)",
  WARRIOR_02_ARGS_BOSS = "4. Warrior: Arms (ST / AoE)",
  DRUID_01_FERAL_PVE   = "5. Druid: Feral (ST / AoE)",
}

function SpArc:GetPresetDisplayTitle(pr)
  if not pr then return "" end
  if SpArc:IsRU() then
    return pr.title or pr.id or ""
  end
  if pr.id and EN_PRESET_TITLES[pr.id] then
    return EN_PRESET_TITLES[pr.id]
  end
  return pr.title or pr.id or ""
end

SpArc.PROFILE_SCHEMA_VERSION = 26

---------------------------------------------------------------------------------------
--         5 ACTIVE BUILT-IN PRESETS (PRIEST, MAGE, ROGUE, WARRIOR, DRUID)           --
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
-- #1: PRIEST — Shadow (Ньарлатхотеп: Leveling / ST / AoE)
-- ====================================================================================
RegisterPreset("PRIEST_01_SHADOW_PVE", "PRIEST", "1. Жрец: Тьма (ШП — Левелинг / СТ / АоЕ)", "PVE", [[
# PROFILE: 1. Жрец: Тьма (ШП — Левелинг / СТ / АоЕ)
# CLASS: PRIEST
# SPEC: Shadow
# MODE: PVE

## SPELL_BOOK
SPELL TENTACLE_SLAM = ID:1227280,205385,457042,1234796 | AURA_ID:34914 | AURA_DUR:21 | NAME:"Мощный удар щупальцем","Темное сокрушение","Shadow Crash","Tentacle Slam" | CD:15 | CHARGES:2 | GAIN:15 | ICON:136201
SPELL VAMPIRIC_TOUCH = ID:34914 | AURA_ID:34914 | AURA_DUR:21 | NAME:"Прикосновение вампира","Vampiric Touch" | CD:0 | CHARGES:1 | GAIN:6 | ICON:135978
SPELL VOID_ERUPTION = ID:228260,391109,194249 | AURA_ID:194249,391109 | AURA_UNIT:player | AURA_DUR:20 | BURST:20 | NAME:"Вхождение в Бездну","Облик Бездны","Извержение Бездны","Темное вознесение","Voidform","Void Eruption","Dark Ascension" | CD:120 | ICON:537079
SPELL POWER_INFUSION = ID:10060 | AURA_ID:10060 | AURA_UNIT:player | AURA_DUR:15 | BURST:15 | NAME:"Придание сил","Power Infusion" | CD:120 | ICON:135939
SPELL VOID_BOLT = ID:1242173,205448 | NAME:"Залп Бездны","Стрела Бездны","Void Volley","Void Bolt" | CD:6 | GAIN:10 | OVERRIDE_OF:VOID_ERUPTION | PROC_ONLY:true | ICON:1386548
SPELL DEVOURING_PLAGUE = ID:335467 | AURA_ID:335467 | AURA_DUR:6 | NAME:"Слово Тьмы: Безумие","Всепожирающая чума","Shadow Word: Madness","Devouring Plague" | CD:0 | COST:50 | GRANTS:MIND_FLAY_INSANITY | SPENDER:true | ICON:252997
SPELL SHADOW_WORD_DEATH = ID:32379 | NAME:"Слово Тьмы: Смерть","Shadow Word: Death" | CD:10 | GAIN:10 | EXECUTE:true | ICON:136149
SPELL MIND_BLAST = ID:450983,8092 | NAME:"Выброс Бездны","Взрыв разума","Void Blast","Mind Blast" | CD:7.5 | CHARGES:1 | GAIN:15 | ICON:136224
SPELL VOID_TORRENT = ID:263165 | NAME:"Поток бездны","Поток Бездны","Void Torrent" | CD:45 | CHARGES:1 | GAIN:35 | GRANTS:MIND_FLAY_INSANITY | LOCK_CHANNEL:true | ICON:1386551
SPELL MIND_FLAY_INSANITY = ID:391403 | NAME:"Пытка разума: безумие","Mind Flay: Insanity" | CD:0 | GAIN:16 | OVERRIDE_OF:MIND_FLAY | PROC_ONLY:true | ICON:136208
SPELL MIND_FLAY = ID:15407 | NAME:"Пытка разума","Mind Flay" | CD:0 | GAIN:12 | FILLER_INTERRUPTIBLE:true | ICON:136208
SPELL PSYFIEND = ID:34433,211522,375901,451235,200174 | NAME:"Исчадие Тьмы","Ментальный демон","Игры разума","Призрак Бездны","Shadowfiend","Psyfiend" | CD:60 | ICON:136199
SPELL DISPERSION = ID:47585 | NAME:"Слияние с тьмой","Слияние с Тьмой","Dispersion" | CD:90 | ICON:237563
SPELL DESPERATE_PRAYER = ID:19236 | NAME:"Молитва отчаяния","Desperate Prayer" | CD:90 | ICON:237550
SPELL VAMPIRIC_EMBRACE = ID:15286 | NAME:"Объятия вампира","Vampiric Embrace" | CD:120 | ICON:136230
SPELL FADE = ID:586,8122 | NAME:"Уход в тень","Ментальный крик","Fade","Psychic Scream" | CD:30 | ICON:135994
SPELL POWER_WORD_SHIELD = ID:17 | NAME:"Слово силы: Щит","Power Word: Shield" | CD:7.5 | ICON:135940

## CHANNEL_POLICY
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
IF target.aura(VAMPIRIC_TOUCH).rem <= 1 AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF target.aura(VAMPIRIC_TOUCH).rem <= 1 AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF PROC(VOID_BOLT) AND READY(VOID_BOLT) THEN
    RETURN CAST(VOID_BOLT)
ELSE IF PROC(DEVOURING_PLAGUE) AND USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF PROC(SHADOW_WORD_DEATH) AND READY(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF USABLE(SHADOW_WORD_DEATH) AND READY(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF PROC(MIND_BLAST) AND READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF PROC(MIND_FLAY_INSANITY) THEN
    RETURN CAST(MIND_FLAY_INSANITY)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- ====================================================================================
-- #2: MAGE — Frost (Калиратри / Морвара: ST + AoE)
-- ====================================================================================
RegisterPreset("MAGE_04_FROST_PVE", "MAGE", "2. Маг: Лёд (Фрост — СТ / АоЕ)", "PVE", [[
# PROFILE: 2. Маг: Лёд (Фрост — СТ / АоЕ)
# CLASS: MAGE
# SPEC: Frost
# MODE: PVE

## SPELL_BOOK
AURA FREEZING = ID:1221389,228358,205708 | AURA_UNIT:target | AURA_DUR:15 | NAME:"Обледенение","Замерзание","Freezing","Зимняя стужа","Winter's Chill"
SPELL RAY_OF_FROST = ID:205021 | NAME:"Морозный луч","Луч холода","Ray of Frost" | CD:60 | CHARGES:1 | STACKS:+3 | LOCK_CHANNEL:true | ICON:1698700
SPELL COMET_STORM = ID:153595,455396 | NAME:"Кометная буря","Comet Storm" | CD:30 | STACKS:+2 | PROC_ONLY:true | OVERRIDE_OF:RAY_OF_FROST | ICON:1033912
SPELL GLACIAL_SPIKE = ID:199786,257537 | NAME:"Ледниковый шип","Черная стрела","Glacial Spike","Ebonbolt" | CD:0 | STACKS:+2 | PROC_ONLY:true | OVERRIDE_OF:FROSTBOLT | ICON:1394891
SPELL FLURRY = ID:44614 | NAME:"Шквал","Flurry" | CD:30 | CHARGES:2 | STACKS:+2 | ICON:135859
SPELL FROZEN_ORB = ID:84714 | NAME:"Ледяной шар","Мерзлая сфера","Frozen Orb" | CD:60 | STACKS:+2 | ICON:629077
SPELL ICE_LANCE = ID:30455 | NAME:"Ледяное копье","Ice Lance" | CD:0 | CONSUMES_STACKS:true | STACKS:-4 | ICON:135844
SPELL BLIZZARD = ID:190356,1248829 | NAME:"Снежная буря","Blizzard" | CD:12 | ICON:135858
SPELL FROSTBOLT = ID:431044,116 | NAME:"Ледяная стрела","Стрела ледяного огня","Frostbolt","Frostfire Bolt" | CD:0 | STACKS:+1 | ICON:135846
SPELL ICE_BLOCK = ID:45438,414658 | NAME:"Ледяная глыба","Холодная хватка","Ice Block","Ice Cold" | CD:240 | CHARGES:2 | ICON:135841
SPELL ICE_BARRIER = ID:11426,235313,431038 | NAME:"Ледяная преграда","Пылающая преграда","Пылающий барьер","Ice Barrier","Blazing Barrier" | CD:25 | CHARGES:1 | ICON:135988
SPELL ALTER_TIME = ID:342245,108978 | NAME:"Манипуляции со временем","Путешествие во времени","Alter Time" | CD:60 | ICON:609811
SPELL COLD_SNAP = ID:235219,55342 | NAME:"Холодная хватка","Зеркальное изображение","Cold Snap","Mirror Image" | CD:120 | ICON:135865

## CHANNEL_POLICY
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

## ROTATION_QUEUE
IF PROC(COMET_STORM) AND READY(COMET_STORM) THEN
    RETURN CAST(COMET_STORM)
ELSE IF PROC(GLACIAL_SPIKE) AND READY(GLACIAL_SPIKE) THEN
    RETURN CAST(GLACIAL_SPIKE)
ELSE IF PROC(FLURRY) AND READY(FLURRY) THEN
    RETURN CAST(FLURRY)
ELSE IF enemies >= 3 AND READY(FROZEN_ORB) THEN
    RETURN CAST(FROZEN_ORB)
ELSE IF (enemies >= 3 OR PROC(BLIZZARD)) AND READY(BLIZZARD) THEN
    RETURN CAST(BLIZZARD)
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
ELSE IF target.aura(FREEZING).stacks >= 4 AND READY(ICE_LANCE) THEN
    RETURN CAST(ICE_LANCE)
ELSE
    RETURN CAST(FROSTBOLT)
END IF
]])

-- ====================================================================================
-- #3: ROGUE — Assassination (Улак: ST + AoE + Подхват бурста)
-- ====================================================================================
RegisterPreset("ROGUE_01_ASSA_PVE", "ROGUE", "3. Разбойник: Ликвидация (Мути — СТ / АоЕ)", "PVE", [[
# PROFILE: 3. Разбойник: Ликвидация (Мути — СТ / АоЕ)
# CLASS: ROGUE
# SPEC: Assassination
# MODE: PVE

## SPELL_BOOK
SPELL DEATHMARK = ID:360194 | AURA_ID:360194 | AURA_UNIT:target | AURA_DUR:16 | BURST:16 | NAME:"Знак смерти","Метка смерти","Deathmark" | CD:120 | ICON:4667421
SPELL KINGSBANE = ID:385627 | AURA_ID:385627 | AURA_UNIT:target | AURA_DUR:14 | BURST:14 | NAME:"Погибель королей","Kingsbane" | CD:60 | GAIN:20 | ICON:1373906
SPELL SHIV = ID:5938,319504 | NAME:"Отравляющий укол","Shiv" | CD:30 | CHARGES:1 | GAIN:20 | ICON:135428
SPELL GARROTE = ID:703 | AURA_ID:703 | AURA_DUR:18 | NAME:"Гаррота","Garrote" | CD:13 | GAIN:20 | ICON:132297
SPELL RUPTURE = ID:1943 | AURA_ID:1943 | AURA_DUR:24 | NAME:"Рваная рана","Rupture" | CD:0 | COST:80 | SPENDER:true | ICON:132302
SPELL CRIMSON_TEMPEST = ID:1247227,121411 | AURA_ID:121411 | AURA_DUR:12 | NAME:"Кровавый вихрь","Crimson Tempest" | CD:14 | COST:80 | SPENDER:true | ICON:461860
SPELL ENVENOM = ID:32645,196819 | NAME:"Отравление","Потрошение","Envenom","Eviscerate" | CD:0 | COST:80 | SPENDER:true | ICON:132287
SPELL AMBUSH = ID:8676 | NAME:"Внезапный удар","Ambush" | CD:0 | GAIN:40 | PROC_ONLY:true | OVERRIDE_OF:MUTILATE | ICON:132282
SPELL MUTILATE = ID:1329,1752 | NAME:"Расправа","Коварный удар","Mutilate","Sinister Strike" | CD:0 | GAIN:40 | FILLER_INTERRUPTIBLE:true | ICON:132304
SPELL FAN_OF_KNIVES = ID:51723 | NAME:"Веер клинков","Fan of Knives" | CD:0 | GAIN:20 | ICON:236273
SPELL VANISH = ID:1856 | NAME:"Исчезновение","Vanish" | CD:120 | ICON:132331
SPELL CLOAK_OF_SHADOWS = ID:31224 | NAME:"Плащ теней","Cloak of Shadows" | CD:120 | ICON:136177
SPELL EVASION = ID:5277 | NAME:"Ускользание","Evasion" | CD:120 | ICON:136205
SPELL CRIMSON_VIAL = ID:185311 | NAME:"Алый фиал","Crimson Vial" | CD:30 | ICON:1373900
SPELL FEINT = ID:1966 | NAME:"Уловка","Feint" | CD:15 | CHARGES:2 | ICON:132294

## TRACKERS
TRACK_SAVES: CRIMSON_VIAL, EVASION, CLOAK_OF_SHADOWS, FEINT
TRACK_CDS: DEATHMARK, KINGSBANE, SHIV, VANISH

## EMERGENCY_SAVE
IF player.hp_percent <= 35 AND READY(CRIMSON_VIAL) THEN
    RETURN EMERGENCY(CRIMSON_VIAL)
ELSE IF player.hp_percent <= 25 AND READY(EVASION) THEN
    RETURN EMERGENCY(EVASION)
ELSE IF player.hp_percent <= 20 AND READY(CLOAK_OF_SHADOWS) THEN
    RETURN EMERGENCY(CLOAK_OF_SHADOWS)
END IF

## ROTATION_QUEUE
IF target.aura(GARROTE).rem <= 1 AND READY(GARROTE) THEN
    RETURN CAST(GARROTE)
ELSE IF target.aura(RUPTURE).rem <= 1 AND READY(RUPTURE) THEN
    RETURN CAST(RUPTURE)
ELSE IF target.aura(DEATHMARK).rem > 0 AND READY(KINGSBANE) THEN
    RETURN CAST(KINGSBANE)
ELSE IF player.in_burst AND READY(SHIV) THEN
    RETURN CAST(SHIV)
ELSE IF enemies >= 2 AND READY(CRIMSON_TEMPEST) THEN
    RETURN CAST(CRIMSON_TEMPEST)
ELSE IF READY(ENVENOM) THEN
    RETURN CAST(ENVENOM)
ELSE IF PROC(AMBUSH) AND READY(AMBUSH) THEN
    RETURN CAST(AMBUSH)
ELSE IF enemies >= 3 AND READY(FAN_OF_KNIVES) THEN
    RETURN CAST(FAN_OF_KNIVES)
ELSE
    RETURN CAST(MUTILATE)
END IF
]])

-- ====================================================================================
-- #4: WARRIOR — Arms (Моржовый: ST + AoE Размашистые/Рассекающий)
-- ====================================================================================
RegisterPreset("WARRIOR_02_ARGS_BOSS", "WARRIOR", "4. Воин: Оружие (Армс — СТ / АоЕ)", "PVE", [[
# PROFILE: 4. Воин: Оружие (Армс — СТ / АоЕ)
# CLASS: WARRIOR
# SPEC: Arms
# MODE: PVE

## SPELL_BOOK
SPELL COLOSSUS_SMASH = ID:167105,262161,436358 | AURA_ID:208086 | AURA_DUR:10 | BURST:10 | NAME:"Удар колосса","Миротворец","Сокрушение","Colossus Smash","Warbreaker","Demolish" | CD:45 | CHARGES:1 | ICON:132355
SPELL BLADESTORM = ID:227847,389774,228920 | NAME:"Вихрь клинков","Опустошитель","Bladestorm","Ravager" | CD:90 | CHARGES:1 | ICON:236303
SPELL EXECUTE = ID:163201,5308,281000 | NAME:"Казнь","Execute" | CD:0 | CHARGES:1 | EXECUTE:true | ICON:135358
SPELL SWEEPING_STRIKES = ID:260708 | AURA_ID:260708 | AURA_UNIT:player | AURA_DUR:15 | NAME:"Размашистые удары","Sweeping Strikes" | CD:30 | CHARGES:1 | ICON:132366
SPELL REND = ID:772,384318,376079 | AURA_ID:772,388539 | AURA_DUR:15 | NAME:"Кровопускание","Громогласный рык","Копье чемпиона","Rend","Thunderous Roar","Champion's Spear" | CD:0 | CHARGES:1 | ICON:132155
SPELL AVATAR = ID:107574 | AURA_ID:107574 | AURA_UNIT:player | AURA_DUR:20 | BURST:20 | NAME:"Аватара","Avatar" | CD:90 | CHARGES:1 | ICON:613534
SPELL MORTAL_STRIKE = ID:12294 | NAME:"Смертельный удар","Mortal Strike" | CD:6 | CHARGES:1 | ICON:132355
SPELL OVERPOWER = ID:7384 | NAME:"Превосходство","Overpower" | CD:12 | CHARGES:2 | ICON:132223
SPELL CLEAVE = ID:845 | NAME:"Рассекающий удар","Cleave" | CD:4.5 | CHARGES:1 | ICON:132338
SPELL SLAM = ID:1680,1464,6343 | NAME:"Вихрь","Мощный удар","Удар грома","Whirlwind","Slam","Thunder Clap" | CD:0 | CHARGES:1 | FILLER_INTERRUPTIBLE:true | ICON:132369
SPELL DIE_BY_THE_SWORD = ID:118038 | NAME:"Бой насмерть","Die by the Sword" | CD:120 | CHARGES:1 | ICON:132336
SPELL RALLYING_CRY = ID:97462,383762 | NAME:"Ободряющий клич","Горестная невосприимчивость","Rallying Cry","Bitter Immunity" | CD:180 | CHARGES:1 | ICON:132351
SPELL SPELL_REFLECTION = ID:23920 | NAME:"Отражение заклинаний","Spell Reflection" | CD:25 | CHARGES:1 | ICON:132361
SPELL IMPENDING_VICTORY = ID:202168 | NAME:"Верная победа","Impending Victory" | CD:25 | CHARGES:1 | ICON:589768

## TRACKERS
TRACK_SAVES: DIE_BY_THE_SWORD, RALLYING_CRY, SPELL_REFLECTION, IMPENDING_VICTORY
TRACK_CDS: AVATAR, COLOSSUS_SMASH, BLADESTORM, SWEEPING_STRIKES

## EMERGENCY_SAVE
IF player.hp_percent <= 25 AND READY(DIE_BY_THE_SWORD) THEN
    RETURN EMERGENCY(DIE_BY_THE_SWORD)
ELSE IF player.hp_percent <= 35 AND READY(IMPENDING_VICTORY) THEN
    RETURN EMERGENCY(IMPENDING_VICTORY)
END IF

## ROTATION_QUEUE
IF enemies >= 2 AND READY(SWEEPING_STRIKES) THEN
    RETURN CAST(SWEEPING_STRIKES)
ELSE IF PROC(EXECUTE) AND READY(EXECUTE) THEN
    RETURN CAST(EXECUTE)
ELSE IF USABLE(EXECUTE) AND READY(EXECUTE) THEN
    RETURN CAST(EXECUTE)
ELSE IF target.aura(REND).rem <= 1 AND READY(REND) THEN
    RETURN CAST(REND)
ELSE IF READY(COLOSSUS_SMASH) THEN
    RETURN CAST(COLOSSUS_SMASH)
ELSE IF enemies >= 3 AND READY(CLEAVE) THEN
    RETURN CAST(CLEAVE)
ELSE IF READY(MORTAL_STRIKE) THEN
    RETURN CAST(MORTAL_STRIKE)
ELSE IF (enemies >= 3 OR player.in_burst) AND READY(BLADESTORM) THEN
    RETURN CAST(BLADESTORM)
ELSE IF READY(OVERPOWER) THEN
    RETURN CAST(OVERPOWER)
ELSE IF READY(CLEAVE) THEN
    RETURN CAST(CLEAVE)
ELSE
    RETURN CAST(SLAM)
END IF
]])

-- ====================================================================================
-- #5: DRUID — Feral (Трипобраз: Midnight 12.0+ ST + AoE + Авто-подхват бурста)
-- ====================================================================================
RegisterPreset("DRUID_01_FERAL_PVE", "DRUID", "5. Друид: Сила зверя (Кот — СТ / АоЕ)", "PVE", [[
# PROFILE: 5. Друид: Сила зверя (Кот — СТ / АоЕ)
# CLASS: DRUID
# SPEC: Feral
# MODE: PVE

## SPELL_BOOK
SPELL TIGERS_FURY = ID:5217 | AURA_ID:5217 | AURA_UNIT:player | AURA_DUR:20 | BURST:20 | NAME:"Тигриное неистовство","Tiger's Fury" | CD:30 | ICON:132242
SPELL BERSERK = ID:106951,102543,343223 | AURA_ID:106951,102543 | AURA_UNIT:player | AURA_DUR:15 | BURST:15 | NAME:"Берсерк","Воплощение: аватара Ашаманы","Berserk","Incarnation: Avatar of Ashamane" | CD:120 | ICON:236149
SPELL CONVOKE_THE_SPIRITS = ID:391528 | NAME:"Созыв духов","Convoke the Spirits" | CD:120 | LOCK_CHANNEL:true | ICON:3636839
SPELL FERAL_FRENZY = ID:274837,1243807 | NAME:"Дикое бешенство","Безумное бешенство","Feral Frenzy","Frantic Frenzy" | CD:45 | GAIN:100 | ICON:2065580
SPELL RAKE = ID:1822 | AURA_ID:155722 | AURA_DUR:15 | NAME:"Глубокая рана","Rake" | CD:0 | GAIN:20 | ICON:132122
SPELL PRIMAL_WRATH = ID:285381 | AURA_ID:1079 | AURA_DUR:12 | NAME:"Первобытный гнев","Primal Wrath" | CD:0 | COST:80 | SPENDER:true | ICON:2065583
SPELL RIP = ID:1079 | AURA_ID:1079 | AURA_DUR:24 | NAME:"Разорвать","Rip" | CD:0 | COST:80 | SPENDER:true | ICON:132152
SPELL FEROCIOUS_BITE = ID:22568,441583,441591 | NAME:"Свирепый укус","Опустошение","Ferocious Bite","Ravage" | CD:0 | COST:80 | SPENDER:true | ICON:132127
SPELL SWIPE = ID:106785,213764 | NAME:"Размах","Swipe" | CD:0 | GAIN:20 | ICON:132141
SPELL SHRED = ID:5221 | NAME:"Полоснуть","Shred" | CD:0 | GAIN:20 | FILLER_INTERRUPTIBLE:true | ICON:136231
SPELL SURVIVAL_INSTINCTS = ID:61336 | NAME:"Инстинкты выживания","Survival Instincts" | CD:180 | CHARGES:2 | ICON:236169
SPELL BARKSKIN = ID:22812 | NAME:"Дубовая кожа","Barkskin" | CD:60 | ICON:136097
SPELL REGROWTH = ID:8936 | AURA_ID:69369 | AURA_UNIT:player | AURA_DUR:12 | NAME:"Восстановление","Regrowth","Стремительность хищника","Predatory Swiftness" | CD:0 | ICON:136085
SPELL FRENZIED_REGENERATION = ID:22842,108238 | NAME:"Неистовое восстановление","Обновление","Frenzied Regeneration","Renewal" | CD:36 | ICON:132091

## CHANNEL_POLICY
PROTECT_CHANNEL: CONVOKE_THE_SPIRITS

## TRACKERS
TRACK_SAVES: SURVIVAL_INSTINCTS, BARKSKIN, REGROWTH, FRENZIED_REGENERATION
TRACK_CDS: BERSERK, CONVOKE_THE_SPIRITS, TIGERS_FURY, FERAL_FRENZY

## EMERGENCY_SAVE
IF player.hp_percent <= 25 AND READY(SURVIVAL_INSTINCTS) THEN
    RETURN EMERGENCY(SURVIVAL_INSTINCTS)
ELSE IF player.hp_percent <= 45 AND PROC(REGROWTH) AND READY(REGROWTH) THEN
    RETURN EMERGENCY(REGROWTH)
ELSE IF player.hp_percent <= 35 AND READY(FRENZIED_REGENERATION) THEN
    RETURN EMERGENCY(FRENZIED_REGENERATION)
ELSE IF player.hp_percent <= 40 AND READY(BARKSKIN) THEN
    RETURN EMERGENCY(BARKSKIN)
END IF

## ROTATION_QUEUE
IF player.stealthed AND READY(RAKE) THEN
    RETURN CAST(RAKE)
ELSE IF PROC(FEROCIOUS_BITE) AND READY(FEROCIOUS_BITE) THEN
    RETURN CAST(FEROCIOUS_BITE)
ELSE IF player.energy <= 40 AND READY(TIGERS_FURY) THEN
    RETURN CAST(TIGERS_FURY)
ELSE IF enemies >= 2 AND target.aura(RIP).rem <= 1 AND USABLE(PRIMAL_WRATH) THEN
    RETURN CAST(PRIMAL_WRATH)
ELSE IF target.aura(RIP).rem <= 1 AND USABLE(RIP) THEN
    RETURN CAST(RIP)
ELSE IF USABLE(FEROCIOUS_BITE) THEN
    RETURN CAST(FEROCIOUS_BITE)
ELSE IF target.aura(RAKE).rem <= 1 AND READY(RAKE) THEN
    RETURN CAST(RAKE)
ELSE IF player.combo_points <= 2 AND READY(FERAL_FRENZY) THEN
    RETURN CAST(FERAL_FRENZY)
ELSE IF player.aura(BERSERK).rem > 0 AND player.combo_points <= 2 AND READY(CONVOKE_THE_SPIRITS) THEN
    RETURN CAST(CONVOKE_THE_SPIRITS)
ELSE IF enemies >= 2 AND READY(SWIPE) THEN
    RETURN CAST(SWIPE)
ELSE
    RETURN CAST(SHRED)
END IF
]])

-- Legacy compatibility map for PVE / BOSS / PVP quick mode keys
SpArc.DefaultMarkdownProfiles = {
  ["PVE"]  = SpArc.BuiltInPresets["PRIEST_01_SHADOW_PVE"].md,
  ["BOSS"] = SpArc.BuiltInPresets["PRIEST_01_SHADOW_PVE"].md,
  ["PVP"]  = SpArc.BuiltInPresets["PRIEST_01_SHADOW_PVE"].md,
}
