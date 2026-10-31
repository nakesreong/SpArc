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
      dst.dotDuration = spDef.dotDuration
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
      dst.auraIDs = spDef.auraIDs
      dst.auraDuration = spDef.auraDuration
      dst.auraUnit = spDef.auraUnit
      dst.auraKey = spDef.auraKey
      dst.burstDuration = spDef.burstDuration
      dst.isBossSkill = spDef.isBossSkill
      dst.isPvPSkill = spDef.isPvPSkill
      dst.isInterrupt = spDef.isInterrupt
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
  -- DRUID (Balance & Feral)
  [102] = { PVE = "DRUID_02_BALANCE_PVE",  BOSS = "DRUID_02_BALANCE_PVE",  PVP = "DRUID_02_BALANCE_PVE" },
  [103] = { PVE = "DRUID_01_FERAL_PVE",    BOSS = "DRUID_01_FERAL_PVE",    PVP = "DRUID_01_FERAL_PVE" },
  [104] = { PVE = "DRUID_01_FERAL_PVE",    BOSS = "DRUID_01_FERAL_PVE",    PVP = "DRUID_01_FERAL_PVE" },
  [105] = { PVE = "DRUID_02_BALANCE_PVE",  BOSS = "DRUID_02_BALANCE_PVE",  PVP = "DRUID_02_BALANCE_PVE" },
}

