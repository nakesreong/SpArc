---------------------------------------------------------------------------------------
--  SpArc/Evaluator.lua — Generic .MD FSM Condition Evaluator, Queue Builder & Events
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
--  @module Evaluator
--  @responsibility
--    1. Synchronizes `SpArc.SPELL_DEFS` with the active `.MD` profile (`SyncSpellDefsFromProfile`).
--    2. Evaluates `.MD` condition expressions (`IsRuleConditionMet`).
--    3. Builds the 3..6 icon lookahead rotation queue (`BuildRotationQueue`) by combining
--       Blizzard's Assisted Combat primary suggestion with `.MD` lookahead simulation.
--    4. Handles live combat cast events (`RecordSpellCastSuccess` + `eventFrame`).
--  @contract
--    - `SpArc:BuildRotationQueue(maxLen)` MUST return `(queue, states)` where `queue` is an
--      array of `1..maxLen` spell state objects and `states` is a dictionary by `defKey`.
--  @techdebt [AUDIT-EV1..EV3]
--    - [AUDIT-EV1] `BuildRotationQueue` (lines 1102–1175) and `RecordSpellCastSuccess` (lines 1278–1376)
--      duplicate ~100 lines of spell-cast state transition logic (Aura application, Insanity/Energy cost,
--      `grantsProc`, stack consumption/gain, and `MAELSTROM_WEAPON` +2/-10 stack math).
--      Planned Refactor (Phase 2): Extract a single shared `ApplySpellCastTransition(stateAdapter, defKey, def)` function.
--    - [AUDIT-EV2] Class-specific spell rules are hardcoded inside `Evaluator.lua`:
--      • `MAELSTROM_WEAPON` stack builders/spenders (`STORMSTRIKE`, `LAVA_LASH`, `TEMPEST`, etc.)
--      • `TIGERS_FURY` (+50 energy), `VOID_ERUPTION` + `POWER_INFUSION` shared macro keybind
--      • `RAY_OF_FROST` / `CONVOKE_THE_SPIRITS` / `VOID_TORRENT` channel durations
--      • `GARROTE` / `CRIMSON_TEMPEST` / `PICK_POCKET` target-change cooldown resets
--      • `MOONKIN_FORM` / `SHADOWFORM` / `LIGHTNING_SHIELD` / `EARTH_SHIELD` OOC aura spoofing
--      Planned Refactor (Phase 2): Move into declarative `.MD` spell properties.
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc

local CreateFrame = _G.CreateFrame
local GetTime = _G.GetTime
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitClassification = _G.UnitClassification
local UnitLevel = _G.UnitLevel
local UnitCastingInfo = _G.UnitCastingInfo
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
    local db = SpArc:EnsureDB()
    if db and db.visual and db.visual.npAutoAurasFromMD ~= false and SpArc.SyncNameplateAurasFromActiveMD then
      SpArc:SyncNameplateAurasFromActiveMD(presetID, false)
    end
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
  -- SHAMAN (Enhancement)
  [262] = { PVE = "SHAMAN_01_ENH_PVE",     BOSS = "SHAMAN_01_ENH_PVE",     PVP = "SHAMAN_01_ENH_PVE" },
  [263] = { PVE = "SHAMAN_01_ENH_PVE",     BOSS = "SHAMAN_01_ENH_PVE",     PVP = "SHAMAN_01_ENH_PVE" },
  [264] = { PVE = "SHAMAN_01_ENH_PVE",     BOSS = "SHAMAN_01_ENH_PVE",     PVP = "SHAMAN_01_ENH_PVE" },
}

