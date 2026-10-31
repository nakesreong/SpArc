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

SpArc.VERSION = "2.9.2"
SpArc.PROFILE_SCHEMA_VERSION = 32

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
  if not s then return "" end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
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
  showResourceBar = true,
  alwaysShowResourceBar = false,
  resourceBarWidth = 276,
  resourceBarHeight = 16,
  resourceBarOffsetX = 0,
  resourceBarOffsetY = -166,
  resourceBarScale = 1.00,
  alwaysShowCDs = false,
  enableTelemetry = true,
  showMinimapButton = true,
  minimapAngle = 205,
  enableArcHUD = true,
  enableBossRotation = true,
  enablePvPRotation = true,
  enablePressFeedback = true,
  enableCombatCamera = true,
  enableCamClickCast = true,
  showCameraCrosshair = true,
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
  autoUnshiftOutOfCombat = false,
  enableNameplates = true,
  npWidth = 140,
  npHeight = 30,
  npCastHeight = 14,
  npFontSize = 11,
  npShowQuestNPCs = true,
  npShowFriendlyPlayers = true,
  npShowHostileClassIcon = true,
  lang = "AUTO",
}

SpArc.DEFAULT_NP_AURA_RULES = {
  -- Example starter rules (Balance Druid Moonfire + Sunfire combo & single DoTs; fully editable in UI)
  { enabled = true, ids = "164812, 164815", r = 0.62, g = 0.22, b = 1.00 },
  { enabled = true, ids = "164812",         r = 0.16, g = 0.52, b = 1.00 },
  { enabled = true, ids = "164815",         r = 1.00, g = 0.58, b = 0.12 },
}

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
  mfiProcUntil = 0,
  lastStableAssistKey = nil,
  lastStableAssistID = nil,
  lastStableAssistAt = 0,
  assistCandidateKey = nil,
  assistCandidateSince = 0,
  lockedTopKey = nil,
  lockedTopCandidateKey = nil,
  lockedTopCandidateSince = 0,
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
    cachedCharKey = uName
    return cachedCharKey
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

local function EnsureProfileObject(db, profName, templateVisual, keepExplicitInteract)
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
        if existing and existing.userModified and type(existing.md) == "string" and existing.md ~= "" then
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

    local charDefaultPreset = {
      ["Ньарлатхотеп - Свежеватель Душ"] = "PRIEST_01_SHADOW_PVE",
      ["Калиратри - Свежеватель Душ"]    = "MAGE_04_FROST_PVE",
      ["Морвара - Свежеватель Душ"]      = "MAGE_04_FROST_PVE",
      ["Улак - Свежеватель Душ"]         = "ROGUE_01_ASSA_PVE",
      ["Моржовый - Свежеватель Душ"]     = "WARRIOR_02_ARGS_BOSS",
    }
    for pName, pObj in pairs(db.profiles or {}) do
      if not pObj.activePresetID or not db.presets[pObj.activePresetID] then
        local wantID = charDefaultPreset[pName] or "PRIEST_01_SHADOW_PVE"
        pObj.activePresetID = wantID
        pObj.autoPresets = { PVE = wantID, BOSS = wantID, PVP = wantID }
      end
    end
    db.profileSchemaVersion = SpArc.PROFILE_SCHEMA_VERSION
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

  if type(db.npAuraRules) ~= "table" then
    db.npAuraRules = {}
    for _, r in ipairs(SpArc.DEFAULT_NP_AURA_RULES or {}) do
      db.npAuraRules[#db.npAuraRules + 1] = {
        enabled = (r.enabled ~= false),
        ids = tostring(r.ids or ""),
        r = tonumber(r.r) or 0.2,
        g = tonumber(r.g) or 0.6,
        b = tonumber(r.b) or 1.0,
      }
    end
  end

  db.telemetryLog = db.telemetryLog or {}
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
  if SpArc.ApplyVisualLayout then SpArc:ApplyVisualLayout() end
  if SpArc.ApplyCombatCameraBindings then SpArc:ApplyCombatCameraBindings() end
  if SpArc.UpdateCameraState then SpArc:UpdateCameraState() end
  if SpArc.UpdateMinimapButtonVisibility then SpArc:UpdateMinimapButtonVisibility() end
end

function SpArc:CopyProfileFrom(srcProfileName)
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
  db.visual = curProf.visual
  if SpArc.ApplyVisualLayout then SpArc:ApplyVisualLayout() end
  if SpArc.ApplyCombatCameraBindings then SpArc:ApplyCombatCameraBindings() end
  if SpArc.UpdateCameraState then SpArc:UpdateCameraState() end
  if SpArc.UpdateMinimapButtonVisibility then SpArc:UpdateMinimapButtonVisibility() end
  return true
end

function SpArc:ResetCurrentProfile()
  local db = SpArc:EnsureDB()
  local curProfName = SpArc:GetActiveProfileName()
  db.profiles[curProfName] = {
    visual = CloneVisualTable(nil),
  }
  db.visual = db.profiles[curProfName].visual
  if SpArc.ApplyVisualLayout then SpArc:ApplyVisualLayout() end
  if SpArc.ApplyCombatCameraBindings then SpArc:ApplyCombatCameraBindings() end
  if SpArc.UpdateCameraState then SpArc:UpdateCameraState() end
  if SpArc.UpdateMinimapButtonVisibility then SpArc:UpdateMinimapButtonVisibility() end
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
    end
  end
end