local PRESET_SPEC_IDS = {
  PRIEST_01_SHADOW_PVE = 258,
  MAGE_04_FROST_PVE    = 64,
  ROGUE_01_ASSA_PVE    = 259,
  WARRIOR_02_ARGS_BOSS = 71,
  DRUID_01_FERAL_PVE   = 103,
  DRUID_02_BALANCE_PVE = 102,
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

local function GetSimAura(simCtx, u, k)
  if not simCtx or not simCtx.auraRem or not simCtx.auraStacks then return 0, 0 end
  local rem = simCtx.auraRem[u] and simCtx.auraRem[u][k]
  local stacks = simCtx.auraStacks[u] and simCtx.auraStacks[u][k]
  if rem == nil and k and SpArc.GetUnitAuraState then
    local _, r, s = SpArc:GetUnitAuraState(u, k, st.activeParsed, nil, GetTime())
    rem = r or 0
    stacks = s or 0
    simCtx.auraRem[u][k] = rem
    simCtx.auraStacks[u][k] = stacks
  end
  return rem or 0, stacks or 0
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
  elseif c == "BOSS" or c == "player.boss_mode" or c == "BURST_MODE" then
    return (simCtx and simCtx.bossMode) and true or false
  elseif c == "NOT BOSS" or c == "NOT player.boss_mode" or c == "NOT BURST_MODE" then
    return not (simCtx and simCtx.bossMode)
  elseif c == "PVP" or c == "player.pvp_mode" or c == "PVP_MODE" then
    return (simCtx and simCtx.pvpMode) and true or false
  elseif c == "NOT PVP" or c == "NOT player.pvp_mode" or c == "NOT PVP_MODE" then
    return not (simCtx and simCtx.pvpMode)
  elseif c == "target.casting_interruptible" or c == "target.interruptible" or c == "INTERRUPTIBLE" then
    return (simCtx and simCtx.targetCastingInterruptible) and true or false
  elseif c == "NOT target.casting_interruptible" or c == "NOT target.interruptible" or c == "NOT INTERRUPTIBLE" then
    return not (simCtx and simCtx.targetCastingInterruptible)
  elseif c == "target.casting_uninterruptible" or c == "UNINTERRUPTIBLE" then
    return (simCtx and simCtx.targetIsCasting and not simCtx.targetCastingInterruptible) and true or false
  elseif c == "target.is_casting" or c == "target.casting" then
    return (simCtx and simCtx.targetIsCasting) and true or false
  elseif c == "NOT target.is_casting" or c == "NOT target.casting" then
    return not (simCtx and simCtx.targetIsCasting)
  end

  -- WeakAuras-style unified Aura conditions:
  --   target.aura(KEY_OR_ID).rem <= 1.0  /  player.aura(KEY_OR_ID).rem > 0
  --   target.aura(KEY_OR_ID).stacks >= 4 /  player.aura(KEY_OR_ID).stacks >= 2
  local aUnit, aKey, aProp, aOp, aVal = c:match("^([a-zA-Z]+)%.aura%(([A-Za-z0-9_]+)%)%.([a-zA-Z_]+)%s*([><=]+)%s*([%d%.]+)$")
  if aUnit and aKey and aProp and aOp and aVal then
    local u = (aUnit:lower() == "player") and "player" or "target"
    local k = aKey:upper()
    local prop = aProp:lower()
    local curR, curS = GetSimAura(simCtx, u, k)
    if prop == "stacks" or prop == "stack" or prop == "applications" then
      return CompareNum(curS, aOp, tonumber(aVal) or 0)
    else
      return CompareNum(curR, aOp, tonumber(aVal) or 0)
    end
  end

  -- Boolean shorthand: target.aura(KEY) / NOT target.aura(KEY) / player.aura(KEY) / NOT player.aura(KEY)
  local bUnit, bKey = c:match("^([a-zA-Z]+)%.aura%(([A-Za-z0-9_]+)%)$")
  if bUnit and bKey then
    local u = (bUnit:lower() == "player") and "player" or "target"
    local k = bKey:upper()
    local curR = GetSimAura(simCtx, u, k)
    return curR > 0
  end

  local nbUnit, nbKey = c:match("^NOT%s+([a-zA-Z]+)%.aura%(([A-Za-z0-9_]+)%)$")
  if nbUnit and nbKey then
    local u = (nbUnit:lower() == "player") and "player" or "target"
    local k = nbKey:upper()
    local curR = GetSimAura(simCtx, u, k)
    return curR <= 0
  end

  -- Legacy aliases mapped onto unified Aura tables for custom profile compatibility
  local activeSp = c:match("^ACTIVE%(([A-Z0-9_]+)%)$")
  if activeSp then
    local rP = (simCtx and simCtx.auraRem and simCtx.auraRem.player and simCtx.auraRem.player[activeSp]) or 0
    local rT = (simCtx and simCtx.auraRem and simCtx.auraRem.target and simCtx.auraRem.target[activeSp]) or 0
    return (rP > 0 or rT > 0 or (simActive and simActive[activeSp])) and true or false
  end

  local notActiveSp = c:match("^NOT%s+ACTIVE%(([A-Z0-9_]+)%)$")
  if notActiveSp then
    local rP = (simCtx and simCtx.auraRem and simCtx.auraRem.player and simCtx.auraRem.player[notActiveSp]) or 0
    local rT = (simCtx and simCtx.auraRem and simCtx.auraRem.target and simCtx.auraRem.target[notActiveSp]) or 0
    return not (rP > 0 or rT > 0 or (simActive and simActive[notActiveSp]))
  end

  local buffSp = c:match("^BUFF%(([A-Z0-9_]+)%)$")
  if buffSp then
    local rP = (simCtx and simCtx.auraRem and simCtx.auraRem.player and simCtx.auraRem.player[buffSp]) or 0
    return rP > 0
  end

  local notBuffSp = c:match("^NOT%s+BUFF%(([A-Z0-9_]+)%)$")
  if notBuffSp then
    local rP = (simCtx and simCtx.auraRem and simCtx.auraRem.player and simCtx.auraRem.player[notBuffSp]) or 0
    return rP <= 0
  end

  local dotSp = c:match("^DOT%(([A-Z0-9_]+)%)$")
  if dotSp then
    local rT = (simCtx and simCtx.auraRem and simCtx.auraRem.target and simCtx.auraRem.target[dotSp]) or 0
    return rT > 1.0
  end

  local notDotSp = c:match("^NOT%s+DOT%(([A-Z0-9_]+)%)$")
  if notDotSp then
    local rT = (simCtx and simCtx.auraRem and simCtx.auraRem.target and simCtx.auraRem.target[notDotSp]) or 0
    return rT <= 1.0
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

  local eOp, eVal = c:match("^player%.energy%s*([><=]+)%s*(%d+)$")
  if not eOp then eOp, eVal = c:match("^ENERGY%s*([><=]+)%s*(%d+)$") end
  if not eOp then eOp, eVal = c:match("^energy%s*([><=]+)%s*(%d+)$") end
  if eOp and eVal then
    local curE = (simCtx and simCtx.energy) or 100
    return CompareNum(curE, eOp, tonumber(eVal) or 0)
  end

  local apOp, apVal = c:match("^player%.astral_power%s*([><=]+)%s*(%d+)$")
  if not apOp then apOp, apVal = c:match("^player%.insanity%s*([><=]+)%s*(%d+)$") end
  if not apOp then apOp, apVal = c:match("^player%.power%s*([><=]+)%s*(%d+)$") end
  if not apOp then apOp, apVal = c:match("^ASTRAL_POWER%s*([><=]+)%s*(%d+)$") end
  if not apOp then apOp, apVal = c:match("^INSANITY%s*([><=]+)%s*(%d+)$") end
  if apOp and apVal then
    local curAP = (simCtx and simCtx.insanity) or 0
    return CompareNum(curAP, apOp, tonumber(apVal) or 0)
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
local simAuraRem = { target = {}, player = {} }
local simAuraStacks = { target = {}, player = {} }
local simCtx = { auraRem = simAuraRem, auraStacks = simAuraStacks }
local EMPTY_TABLE = {}

function SpArc:BuildRotationQueue(maxSlots)
  local db = SpArc:EnsureDB()
  local now = GetTime()
  maxSlots = maxSlots or (db.visual and db.visual.queueLength) or 5
  SpArc:RefreshTrackedInsanity()
  local assistedKey = SpArc:GetAssistedSuggestedDefKey()
  if assistedKey and SPELL_DEFS[assistedKey] and SPELL_DEFS[assistedKey].isSpender then
    local aCost = SPELL_DEFS[assistedKey].insanityCost or 50
    if st.trackedInsanity < aCost then
      st.trackedInsanity = aCost
    end
  end

  local parsed = SpArc:SelectActiveParsedProfile()
  if not parsed or not parsed.rules then
    return EMPTY_TABLE, EMPTY_TABLE, parsed, nil, false, false
  end

  for k in pairs(simAuraRem.target) do simAuraRem.target[k] = nil end
  for k in pairs(simAuraRem.player) do simAuraRem.player[k] = nil end
  for k in pairs(simAuraStacks.target) do simAuraStacks.target[k] = nil end
  for k in pairs(simAuraStacks.player) do simAuraStacks.player[k] = nil end

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
    simActive[k] = (SpArc.IsSpellBurstActive and SpArc:IsSpellBurstActive(k, sObj, parsed, now)) or false
    simNoResource[k] = isNoResource or false
  end

  -- Populate unified Aura state for active aura definitions on their designated unit
  local auraMap = (parsed and parsed.auras) or SPELL_DEFS
  local simHasDoTs = false
  local anyDoTDef = false
  local allDoTsActive = true
  for aKey, aDef in pairs(auraMap) do
    local hasAuraMeta = aDef.isAuraOnly or (aDef.auraDuration and aDef.auraDuration > 0) or aDef.appliesDoTs or (aDef.burstDuration and aDef.burstDuration > 0)
    if hasAuraMeta then
      local u = aDef.auraUnit or ((aDef.burstDuration and aDef.burstDuration > 0 and not aDef.appliesDoTs) and "player" or "target")
      local _, uRem, uStacks = SpArc:GetUnitAuraState(u, aKey, parsed, assistedKey, now)
      uRem = uRem or 0
      uStacks = uStacks or 0
      simAuraRem[u][aKey] = uRem
      simAuraStacks[u][aKey] = uStacks
      local aIDs = aDef.auraIDs or aDef.debuffIDs or aDef.ids
      if aIDs then
        for _, id in ipairs(aIDs) do
          local idStr = tostring(id)
          if uRem > (simAuraRem[u][idStr] or 0) then simAuraRem[u][idStr] = uRem end
          if uStacks > (simAuraStacks[u][idStr] or 0) then simAuraStacks[u][idStr] = uStacks end
        end
      end
      if aDef.appliesDoTs and states[aKey] and not states[aKey].isUnavailable then
        anyDoTDef = true
        if uRem <= 1.0 then
          allDoTsActive = false
        end
      end
    end
  end
  if anyDoTDef and allDoTsActive then
    simHasDoTs = true
  end
  local simStacks = simAuraStacks.target["FREEZING"] or 0
  local simBurst = (SpArc.IsPlayerInBurst and SpArc:IsPlayerInBurst(states, parsed, now)) or false

  local queue = reusableQueue
  local qCount = 0
  for spK, spD in pairs(SPELL_DEFS) do
    if spD.isSpender and spD.insanityCost and spD.insanityCost > 0 and (not spD.baseCD or spD.baseCD <= 0) then
      local sSp = states[spK]
      if sSp and not sSp.isUnavailable then
        local cost = spD.insanityCost
        local isFreeProc = ((spK == "FEROCIOUS_BITE" or spK == "STARSURGE" or spK == "STARFALL") and sSp.isProc)
        if not isFreeProc then
          if not sSp.isUsable and st.trackedInsanity >= cost then
            st.trackedInsanity = math.floor(cost * 0.5)
          elseif sSp.isUsable and st.trackedInsanity < cost then
            st.trackedInsanity = cost
          end
          break
        end
      end
    end
  end
  local simInsanity = st.trackedInsanity
  local simEnergy = (SpArc.GetPlayerEnergy and SpArc:GetPlayerEnergy(now)) or 100

  simCtx.enemies = (SpArc.GetNearbyEnemyCount and SpArc:GetNearbyEnemyCount(now, assistedKey)) or 1
  simCtx.stealthed = (_G.IsStealthed and SafeBool(_G.IsStealthed)) or false
  simCtx.inCombat = (_G.InCombatLockdown and SafeBool(_G.InCombatLockdown)) or (_G.UnitAffectingCombat and SafeBool(_G.UnitAffectingCombat, "player")) or false
  local hasHostileTarget = _G.UnitExists and SafeBool(_G.UnitExists, "target") and _G.UnitCanAttack and SafeBool(_G.UnitCanAttack, "player", "target") and not (_G.UnitIsDeadOrGhost and SafeBool(_G.UnitIsDeadOrGhost, "target"))
  if not simCtx.inCombat and not hasHostileTarget and not SpArc.testMode and (not SpArc.IsAutoUnshiftEnabled or SpArc:IsAutoUnshiftEnabled()) then
    simAuraRem.player["MOONKIN_FORM"] = 3600
    simAuraRem.player["24858"] = 3600
    simAuraRem.player["SHADOWFORM"] = 3600
    simAuraRem.player["232698"] = 3600
  end
  simCtx.canPickPocket = (SpArc.CanPickPocketTarget and SpArc:CanPickPocketTarget(now)) or false
  simCtx.bossMode = (SpArc.IsBossRotationEnabled and SpArc:IsBossRotationEnabled()) or false
  simCtx.pvpMode = (SpArc.IsPvPRotationEnabled and SpArc:IsPvPRotationEnabled()) or false
  local tCast, tInt = false, false
  if SpArc.GetUnitCastInterruptState then
    tCast, tInt = SpArc:GetUnitCastInterruptState("target", now)
  end
  simCtx.targetIsCasting = tCast or false
  simCtx.targetCastingInterruptible = (tCast and tInt) or false
  simCtx.insanity = simInsanity
  simCtx.comboPoints = math.floor(simInsanity / 20)
  simCtx.energy = simEnergy
  simCtx.playerHP = (SpArc.GetPlayerHPPercent and SpArc:GetPlayerHPPercent()) or 100
  simCtx.targetHP = (SpArc.GetTargetHPPercent and SpArc:GetTargetHPPercent()) or 100
  simCtx.auraRem = simAuraRem
  simCtx.auraStacks = simAuraStacks

  local function IsSpellAllowedByToggles(spKey, stepIdx)
    local d = SPELL_DEFS[spKey]
    if not d then return true end
    if d.isBossSkill and not simCtx.bossMode then
      return false
    end
    if d.isPvPSkill and not simCtx.pvpMode then
      return false
    end
    if d.isInterrupt then
      if stepIdx ~= 1 or not simCtx.targetCastingInterruptible then
        return false
      end
    end
    return true
  end

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
      if simReady[sp] and simUsable[sp] and IsSpellAllowedByToggles(sp, step) and not (step == 1 and simNoResource[sp]) then
        if SpArc:EvalSingleCondition(rule.cond, simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges, simBurst, simActive, simCtx) then
          pickedKey = sp
          break
        end
      end
    end

    if not pickedKey and step == 1 then
      for _, rule in ipairs(parsed.rules) do
        local sp = rule.spell
        if simReady[sp] and simUsable[sp] and IsSpellAllowedByToggles(sp, step) and simNoResource[sp] then
          if SpArc:EvalSingleCondition(rule.cond, simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges, simBurst, simActive, simCtx) then
            pickedKey = sp
            pickedIsNoResource = true
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
      qItem.isUsable = (step == 1) and (s.isUsable and not s.isNoResource) or true
      qItem.isNoResource = (step == 1 and (pickedIsNoResource or s.isNoResource or (s.isReady and not s.isUsable))) or false
      qItem.resWaitSec = (qItem.isNoResource and s.resWaitSec and s.resWaitSec > 0) and s.resWaitSec or 2.8
      qItem.isOutOfRange = s.isOutOfRange or false
      qItem.isUnavailable = s.isUnavailable or false

      local pickedWasProc = simProcs[pickedKey]
      simProcs[pickedKey] = false
      if def and def.isInterrupt then
        simCtx.targetCastingInterruptible = false
        simCtx.targetIsCasting = false
      end
      if simCtx.stealthed then
        simCtx.stealthed = false
      end
      if def then
        local aDur = (def.auraDuration and def.auraDuration > 0) and def.auraDuration or ((def.appliesDoTs and 21.0) or ((def.burstDuration and def.burstDuration > 0) and def.burstDuration) or 0)
        if aDur > 0 then
          local u = def.auraUnit or ((def.burstDuration and def.burstDuration > 0 and not def.appliesDoTs) and "player" or "target")
          simAuraRem[u][pickedKey] = aDur
          if (simAuraStacks[u][pickedKey] or 0) < 1 then simAuraStacks[u][pickedKey] = 1 end
          local aIDs = def.auraIDs or def.debuffIDs or def.ids
          if aIDs then
            for _, aID in ipairs(aIDs) do
              local idStr = tostring(aID)
              simAuraRem[u][idStr] = aDur
              if (simAuraStacks[u][idStr] or 0) < 1 then simAuraStacks[u][idStr] = 1 end
              for otherKey, otherDef in pairs(auraMap) do
                local oIDs = otherDef.auraIDs or otherDef.debuffIDs or otherDef.ids
                if oIDs then
                  for _, oID in ipairs(oIDs) do
                    if oID == aID then
                      simAuraRem[u][otherKey] = aDur
                      if (simAuraStacks[u][otherKey] or 0) < 1 then simAuraStacks[u][otherKey] = 1 end
                    end
                  end
                end
              end
            end
          end
        else
          simAuraRem.player[pickedKey] = 10.0
        end
        if def.appliesDoTs then
          simHasDoTs = true
        end
        if def.burstDuration and def.burstDuration > 0 then
          simActive[pickedKey] = true
          simBurst = true
        end
        if def.insanityGain then simInsanity = math.min(100, simInsanity + def.insanityGain) end
        if def.insanityCost and not (def.isSpender and pickedWasProc) then
          simInsanity = math.max(0, simInsanity - def.insanityCost)
        end
        simCtx.insanity = simInsanity
        simCtx.comboPoints = math.floor(simInsanity / 20)
        if pickedKey == "TIGERS_FURY" then
          simEnergy = math.min(100, simEnergy + 50)
        elseif SpArc.DEFAULT_ENERGY_COST and SpArc.DEFAULT_ENERGY_COST[pickedKey] and not (def.isSpender and pickedWasProc) then
          simEnergy = math.max(0, simEnergy - SpArc.DEFAULT_ENERGY_COST[pickedKey])
        end
        simCtx.energy = simEnergy
        if def.grantsProc and SPELL_DEFS[def.grantsProc] then
          simProcs[def.grantsProc] = true
          simCD[def.grantsProc] = 0
          simReady[def.grantsProc] = true
          simUsable[def.grantsProc] = true
        end
        if def.consumesStacks and not pickedWasProc then
          local cost = (def.stacksCost and def.stacksCost > 0) and def.stacksCost or 4
          local tKey = def.auraKey or "FREEZING"
          local newSt = math.max(0, (simAuraStacks.target[tKey] or simStacks or 0) - cost)
          simStacks = newSt
          simAuraStacks.target[tKey] = newSt
          if newSt <= 0 then simAuraRem.target[tKey] = 0 end
        end
        if def.stacksGain and def.stacksGain > 0 then
          local tKey = def.auraKey or "FREEZING"
          local newSt = math.min(20, (simAuraStacks.target[tKey] or simStacks or 0) + def.stacksGain)
          simStacks = newSt
          simAuraStacks.target[tKey] = newSt
          simAuraRem.target[tKey] = def.auraDuration or 15.0
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
        else
          simCD[pickedKey] = 0
        end
      end

      for spK, _ in pairs(SPELL_DEFS) do
        if simCD[spK] and simCD[spK] < 9000 then
          simCD[spK] = math.max(0, simCD[spK] - 1.4)
        end
      end
      for aK, rVal in pairs(simAuraRem.target) do
        if rVal and rVal > 0 and rVal < 9000 then
          simAuraRem.target[aK] = math.max(0, rVal - 1.4)
        end
      end
      for aK, rVal in pairs(simAuraRem.player) do
        if rVal and rVal > 0 and rVal < 9000 then
          simAuraRem.player[aK] = math.max(0, rVal - 1.4)
        end
      end

      for spK, spD in pairs(SPELL_DEFS) do
        if spD.isSpender and spD.insanityCost then
          local canAfford = simInsanity >= spD.insanityCost
          simUsable[spK] = canAfford
          if canAfford and (not spD.baseCD or spD.baseCD <= 0) then
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
  if defKey == "MOONKIN_FORM" or defKey == "SHADOWFORM" or defKey == "BEAR_FORM" or defKey == "CAT_FORM" then
    st.lastManualFormCastAt = now
    if SpArc.ClearPendingAutoUnshift then
      SpArc:ClearPendingAutoUnshift()
    end
  end
  if defKey == "PICK_POCKET" and UnitGUID then
    local okG, guid = pcall(UnitGUID, "target")
    if okG and not IsSecret(guid) and type(guid) == "string" then
      st.pickPocketedGUIDs = st.pickPocketedGUIDs or {}
      st.pickPocketedGUIDs[guid] = true
    end
  end
  local def = SPELL_DEFS[defKey]
  if not def then return end
  st.unitAuras = st.unitAuras or { target = {}, player = {} }
  st.unitAuras.target = st.unitAuras.target or {}
  st.unitAuras.player = st.unitAuras.player or {}

  local aDur = (def.auraDuration and def.auraDuration > 0) and def.auraDuration or ((def.appliesDoTs and 21.0) or ((def.burstDuration and def.burstDuration > 0) and def.burstDuration) or 0)
  if aDur > 0 then
    local u = def.auraUnit or ((def.burstDuration and def.burstDuration > 0 and not def.appliesDoTs) and "player" or "target")
    local uMap = st.unitAuras[u]
    local prev = uMap[defKey]
    local remPrev = (prev and prev.untilTime and prev.untilTime > now) and math.min(aDur * 0.3, prev.untilTime - now) or 0
    local newUntil = now + aDur + remPrev
    local entry = { untilTime = newUntil, stacks = math.max(1, (prev and prev.stacks) or 1) }
    uMap[defKey] = entry
    local aIDs = def.auraIDs or def.debuffIDs or def.ids
    if aIDs then
      local auraMap = (st.activeParsed and st.activeParsed.auras) or SPELL_DEFS
      for _, aID in ipairs(aIDs) do
        uMap[aID] = entry
        uMap[tostring(aID)] = entry
        for otherKey, otherDef in pairs(auraMap) do
          local oIDs = otherDef.auraIDs or otherDef.debuffIDs or otherDef.ids
          if oIDs then
            for _, oID in ipairs(oIDs) do
              if oID == aID then
                uMap[otherKey] = entry
              end
            end
          end
        end
      end
    end
  end

  if def.insanityGain then
    st.trackedInsanity = math.min(100, st.trackedInsanity + def.insanityGain)
  end
  local lastAudit = st.lastSpellAudit and st.lastSpellAudit[defKey]
  local castWasProc = (lastAudit and lastAudit.isProc) or false
  if def.insanityCost and not (def.isSpender and castWasProc) then
    st.trackedInsanity = math.max(0, st.trackedInsanity - def.insanityCost)
  end
  if defKey == "TIGERS_FURY" then
    local curE = (SpArc.GetPlayerEnergy and SpArc:GetPlayerEnergy(now)) or 100
    st.trackedEnergy = math.min(100, curE + 50)
    st.lastEnergyUpdateAt = now
  elseif SpArc.DEFAULT_ENERGY_COST and SpArc.DEFAULT_ENERGY_COST[defKey] and not (def.isSpender and castWasProc) then
    local curE = (SpArc.GetPlayerEnergy and SpArc:GetPlayerEnergy(now)) or 100
    st.trackedEnergy = math.max(0, curE - SpArc.DEFAULT_ENERGY_COST[defKey])
    st.lastEnergyUpdateAt = now
  end
  if def.grantsMFI then
    st.mfiProcUntil = now + 10.0
  end
  if defKey == "MIND_FLAY_INSANITY" then
    st.mfiProcUntil = 0
  end
  if def.isSpender and SPELL_DEFS["REGROWTH"] then
    local psEntry = { untilTime = now + 12.0, expiresAt = now + 12.0, stacks = 1 }
    st.unitAuras.player["REGROWTH"] = psEntry
    st.unitAuras.player[69369] = psEntry
    st.unitAuras.player["69369"] = psEntry
  elseif defKey == "REGROWTH" then
    st.unitAuras.player["REGROWTH"] = nil
    st.unitAuras.player[69369] = nil
    st.unitAuras.player["69369"] = nil
  end
  if def.consumesStacks and not castWasProc then
    local cost = (def.stacksCost and def.stacksCost > 0) and def.stacksCost or 4
    local tKey = def.auraKey or "FREEZING"
    local prev = st.unitAuras.target[tKey]
    local newSt = math.max(0, ((prev and prev.stacks) or st.targetDebuffStacks or 0) - cost)
    st.targetDebuffStacks = newSt
    st.unitAuras.target[tKey] = { untilTime = (newSt > 0 and prev and prev.untilTime) or 0, stacks = newSt }
  end
  if def.stacksGain and def.stacksGain > 0 then
    local tKey = def.auraKey or "FREEZING"
    local prev = st.unitAuras.target[tKey]
    local newSt = math.min(20, ((prev and prev.stacks) or st.targetDebuffStacks or 0) + def.stacksGain)
    local newUntil = now + (def.auraDuration or 15.0)
    st.targetDebuffStacks = newSt
    st.targetDebuffUntil = newUntil
    st.unitAuras.target[tKey] = { untilTime = newUntil, stacks = newSt }
  end
  local maxCh = def.liveMaxCharges or def.maxCharges or 1
  if maxCh > 1 or (def.baseCD and def.baseCD > 0 and def.baseCD <= 30) then
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
pcall(eventFrame.RegisterEvent, eventFrame, "TRAIT_CONFIG_UPDATED")
pcall(eventFrame.RegisterEvent, eventFrame, "PLAYER_TALENT_UPDATE")
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

  if event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" or event == "UPDATE_MACROS" or event == "UPDATE_BINDINGS" or event == "SPELLS_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "TRAIT_CONFIG_UPDATED" or event == "PLAYER_TALENT_UPDATE" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_FLAGS_CHANGED" then
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
    local sameTarget = (newGUID and st.lastTargetGUID and newGUID == st.lastTargetGUID) or false
    if (not hasTarget) or targetDead or (not sameTarget) then
      if st.unitAuras then
        st.unitAuras.target = {}
      end
      st.targetDebuffStacks = 0
      st.targetDebuffUntil = 0
      st.targetPickPocketed = false
      if st.unitCastState then
        st.unitCastState["target"] = nil
      end
      st.lastCastAt["GARROTE"] = nil
      st.lastCastAt["CRIMSON_TEMPEST"] = nil
      st.lastCastAt["PICK_POCKET"] = nil
    end
    if newGUID then
      st.lastTargetGUID = newGUID
    else
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
    local dur = (defKey == "RAY_OF_FROST" or defKey == "CONVOKE_THE_SPIRITS") and 4.0 or ((defKey == "VOID_TORRENT") and 3.0 or 2.8)
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
    if defKey and not isChan then
      SpArc:RecordSpellCastSuccess(defKey, now)
    end
  end
end)

