---------------------------------------------------------------------------------------
--  SpArc/Core.lua — Core Namespace, Shared Helpers, Debug/Contract Engine & SavedVariables
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
--  @module Core
--  @responsibility
--    1. Initializes global `SpArc` / `SparkArc` namespace and schema version.
--    2. Provides shared WoW 12.x Secret Value & string utilities (`IsSecret`, `SafeBool`, `Trim`, `UTF8Lower`, `ApplyCyrFont`).
--    3. Manages SavedVariables (`SpArcDB`), ElvUI-style isolated character profiles, and `.MD` AST compilation cache.
--    4. Provides the Universal Debug & Contract Verification Engine (`RecordModuleTick`, `AssertContract`, `SafeCall`, `RunDebugSelfTest`)
--       used to detect regressions immediately during codebase refactoring.
--  @architecture
--    - Loaded first in `SpArc.toc` so all downstream modules share `SpArc.Trim`,
--      `SpArc.SafeGetCVar`/`SpArc.SafeSetCVar`, `SpArc.METRO_COLORS`, `SpArc.SetBackdropFlat`,
--      `SpArc.CreateFlatBorder`, and `SpArc:GetPlayerDefaultPresetID()`.
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc or _G.SparkArc or {}
_G.SpArc = SpArc
_G.SparkArc = SpArc
_G.SpArcLoaded = true
_G.SparkArcLoaded = true

SpArc.VERSION = "2.9.6"
SpArc.PROFILE_SCHEMA_VERSION = 39
if SpArc.testMode == nil then
  SpArc.testMode = false
end

local C_CVar = _G.C_CVar
local issecretvalue = _G.issecretvalue
local pcall = _G.pcall
local ipairs = _G.ipairs
local pairs = _G.pairs
local type = _G.type
local table = _G.table
local string = _G.string

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
  if not s or SpArc.IsSecret(s) or type(s) ~= "string" then return "" end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function SpArc.SafeGetCVar(cvar)
  if C_CVar and C_CVar.GetCVar then
    local ok, v = pcall(C_CVar.GetCVar, cvar)
    if ok and not SpArc.IsSecret(v) then return v end
  elseif _G.GetCVar then
    local ok, v = pcall(_G.GetCVar, cvar)
    if ok and not SpArc.IsSecret(v) then return v end
  end
  return nil
end

function SpArc.SafeSetCVar(cvar, val)
  local sVal = tostring(val)
  if SpArc.SafeGetCVar(cvar) == sVal then
    return
  end
  if C_CVar and C_CVar.SetCVar then
    pcall(C_CVar.SetCVar, cvar, sVal)
  elseif _G.SetCVar then
    pcall(_G.SetCVar, cvar, sVal)
  end
end

SpArc.FLAT_TEX = "Interface\\Buttons\\WHITE8x8"
SpArc.CLASS_ICONS_TEX = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"

SpArc.METRO_COLORS = {
  HOSTILE_RED    = { r = 0.85, g = 0.15, b = 0.15 },
  NEUTRAL_YELLOW = { r = 0.92, g = 0.78, b = 0.16 },
  FRIENDLY_GREEN = { r = 0.18, g = 0.80, b = 0.32 },
  DK_CHERRY      = { r = 0.48, g = 0.06, b = 0.18 },
  TAPPED_GREY    = { r = 0.50, g = 0.50, b = 0.54 },
  OBSIDIAN_DARK  = { r = 0.14, g = 0.15, b = 0.20 },
  CAST_GOLD      = { r = 1.00, g = 0.80, b = 0.15 },
  CAST_GREY      = { r = 0.45, g = 0.47, b = 0.50 },
}

function SpArc.SetBackdropFlat(frame, bgR, bgG, bgB, bgA, brR, brG, brB, brA)
  if not frame or not frame.SetBackdrop then return end
  frame:SetBackdrop({
    bgFile = SpArc.FLAT_TEX,
    edgeFile = SpArc.FLAT_TEX,
    edgeSize = 1,
  })
  frame:SetBackdropColor(bgR or 0.06, bgG or 0.06, bgB or 0.08, bgA or 0.95)
  frame:SetBackdropBorderColor(brR or 0.20, brG or 0.20, brB or 0.26, brA or 1.0)
end

function SpArc.CreateFlatBorder(parent, thickness, r, g, b, a, levelOffset)
  local f = _G.CreateFrame("Frame", nil, parent, "BackdropTemplate")
  f:SetAllPoints(parent)
  f:SetFrameLevel(parent:GetFrameLevel() + (levelOffset or 2))
  f:SetBackdrop({
    edgeFile = SpArc.FLAT_TEX,
    edgeSize = thickness or 1,
  })
  f:SetBackdropBorderColor(r or 0.04, g or 0.04, b or 0.06, a or 1.0)
  return f
end

local CYR_UPPER_TO_LOWER = {
  ["\208\129"] = "\209\145", -- Ё -> ё
}
for b = 144, 159 do
  CYR_UPPER_TO_LOWER[string.char(208, b)] = string.char(208, b + 32)
end
for b = 160, 175 do
  CYR_UPPER_TO_LOWER[string.char(208, b)] = string.char(209, b - 32)
end

function SpArc.UTF8Lower(s)
  if type(s) ~= "string" or s == "" then return "" end
  local low = s:lower()
  if not low:find("\208", 1, true) then
    return low
  end
  return (low:gsub("\208[\129\144-\175]", CYR_UPPER_TO_LOWER))
end

function SpArc.EnableAssistedCombatEngine()
  if C_CVar and C_CVar.SetCVar then
    pcall(C_CVar.SetCVar, "assistedCombatHighlight", "1")
  end
end

SpArc.EnableAssistedCombatEngine()

---------------------------------------------------------------------------------------
--  POST-ELVUI CHAT RECOVERY BRIDGE (Restores LeftChatPanel & ChatFrame1 when ElvUI is off)
---------------------------------------------------------------------------------------
local function IsElvUIActiveOrEnabled()
  if _G.ElvUI then return true end
  if _G.C_AddOns then
    if _G.C_AddOns.IsAddOnLoaded and _G.C_AddOns.IsAddOnLoaded("ElvUI") then
      return true
    end
    if _G.C_AddOns.GetAddOnEnableState then
      local ok, state = pcall(_G.C_AddOns.GetAddOnEnableState, "ElvUI")
      if ok and type(state) == "number" and state > 0 then
        return true
      end
    end
  end
  return false
end

