---------------------------------------------------------------------------------------
--  SpArc/Evaluator.lua — Generic .MD FSM Condition Evaluator, Queue Builder & Events
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc

local CreateFrame = _G.CreateFrame
local GetTime = _G.GetTime
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitClassification = _G.UnitClassification
local UnitLevel = _G.UnitLevel
local UnitChannelInfo = _G.UnitChannelInfo
local UnitGUID = _G.UnitGUID
local C_Spell = _G.C_Spell
local pcall = _G.pcall
local ipairs = _G.ipairs
local pairs = _G.pairs
local type = _G.type
local math = _G.math

local IsSecret = SpArc.IsSecret
local SafeBool = SpArc.SafeBool
local SPELL_DEFS = SpArc.SPELL_DEFS
local st = SpArc.state

function SpArc:SyncSpellDefsFromProfile(parsed, presetID)
  if not parsed or not parsed.spells then return end
  local changed = (presetID and st.lastSyncedPresetID ~= presetID) or false
  if changed and next(parsed.spells) ~= nil then
    for k in pairs(SPELL_DEFS) do
      if not parsed.spells[k] then
        SPELL_DEFS[k] = nil
      end
    end
  end
  for k, spDef in pairs(parsed.spells) do
    if not SPELL_DEFS[k] or changed then
      SPELL_DEFS[k] = spDef
      changed = true
    else
      local dst = SPELL_DEFS[k]
      if spDef.fillerInterruptible ~= nil then dst.fillerInterruptible = spDef.fillerInterruptible end
      if spDef.lockChannel ~= nil then dst.lockChannel = spDef.lockChannel end
      if spDef.insanityGain and spDef.insanityGain > 0 then dst.insanityGain = spDef.insanityGain end
      if spDef.insanityCost and spDef.insanityCost > 0 then dst.insanityCost = spDef.insanityCost end
      if spDef.stacksGain ~= nil then dst.stacksGain = spDef.stacksGain end
      if spDef.stacksCost ~= nil then dst.stacksCost = spDef.stacksCost end
      if spDef.consumesStacks ~= nil then dst.consumesStacks = spDef.consumesStacks end
      if spDef.overrideOf ~= nil then dst.overrideOf = spDef.overrideOf end
      if spDef.debuffIDs ~= nil then dst.debuffIDs = spDef.debuffIDs end
    end
  end
  if changed then
    st.lastSyncedPresetID = presetID
    SpArc:ScanActionSlotsAndSpells(true)
  end
end

