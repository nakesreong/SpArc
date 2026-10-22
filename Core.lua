---------------------------------------------------------------------------------------
--  SpArc/Core.lua — Core Namespace, Shared Helpers, Spell Catalog & SavedVariables
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc or _G.SparkArc or {}
_G.SpArc = SpArc
_G.SparkArc = SpArc
_G.SpArcLoaded = true
_G.SparkArcLoaded = true

SpArc.VERSION = "2.7.1"
SpArc.PROFILE_SCHEMA_VERSION = 9

local C_AddOns = _G.C_AddOns
local C_CVar = _G.C_CVar
local UIParent = _G.UIParent
local issecretvalue = _G.issecretvalue
local pcall = _G.pcall
local ipairs = _G.ipairs
local pairs = _G.pairs
local type = _G.type

local FONT_PATH = (_G.GameFontNormal and select(1, _G.GameFontNormal:GetFont()))
  or (_G.StandardTextFont and select(1, _G.StandardTextFont:GetFont()))
  or "Fonts\\FRIZQT___CYR.TTF"

function SpArc.ApplyCyrFont(fs, size)
  if not fs then return end
  local fPath = (_G.GameFontNormal and select(1, _G.GameFontNormal:GetFont())) or FONT_PATH
  local ok = fs:SetFont(fPath, size, "OUTLINE")
  if not ok then
    fs:SetFont("Fonts\\FRIZQT___CYR.TTF", size, "OUTLINE")
  end
end

function SpArc.IsSecret(v)
  return issecretvalue and issecretvalue(v) or false
end

function SpArc.SafeBool(fn, ...)
  if not fn then return false end
  local ok, res = pcall(fn, ...)
  if not ok or SpArc.IsSecret(res) then return false end
  return res and true or false
end

function SpArc.Trim(s)
  if not s then return "" end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function SpArc.EnableAssistedCombatEngine()
  if C_CVar and C_CVar.SetCVar then
    pcall(C_CVar.SetCVar, "assistedCombatHighlight", "1")
  end
end

SpArc.EnableAssistedCombatEngine()

