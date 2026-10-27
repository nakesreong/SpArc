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
  for k in pairs(SPELL_DEFS) do
    if not parsed.spells[k] then
      SPELL_DEFS[k] = nil
      changed = true
    end
  end
  for k, spDef in pairs(parsed.spells) do
    if not SPELL_DEFS[k] or changed then
      SPELL_DEFS[k] = spDef
      changed = true
    else
      local dst = SPELL_DEFS[k]
      dst.ids = spDef.ids
      dst.names = spDef.names
      dst.fallbackIcon = spDef.fallbackIcon
      dst.baseCD = spDef.baseCD
      dst.maxCharges = spDef.maxCharges
      dst.procOnly = spDef.procOnly
      dst.isSpender = spDef.isSpender
      dst.isExecute = spDef.isExecute
      dst.requiresUsable = spDef.requiresUsable
      dst.appliesDoTs = spDef.appliesDoTs
      dst.grantsProc = spDef.grantsProc
      dst.grantsMFI = spDef.grantsMFI
      dst.fillerInterruptible = spDef.fillerInterruptible
      dst.lockChannel = spDef.lockChannel
      dst.insanityGain = spDef.insanityGain
      dst.insanityCost = spDef.insanityCost
      dst.stacksGain = spDef.stacksGain
      dst.stacksCost = spDef.stacksCost
      dst.consumesStacks = spDef.consumesStacks
      dst.overrideOf = spDef.overrideOf
      dst.debuffIDs = spDef.debuffIDs
      dst.burstDuration = spDef.burstDuration
    end
  end
  if changed then
    st.lastSyncedPresetID = presetID
    SpArc:ScanActionSlotsAndSpells(true)
  end
end

local SPEC_ID_TO_PRESETS = {
  -- PRIEST (Shadow)
  [256] = { PVE = "PRIEST_01_SHADOW_PVE",  BOSS = "PRIEST_01_SHADOW_PVE",  PVP = "PRIEST_01_SHADOW_PVE" },
  [257] = { PVE = "PRIEST_01_SHADOW_PVE",  BOSS = "PRIEST_01_SHADOW_PVE",  PVP = "PRIEST_01_SHADOW_PVE" },
  [258] = { PVE = "PRIEST_01_SHADOW_PVE",  BOSS = "PRIEST_01_SHADOW_PVE",  PVP = "PRIEST_01_SHADOW_PVE" },
  -- MAGE (Frost)
  [62]  = { PVE = "MAGE_04_FROST_PVE",     BOSS = "MAGE_04_FROST_PVE",     PVP = "MAGE_04_FROST_PVE" },
  [63]  = { PVE = "MAGE_04_FROST_PVE",     BOSS = "MAGE_04_FROST_PVE",     PVP = "MAGE_04_FROST_PVE" },
  [64]  = { PVE = "MAGE_04_FROST_PVE",     BOSS = "MAGE_04_FROST_PVE",     PVP = "MAGE_04_FROST_PVE" },
  -- ROGUE (Assassination)
  [259] = { PVE = "ROGUE_01_ASSA_PVE",     BOSS = "ROGUE_01_ASSA_PVE",     PVP = "ROGUE_01_ASSA_PVE" },
  [260] = { PVE = "ROGUE_01_ASSA_PVE",     BOSS = "ROGUE_01_ASSA_PVE",     PVP = "ROGUE_01_ASSA_PVE" },
  [261] = { PVE = "ROGUE_01_ASSA_PVE",     BOSS = "ROGUE_01_ASSA_PVE",     PVP = "ROGUE_01_ASSA_PVE" },
  -- WARRIOR (Arms)
  [71]  = { PVE = "WARRIOR_02_ARGS_BOSS",  BOSS = "WARRIOR_02_ARGS_BOSS",  PVP = "WARRIOR_02_ARGS_BOSS" },
  [72]  = { PVE = "WARRIOR_02_ARGS_BOSS",  BOSS = "WARRIOR_02_ARGS_BOSS",  PVP = "WARRIOR_02_ARGS_BOSS" },
  [73]  = { PVE = "WARRIOR_02_ARGS_BOSS",  BOSS = "WARRIOR_02_ARGS_BOSS",  PVP = "WARRIOR_02_ARGS_BOSS" },
}