local PRESET_SPEC_IDS = {
  PRIEST_01_SHADOW_PVE = 258,
  MAGE_04_FROST_PVE    = 64,
  ROGUE_01_ASSA_PVE    = 259,
  WARRIOR_02_ARGS_BOSS = 71,
  DRUID_01_FERAL_PVE   = 103,
  DRUID_02_BALANCE_PVE = 102,
  SHAMAN_01_ENH_PVE    = 263,
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
    if SpArc.IsTargetPvP and SpArc:IsTargetPvP("target") then
      targetMode = "PVP"
      presetID = (db.autoPresets and db.autoPresets.PVP) or "PRIEST_03_SHADOW_PVP"
    elseif SpArc.IsTargetBossOrRare and SpArc:IsTargetBossOrRare("target") then
      targetMode = "BOSS"
      presetID = (db.autoPresets and db.autoPresets.BOSS) or "PRIEST_02_SHADOW_BOSS"
    else
      targetMode = "PVE"
      presetID = (db.autoPresets and db.autoPresets.PVE) or "PRIEST_01_SHADOW_PVE"
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
      local isBuiltInOtherClass = curPreset and SpArc.BuiltInPresets and SpArc.BuiltInPresets[presetID] and curPreset.class ~= playerClass
      if mode == "AUTO" or isBuiltInOtherClass or not curPreset then
        local presetSpec = PRESET_SPEC_IDS[presetID]
        local specMismatch = (mode == "AUTO" and specMap and presetSpec and presetSpec ~= specID) or false

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
              db.activePresetID = presetID
              db.autoPresets = db.autoPresets or {}
              db.autoPresets.PVE  = fallbackID
              db.autoPresets.BOSS = fallbackID
              db.autoPresets.PVP  = fallbackID
              if SpArc.SaveCharPresetState then SpArc:SaveCharPresetState(db) end
            end
          end
        else
          db.activePresetID = presetID
          if SpArc.SaveCharPresetState then SpArc:SaveCharPresetState(db) end
        end
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

local STATIC_CLAUSES = {
  [""]                               = { op = "ALWAYS" },
  ["ALWAYS"]                         = { op = "ALWAYS" },
  ["target.has_dots"]                = { op = "HAS_DOTS", inv = false },
  ["NOT target.has_dots"]            = { op = "HAS_DOTS", inv = true },
  ["player.in_burst"]                = { op = "BURST", inv = false },
  ["BURST"]                          = { op = "BURST", inv = false },
  ["NOT player.in_burst"]            = { op = "BURST", inv = true },
  ["NOT BURST"]                      = { op = "BURST", inv = true },
  ["player.stealthed"]               = { op = "CTX_BOOL", field = "stealthed", inv = false },
  ["STEALTH"]                        = { op = "CTX_BOOL", field = "stealthed", inv = false },
  ["NOT player.stealthed"]           = { op = "CTX_BOOL", field = "stealthed", inv = true },
  ["NOT STEALTH"]                    = { op = "CTX_BOOL", field = "stealthed", inv = true },
  ["player.in_combat"]               = { op = "CTX_BOOL", field = "inCombat", inv = false },
  ["COMBAT"]                         = { op = "CTX_BOOL", field = "inCombat", inv = false },
  ["NOT player.in_combat"]           = { op = "CTX_BOOL", field = "inCombat", inv = true },
  ["NOT COMBAT"]                     = { op = "CTX_BOOL", field = "inCombat", inv = true },
  ["target.can_pick_pocket"]         = { op = "CTX_BOOL", field = "canPickPocket", inv = false },
  ["PICK_POCKET_READY"]              = { op = "CTX_BOOL", field = "canPickPocket", inv = false },
  ["NOT target.can_pick_pocket"]     = { op = "CTX_BOOL", field = "canPickPocket", inv = true },
  ["AOE"]                            = { op = "CTX_NUM", field = "enemies", cmp = ">=", val = 3, def = 1 },
  ["NOT AOE"]                        = { op = "CTX_NUM", field = "enemies", cmp = "<",  val = 3, def = 1 },
  ["CLEAVE"]                         = { op = "CTX_NUM", field = "enemies", cmp = ">=", val = 2, def = 1 },
  ["SINGLE_TARGET"]                  = { op = "CTX_NUM", field = "enemies", cmp = "<=", val = 1, def = 1 },
  ["BOSS"]                           = { op = "CTX_BOOL", field = "bossMode", inv = false },
  ["player.boss_mode"]               = { op = "CTX_BOOL", field = "bossMode", inv = false },
  ["BURST_MODE"]                     = { op = "CTX_BOOL", field = "bossMode", inv = false },
  ["NOT BOSS"]                       = { op = "CTX_BOOL", field = "bossMode", inv = true },
  ["NOT player.boss_mode"]           = { op = "CTX_BOOL", field = "bossMode", inv = true },
  ["NOT BURST_MODE"]                 = { op = "CTX_BOOL", field = "bossMode", inv = true },
  ["PVP"]                            = { op = "CTX_BOOL", field = "pvpMode", inv = false },
  ["player.pvp_mode"]                = { op = "CTX_BOOL", field = "pvpMode", inv = false },
  ["PVP_MODE"]                       = { op = "CTX_BOOL", field = "pvpMode", inv = false },
  ["NOT PVP"]                        = { op = "CTX_BOOL", field = "pvpMode", inv = true },
  ["NOT player.pvp_mode"]            = { op = "CTX_BOOL", field = "pvpMode", inv = true },
  ["NOT PVP_MODE"]                   = { op = "CTX_BOOL", field = "pvpMode", inv = true },
  ["target.casting_interruptible"]   = { op = "CTX_BOOL", field = "targetCastingInterruptible", inv = false },
  ["target.interruptible"]           = { op = "CTX_BOOL", field = "targetCastingInterruptible", inv = false },
  ["INTERRUPTIBLE"]                  = { op = "CTX_BOOL", field = "targetCastingInterruptible", inv = false },
  ["NOT target.casting_interruptible"] = { op = "CTX_BOOL", field = "targetCastingInterruptible", inv = true },
  ["NOT target.interruptible"]       = { op = "CTX_BOOL", field = "targetCastingInterruptible", inv = true },
  ["NOT INTERRUPTIBLE"]              = { op = "CTX_BOOL", field = "targetCastingInterruptible", inv = true },
  ["target.casting_uninterruptible"] = { op = "UNINTERRUPTIBLE" },
  ["UNINTERRUPTIBLE"]                = { op = "UNINTERRUPTIBLE" },
  ["target.is_casting"]              = { op = "CTX_BOOL", field = "targetIsCasting", inv = false },
  ["target.casting"]                 = { op = "CTX_BOOL", field = "targetIsCasting", inv = false },
  ["NOT target.is_casting"]          = { op = "CTX_BOOL", field = "targetIsCasting", inv = true },
  ["NOT target.casting"]             = { op = "CTX_BOOL", field = "targetIsCasting", inv = true },
}

local CTX_NUM_FIELDS = {
  ["enemies"]                = { field = "enemies",     def = 1 },
  ["enemies_around"]         = { field = "enemies",     def = 1 },
  ["active_enemies"]         = { field = "enemies",     def = 1 },
  ["player.enemies"]         = { field = "enemies",     def = 1 },
  ["target.enemies"]         = { field = "enemies",     def = 1 },
  ["player.combo_points"]    = { field = "comboPoints", def = 0 },
  ["COMBO_POINTS"]           = { field = "comboPoints", def = 0 },
  ["cp"]                     = { field = "comboPoints", def = 0 },
  ["player.energy"]          = { field = "energy",      def = 100 },
  ["ENERGY"]                 = { field = "energy",      def = 100 },
  ["energy"]                 = { field = "energy",      def = 100 },
  ["player.astral_power"]    = { field = "insanity",    def = 0 },
  ["player.insanity"]        = { field = "insanity",    def = 0 },
  ["player.power"]           = { field = "insanity",    def = 0 },
  ["ASTRAL_POWER"]           = { field = "insanity",    def = 0 },
  ["INSANITY"]               = { field = "insanity",    def = 0 },
  ["player.hp_percent"]      = { field = "playerHP",    def = 100 },
  ["target.hp_percent"]      = { field = "targetHP",    def = 100 },
  ["target.freezing_stacks"] = { field = "STACKS",      def = 0 },
  ["target.debuff_stacks"]   = { field = "STACKS",      def = 0 },
  ["target.shatter_stacks"]  = { field = "STACKS",      def = 0 },
  ["STACKS"]                 = { field = "STACKS",      def = 0 },
}

local function CompileAtomicClause(c)
  local staticDef = STATIC_CLAUSES[c]
  if staticDef then
    return staticDef
  end

  local aUnit, aKey, aProp, aOp, aVal = c:match("^([a-zA-Z]+)%.aura%(([A-Za-z0-9_]+)%)%.([a-zA-Z_]+)%s*([><=]+)%s*([%d%.]+)$")
  if aUnit and aKey and aProp and aOp and aVal then
    local propLow = aProp:lower()
    return {
      op = "AURA_PROP",
      u = (aUnit:lower() == "player") and "player" or "target",
      k = aKey:upper(),
      isStacks = (propLow == "stacks" or propLow == "stack" or propLow == "applications"),
      cmp = aOp,
      val = tonumber(aVal) or 0,
    }
  end

  local invAura, bUnit, bKey = c:match("^(NOT%s+)?([a-zA-Z]+)%.aura%(([A-Za-z0-9_]+)%)$")
  if bUnit and bKey then
    return {
      op = "AURA_BOOL",
      u = (bUnit:lower() == "player") and "player" or "target",
      k = bKey:upper(),
      inv = (invAura ~= nil and invAura ~= ""),
    }
  end

  local chSp, chOp, chVal = c:match("^CHARGES%(([A-Z0-9_]+)%)%s*([><=]+)%s*(%d+)$")
  if chSp and chOp and chVal then
    return {
      op = "CHARGES",
      k = chSp,
      cmp = chOp,
      val = tonumber(chVal) or 0,
    }
  end

  local invFn, fnName, fnArg = c:match("^(NOT%s+)?([A-Z]+)%(([A-Z0-9_]+)%)$")
  if fnName and fnArg then
    local isInv = (invFn ~= nil and invFn ~= "")
    if fnName == "PROC" and fnArg == "VOID_BLAST" then
      fnArg = "MIND_BLAST"
    end
    return {
      op = fnName,
      k = fnArg,
      inv = isInv,
    }
  end

  local lhs, numOp, numVal = c:match("^([A-Za-z0-9_%.]+)%s*([><=]+)%s*([%d%.]+)$")
  if lhs and numOp and numVal then
    local meta = CTX_NUM_FIELDS[lhs]
    if meta then
      return {
        op = (meta.field == "STACKS") and "STACKS" or "CTX_NUM",
        field = meta.field,
        def = meta.def,
        cmp = numOp,
        val = tonumber(numVal) or 0,
      }
    end
  end

  return STATIC_CLAUSES["ALWAYS"]
end

local function EvalAtomicClause(cl, simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges, simBurst, simActive, simCtx)
  local op = cl.op
  if op == "ALWAYS" then
    return true
  elseif op == "AURA_PROP" then
    local curR, curS = GetSimAura(simCtx, cl.u, cl.k)
    return CompareNum(cl.isStacks and curS or curR, cl.cmp, cl.val)
  elseif op == "AURA_BOOL" then
    local curR = GetSimAura(simCtx, cl.u, cl.k)
    return cl.inv and (curR <= 0) or (curR > 0)
  elseif op == "READY" then
    local r = simReady[cl.k] and true or false
    return cl.inv and (not r) or r
  elseif op == "USABLE" then
    local u = (simReady[cl.k] and simUsable[cl.k]) and true or false
    return cl.inv and (not u) or u
  elseif op == "PROC" then
    local p = simProcs[cl.k] and true or false
    return cl.inv and (not p) or p
  elseif op == "CHARGES" then
    return CompareNum((simCharges and simCharges[cl.k]) or 0, cl.cmp, cl.val)
  elseif op == "CTX_NUM" then
    local cur = (simCtx and simCtx[cl.field]) or cl.def
    return CompareNum(cur, cl.cmp, cl.val)
  elseif op == "CTX_BOOL" then
    local b = (simCtx and simCtx[cl.field]) and true or false
    return cl.inv and (not b) or b
  elseif op == "BURST" then
    local b = simBurst and true or false
    return cl.inv and (not b) or b
  elseif op == "HAS_DOTS" then
    local d = simHasDoTs and true or false
    return cl.inv and (not d) or d
  elseif op == "ACTIVE" then
    local rP = (simCtx and simCtx.auraRem and simCtx.auraRem.player and simCtx.auraRem.player[cl.k]) or 0
    local rT = (simCtx and simCtx.auraRem and simCtx.auraRem.target and simCtx.auraRem.target[cl.k]) or 0
    local act = (rP > 0 or rT > 0 or (simActive and simActive[cl.k])) and true or false
    return cl.inv and (not act) or act
  elseif op == "BUFF" then
    local rP = (simCtx and simCtx.auraRem and simCtx.auraRem.player and simCtx.auraRem.player[cl.k]) or 0
    return cl.inv and (rP <= 0) or (rP > 0)
  elseif op == "DOT" then
    local rT = (simCtx and simCtx.auraRem and simCtx.auraRem.target and simCtx.auraRem.target[cl.k]) or 0
    return cl.inv and (rT <= 1.0) or (rT > 1.0)
  elseif op == "UNINTERRUPTIBLE" then
    return (simCtx and simCtx.targetIsCasting and not simCtx.targetCastingInterruptible) and true or false
  elseif op == "STACKS" then
    return CompareNum(simStacks or 0, cl.cmp, cl.val)
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
        clauses[#clauses + 1] = CompileAtomicClause(c)
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
local usedInQueue = {}
local simAuraRem = { target = {}, player = {} }
local simAuraStacks = { target = {}, player = {} }
local simCtx = { auraRem = simAuraRem, auraStacks = simAuraStacks }
local EMPTY_TABLE = {}

function SpArc:BuildRotationQueue(maxSlots)
  local db = SpArc:EnsureDB()
  local now = GetTime()
  maxSlots = maxSlots or (db.visual and db.visual.queueLength) or 5
  SpArc:RefreshTrackedInsanity()
  local assistedKey, assistedSpellID = SpArc:GetAssistedSuggestedDefKey()
  if assistedKey and SPELL_DEFS[assistedKey] and SPELL_DEFS[assistedKey].isSpender then
    local aCost = SPELL_DEFS[assistedKey].insanityCost or 50
    if st.trackedInsanity < aCost then
      st.trackedInsanity = aCost
    end
  end

  local parsed = SpArc:SelectActiveParsedProfile()
  st.secretInterruptOverlay = nil
  if not parsed or not parsed.rules then
    return EMPTY_TABLE, EMPTY_TABLE, parsed, nil, false, false
  end

  for k in pairs(simAuraRem.target) do simAuraRem.target[k] = nil end
  for k in pairs(simAuraRem.player) do simAuraRem.player[k] = nil end
  for k in pairs(simAuraStacks.target) do simAuraStacks.target[k] = nil end
  for k in pairs(simAuraStacks.player) do simAuraStacks.player[k] = nil end
  for k in pairs(usedInQueue) do usedInQueue[k] = nil end

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
  if auraMap["MAELSTROM_WEAPON"] then
    local mwSpenderSuggested = (assistedKey == "LIGHTNING_BOLT" or assistedKey == "TEMPEST" or assistedKey == "CHAIN_LIGHTNING" or assistedKey == "ELEMENTAL_BLAST")
      or (states["LIGHTNING_BOLT"] and states["LIGHTNING_BOLT"].isProc)
      or (states["CHAIN_LIGHTNING"] and states["CHAIN_LIGHTNING"].isProc)
    if mwSpenderSuggested then
      if (simAuraStacks.player["MAELSTROM_WEAPON"] or 0) < 10 then
        simAuraStacks.player["MAELSTROM_WEAPON"] = 10
        simAuraStacks.player["344179"] = 10
      end
      if (simAuraRem.player["MAELSTROM_WEAPON"] or 0) <= 0 then
        simAuraRem.player["MAELSTROM_WEAPON"] = 15
        simAuraRem.player["344179"] = 15
      end
    elseif assistedKey then
      if (simAuraStacks.player["MAELSTROM_WEAPON"] or 0) >= 8 then
        simAuraStacks.player["MAELSTROM_WEAPON"] = 5
        simAuraStacks.player["344179"] = 5
      elseif (simAuraRem.player["MAELSTROM_WEAPON"] or 0) > 0 and (simAuraStacks.player["MAELSTROM_WEAPON"] or 0) <= 1 then
        local estMW = math.max(2, math.min(7, st.maelstromWeaponStacks or 4))
        simAuraStacks.player["MAELSTROM_WEAPON"] = estMW
        simAuraStacks.player["344179"] = estMW
      end
    end
    st.maelstromWeaponStacks = simAuraStacks.player["MAELSTROM_WEAPON"] or 0
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
  local unshiftActiveHere = (SpArc.IsAutoUnshiftActiveHere and SpArc:IsAutoUnshiftActiveHere())
    or (not SpArc.IsAutoUnshiftActiveHere and (not SpArc.IsAutoUnshiftEnabled or SpArc:IsAutoUnshiftEnabled()))
  if not simCtx.inCombat and not hasHostileTarget and not SpArc.testMode and unshiftActiveHere then
    simAuraRem.player["MOONKIN_FORM"] = 3600
    simAuraRem.player["24858"] = 3600
    simAuraRem.player["SHADOWFORM"] = 3600
    simAuraRem.player["232698"] = 3600
    simAuraRem.player["LIGHTNING_SHIELD"] = 3600
    simAuraRem.player["192106"] = 3600
    simAuraRem.player["EARTH_SHIELD"] = 3600
    simAuraRem.player["974"] = 3600
    simAuraRem.player["383648"] = 3600
  end
  simCtx.canPickPocket = (SpArc.CanPickPocketTarget and SpArc:CanPickPocketTarget(now)) or false
  simCtx.bossMode = (SpArc.IsBossRotationEnabled and SpArc:IsBossRotationEnabled()) or false
  simCtx.pvpMode = (SpArc.IsPvPRotationEnabled and SpArc:IsPvPRotationEnabled()) or false
  local tCast, tInt, _, _, _, _, _, _, rawNotInt = false, false, false, nil, nil, 0, 0, nil, nil
  if SpArc.GetUnitCastInterruptState then
    tCast, tInt, _, _, _, _, _, _, rawNotInt = SpArc:GetUnitCastInterruptState("target", now)
  end
  local isSecretCastInt = (tCast and rawNotInt ~= nil and IsSecret(rawNotInt)) or false
  simCtx.targetIsCasting = tCast or false
  simCtx.targetCastingInterruptible = (tCast and not isSecretCastInt and tInt) or false
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
      if states[spKey] and states[spKey].isOutOfRange then
        return false
      end
    end
    if stepIdx and stepIdx >= 2 then
      if usedInQueue[spKey] or (d.overrideOf and usedInQueue[d.overrideOf]) then
        return false
      end
      if auraMap["MAELSTROM_WEAPON"] and (spKey == "TEMPEST" or spKey == "LIGHTNING_BOLT" or spKey == "CHAIN_LIGHTNING" or spKey == "ELEMENTAL_BLAST") then
        if (simAuraStacks.player["MAELSTROM_WEAPON"] or 0) < 8 then
          return false
        end
      end
    end
    -- Never suggest a 2nd charge of a burst or boss cooldown while its burst window/buff is already active!
    if (d.burstDuration and d.burstDuration > 0) or d.isBossSkill then
      local u = d.auraUnit or "player"
      local rem = (simCtx.auraRem and simCtx.auraRem[u] and simCtx.auraRem[u][spKey]) or 0
      if simActive[spKey] or rem > 1.5 then
        return false
      end
      -- If Power Infusion shares the same macro button as Void Eruption (e.g. 1_to_2 on Q),
      -- do not prompt Power Infusion alone while Void Eruption is still on cooldown!
      if spKey == "POWER_INFUSION" and states["VOID_ERUPTION"] and not states["VOID_ERUPTION"].isUnavailable then
        local piKB = states["POWER_INFUSION"] and states["POWER_INFUSION"].keybind
        local veKB = states["VOID_ERUPTION"].keybind
        if piKB and piKB ~= "" and piKB == veKB then
          if not states["VOID_ERUPTION"].isReady and not simActive["VOID_ERUPTION"] then
            return false
          end
        end
      end
    end
    return true
  end

  if isSecretCastInt and not SpArc.testMode then
    for spK in pairs(SPELL_DEFS) do
      simReady[spK] = simKnown[spK] and (states[spK] and states[spK].isReady == true) and (simCD[spK] <= 0.05) or false
    end
    simCtx.targetCastingInterruptible = true
    for _, rule in ipairs(parsed.rules) do
      local sp = rule.spell
      local d = SPELL_DEFS[sp]
      local s = states[sp]
      if d and d.isInterrupt and simReady[sp] and simUsable[sp] and not simNoResource[sp] and s and not s.isOutOfRange and not s.isUnavailable then
        if IsSpellAllowedByToggles(sp, 1) and SpArc:EvalSingleCondition(rule.cond, simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges, simBurst, simActive, simCtx) then
          st.secretInterruptOverlay = {
            key = sp,
            icon = s.icon,
            keybind = s.keybind or "",
            rawNotInterruptible = rawNotInt,
          }
          break
        end
      end
    end
    simCtx.targetCastingInterruptible = false
  end

  local anySpellBound = false
  for _, sObj in pairs(states) do
    if sObj.keybind and sObj.keybind ~= "" then
      anySpellBound = true
      break
    end
  end

  local function IsSpellBoundOnBar(spKey)
    if SpArc.testMode or not anySpellBound then return true end
    local s = states[spKey]
    if s and s.keybind and s.keybind ~= "" then
      return true
    end
    local d = SPELL_DEFS[spKey]
    if d and d.overrideOf and states[d.overrideOf] then
      local baseKB = states[d.overrideOf].keybind
      if baseKB and baseKB ~= "" then
        return true
      end
    end
    return false
  end

  local function RefreshSimReady(stepIdx)
    for spK, spD in pairs(SPELL_DEFS) do
      if spD.procOnly and not simProcs[spK] then
        simReady[spK] = false
      elseif stepIdx == 1 then
        simReady[spK] = simKnown[spK] and (states[spK] and states[spK].isReady == true) and (simCD[spK] <= 0.05) or false
      else
        simReady[spK] = simKnown[spK] and (simCD[spK] <= 0.05) or false
      end
    end
  end

  local function AdvanceSimTime(dt)
    if not dt or dt <= 0 then return end
    for spK, spD in pairs(SPELL_DEFS) do
      local isMajorBurst = spD and (spD.isBossSkill or (spD.burstDuration and spD.burstDuration > 0) or ((spD.baseCD or 0) >= 30))
      if not isMajorBurst and simCD[spK] and simCD[spK] > 0 and simCD[spK] < 9000 then
        simCD[spK] = math.max(0, simCD[spK] - dt)
        if simCD[spK] <= 0.05 and (spD.liveMaxCharges or spD.maxCharges or 1) > 1 and (simCharges[spK] or 0) <= 0 then
          simCharges[spK] = 1
        end
      end
    end
    for aK, rVal in pairs(simAuraRem.target) do
      if rVal and rVal > 0 and rVal < 9000 then
        simAuraRem.target[aK] = math.max(0, rVal - dt)
      end
    end
    for aK, rVal in pairs(simAuraRem.player) do
      if rVal and rVal > 0 and rVal < 9000 then
        simAuraRem.player[aK] = math.max(0, rVal - dt)
      end
    end
  end

  local function SetSimAuraState(u, aKey, newSt, newRem)
    if newSt ~= nil then
      simAuraStacks[u][aKey] = newSt
    end
    if newRem ~= nil then
      simAuraRem[u][aKey] = newRem
    elseif newSt ~= nil and newSt <= 0 then
      simAuraRem[u][aKey] = 0
    end
    local aDef = auraMap[aKey] or SPELL_DEFS[aKey]
    local aIDs = aDef and (aDef.auraIDs or aDef.debuffIDs or aDef.ids)
    if aIDs then
      for _, aID in ipairs(aIDs) do
        local idStr = tostring(aID)
        if newSt ~= nil then
          simAuraStacks[u][idStr] = newSt
        end
        if newRem ~= nil then
          simAuraRem[u][idStr] = newRem
        elseif newSt ~= nil and newSt <= 0 then
          simAuraRem[u][idStr] = 0
        end
        for otherKey, otherDef in pairs(auraMap) do
          local oIDs = otherDef.auraIDs or otherDef.debuffIDs or otherDef.ids
          if oIDs then
            for _, oID in ipairs(oIDs) do
              if oID == aID then
                if newSt ~= nil then
                  simAuraStacks[u][otherKey] = newSt
                end
                if newRem ~= nil then
                  simAuraRem[u][otherKey] = newRem
                elseif newSt ~= nil and newSt <= 0 then
                  simAuraRem[u][otherKey] = 0
                end
              end
            end
          end
        end
      end
    end
  end

  local function PickMatchingRule(stepIdx, onlyInterrupt, skipKey, noResMode)
    for _, rule in ipairs(parsed.rules) do
      local sp = rule.spell
      if sp ~= skipKey and simReady[sp] and simUsable[sp] and IsSpellBoundOnBar(sp) and IsSpellAllowedByToggles(sp, stepIdx) then
        local d = SPELL_DEFS[sp]
        local intOk = (not onlyInterrupt) or (d and d.isInterrupt)
        local resOk = (noResMode == "any")
          or (noResMode == "exclude" and not simNoResource[sp])
          or (noResMode == "only" and simNoResource[sp])
        if intOk and resOk and SpArc:EvalSingleCondition(rule.cond, simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges, simBurst, simActive, simCtx) then
          return sp, rule
        end
      end
    end
    return nil, nil
  end

  for step = 1, maxSlots do
    RefreshSimReady(step)

    local pickedKey = nil
    local pickedRule = nil
    local pickedIsNoResource = false
    local handledDynamicSlot1 = false

    if step == 1 then
      -- Priority 0: Interrupts from .MD if target is actively casting an interruptible spell
      if simCtx.targetCastingInterruptible then
        pickedKey, pickedRule = PickMatchingRule(1, true, nil, "exclude")
      end

      -- Smart Arbiter ("Trust Blizzard Helper, but override when it lags or lies"):
      -- Check if .MD has an immediate Ready & Usable action that should supersede a stale/blind Assisted Combat suggestion
      if not pickedKey and not SpArc.testMode then
        local mdKey, mdRule = PickMatchingRule(1, false, nil, "exclude")
        local sMD = mdKey and states[mdKey]
        local sA = assistedKey and states[assistedKey]
        if mdKey and sMD and sMD.isReady and sMD.isUsable and not sMD.isNoResource then
          local condStr = (mdRule and type(mdRule.cond) == "string") and mdRule.cond or ""
          local isLowHpEmergency = (simCtx.playerHP <= 45) and (condStr:find("player.hp", 1, true) ~= nil or condStr:find("HP", 1, true) ~= nil)
          local isStealthOpener = simCtx.stealthed and (mdKey == "PICK_POCKET" or condStr:find("STEALTH", 1, true) ~= nil or condStr:find("stealthed", 1, true) ~= nil)
          local assistIsStaleOrOnCD = sA and ((not sA.isReady and (sA.remSec or 0) > 0.35) or sA.isNoResource or not sA.isUsable)
          local isHigherPriorityProc = false
          if sMD.isProc and sA and not sA.isProc and mdKey ~= assistedKey then
            for _, r in ipairs(parsed.rules) do
              if r == mdRule then
                isHigherPriorityProc = true
                break
              elseif r.spell == assistedKey then
                break
              end
            end
          end
          if isLowHpEmergency or isStealthOpener or assistIsStaleOrOnCD or isHigherPriorityProc then
            pickedKey = mdKey
            pickedRule = mdRule
          end
        end
      end

      -- Primary Slot #1: Follow Blizzard Assisted Combat (C_AssistedCombat.GetNextCastSpell) when active
      if not pickedKey and not SpArc.testMode then
        if assistedKey and SPELL_DEFS[assistedKey] and states[assistedKey] then
          pickedKey = assistedKey
          local sA = states[assistedKey]
          local dA = SPELL_DEFS[assistedKey]
          sA.isUnavailable = false
          if (not sA.keybind or sA.keybind == "") and dA.overrideOf and states[dA.overrideOf] and states[dA.overrideOf].keybind ~= "" then
            sA.keybind = states[dA.overrideOf].keybind
          end
          simKnown[assistedKey] = true
          simUsable[assistedKey] = true
          if simCD[assistedKey] and simCD[assistedKey] > 0.05 and simCD[assistedKey] <= 18.0 then
            AdvanceSimTime(simCD[assistedKey])
          end
          simCD[assistedKey] = 0
          simReady[assistedKey] = true
          for _, rule in ipairs(parsed.rules) do
            if rule.spell == assistedKey then
              if not pickedRule then pickedRule = rule end
              if SpArc:EvalSingleCondition(rule.cond, simHasDoTs, simReady, simUsable, simProcs, simStacks, simCharges, simBurst, simActive, simCtx) then
                pickedRule = rule
                break
              end
            end
          end
        elseif assistedSpellID and assistedSpellID > 0 and SpArc.GetDynamicAssistedSpellMeta then
          local dynIcon, dynKB, dynSlot = SpArc:GetDynamicAssistedSpellMeta(assistedSpellID)
          local dynKey = "ASSIST_" .. tostring(assistedSpellID)
          local dynOOR = (SpArc.IsSpellOutOfRange and SpArc:IsSpellOutOfRange(dynKey, nil, assistedSpellID, dynSlot, true)) or false
          qCount = qCount + 1
          local qItem = queue[qCount]
          if not qItem then
            qItem = {}
            queue[qCount] = qItem
          end
          qItem.key = dynKey
          qItem.icon = dynIcon or 134400
          qItem.keybind = dynKB or ""
          qItem.isProc = false
          qItem.isReady = true
          qItem.isUsable = true
          qItem.isNoResource = false
          qItem.resWaitSec = 0
          qItem.isOutOfRange = dynOOR
          qItem.isUnavailable = false
          usedInQueue[dynKey] = true
          AdvanceSimTime(1.4)
          handledDynamicSlot1 = true
        end
      end
    end

    if not handledDynamicSlot1 then
      if not pickedKey then
        pickedKey, pickedRule = PickMatchingRule(step, false, nil, step == 1 and "exclude" or "any")
      end

      if not pickedKey and step == 1 then
        pickedKey, pickedRule = PickMatchingRule(1, false, nil, "only")
        if pickedKey then
          pickedIsNoResource = true
        end
      end

      -- Cooldown Lookahead Fast-Forward: if all bound rotational rules in .MD are currently on cooldown,
      -- advance virtual time to the soonest rotational cooldown so Slots #2..#N show the upcoming priority order
      if not pickedKey then
        local prevKey = (qCount > 0 and queue[qCount] and queue[qCount].key) or nil
        for _ = 1, 3 do
          local minWaitDiff = nil
          local minWaitAny = nil
          for _, rule in ipairs(parsed.rules) do
            local sp = rule.spell
            local spD = SPELL_DEFS[sp]
            local cdRem = simCD[sp] or 9999
            if spD and simKnown[sp] and simUsable[sp] and IsSpellBoundOnBar(sp) and IsSpellAllowedByToggles(sp, step)
              and not spD.procOnly and not spD.isInterrupt and not spD.isBossSkill
              and not (spD.burstDuration and spD.burstDuration > 0) and (spD.baseCD or 0) < 30
              and cdRem > 0.05 and cdRem <= 18.0 then
              if not minWaitAny or cdRem < minWaitAny then
                minWaitAny = cdRem
              end
              if sp ~= prevKey and (not minWaitDiff or cdRem < minWaitDiff) then
                minWaitDiff = cdRem
              end
            end
          end
          local minWait = (minWaitDiff and (not minWaitAny or minWaitDiff <= minWaitAny + 3.5)) and minWaitDiff or minWaitAny
          if not minWait then
            break
          end
          AdvanceSimTime(minWait + 0.01)
          RefreshSimReady(2)
          pickedKey, pickedRule = PickMatchingRule(step, false, prevKey, "any")
          if not pickedKey then
            pickedKey, pickedRule = PickMatchingRule(step, false, nil, "any")
          end
          if pickedKey then
            break
          end
        end
      end

      if pickedKey and states[pickedKey] and not states[pickedKey].isUnavailable then
        local s = states[pickedKey]
        local def = SPELL_DEFS[pickedKey]
        local isAssistedSlot1 = (step == 1 and not SpArc.testMode and pickedKey == assistedKey)
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
        qItem.isReady = (step == 1) and (isAssistedSlot1 or s.isReady) or true
        qItem.isUsable = (step == 1) and ((isAssistedSlot1 or s.isUsable) and not s.isNoResource) or true
        qItem.isNoResource = (step == 1 and (pickedIsNoResource or s.isNoResource or (not isAssistedSlot1 and s.isReady and not s.isUsable))) or false
        qItem.resWaitSec = (qItem.isNoResource and s.resWaitSec and s.resWaitSec > 0) and s.resWaitSec or 2.8
        qItem.isOutOfRange = s.isOutOfRange or false
        qItem.isUnavailable = s.isUnavailable or false
        usedInQueue[pickedKey] = true
        if def and def.overrideOf then
          usedInQueue[def.overrideOf] = true
        end

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
            SetSimAuraState(u, pickedKey, math.max(1, simAuraStacks[u][pickedKey] or 1), aDur)
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
            simKnown[def.grantsProc] = true
            simProcs[def.grantsProc] = true
            simCD[def.grantsProc] = 0
            simReady[def.grantsProc] = true
            simUsable[def.grantsProc] = true
          end
          if def.consumesStacks and not pickedWasProc then
            local cost = (def.stacksCost and def.stacksCost > 0) and def.stacksCost or 4
            local tKey = def.auraKey or "FREEZING"
            local u = def.auraUnit or (auraMap[tKey] and auraMap[tKey].auraUnit) or "target"
            local newSt = math.max(0, (simAuraStacks[u][tKey] or simStacks or 0) - cost)
            if tKey == "FREEZING" then simStacks = newSt end
            SetSimAuraState(u, tKey, newSt)
          end
          if def.stacksGain and def.stacksGain > 0 then
            local tKey = def.auraKey or "FREEZING"
            local u = def.auraUnit or (auraMap[tKey] and auraMap[tKey].auraUnit) or "target"
            local newSt = math.min(20, (simAuraStacks[u][tKey] or simStacks or 0) + def.stacksGain)
            if tKey == "FREEZING" then simStacks = newSt end
            SetSimAuraState(u, tKey, newSt, def.auraDuration or 15.0)
          end
          local consumedRuleStacks = false
          if pickedRule and type(pickedRule.cond) == "string" and not (def.burstDuration and def.burstDuration > 0) and not def.isBossSkill and (def.baseCD or 0) < 15 then
            for uRaw, aKey, prop, op, valStr in pickedRule.cond:gmatch("([a-zA-Z]+)%.aura%(([A-Za-z0-9_]+)%)%.([a-zA-Z_]+)%s*([><=]+)%s*([%d%.]+)") do
              local u = (uRaw:lower() == "player") and "player" or "target"
              local pLow = prop:lower()
              if (pLow == "stacks" or pLow == "stack" or pLow == "applications") and (op == ">=" or op == ">" or op == "==" or op == "=") then
                local thresh = tonumber(valStr) or 1
                local curSt = simAuraStacks[u][aKey] or 0
                local cost = (def.stacksCost and def.stacksCost > 0) and def.stacksCost or math.max(thresh, 10)
                local newSt = math.max(0, curSt - cost)
                if aKey == "FREEZING" then simStacks = newSt end
                SetSimAuraState(u, aKey, newSt)
                consumedRuleStacks = true
              end
            end
          end
          if not consumedRuleStacks and (pickedKey == "LIGHTNING_BOLT" or pickedKey == "CHAIN_LIGHTNING" or pickedKey == "TEMPEST" or pickedKey == "ELEMENTAL_BLAST") then
            local curMW = simAuraStacks.player["MAELSTROM_WEAPON"] or 0
            if curMW > 0 then
              SetSimAuraState("player", "MAELSTROM_WEAPON", math.max(0, curMW - 10))
            end
          elseif auraMap["MAELSTROM_WEAPON"] and (pickedKey == "STORMSTRIKE" or pickedKey == "WINDSTRIKE" or pickedKey == "LAVA_LASH" or pickedKey == "CRASH_LIGHTNING" or pickedKey == "VOLTAIC_BLAZE" or pickedKey == "SUNDERING" or pickedKey == "ICE_STRIKE") then
            local curMW = simAuraStacks.player["MAELSTROM_WEAPON"] or 0
            SetSimAuraState("player", "MAELSTROM_WEAPON", math.min(10, curMW + 2), 30.0)
          end
          if def.procOnly or def.isSpender or def.isExecute then
            simCD[pickedKey] = 9999
            simReady[pickedKey] = false
            simUsable[pickedKey] = false
          elseif (def.burstDuration and def.burstDuration > 0) or def.isBossSkill then
            -- Never queue a 2nd charge of a burst immediately after the 1st charge in the same queue preview
            simActive[pickedKey] = true
            simCD[pickedKey] = math.max(def.burstDuration or 15, def.baseCD or 30)
            simReady[pickedKey] = false
            if pickedKey == "VOID_ERUPTION" and states["POWER_INFUSION"] and s.keybind ~= "" and s.keybind == states["POWER_INFUSION"].keybind then
              simActive["POWER_INFUSION"] = true
              simCD["POWER_INFUSION"] = 120
              simReady["POWER_INFUSION"] = false
            end
          elseif (def.liveMaxCharges or def.maxCharges or 1) > 1 then
            if def.oncePerQueue then
              simCharges[pickedKey] = 0
              simCD[pickedKey] = def.liveChargeCD or def.baseCD or 15
              simReady[pickedKey] = false
            else
              simCharges[pickedKey] = (simCharges[pickedKey] or 1) - 1
              if simCharges[pickedKey] <= 0 then
                simCD[pickedKey] = def.liveChargeCD or def.baseCD or 7.5
                simReady[pickedKey] = false
              elseif def.baseCD and def.baseCD > 1.6 then
                simCD[pickedKey] = 1.4
                simReady[pickedKey] = false
              end
            end
          elseif (def.liveChargeCD and def.liveChargeCD > 0) or (def.baseCD and def.baseCD > 0) then
            simCD[pickedKey] = def.liveChargeCD or def.baseCD
            simReady[pickedKey] = false
          else
            simCD[pickedKey] = 0
          end
        end

        AdvanceSimTime(1.4)

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
      else
        break
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

  if SpArc.RecordModuleTick then
    SpArc:RecordModuleTick("Evaluator", queue[1] and queue[1].key or "EmptyQueue")
  end
  if SpArc.AssertContract then
    SpArc:AssertContract("Evaluator", type(queue) == "table" and type(states) == "table", "BUILD_QUEUE_RET", "BuildRotationQueue must return valid queue and states tables")
  end

  return queue, states, parsed, activeChannelKey, shouldInterruptChannel, isProtectedChannel
end

-- @techdebt [AUDIT-EV1]: Shares ~100 lines of state-transition logic with BuildRotationQueue lookahead loop;
--                        extract into unified ApplySpellCastTransition() in Phase 2.
function SpArc:RecordSpellCastSuccess(defKey, now)
  st.lastAnyCastAt = now
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
    local auraMap = (st.activeParsed and st.activeParsed.auras) or SPELL_DEFS
    local u = def.auraUnit or (auraMap and auraMap[tKey] and auraMap[tKey].auraUnit) or "target"
    local uMap = st.unitAuras[u]
    local prev = uMap[tKey]
    local newSt = math.max(0, ((prev and prev.stacks) or (tKey == "FREEZING" and st.targetDebuffStacks) or 0) - cost)
    if tKey == "FREEZING" then st.targetDebuffStacks = newSt end
    uMap[tKey] = { untilTime = (newSt > 0 and prev and prev.untilTime) or 0, stacks = newSt }
  end
  if def.stacksGain and def.stacksGain > 0 then
    local tKey = def.auraKey or "FREEZING"
    local auraMap = (st.activeParsed and st.activeParsed.auras) or SPELL_DEFS
    local u = def.auraUnit or (auraMap and auraMap[tKey] and auraMap[tKey].auraUnit) or "target"
    local uMap = st.unitAuras[u]
    local prev = uMap[tKey]
    local newSt = math.min(20, ((prev and prev.stacks) or (tKey == "FREEZING" and st.targetDebuffStacks) or 0) + def.stacksGain)
    local newUntil = now + (def.auraDuration or 15.0)
    if tKey == "FREEZING" then
      st.targetDebuffStacks = newSt
      st.targetDebuffUntil = newUntil
    end
    uMap[tKey] = { untilTime = newUntil, stacks = newSt }
  end
  if defKey == "LIGHTNING_BOLT" or defKey == "CHAIN_LIGHTNING" or defKey == "TEMPEST" or defKey == "ELEMENTAL_BLAST" then
    local curMW = math.max(0, (st.maelstromWeaponStacks or 0) - 10)
    st.maelstromWeaponStacks = curMW
    if st.unitAuras and st.unitAuras.player then
      st.unitAuras.player["MAELSTROM_WEAPON"] = curMW > 0 and { untilTime = now + 30.0, stacks = curMW } or nil
      st.unitAuras.player[344179] = st.unitAuras.player["MAELSTROM_WEAPON"]
      st.unitAuras.player["344179"] = st.unitAuras.player["MAELSTROM_WEAPON"]
    end
  elseif defKey == "STORMSTRIKE" or defKey == "WINDSTRIKE" or defKey == "LAVA_LASH" or defKey == "CRASH_LIGHTNING" or defKey == "VOLTAIC_BLAZE" or defKey == "SUNDERING" or defKey == "ICE_STRIKE" then
    local curMW = math.min(10, (st.maelstromWeaponStacks or 0) + 2)
    st.maelstromWeaponStacks = curMW
    if st.unitAuras and st.unitAuras.player then
      local mwEntry = { untilTime = now + 30.0, stacks = curMW }
      st.unitAuras.player["MAELSTROM_WEAPON"] = mwEntry
      st.unitAuras.player[344179] = mwEntry
      st.unitAuras.player["344179"] = mwEntry
    end
  end
  local maxCh = def.liveMaxCharges or def.maxCharges or 1
  if maxCh > 1 or (def.baseCD and def.baseCD > 0 and def.baseCD <= 30) then
    SpArc:GetTrackedSpellCharges(defKey, now)
    local used = st.spellChargesUsed[defKey] or 0
    if st.lastOverlayProcAt and st.lastOverlayProcAt[defKey] then
      st.lastOverlayProcAt[defKey] = nil
    end
    if used == 0 or not st.spellChargeStart[defKey] or st.spellChargeStart[defKey] <= 0 then
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
eventFrame:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", "player")
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
    local nowSent = GetTime()
    st.lastAnyCastAt = nowSent
    spellID = arg4
    local defKey = (spellID and not IsSecret(spellID) and SpArc:MatchSpellToDefKey(spellID, nil))
      or ((st.lastPressedAt and (nowSent - st.lastPressedAt) < 0.8) and st.lastPressedDefKey)
      or nil
    if defKey == "PICK_POCKET" and SpArc.MarkTargetPickPocketed then
      SpArc:MarkTargetPickPocketed(false)
    end
    if defKey and SpArc.TriggerSpellPress then
      SpArc:TriggerSpellPress(defKey, nil, nil)
    end
    if SpArc.SnapshotNameplateCastTarget then
      SpArc:SnapshotNameplateCastTarget(spellID, defKey, false, nowSent)
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
    if SpArc.RequestSlotScan then
      SpArc:RequestSlotScan()
    else
      SpArc:ScanActionSlotsAndSpells(true)
    end
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
      or ((st.lastPressedAt and (now - st.lastPressedAt) < 0.8) and st.lastPressedDefKey)
      or nil
    if defKey then
      st.lastHardCastStartAt = st.lastHardCastStartAt or {}
      st.lastHardCastStartAt[defKey] = now
      st.castingDefKey = defKey
      if SpArc.TriggerSpellPress then
        SpArc:TriggerSpellPress(defKey, nil, nil)
      end
    end
    if SpArc.SnapshotNameplateCastTarget then
      SpArc:SnapshotNameplateCastTarget(spellID, defKey, true, now)
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
      or ((st.lastPressedAt and (now - st.lastPressedAt) < 0.8) and st.lastPressedDefKey)
      or nil
    if defKey then
      st.lastHardCastStartAt = st.lastHardCastStartAt or {}
      st.lastHardCastStartAt[defKey] = now
      st.castingDefKey = defKey
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
    local stillCasting = false
    if event == "UNIT_SPELLCAST_FAILED" then
      local okC, cName = pcall(UnitCastingInfo, "player")
      local okCh, chName = pcall(UnitChannelInfo, "player")
      if (okC and cName ~= nil) or (okCh and chName ~= nil) then
        stillCasting = true
      end
    end
    if not stillCasting then
      if event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        st.castingDefKey = nil
        st.hardCastMetro = nil
        st.hardCastPlateUnit = nil
      end
      st.castState.active = false
      st.castState.defKey = nil
    end
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    st.lastAnyCastAt = now
    local defKey = SpArc:MatchSpellToDefKey(spellID, sName)
      or st.castingDefKey
      or ((st.lastPressedAt and (now - st.lastPressedAt) < 1.0) and st.lastPressedDefKey)
      or nil
    st.castingDefKey = nil
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
    if SpArc.RecordNameplateAuraCast then
      SpArc:RecordNameplateAuraCast(spellID, defKey, now, wasHardCast)
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
    uEv.interruptible = nil
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