---------------------------------------------------------------------------------------
--                  DEFAULT SPELL CATALOG (MERGED WITH .MD SPELL_BOOK)               --
---------------------------------------------------------------------------------------
local BASE_SPELL_DEFS = {
  TENTACLE_SLAM = {
    key = "TENTACLE_SLAM",
    names = { "Мощный удар щупальцем", "Темное сокрушение", "Shadow Crash", "Tentacle Slam" },
    macroNames = { "M1", "M2", "sp3" },
    ids = { 1227280, 205385, 457042, 1234796 },
    preferredSlot = 1,
    baseCD = 15,
    maxCharges = 2,
    insanityGain = 15,
    fallbackIcon = 136201,
    fallbackKey = "M1",
    appliesDoTs = true,
  },
  VAMPIRIC_TOUCH = {
    key = "VAMPIRIC_TOUCH",
    names = { "Прикосновение вампира", "Vampiric Touch" },
    macroNames = { "sp1pvp", "sp1" },
    ids = { 34914 },
    preferredSlot = 64,
    baseCD = 0,
    maxCharges = 1,
    insanityGain = 6,
    fallbackIcon = 135978,
    fallbackKey = "SR",
    appliesDoTs = true,
  },
  VOID_TORRENT = {
    key = "VOID_TORRENT",
    names = { "Поток бездны", "Поток Бездны", "Void Torrent" },
    macroNames = { "SM1", "SM2" },
    ids = { 263165 },
    preferredSlot = 3,
    baseCD = 45,
    maxCharges = 1,
    insanityGain = 35,
    grantsMFI = true,
    lockChannel = true,
    fallbackIcon = 1386551,
    fallbackKey = "SM1",
  },
  DEVOURING_PLAGUE = {
    key = "DEVOURING_PLAGUE",
    names = { "Слово Тьмы: Безумие", "Всепожирающая чума", "Shadow Word: Madness", "Devouring Plague" },
    macroNames = { "sp4" },
    ids = { 335467 },
    preferredSlot = 63,
    baseCD = 0,
    maxCharges = 1,
    insanityCost = 50,
    grantsMFI = true,
    fallbackIcon = 252997,
    fallbackKey = "R",
    isSpender = true,
    requiresUsable = true,
  },
  MIND_BLAST = {
    key = "MIND_BLAST",
    names = { "Выброс Бездны", "Взрыв разума", "Void Blast", "Mind Blast" },
    macroNames = { "M2", "M1", "M1_2" },
    ids = { 450983, 8092 },
    preferredSlot = 2,
    baseCD = 7.5,
    maxCharges = 1,
    insanityGain = 15,
    fallbackIcon = 136224,
    fallbackKey = "M2",
  },
  VOID_BOLT = {
    key = "VOID_BOLT",
    names = { "Залп Бездны", "Стрела Бездны", "Void Volley", "Void Bolt" },
    macroNames = { "M2", "1_to_2", "Dps", "M1" },
    ids = { 1242173, 205448 },
    preferredSlot = 2,
    baseCD = 6,
    maxCharges = 1,
    insanityGain = 10,
    fallbackIcon = 1386548,
    fallbackKey = "M2",
    procOnly = true,
  },
  SHADOW_WORD_DEATH = {
    key = "SHADOW_WORD_DEATH",
    names = { "Слово Тьмы: Смерть", "Shadow Word: Death" },
    macroNames = { "SM2", "SM1" },
    ids = { 32379 },
    preferredSlot = 4,
    baseCD = 10,
    maxCharges = 1,
    insanityGain = 10,
    fallbackIcon = 136149,
    fallbackKey = "SM2",
    requiresUsable = true,
    isExecute = true,
  },
  MIND_FLAY_INSANITY = {
    key = "MIND_FLAY_INSANITY",
    names = { "Пытка разума: безумие", "Mind Flay: Insanity" },
    macroNames = { "sp8" },
    ids = { 391403 },
    preferredSlot = 10,
    baseCD = 0,
    maxCharges = 1,
    insanityGain = 16,
    fallbackIcon = 136208,
    fallbackKey = "SE",
    procOnly = true,
  },
  MIND_FLAY = {
    key = "MIND_FLAY",
    names = { "Пытка разума", "Mind Flay" },
    macroNames = { "sp8" },
    ids = { 15407, 391403 },
    preferredSlot = 10,
    baseCD = 0,
    maxCharges = 1,
    insanityGain = 12,
    fillerInterruptible = true,
    fallbackIcon = 136208,
    fallbackKey = "SE",
  },
  VOID_ERUPTION = {
    key = "VOID_ERUPTION",
    names = { "Облик Бездны", "Извержение Бездны", "Темное вознесение", "Voidform", "Void Eruption", "Dark Ascension" },
    macroNames = { "M2", "1_to_2", "Dps" },
    ids = { 228260, 391109 },
    preferredSlot = 2,
    baseCD = 120,
    maxCharges = 1,
    fallbackIcon = 537079,
    fallbackKey = "M2",
  },
  POWER_INFUSION = {
    key = "POWER_INFUSION",
    names = { "Придание сил", "Power Infusion" },
    macroNames = { "1_to_2" },
    ids = { 10060 },
    preferredSlot = 11,
    baseCD = 120,
    maxCharges = 1,
    fallbackIcon = 135939,
    fallbackKey = "Q",
  },
  HALO = {
    key = "HALO",
    names = { "Сияние", "Божественная звезда", "Halo", "Divine Star" },
    macroNames = { "S1" },
    ids = { 120644, 122121, 120517 },
    preferredSlot = 53,
    baseCD = 60,
    maxCharges = 1,
    insanityGain = 10,
    fallbackIcon = 632352,
    fallbackKey = "S1",
  },
  PSYFIEND = {
    key = "PSYFIEND",
    names = { "Исчадие Тьмы", "Ментальный демон", "Игры разума", "Призрак Бездны", "Shadowfiend", "Psyfiend", "Mindgames" },
    macroNames = { "pvptal" },
    ids = { 34433, 211522, 375901, 451235, 200174 },
    preferredSlot = 67,
    baseCD = 60,
    maxCharges = 1,
    fallbackIcon = 136199,
    fallbackKey = "T",
  },
  DISPERSION = {
    key = "DISPERSION",
    names = { "Слияние с тьмой", "Слияние с Тьмой", "Dispersion" },
    macroNames = { "CM2" },
    ids = { 47585 },
    preferredSlot = 6,
    baseCD = 90,
    maxCharges = 1,
    fallbackIcon = 237563,
    fallbackKey = "CM2",
  },
  DESPERATE_PRAYER = {
    key = "DESPERATE_PRAYER",
    names = { "Молитва отчаяния", "Desperate Prayer" },
    macroNames = { "CM1" },
    ids = { 19236 },
    preferredSlot = 5,
    baseCD = 90,
    maxCharges = 1,
    fallbackIcon = 237550,
    fallbackKey = "CM1",
  },
  VAMPIRIC_EMBRACE = {
    key = "VAMPIRIC_EMBRACE",
    names = { "Объятия вампира", "Vampiric Embrace" },
    macroNames = { "AM1" },
    ids = { 15286 },
    preferredSlot = 7,
    baseCD = 120,
    maxCharges = 1,
    fallbackIcon = 136230,
    fallbackKey = "AM1",
  },
  FADE = {
    key = "FADE",
    names = { "Уход в тень", "Ментальный крик", "Fade", "Psychic Scream" },
    macroNames = { "p2", "p12", "p4" },
    ids = { 586, 8122 },
    preferredSlot = 71,
    baseCD = 30,
    maxCharges = 1,
    fallbackIcon = 135994,
    fallbackKey = "Z",
  },
  POWER_WORD_SHIELD = {
    key = "POWER_WORD_SHIELD",
    names = { "Слово силы: Щит", "Power Word: Shield" },
    macroNames = { "H_Shield", "p4" },
    ids = { 17 },
    preferredSlot = 62,
    baseCD = 7.5,
    maxCharges = 1,
    fallbackIcon = 135940,
    fallbackKey = "SB3",
  },
  SILENCE = {
    key = "SILENCE",
    names = { "Безмолвие", "Silence" },
    macroNames = { "F" },
    ids = { 15487 },
    preferredSlot = 65,
    baseCD = 45,
    maxCharges = 1,
    fallbackIcon = 458230,
    fallbackKey = "F",
  },
  PSYCHIC_HORROR = {
    key = "PSYCHIC_HORROR",
    names = { "Глубинный ужас", "Psychic Horror" },
    macroNames = { "p2vp", "M3" },
    ids = { 64044 },
    preferredSlot = 12,
    baseCD = 45,
    maxCharges = 1,
    fallbackIcon = 237568,
    fallbackKey = "SQ",
  },
}