local SPEC_ID_TO_PRESETS = {
  -- PRIEST
  [256] = { PVE = "PRIEST_08_DISC_PVE",    BOSS = "PRIEST_08_DISC_PVE",    PVP = "PRIEST_09_DISC_PVP" },
  [257] = { PVE = "PRIEST_10_HOLY_PVE",    BOSS = "PRIEST_10_HOLY_PVE",    PVP = "PRIEST_10_HOLY_PVE" },
  [258] = { PVE = "PRIEST_01_SHADOW_PVE",  BOSS = "PRIEST_02_SHADOW_BOSS", PVP = "PRIEST_03_SHADOW_PVP" },
  -- MAGE
  [62]  = { PVE = "MAGE_01_ARCANE_PVE",    BOSS = "MAGE_02_ARCANE_BOSS",   PVP = "MAGE_01_ARCANE_PVE" },
  [63]  = { PVE = "MAGE_03_FIRE_PVE",      BOSS = "MAGE_03_FIRE_PVE",      PVP = "MAGE_03_FIRE_PVE" },
  [64]  = { PVE = "MAGE_04_FROST_PVE",     BOSS = "MAGE_05_FROST_PVP",     PVP = "MAGE_05_FROST_PVP" },
  -- WARLOCK
  [265] = { PVE = "WARLOCK_01_AFF_PVE",    BOSS = "WARLOCK_02_AFF_BOSS",   PVP = "WARLOCK_01_AFF_PVE" },
  [266] = { PVE = "WARLOCK_03_DEMO_PVE",   BOSS = "WARLOCK_03_DEMO_PVE",   PVP = "WARLOCK_03_DEMO_PVE" },
  [267] = { PVE = "WARLOCK_04_DESTRO_PVE", BOSS = "WARLOCK_04_DESTRO_PVE", PVP = "WARLOCK_05_DESTRO_PVP" },
  -- PALADIN
  [65]  = { PVE = "PALADIN_01_RET_PVE",    BOSS = "PALADIN_02_RET_BOSS",   PVP = "PALADIN_03_RET_PVP" },
  [66]  = { PVE = "PALADIN_04_PROT_PVE",   BOSS = "PALADIN_04_PROT_PVE",  PVP = "PALADIN_04_PROT_PVE" },
  [70]  = { PVE = "PALADIN_01_RET_PVE",    BOSS = "PALADIN_02_RET_BOSS",   PVP = "PALADIN_03_RET_PVP" },
  -- HUNTER
  [253] = { PVE = "HUNTER_01_BM_PVE",      BOSS = "HUNTER_02_BM_BOSS",     PVP = "HUNTER_01_BM_PVE" },
  [254] = { PVE = "HUNTER_03_MM_PVE",      BOSS = "HUNTER_03_MM_PVE",      PVP = "HUNTER_03_MM_PVE" },
  [255] = { PVE = "HUNTER_04_SURV_PVP",    BOSS = "HUNTER_04_SURV_PVP",    PVP = "HUNTER_04_SURV_PVP" },
  -- ROGUE
  [259] = { PVE = "ROGUE_01_ASSA_PVE",     BOSS = "ROGUE_01_ASSA_PVE",     PVP = "ROGUE_01_ASSA_PVE" },
  [260] = { PVE = "ROGUE_02_OUTLAW_PVE",   BOSS = "ROGUE_02_OUTLAW_PVE",   PVP = "ROGUE_02_OUTLAW_PVE" },
  [261] = { PVE = "ROGUE_03_SUB_BOSS",     BOSS = "ROGUE_03_SUB_BOSS",     PVP = "ROGUE_04_SUB_PVP" },
  -- WARRIOR
  [71]  = { PVE = "WARRIOR_02_ARGS_BOSS",  BOSS = "WARRIOR_02_ARGS_BOSS",  PVP = "WARRIOR_03_ARMS_PVP" },
  [72]  = { PVE = "WARRIOR_01_FURY_PVE",   BOSS = "WARRIOR_01_FURY_PVE",   PVP = "WARRIOR_01_FURY_PVE" },
  [73]  = { PVE = "WARRIOR_04_PROT_PVE",   BOSS = "WARRIOR_04_PROT_PVE",   PVP = "WARRIOR_04_PROT_PVE" },
  -- DRUID
  [102] = { PVE = "DRUID_01_BAL_PVE",      BOSS = "DRUID_02_BAL_BOSS",     PVP = "DRUID_01_BAL_PVE" },
  [103] = { PVE = "DRUID_03_FERAL_PVE",    BOSS = "DRUID_03_FERAL_PVE",    PVP = "DRUID_04_FERAL_PVP" },
  [104] = { PVE = "DRUID_03_FERAL_PVE",    BOSS = "DRUID_03_FERAL_PVE",    PVP = "DRUID_04_FERAL_PVP" },
  [105] = { PVE = "DRUID_01_BAL_PVE",      BOSS = "DRUID_02_BAL_BOSS",     PVP = "DRUID_01_BAL_PVE" },
  -- SHAMAN
  [262] = { PVE = "SHAMAN_01_ELE_PVE",     BOSS = "SHAMAN_02_ELE_BOSS",    PVP = "SHAMAN_01_ELE_PVE" },
  [263] = { PVE = "SHAMAN_03_ENH_PVE",     BOSS = "SHAMAN_03_ENH_PVE",     PVP = "SHAMAN_04_ENH_PVP" },
  [264] = { PVE = "SHAMAN_01_ELE_PVE",     BOSS = "SHAMAN_02_ELE_BOSS",    PVP = "SHAMAN_01_ELE_PVE" },
  -- DEATH KNIGHT
  [250] = { PVE = "DK_03_BLOOD_PVE",       BOSS = "DK_03_BLOOD_PVE",       PVP = "DK_03_BLOOD_PVE" },
  [251] = { PVE = "DK_02_FROST_PVE",       BOSS = "DK_02_FROST_PVE",       PVP = "DK_02_FROST_PVE" },
  [252] = { PVE = "DK_01_UNHOLY_PVE",      BOSS = "DK_01_UNHOLY_PVE",      PVP = "DK_01_UNHOLY_PVE" },
  -- MONK
  [268] = { PVE = "MONK_03_BM_PVE",        BOSS = "MONK_03_BM_PVE",        PVP = "MONK_03_BM_PVE" },
  [269] = { PVE = "MONK_01_WW_PVE",        BOSS = "MONK_01_WW_PVE",        PVP = "MONK_02_WW_PVP" },
  [270] = { PVE = "MONK_01_WW_PVE",        BOSS = "MONK_01_WW_PVE",        PVP = "MONK_02_WW_PVP" },
  -- DEMON HUNTER
  [577] = { PVE = "DH_01_HAVOC_PVE",       BOSS = "DH_01_HAVOC_PVE",       PVP = "DH_02_HAVOC_PVP" },
  [581] = { PVE = "DH_03_VENG_PVE",        BOSS = "DH_03_VENG_PVE",        PVP = "DH_03_VENG_PVE" },
  -- EVOKER
  [1467] = { PVE = "EVOKER_01_DEV_PVE",    BOSS = "EVOKER_01_DEV_PVE",     PVP = "EVOKER_01_DEV_PVE" },
  [1468] = { PVE = "EVOKER_01_DEV_PVE",    BOSS = "EVOKER_01_DEV_PVE",     PVP = "EVOKER_01_DEV_PVE" },
  [1473] = { PVE = "EVOKER_02_AUG_PVE",    BOSS = "EVOKER_02_AUG_PVE",     PVP = "EVOKER_02_AUG_PVE" },
}