function SpArc:EnsureChatVisibleWithoutElvUI()
  if IsElvUIActiveOrEnabled() then return end
  if _G.InCombatLockdown and _G.InCombatLockdown() then return end

  local lcp = _G.LeftChatPanel
  if not lcp and _G.CreateFrame and _G.UIParent then
    lcp = _G.CreateFrame("Frame", "LeftChatPanel", _G.UIParent)
    lcp:SetSize(430, 185)
    lcp:SetPoint("BOTTOMLEFT", _G.UIParent, "BOTTOMLEFT", 18, 28)
    lcp._sparcFallback = true
  elseif lcp and lcp._sparcFallback and lcp:GetNumPoints() == 0 and _G.UIParent then
    lcp:SetPoint("BOTTOMLEFT", _G.UIParent, "BOTTOMLEFT", 18, 28)
  end

  local cf1 = _G.ChatFrame1
  if cf1 then
    if cf1:GetNumPoints() == 0 then
      pcall(cf1.ClearAllPoints, cf1)
      pcall(cf1.SetPoint, cf1, "BOTTOMLEFT", lcp or _G.UIParent, "BOTTOMLEFT", 5, 5)
    end
    local w, h = cf1:GetSize()
    if not w or w < 120 or not h or h < 60 then
      pcall(cf1.SetSize, cf1, 420, 175)
    end
    if _G.UIParent and cf1:GetParent() ~= _G.UIParent then
      pcall(cf1.SetParent, cf1, _G.UIParent)
    end
    pcall(cf1.Show, cf1)
    pcall(cf1.SetAlpha, cf1, 1.0)
  end
  if _G.GeneralDockManager then
    pcall(_G.GeneralDockManager.Show, _G.GeneralDockManager)
  end
  if _G.ChatFrame1Tab then
    pcall(_G.ChatFrame1Tab.Show, _G.ChatFrame1Tab)
  end
end

SpArc:EnsureChatVisibleWithoutElvUI()

---------------------------------------------------------------------------------------
--         DYNAMIC SPELL TABLE (POPULATED STRICTLY FROM ACTIVE .MD PSEUDOCODE)       --
---------------------------------------------------------------------------------------
SpArc.SPELL_DEFS = {}

SpArc.ACTIVE_SLOTS = {
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
  61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72,
  49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60,
  25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36,
  37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48,
  13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
  73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84,
  85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96,
  97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108,
  109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120,
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
  arcOffsetX = 0,
  arcOffsetY = 0,
  arcOrderMode = "LTR",
  primaryScale = 1.50,
  primaryBorderSize = 1,
  arcAlpha = 100,
  queueScale = 1.00,
  queueLength = 5,
  castbarWidth = 276,
  castbarOffsetX = 0,
  castbarOffsetY = -135,
  wingsOffsetY = -75,
  savesOffsetX = -246,
  cdsOffsetX = 246,
  emergencyOffsetX = 0,
  emergencyOffsetY = -35,
  emergencyHP = 25,
  showSavesWing = true,
  showCDsWing = true,
  showEmergencySave = true,
  showInterruptAlert = true,
  showCastbar = true,
  showResourceBar = true,
  alwaysShowResourceBar = false,
  resourceBarWidth = 276,
  resourceBarHeight = 16,
  resourceBarOffsetX = 0,
  resourceBarOffsetY = -166,
  resourceBarScale = 1.00,
  alwaysShowCDs = false,
  enableTelemetry = true,
  enableDebugMode = true,
  showMinimapButton = true,
  minimapAngle = 205,
  enableArcHUD = true,
  enableBossRotation = true,
  enablePvPRotation = true,
  enablePressFeedback = true,
  enableCombatCamera = true,
  enableCamClickCast = true,
  showCameraCrosshair = true,
  camCrosshairOffsetX = 0,
  camCrosshairOffsetY = 20,
  camCrosshairScale = 1.00,
  camHoldKey = "G",
  camToggleKey = "`",
  camInteractKey = "AUTO",
  macroGenSkipExisting = true,
  macroGenIncludeClass = true,
  macroGenIncludeSpec = true,
  macroGenTemplate = "#showtooltip\n/stopmacro [flying]\n/cast [@target] spell",
  smartBossTab = true,
  autoUnshiftOutOfCombat = true,
  keepFormsInInstances = true,
  enableNameplates = true,
  npWidth = 140,
  npHeight = 30,
  npCastHeight = 14,
  npFontSize = 11,
  npShowQuestNPCs = true,
  npShowFriendlyNPCs = false,
  npShowNeutralNPCs = true,
  npShowFriendlyPlayers = true,
  npShowHostileClassIcon = true,
  npAutoAurasFromMD = true,
  npMaxDistance = 40,
  npDistanceFade = true,
  npMinAlpha = 0.30,
  npDimOutOfCombat = true,
  enableCombatText = true,
  ctHidePlayerScrolling = true,
  ctSuppressAlerts = true,
  ctShowDirectDamage = true,
  ctDotTickMode = "AUTO_AOE",
  ctHidePetDamage = true,
  ctHideWorldHealing = true,
  ctHideDodgeParryMiss = true,
  ctWorldTextScale = 0.65,
  ctOverheadAlpha = 0.60,
  ctOverheadY = 55,
  ctDirectionalScale = 0,
  ctSpreadNameplates = true,
  ctNameplateOverlapV = 1.35,
  ctNameplateOverlapH = 0.90,
  ctShowIncomingZone = true,
  ctShowOutgoingZone = true,
  ctIncomingX = -260,
  ctIncomingY = -20,
  ctOutgoingX = 260,
  ctOutgoingY = 20,
  ctScrollStyle = "ARC",
  ctArcCurve = 55,
  ctCritShake = true,
  ctFontSize = 16,
  enableUnitFrames = true,
  ufHideBlizzard = true,
  ufPortraitStyle = "CIRCLE",
  ufColorMode = "CLASS",
  ufShowPowerBar = true,
  ufShowTargetCastbar = true,
  ufShowTargetAuras = true,
  ufShowToT = true,
  ufShowFocus = true,
  ufShowPet = true,
  ufShowParty = true,
  ufShowBoss = true,
  ufOocAlpha = 0.85,
  ufWidth = 176,
  ufHeight = 28,
  ufPortraitSize = 48,
  ufFontSize = 11,
  ufTargetCastHeight = 16,
  ufPlayerX = -260,
  ufPlayerY = -145,
  ufTargetX = 260,
  ufTargetY = -145,
  ufTargetCastX = 260,
  ufTargetCastY = -182,
  ufToTX = 425,
  ufToTY = -145,
  ufFocusX = -430,
  ufFocusY = -40,
  ufPetX = -260,
  ufPetY = -194,
  ufPartyX = -460,
  ufPartyY = 120,
  ufBossX = 460,
  ufBossY = 140,
  lang = "AUTO",
}

SpArc.DEFAULT_NP_AURA_RULES = {}