SpArc.SPELL_DEFS = {}
for k, v in pairs(BASE_SPELL_DEFS) do
  SpArc.SPELL_DEFS[k] = v
end

SpArc.ACTIVE_SLOTS = {
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
  61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72,
  49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60,
  13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
}

SpArc.SLOT_DEFAULT_KEYBIND = {
  [1]  = "M1",
  [2]  = "M2",
  [3]  = "SM1",
  [4]  = "SM2",
  [5]  = "CM1",
  [6]  = "CM2",
  [7]  = "AM1",
  [8]  = "AM2",
  [9]  = "E",
  [10] = "SE",
  [11] = "Q",
  [12] = "SQ",
  [61] = "B3",
  [62] = "SB3",
  [63] = "R",
  [64] = "SR",
  [65] = "F",
  [66] = "SF",
  [67] = "T",
  [68] = "ST",
  [69] = "CR",
  [70] = "V",
  [71] = "Z",
  [72] = "SZ",
}

SpArc.ACTION_BAR_RANGES = {
  { base = 1,   count = 12, bind = "ACTIONBUTTON" },
  { base = 61,  count = 12, bind = "MULTIACTIONBAR1BUTTON" },
  { base = 49,  count = 12, bind = "MULTIACTIONBAR2BUTTON" },
  { base = 25,  count = 12, bind = "MULTIACTIONBAR3BUTTON" },
  { base = 37,  count = 12, bind = "MULTIACTIONBAR4BUTTON" },
}