local PRESET_SPEC_IDS = {
  PRIEST_01_SHADOW_PVE      = 258,
  PRIEST_02_SHADOW_BOSS     = 258,
  PRIEST_03_SHADOW_PVP      = 258,
  PRIEST_04_SHADOW_ARCHON   = 258,
  PRIEST_05_SHADOW_VOIDWEAVER = 258,
  PRIEST_06_SHADOW_DELVES   = 258,
  PRIEST_07_SHADOW_SPEEDRUN = 258,
  PRIEST_08_DISC_PVE        = 256,
  PRIEST_09_DISC_PVP        = 256,
  PRIEST_10_HOLY_PVE        = 257,
  MAGE_01_ARCANE_PVE        = 62,
  MAGE_02_ARCANE_BOSS       = 62,
  MAGE_03_FIRE_PVE          = 63,
  MAGE_04_FROST_PVE         = 64,
  MAGE_05_FROST_PVP         = 64,
  WARLOCK_01_AFF_PVE        = 265,
  WARLOCK_02_AFF_BOSS       = 265,
  WARLOCK_03_DEMO_PVE       = 266,
  WARLOCK_04_DESTRO_PVE     = 267,
  WARLOCK_05_DESTRO_PVP     = 267,
  PALADIN_01_RET_PVE        = 70,
  PALADIN_02_RET_BOSS       = 70,
  PALADIN_03_RET_PVP        = 70,
  PALADIN_04_PROT_PVE       = 66,
  HUNTER_01_BM_PVE          = 253,
  HUNTER_02_BM_BOSS         = 253,
  HUNTER_03_MM_PVE          = 254,
  HUNTER_04_SURV_PVP        = 255,
  ROGUE_01_ASSA_PVE         = 259,
  ROGUE_02_OUTLAW_PVE       = 260,
  ROGUE_03_SUB_BOSS         = 261,
  ROGUE_04_SUB_PVP          = 261,
  WARRIOR_01_FURY_PVE       = 72,
  WARRIOR_02_ARGS_BOSS      = 71,
  WARRIOR_03_ARMS_PVP       = 71,
  WARRIOR_04_PROT_PVE       = 73,
  DRUID_01_BAL_PVE          = 102,
  DRUID_02_BAL_BOSS         = 102,
  DRUID_03_FERAL_PVE        = 103,
  DRUID_04_FERAL_PVP        = 103,
  SHAMAN_01_ELE_PVE         = 262,
  SHAMAN_02_ELE_BOSS        = 262,
  SHAMAN_03_ENH_PVE         = 263,
  SHAMAN_04_ENH_PVP         = 263,
  DK_01_UNHOLY_PVE          = 252,
  DK_02_FROST_PVE           = 251,
  DK_03_BLOOD_PVE           = 250,
  MONK_01_WW_PVE            = 269,
  MONK_02_WW_PVP            = 269,
  MONK_03_BM_PVE            = 268,
  DH_01_HAVOC_PVE           = 577,
  DH_02_HAVOC_PVP           = 577,
  DH_03_VENG_PVE            = 581,
  EVOKER_01_DEV_PVE         = 1467,
  EVOKER_02_AUG_PVE         = 1473,
}

local lastValidSpecID = nil

function SpArc:GetPlayerSpecID()
  local getSpec = (_G.C_SpecializationInfo and _G.C_SpecializationInfo.GetSpecialization) or _G.GetSpecialization
  local getSpecInfo = (_G.C_SpecializationInfo and _G.C_SpecializationInfo.GetSpecializationInfo) or _G.GetSpecializationInfo
  if getSpec and getSpecInfo then
    local okS, specIdx = pcall(getSpec)
    if okS and not IsSecret(specIdx) and type(specIdx) == "number" and specIdx > 0 and specIdx < 5 then
      local okI, specID = pcall(getSpecInfo, specIdx)
      if okI and not IsSecret(specID) and type(specID) == "number" and specID > 0 then
        lastValidSpecID = specID
        return specID
      end
    end
  end
  if _G.GetSpecialization and _G.GetSpecializationInfo then
    local okS, specIdx = pcall(_G.GetSpecialization)
    if okS and not IsSecret(specIdx) and type(specIdx) == "number" and specIdx > 0 and specIdx < 5 then
      local okI, specID = pcall(_G.GetSpecializationInfo, specIdx)
      if okI and not IsSecret(specID) and type(specID) == "number" and specID > 0 then
        lastValidSpecID = specID
        return specID
      end
    end
  end
  return lastValidSpecID
end