SpArc.state = {
  lastCastAt = {},
  lastAnyCastAt = 0,
  lastSlotScanAt = 0,
  unitAuras = { target = {}, player = {} },
  nameplateAuras = {},
  nameplateUnitAuras = {},
  targetDebuffStacks = 0,
  targetDebuffUntil = 0,
  lastTargetGUID = nil,
  trackedInsanity = 0,
  spellChargesUsed = {},
  spellChargeStart = {},
  gcdStartTime = 0,
  gcdDuration = 0,
  lastStableAssistKey = nil,
  lastStableAssistID = nil,
  lastStableAssistAt = 0,
  assistCandidateKey = nil,
  assistCandidateSince = 0,
  lastSpellAudit = {},
  lastShouldInterrupt = false,
  lastIsProtectedChannel = false,
  lastNextKeybind = "",
  unitCastState = {},
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

function SpArc:IsTargetBossOrRare(unit)
  unit = unit or "target"
  if SpArc.testMode then return true end
  if not (_G.UnitExists and SpArc.SafeBool(_G.UnitExists, unit)) then
    return false
  end
  -- 1. Classification: worldboss, rareelite, rare (explicitly NOT "elite", because dungeon packs are all elite)
  if _G.UnitClassification then
    local okC, classif = pcall(_G.UnitClassification, unit)
    if okC and not SpArc.IsSecret(classif) and (classif == "worldboss" or classif == "rareelite" or classif == "rare") then
      return true
    end
  end
  -- 2. Skull level (-1)
  if _G.UnitLevel then
    local okL, lvl = pcall(_G.UnitLevel, unit)
    if okL and not SpArc.IsSecret(lvl) and lvl == -1 then
      return true
    end
  end
  -- 3. Active encounter boss frames (boss1..boss8) so dungeon/raid bosses are detected without triggering on normal elite packs
  if _G.UnitIsUnit and _G.UnitExists then
    for i = 1, 8 do
      local bUnit = "boss" .. i
      if SpArc.SafeBool(_G.UnitExists, bUnit) and SpArc.SafeBool(_G.UnitIsUnit, unit, bUnit) then
        return true
      end
    end
  end
  return false
end

function SpArc:IsTargetPvP(unit)
  unit = unit or "target"
  if SpArc.testMode then return true end
  if not (_G.UnitExists and SpArc.SafeBool(_G.UnitExists, unit)) then
    return false
  end
  if _G.UnitIsPlayer and SpArc.SafeBool(_G.UnitIsPlayer, unit) then
    return true
  end
  return false
end

function SpArc:IsBossRotationEnabled()
  local db = SpArc:EnsureDB()
  if not (db and db.visual and db.visual.enableBossRotation ~= false) then
    return false
  end
  return SpArc:IsTargetBossOrRare("target")
end

function SpArc:IsPvPRotationEnabled()
  local db = SpArc:EnsureDB()
  if not (db and db.visual and db.visual.enablePvPRotation ~= false) then
    return false
  end
  return SpArc:IsTargetPvP("target")
end

function SpArc:IsNameplatesEnabled()
  local db = SpArc:EnsureDB()
  return (db and db.visual and db.visual.enableNameplates ~= false) or false
end

local cachedCharKey = nil
local cachedDB = nil

function SpArc:GetCurrentCharKey()
  if cachedCharKey then
    return cachedCharKey
  end
  local uName = _G.UnitName and _G.UnitName("player")
  local rName = _G.GetRealmName and _G.GetRealmName()
  if uName and not SpArc.IsSecret(uName) and type(uName) == "string" and uName ~= "" and uName ~= _G.UNKNOWNOBJECT then
    if rName and not SpArc.IsSecret(rName) and type(rName) == "string" and rName ~= "" then
      cachedCharKey = uName .. " - " .. rName
      return cachedCharKey
    end
    return uName
  end
  return "Default"
end

function SpArc:GetGameInteractKey()
  if _G.GetBindingKey then
    local ok1, k1, k2 = pcall(_G.GetBindingKey, "INTERACTTARGET")
    if ok1 then
      if k1 and not SpArc.IsSecret(k1) and k1 ~= "" then return k1 end
      if k2 and not SpArc.IsSecret(k2) and k2 ~= "" then return k2 end
    end
    local ok2, m1, m2 = pcall(_G.GetBindingKey, "INTERACTMOUSEOVER")
    if ok2 then
      if m1 and not SpArc.IsSecret(m1) and m1 ~= "" then return m1 end
      if m2 and not SpArc.IsSecret(m2) and m2 ~= "" then return m2 end
    end
  end
  return "E"
end

---------------------------------------------------------------------------------------
--  @function SpArc:GetPlayerDefaultPresetID
--  @description Dynamically resolves the best default built-in `.MD` preset for the
--               current player's Specialization and Class without hardcoded names.
---------------------------------------------------------------------------------------
local DEFAULT_PRESET_BY_SPEC_ID = {
  [102] = "DRUID_02_BALANCE_PVE",
  [103] = "DRUID_01_FERAL_PVE",
  [258] = "PRIEST_01_SHADOW_PVE",
  [259] = "ROGUE_01_ASSA_PVE",
  [263] = "SHAMAN_01_ENH_PVE",
  [268] = "MONK_01_WW_PVE",
  [269] = "MONK_01_WW_PVE",
  [270] = "MONK_01_WW_PVE",
  [64]  = "MAGE_04_FROST_PVE",
  [71]  = "WARRIOR_02_ARGS_BOSS",
}

local DEFAULT_PRESET_BY_CLASS = {
  PRIEST  = "PRIEST_01_SHADOW_PVE",
  DRUID   = "DRUID_02_BALANCE_PVE",
  ROGUE   = "ROGUE_01_ASSA_PVE",
  SHAMAN  = "SHAMAN_01_ENH_PVE",
  MONK    = "MONK_01_WW_PVE",
  MAGE    = "MAGE_04_FROST_PVE",
  WARRIOR = "WARRIOR_02_ARGS_BOSS",
}

function SpArc:GetPlayerDefaultPresetID()
  if _G.GetSpecialization and _G.GetSpecializationInfo then
    local okS, specIdx = pcall(_G.GetSpecialization)
    if okS and not SpArc.IsSecret(specIdx) and type(specIdx) == "number" and specIdx > 0 then
      local okI, specID = pcall(_G.GetSpecializationInfo, specIdx)
      if okI and not SpArc.IsSecret(specID) and DEFAULT_PRESET_BY_SPEC_ID[specID] then
        return DEFAULT_PRESET_BY_SPEC_ID[specID]
      end
    end
  end
  if _G.UnitClass then
    local okC, _, classTag = pcall(_G.UnitClass, "player")
    if okC and not SpArc.IsSecret(classTag) and DEFAULT_PRESET_BY_CLASS[classTag] then
      return DEFAULT_PRESET_BY_CLASS[classTag]
    end
  end
  return "PRIEST_01_SHADOW_PVE"
end

local function InferProfileDefaultPresetID(profName, profObj)
  if type(profObj) == "table" and type(profObj.activePresetID) == "string" and profObj.activePresetID ~= "" then
    return profObj.activePresetID
  end
  if type(profName) == "string" then
    if profName:find("Котастрофа", 1, true) or profName:find("Трипобраз", 1, true) then
      return "DRUID_02_BALANCE_PVE"
    elseif profName:find("Улак", 1, true) then
      return "ROGUE_01_ASSA_PVE"
    elseif profName:find("Моржовый", 1, true) or profName:find("Стархаммер", 1, true) then
      return "WARRIOR_02_ARGS_BOSS"
    elseif profName:find("Калиратри", 1, true) or profName:find("Морвара", 1, true) then
      return "MAGE_04_FROST_PVE"
    elseif profName:find("Ниоч", 1, true) then
      return "SHAMAN_01_ENH_PVE"
    elseif profName:find("Гитсутра", 1, true) then
      return "MONK_01_WW_PVE"
    end
  end
  return SpArc:GetPlayerDefaultPresetID()
end

function SpArc:GetMDAuraRulesForPreset(presetID, db)
  db = db or cachedDB or _G.SpArcDB
  if not presetID or presetID == "" then
    presetID = (db and db.activePresetID) or "PRIEST_01_SHADOW_PVE"
  end
  local parsed = SpArc.ParsedPresets and SpArc.ParsedPresets[presetID]
  if not parsed and SpArc.ParseMarkdownFSM then
    local md = (db and db.presets and db.presets[presetID] and db.presets[presetID].md)
      or (SpArc.BuiltInPresets and SpArc.BuiltInPresets[presetID] and SpArc.BuiltInPresets[presetID].md)
      or (SpArc.BuiltInPresets and SpArc.BuiltInPresets["PRIEST_01_SHADOW_PVE"] and SpArc.BuiltInPresets["PRIEST_01_SHADOW_PVE"].md)
    if type(md) == "string" and md ~= "" then
      parsed = SpArc:ParseMarkdownFSM(md)
    end
  end
  return (parsed and parsed.mdAuraRules) or {}
end

local function CloneAuraRulesTable(srcRules, fallbackPresetID, db)
  local list = srcRules
  if type(list) ~= "table" or #list == 0 then
    list = SpArc:GetMDAuraRulesForPreset(fallbackPresetID, db)
  end
  local out = {}
  for _, r in ipairs(list) do
    if type(r) == "table" then
      out[#out + 1] = {
        enabled = (r.enabled ~= false),
        ids = tostring(r.ids or ""),
        r = tonumber(r.r) or 0.2,
        g = tonumber(r.g) or 0.6,
        b = tonumber(r.b) or 1.0,
        fromMD = (r.fromMD ~= false),
        isCustomUserRule = r.isCustomUserRule or false,
      }
    end
  end
  return out
end

local function CloneVisualTable(src, keepExplicitInteract)
  local dst = {}
  for k, v in pairs(SpArc.DEFAULT_VISUAL) do
    dst[k] = v
  end
  if type(src) == "table" then
    for k, v in pairs(src) do
      if type(v) ~= "table" then
        dst[k] = v
      end
    end
  end
  if not keepExplicitInteract or dst.camInteractKey == nil then
    dst.camInteractKey = "AUTO"
    dst.camInteractKeyUserSet = false
  end
  dst.camBindSnapshot = {}
  return dst
end

local function EnsureProfileObject(db, profName, templateVisual, keepExplicitInteract, templateAuraRules)
  db.profiles = db.profiles or {}
  if not db.profiles[profName] then
    db.profiles[profName] = {
      visual = CloneVisualTable(templateVisual or (db.profiles["Default"] and db.profiles["Default"].visual), keepExplicitInteract),
    }
  end
  local prof = db.profiles[profName]
  prof.visual = prof.visual or {}
  for k, v in pairs(SpArc.DEFAULT_VISUAL) do
    if prof.visual[k] == nil then
      prof.visual[k] = v
    end
  end
  prof.visual.camBindSnapshot = prof.visual.camBindSnapshot or {}
  if type(prof.npAuraRules) ~= "table" then
    local defPresetID = InferProfileDefaultPresetID(profName, prof)
    prof.npAuraRules = CloneAuraRulesTable(templateAuraRules, defPresetID, db)
  end
  return prof
end

function SpArc:EnsureDB(forceReinit)
  if cachedDB and _G.SpArcDB == cachedDB and cachedCharKey and not forceReinit and cachedDB.visual then
    return cachedDB
  end
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

  db.profileKeys = db.profileKeys or {}
  db.profiles = db.profiles or {}

  if not db._profilesInitialized then
    local legacyVis = type(db.visual) == "table" and db.visual or nil
    EnsureProfileObject(db, "Default", legacyVis)
    if legacyVis then
      EnsureProfileObject(db, "Ньарлатхотеп - Свежеватель Душ", legacyVis)
    end
    db._profilesInitialized = true
  else
    EnsureProfileObject(db, "Default", nil)
  end

  local charKey = SpArc:GetCurrentCharKey()
  if charKey ~= "Default" and not db.profileKeys[charKey] then
    db.profileKeys[charKey] = charKey
  end

  local activeProfName = (charKey ~= "Default" and db.profileKeys[charKey]) or db.activeProfile or "Default"
  local activeProf = EnsureProfileObject(db, activeProfName, db.profiles["Default"] and db.profiles["Default"].visual)
  db.activeProfile = activeProfName
  db.visual = activeProf.visual

  if not db._bossPvpAutoMigrated then
    for _, pObj in pairs(db.profiles or {}) do
      if pObj and type(pObj.visual) == "table" then
        pObj.visual.enableBossRotation = true
        pObj.visual.enablePvPRotation = true
      end
    end
    db._bossPvpAutoMigrated = true
  end

  db.presets = db.presets or {}
  db.presetOrder = db.presetOrder or {}
  if db.profileSchemaVersion ~= SpArc.PROFILE_SCHEMA_VERSION or #db.presetOrder == 0 then
    local prevSchema = tonumber(db.profileSchemaVersion) or 0
    local preservedPresets = {}
    local preservedCustomOrder = {}

    if prevSchema >= 21 then
      for _, id in ipairs(db.presetOrder) do
        local p = db.presets[id]
        if p then
          preservedPresets[id] = p
          if not (SpArc.BuiltInPresets and SpArc.BuiltInPresets[id]) then
            p.isCustom = true
            p.userModified = true
            preservedCustomOrder[#preservedCustomOrder + 1] = id
          end
        end
      end
      for id, p in pairs(db.presets) do
        if p and not preservedPresets[id] then
          preservedPresets[id] = p
          if not (SpArc.BuiltInPresets and SpArc.BuiltInPresets[id]) then
            p.isCustom = true
            p.userModified = true
            preservedCustomOrder[#preservedCustomOrder + 1] = id
          end
        end
      end
    else
      for id, p in pairs(db.presets) do
        local isBuiltIn = (SpArc.BuiltInPresets and SpArc.BuiltInPresets[id] ~= nil) or false
        if p and not isBuiltIn and (p.isCustom or p.userModified or tostring(id):find("_CUSTOM_", 1, true)) then
          p.isCustom = true
          p.userModified = true
          preservedPresets[id] = p
          preservedCustomOrder[#preservedCustomOrder + 1] = id
        end
      end
    end

    db.presetOrder = {}
    db.presets = {}
    for _, id in ipairs(SpArc.BuiltInPresetOrder or {}) do
      local bp = SpArc.BuiltInPresets and SpArc.BuiltInPresets[id]
      if bp then
        db.presetOrder[#db.presetOrder + 1] = id
        local existing = preservedPresets[id]
        -- If SHAMAN_01_ENH_PVE was overwritten with a MONK profile before MONK_01_WW_PVE existed, restore Shaman built-in
        local isWrongClassOverwrite = (id == "SHAMAN_01_ENH_PVE" and existing and type(existing.md) == "string" and existing.md:find("CLASS:%s*MONK"))
        if existing and existing.userModified and type(existing.md) == "string" and existing.md ~= "" and not isWrongClassOverwrite then
          db.presets[id] = existing
        else
          db.presets[id] = {
            id = bp.id,
            class = bp.class,
            title = bp.title,
            mode = bp.mode,
            md = bp.md,
            userModified = false,
          }
        end
      end
    end

    for _, cid in ipairs(preservedCustomOrder) do
      if preservedPresets[cid] and not db.presets[cid] then
        db.presetOrder[#db.presetOrder + 1] = cid
        db.presets[cid] = preservedPresets[cid]
      end
    end

    for pName, pObj in pairs(db.profiles or {}) do
      if pName:find("Гитсутра", 1, true) then
        pObj.activePresetID = "MONK_01_WW_PVE"
        pObj.autoPresets = { PVE = "MONK_01_WW_PVE", BOSS = "MONK_01_WW_PVE", PVP = "MONK_01_WW_PVE" }
      elseif not pObj.activePresetID or not db.presets[pObj.activePresetID] then
        local wantID = InferProfileDefaultPresetID(pName, pObj)
        pObj.activePresetID = wantID
        pObj.autoPresets = { PVE = wantID, BOSS = wantID, PVP = wantID }
      end
    end
    if tostring(db.activeProfile or ""):find("Гитсутра", 1, true) then
      db.activePresetID = "MONK_01_WW_PVE"
      db.autoPresets = { PVE = "MONK_01_WW_PVE", BOSS = "MONK_01_WW_PVE", PVP = "MONK_01_WW_PVE" }
    end
    db.profileSchemaVersion = SpArc.PROFILE_SCHEMA_VERSION
  end

  if not db._shamanBuiltInPresetMigrated then
    if db.presets and db.presets["SHAMAN_01_ENH_PVE"] then
      if db.presets["SHAMAN_CUSTOM_7"] then
        db.presets["SHAMAN_CUSTOM_7"] = nil
        for i = #db.presetOrder, 1, -1 do
          if db.presetOrder[i] == "SHAMAN_CUSTOM_7" then
            table.remove(db.presetOrder, i)
          end
        end
      end
      if db.activePresetID == "SHAMAN_CUSTOM_7" then
        db.activePresetID = "SHAMAN_01_ENH_PVE"
      end
      if type(db.autoPresets) == "table" then
        for k, v in pairs(db.autoPresets) do
          if v == "SHAMAN_CUSTOM_7" then db.autoPresets[k] = "SHAMAN_01_ENH_PVE" end
        end
      end
      for pName, pObj in pairs(db.profiles or {}) do
        if type(pObj) == "table" then
          if pObj.activePresetID == "SHAMAN_CUSTOM_7" or pName:find("Ниоч", 1, true) then
            pObj.activePresetID = "SHAMAN_01_ENH_PVE"
            pObj.autoPresets = { PVE = "SHAMAN_01_ENH_PVE", BOSS = "SHAMAN_01_ENH_PVE", PVP = "SHAMAN_01_ENH_PVE" }
          end
        end
      end
    end
    db._shamanBuiltInPresetMigrated = true
  end

  if activeProf.mode then
    db.mode = activeProf.mode
  else
    activeProf.mode = db.mode or "AUTO"
  end
  if activeProf.activePresetID and db.presets[activeProf.activePresetID] then
    db.activePresetID = activeProf.activePresetID
  end
  if type(activeProf.autoPresets) == "table" then
    db.autoPresets = activeProf.autoPresets
  else
    activeProf.autoPresets = {
      PVE  = (db.autoPresets and db.autoPresets.PVE) or "PRIEST_01_SHADOW_PVE",
      BOSS = (db.autoPresets and db.autoPresets.BOSS) or "PRIEST_02_SHADOW_BOSS",
      PVP  = (db.autoPresets and db.autoPresets.PVP) or "PRIEST_03_SHADOW_PVP",
    }
    db.autoPresets = activeProf.autoPresets
  end

  -- Isolate npAuraRules per profile and auto-populate from each profile's active .MD preset
  if not db._npAuraRulesFromMDV3 then
    for pName, pObj in pairs(db.profiles or {}) do
      if type(pObj) == "table" then
        local defPresetID = InferProfileDefaultPresetID(pName, pObj)
        pObj.npAuraRules = CloneAuraRulesTable(nil, defPresetID, db)
      end
    end
    db._npAuraRulesFromMDV3 = true
  end

  if type(activeProf.npAuraRules) ~= "table" or #activeProf.npAuraRules == 0 then
    activeProf.npAuraRules = CloneAuraRulesTable(nil, InferProfileDefaultPresetID(activeProfName, activeProf), db)
  end
  db.npAuraRules = activeProf.npAuraRules

  db.telemetryLog = db.telemetryLog or {}
  db.debugLog = db.debugLog or {}
  db.lastSpellAudit = db.lastSpellAudit or {}
  cachedDB = db
  return db
end

function SpArc:SaveCharPresetState(db)
  db = db or cachedDB or _G.SpArcDB
  if not db then return end
  local profName = db.activeProfile
  local prof = profName and db.profiles and db.profiles[profName]
  if prof then
    prof.mode = db.mode
    prof.activePresetID = db.activePresetID
    prof.autoPresets = db.autoPresets
  end
end

function SpArc:GetActiveProfileName()
  local db = SpArc:EnsureDB()
  return db.activeProfile or "Default"
end

function SpArc:GetProfileList()
  local db = SpArc:EnsureDB()
  local charKey = SpArc:GetCurrentCharKey()
  local seen = {}
  local list = {}
  local function add(name)
    if name and name ~= "" and not seen[name] and db.profiles[name] then
      seen[name] = true
      list[#list + 1] = name
    end
  end
  if charKey ~= "Default" then
    EnsureProfileObject(db, charKey, db.profiles["Default"] and db.profiles["Default"].visual)
    add(charKey)
  end
  add("Default")
  local others = {}
  for k in pairs(db.profiles) do
    if not seen[k] then
      others[#others + 1] = k
    end
  end
  table.sort(others)
  for _, k in ipairs(others) do
    add(k)
  end
  return list
end

local function ApplyAllActiveProfileSubsystems()
  if SpArc.RefreshAllNameplates then
    SpArc:RefreshAllNameplates()
  elseif SpArc.CompileNameplateAuraRules then
    SpArc:CompileNameplateAuraRules()
  end
  if SpArc.ApplyVisualLayout then SpArc:ApplyVisualLayout() end
  if SpArc.ApplyCombatCameraBindings then SpArc:ApplyCombatCameraBindings() end
  if SpArc.UpdateCameraState then SpArc:UpdateCameraState() end
  if SpArc.UpdateMinimapButtonVisibility then SpArc:UpdateMinimapButtonVisibility() end
  if SpArc.ApplyCombatTextSettings then SpArc:ApplyCombatTextSettings() end
  if SpArc.ApplyUnitFramesSettings then SpArc:ApplyUnitFramesSettings() end
end

function SpArc:SetProfile(profileName)
  if not profileName or profileName == "" then return end
  local db = SpArc:EnsureDB()
  local charKey = SpArc:GetCurrentCharKey()
  local prof = EnsureProfileObject(db, profileName, db.profiles["Default"] and db.profiles["Default"].visual)
  if charKey ~= "Default" then
    db.profileKeys[charKey] = profileName
  end
  db.activeProfile = profileName
  db.visual = prof.visual
  db.npAuraRules = prof.npAuraRules
  ApplyAllActiveProfileSubsystems()
end

function SpArc:CreateNewProfile(newProfileName)
  newProfileName = SpArc.Trim(newProfileName or "")
  if newProfileName == "" or #newProfileName > 50 then return false end
  local db = SpArc:EnsureDB()
  local defPresetID = db.activePresetID or InferProfileDefaultPresetID(SpArc:GetCurrentCharKey(), nil)
  db.profiles[newProfileName] = {
    visual = CloneVisualTable(nil),
    npAuraRules = CloneAuraRulesTable(nil, defPresetID, db),
  }
  SpArc:SetProfile(newProfileName)
  return true
end

function SpArc:CopyProfileFrom(srcProfileName, copyAuraRules)
  local db = SpArc:EnsureDB()
  local srcProf = db.profiles and db.profiles[srcProfileName]
  if not srcProf or not srcProf.visual then return false end
  local curProfName = SpArc:GetActiveProfileName()
  local curProf = EnsureProfileObject(db, curProfName, nil)
  for k, v in pairs(srcProf.visual) do
    if type(v) ~= "table" then
      curProf.visual[k] = v
    end
  end
  curProf.visual.camBindSnapshot = {}
  curProf.visual.camInteractKeyUserSet = false
  if copyAuraRules ~= false and type(srcProf.npAuraRules) == "table" then
    curProf.npAuraRules = CloneAuraRulesTable(srcProf.npAuraRules, InferProfileDefaultPresetID(curProfName, curProf), db)
  end
  db.visual = curProf.visual
  db.npAuraRules = curProf.npAuraRules
  ApplyAllActiveProfileSubsystems()
  return true
end

function SpArc:ResetCurrentProfile()
  local db = SpArc:EnsureDB()
  local curProfName = SpArc:GetActiveProfileName()
  local curProf = db.profiles[curProfName]
  local defPresetID = InferProfileDefaultPresetID(curProfName, curProf)
  db.profiles[curProfName] = {
    visual = CloneVisualTable(nil),
    npAuraRules = CloneAuraRulesTable(nil, defPresetID, db),
    mode = curProf and curProf.mode,
    activePresetID = curProf and curProf.activePresetID,
    autoPresets = curProf and curProf.autoPresets,
  }
  db.visual = db.profiles[curProfName].visual
  db.npAuraRules = db.profiles[curProfName].npAuraRules
  ApplyAllActiveProfileSubsystems()
end

function SpArc:SyncNameplateAurasFromActiveMD(presetID, forceResetColors)
  local db = SpArc:EnsureDB()
  local curProfName = SpArc:GetActiveProfileName()
  local curProf = EnsureProfileObject(db, curProfName, nil)
  local targetPresetID = presetID or db.activePresetID or InferProfileDefaultPresetID(curProfName, curProf)
  local mdRules = SpArc:GetMDAuraRulesForPreset(targetPresetID, db)
  if type(mdRules) ~= "table" or #mdRules == 0 then
    return
  end
  local oldRules = curProf.npAuraRules or {}
  local colorByIDs = {}
  local customRules = {}
  for _, r in ipairs(oldRules) do
    if type(r) == "table" and type(r.ids) == "string" and r.ids ~= "" then
      if not forceResetColors then
        colorByIDs[r.ids] = {
          enabled = (r.enabled ~= false),
          r = tonumber(r.r) or 0.2,
          g = tonumber(r.g) or 0.6,
          b = tonumber(r.b) or 1.0,
        }
      end
      if r.isCustomUserRule and not forceResetColors then
        customRules[#customRules + 1] = {
          enabled = (r.enabled ~= false),
          ids = r.ids,
          r = tonumber(r.r) or 0.2,
          g = tonumber(r.g) or 0.6,
          b = tonumber(r.b) or 1.0,
          fromMD = false,
          isCustomUserRule = true,
        }
      end
    end
  end
  local newList = {}
  local seenIDs = {}
  for _, mr in ipairs(mdRules) do
    local idStr = tostring(mr.ids or "")
    if idStr ~= "" then
      seenIDs[idStr] = true
      local saved = colorByIDs[idStr]
      newList[#newList + 1] = {
        enabled = (saved and saved.enabled ~= nil) and saved.enabled or true,
        ids = idStr,
        r = (saved and saved.r) or tonumber(mr.r) or 0.2,
        g = (saved and saved.g) or tonumber(mr.g) or 0.6,
        b = (saved and saved.b) or tonumber(mr.b) or 1.0,
        fromMD = true,
        isCustomUserRule = false,
      }
    end
  end
  for _, cr in ipairs(customRules) do
    if not seenIDs[cr.ids] then
      newList[#newList + 1] = cr
    end
  end
  curProf.npAuraRules = newList
  db.npAuraRules = newList
  if SpArc.RefreshAllNameplates then
    SpArc:RefreshAllNameplates()
  elseif SpArc.CompileNameplateAuraRules then
    SpArc:CompileNameplateAuraRules()
  end
end

function SpArc:ResetCurrentProfileAuraRules()
  SpArc:SyncNameplateAurasFromActiveMD(nil, true)
end

function SpArc:DeleteProfile(profileName)
  local db = SpArc:EnsureDB()
  local curProfName = SpArc:GetActiveProfileName()
  if not profileName or profileName == "Default" or profileName == curProfName then
    return false
  end
  if db.profiles[profileName] then
    db.profiles[profileName] = nil
    for ck, pk in pairs(db.profileKeys or {}) do
      if pk == profileName then
        db.profileKeys[ck] = ck
      end
    end
    return true
  end
  return false
end

function SpArc:RebuildParsedProfiles()
  local db = SpArc:EnsureDB()
  SpArc.ParsedPresets = {}
  for id, p in pairs(db.presets) do
    if p and type(p.md) == "string" and SpArc.ParseMarkdownFSM then
      local compiled = SpArc:ParseMarkdownFSM(p.md)
      SpArc.ParsedPresets[id] = compiled
      local isBuiltIn = (SpArc.BuiltInPresets and SpArc.BuiltInPresets[id] ~= nil) or false
      if not isBuiltIn or p.userModified then
        if compiled.title and compiled.title ~= "" and compiled.title ~= "Custom FSM" then
          p.title = compiled.title
        end
        local idPrefixCls = tostring(id):match("^([A-Z]+)_CUSTOM_")
        if compiled.class and compiled.class ~= "" and (compiled.class ~= "PRIEST" or p.md:match("CLASS:%s*PRIEST")) then
          p.class = compiled.class
        elseif idPrefixCls and (not p.class or p.class == "PRIEST") then
          p.class = idPrefixCls
        end
        if compiled.mode and compiled.mode ~= "" then
          p.mode = compiled.mode
        end
      end
    end
  end
  SpArc:RecordModuleTick("Core", "RebuildParsedProfiles")
end

---------------------------------------------------------------------------------------
--  UNIVERSAL DEBUG & CONTRACT VERIFICATION ENGINE (Refactoring Safety Net)
---------------------------------------------------------------------------------------
--  @purpose
--    Tracks runtime health, tick counters, contract assertions, and error boundaries
--    across all 15 SpArc modules. When `db.visual.enableDebugMode` is true, any broken
--    contract or nil reference introduced during refactoring is immediately caught,
--    recorded in `db.debugLog`, surfaced in `/sparc debug`, and alerted in chat
--    (with rate-limiting so 60 FPS loops never spam).
---------------------------------------------------------------------------------------
SpArc.DEBUG_MODULES_ORDER = {
  "Core",
  "Parser",
  "Scanner",
  "State",
  "Evaluator",
  "HUD",
  "ResourceBar",
  "Camera",
  "Telemetry",
  "MacroGen",
  "Nameplates",
  "CombatText",
  "EditMode",
  "UnitFrames",
  "ControlCenter",
}

SpArc.debugStats = SpArc.debugStats or {}
local debugRateLimit = {}

local function EnsureModuleDebugStat(moduleName)
  moduleName = tostring(moduleName or "Unknown")
  local st = SpArc.debugStats[moduleName]
  if not st then
    st = {
      name = moduleName,
      ticks = 0,
      lastTickAt = 0,
      errors = 0,
      warnings = 0,
      assertionsPassed = 0,
      lastError = nil,
      lastWarning = nil,
      lastDetail = nil,
      status = "IDLE",
    }
    SpArc.debugStats[moduleName] = st
  end
  return st
end

for _, mName in ipairs(SpArc.DEBUG_MODULES_ORDER) do
  EnsureModuleDebugStat(mName)
end

function SpArc:IsDebugEnabled()
  local db = cachedDB or _G.SpArcDB
  if db and db.visual then
    return db.visual.enableDebugMode ~= false
  end
  return true
end

local function AppendDebugLogEntry(level, moduleName, msg)
  local db = cachedDB or _G.SpArcDB
  if not db then return end
  db.debugLog = db.debugLog or {}
  local now = (_G.GetTime and _G.GetTime()) or 0
  local entry = string.format("[%.1fs] [%s] [%s] %s", now, tostring(level), tostring(moduleName), tostring(msg))
  table.insert(db.debugLog, 1, entry)
  while #db.debugLog > 200 do
    table.remove(db.debugLog)
  end
end

function SpArc:RecordModuleTick(moduleName, detail)
  local st = EnsureModuleDebugStat(moduleName)
  st.ticks = (st.ticks or 0) + 1
  st.lastTickAt = (_G.GetTime and _G.GetTime()) or 0
  if detail then
    st.lastDetail = tostring(detail)
  end
  if st.status == "IDLE" then
    st.status = "OK"
  end
end

function SpArc:DebugLog(moduleName, fmt, ...)
  if not SpArc:IsDebugEnabled() then return end
  local ok, msg = pcall(string.format, tostring(fmt or ""), ...)
  if not ok then msg = tostring(fmt) end
  AppendDebugLogEntry("INFO", moduleName, msg)
end

function SpArc:DebugWarn(moduleName, warnKey, fmt, ...)
  local st = EnsureModuleDebugStat(moduleName)
  st.warnings = (st.warnings or 0) + 1
  local ok, msg = pcall(string.format, tostring(fmt or ""), ...)
  if not ok then msg = tostring(fmt) end
  st.lastWarning = msg
  if st.status ~= "ERR" then
    st.status = "WARN"
  end
  local now = (_G.GetTime and _G.GetTime()) or 0
  local rKey = "W:" .. tostring(moduleName) .. ":" .. tostring(warnKey or msg)
  if not debugRateLimit[rKey] or (now - debugRateLimit[rKey]) >= 10.0 then
    debugRateLimit[rKey] = now
    AppendDebugLogEntry("WARN", moduleName, msg)
    if SpArc:IsDebugEnabled() then
      print(string.format("|cffa335ee[SpArc DEBUG WARN]|r |cffffd100[%s]|r %s", tostring(moduleName), msg))
    end
  end
end

function SpArc:DebugError(moduleName, errKey, errMsg)
  local st = EnsureModuleDebugStat(moduleName)
  st.errors = (st.errors or 0) + 1
  local msg = tostring(errMsg or "unknown error")
  st.lastError = msg
  st.status = "ERR"
  local now = (_G.GetTime and _G.GetTime()) or 0
  local rKey = "E:" .. tostring(moduleName) .. ":" .. tostring(errKey or msg)
  if not debugRateLimit[rKey] or (now - debugRateLimit[rKey]) >= 8.0 then
    debugRateLimit[rKey] = now
    AppendDebugLogEntry("ERROR", moduleName, msg)
    if SpArc:IsDebugEnabled() then
      print(string.format("|cffff4040[SpArc DEBUG ERROR]|r |cffffd100[%s:%s]|r %s", tostring(moduleName), tostring(errKey or "?"), msg))
    end
  end
end

function SpArc:AssertContract(moduleName, condition, contractKey, fmt, ...)
  local st = EnsureModuleDebugStat(moduleName)
  if condition then
    st.assertionsPassed = (st.assertionsPassed or 0) + 1
    if st.status == "IDLE" then st.status = "OK" end
    return true
  end
  SpArc:DebugWarn(moduleName, contractKey or "CONTRACT", fmt or ("Contract violation: " .. tostring(contractKey)), ...)
  return false
end

function SpArc:SafeCall(moduleName, fnName, fn, ...)
  if type(fn) ~= "function" then
    SpArc:DebugError(moduleName, fnName or "SafeCall", "Attempted to call non-function (" .. type(fn) .. ")")
    return false
  end
  local ok, r1, r2, r3, r4 = pcall(fn, ...)
  if not ok then
    SpArc:DebugError(moduleName, fnName or "SafeCall", r1)
    return false
  end
  SpArc:RecordModuleTick(moduleName, fnName)
  return true, r1, r2, r3, r4
end

function SpArc:RunDebugSelfTest(printToChat)
  local db = SpArc:EnsureDB()
  local passed = 0
  local failed = 0
  local function check(modName, cond, key, desc)
    if SpArc:AssertContract(modName, cond, key, desc) then
      passed = passed + 1
    else
      failed = failed + 1
    end
  end

  -- 1. Core & SavedVariables contract
  check("Core", type(db) == "table" and type(db.visual) == "table", "DB_VISUAL", "db.visual table must exist")
  check("Core", type(db.presets) == "table" and type(db.presetOrder) == "table" and #db.presetOrder > 0, "DB_PRESETS", "db.presets and presetOrder must be non-empty")
  check("Core", type(SpArc.SPELL_DEFS) == "table", "SPELL_DEFS_TABLE", "SpArc.SPELL_DEFS table must exist")
  check("Core", type(SpArc.SetBackdropFlat) == "function" and type(SpArc.CreateFlatBorder) == "function" and type(SpArc.METRO_COLORS) == "table", "CORE_UI_PRIMITIVES", "Shared Metro UI primitives (SetBackdropFlat, CreateFlatBorder, METRO_COLORS) must exist")
  check("Core", type(SpArc.GetPlayerDefaultPresetID) == "function" and type(SpArc:GetPlayerDefaultPresetID()) == "string", "CORE_DEFAULT_PRESET", "GetPlayerDefaultPresetID must return a valid preset ID string")

  -- 2. Parser & Active Profile contract
  check("Parser", type(SpArc.ParseMarkdownFSM) == "function", "FN_PARSE", "SpArc:ParseMarkdownFSM must be registered")
  local activeProf = SpArc:SelectActiveParsedProfile()
  check("Parser", type(activeProf) == "table" and type(activeProf.rules) == "table", "ACTIVE_AST", "Active parsed profile AST must contain rules table")
  local defCount = 0
  for _ in pairs(SpArc.SPELL_DEFS or {}) do defCount = defCount + 1 end
  check("Parser", defCount > 0, "SPELL_DEFS_POPULATED", "SPELL_DEFS must have >0 spells after profile selection (got %d)", defCount)

  -- 3. Scanner contract
  check("Scanner", type(SpArc.ScanActionSlotsAndSpells) == "function", "FN_SCAN", "SpArc:ScanActionSlotsAndSpells must exist")
  check("Scanner", type(SpArc.GetSlotKeybind) == "function" and type(SpArc.MatchSpellToDefKey) == "function", "SCAN_API", "Scanner keybind & spell matcher API must exist")

  -- 4. State contract
  check("State", type(SpArc.state) == "table" and type(SpArc.state.castState) == "table", "STATE_TABLE", "SpArc.state and castState must exist")
  check("State", type(SpArc.EvaluateSpellState) == "function" and type(SpArc.GetUnitAuraState) == "function", "FN_STATE", "State evaluation functions must exist")

  -- 5. Evaluator contract (dry-run BuildRotationQueue)
  check("Evaluator", type(SpArc.BuildRotationQueue) == "function", "FN_EVAL", "SpArc:BuildRotationQueue must exist")
  local okQ, qRes, evalRes = SpArc:SafeCall("Evaluator", "SelfTest_BuildRotationQueue", SpArc.BuildRotationQueue, SpArc, 5)
  check("Evaluator", okQ and type(qRes) == "table" and type(evalRes) == "table", "EVAL_QUEUE_RET", "BuildRotationQueue must return (queue, evaluated) tables")

  -- 6. HUD contract
  check("HUD", type(SpArc.ApplyVisualLayout) == "function" and _G.SpArcHUDRoot ~= nil, "HUD_ROOT", "SpArcHUDRoot and ApplyVisualLayout must exist")

  -- 7. ResourceBar contract
  check("ResourceBar", type(SpArc.UpdateResourceBar) == "function" and SpArc.resourceFrame ~= nil, "RES_FRAME", "SpArc.resourceFrame and UpdateResourceBar must exist")
  check("ResourceBar", type(SpArc.GetClassResourceState) == "function", "RES_STATE_API", "Unified SpArc:GetClassResourceState() API must exist")

  -- 8. Camera contract
  check("Camera", type(SpArc.UpdateCameraState) == "function" and _G.SpArcCamHoldButton ~= nil and _G.SpArcCamInteractButton ~= nil, "CAM_BUTTONS", "Secure camera buttons and UpdateCameraState must exist")

  -- 9. Telemetry contract
  check("Telemetry", type(SpArc.BuildTelemetryReportText) == "function" and type(SpArc.CaptureTelemetrySnapshot) == "function", "FN_TEL", "Telemetry snapshot & report functions must exist")

  -- 10. MacroGen contract
  check("MacroGen", type(SpArc.ScanSpellBookForMacros) == "function" and type(SpArc.GenerateClassMacros) == "function", "FN_MACROGEN", "MacroGen functions must exist")

  -- 11. Nameplates contract
  check("Nameplates", type(SpArc.RefreshAllNameplates) == "function" and type(SpArc.CompileNameplateAuraRules) == "function", "FN_NAMEPLATES", "Nameplates API must exist")

  -- 12. CombatText contract
  check("CombatText", type(SpArc.ApplyCombatTextSettings) == "function" and type(SpArc.SpawnMSBTText) == "function", "FN_COMBATTEXT", "CombatText & MSBT API must exist")

  -- 13. EditMode contract
  check("EditMode", type(SpArc.ToggleEditMode) == "function" and type(SpArc.RegisterEditMover) == "function", "FN_EDITMODE", "EditMode registry API must exist")

  -- 14. UnitFrames contract
  check("UnitFrames", type(SpArc.ApplyUnitFramesSettings) == "function" and type(SpArc.unitFrames) == "table", "UF_POOL", "UnitFrames table and ApplyUnitFramesSettings must exist")
  check("UnitFrames", SpArc.unitFrames and SpArc.unitFrames.player ~= nil and SpArc.unitFrames.target ~= nil and SpArc.unitFrames.party1 ~= nil, "UF_FRAMES", "Player, Target, and Party1 UnitFrames must be constructed")

  -- 15. ControlCenter contract
  check("ControlCenter", type(SpArc.OpenControlCenter) == "function", "FN_CONTROLCENTER", "OpenControlCenter must exist")

  local summary = string.format("Self-Test Complete: %d passed, %d failed across %d modules", passed, failed, #SpArc.DEBUG_MODULES_ORDER)
  AppendDebugLogEntry(failed == 0 and "SELF-TEST OK" or "SELF-TEST WARN", "Core", summary)
  if printToChat then
    local badge = (failed == 0) and "|cff00ff96[OK]|r" or "|cffff4040[WARN]|r"
    print(string.format("|cffa335ee[SpArc Debug]|r %s %s", badge, summary))
  end
  return passed, failed, summary
end