SpArc.CLICKCAST_SHORT = {
  button1 = "M1",
  button2 = "M2",
  shiftbutton1 = "SM1",
  shiftbutton2 = "SM2",
  ctrlbutton1 = "CM1",
  ctrlbutton2 = "CM2",
  altbutton1 = "AM1",
  altbutton2 = "AM2",
}

SpArc.DEFAULT_VISUAL = {
  arcRadius = 135,
  arcSpreadDeg = 120,
  arcOffsetY = 0,
  primaryScale = 1.50,
  queueScale = 1.00,
  queueLength = 5,
  castbarWidth = 276,
  castbarOffsetY = -135,
  wingsOffsetY = -75,
  emergencyHP = 25,
  showSavesWing = true,
  showCDsWing = true,
  showEmergencySave = true,
  showInterruptAlert = true,
  showCastbar = true,
  alwaysShowCDs = false,
  enableTelemetry = true,
  showMinimapButton = true,
  minimapAngle = 205,
  lang = "AUTO",
}

SpArc.state = {
  lastCastAt = {},
  lastSlotScanAt = 0,
  targetDoTsUntil = 0,
  lastTargetGUID = nil,
  trackedInsanity = 0,
  spellChargesUsed = {},
  spellChargeStart = {},
  mfiProcUntil = 0,
  lastSpellAudit = {},
  lastShouldInterrupt = false,
  lastIsProtectedChannel = false,
  lastNextKeybind = "",
  castState = {
    active = false,
    isChannel = false,
    defKey = nil,
    name = "",
    icon = 136208,
    startTime = 0,
    endTime = 0,
  },
}

function SpArc:EnsureDB()
  _G.SpArcDB = _G.SpArcDB or _G.SparkArcDB or {}
  _G.SparkArcDB = _G.SpArcDB
  local db = _G.SpArcDB

  db.mode = db.mode or "AUTO"
  db.activePresetID = db.activePresetID or "PRIEST_01_SHADOW_PVE"
  db.autoPresets = db.autoPresets or {
    PVE  = "PRIEST_01_SHADOW_PVE",
    BOSS = "PRIEST_02_SHADOW_BOSS",
    PVP  = "PRIEST_03_SHADOW_PVP",
  }
  db.visual = db.visual or {}
  for k, v in pairs(SpArc.DEFAULT_VISUAL) do
    if db.visual[k] == nil then
      db.visual[k] = v
    end
  end

  db.presets = db.presets or {}
  db.presetOrder = db.presetOrder or {}
  if db.profileSchemaVersion ~= SpArc.PROFILE_SCHEMA_VERSION or #db.presetOrder == 0 then
    db.presetOrder = {}
    for _, id in ipairs(SpArc.BuiltInPresetOrder or {}) do
      local bp = SpArc.BuiltInPresets and SpArc.BuiltInPresets[id]
      if bp then
        db.presetOrder[#db.presetOrder + 1] = id
        db.presets[id] = {
          id = bp.id,
          class = bp.class,
          title = bp.title,
          mode = bp.mode,
          md = bp.md,
        }
      end
    end
    db.profileSchemaVersion = SpArc.PROFILE_SCHEMA_VERSION
  end

  db.telemetryLog = db.telemetryLog or {}
  db.lastSpellAudit = db.lastSpellAudit or {}
  return db
end

function SpArc:RebuildParsedProfiles()
  local db = SpArc:EnsureDB()
  SpArc.ParsedPresets = {}
  for id, p in pairs(db.presets) do
    if p and type(p.md) == "string" and SpArc.ParseMarkdownFSM then
      local compiled = SpArc:ParseMarkdownFSM(p.md)
      SpArc.ParsedPresets[id] = compiled
    end
  end
end