function SpArc:SelectActiveParsedProfile()
  local db = SpArc:EnsureDB()
  if UnitIsDeadOrGhost and SafeBool(UnitIsDeadOrGhost, "player") and st.lastSyncedPresetID then
    local cachedParsed = SpArc.ParsedPresets and SpArc.ParsedPresets[st.lastSyncedPresetID]
    if cachedParsed then
      return cachedParsed, st.lastSyncedPresetID
    end
  end
  local mode = db.mode or "AUTO"
  local presetID = db.activePresetID or "PRIEST_01_SHADOW_PVE"
  local targetMode = "PVE"

  if mode == "AUTO" then
    if SafeBool(UnitIsPlayer, "target") then
      targetMode = "PVP"
      presetID = (db.autoPresets and db.autoPresets.PVP) or "PRIEST_03_SHADOW_PVP"
    else
      local okC, classif = pcall(UnitClassification, "target")
      local okL, lvl = pcall(UnitLevel, "target")
      if (okC and not IsSecret(classif) and (classif == "worldboss" or classif == "rareelite" or classif == "elite"))
        or (okL and not IsSecret(lvl) and lvl == -1) then
        targetMode = "BOSS"
        presetID = (db.autoPresets and db.autoPresets.BOSS) or "PRIEST_02_SHADOW_BOSS"
      else
        targetMode = "PVE"
        presetID = (db.autoPresets and db.autoPresets.PVE) or "PRIEST_01_SHADOW_PVE"
      end
    end
  elseif mode == "PVE" or mode == "BOSS" or mode == "PVP" then
    targetMode = mode
    presetID = (db.autoPresets and db.autoPresets[mode]) or presetID
  end

  local specID = SpArc:GetPlayerSpecID()
  local specMap = specID and SPEC_ID_TO_PRESETS[specID] or nil

  if _G.UnitClass then
    local okCls, _, playerClass = pcall(_G.UnitClass, "player")
    if okCls and not IsSecret(playerClass) and type(playerClass) == "string" then
      local curPreset = db.presets and db.presets[presetID]
      local presetSpec = PRESET_SPEC_IDS[presetID]
      local specMismatch = (specMap and presetSpec and presetSpec ~= specID) or false

      if not curPreset or curPreset.class ~= playerClass or specMismatch then
        if specMap then
          db.autoPresets = db.autoPresets or {}
          db.autoPresets.PVE  = specMap.PVE
          db.autoPresets.BOSS = specMap.BOSS
          db.autoPresets.PVP  = specMap.PVP
          presetID = specMap[targetMode] or specMap.PVE
          db.activePresetID = presetID
          if SpArc.SaveCharPresetState then SpArc:SaveCharPresetState(db) end
        else
          local fallbackID = nil
          for _, id in ipairs(db.presetOrder or {}) do
            local p = db.presets and db.presets[id]
            if p and p.class == playerClass then
              if not fallbackID then fallbackID = id end
              if p.mode == targetMode then
                fallbackID = id
                break
              end
            end
          end
          if fallbackID then
            -- Use fallbackID temporarily while specID is nil, without overwriting SavedVariables
            presetID = fallbackID
          end
        end
      elseif mode == "AUTO" then
        db.activePresetID = presetID
        if SpArc.SaveCharPresetState then SpArc:SaveCharPresetState(db) end
      else
        if SpArc.SaveCharPresetState then SpArc:SaveCharPresetState(db) end
      end
    end
  end

  local parsed = (SpArc.ParsedPresets and SpArc.ParsedPresets[presetID])
    or (SpArc.ParsedPresets and SpArc.ParsedPresets["PRIEST_01_SHADOW_PVE"])
  SpArc:SyncSpellDefsFromProfile(parsed, presetID)
  return parsed, presetID
end

local function CompareNum(lhs, op, rhs)
  if op == ">=" then return lhs >= rhs
  elseif op == "<=" then return lhs <= rhs
  elseif op == "==" or op == "=" then return lhs == rhs
  elseif op == ">" then return lhs > rhs
  elseif op == "<" then return lhs < rhs
  end
  return false
end

local function EvalAtomicClause(c, simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges)
  if c == "" or c == "ALWAYS" then
    return true
  elseif c == "NOT target.has_dots" then
    return not simHasDoTs
  elseif c == "target.has_dots" then
    return simHasDoTs and true or false
  end

  local readySp = c:match("^READY%(([A-Z0-9_]+)%)$")
  if readySp then
    return simReady[readySp] and true or false
  end

  local notReadySp = c:match("^NOT%s+READY%(([A-Z0-9_]+)%)$")
  if notReadySp then
    return not simReady[notReadySp]
  end

  local usableSp = c:match("^USABLE%(([A-Z0-9_]+)%)$")
  if usableSp then
    return (simReady[usableSp] and simUsable[usableSp]) and true or false
  end

  local procSp = c:match("^PROC%(([A-Z0-9_]+)%)$")
  if procSp then
    local pKey = (procSp == "VOID_BLAST") and "MIND_BLAST" or procSp
    return simProcs[pKey] and true or false
  end

  local notProcSp = c:match("^NOT%s+PROC%(([A-Z0-9_]+)%)$")
  if notProcSp then
    local pKey = (notProcSp == "VOID_BLAST") and "MIND_BLAST" or notProcSp
    return not simProcs[pKey]
  end

  local chSp, chOp, chVal = c:match("^CHARGES%(([A-Z0-9_]+)%)%s*([><=]+)%s*(%d+)$")
  if chSp and chOp and chVal then
    local curCh = (simCharges and simCharges[chSp]) or 0
    return CompareNum(curCh, chOp, tonumber(chVal) or 0)
  end

  local stOp, stVal = c:match("^target%.freezing_stacks%s*([><=]+)%s*(%d+)$")
  if not stOp then
    stOp, stVal = c:match("^target%.debuff_stacks%s*([><=]+)%s*(%d+)$")
  end
  if not stOp then
    stOp, stVal = c:match("^target%.shatter_stacks%s*([><=]+)%s*(%d+)$")
  end
  if not stOp then
    stOp, stVal = c:match("^STACKS%s*([><=]+)%s*(%d+)$")
  end
  if stOp and stVal then
    return CompareNum(simStacks or 0, stOp, tonumber(stVal) or 0)
  end

  return true