-- Target & Nameplate Cast / Interruptibility Tracker (Secret-Safe for WoW 12.x)
local unitCastFrame = CreateFrame("Frame")
unitCastFrame:RegisterEvent("UNIT_SPELLCAST_START")
unitCastFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
unitCastFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
unitCastFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
unitCastFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
unitCastFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
pcall(unitCastFrame.RegisterEvent, unitCastFrame, "UNIT_SPELLCAST_EMPOWER_START")
pcall(unitCastFrame.RegisterEvent, unitCastFrame, "UNIT_SPELLCAST_EMPOWER_STOP")
pcall(unitCastFrame.RegisterEvent, unitCastFrame, "UNIT_SPELLCAST_INTERRUPTIBLE")
pcall(unitCastFrame.RegisterEvent, unitCastFrame, "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")

unitCastFrame:SetScript("OnEvent", function(_, event, unit, _, spellID)
  if not unit or IsSecret(unit) or type(unit) ~= "string" or unit == "player" then return end
  if unit ~= "target" and unit ~= "focus" and not unit:find("^nameplate") and not unit:find("^boss") then
    return
  end
  st.unitCastState = st.unitCastState or {}
  local uEv = st.unitCastState[unit]
  if not uEv then
    uEv = {}
    st.unitCastState[unit] = uEv
  end
  local now = GetTime()

  if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START" then
    local isChan = (event ~= "UNIT_SPELLCAST_START")
    local dur = isChan and 3.0 or 2.0
    local sName, sIcon
    if spellID and not IsSecret(spellID) and C_Spell and C_Spell.GetSpellInfo then
      local okI, info = pcall(C_Spell.GetSpellInfo, spellID)
      if okI and type(info) == "table" then
        sName = not IsSecret(info.name) and info.name or nil
        sIcon = not IsSecret(info.iconID) and info.iconID or nil
        local cMS = not IsSecret(info.castTime) and info.castTime or nil
        if cMS and type(cMS) == "number" and cMS > 0 then
          dur = cMS / 1000.0
        end
      end
    end
    uEv.active = true
    uEv.isChannel = isChan
    uEv.interruptible = true
    uEv.startTime = now
    uEv.endTime = now + dur
    uEv.spellID = (not IsSecret(spellID) and type(spellID) == "number" and spellID) or nil
    uEv.name = sName
    uEv.icon = sIcon
  elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
    uEv.interruptible = true
  elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
    uEv.interruptible = false
  elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_EMPOWER_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
    uEv.active = false
  end
end)