local PRESET_SPEC_IDS = {
  PRIEST_01_SHADOW_PVE = 258,
  MAGE_04_FROST_PVE    = 64,
  ROGUE_01_ASSA_PVE    = 259,
  WARRIOR_02_ARGS_BOSS = 71,
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

  if mode == "AUTO" and _G.UnitClass then
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
            presetID = fallbackID
          end
        end
      else
        db.activePresetID = presetID
        if SpArc.SaveCharPresetState then SpArc:SaveCharPresetState(db) end
      end
    end
  elseif mode ~= "AUTO" then
    if SpArc.SaveCharPresetState then SpArc:SaveCharPresetState(db) end
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

local function EvalAtomicClause(c, simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges, simBurst, simActive, simCtx)
  if c == "" or c == "ALWAYS" then
    return true
  elseif c == "NOT target.has_dots" then
    return not simHasDoTs
  elseif c == "target.has_dots" then
    return simHasDoTs and true or false
  elseif c == "player.in_burst" or c == "BURST" then
    return simBurst and true or false
  elseif c == "NOT player.in_burst" or c == "NOT BURST" then
    return not simBurst
  elseif c == "player.stealthed" or c == "STEALTH" then
    return (simCtx and simCtx.stealthed) and true or false
  elseif c == "NOT player.stealthed" or c == "NOT STEALTH" then
    return not (simCtx and simCtx.stealthed)
  elseif c == "player.in_combat" or c == "COMBAT" then
    return (simCtx and simCtx.inCombat) and true or false
  elseif c == "NOT player.in_combat" or c == "NOT COMBAT" then
    return not (simCtx and simCtx.inCombat)
  elseif c == "target.can_pick_pocket" or c == "PICK_POCKET_READY" then
    return (simCtx and simCtx.canPickPocket) and true or false
  elseif c == "NOT target.can_pick_pocket" then
    return not (simCtx and simCtx.canPickPocket)
  elseif c == "AOE" then
    return ((simCtx and simCtx.enemies) or 1) >= 3
  elseif c == "NOT AOE" then
    return ((simCtx and simCtx.enemies) or 1) < 3
  elseif c == "CLEAVE" then
    return ((simCtx and simCtx.enemies) or 1) >= 2
  elseif c == "SINGLE_TARGET" then
    return ((simCtx and simCtx.enemies) or 1) <= 1
  end

  local activeSp = c:match("^ACTIVE%(([A-Z0-9_]+)%)$")
  if activeSp then
    return (simActive and simActive[activeSp]) and true or false
  end

  local notActiveSp = c:match("^NOT%s+ACTIVE%(([A-Z0-9_]+)%)$")
  if notActiveSp then
    return not (simActive and simActive[notActiveSp])
  end

  local buffSp = c:match("^BUFF%(([A-Z0-9_]+)%)$")
  if buffSp then
    return (simCtx and simCtx.buffs and simCtx.buffs[buffSp]) and true or false
  end

  local notBuffSp = c:match("^NOT%s+BUFF%(([A-Z0-9_]+)%)$")
  if notBuffSp then
    return not (simCtx and simCtx.buffs and simCtx.buffs[notBuffSp])
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

  local enOp, enVal = c:match("^enemies%s*([><=]+)%s*(%d+)$")
  if not enOp then enOp, enVal = c:match("^enemies_around%s*([><=]+)%s*(%d+)$") end
  if not enOp then enOp, enVal = c:match("^active_enemies%s*([><=]+)%s*(%d+)$") end
  if not enOp then enOp, enVal = c:match("^player%.enemies%s*([><=]+)%s*(%d+)$") end
  if not enOp then enOp, enVal = c:match("^target%.enemies%s*([><=]+)%s*(%d+)$") end
  if enOp and enVal then
    local curEnemies = (simCtx and simCtx.enemies) or 1
    return CompareNum(curEnemies, enOp, tonumber(enVal) or 0)
  end

  local cpOp, cpVal = c:match("^player%.combo_points%s*([><=]+)%s*(%d+)$")
  if not cpOp then cpOp, cpVal = c:match("^COMBO_POINTS%s*([><=]+)%s*(%d+)$") end
  if not cpOp then cpOp, cpVal = c:match("^cp%s*([><=]+)%s*(%d+)$") end
  if cpOp and cpVal then
    local curCP = (simCtx and simCtx.comboPoints) or 0
    return CompareNum(curCP, cpOp, tonumber(cpVal) or 0)
  end

  local pHpOp, pHpVal = c:match("^player%.hp_percent%s*([><=]+)%s*(%d+)$")
  if pHpOp and pHpVal then
    local curPHP = (simCtx and simCtx.playerHP) or 100
    return CompareNum(curPHP, pHpOp, tonumber(pHpVal) or 0)
  end

  local tHpOp, tHpVal = c:match("^target%.hp_percent%s*([><=]+)%s*(%d+)$")
  if tHpOp and tHpVal then
    local curTHP = (simCtx and simCtx.targetHP) or 100
    return CompareNum(curTHP, tHpOp, tonumber(tHpVal) or 0)
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

function SpArc:EvalSingleCondition(condStr, simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges, simBurst, simActive, simCtx)
  if not condStr or condStr == "ALWAYS" then
    return true
  end
  local branches = GetCompiledConditionBranches(condStr)
  for i = 1, #branches do
    local clauses = branches[i]
    local branchOk = true
    for j = 1, #clauses do
      if not EvalAtomicClause(clauses[j], simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges, simBurst, simActive, simCtx) then
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
local simActive = {}
local simNoResource = {}
local simBuffs = {}
local simCtx = { buffs = simBuffs }
local EMPTY_TABLE = {}

function SpArc:BuildRotationQueue(maxSlots)
  local db = SpArc:EnsureDB()
  local now = GetTime()
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
      simActive[k] = nil
      simNoResource[k] = nil
      simBuffs[k] = nil
    end
  end

  for k, def in pairs(SPELL_DEFS) do
    local isReady, remSec, durSec, startTime, isUsable, isProc, icon, keybind, charges, isUnavailable, isNoResource, resWaitSec, isOutOfRange = SpArc:EvaluateSpellState(k, assistedKey)
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
    sObj.isNoResource = isNoResource or false
    sObj.resWaitSec = resWaitSec or 0
    sObj.isOutOfRange = isOutOfRange or false
    sObj.isProc = isProc
    sObj.isUnavailable = isUnavailable or false
    sObj.icon = icon
    sObj.keybind = keybind
    sObj.charges = charges

    local known = (not isUnavailable) and true or false
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
    simActive[k] = (SpArc.IsSpellBurstActive and SpArc:IsSpellBurstActive(k, sObj, now)) or false
    simNoResource[k] = isNoResource or false
    simBuffs[k] = (SpArc.PlayerHasBuff and SpArc:PlayerHasBuff(k, now)) or false
  end

  local queue = reusableQueue
  local qCount = 0
  local simHasDoTs = SpArc:CheckTargetHasDoTs(assistedKey)
  local simStacks = (SpArc.GetTargetDebuffStacks and SpArc:GetTargetDebuffStacks(parsed, assistedKey)) or 0
  local simBurst = (SpArc.IsPlayerInBurst and SpArc:IsPlayerInBurst(states, now)) or false
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

  simCtx.enemies = (SpArc.GetNearbyEnemyCount and SpArc:GetNearbyEnemyCount(now, assistedKey)) or 1
  simCtx.stealthed = (_G.IsStealthed and SafeBool(_G.IsStealthed)) or false
  simCtx.inCombat = (_G.InCombatLockdown and SafeBool(_G.InCombatLockdown)) or (_G.UnitAffectingCombat and SafeBool(_G.UnitAffectingCombat, "player")) or false
  simCtx.canPickPocket = (SpArc.CanPickPocketTarget and SpArc:CanPickPocketTarget(now)) or false
  simCtx.comboPoints = math.floor(simInsanity / 20)
  simCtx.playerHP = (SpArc.GetPlayerHPPercent and SpArc:GetPlayerHPPercent()) or 100
  simCtx.targetHP = (SpArc.GetTargetHPPercent and SpArc:GetTargetHPPercent()) or 100
  simCtx.buffs = simBuffs

  for step = 1, maxSlots do
    for spK, spD in pairs(SPELL_DEFS) do
      simReady[spK] = simKnown[spK] and (simCD[spK] <= 0.05) or false
      if step > 1 and simReady[spK] and not spD.procOnly and not spD.isExecute and not spD.isSpender then
        simUsable[spK] = true
      end
    end

    local pickedKey = nil
    local pickedIsNoResource = false
    for _, rule in ipairs(parsed.rules) do
      local sp = rule.spell
      if simReady[sp] and simUsable[sp] and not (step == 1 and simNoResource[sp]) then
        if SpArc:EvalSingleCondition(rule.cond, simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges, simBurst, simActive, simCtx) then
          pickedKey = sp
          break
        end
      end
    end

    if not pickedKey and step == 1 then
      for _, rule in ipairs(parsed.rules) do
        local sp = rule.spell
        if simReady[sp] and simUsable[sp] and simNoResource[sp] then
          if SpArc:EvalSingleCondition(rule.cond, simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges, simBurst, simActive, simCtx) then
            pickedKey = sp
            pickedIsNoResource = true
            break
          end
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
          if rem > 0.05 and rem < bestRem then
            local prevR, prevU = simReady[sp], simUsable[sp]
            simReady[sp] = true
            simUsable[sp] = true
            local condOK = SpArc:EvalSingleCondition(rule.cond, simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges, simBurst, simActive, simCtx)
            simReady[sp] = prevR
            simUsable[sp] = prevU
            if condOK then
              bestRem = rem
              bestSp = sp
            end
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
        local lastRule = parsed.rules[#parsed.rules]
        if lastRule and simKnown[lastRule.spell] then
          pickedKey = lastRule.spell
        end
      end
    end

    if step == 1 and pickedKey then
      local inCombat = _G.InCombatLockdown and SafeBool(_G.InCombatLockdown) or false
      local recentCast = (now - (st.lastAnyCastAt or 0)) < 0.40
      local locked = st.lockedTopKey
      if inCombat and not recentCast and not simBurst and locked and locked ~= pickedKey and simReady[locked] and simUsable[locked] then
        if st.lockedTopCandidateKey ~= pickedKey then
          st.lockedTopCandidateKey = pickedKey
          st.lockedTopCandidateSince = now
          pickedKey = locked
        elseif (now - (st.lockedTopCandidateSince or now)) < 0.45 then
          pickedKey = locked
        else
          st.lockedTopKey = pickedKey
          st.lockedTopCandidateKey = nil
        end
      else
        st.lockedTopKey = pickedKey
        st.lockedTopCandidateKey = nil
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
      qItem.isUsable = (step == 1) and (s.isUsable and not s.isNoResource) or true
      qItem.isNoResource = (step == 1 and (pickedIsNoResource or s.isNoResource or (s.isReady and not s.isUsable))) or false
      qItem.resWaitSec = (qItem.isNoResource and s.resWaitSec and s.resWaitSec > 0) and s.resWaitSec or 2.8
      qItem.isOutOfRange = s.isOutOfRange or false
      qItem.isUnavailable = s.isUnavailable or false

      local pickedWasProc = simProcs[pickedKey]
      simProcs[pickedKey] = false
      simBuffs[pickedKey] = true
      if pickedKey == "PICK_POCKET" then
        simCtx.canPickPocket = false
        simCD[pickedKey] = 9999
        simReady[pickedKey] = false
        simUsable[pickedKey] = false
      elseif pickedKey == "STEALTH" or pickedKey == "VANISH" then
        simCtx.stealthed = true
        simCD[pickedKey] = 9999
        simReady[pickedKey] = false
        simUsable[pickedKey] = false
      else
        simCtx.stealthed = false
        simCtx.inCombat = true
        if simProcs["AMBUSH"] then
          simProcs["AMBUSH"] = false
          simReady["AMBUSH"] = false
          simUsable["AMBUSH"] = false
        end
      end
      if def then
        if def.appliesDoTs then simHasDoTs = true end
        if def.burstDuration and def.burstDuration > 0 then
          simActive[pickedKey] = true
          simBurst = true
        end
        if def.insanityGain then simInsanity = math.min(100, simInsanity + def.insanityGain) end
        if def.insanityCost then simInsanity = math.max(0, simInsanity - def.insanityCost) end
        simCtx.comboPoints = math.floor(simInsanity / 20)
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
        elseif pickedKey ~= "PICK_POCKET" and pickedKey ~= "STEALTH" then
          simCD[pickedKey] = 0
        end
      end

      for spK, _ in pairs(SPELL_DEFS) do
        if simCD[spK] and simCD[spK] < 9000 then
          simCD[spK] = math.max(0, simCD[spK] - 1.4)
        end
      end

      local isComboPointClass = (SPELL_DEFS["DEVOURING_PLAGUE"] == nil)
      for spK, spD in pairs(SPELL_DEFS) do
        if spD.isSpender and spD.insanityCost then
          if isComboPointClass then
            if def and def.isSpender then
              simUsable[spK] = false
              simReady[spK] = false
            end
          else
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
  end

  for i = qCount + 1, #queue do
    queue[i] = nil
  end

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
  st.lastAnyCastAt = now
  st.lockedTopKey = nil
  st.lockedTopCandidateKey = nil
  if not defKey then return end
  st.lastCastAt[defKey] = now
  if defKey == "PICK_POCKET" and UnitGUID then
    local okG, guid = pcall(UnitGUID, "target")
    if okG and not IsSecret(guid) and type(guid) == "string" then
      st.pickPocketedGUIDs = st.pickPocketedGUIDs or {}
      st.pickPocketedGUIDs[guid] = true
    end
  end
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
eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
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
  if event == "UI_ERROR_MESSAGE" then
    if _G.IsStealthed and SafeBool(_G.IsStealthed) and SpArc.MarkTargetPickPocketed then
      local msg = not IsSecret(arg2) and type(arg2) == "string" and arg2 or ""
      local lowM = SpArc.UTF8Lower and SpArc.UTF8Lower(msg) or msg:lower()
      if lowM == "" or lowM:find("карман", 1, true) or lowM:find("pocket", 1, true) or lowM:find("краст", 1, true) or lowM:find("steal", 1, true) or lowM:find("обокра", 1, true) then
        SpArc:MarkTargetPickPocketed(true)
      end
    end
    return
  end
  if event == "UNIT_SPELLCAST_SENT" then
    if unit ~= "player" then return end
    st.lastAnyCastAt = GetTime()
    st.lockedTopKey = nil
    st.lockedTopCandidateKey = nil
    spellID = arg4
    if spellID and not IsSecret(spellID) then
      local defKey = SpArc:MatchSpellToDefKey(spellID, nil)
      if defKey == "PICK_POCKET" and SpArc.MarkTargetPickPocketed then
        SpArc:MarkTargetPickPocketed(false)
      end
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
    local hasTarget = _G.UnitExists and SafeBool(_G.UnitExists, "target") or false
    local targetDead = hasTarget and UnitIsDeadOrGhost and SafeBool(UnitIsDeadOrGhost, "target") or false
    local okG, guid = pcall(UnitGUID, "target")
    local newGUID = (okG and not IsSecret(guid) and guid) or nil
    if (not hasTarget) or targetDead or (newGUID and st.lastTargetGUID and newGUID ~= st.lastTargetGUID) then
      st.targetDoTsUntil = 0
      st.targetDebuffStacks = 0
      st.targetDebuffUntil = 0
      st.targetPickPocketed = false
      st.lastCastAt["GARROTE"] = nil
      st.lastCastAt["CRIMSON_TEMPEST"] = nil
      st.lastCastAt["PICK_POCKET"] = nil
    end
    if newGUID then
      st.lastTargetGUID = newGUID
    elseif not hasTarget then
      st.lastTargetGUID = nil
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
    if event == "UNIT_SPELLCAST_FAILED" and spellID and not IsSecret(spellID) then
      local failedKey = SpArc:MatchSpellToDefKey(spellID, sName)
      if failedKey == "PICK_POCKET" and SpArc.MarkTargetPickPocketed then
        SpArc:MarkTargetPickPocketed(true)
      end
    end
    st.castState.active = false
    st.castState.defKey = nil
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    st.lastAnyCastAt = now
    st.lockedTopKey = nil
    st.lockedTopCandidateKey = nil
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