end

local compiledCondCache = {}

local function GetCompiledConditionBranches(condStr)
  local cached = compiledCondCache[condStr]
  if cached then
    return cached
  end
  local branches = {}
  local orNorm = condStr:gsub("%s+OR%s+", "\2")
  for orBranch in orNorm:gmatch("([^\2]+)") do
    local clauses = {}
    local andNorm = orBranch:gsub("%s+AND%s+", "\1")
    for rawClause in andNorm:gmatch("([^\1]+)") do
      local c = rawClause:gsub("^%s+", ""):gsub("%s+$", "")
      if c ~= "" then
        clauses[#clauses + 1] = c
      end
    end
    if #clauses > 0 then
      branches[#branches + 1] = clauses
    end
  end
  compiledCondCache[condStr] = branches
  return branches
end

function SpArc:EvalSingleCondition(condStr, simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges)
  if not condStr or condStr == "ALWAYS" then
    return true
  end
  local branches = GetCompiledConditionBranches(condStr)
  for i = 1, #branches do
    local clauses = branches[i]
    local branchOk = true
    for j = 1, #clauses do
      if not EvalAtomicClause(clauses[j], simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges) then
        branchOk = false
        break
      end
    end
    if branchOk then
      return true
    end
  end
  return false
end

function SpArc:GetActiveChannelDefKey(now)
  if UnitChannelInfo then
    local ok, n = pcall(UnitChannelInfo, "player")
    if ok and not IsSecret(n) and type(n) == "string" and n ~= "" then
      local k = SpArc:MatchSpellToDefKey(nil, n)
      if k then return k end
    end
  end
  if st.castState.active and st.castState.isChannel and now < st.castState.endTime then
    return st.castState.defKey
  end
  if SpArc.testMode and (now % 6) >= 3 then
    return "MIND_FLAY"
  end
  return nil
end

local reusableStates = {}
local reusableQueue = {}
local simReady = {}
local simUsable = {}
local simProcs = {}
local simCharges = {}
local simCD = {}
local simKnown = {}
local EMPTY_TABLE = {}

function SpArc:BuildRotationQueue(maxSlots)
  local db = SpArc:EnsureDB()
  maxSlots = maxSlots or (db.visual and db.visual.queueLength) or 5
  SpArc:RefreshTrackedInsanity()
  local assistedKey = SpArc:GetAssistedSuggestedDefKey()
  if assistedKey == "DEVOURING_PLAGUE" and st.trackedInsanity < 50 then
    st.trackedInsanity = 55
  end

  local parsed = SpArc:SelectActiveParsedProfile()
  if not parsed or not parsed.rules then
    return EMPTY_TABLE, EMPTY_TABLE, parsed, nil, false, false
  end

  local states = reusableStates
  for k in pairs(states) do
    if not SPELL_DEFS[k] then
      states[k] = nil
      simReady[k] = nil
      simUsable[k] = nil
      simProcs[k] = nil
      simCharges[k] = nil
      simCD[k] = nil
      simKnown[k] = nil
    end
  end

  for k, def in pairs(SPELL_DEFS) do
    local isReady, remSec, durSec, startTime, isUsable, isProc, icon, keybind, charges, isUnavailable = SpArc:EvaluateSpellState(k, assistedKey)
    local sObj = states[k]
    if not sObj then
      sObj = {}
      states[k] = sObj
    end
    sObj.key = k
    sObj.isReady = isReady
    sObj.remSec = remSec
    sObj.durSec = durSec
    sObj.startTime = startTime
    sObj.isUsable = isUsable
    sObj.isProc = isProc
    sObj.isUnavailable = isUnavailable or false
    sObj.icon = icon
    sObj.keybind = keybind
    sObj.charges = charges

    local known = (not isUnavailable) and (def.isKnown or def.slot ~= nil or SpArc.testMode) and true or false
    simKnown[k] = known
    if not known then
      simCD[k] = 9999
    elseif isReady then
      simCD[k] = 0
    elseif def.procOnly and not isProc then
      simCD[k] = 9999
    elseif remSec and remSec > 0 then
      simCD[k] = remSec
    else
      simCD[k] = (def.baseCD and def.baseCD > 0) and def.baseCD or 9999
    end
    simReady[k] = (simCD[k] <= 0.05)
    simUsable[k] = isUsable
    simProcs[k] = isProc
    simCharges[k] = charges or (isReady and 1 or 0)
  end

  local queue = reusableQueue
  local qCount = 0
  local simHasDoTs = SpArc:CheckTargetHasDoTs(assistedKey)
  local simStacks = (SpArc.GetTargetDebuffStacks and SpArc:GetTargetDebuffStacks(parsed, assistedKey)) or 0
  if states["DEVOURING_PLAGUE"] and not states["DEVOURING_PLAGUE"].isUsable then
    st.trackedInsanity = math.min(st.trackedInsanity, 25)
  elseif states["DEVOURING_PLAGUE"] and states["DEVOURING_PLAGUE"].isUsable and st.trackedInsanity < 50 then
    st.trackedInsanity = 50
  else
    local cpSpender = states["ENVENOM"] or states["RUPTURE"]
    if cpSpender and not cpSpender.isUnavailable then
      if not cpSpender.isUsable and st.trackedInsanity >= 80 then
        st.trackedInsanity = 40
      elseif cpSpender.isUsable and st.trackedInsanity < 80 then
        st.trackedInsanity = 80
      end
    end
  end
  local simInsanity = st.trackedInsanity

  for step = 1, maxSlots do
    for spK, spD in pairs(SPELL_DEFS) do
      simReady[spK] = simKnown[spK] and (simCD[spK] <= 0.05) or false
      if step > 1 and simReady[spK] and not spD.procOnly and not spD.isExecute and not spD.isSpender then
        simUsable[spK] = true
      end
    end

    local pickedKey = nil
    for _, rule in ipairs(parsed.rules) do
      local sp = rule.spell
      if simReady[sp] and simUsable[sp] then
        if SpArc:EvalSingleCondition(rule.cond, simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges) then
          pickedKey = sp
          break
        end
      end
    end

    -- Lookahead fallback: if all known spells are currently on short cooldowns, advance to the earliest upcoming spell
    if not pickedKey then
      local bestSp = nil
      local bestRem = 9000
      for _, rule in ipairs(parsed.rules) do
        local sp = rule.spell
        local spD = SPELL_DEFS[sp]
        if simKnown[sp] and spD and not spD.procOnly and not spD.isExecute and not spD.isSpender and not spD.consumesStacks then
          local rem = simCD[sp] or 9999
          if rem < bestRem then
            bestRem = rem
            bestSp = sp
          end
        end
      end
      if bestSp and bestRem < 9000 then
        for spK, _ in pairs(SPELL_DEFS) do
          if simCD[spK] and simCD[spK] < 9000 then
            simCD[spK] = math.max(0, simCD[spK] - bestRem)
          end
        end
        simReady[bestSp] = true
        simUsable[bestSp] = true
        pickedKey = bestSp
      elseif #parsed.rules > 0 then
        for i = #parsed.rules, 1, -1 do
          local fallbackSp = parsed.rules[i].spell
          if simKnown[fallbackSp] then
            pickedKey = fallbackSp
            break
          end
        end
      end
    end

    if pickedKey and states[pickedKey] and not states[pickedKey].isUnavailable then
      local s = states[pickedKey]
      local def = SPELL_DEFS[pickedKey]
      qCount = qCount + 1
      local qItem = queue[qCount]
      if not qItem then
        qItem = {}
        queue[qCount] = qItem
      end
      qItem.key = pickedKey
      qItem.icon = s.icon
      qItem.keybind = s.keybind
      qItem.isProc = (step == 1 and s.isProc) or false
      qItem.isReady = (step == 1) and s.isReady or true
      qItem.isUsable = (step == 1) and s.isUsable or true
      qItem.isUnavailable = s.isUnavailable or false

      local pickedWasProc = simProcs[pickedKey]
      simProcs[pickedKey] = false
      if def then
        if def.appliesDoTs then simHasDoTs = true end
        if def.insanityGain then simInsanity = math.min(100, simInsanity + def.insanityGain) end
        if def.insanityCost then simInsanity = math.max(0, simInsanity - def.insanityCost) end
        if def.grantsProc and SPELL_DEFS[def.grantsProc] then
          simProcs[def.grantsProc] = true
          simCD[def.grantsProc] = 0
          simReady[def.grantsProc] = true
          simUsable[def.grantsProc] = true
        end
        if def.grantsMFI and SPELL_DEFS["MIND_FLAY_INSANITY"] then
          simProcs["MIND_FLAY_INSANITY"] = true
          simCD["MIND_FLAY_INSANITY"] = 0
          simReady["MIND_FLAY_INSANITY"] = true
          simUsable["MIND_FLAY_INSANITY"] = true
        end
        if def.consumesStacks and not pickedWasProc then
          local cost = (def.stacksCost and def.stacksCost > 0) and def.stacksCost or 4
          simStacks = math.max(0, (simStacks or 0) - cost)
        end
        if def.stacksGain and def.stacksGain > 0 then
          simStacks = math.min(20, (simStacks or 0) + def.stacksGain)
        end
        if def.procOnly or def.isSpender or def.isExecute then
          simCD[pickedKey] = 9999
          simReady[pickedKey] = false
          simUsable[pickedKey] = false
        elseif (def.liveMaxCharges or def.maxCharges or 1) > 1 then
          simCharges[pickedKey] = (simCharges[pickedKey] or 1) - 1
          if simCharges[pickedKey] <= 0 then
            simCD[pickedKey] = def.liveChargeCD or def.baseCD or 7.5
            simReady[pickedKey] = false
          elseif def.baseCD and def.baseCD > 1.6 then
            simCD[pickedKey] = 1.4
            simReady[pickedKey] = false
          end
        elseif def.baseCD and def.baseCD > 0 then
          simCD[pickedKey] = def.baseCD
          simReady[pickedKey] = false
        elseif def.fillerInterruptible and pickedKey == "MIND_FLAY" then
          simCD[pickedKey] = 4.5
          simReady[pickedKey] = false
        else
          simCD[pickedKey] = 0
        end
      end

      for spK, _ in pairs(SPELL_DEFS) do
        if simCD[spK] and simCD[spK] < 9000 then
          simCD[spK] = math.max(0, simCD[spK] - 1.4)
        end
      end

      for spK, spD in pairs(SPELL_DEFS) do
        if spD.isSpender and spD.insanityCost then
          local canAfford = simInsanity >= spD.insanityCost
          simUsable[spK] = canAfford
          if canAfford then
            simCD[spK] = 0
            simReady[spK] = true
          end
        end
      end
    end
  end

  for i = qCount + 1, #queue do
    queue[i] = nil
  end

  local now = GetTime()
  local activeChannelKey = SpArc:GetActiveChannelDefKey(now)
  local shouldInterruptChannel = false
  local isProtectedChannel = false

  if activeChannelKey then
    local isInterruptibleFiller = (parsed.interruptibleChannels and parsed.interruptibleChannels[activeChannelKey])
      or (SPELL_DEFS[activeChannelKey] and SPELL_DEFS[activeChannelKey].fillerInterruptible)
    local isProtected = (parsed.protectedChannels and parsed.protectedChannels[activeChannelKey])
      or (SPELL_DEFS[activeChannelKey] and SPELL_DEFS[activeChannelKey].lockChannel)

    if isProtected then
      isProtectedChannel = true
    elseif isInterruptibleFiller and queue[1] and queue[1].key ~= activeChannelKey then
      shouldInterruptChannel = true
    end
  end

  return queue, states, parsed, activeChannelKey, shouldInterruptChannel, isProtectedChannel
end

function SpArc:RecordSpellCastSuccess(defKey, now)
  if not defKey then return end
  st.lastCastAt[defKey] = now
  local def = SPELL_DEFS[defKey]
  if not def then return end
  if def.appliesDoTs then
    st.targetDoTsUntil = now + 21.0
  end
  if def.insanityGain then
    st.trackedInsanity = math.min(100, st.trackedInsanity + def.insanityGain)
  end
  if def.insanityCost then
    st.trackedInsanity = math.max(0, st.trackedInsanity - def.insanityCost)
  end
  if def.grantsMFI then
    st.mfiProcUntil = now + 10.0
  end
  if defKey == "MIND_FLAY_INSANITY" then
    st.mfiProcUntil = 0
  end
  local lastAudit = st.lastSpellAudit and st.lastSpellAudit[defKey]
  local castWasProc = (lastAudit and lastAudit.isProc) or false
  if def.consumesStacks and not castWasProc then
    local cost = (def.stacksCost and def.stacksCost > 0) and def.stacksCost or 4
    st.targetDebuffStacks = math.max(0, (st.targetDebuffStacks or 0) - cost)
  end
  if def.stacksGain and def.stacksGain > 0 then
    st.targetDebuffStacks = math.min(20, (st.targetDebuffStacks or 0) + def.stacksGain)
    st.targetDebuffUntil = now + 15.0
  end
  local maxCh = def.liveMaxCharges or def.maxCharges or 1
  if maxCh > 1 or defKey == "MIND_BLAST" or defKey == "TENTACLE_SLAM" or defKey == "FLURRY" then
    SpArc:GetTrackedSpellCharges(defKey, now)
    local used = st.spellChargesUsed[defKey] or 0
    if used == 0 then
      st.spellChargeStart[defKey] = now
    end
    st.spellChargesUsed[defKey] = math.min(maxCh, used + 1)
  end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
eventFrame:RegisterEvent("UPDATE_MACROS")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")

eventFrame:SetScript("OnEvent", function(_, event, unit, arg2, arg3, arg4)
  local castGUID, spellID = arg2, arg3
  if event == "UNIT_SPELLCAST_SENT" then
    if unit ~= "player" then return end
    spellID = arg4
    if spellID and not IsSecret(spellID) then
      local defKey = SpArc:MatchSpellToDefKey(spellID, nil)
      if defKey and SpArc.TriggerSpellPress then
        SpArc:TriggerSpellPress(defKey, nil, nil)
      end
    end
    return
  end
  if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
    if SpArc.EnableAssistedCombatEngine then SpArc.EnableAssistedCombatEngine() end
    SpArc:RebuildParsedProfiles()
    if SpArc.ApplyVisualLayout then SpArc:ApplyVisualLayout() end
    if SpArc.ApplySmartBossTabBinding then SpArc:ApplySmartBossTabBinding() end
    SpArc:ScanActionSlotsAndSpells(true)
    return
  end

  if event == "PLAYER_REGEN_ENABLED" then
    if SpArc.ApplySmartBossTabBinding then SpArc:ApplySmartBossTabBinding() end
    return
  end

  if event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" or event == "UPDATE_MACROS" or event == "UPDATE_BINDINGS" or event == "SPELLS_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_FLAGS_CHANGED" then
    if event == "UPDATE_BINDINGS" and SpArc.ApplySmartBossTabBinding then
      SpArc:ApplySmartBossTabBinding()
    end
    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
      st.lastSyncedPresetID = nil
      SpArc:SelectActiveParsedProfile()
    end
    SpArc:ScanActionSlotsAndSpells(true)
    return
  end

  if event == "PLAYER_TARGET_CHANGED" then
    local okG, guid = pcall(UnitGUID, "target")
    local newGUID = (okG and not IsSecret(guid) and guid) or nil
    if not newGUID or newGUID ~= st.lastTargetGUID then
      st.targetDoTsUntil = 0
      st.targetDebuffStacks = 0
      st.targetDebuffUntil = 0
      st.lastCastAt["GARROTE"] = nil
      st.lastTargetGUID = newGUID
    end
    return
  end

  local now = GetTime()
  local sName, sIcon, sCastMS
  if spellID and not IsSecret(spellID) and C_Spell and C_Spell.GetSpellInfo then
    local okI, info = pcall(C_Spell.GetSpellInfo, spellID)
    if okI and type(info) == "table" then
      sName = not IsSecret(info.name) and info.name or nil
      sIcon = not IsSecret(info.iconID) and info.iconID or nil
      sCastMS = not IsSecret(info.castTime) and info.castTime or nil
    end
  end

  if event == "UNIT_SPELLCAST_START" then
    local defKey = SpArc:MatchSpellToDefKey(spellID, sName)
    if defKey then
      st.lastHardCastStartAt = st.lastHardCastStartAt or {}
      st.lastHardCastStartAt[defKey] = now
      if SpArc.TriggerSpellPress then
        SpArc:TriggerSpellPress(defKey, nil, nil)
      end
    end
    local dur = (sCastMS and sCastMS > 0 and (sCastMS / 1000)) or 1.4
    st.castState.active = true
    st.castState.isChannel = false
    st.castState.defKey = defKey
    st.castState.name = sName or "Заклинание"
    st.castState.icon = sIcon or 136208
    st.castState.startTime = now
    st.castState.endTime = now + dur
  elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
    local defKey = SpArc:MatchSpellToDefKey(spellID, sName)
    if defKey then
      st.lastHardCastStartAt = st.lastHardCastStartAt or {}
      st.lastHardCastStartAt[defKey] = now
      if SpArc.TriggerSpellPress then
        SpArc:TriggerSpellPress(defKey, nil, nil)
      end
    end
    local dur = (defKey == "RAY_OF_FROST") and 4.0 or ((defKey == "VOID_TORRENT") and 3.0 or 2.8)
    st.castState.active = true
    st.castState.isChannel = true
    st.castState.defKey = defKey
    st.castState.name = sName or "Поток"
    st.castState.icon = sIcon or 136208
    st.castState.startTime = now
    st.castState.endTime = now + dur
    if defKey then
      SpArc:RecordSpellCastSuccess(defKey, now)
    end
  elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
    st.castState.active = false
    st.castState.defKey = nil
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    local defKey = SpArc:MatchSpellToDefKey(spellID, sName)
    local wasHardCast = defKey and st.lastHardCastStartAt and st.lastHardCastStartAt[defKey] and (now - st.lastHardCastStartAt[defKey]) < 4.5
    if wasHardCast then
      st.lastHardCastStartAt[defKey] = nil
    elseif defKey and SpArc.TriggerSpellPress then
      SpArc:TriggerSpellPress(defKey, nil, nil)
    end
    local d = defKey and SPELL_DEFS[defKey]
    local isChan = d and (d.lockChannel or d.fillerInterruptible)
    if defKey and not isChan and defKey ~= "VOID_TORRENT" and defKey ~= "MIND_FLAY" and defKey ~= "MIND_FLAY_INSANITY" and defKey ~= "RAY_OF_FROST" then
      SpArc:RecordSpellCastSuccess(defKey, now)
    end
  end
end)
