---------------------------------------------------------------------------------------
--  SpArc/Nameplates.lua — Minimalist Windows Metro Tile Nameplates, Castbar & Aura Colors
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
--  @module Nameplates
--  @responsibility
--    1. Attaches non-tainting Metro Tile overlays to Blizzard nameplates (`NAME_PLATE_UNIT_ADDED`).
--    2. Compiles and evaluates `.MD` + user DoT/Aura color rules (`CompileNameplateAuraRules`).
--    3. Renders WoW 12.x Secret-Value-safe health bars (`StatusBar:SetValue`), castbars
--       (`SetTimerDuration` + event fallback), Quest NPC badges, and distance fade.
--    4. Builds Tab 10 (`BuildNameplatesPage` / `RefreshNameplatesPage`) in the Control Center.
--  @contract
--    - NEVER hides or reparents the root `NamePlateN` secure frame in combat.
--    - `SpArc:RefreshAllNameplates()` and `SpArc:CompileNameplateAuraRules()` must remain safe at any time.
--  @techdebt [AUDIT-NP1..NP3]
--    - [AUDIT-NP1] At 2,321 lines, `Nameplates.lua` is the largest file in `SpArc`, combining runtime
--      nameplate rendering (lines 1–1871) with the Tab 10 Control Center UI builder (lines 1872–2321).
--    - [AUDIT-NP2] Metro color constants (`COLOR_HOSTILE_RED`, `COLOR_NEUTRAL_YELLOW`, `COLOR_FRIENDLY_GREEN`,
--      `COLOR_CAST_GOLD`, `COLOR_CAST_GREY`), `CreateFlatBorder`, reaction color resolution, and Secret-Value
--      castbar rendering are duplicated between `Nameplates.lua` and `UnitFrames.lua`.
--      Planned Refactor (Phase 1): Extract shared Metro UI & Secret-Value bar helpers into `Core.lua`.
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc
local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local GetTime = _G.GetTime
local UnitExists = _G.UnitExists
local UnitIsUnit = _G.UnitIsUnit
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsEnemy = _G.UnitIsEnemy
local UnitIsFriend = _G.UnitIsFriend
local UnitCanAttack = _G.UnitCanAttack
local UnitReaction = _G.UnitReaction
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitName = _G.UnitName
local UnitLevel = _G.UnitLevel
local UnitClass = _G.UnitClass
local UnitGUID = _G.UnitGUID
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitNameplateShowsWidgetsOnly = _G.UnitNameplateShowsWidgetsOnly
local UnitIsGameObject = _G.UnitIsGameObject
local UnitIsTapDenied = _G.UnitIsTapDenied
local InCombatLockdown = _G.InCombatLockdown
local C_NamePlate = _G.C_NamePlate
local C_UnitAuras = _G.C_UnitAuras
local C_SpellBook = _G.C_SpellBook
local C_QuestLog = _G.C_QuestLog
local C_TooltipInfo = _G.C_TooltipInfo
local C_ClassColor = _G.C_ClassColor
local C_CVar = _G.C_CVar
local C_AddOns = _G.C_AddOns
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS
local CLASS_ICON_TCOORDS = _G.CLASS_ICON_TCOORDS
local ColorPickerFrame = _G.ColorPickerFrame
local pcall = _G.pcall
local ipairs = _G.ipairs
local pairs = _G.pairs
local tonumber = _G.tonumber
local tostring = _G.tostring
local type = _G.type
local math = _G.math
local table = _G.table
local string = _G.string
local ApplyCyrFont = SpArc.ApplyCyrFont
local IsSecret = SpArc.IsSecret
local SafeBool = SpArc.SafeBool
local GetSpellNameAndIconSafe = SpArc.GetSpellNameAndIconSafe
local st = SpArc.state
local FLAT_TEX = SpArc.FLAT_TEX
local CLASS_ICONS_TEX = SpArc.CLASS_ICONS_TEX
local METRO_COLORS = SpArc.METRO_COLORS
local COLOR_HOSTILE_RED    = METRO_COLORS.HOSTILE_RED
local COLOR_NEUTRAL_YELLOW = METRO_COLORS.NEUTRAL_YELLOW
local COLOR_FRIENDLY_GREEN = METRO_COLORS.FRIENDLY_GREEN
local COLOR_TAPPED_GREY    = METRO_COLORS.TAPPED_GREY
local COLOR_CAST_GOLD      = METRO_COLORS.CAST_GOLD
-- Known Cast Spell ID <-> Debuff Aura ID aliases (strictly 1-to-1 spell/debuff pairs; never assume optional talents!)
local SPELL_AURA_ALIASES = {
  [8921]    = { 164812 },         -- Moonfire (cast) -> Moonfire (debuff)
  [164812]  = { 8921 },           -- Moonfire (debuff) -> Moonfire (cast)
  [93402]   = { 164815 },         -- Sunfire (cast) -> Sunfire (debuff)
  [164815]  = { 93402 },          -- Sunfire (debuff) -> Sunfire (cast)
  [1822]    = { 155722 },         -- Rake (cast) -> Rake (debuff)
  [155722]  = { 1822 },           -- Rake (debuff) -> Rake (cast)
  [285381]  = { 1079 },           -- Primal Wrath -> Rip
  [1079]    = { 285381 },         -- Rip -> Primal Wrath
  [106832]  = { 405233, 106830 }, -- Thrash -> Thrash debuff
  [405233]  = { 106832, 106830 },
  [205385]  = { 34914 },          -- Shadow Crash -> Vampiric Touch (SW:P only if Misery 238558 is known)
  [457042]  = { 34914 },          -- Tentacle Slam / Shadow Crash -> Vampiric Touch
  [1227280] = { 34914 },          -- Tentacle Slam (12.x) -> Vampiric Touch
  [1234796] = { 34914 },          -- Tentacle Slam (12.x alt) -> Vampiric Touch
  [1247227] = { 121411 },         -- Crimson Tempest
  [121411]  = { 1247227 },
  [384318]  = { 772, 388539 },    -- Thunderous Roar / Rend
  [772]     = { 388539 },
}
-- AoE DoT spells (used ONLY to correlate secret-aura count jumps on UNIT_AURA; never blind-painted across screen!)
local AOE_DOT_SPELLS = {
  [93402]   = { auras = { 164815 }, dur = 18.0 }, -- Sunfire
  [164815]  = { auras = { 164815 }, dur = 18.0 },
  [205385]  = { auras = { 34914 },  dur = 21.0, checkMisery = true }, -- Shadow Crash
  [457042]  = { auras = { 34914 },  dur = 21.0, checkMisery = true }, -- Tentacle Slam
  [1227280] = { auras = { 34914 },  dur = 21.0, checkMisery = true }, -- Tentacle Slam (12.x)
  [1234796] = { auras = { 34914 },  dur = 21.0, checkMisery = true }, -- Tentacle Slam (12.x alt)
  [285381]  = { auras = { 1079 },   dur = 16.0 }, -- Primal Wrath
  [106832]  = { auras = { 405233 }, dur = 15.0 }, -- Thrash
  [121411]  = { auras = { 121411 }, dur = 12.0 }, -- Crimson Tempest
  [1247227] = { auras = { 121411 }, dur = 12.0 },
  [6343]    = { auras = { 772 },    dur = 15.0 }, -- Thunder Clap (Rend)
}
local DEFAULT_AURA_DURATIONS = {
  [164812] = 22.0, [8921]   = 22.0, -- Moonfire
  [164815] = 18.0, [93402]  = 18.0, -- Sunfire
  [202347] = 24.0,                  -- Stellar Flare
  [155722] = 15.0, [1822]   = 15.0, -- Rake
  [1079]   = 24.0,                  -- Rip
  [405233] = 15.0, [106832] = 15.0, -- Thrash
  [34914]  = 21.0,                  -- Vampiric Touch
  [589]    = 16.0,                  -- Shadow Word: Pain
  [335467] = 6.0,                   -- Devouring Plague
  [703]    = 18.0,                  -- Garrote
  [1943]   = 24.0,                  -- Rupture
  [121411] = 12.0,                  -- Crimson Tempest
  [360194] = 16.0,                  -- Deathmark
  [385627] = 14.0,                  -- Kingsbane
  [772]    = 15.0,                  -- Rend
}
local activeMetroPlates = {}  -- [plate] = metroFrame
local unitToMetro = {}        -- [unit] = metroFrame
local hookedBlizzFrames = {}  -- [uFrame] = true
local questCacheByGUID = {}   -- [guid] = boolean
local compiledAuraRules = {}
local elvUINPSuppressed = false
local previewColorMode = 0    -- 0 = auto cycle/base, 1..N = rule index
local UpdateMetroHealthAndColor
local UpdateMetroAuraIcons
local UpdateMetroCastbar
local FullUpdateMetroPlate
---------------------------------------------------------------------------------------
--  1. AURA RULE COMPILER & RESOLVER
---------------------------------------------------------------------------------------
local function HasPriestMisery()
  if _G.IsPlayerSpell and SafeBool(_G.IsPlayerSpell, 238558) then
    return true
  end
  if C_SpellBook and C_SpellBook.IsSpellKnown and SafeBool(C_SpellBook.IsSpellKnown, 238558) then
    return true
  end
  return false
end

local function DoesActionSlotUseMouseover(defKey)
  if not defKey or not st.spellStates then return false end
  local sObj = st.spellStates[defKey]
  local slot = sObj and sObj.slot
  if not slot or type(slot) ~= "number" or not _G.GetActionInfo or not _G.GetMacroBody then
    return false
  end
  local okA, aType, aID = pcall(_G.GetActionInfo, slot)
  if okA and aType == "macro" and aID then
    local okB, body = pcall(_G.GetMacroBody, aID)
    if okB and not IsSecret(body) and type(body) == "string" and body:lower():find("mouseover", 1, true) then
      return true
    end
  end
  return false
end

local function ParseIDListString(str)
  local list = {}
  local seen = {}
  if type(str) ~= "string" then return list end
  for numStr in str:gmatch("(%d+)") do
    local id = tonumber(numStr)
    if id and id > 0 and not seen[id] then
      seen[id] = true
      list[#list + 1] = id
    end
  end
  return list
end
function SpArc:CompileNameplateAuraRules()
  local db = SpArc:EnsureDB()
  compiledAuraRules = {}
  local rules = db and db.npAuraRules
  if type(rules) ~= "table" then return compiledAuraRules end
  local temp = {}
  for idx, r in ipairs(rules) do
    if type(r) == "table" and r.enabled ~= false then
      local rawIDs = ParseIDListString(r.ids)
      if #rawIDs > 0 then
        local reqGroups = {}
        for _, baseID in ipairs(rawIDs) do
          local idSet = { [baseID] = true }
          local idList = { baseID }
          local aliases = SPELL_AURA_ALIASES[baseID]
          if aliases then
            for _, alID in ipairs(aliases) do
              if not idSet[alID] then
                idSet[alID] = true
                idList[#idList + 1] = alID
              end
            end
          end
          local nm, ic = GetSpellNameAndIconSafe(baseID)
          local lowName = (nm and SpArc.UTF8Lower and SpArc.UTF8Lower(nm)) or (nm and nm:lower()) or nil
          reqGroups[#reqGroups + 1] = {
            baseID = baseID,
            idSet = idSet,
            idList = idList,
            name = nm,
            lowerName = lowName,
            icon = ic,
          }
        end
        temp[#temp + 1] = {
          origIndex = idx,
          count = #reqGroups,
          reqGroups = reqGroups,
          r = tonumber(r.r) or 0.2,
          g = tonumber(r.g) or 0.6,
          b = tonumber(r.b) or 1.0,
        }
      end
    end
  end
  -- Sort: multi-aura (AND) rules with more required IDs first, then by user order
  table.sort(temp, function(a, b)
    if a.count ~= b.count then
      return a.count > b.count
    end
    return a.origIndex < b.origIndex
  end)
  compiledAuraRules = temp
  return compiledAuraRules
end
---------------------------------------------------------------------------------------
--  2. CAST-BASED & MULTI-TARGET AURA TRACKER (SECRET-SAFE FOR WOW 12.X COMBAT)
---------------------------------------------------------------------------------------
local function GetMetroForUnitToken(token)
  if not token or not C_NamePlate or not C_NamePlate.GetNamePlateForUnit then
    return nil, nil, nil
  end
  local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, token)
  if ok and plate and not IsSecret(plate) then
    local metro = plate.sparcMetro or activeMetroPlates[plate]
    local npUnit = (metro and metro.unit) or plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
    return metro, npUnit, plate
  end
  return nil, nil, nil
end
local function RecordAuraOnMetroAndUnit(metro, unit, guid, auraID, lowName, untilTime, now)
  st.nameplateAuras = st.nameplateAuras or {}
  st.nameplateUnitAuras = st.nameplateUnitAuras or {}
  if metro then
    metro.trackedAuras = metro.trackedAuras or {}
    if auraID then metro.trackedAuras[auraID] = untilTime end
    if lowName and lowName ~= "" then metro.trackedAuras[lowName] = untilTime end
    metro.lastAuraCastAt = now or GetTime()
  end
  if guid and not IsSecret(guid) and type(guid) == "string" then
    local gMap = st.nameplateAuras[guid]
    if not gMap then
      gMap = {}
      st.nameplateAuras[guid] = gMap
    end
    if auraID then gMap[auraID] = untilTime end
    if lowName and lowName ~= "" then gMap[lowName] = untilTime end
  end
  if unit and type(unit) == "string" then
    local uMap = st.nameplateUnitAuras[unit]
    if not uMap then
      uMap = {}
      st.nameplateUnitAuras[unit] = uMap
    end
    if auraID then uMap[auraID] = untilTime end
    if lowName and lowName ~= "" then uMap[lowName] = untilTime end
  end
end
local function UnitMatchesSentName(unitTok, sentTargetName)
  if not unitTok or not sentTargetName or IsSecret(sentTargetName) or type(sentTargetName) ~= "string" or sentTargetName == "" then
    return false
  end
  if not SafeBool(UnitExists, unitTok) then return false end
  local okN, uName = pcall(UnitName, unitTok)
  if not okN or IsSecret(uName) or type(uName) ~= "string" or uName == "" then
    return false
  end
  if uName == sentTargetName then
    return true
  end
  local shortSent = sentTargetName:match("^([^%-]+)")
  return (shortSent ~= nil and shortSent == uName)
end

function SpArc:SnapshotNameplateCastTarget(spellID, defKey, isHardCastStart, now, sentTargetName)
  now = now or GetTime()
  local tgtMetro, tgtUnit = GetMetroForUnitToken("target")
  if not tgtMetro and st.currentTargetMetro and st.currentTargetMetro.unit then
    tgtMetro, tgtUnit = st.currentTargetMetro, st.currentTargetMetro.unit
  end
  local moMetro, moUnit = GetMetroForUnitToken("mouseover")
  local focMetro, focUnit = GetMetroForUnitToken("focus")
  local softMetro, softUnit = GetMetroForUnitToken("softenemy")
  local pickedMetro, pickedUnit = nil, nil

  -- 1. Exact match against UNIT_SPELLCAST_SENT targetName (checks mouseover first for @mouseover macros!)
  if sentTargetName and not IsSecret(sentTargetName) and type(sentTargetName) == "string" and sentTargetName ~= "" then
    if moMetro and moMetro.isEnemy and UnitMatchesSentName("mouseover", sentTargetName) then
      pickedMetro, pickedUnit = moMetro, moUnit
    elseif tgtMetro and tgtMetro.isEnemy and UnitMatchesSentName("target", sentTargetName) then
      pickedMetro, pickedUnit = tgtMetro, tgtUnit
    elseif focMetro and focMetro.isEnemy and UnitMatchesSentName("focus", sentTargetName) then
      pickedMetro, pickedUnit = focMetro, focUnit
    elseif softMetro and softMetro.isEnemy and UnitMatchesSentName("softenemy", sentTargetName) then
      pickedMetro, pickedUnit = softMetro, softUnit
    else
      for npUnit, metro in pairs(unitToMetro) do
        if metro and metro.isEnemy and UnitMatchesSentName(npUnit, sentTargetName) then
          pickedMetro, pickedUnit = metro, npUnit
          break
        end
      end
    end
  end

  -- 2. Fallback: respect @mouseover macros on the bound action slot before falling back to target
  if not pickedMetro and not pickedUnit then
    local preferMouseover = moMetro and moMetro.isEnemy and DoesActionSlotUseMouseover(defKey)
    if preferMouseover then
      pickedMetro, pickedUnit = moMetro, moUnit
    elseif tgtMetro and tgtMetro.isEnemy then
      pickedMetro, pickedUnit = tgtMetro, tgtUnit
    elseif moMetro and moMetro.isEnemy then
      pickedMetro, pickedUnit = moMetro, moUnit
    elseif focMetro and focMetro.isEnemy then
      pickedMetro, pickedUnit = focMetro, focUnit
    elseif softMetro and softMetro.isEnemy then
      pickedMetro, pickedUnit = softMetro, softUnit
    end
  end

  if pickedMetro or pickedUnit then
    st.pendingCastMetro = pickedMetro
    st.pendingCastPlateUnit = pickedUnit
    st.pendingCastSnapshotAt = now
    if isHardCastStart then
      st.hardCastMetro = pickedMetro
      st.hardCastPlateUnit = pickedUnit
      st.hardCastSnapshotAt = now
    end
  end
end

function SpArc:RecordNameplateAuraCast(spellID, defKey, now, wasHardCast)
  now = now or GetTime()
  local def = defKey and SpArc.SPELL_DEFS and SpArc.SPELL_DEFS[defKey]
  local castID = (not IsSecret(spellID) and type(spellID) == "number" and spellID)
    or (def and def.liveSpellID)
    or (def and def.ids and def.ids[1])
  if not castID then return end
  local dur = (def and def.auraDuration and def.auraDuration > 0 and def.auraDuration)
    or DEFAULT_AURA_DURATIONS[castID]
    or 18.0
  local idsToRecord = {}
  local seen = {}
  local function AddRecordID(id)
    if id and type(id) == "number" and id > 0 and not seen[id] then
      seen[id] = true
      idsToRecord[#idsToRecord + 1] = id
    end
  end

  local aoeInfo = AOE_DOT_SPELLS[castID]
  if aoeInfo and aoeInfo.auras then
    for _, al in ipairs(aoeInfo.auras) do
      AddRecordID(al)
    end
    if aoeInfo.checkMisery and HasPriestMisery() then
      AddRecordID(589)
    end
  else
    AddRecordID(castID)
    if SPELL_AURA_ALIASES[castID] then
      for _, al in ipairs(SPELL_AURA_ALIASES[castID]) do
        AddRecordID(al)
      end
    end
    if def then
      local dList = def.auraIDs or def.debuffIDs or def.ids
      if dList then
        for _, id in ipairs(dList) do
          AddRecordID(id)
          if SPELL_AURA_ALIASES[id] then
            for _, al in ipairs(SPELL_AURA_ALIASES[id]) do
              AddRecordID(al)
            end
          end
        end
      end
    end
    -- Shadow Priest Misery (238558): Vampiric Touch (34914) ONLY applies SW:P (589) when Misery is learned!
    local isVTCast = (castID == 34914 or defKey == "VAMPIRIC_TOUCH")
    if isVTCast and HasPriestMisery() then
      AddRecordID(589)
    end
  end

  local nm = GetSpellNameAndIconSafe(idsToRecord[1] or castID)
  local lowName = (nm and SpArc.UTF8Lower and SpArc.UTF8Lower(nm)) or (nm and nm:lower()) or nil

  -- Resolve recipient nameplate:
  -- 1. Hard-cast snapshot (immune to mid-cast target/mouseover movement)
  -- 2. Recent UNIT_SPELLCAST_SENT snapshot (honors exact @mouseover / sentTargetName!)
  -- 3. Live @mouseover (if macro uses @mouseover) -> target -> mouseover -> softenemy
  local targetMetro, targetPlateUnit = nil, nil
  if wasHardCast and st.hardCastMetro and st.hardCastSnapshotAt and (now - st.hardCastSnapshotAt) < 5.0 then
    targetMetro = st.hardCastMetro
    targetPlateUnit = st.hardCastPlateUnit or targetMetro.unit
  end
  st.hardCastMetro = nil
  st.hardCastPlateUnit = nil

  if not targetMetro and st.pendingCastMetro and st.pendingCastSnapshotAt and (now - st.pendingCastSnapshotAt) < 0.45 then
    targetMetro = st.pendingCastMetro
    targetPlateUnit = st.pendingCastPlateUnit or targetMetro.unit
  end
  st.pendingCastMetro = nil
  st.pendingCastPlateUnit = nil

  if not targetMetro then
    local moMetro, moUnit = GetMetroForUnitToken("mouseover")
    if moMetro and moMetro.isEnemy and DoesActionSlotUseMouseover(defKey) then
      targetMetro, targetPlateUnit = moMetro, moUnit
    end
  end
  if not targetMetro then
    local tgtM, tgtU = GetMetroForUnitToken("target")
    if tgtM and tgtM.isEnemy then
      targetMetro, targetPlateUnit = tgtM, tgtU
    elseif st.currentTargetMetro and st.currentTargetMetro.unit and st.currentTargetMetro.isEnemy then
      targetMetro, targetPlateUnit = st.currentTargetMetro, st.currentTargetMetro.unit
    end
  end
  if not targetMetro then
    local moMetro, moUnit = GetMetroForUnitToken("mouseover")
    if moMetro and moMetro.isEnemy then
      targetMetro, targetPlateUnit = moMetro, moUnit
    end
  end
  if not targetMetro then
    local softMetro, softUnit = GetMetroForUnitToken("softenemy")
    if softMetro and softMetro.isEnemy then
      targetMetro, targetPlateUnit = softMetro, softUnit
    end
  end

  local isTrackedDoT = false
  if compiledAuraRules then
    for _, r in ipairs(compiledAuraRules) do
      for _, grp in ipairs(r.reqGroups) do
        for _, aID in ipairs(idsToRecord) do
          if grp.idSet[aID] then
            isTrackedDoT = true
            break
          end
        end
        if isTrackedDoT then break end
      end
      if isTrackedDoT then break end
    end
  end

  local isTwinMoons = (castID == 8921 or castID == 164812) and (_G.IsPlayerSpell and SafeBool(_G.IsPlayerSpell, 279620)) or false
  if isTrackedDoT or aoeInfo then
    st.lastCastDoTInfo = {
      ids = idsToRecord,
      lowName = lowName,
      dur = (aoeInfo and aoeInfo.dur) or dur,
      castAt = now,
      isAoE = (aoeInfo ~= nil),
      primaryMetro = targetMetro,
      unclaimedSpreads = isTwinMoons and 1 or 0,
    }
  end

  -- Only pre-record instant single-target casts on the exact recipient plate (for <0.35s latency before UNIT_AURA).
  -- AoE / ground-targeted projectiles (Tentacle Slam / Shadow Crash) have travel time and are confirmed per-mob by UNIT_AURA on impact!
  if not aoeInfo and isTrackedDoT and (targetMetro or targetPlateUnit) then
    local tGUID = (targetMetro and targetMetro.unitGUID) or nil
    if targetMetro then
      targetMetro.lastDirectCastAt = now
    end
    for _, aID in ipairs(idsToRecord) do
      local aDur = DEFAULT_AURA_DURATIONS[aID] or dur
      RecordAuraOnMetroAndUnit(targetMetro, targetPlateUnit, tGUID, aID, lowName, now + aDur, now)
    end
  end

  if SpArc:IsNameplatesEnabled() and UpdateMetroHealthAndColor then
    if targetMetro and targetMetro.unit and targetMetro:IsShown() then
      UpdateMetroHealthAndColor(targetMetro, now)
    end
  end
end

local function DoesUnitHaveAuraGroup(unit, metro, group, liveIDSet, liveNameSet, allowFallbackTracker, now)
  -- 1. Ground-truth live player debuffs on unit (`HARMFUL|PLAYER`)
  for id in pairs(group.idSet) do
    if liveIDSet[id] then
      return true
    end
  end
  if group.lowerName and liveNameSet[group.lowerName] then
    return true
  end
  if not allowFallbackTracker then
    return false
  end
  -- 2. Secret-aura / <0.35s cast-flight fallback ONLY
  if metro and metro.trackedAuras then
    local mMap = metro.trackedAuras
    for id in pairs(group.idSet) do
      local uTime = mMap[id]
      if uTime and uTime > now then return true end
    end
    if group.lowerName and mMap[group.lowerName] and mMap[group.lowerName] > now then
      return true
    end
  end
  if unit and st.nameplateUnitAuras and st.nameplateUnitAuras[unit] then
    local uMap = st.nameplateUnitAuras[unit]
    for id in pairs(group.idSet) do
      local uTime = uMap[id]
      if uTime and uTime > now then return true end
    end
    if group.lowerName and uMap[group.lowerName] and uMap[group.lowerName] > now then
      return true
    end
  end
  return false
end

local reusableLiveIDSet = {}
local reusableLiveNameSet = {}
local function EvaluateNameplateAuraColor(unit, metro, now)
  for k in pairs(reusableLiveIDSet) do reusableLiveIDSet[k] = nil end
  for k in pairs(reusableLiveNameSet) do reusableLiveNameSet[k] = nil end

  local playerDebuffCount = 0
  local sawSecretPlayerDebuff = false
  if metro then
    metro.livePlayerAuras = metro.livePlayerAuras or {}
    metro.livePlayerAuraCount = 0
  end

  if C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex then
    for i = 1, 16 do
      -- Strictly filter by `HARMFUL|PLAYER` so C++ filters player ownership even in 12.x combat
      -- and NEVER contaminates nameplate colors with other Priests' or NPCs' debuffs!
      local ok, aura = pcall(C_UnitAuras.GetDebuffDataByIndex, unit, i, "HARMFUL|PLAYER")
      if not ok or type(aura) ~= "table" then
        break
      end
      playerDebuffCount = playerDebuffCount + 1
      local exp = aura.expirationTime
      local isActive = IsSecret(exp) or type(exp) ~= "number" or exp == 0 or exp > now
      if isActive then
        if metro and metro.livePlayerAuraCount < 5 then
          metro.livePlayerAuraCount = metro.livePlayerAuraCount + 1
          metro.livePlayerAuras[metro.livePlayerAuraCount] = aura
        end
        if not IsSecret(aura.spellId) and type(aura.spellId) == "number" then
          reusableLiveIDSet[aura.spellId] = true
          if metro then
            metro.trackedAuras = metro.trackedAuras or {}
            local dur = DEFAULT_AURA_DURATIONS[aura.spellId] or 18.0
            local uTime = (not IsSecret(exp) and type(exp) == "number" and exp > now) and exp or (now + dur)
            metro.trackedAuras[aura.spellId] = uTime
          end
        else
          sawSecretPlayerDebuff = true
        end
        if not IsSecret(aura.name) and type(aura.name) == "string" and aura.name ~= "" then
          local low = SpArc.UTF8Lower and SpArc.UTF8Lower(aura.name) or aura.name:lower()
          reusableLiveNameSet[low] = true
        end
      end
    end
  end

  if metro then
    metro._lastSawSecretDebuff = sawSecretPlayerDebuff
    metro._lastPlayerDebuffCount = playerDebuffCount
    -- If C++ `HARMFUL|PLAYER` reports 0 player debuffs after the brief cast-flight grace window,
    -- wipe any cached tracker state immediately (both in and out of combat!).
    local inCastFlight = ((now - (metro.lastDirectCastAt or 0)) <= 0.35)
    if playerDebuffCount == 0 and not inCastFlight then
      if metro.trackedAuras then
        for k in pairs(metro.trackedAuras) do metro.trackedAuras[k] = nil end
      end
      if unit and st.nameplateUnitAuras and st.nameplateUnitAuras[unit] then
        for k in pairs(st.nameplateUnitAuras[unit]) do st.nameplateUnitAuras[unit][k] = nil end
      end
    end
  end

  if not compiledAuraRules or #compiledAuraRules == 0 then
    return nil, nil, nil
  end

  local allowFallbackTracker = sawSecretPlayerDebuff or (metro ~= nil and ((now - (metro.lastDirectCastAt or 0)) <= 0.35))
  if playerDebuffCount == 0 and not allowFallbackTracker then
    return nil, nil, nil
  end

  for _, rule in ipairs(compiledAuraRules) do
    -- In secret-aura mode, a 3-DoT rule cannot match if the unit only has 1 or 2 player debuffs!
    if not (sawSecretPlayerDebuff and playerDebuffCount > 0 and rule.count > playerDebuffCount) then
      local allMatched = true
      for _, grp in ipairs(rule.reqGroups) do
        if not DoesUnitHaveAuraGroup(unit, metro, grp, reusableLiveIDSet, reusableLiveNameSet, allowFallbackTracker, now) then
          allMatched = false
          break
        end
      end
      if allMatched then
        return rule.r, rule.g, rule.b
      end
    end
  end
  return nil, nil, nil
end
---------------------------------------------------------------------------------------
--  3. QUEST NPC DETECTION (NATIVE + SOFTTARGET + TOOLTIP SCAN CACHE)
---------------------------------------------------------------------------------------
local questTipNextScanByUnit = {}

local function IsTooltipObjectiveLineCompleted(ln)
  if type(ln) ~= "table" then return false end
  if not IsSecret(ln.completed) and ln.completed == true then
    return true
  end
  local txt = (not IsSecret(ln.leftText) and type(ln.leftText) == "string" and ln.leftText) or nil
  if txt then
    local cur, max = txt:match("(%d+)%s*/%s*(%d+)")
    if cur and max then
      local nCur, nMax = tonumber(cur), tonumber(max)
      if nCur and nMax and nMax > 0 and nCur >= nMax then
        return true
      end
    end
    local pct = txt:match("(%d+)%%")
    if pct and tonumber(pct) and tonumber(pct) >= 100 then
      return true
    end
  end
  return false
end

local function IsUnitQuestRelated(unit, guid, plate)
  if not unit or SafeBool(UnitIsPlayer, unit) then
    return false
  end
  if _G.UnitIsQuestBoss and SafeBool(_G.UnitIsQuestBoss, unit) then
    if guid and not IsSecret(guid) then questCacheByGUID[guid] = GetTime() + 2.5 end
    return true
  end
  local canAttack = SafeBool(UnitCanAttack, "player", unit)
  local apiRelated = false
  if C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest then
    local okQ, isRel = pcall(C_QuestLog.UnitIsRelatedToActiveQuest, unit)
    if okQ and not IsSecret(isRel) and isRel == true then
      apiRelated = true
      if not canAttack then
        if guid and not IsSecret(guid) then questCacheByGUID[guid] = GetTime() + 2.5 end
        return true
      end
    end
  end
  local now = GetTime()
  if guid and not IsSecret(guid) then
    local exp = questCacheByGUID[guid]
    if type(exp) == "number" and exp > now then
      return true
    end
  end
  local nextScan = questTipNextScanByUnit[unit] or 0
  if now < nextScan then
    return apiRelated
  end
  questTipNextScanByUnit[unit] = now + 0.65
  local tType = _G.Enum and _G.Enum.TooltipDataLineType
  if C_TooltipInfo and C_TooltipInfo.GetUnit and tType then
    local okT, tip = pcall(C_TooltipInfo.GetUnit, unit)
    if okT and type(tip) == "table" and type(tip.lines) == "table" then
      local qTitle = tType.QuestTitle
      local qObj = tType.QuestObjective
      local qPlayer = tType.QuestPlayer
      local sawIncompleteObj = false
      local sawCompletedObj = false
      local sawQuestHeader = false
      for i = 2, #tip.lines do
        local ln = tip.lines[i]
        if type(ln) == "table" and not IsSecret(ln.type) and ln.type ~= nil then
          local lt = ln.type
          if qObj and lt == qObj then
            if IsTooltipObjectiveLineCompleted(ln) then
              sawCompletedObj = true
            else
              sawIncompleteObj = true
            end
          elseif (qTitle and lt == qTitle) or (qPlayer and lt == qPlayer) then
            sawQuestHeader = true
          end
        end
      end
      if sawIncompleteObj then
        if guid and not IsSecret(guid) then questCacheByGUID[guid] = now + 2.5 end
        return true
      end
      if sawCompletedObj and not sawIncompleteObj then
        if guid and not IsSecret(guid) then questCacheByGUID[guid] = nil end
        return false
      end
      if not canAttack and (sawQuestHeader or apiRelated) then
        if guid and not IsSecret(guid) then questCacheByGUID[guid] = now + 2.5 end
        return true
      end
    end
  end
  return apiRelated
end
---------------------------------------------------------------------------------------
--  4. BLIZZARD SUPPRESSION & ELVUI / PLATER CONFLICT DIALOG (NO SILENT AUTO-DISABLE!)
---------------------------------------------------------------------------------------
local conflictDialog = nil
local conflictResolvedToSpArc = false

local function GetActiveConflictingNameplateAddon()
  local hasElvNP = false
  local hasPlater = false
  if _G.ElvUI then
    local okE, E = pcall(_G.unpack, _G.ElvUI)
    if okE and type(E) == "table" and E.private and E.private.nameplates and E.private.nameplates.enable == true then
      hasElvNP = true
    end
  end
  if _G.Plater ~= nil or (C_AddOns and C_AddOns.IsAddOnLoaded and SafeBool(C_AddOns.IsAddOnLoaded, "Plater")) then
    hasPlater = true
  end
  if hasElvNP and hasPlater then
    return "ElvUI NamePlates & Plater", true, true
  elseif hasElvNP then
    return "ElvUI NamePlates", true, false
  elseif hasPlater then
    return "Plater", false, true
  end
  return nil, false, false
end

local function DisableExternalNameplateAddonsByUserChoice(hasElvNP, hasPlater)
  conflictResolvedToSpArc = true
  if hasElvNP and _G.ElvUI then
    local okE, E = pcall(_G.unpack, _G.ElvUI)
    if okE and type(E) == "table" then
      if E.private and E.private.nameplates then
        E.private.nameplates.enable = false
      end
      if E.GetModule then
        local okNP, NP = pcall(E.GetModule, E, "NamePlates", true)
        if okNP and type(NP) == "table" then
          if NP.PlateDriver then
            pcall(NP.PlateDriver.UnregisterAllEvents, NP.PlateDriver)
          end
          if NP.PlayerFrame then pcall(NP.PlayerFrame.Hide, NP.PlayerFrame) end
          if NP.TargetClassPower then pcall(NP.TargetClassPower.Hide, NP.TargetClassPower) end
          if NP.PlayerNamePlateAnchor then pcall(NP.PlayerNamePlateAnchor.Hide, NP.PlayerNamePlateAnchor) end
          elvUINPSuppressed = true
        end
      end
    end
  end
  if hasPlater then
    if C_AddOns and C_AddOns.DisableAddOn then
      pcall(C_AddOns.DisableAddOn, "Plater")
    end
    if _G.ReloadUI then
      pcall(_G.ReloadUI)
    end
  end
end

local function ShowNameplateConflictDialog(conflictName, hasElvNP, hasPlater)
  if not conflictDialog then
    local f = CreateFrame("Frame", "SpArcNameplateConflictDialog", UIParent, "BackdropTemplate")
    f:SetSize(460, 178)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 110)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(200)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
      bgFile = FLAT_TEX,
      edgeFile = FLAT_TEX,
      edgeSize = 2,
    })
    f:SetBackdropColor(0.05, 0.05, 0.08, 0.98)
    f:SetBackdropBorderColor(0.75, 0.30, 1.0, 1.0)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ApplyCyrFont(title, 15)
    title:SetPoint("TOP", f, "TOP", 0, -14)
    title:SetTextColor(1.0, 0.85, 0.25, 1.0)
    f.title = title

    local body = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ApplyCyrFont(body, 12)
    body:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -44)
    body:SetPoint("TOPRIGHT", f, "TOPRIGHT", -20, -44)
    body:SetJustifyH("CENTER")
    body:SetSpacing(3)
    f.body = body

    local function MakeChoiceBtn(xOffset)
      local b = CreateFrame("Button", nil, f, "BackdropTemplate")
      b:SetSize(200, 32)
      b:SetPoint("BOTTOM", f, "BOTTOM", xOffset, 16)
      b:SetBackdrop({
        bgFile = FLAT_TEX,
        edgeFile = FLAT_TEX,
        edgeSize = 1,
      })
      b:SetBackdropColor(0.14, 0.14, 0.20, 0.98)
      b:SetBackdropBorderColor(0.32, 0.32, 0.44, 1.0)
      local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      ApplyCyrFont(fs, 12)
      fs:SetPoint("CENTER")
      fs:SetTextColor(0.95, 0.95, 1.0, 1.0)
      b.fs = fs
      b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.20, 0.36, 0.58, 0.98)
        self:SetBackdropBorderColor(0.45, 0.75, 1.0, 1.0)
      end)
      b:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.14, 0.14, 0.20, 0.98)
        self:SetBackdropBorderColor(0.32, 0.32, 0.44, 1.0)
      end)
      return b
    end

    f.btnSpArc = MakeChoiceBtn(-106)
    f.btnTheirs = MakeChoiceBtn(106)
    conflictDialog = f
  end

  conflictDialog.title:SetText(SpArc:L("NP_CONFLICT_TITLE"))
  conflictDialog.body:SetText(string.format(SpArc:L("NP_CONFLICT_BODY"), conflictName))
  conflictDialog.btnSpArc.fs:SetText(SpArc:L("NP_CONFLICT_USE_SPARC"))
  conflictDialog.btnTheirs.fs:SetText(string.format(SpArc:L("NP_CONFLICT_USE_THEIRS"), conflictName))

  conflictDialog.btnSpArc:SetScript("OnClick", function()
    conflictDialog:Hide()
    local db = SpArc:EnsureDB()
    if db and db.visual then
      db.visual.enableNameplates = true
    end
    DisableExternalNameplateAddonsByUserChoice(hasElvNP, hasPlater)
    print(string.format(SpArc:L("MSG_NP_CHOICE_SPARC"), conflictName))
    SpArc:RefreshAllNameplates()
    if SpArc.RefreshControlCenterUI then SpArc.RefreshControlCenterUI() end
  end)

  conflictDialog.btnTheirs:SetScript("OnClick", function()
    conflictDialog:Hide()
    conflictResolvedToSpArc = false
    local db = SpArc:EnsureDB()
    if db and db.visual then
      db.visual.enableNameplates = false
    end
    print(string.format(SpArc:L("MSG_NP_CHOICE_THEIRS"), conflictName))
    SpArc:RefreshAllNameplates()
    if SpArc.RefreshControlCenterUI then SpArc.RefreshControlCenterUI() end
  end)

  conflictDialog:Show()
end

local function IsBlockedByUnresolvedConflict()
  if not SpArc:IsNameplatesEnabled() then
    return false
  end
  local conflictName, hasElvNP, hasPlater = GetActiveConflictingNameplateAddon()
  if not conflictName then
    if conflictDialog and conflictDialog:IsShown() then
      conflictDialog:Hide()
    end
    return false
  end
  if conflictResolvedToSpArc then
    return false
  end
  ShowNameplateConflictDialog(conflictName, hasElvNP, hasPlater)
  return true
end

local function SuppressSubFrameEvents(sf)
  if sf and sf.UnregisterAllEvents then
    pcall(sf.UnregisterAllEvents, sf)
  end
end
local function SuppressBlizzardUnitFrame(plate, metro)
  if not plate or IsBlockedByUnresolvedConflict() then return end
  local uFrame = plate.UnitFrame
  local inLockdown = InCombatLockdown and InCombatLockdown()
  if uFrame then
    pcall(uFrame.SetAlpha, uFrame, 0)
    if uFrame.WidgetContainer then
      pcall(uFrame.WidgetContainer.SetIgnoreParentAlpha, uFrame.WidgetContainer, false)
      pcall(uFrame.WidgetContainer.SetAlpha, uFrame.WidgetContainer, 0)
    end
    if uFrame.SoftTargetFrame then
      pcall(uFrame.SoftTargetFrame.SetIgnoreParentAlpha, uFrame.SoftTargetFrame, false)
      pcall(uFrame.SoftTargetFrame.SetAlpha, uFrame.SoftTargetFrame, 0)
    end
    if not hookedBlizzFrames[uFrame] then
      hookedBlizzFrames[uFrame] = true
      pcall(uFrame.UnregisterAllEvents, uFrame)
      SuppressSubFrameEvents(uFrame.healthBar)
      SuppressSubFrameEvents(uFrame.HealthBarsContainer and uFrame.HealthBarsContainer.healthBar)
      SuppressSubFrameEvents(uFrame.castBar)
      SuppressSubFrameEvents(uFrame.spellbar)
      SuppressSubFrameEvents(uFrame.CastingBarFrame)
      SuppressSubFrameEvents(uFrame.BuffFrame)
      SuppressSubFrameEvents(uFrame.AurasFrame)
      SuppressSubFrameEvents(uFrame.ClassificationFrame)
      SuppressSubFrameEvents(uFrame.WidgetContainer)
      pcall(_G.hooksecurefunc, uFrame, "Show", function(self)
        if SpArc:IsNameplatesEnabled() and not IsBlockedByUnresolvedConflict() then
          pcall(self.SetAlpha, self, 0)
        end
      end)
      local inAlphaHook = false
      pcall(_G.hooksecurefunc, uFrame, "SetAlpha", function(self, alpha)
        if inAlphaHook or not alpha or alpha == 0 then return end
        if SpArc:IsNameplatesEnabled() and not IsBlockedByUnresolvedConflict() then
          inAlphaHook = true
          pcall(self.SetAlpha, self, 0)
          inAlphaHook = false
        end
      end)
    end
  end
  -- Only hide ElvUI's per-plate unitFrame if the user explicitly chose SpArc over ElvUI
  if elvUINPSuppressed and plate.unitFrame and plate.unitFrame ~= metro then
    pcall(plate.unitFrame.UnregisterAllEvents, plate.unitFrame)
    if not inLockdown then
      pcall(plate.unitFrame.Hide, plate.unitFrame)
    end
    pcall(plate.unitFrame.SetAlpha, plate.unitFrame, 0)
  end
end
function SpArc:SyncExternalNameplateAddons()
  local enabled = SpArc:IsNameplatesEnabled()
  if not enabled then
    if conflictDialog and conflictDialog:IsShown() then
      conflictDialog:Hide()
    end
    return
  end
  if IsBlockedByUnresolvedConflict() then
    return
  end
  if enabled and C_CVar and C_CVar.SetCVar and not (InCombatLockdown and InCombatLockdown()) then
    pcall(C_CVar.SetCVar, "nameplateShowEnemies", "1")
    local db = SpArc:EnsureDB()
    local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL
    if vis.npShowFriendlyPlayers ~= false or vis.npShowFriendlyNPCs == true or vis.npShowQuestNPCs ~= false then
      pcall(C_CVar.SetCVar, "nameplateShowFriends", "1")
      pcall(C_CVar.SetCVar, "nameplateShowOnlyNameForFriendlyPlayerUnits", "0")
    end
    if vis.npShowFriendlyNPCs == true or vis.npShowQuestNPCs ~= false then
      pcall(C_CVar.SetCVar, "nameplateShowFriendlyNPCs", "1")
      pcall(C_CVar.SetCVar, "UnitNameFriendlySpecialNPCName", "1")
    else
      pcall(C_CVar.SetCVar, "nameplateShowFriendlyNPCs", "0")
    end
    pcall(C_CVar.SetCVar, "nameplateMinScale", "1")
    pcall(C_CVar.SetCVar, "nameplateMaxScale", "1")
    pcall(C_CVar.SetCVar, "nameplateSelectedScale", "1")

    -- View Distance (20..60 yd) & Smooth C++ 3D Distance Fading (no double-multiplication with metro:SetAlpha)
    local maxDist = math.floor(math.max(20, math.min(60, tonumber(vis.npMaxDistance) or 40)) + 0.5)
    local distFade = (vis.npDistanceFade ~= false)
    local minAlpha = math.max(0.42, math.min(1.00, tonumber(vis.npMinAlpha) or 0.50))
    pcall(C_CVar.SetCVar, "nameplateMaxDistance", tostring(maxDist))
    pcall(C_CVar.SetCVar, "nameplatePlayerMaxDistance", tostring(maxDist))
    pcall(C_CVar.SetCVar, "nameplateSelectedAlpha", "1.0")
    pcall(C_CVar.SetCVar, "nameplateMaxAlpha", "1.0")
    pcall(C_CVar.SetCVar, "nameplateMaxAlphaDistance", "28")
    if distFade then
      pcall(C_CVar.SetCVar, "nameplateMinAlpha", string.format("%.2f", minAlpha))
      pcall(C_CVar.SetCVar, "nameplateMinAlphaDistance", "10")
      pcall(C_CVar.SetCVar, "nameplateOccludedAlphaMult", string.format("%.2f", math.max(0.40, minAlpha * 0.85)))
    else
      pcall(C_CVar.SetCVar, "nameplateMinAlpha", "0.95")
      pcall(C_CVar.SetCVar, "nameplateMinAlphaDistance", "10")
      pcall(C_CVar.SetCVar, "nameplateOccludedAlphaMult", "0.65")
    end
  end
end
---------------------------------------------------------------------------------------
--  5. METRO TILE FRAME FACTORY & UPDATER
---------------------------------------------------------------------------------------
local CreateBorderFrame = SpArc.CreateFlatBorder
local function CreateMetroPlate(plate, isDemo)
  if plate.sparcMetro then
    return plate.sparcMetro
  end
  local metro = CreateFrame("Frame", nil, plate)
  metro:SetPoint("CENTER", plate, "CENTER", 0, 0)
  metro:SetSize(140, 30)
  metro:EnableMouse(false)
  -- 1. Main Health Bar (Metro Tile)
  local hb = CreateFrame("StatusBar", nil, metro)
  hb:SetAllPoints(metro)
  hb:SetStatusBarTexture(FLAT_TEX)
  hb:SetMinMaxValues(0, 100)
  hb:SetValue(100)
  hb:SetStatusBarColor(COLOR_HOSTILE_RED.r, COLOR_HOSTILE_RED.g, COLOR_HOSTILE_RED.b, 1.0)
  metro.healthBar = hb
  local bg = hb:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(hb)
  bg:SetColorTexture(0.07, 0.07, 0.09, 0.92)
  metro.bg = bg
  -- Top subtle inner specular line for crisp Windows Metro polish
  local topSheen = hb:CreateTexture(nil, "ARTWORK")
  topSheen:SetPoint("TOPLEFT", hb, "TOPLEFT", 1, -1)
  topSheen:SetPoint("TOPRIGHT", hb, "TOPRIGHT", -1, -1)
  topSheen:SetHeight(1)
  topSheen:SetColorTexture(1.0, 1.0, 1.0, 0.12)
  metro.topSheen = topSheen
  -- Crisp 1px dark border
  metro.border = CreateBorderFrame(hb, 1, 0.04, 0.04, 0.06, 1.0, 2)
  -- 2px Target Highlight Border + Golden Target Chevrons (> [Plate] <)
  local tBorder = CreateFrame("Frame", nil, hb, "BackdropTemplate")
  tBorder:SetPoint("TOPLEFT", hb, "TOPLEFT", -1, 1)
  tBorder:SetPoint("BOTTOMRIGHT", hb, "BOTTOMRIGHT", 1, -1)
  tBorder:SetFrameLevel(hb:GetFrameLevel() + 4)
  tBorder:SetBackdrop({
    edgeFile = FLAT_TEX,
    edgeSize = 2,
  })
  tBorder:SetBackdropBorderColor(1.00, 0.90, 0.28, 1.0)
  local leftBracket = tBorder:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  ApplyCyrFont(leftBracket, 18)
  leftBracket:SetPoint("RIGHT", tBorder, "LEFT", -3, 0)
  leftBracket:SetTextColor(1.00, 0.85, 0.15, 1.0)
  leftBracket:SetText(">")
  tBorder.leftBracket = leftBracket
  local rightBracket = tBorder:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  ApplyCyrFont(rightBracket, 18)
  rightBracket:SetPoint("LEFT", tBorder, "RIGHT", 3, 0)
  rightBracket:SetTextColor(1.00, 0.85, 0.15, 1.0)
  rightBracket:SetText("<")
  tBorder.rightBracket = rightBracket
  tBorder:Hide()
  metro.targetBorder = tBorder
  -- Text Layer Frame (above borders)
  local txtFrame = CreateFrame("Frame", nil, hb)
  txtFrame:SetAllPoints(hb)
  txtFrame:SetFrameLevel(hb:GetFrameLevel() + 6)
  metro.txtFrame = txtFrame
  local hpText = txtFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyCyrFont(hpText, 10)
  hpText:SetPoint("RIGHT", txtFrame, "RIGHT", -5, 0)
  hpText:SetJustifyH("RIGHT")
  hpText:SetWordWrap(false)
  hpText:SetTextColor(0.96, 0.96, 1.0, 1.0)
  metro.hpText = hpText
  local levelText = txtFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyCyrFont(levelText, 10)
  levelText:SetPoint("LEFT", txtFrame, "LEFT", 5, 0)
  levelText:SetJustifyH("LEFT")
  levelText:SetWordWrap(false)
  levelText:SetTextColor(1.00, 0.85, 0.28, 1.0)
  metro.levelText = levelText
  local nameText = txtFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(nameText, 11)
  nameText:SetPoint("LEFT", txtFrame, "LEFT", 6, 0)
  nameText:SetPoint("RIGHT", hpText, "LEFT", -4, 0)
  nameText:SetJustifyH("LEFT")
  nameText:SetWordWrap(false)
  nameText:SetTextColor(1.0, 1.0, 1.0, 1.0)
  metro.nameText = nameText
  -- 2. Left Square Class Icon (for Hostile Players: 30x30 attached flush left)
  local classBox = CreateFrame("Frame", nil, metro, "BackdropTemplate")
  classBox:SetSize(30, 30)
  classBox:SetPoint("RIGHT", hb, "LEFT", -1, 0)
  classBox:SetFrameLevel(hb:GetFrameLevel() + 3)
  classBox:SetBackdrop({
    bgFile = FLAT_TEX,
    edgeFile = FLAT_TEX,
    edgeSize = 1,
  })
  classBox:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
  classBox:SetBackdropBorderColor(0.04, 0.04, 0.06, 1.0)
  local classIcon = classBox:CreateTexture(nil, "ARTWORK")
  classIcon:SetPoint("TOPLEFT", classBox, "TOPLEFT", 1, -1)
  classIcon:SetPoint("BOTTOMRIGHT", classBox, "BOTTOMRIGHT", -1, 1)
  classIcon:SetTexture(CLASS_ICONS_TEX)
  classBox.icon = classIcon
  classBox:Hide()
  metro.classBox = classBox
  -- 3. Right Quest Indicator Badge (!) for Quest NPCs
  local questBadge = CreateFrame("Frame", nil, metro, "BackdropTemplate")
  questBadge:SetSize(22, 22)
  questBadge:SetPoint("LEFT", hb, "RIGHT", 2, 0)
  questBadge:SetFrameLevel(hb:GetFrameLevel() + 5)
  questBadge:SetBackdrop({
    bgFile = FLAT_TEX,
    edgeFile = FLAT_TEX,
    edgeSize = 1,
  })
  questBadge:SetBackdropColor(0.95, 0.72, 0.08, 0.96)
  questBadge:SetBackdropBorderColor(0.08, 0.06, 0.02, 1.0)
  local qTxt = questBadge:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(qTxt, 14)
  qTxt:SetPoint("CENTER", questBadge, "CENTER", 0, 0)
  qTxt:SetText("|cff111111!|r")
  questBadge.txt = qTxt
  questBadge:Hide()
  metro.questBadge = questBadge
  -- 4. Castbar Underneath Health Bar (Half Thickness Metro Tile)
  local cbContainer = CreateFrame("Frame", nil, metro)
  cbContainer:SetPoint("TOPLEFT", hb, "BOTTOMLEFT", 0, -1)
  cbContainer:SetPoint("TOPRIGHT", hb, "BOTTOMRIGHT", 0, -1)
  cbContainer:SetHeight(14)
  cbContainer:SetFrameLevel(hb:GetFrameLevel() + 3)
  local cbIconBox = CreateFrame("Frame", nil, cbContainer, "BackdropTemplate")
  cbIconBox:SetPoint("TOPLEFT", cbContainer, "TOPLEFT", 0, 0)
  cbIconBox:SetSize(14, 14)
  cbIconBox:SetBackdrop({
    bgFile = FLAT_TEX,
    edgeFile = FLAT_TEX,
    edgeSize = 1,
  })
  cbIconBox:SetBackdropColor(0.06, 0.06, 0.08, 0.96)
  cbIconBox:SetBackdropBorderColor(0.04, 0.04, 0.06, 1.0)
  local cbIcon = cbIconBox:CreateTexture(nil, "ARTWORK")
  cbIcon:SetPoint("TOPLEFT", cbIconBox, "TOPLEFT", 1, -1)
  cbIcon:SetPoint("BOTTOMRIGHT", cbIconBox, "BOTTOMRIGHT", -1, 1)
  cbIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  cbIconBox.icon = cbIcon
  cbContainer.iconBox = cbIconBox
  local cb = CreateFrame("StatusBar", nil, cbContainer)
  cb:SetPoint("TOPLEFT", cbIconBox, "TOPRIGHT", 1, 0)
  cb:SetPoint("BOTTOMRIGHT", cbContainer, "BOTTOMRIGHT", 0, 0)
  cb:SetStatusBarTexture(FLAT_TEX)
  cb:SetMinMaxValues(0, 1)
  cb:SetValue(0)
  cb:SetStatusBarColor(COLOR_CAST_GOLD.r, COLOR_CAST_GOLD.g, COLOR_CAST_GOLD.b, 1.0)
  cbContainer.bar = cb
  local cbBg = cb:CreateTexture(nil, "BACKGROUND")
  cbBg:SetAllPoints(cb)
  cbBg:SetColorTexture(0.06, 0.06, 0.08, 0.94)
  cbContainer.bg = cbBg
  cbContainer.border = CreateBorderFrame(cb, 1, 0.04, 0.04, 0.06, 1.0, 2)
  -- Golden Glow Frame for Interruptible Casts
  local cbGlow = CreateFrame("Frame", nil, cbContainer, "BackdropTemplate")
  cbGlow:SetPoint("TOPLEFT", cbContainer, "TOPLEFT", -2, 2)
  cbGlow:SetPoint("BOTTOMRIGHT", cbContainer, "BOTTOMRIGHT", 2, -2)
  cbGlow:SetFrameLevel(cb:GetFrameLevel() + 4)
  cbGlow:SetBackdrop({
    edgeFile = FLAT_TEX,
    edgeSize = 2,
  })
  cbGlow:SetBackdropBorderColor(1.00, 0.86, 0.22, 0.95)
  local outerGlow = cbGlow:CreateTexture(nil, "BACKGROUND")
  outerGlow:SetPoint("TOPLEFT", cbGlow, "TOPLEFT", -2, 2)
  outerGlow:SetPoint("BOTTOMRIGHT", cbGlow, "BOTTOMRIGHT", 2, -2)
  outerGlow:SetColorTexture(1.00, 0.82, 0.15, 0.25)
  cbGlow.outerGlow = outerGlow
  cbGlow:Hide()
  cbContainer.glow = cbGlow
  local cbTxtFrame = CreateFrame("Frame", nil, cb)
  cbTxtFrame:SetAllPoints(cb)
  cbTxtFrame:SetFrameLevel(cb:GetFrameLevel() + 6)
  local cbTime = cbTxtFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyCyrFont(cbTime, 9)
  cbTime:SetPoint("RIGHT", cbTxtFrame, "RIGHT", -3, 0)
  cbTime:SetJustifyH("RIGHT")
  cbTime:SetWordWrap(false)
  cbTime:SetTextColor(1.0, 0.98, 0.90, 1.0)
  cbContainer.timeText = cbTime
  local cbText = cbTxtFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyCyrFont(cbText, 9)
  cbText:SetPoint("LEFT", cbTxtFrame, "LEFT", 4, 0)
  cbText:SetPoint("RIGHT", cbTime, "LEFT", -3, 0)
  cbText:SetJustifyH("LEFT")
  cbText:SetWordWrap(false)
  cbText:SetTextColor(1.0, 1.0, 1.0, 1.0)
  cbContainer.spellText = cbText
  cbContainer:Hide()
  metro.castBar = cbContainer

  -- 5. Mini Player DoT Icons Row Above Enemy Nameplates (Mouse-transparent so @mouseover never breaks!)
  local auraRow = CreateFrame("Frame", nil, metro)
  auraRow:SetPoint("BOTTOM", hb, "TOP", 0, 3)
  auraRow:SetSize(98, 18)
  auraRow:SetFrameLevel(hb:GetFrameLevel() + 5)
  auraRow:EnableMouse(false)
  metro.auraRow = auraRow
  metro.auraIcons = {}
  for i = 1, 5 do
    local aBox = CreateFrame("Frame", nil, auraRow, "BackdropTemplate")
    aBox:SetSize(18, 18)
    aBox:EnableMouse(false)
    aBox:SetBackdrop({
      bgFile = FLAT_TEX,
      edgeFile = FLAT_TEX,
      edgeSize = 1,
    })
    aBox:SetBackdropColor(0.05, 0.05, 0.08, 0.94)
    aBox:SetBackdropBorderColor(0.68, 0.28, 1.00, 1.0)
    local tex = aBox:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT", 1, -1)
    tex:SetPoint("BOTTOMRIGHT", -1, 1)
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    aBox.icon = tex

    local cd = CreateFrame("Cooldown", nil, aBox, "CooldownFrameTemplate")
    cd:SetPoint("TOPLEFT", 1, -1)
    cd:SetPoint("BOTTOMRIGHT", -1, 1)
    cd:EnableMouse(false)
    if cd.SetDrawEdge then cd:SetDrawEdge(false) end
    if cd.SetDrawSwipe then cd:SetDrawSwipe(true) end
    if cd.SetReverse then cd:SetReverse(true) end
    if cd.SetHideCountdownNumbers then cd:SetHideCountdownNumbers(true) end
    aBox.cd = cd

    local txtLayer = CreateFrame("Frame", nil, aBox)
    txtLayer:SetAllPoints(aBox)
    txtLayer:SetFrameLevel(cd:GetFrameLevel() + 2)
    txtLayer:EnableMouse(false)

    local tTxt = txtLayer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ApplyCyrFont(tTxt, 9)
    tTxt:SetPoint("CENTER", txtLayer, "CENTER", 0, 0)
    tTxt:SetTextColor(1.0, 0.98, 0.92, 1.0)
    aBox.timeText = tTxt

    local cnt = txtLayer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ApplyCyrFont(cnt, 8)
    cnt:SetPoint("BOTTOMRIGHT", txtLayer, "BOTTOMRIGHT", 0, 0)
    cnt:SetTextColor(1.0, 0.90, 0.22, 1.0)
    aBox.count = cnt

    aBox:Hide()
    metro.auraIcons[i] = aBox
  end
  auraRow:Hide()

  metro:Hide()
  plate.sparcMetro = metro
  if not isDemo then
    activeMetroPlates[plate] = metro
  end
  return metro
end
local function ApplyMetroGeometryToPlate(metro)
  if not metro then return end
  local db = SpArc:EnsureDB()
  local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL
  local w = tonumber(vis.npWidth) or 140
  local h = tonumber(vis.npHeight) or 30
  local cbH = tonumber(vis.npCastHeight) or 14
  local fSize = tonumber(vis.npFontSize) or 12
  local fKey = (SpArc.GetActiveFontKey and SpArc:GetActiveFontKey()) or "ROBOTO_BOLD"
  if metro._appliedW == w and metro._appliedH == h and metro._appliedCbH == cbH and metro._appliedFSize == fSize and metro._appliedFontKey == fKey then
    return
  end
  metro._appliedW = w
  metro._appliedH = h
  metro._appliedCbH = cbH
  metro._appliedFSize = fSize
  metro._appliedFontKey = fKey
  metro:SetSize(w, h)
  metro.classBox:SetSize(h, h)
  local qSize = math.max(18, math.min(26, h - 4))
  metro.questBadge:SetSize(qSize, qSize)
  metro.castBar:SetHeight(cbH)
  metro.castBar.iconBox:SetSize(cbH, cbH)
  ApplyCyrFont(metro.nameText, fSize)
  if metro.levelText then
    ApplyCyrFont(metro.levelText, math.max(9, fSize - 1))
  end
  ApplyCyrFont(metro.hpText, math.max(9, fSize - 1))
  local cbFont = math.max(9, math.min(12, cbH - 3))
  ApplyCyrFont(metro.castBar.spellText, cbFont)
  ApplyCyrFont(metro.castBar.timeText, cbFont)
end
local function EvaluatePlateVisibilityAndType(unit, metro)
  if not unit or not SafeBool(UnitExists, unit) then
    return false
  end
  if SafeBool(UnitIsUnit, unit, "player") or SafeBool(UnitIsDeadOrGhost, unit) then
    return false
  end
  if (UnitNameplateShowsWidgetsOnly and SafeBool(UnitNameplateShowsWidgetsOnly, unit))
    or (UnitIsGameObject and SafeBool(UnitIsGameObject, unit)) then
    return false
  end
  local db = SpArc:EnsureDB()
  local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL
  local isPlayer = SafeBool(UnitIsPlayer, unit)
  local canAttack = SafeBool(UnitCanAttack, "player", unit)
  local isHostileEnemy = SafeBool(UnitIsEnemy, "player", unit)
  local isEnemy = canAttack
  local isFriend = not canAttack
  local okR, reaction = pcall(UnitReaction, unit, "player")
  if not okR or reaction == nil or IsSecret(reaction) then
    okR, reaction = pcall(UnitReaction, "player", unit)
  end
  local reactNum
  if okR and not IsSecret(reaction) and type(reaction) == "number" then
    reactNum = reaction
  elseif not canAttack then
    reactNum = 5
  elseif isHostileEnemy then
    reactNum = 2
  else
    reactNum = 4
  end
  local tgtMetro = GetMetroForUnitToken("target")
  local isTarget = (tgtMetro ~= nil and tgtMetro == metro) or SafeBool(UnitIsUnit, unit, "target")
  if isTarget then
    st.currentTargetMetro = metro
  elseif st.currentTargetMetro == metro then
    st.currentTargetMetro = nil
  end
  local okG, guid = pcall(UnitGUID, unit)
  local cleanGUID = (okG and not IsSecret(guid) and type(guid) == "string" and guid) or nil
  metro.unitGUID = cleanGUID
  metro.isPlayer = isPlayer
  metro.isEnemy = isEnemy
  metro.isFriend = isFriend
  metro.isTarget = isTarget
  metro.reaction = reactNum
  if isPlayer then
    local okC, _, classFile = pcall(UnitClass, unit)
    if okC and classFile then
      metro.classFile = classFile
      if not IsSecret(classFile) and type(classFile) == "string" then
        metro.cachedClassFile = classFile
      end
    end
    if canAttack then
      metro.plateCategory = "ENEMY_PLAYER"
      metro.isQuestNPC = false
      return true
    else
      if vis.npShowFriendlyPlayers == false then
        return false
      end
      metro.plateCategory = "FRIENDLY_PLAYER"
      metro.isQuestNPC = false
      return true
    end
  end
  -- NPC 3-Tier Logic (strictly divided by canAttack & hostility):
  --   1. FRIENDLY_NPC (`not canAttack`): Cannot be attacked even if you want to -> Green (#2ECC52)
  --   2. NEUTRAL_NPC  (`canAttack` & neutral out-of-combat): Can be attacked, won't attack on sight -> Yellow (#EBC729)
  --   3. ENEMY_NPC    (`canAttack` & hostile/aggressive): Will attack on sight or actively aggroed -> Red (#D92626)
  metro.classFile = nil
  metro.cachedClassFile = nil
  local plate = metro:GetParent()
  local isQuest = IsUnitQuestRelated(unit, cleanGUID, plate)
  metro.isQuestNPC = (vis.npShowQuestNPCs ~= false) and isQuest or false
  if not canAttack then
    metro.plateCategory = "FRIENDLY_NPC"
    if vis.npShowFriendlyNPCs == true then
      return true
    end
    if vis.npShowQuestNPCs ~= false and (isQuest or isTarget) then
      return true
    end
    return false
  end
  local inCombat = SafeBool(UnitAffectingCombat, unit)
  local playerInCombat = (InCombatLockdown and InCombatLockdown()) or SafeBool(UnitAffectingCombat, "player")
  local mobAggroed = isHostileEnemy or (reactNum <= 3) or (inCombat and (playerInCombat or SafeBool(UnitIsUnit, unit .. "target", "player")))
  if mobAggroed then
    metro.plateCategory = "ENEMY_NPC"
    return true
  else
    metro.plateCategory = "NEUTRAL_NPC"
    if vis.npShowNeutralNPCs ~= false then
      return true
    end
    if (vis.npShowQuestNPCs ~= false and isQuest) or isTarget then
      return true
    end
    return false
  end
end
UpdateMetroHealthAndColor = function(metro, now)
  local unit = metro and metro.unit
  if not unit then return end
  now = now or GetTime()
  -- Keep reaction & combat state fresh on every color tick so neutral mobs turn red the instant they aggro
  local okR, reaction = pcall(UnitReaction, unit, "player")
  if not okR or reaction == nil or IsSecret(reaction) then
    okR, reaction = pcall(UnitReaction, "player", unit)
  end
  if okR and not IsSecret(reaction) and type(reaction) == "number" then
    metro.reaction = reaction
  end
  local canAttack = SafeBool(UnitCanAttack, "player", unit)
  local isHostileEnemy = SafeBool(UnitIsEnemy, "player", unit)
  local inCombat = SafeBool(UnitAffectingCombat, unit)
  local reactNum = metro.reaction or (not canAttack and 5) or (isHostileEnemy and 2) or 4
  metro.isEnemy = canAttack
  metro.isFriend = not canAttack
  if metro.isPlayer then
    if not metro.cachedClassFile then
      local okC, _, classFile = pcall(UnitClass, unit)
      if okC and classFile then
        metro.classFile = classFile
        if not IsSecret(classFile) and type(classFile) == "string" then
          metro.cachedClassFile = classFile
        end
      end
    end
    metro.plateCategory = canAttack and "ENEMY_PLAYER" or "FRIENDLY_PLAYER"
  else
    if not canAttack then
      metro.plateCategory = "FRIENDLY_NPC"
    else
      local playerInCombat = (InCombatLockdown and InCombatLockdown()) or SafeBool(UnitAffectingCombat, "player")
      local mobAggroed = isHostileEnemy or (reactNum <= 3) or (inCombat and (playerInCombat or SafeBool(UnitIsUnit, unit .. "target", "player")))
      metro.plateCategory = mobAggroed and "ENEMY_NPC" or "NEUTRAL_NPC"
    end
  end

  -- 1. Health Values (Secret-Safe C++ StatusBar pass-through)
  local ok1, hp = pcall(UnitHealth, unit)
  local ok2, maxHp = pcall(UnitHealthMax, unit)
  if ok1 and ok2 and hp ~= nil and maxHp ~= nil then
    pcall(metro.healthBar.SetMinMaxValues, metro.healthBar, 0, maxHp)
    pcall(metro.healthBar.SetValue, metro.healthBar, hp)
    if not IsSecret(hp) and not IsSecret(maxHp) and type(hp) == "number" and type(maxHp) == "number" and maxHp > 0 then
      local pct = math.floor((hp / maxHp) * 100 + 0.5)
      if pct >= 100 then
        metro.hpText:SetText("")
      else
        metro.hpText:SetText(pct .. "%")
      end
    else
      metro.hpText:SetText("")
    end
  else
    metro.hpText:SetText("")
  end
  -- 2. 5-Category Color Evaluation:
  --    • Friendly Player (`isPlayer and not canAttack`) -> Class Color (RAID_CLASS_COLORS)
  --    • Hostile Player  (`isPlayer and canAttack`)     -> Active .MD DoT Color or Red (#D92626)
  --    • Friendly NPC    (`not isPlayer and not canAttack`) -> Always Green (#2ECC52)
  --    • Neutral NPC     (`not isPlayer and canAttack` & peaceful) -> Active .MD DoT Color or Yellow (#EBC729)
  --    • Hostile NPC     (`not isPlayer and canAttack` & aggressive) -> Active .MD DoT Color or Red (#D92626)
  local r, g, b = COLOR_HOSTILE_RED.r, COLOR_HOSTILE_RED.g, COLOR_HOSTILE_RED.b
  local auraR, auraG, auraB = nil, nil, nil
  if metro.plateCategory == "FRIENDLY_PLAYER" then
    metro.hasActiveDoT = false
    metro.livePlayerAuraCount = 0
    local cf = (not IsSecret(metro.classFile) and metro.classFile) or metro.cachedClassFile
    local cc = cf and not IsSecret(cf) and ((C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(cf)) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[cf]))
    if cc and cc.r and cc.g and cc.b then
      r, g, b = cc.r, cc.g, cc.b
    else
      r, g, b = COLOR_FRIENDLY_GREEN.r, COLOR_FRIENDLY_GREEN.g, COLOR_FRIENDLY_GREEN.b
    end
  elseif metro.plateCategory == "FRIENDLY_NPC" or not canAttack then
    metro.hasActiveDoT = false
    metro.livePlayerAuraCount = 0
    r, g, b = COLOR_FRIENDLY_GREEN.r, COLOR_FRIENDLY_GREEN.g, COLOR_FRIENDLY_GREEN.b
  else
    auraR, auraG, auraB = EvaluateNameplateAuraColor(unit, metro, now)
    metro.hasActiveDoT = (auraR ~= nil)
    if auraR and auraG and auraB then
      r, g, b = auraR, auraG, auraB
    elseif not metro.isPlayer and UnitIsTapDenied and SafeBool(UnitIsTapDenied, unit) then
      r, g, b = COLOR_TAPPED_GREY.r, COLOR_TAPPED_GREY.g, COLOR_TAPPED_GREY.b
    elseif metro.plateCategory == "ENEMY_PLAYER" or metro.plateCategory == "ENEMY_NPC" then
      r, g, b = COLOR_HOSTILE_RED.r, COLOR_HOSTILE_RED.g, COLOR_HOSTILE_RED.b
    else
      r, g, b = COLOR_NEUTRAL_YELLOW.r, COLOR_NEUTRAL_YELLOW.g, COLOR_NEUTRAL_YELLOW.b
    end
  end
  metro.healthBar:SetStatusBarColor(r, g, b, 1.0)
  UpdateMetroAuraIcons(metro, now, auraR, auraG, auraB)
end

UpdateMetroAuraIcons = function(metro, now, auraR, auraG, auraB)
  if not metro or not metro.auraRow or not metro.auraIcons then return end
  local db = SpArc:EnsureDB()
  local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL
  local count = (vis.npShowAuraIcons ~= false and metro.isEnemy and (metro.livePlayerAuraCount or 0)) or 0
  if count <= 0 then
    if metro.auraRow:IsShown() then
      metro.auraRow:Hide()
    end
    return
  end

  local iconSize = 18
  local gap = 2
  local totalW = count * iconSize + (count - 1) * gap
  metro.auraRow:SetSize(totalW, iconSize)

  local br = auraR or 0.72
  local bg = auraG or 0.34
  local bb = auraB or 1.00

  for i = 1, #metro.auraIcons do
    local aBox = metro.auraIcons[i]
    if i <= count then
      local aura = metro.livePlayerAuras and metro.livePlayerAuras[i]
      aBox:ClearAllPoints()
      aBox:SetPoint("LEFT", metro.auraRow, "LEFT", (i - 1) * (iconSize + gap), 0)
      if aura then
        pcall(aBox.icon.SetTexture, aBox.icon, aura.icon or 136243)
        if not IsSecret(aura.applications) and type(aura.applications) == "number" and aura.applications > 1 then
          aBox.count:SetText(tostring(aura.applications))
        else
          aBox.count:SetText("")
        end
        local rem = SpArc.ApplyAuraCooldownWidget(aBox.cd, aBox.timeText, metro.unit, aura, now)
        if rem and rem > 0 and rem < 4.5 then
          aBox:SetBackdropBorderColor(1.00, 0.36, 0.20, 1.0)
        else
          aBox:SetBackdropBorderColor(br, bg, bb, 1.0)
        end
      end
      aBox:Show()
    else
      aBox:Hide()
    end
  end
  if not metro.auraRow:IsShown() then
    metro.auraRow:Show()
  end
end

UpdateMetroCastbar = function(metro, now)
  if not metro or not metro.unit then return end
  SpArc.UpdateSecretSafeCastbar(metro.castBar, metro.unit, now or GetTime(), false)
end
FullUpdateMetroPlate = function(metro)
  if not metro or not metro.unit then return end
  if not SpArc:IsNameplatesEnabled() or IsBlockedByUnresolvedConflict() then
    metro:Hide()
    return
  end
  local unit = metro.unit
  local plate = metro:GetParent()
  SuppressBlizzardUnitFrame(plate, metro)
  if not EvaluatePlateVisibilityAndType(unit, metro) then
    metro:Hide()
    return
  end
  ApplyMetroGeometryToPlate(metro)
  -- Player Level (for both Friendly & Hostile Players)
  if metro.levelText then
    if metro.isPlayer and UnitLevel then
      local okL, uLvl = pcall(UnitLevel, unit)
      if okL and not IsSecret(uLvl) and type(uLvl) == "number" then
        metro.cachedLevel = uLvl
      end
      local lvlVal = metro.cachedLevel
      if lvlVal then
        metro.levelText:SetText(lvlVal < 0 and "??" or tostring(lvlVal))
        metro.nameText:ClearAllPoints()
        metro.nameText:SetPoint("LEFT", metro.levelText, "RIGHT", 4, 0)
        metro.nameText:SetPoint("RIGHT", metro.hpText, "LEFT", -4, 0)
      else
        metro.levelText:SetText("")
        metro.nameText:ClearAllPoints()
        metro.nameText:SetPoint("LEFT", metro.txtFrame, "LEFT", 6, 0)
        metro.nameText:SetPoint("RIGHT", metro.hpText, "LEFT", -4, 0)
      end
    else
      metro.levelText:SetText("")
      metro.nameText:ClearAllPoints()
      metro.nameText:SetPoint("LEFT", metro.txtFrame, "LEFT", 6, 0)
      metro.nameText:SetPoint("RIGHT", metro.hpText, "LEFT", -4, 0)
    end
  end
  -- Unit Name (Secret-Safe C++ pass-through)
  local okN, uName = pcall(UnitName, unit)
  if okN and uName ~= nil then
    pcall(metro.nameText.SetText, metro.nameText, uName)
  else
    metro.nameText:SetText("")
  end
  -- Target Highlight Border
  if metro.isTarget then
    metro.targetBorder:Show()
    metro:SetFrameStrata("HIGH")
  else
    metro.targetBorder:Hide()
    metro:SetFrameStrata("MEDIUM")
  end
  -- Player Left Class Icon Square (for both Friendly & Hostile Players)
  local db = SpArc:EnsureDB()
  local showClassIcon = (not db or not db.visual or db.visual.npShowHostileClassIcon ~= false)
  local cf = (not IsSecret(metro.classFile) and metro.classFile) or metro.cachedClassFile
  if showClassIcon and metro.isPlayer and cf and not IsSecret(cf) and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[cf] then
    local coords = CLASS_ICON_TCOORDS[cf]
    metro.classBox.icon:SetTexCoord(coords[1] + 0.02, coords[2] - 0.02, coords[3] + 0.02, coords[4] - 0.02)
    metro.classBox:Show()
  else
    metro.classBox:Hide()
  end
  -- Quest Indicator Badge (!)
  if metro.isQuestNPC then
    metro.questBadge:Show()
  else
    metro.questBadge:Hide()
  end
  local now = GetTime()
  UpdateMetroHealthAndColor(metro, now)
  UpdateMetroCastbar(metro, now)
  if SpArc.UpdateMetroDistanceFade then
    SpArc:UpdateMetroDistanceFade(metro, 0.05, true, true)
  end
  if not metro:IsShown() then
    metro:Show()
  end
end

function SpArc:GetActiveMetroUnits()
  return unitToMetro
end

function SpArc:UpdateMetroDistanceFade(metro, dt, recomputeTarget, forceSnap)
  if not metro or not metro.unit then return end
  local db = SpArc:EnsureDB()
  local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL
  if metro.isTarget then
    metro._targetFadeAlpha = 1.0
    metro._curFadeAlpha = 1.0
    if metro._appliedFadeAlpha ~= 1.0 then
      metro._appliedFadeAlpha = 1.0
      metro:SetAlpha(1.0)
    end
    return
  end

  local oocDimOn = (vis.npDimOutOfCombat ~= false)
  if not oocDimOn then
    metro._targetFadeAlpha = 1.0
    metro._curFadeAlpha = 1.0
    if metro._appliedFadeAlpha ~= 1.0 then
      metro._appliedFadeAlpha = 1.0
      metro:SetAlpha(1.0)
    end
    return
  end

  if recomputeTarget or not metro._targetFadeAlpha then
    local unit = metro.unit
    local tierA = 1.0
    -- Smooth 3D distance fading is handled by the C++ parent plate (`nameplateMinAlpha` / `nameplateMaxAlphaDistance`).
    -- Here we only apply gentle out-of-combat dimming so we never double-multiply distance alpha (`0.30 * 0.30 = 0.09`).
    local unitInCombat = SafeBool(UnitAffectingCombat, unit) or metro.hasActiveDoT
    if not unitInCombat then
      local playerInCombat = (InCombatLockdown and InCombatLockdown()) or SafeBool(UnitAffectingCombat, "player")
      if playerInCombat then
        tierA = 0.52
      elseif st.currentTargetMetro ~= nil then
        tierA = 0.78
      elseif metro.reaction == 4 then
        tierA = 0.90
      end
    end
    metro._targetFadeAlpha = tierA
  end

  local cur = metro._curFadeAlpha or metro._targetFadeAlpha or 1.0
  local tgt = metro._targetFadeAlpha or 1.0
  if forceSnap or math.abs(tgt - cur) < 0.015 then
    cur = tgt
  else
    cur = cur + (tgt - cur) * math.min(1.0, (dt or 0.05) * 8.0)
  end
  metro._curFadeAlpha = cur
  if not metro._appliedFadeAlpha or math.abs(cur - metro._appliedFadeAlpha) >= 0.01 then
    metro._appliedFadeAlpha = cur
    metro:SetAlpha(cur)
  end
end
function SpArc:RefreshAllNameplates()
  SpArc:CompileNameplateAuraRules()
  SpArc:SyncExternalNameplateAddons()
  local enabled = SpArc:IsNameplatesEnabled() and not IsBlockedByUnresolvedConflict()
  if C_NamePlate and C_NamePlate.GetNamePlates then
    local okP, plates = pcall(C_NamePlate.GetNamePlates)
    if okP and type(plates) == "table" then
      for _, plate in ipairs(plates) do
        local metro = CreateMetroPlate(plate)
        local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit) or metro.unit
        if unit then
          metro.unit = unit
          unitToMetro[unit] = metro
          if enabled then
            FullUpdateMetroPlate(metro)
          else
            metro:Hide()
          end
        end
      end
    end
  end
  for _, metro in pairs(activeMetroPlates) do
    if not enabled then
      metro:Hide()
    elseif metro.unit then
      FullUpdateMetroPlate(metro)
    end
  end
end
---------------------------------------------------------------------------------------
--  6. EVENT DRIVER & ONUPDATE TICKER (30 FPS FOR CASTBARS & AURA TIMERS)
---------------------------------------------------------------------------------------
local npDriver = CreateFrame("Frame")
npDriver:RegisterEvent("PLAYER_LOGIN")
npDriver:RegisterEvent("PLAYER_ENTERING_WORLD")
npDriver:RegisterEvent("NAME_PLATE_CREATED")
npDriver:RegisterEvent("NAME_PLATE_UNIT_ADDED")
npDriver:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
npDriver:RegisterEvent("PLAYER_TARGET_CHANGED")
npDriver:RegisterEvent("PLAYER_REGEN_DISABLED")
npDriver:RegisterEvent("PLAYER_REGEN_ENABLED")
npDriver:RegisterEvent("QUEST_LOG_UPDATE")
pcall(npDriver.RegisterEvent, npDriver, "UNIT_QUEST_LOG_CHANGED")
pcall(npDriver.RegisterEvent, npDriver, "PLAYER_SOFT_INTERACT_CHANGED")
npDriver:RegisterEvent("UNIT_HEALTH")
npDriver:RegisterEvent("UNIT_MAXHEALTH")
npDriver:RegisterEvent("UNIT_AURA")
npDriver:RegisterEvent("UNIT_FACTION")
npDriver:RegisterEvent("UNIT_NAME_UPDATE")
npDriver:RegisterEvent("UNIT_LEVEL")
npDriver:RegisterEvent("UNIT_FLAGS")
npDriver:SetScript("OnEvent", function(_, event, arg1)
  if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
    questCacheByGUID = {}
    questTipNextScanByUnit = {}
    SpArc:RefreshAllNameplates()
    return
  end
  if event == "QUEST_LOG_UPDATE" or event == "UNIT_QUEST_LOG_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" then
    local now = GetTime()
    if event ~= "PLAYER_SOFT_INTERACT_CHANGED" and npDriver._lastQuestRefreshAt and (now - npDriver._lastQuestRefreshAt) < 0.35 then
      return
    end
    npDriver._lastQuestRefreshAt = now
    questCacheByGUID = {}
    questTipNextScanByUnit = {}
    for _, metro in pairs(unitToMetro) do
      if metro and metro.unit then
        FullUpdateMetroPlate(metro)
      end
    end
    return
  end
  if event == "NAME_PLATE_CREATED" then
    local plate = arg1
    if plate then
      local metro = CreateMetroPlate(plate)
      if SpArc:IsNameplatesEnabled() and not IsBlockedByUnresolvedConflict() then
        SuppressBlizzardUnitFrame(plate, metro)
      end
    end
    return
  end
  if event == "NAME_PLATE_UNIT_ADDED" then
    local unit = arg1
    if not unit or not C_NamePlate or not C_NamePlate.GetNamePlateForUnit then return end
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if not ok or not plate then return end
    local metro = CreateMetroPlate(plate)
    metro.unit = unit
    metro.trackedAuras = {}
    metro._lastPlayerDebuffCount = 0
    unitToMetro[unit] = metro
    FullUpdateMetroPlate(metro)
    return
  end
  if event == "NAME_PLATE_UNIT_REMOVED" then
    local unit = arg1
    if unit then
      local metro = unitToMetro[unit]
      if metro then
        if st.currentTargetMetro == metro then
          st.currentTargetMetro = nil
        end
        metro:Hide()
        metro.unit = nil
        metro.unitGUID = nil
        metro.isTarget = false
        metro.trackedAuras = nil
        metro._lastPlayerDebuffCount = 0
        metro.cachedLevel = nil
        metro.cachedClassFile = nil
      end
      unitToMetro[unit] = nil
      if st.nameplateUnitAuras then
        st.nameplateUnitAuras[unit] = nil
      end
    end
    return
  end
  if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
    if event == "PLAYER_REGEN_ENABLED" then
      SpArc:SyncExternalNameplateAddons()
    end
    if event == "PLAYER_TARGET_CHANGED" then
      local now = GetTime()
      local tgtMetro = GetMetroForUnitToken("target")
      st.currentTargetMetro = tgtMetro
      for _, metro in pairs(unitToMetro) do
        if metro and metro.unit then
          local wasTarget = metro.isTarget
          local isNowTarget = (tgtMetro ~= nil and tgtMetro == metro) or SafeBool(UnitIsUnit, metro.unit, "target")
          if isNowTarget then
            st.currentTargetMetro = metro
          end
          if wasTarget ~= isNowTarget or not metro:IsShown() then
            FullUpdateMetroPlate(metro)
          elseif isNowTarget then
            UpdateMetroHealthAndColor(metro, now)
            UpdateMetroCastbar(metro, now)
          else
            SpArc:UpdateMetroDistanceFade(metro, 0.05, true, false)
          end
        end
      end
      return
    end
    for _, metro in pairs(unitToMetro) do
      if metro and metro.unit then
        FullUpdateMetroPlate(metro)
      end
    end
    return
  end
  -- Unit-specific events (UNIT_HEALTH, UNIT_AURA, UNIT_FACTION, UNIT_NAME_UPDATE, UNIT_LEVEL, UNIT_FLAGS)
  local unit = arg1
  if unit and not IsSecret(unit) and type(unit) == "string" then
    local metro = unitToMetro[unit]
    if metro then
      if event == "UNIT_AURA" and metro.isEnemy and st.lastCastDoTInfo then
        local now = GetTime()
        local info = st.lastCastDoTInfo
        local dt = now - (info.castAt or 0)
        if dt < 2.2 and C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex then
          -- Only stamp fallback tracker if WoW 12.x actually returned SECRET spellIds AND this unit's player-debuff count jumped!
          local prevCount = metro._lastPlayerDebuffCount or 0
          local curCount = 0
          local anySecret = false
          for i = 1, 16 do
            local ok, aura = pcall(C_UnitAuras.GetDebuffDataByIndex, unit, i, "HARMFUL|PLAYER")
            if not ok or type(aura) ~= "table" then break end
            curCount = curCount + 1
            if IsSecret(aura.spellId) then anySecret = true end
          end
          if anySecret and curCount > prevCount then
            if info.isAoE or (not info.isAoE and info.primaryMetro == nil and dt < 0.45) then
              for _, aID in ipairs(info.ids or {}) do
                local aDur = DEFAULT_AURA_DURATIONS[aID] or (info.dur or 18.0)
                RecordAuraOnMetroAndUnit(metro, unit, metro.unitGUID, aID, info.lowName, now + aDur, now)
              end
              if not info.isAoE and info.primaryMetro == nil then
                info.primaryMetro = metro
              end
            elseif info.unclaimedSpreads and info.unclaimedSpreads > 0 and dt < 1.2 and metro ~= info.primaryMetro then
              info.unclaimedSpreads = info.unclaimedSpreads - 1
              for _, aID in ipairs(info.ids or {}) do
                local aDur = DEFAULT_AURA_DURATIONS[aID] or (info.dur or 18.0)
                RecordAuraOnMetroAndUnit(metro, unit, metro.unitGUID, aID, info.lowName, now + aDur, now)
              end
            end
          end
        end
      end
      if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_AURA" then
        if metro:IsShown() then
          UpdateMetroHealthAndColor(metro, GetTime())
        else
          FullUpdateMetroPlate(metro)
        end
      else
        FullUpdateMetroPlate(metro)
      end
    end
  end
end)
local tickElapsed = 0
local auraTickElapsed = 0
npDriver:SetScript("OnUpdate", function(_, elapsed)
  tickElapsed = tickElapsed + elapsed
  auraTickElapsed = auraTickElapsed + elapsed
  if tickElapsed < 0.05 then return end
  tickElapsed = 0
  if not SpArc:IsNameplatesEnabled() then return end
  local now = GetTime()
  local doAuraRefresh = false
  if auraTickElapsed >= 0.25 then
    auraTickElapsed = 0
    doAuraRefresh = true
  end
  for _, metro in pairs(unitToMetro) do
    if metro and metro.unit then
      if doAuraRefresh and not metro.isPlayer then
        local wasQuest = metro.isQuestNPC
        local shouldShow = EvaluatePlateVisibilityAndType(metro.unit, metro)
        if shouldShow ~= metro:IsShown() or metro.isQuestNPC ~= wasQuest then
          FullUpdateMetroPlate(metro)
        end
      end
      if metro:IsShown() then
        if doAuraRefresh then
          UpdateMetroHealthAndColor(metro, now)
        end
        local uEv = st.unitCastState and st.unitCastState[metro.unit]
        if doAuraRefresh or metro.castBar:IsShown() or (uEv and uEv.active) then
          UpdateMetroCastbar(metro, now)
        end
        if SpArc.UpdateMetroDistanceFade then
          SpArc:UpdateMetroDistanceFade(metro, 0.05, doAuraRefresh, false)
        end
      end
    end
  end
  if SpArc.RecordModuleTick then
    SpArc:RecordModuleTick("Nameplates", "OnUpdate")
  end
end)
---------------------------------------------------------------------------------------
--  7. MODULE 10 UI: METRO NAMEPLATES & DYNAMIC AURA COLOR RULES EDITOR
---------------------------------------------------------------------------------------
local function FormatColorHex(r, g, b)
  local ri = math.max(0, math.min(255, math.floor((r or 0) * 255 + 0.5)))
  local gi = math.max(0, math.min(255, math.floor((g or 0) * 255 + 0.5)))
  local bi = math.max(0, math.min(255, math.floor((b or 0) * 255 + 0.5)))
  return string.format("%02X%02X%02X", ri, gi, bi)
end
local function OpenWoWColorPicker(r, g, b, onColorChanged)
  if not ColorPickerFrame then return end
  local prevR, prevG, prevB = r or 1, g or 1, b or 1
  if ColorPickerFrame.SetupColorPickerAndShow then
    local info = {
      r = prevR,
      g = prevG,
      b = prevB,
      hasOpacity = false,
      swatchFunc = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        if onColorChanged then onColorChanged(nr, ng, nb) end
      end,
      cancelFunc = function()
        if onColorChanged then onColorChanged(prevR, prevG, prevB) end
      end,
    }
    ColorPickerFrame:SetupColorPickerAndShow(info)
  else
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.func = function()
      local nr, ng, nb = ColorPickerFrame:GetColorRGB()
      if onColorChanged then onColorChanged(nr, ng, nb) end
    end
    ColorPickerFrame.cancelFunc = function()
      if onColorChanged then onColorChanged(prevR, prevG, prevB) end
    end
    ColorPickerFrame:SetColorRGB(prevR, prevG, prevB)
    ColorPickerFrame:Hide()
    ColorPickerFrame:Show()
  end
end
local function DescribeAuraIDsString(idsStr)
  local ids = ParseIDListString(idsStr)
  if #ids == 0 then
    return "|cffff6060" .. SpArc:L("M10_INVALID_IDS") .. "|r", nil
  end
  local parts = {}
  local firstIcon = nil
  for _, id in ipairs(ids) do
    local nm, ic = GetSpellNameAndIconSafe(id)
    if not firstIcon and ic then firstIcon = ic end
    local texTag = ic and ("|T" .. tostring(ic) .. ":14:14:0:0:64:64:5:59:5:59|t ") or ""
    if nm then
      parts[#parts + 1] = texTag .. "|cffffffff" .. nm .. "|r |cff888899(" .. tostring(id) .. ")|r"
    else
      parts[#parts + 1] = "|cffffd100ID " .. tostring(id) .. "|r"
    end
  end
  local joinWord = " |cff00ffcc" .. SpArc:L("M10_AND_JOIN") .. "|r "
  return table.concat(parts, joinWord), firstIcon
end
function SpArc:BuildNameplatesPage(page, ui, helpers)
  local ApplyCyrFont = helpers.ApplyCyrFont
  local CreateElvButton = helpers.CreateElvButton
  local RegisterGroupBox = helpers.RegisterGroupBox
  local SetBackdropFlat = helpers.SetBackdropFlat
  local CreateElvCheck = helpers.CreateElvCheck
  local CreateElvSlider = helpers.CreateElvSlider
  local controlFrame = helpers.controlFrame
  ui.m10Title = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(ui.m10Title, 15)
  ui.m10Title:SetPoint("TOPLEFT", 0, 0)
  ui.m10Title:SetTextColor(1, 0.85, 0.25, 1)
  -- Row 1 Checkboxes: Module & Player Settings
  local cEnable = CreateElvCheck(page, "MOD_ENABLE", "enableNameplates", 0, -22, true, false, function()
    SpArc:RefreshAllNameplates()
  end)
  cEnable:SetWidth(145)
  local cClassIcon = CreateElvCheck(page, "CK_NP_CLASS_ICON", "npShowHostileClassIcon", 155, -22, false, false, function()
    SpArc:RefreshAllNameplates()
  end)
  cClassIcon:SetWidth(250)
  local cFriendly = CreateElvCheck(page, "CK_NP_FRIENDLY", "npShowFriendlyPlayers", 415, -22, false, false, function()
    SpArc:RefreshAllNameplates()
  end)
  cFriendly:SetWidth(285)
  -- Row 2 Checkboxes: NPC Visibility Filter (Quest NPCs vs All Friendly/Neutral NPCs)
  local cQuestNPCs = CreateElvCheck(page, "CK_NP_QUEST_NPCS", "npShowQuestNPCs", 0, -45, false, false, function()
    SpArc:RefreshAllNameplates()
  end)
  cQuestNPCs:SetWidth(285)
  local cFriendlyNPCs = CreateElvCheck(page, "CK_NP_FRIENDLY_NPCS", "npShowFriendlyNPCs", 295, -45, false, false, function()
    SpArc:RefreshAllNameplates()
  end)
  cFriendlyNPCs:SetWidth(245)
  local cNeutralNPCs = CreateElvCheck(page, "CK_NP_NEUTRAL_NPCS", "npShowNeutralNPCs", 550, -45, false, false, function()
    SpArc:RefreshAllNameplates()
  end)
  cNeutralNPCs:SetWidth(245)
  -- Group 1: Geometry Sliders + Distance Fade + Live Metro Preview Tile (Top Box)
  local geoBox = RegisterGroupBox(page, "M10_GRP_GEO", 0, -74, 640, 200)
  CreateElvSlider(geoBox, "SL_NP_WIDTH", "npWidth", 90, 240, 2, 16, -8, 195, function()
    SpArc:RefreshAllNameplates()
    if SpArc.RefreshNameplatesPage then SpArc:RefreshNameplatesPage(ui) end
  end)
  CreateElvSlider(geoBox, "SL_NP_HEIGHT", "npHeight", 18, 46, 1, 224, -8, 195, function()
    SpArc:RefreshAllNameplates()
    if SpArc.RefreshNameplatesPage then SpArc:RefreshNameplatesPage(ui) end
  end)
  CreateElvSlider(geoBox, "SL_NP_CAST_H", "npCastHeight", 8, 24, 1, 16, -66, 195, function()
    SpArc:RefreshAllNameplates()
    if SpArc.RefreshNameplatesPage then SpArc:RefreshNameplatesPage(ui) end
  end)
  CreateElvSlider(geoBox, "SL_NP_FONT", "npFontSize", 8, 16, 1, 224, -66, 195, function()
    SpArc:RefreshAllNameplates()
    if SpArc.RefreshNameplatesPage then SpArc:RefreshNameplatesPage(ui) end
  end)
  CreateElvSlider(geoBox, "SL_NP_MAX_DIST", "npMaxDistance", 20, 60, 2, 16, -124, 195, function()
    SpArc:RefreshAllNameplates()
    if SpArc.RefreshNameplatesPage then SpArc:RefreshNameplatesPage(ui) end
  end)
  CreateElvSlider(geoBox, "SL_NP_MIN_ALPHA", "npMinAlpha", 0.10, 1.00, 0.05, 224, -124, 195, function()
    SpArc:RefreshAllNameplates()
    if SpArc.RefreshNameplatesPage then SpArc:RefreshNameplatesPage(ui) end
  end)
  -- Live Metro Tile Preview Box on the right side of geoBox
  local prevPanel = CreateFrame("Frame", nil, geoBox, "BackdropTemplate")
  prevPanel:SetPoint("TOPLEFT", geoBox, "TOPLEFT", 536, -10)
  prevPanel:SetPoint("BOTTOMRIGHT", geoBox, "BOTTOMRIGHT", -12, 10)
  SetBackdropFlat(prevPanel, 0.04, 0.04, 0.06, 0.96, 0.22, 0.22, 0.30, 1.0)
  local prevTitle = prevPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyCyrFont(prevTitle, 10)
  prevTitle:SetPoint("TOP", prevPanel, "TOP", 0, -6)
  prevTitle:SetTextColor(0.85, 0.85, 0.92, 1)
  ui.m10PrevTitle = prevTitle
  local demoMetro = CreateMetroPlate(prevPanel, true)
  demoMetro:ClearAllPoints()
  demoMetro:SetPoint("CENTER", prevPanel, "CENTER", 6, 4)
  demoMetro:Show()
  demoMetro.targetBorder:Show()
  demoMetro.classBox:Show()
  if CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS["MAGE"] then
    local tc = CLASS_ICON_TCOORDS["MAGE"]
    demoMetro.classBox.icon:SetTexCoord(tc[1] + 0.02, tc[2] - 0.02, tc[3] + 0.02, tc[4] - 0.02)
  end
  demoMetro.questBadge:Show()
  demoMetro.castBar:Show()
  demoMetro.castBar.glow:Show()
  demoMetro.castBar.iconBox.icon:SetTexture(135846)
  demoMetro.castBar.bar:SetMinMaxValues(0, 100)
  demoMetro.castBar.bar:SetValue(68)
  demoMetro.castBar.spellText:SetText("Shadow Bolt")
  demoMetro.castBar.timeText:SetText("1.2")
  ui.m10DemoMetro = demoMetro
  local cycleBtn = CreateElvButton(prevPanel, 174, 20, "")
  cycleBtn:SetPoint("BOTTOM", prevPanel, "BOTTOM", 0, 5)
  cycleBtn:SetScript("OnClick", function()
    local db = SpArc:EnsureDB()
    local total = (db.npAuraRules and #db.npAuraRules) or 0
    previewColorMode = (previewColorMode + 1) % (total + 1)
    SpArc:RefreshNameplatesPage(ui)
  end)
  ui.m10CyclePrevBtn = cycleBtn
  -- Group 2: Dynamic Aura / DoT Color Rules (Auto-synced from .MD + Custom rules)
  local rulesBox = RegisterGroupBox(page, "M10_GRP_AURAS", 0, -282, 640, 336)
  local cAutoMD = CreateElvCheck(rulesBox, "CK_NP_AUTO_MD", "npAutoAurasFromMD", 14, -8, false, false, function(checked)
    if checked and SpArc.SyncNameplateAurasFromActiveMD then
      SpArc:SyncNameplateAurasFromActiveMD(nil, false)
    end
    SpArc:RefreshAllNameplates()
    if SpArc.RefreshNameplatesPage then SpArc:RefreshNameplatesPage(ui) end
  end)
  cAutoMD:SetWidth(290)
  local cAuraIcons = CreateElvCheck(rulesBox, "CK_NP_AURA_ICONS", "npShowAuraIcons", 310, -8, false, false, function()
    SpArc:RefreshAllNameplates()
    if SpArc.RefreshNameplatesPage then SpArc:RefreshNameplatesPage(ui) end
  end)
  cAuraIcons:SetWidth(240)
  local cDistFade = CreateElvCheck(rulesBox, "CK_NP_DIST_FADE", "npDistanceFade", 556, -8, false, false, function()
    SpArc:RefreshAllNameplates()
    if SpArc.RefreshNameplatesPage then SpArc:RefreshNameplatesPage(ui) end
  end)
  cDistFade:SetWidth(230)
  -- Add New Rule Bar
  local newIDBg = CreateFrame("Frame", nil, rulesBox, "BackdropTemplate")
  newIDBg:SetPoint("TOPLEFT", rulesBox, "TOPLEFT", 14, -34)
  newIDBg:SetSize(185, 26)
  SetBackdropFlat(newIDBg, 0.03, 0.03, 0.05, 1.0, 0.30, 0.30, 0.42, 1.0)
  local newIDEdit = CreateFrame("EditBox", nil, newIDBg)
  newIDEdit:SetPoint("TOPLEFT", 6, -2)
  newIDEdit:SetPoint("BOTTOMRIGHT", -6, 2)
  newIDEdit:SetFontObject("ChatFontNormal")
  ApplyCyrFont(newIDEdit, 12)
  newIDEdit:SetAutoFocus(false)
  local defSampleIDs = "164812, 164815"
  local initMD = SpArc.GetMDAuraRulesForPreset and SpArc:GetMDAuraRulesForPreset(nil, nil)
  if type(initMD) == "table" and initMD[1] and type(initMD[1].ids) == "string" and initMD[1].ids ~= "" then
    defSampleIDs = initMD[1].ids
  end
  newIDEdit:SetText(defSampleIDs)
  newIDEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  ui.m10NewIDEdit = newIDEdit
  ui.m10NewColor = { r = 0.20, g = 0.88, b = 0.45 }
  local newColorBtn = CreateElvButton(rulesBox, 96, 26, "")
  newColorBtn:SetPoint("LEFT", newIDBg, "RIGHT", 6, 0)
  local newSwatch = newColorBtn:CreateTexture(nil, "OVERLAY")
  newSwatch:SetSize(14, 14)
  newSwatch:SetPoint("LEFT", newColorBtn, "LEFT", 7, 0)
  newSwatch:SetColorTexture(ui.m10NewColor.r, ui.m10NewColor.g, ui.m10NewColor.b, 1.0)
  newColorBtn.swatch = newSwatch
  newColorBtn.fs:ClearAllPoints()
  newColorBtn.fs:SetPoint("LEFT", newSwatch, "RIGHT", 6, 0)
  local function UpdateNewColorBtnVisual()
    local c = ui.m10NewColor
    newSwatch:SetColorTexture(c.r, c.g, c.b, 1.0)
    newColorBtn:SetText("#" .. FormatColorHex(c.r, c.g, c.b))
  end
  UpdateNewColorBtnVisual()
  newColorBtn:SetScript("OnClick", function()
    local c = ui.m10NewColor
    OpenWoWColorPicker(c.r, c.g, c.b, function(nr, ng, nb)
      c.r, c.g, c.b = nr, ng, nb
      UpdateNewColorBtnVisual()
    end)
  end)
  ui.m10NewColorBtn = newColorBtn
  local addRuleBtn = CreateElvButton(rulesBox, 185, 26, "")
  addRuleBtn:SetPoint("LEFT", newColorBtn, "RIGHT", 6, 0)
  addRuleBtn:SetScript("OnClick", function()
    local db = SpArc:EnsureDB()
    local raw = SpArc.Trim(newIDEdit:GetText() or "")
    local parsed = ParseIDListString(raw)
    if #parsed == 0 then
      print(SpArc:L("MSG_M10_ENTER_ID"))
      return
    end
    local cleanStr = {}
    for _, id in ipairs(parsed) do cleanStr[#cleanStr + 1] = tostring(id) end
    db.npAuraRules = db.npAuraRules or {}
    table.insert(db.npAuraRules, 1, {
      enabled = true,
      ids = table.concat(cleanStr, ", "),
      r = ui.m10NewColor.r,
      g = ui.m10NewColor.g,
      b = ui.m10NewColor.b,
      fromMD = false,
      isCustomUserRule = true,
    })
    newIDEdit:ClearFocus()
    SpArc:RefreshAllNameplates()
    controlFrame:RefreshUI()
  end)
  ui.m10AddRuleBtn = addRuleBtn
  local resetRulesBtn = CreateElvButton(rulesBox, 132, 26, "")
  resetRulesBtn:SetPoint("LEFT", addRuleBtn, "RIGHT", 6, 0)
  resetRulesBtn:SetScript("OnClick", function()
    if SpArc.ResetCurrentProfileAuraRules then
      SpArc:ResetCurrentProfileAuraRules()
    end
    previewColorMode = 0
    SpArc:RefreshAllNameplates()
    controlFrame:RefreshUI()
  end)
  ui.m10ResetRulesBtn = resetRulesBtn
  -- Scrollable Rules List Container
  local listFrame = CreateFrame("Frame", nil, rulesBox, "BackdropTemplate")
  listFrame:SetPoint("TOPLEFT", rulesBox, "TOPLEFT", 14, -66)
  listFrame:SetPoint("BOTTOMRIGHT", rulesBox, "BOTTOMRIGHT", -14, 10)
  SetBackdropFlat(listFrame, 0.04, 0.04, 0.06, 0.96, 0.20, 0.20, 0.27, 1.0)
  local rulesScroll = CreateFrame("ScrollFrame", "SpArcNPAuraRulesScroll", listFrame, "UIPanelScrollFrameTemplate")
  rulesScroll:SetPoint("TOPLEFT", 4, -4)
  rulesScroll:SetPoint("BOTTOMRIGHT", -26, 4)
  local rulesContent = CreateFrame("Frame", nil, rulesScroll)
  rulesContent:SetSize(752, 480)
  rulesScroll:SetScrollChild(rulesContent)
  ui.m10RulesContent = rulesContent
  ui.m10RuleRows = {}
  for idx = 1, 20 do
    local row = CreateFrame("Frame", nil, rulesContent, "BackdropTemplate")
    row:SetSize(752, 30)
    row:SetPoint("TOPLEFT", rulesContent, "TOPLEFT", 0, -(idx - 1) * 32)
    SetBackdropFlat(row, 0.08, 0.08, 0.11, 0.94, 0.18, 0.18, 0.25, 1.0)
    -- Enable toggle button
    local chk = CreateFrame("Button", nil, row, "BackdropTemplate")
    chk:SetSize(18, 18)
    chk:SetPoint("LEFT", row, "LEFT", 8, 0)
    SetBackdropFlat(chk, 0.03, 0.03, 0.05, 1.0, 0.34, 0.34, 0.44, 1.0)
    local chkFill = chk:CreateTexture(nil, "ARTWORK")
    chkFill:SetPoint("TOPLEFT", 3, -3)
    chkFill:SetPoint("BOTTOMRIGHT", -3, 3)
    chkFill:SetColorTexture(0.20, 0.88, 0.36, 1.0)
    chk.fill = chkFill
    row.chk = chk
    -- Editable IDs Box
    local idBoxBg = CreateFrame("Frame", nil, row, "BackdropTemplate")
    idBoxBg:SetSize(160, 22)
    idBoxBg:SetPoint("LEFT", chk, "RIGHT", 8, 0)
    SetBackdropFlat(idBoxBg, 0.03, 0.03, 0.05, 1.0, 0.26, 0.26, 0.36, 1.0)
    local idEdit = CreateFrame("EditBox", nil, idBoxBg)
    idEdit:SetPoint("TOPLEFT", 5, -1)
    idEdit:SetPoint("BOTTOMRIGHT", -5, 1)
    idEdit:SetFontObject("ChatFontNormal")
    ApplyCyrFont(idEdit, 11)
    idEdit:SetAutoFocus(false)
    idEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    row.idEdit = idEdit
    -- Resolved Spell Names & Condition Badge
    local descTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ApplyCyrFont(descTxt, 11)
    descTxt:SetPoint("LEFT", idBoxBg, "RIGHT", 8, 0)
    descTxt:SetWidth(415)
    descTxt:SetJustifyH("LEFT")
    descTxt:SetWordWrap(false)
    row.descTxt = descTxt
    -- Color Swatch Button
    local colBtn = CreateElvButton(row, 88, 22, "")
    colBtn:SetPoint("RIGHT", row, "RIGHT", -36, 0)
    local sw = colBtn:CreateTexture(nil, "OVERLAY")
    sw:SetSize(13, 13)
    sw:SetPoint("LEFT", colBtn, "LEFT", 6, 0)
    colBtn.swatch = sw
    colBtn.fs:ClearAllPoints()
    colBtn.fs:SetPoint("LEFT", sw, "RIGHT", 5, 0)
    row.colBtn = colBtn
    -- Delete Button [X]
    local delBtn = CreateElvButton(row, 24, 22, "|cffff5555X|r")
    delBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.delBtn = delBtn
    chk:SetScript("OnClick", function()
      local db = SpArc:EnsureDB()
      local rObj = db.npAuraRules and db.npAuraRules[row.ruleIdx]
      if rObj then
        rObj.enabled = not (rObj.enabled ~= false)
        SpArc:RefreshAllNameplates()
        SpArc:RefreshNameplatesPage(ui)
      end
    end)
    local function CommitIDEdit(self)
      local db = SpArc:EnsureDB()
      local rObj = db.npAuraRules and db.npAuraRules[row.ruleIdx]
      if rObj then
        local parsed = ParseIDListString(self:GetText() or "")
        if #parsed > 0 then
          local clean = {}
          for _, id in ipairs(parsed) do clean[#clean + 1] = tostring(id) end
          rObj.ids = table.concat(clean, ", ")
        end
        SpArc:RefreshAllNameplates()
        SpArc:RefreshNameplatesPage(ui)
      end
    end
    idEdit:SetScript("OnEnterPressed", function(self)
      self:ClearFocus()
      CommitIDEdit(self)
    end)
    idEdit:SetScript("OnEditFocusLost", function(self)
      CommitIDEdit(self)
    end)
    colBtn:SetScript("OnClick", function()
      local db = SpArc:EnsureDB()
      local rObj = db.npAuraRules and db.npAuraRules[row.ruleIdx]
      if not rObj then return end
      OpenWoWColorPicker(rObj.r, rObj.g, rObj.b, function(nr, ng, nb)
        rObj.r, rObj.g, rObj.b = nr, ng, nb
        previewColorMode = row.ruleIdx
        SpArc:RefreshAllNameplates()
        SpArc:RefreshNameplatesPage(ui)
      end)
    end)
    delBtn:SetScript("OnClick", function()
      local db = SpArc:EnsureDB()
      if db.npAuraRules and db.npAuraRules[row.ruleIdx] then
        table.remove(db.npAuraRules, row.ruleIdx)
        previewColorMode = 0
        SpArc:RefreshAllNameplates()
        SpArc:RefreshNameplatesPage(ui)
      end
    end)
    row:Hide()
    ui.m10RuleRows[idx] = row
  end
end
function SpArc:RefreshNameplatesPage(ui)
  if not ui or not ui.m10Title then return end
  local db = SpArc:EnsureDB()
  local rules = db.npAuraRules or {}
  ui.m10Title:SetText(SpArc:L("M10_TITLE"))
  if ui.m10HintTxt then ui.m10HintTxt:SetText(SpArc:L("M10_AURA_HINT")) end
  if ui.m10AddRuleBtn then ui.m10AddRuleBtn:SetText(SpArc:L("M10_ADD_RULE_BTN")) end
  if ui.m10ResetRulesBtn then ui.m10ResetRulesBtn:SetText(SpArc:L("M10_RESET_RULES_BTN")) end
  -- Update Demo Metro Preview Tile
  if ui.m10DemoMetro then
    local demo = ui.m10DemoMetro
    local vis = db.visual or SpArc.DEFAULT_VISUAL
    local w = math.min(150, tonumber(vis.npWidth) or 140)
    local h = math.min(36, tonumber(vis.npHeight) or 30)
    local cbH = math.min(20, tonumber(vis.npCastHeight) or 14)
    local fSize = tonumber(vis.npFontSize) or 11
    demo:SetSize(w, h)
    demo.classBox:SetSize(h, h)
    demo.classBox:SetShown(vis.npShowHostileClassIcon ~= false)
    demo.castBar:SetHeight(cbH)
    demo.castBar.iconBox:SetSize(cbH, cbH)
    if demo.levelText then
      ApplyCyrFont(demo.levelText, math.max(8, fSize - 1))
      local pLvl = (UnitLevel and not IsSecret(UnitLevel("player"))) and tonumber(UnitLevel("player")) or 80
      demo.levelText:SetText(tostring(pLvl and pLvl > 0 and pLvl or 80))
      demo.levelText:Show()
      demo.nameText:ClearAllPoints()
      demo.nameText:SetPoint("LEFT", demo.levelText, "RIGHT", 4, 0)
    end
    ApplyCyrFont(demo.nameText, fSize)
    ApplyCyrFont(demo.hpText, math.max(8, fSize - 1))
    local pName = (UnitName and UnitName("player"))
    if not pName or IsSecret(pName) or pName == "" then
      pName = (SpArc.IsRU and SpArc:IsRU()) and "Котастрофа" or "Target Dummy"
    end
    demo.nameText:SetText(pName)
    demo.hpText:SetText("84%")
    local r, g, b = COLOR_HOSTILE_RED.r, COLOR_HOSTILE_RED.g, COLOR_HOSTILE_RED.b
    local modeLabel = SpArc:L("M10_PREV_BASE")
    if previewColorMode > 0 and rules[previewColorMode] then
      local pr = rules[previewColorMode]
      r, g, b = pr.r or r, pr.g or g, pr.b or b
      modeLabel = string.format(SpArc:L("M10_PREV_RULE"), previewColorMode, pr.ids or "")
    end
    demo.healthBar:SetStatusBarColor(r, g, b, 1.0)
    if demo.auraRow and demo.auraIcons then
      if vis.npShowAuraIcons ~= false then
        local demoTex = { 136214, 136207, 252997 }
        local demoSec = { "18", "12", "4.1" }
        demo.auraRow:SetSize(3 * 18 + 2 * 2, 18)
        for i = 1, #demo.auraIcons do
          local box = demo.auraIcons[i]
          if i <= 3 then
            box:ClearAllPoints()
            box:SetPoint("LEFT", demo.auraRow, "LEFT", (i - 1) * 20, 0)
            box.icon:SetTexture(demoTex[i])
            box.timeText:SetText(demoSec[i])
            if i == 3 then
              box.timeText:SetTextColor(1.0, 0.36, 0.22, 1.0)
              box:SetBackdropBorderColor(1.0, 0.36, 0.20, 1.0)
            else
              box.timeText:SetTextColor(1.0, 0.98, 0.92, 1.0)
              box:SetBackdropBorderColor(r, g, b, 1.0)
            end
            box.count:SetText("")
            box:Show()
          else
            box:Hide()
          end
        end
        demo.auraRow:Show()
      else
        demo.auraRow:Hide()
      end
    end
    if ui.m10PrevTitle then ui.m10PrevTitle:SetText(modeLabel) end
    if ui.m10CyclePrevBtn then ui.m10CyclePrevBtn:SetText(SpArc:L("M10_CYCLE_PREV_BTN")) end
  end
  -- Populate Aura Rule Rows
  for idx = 1, #ui.m10RuleRows do
    local row = ui.m10RuleRows[idx]
    local rObj = rules[idx]
    if rObj then
      row.ruleIdx = idx
      local en = (rObj.enabled ~= false)
      row.chk.fill:SetShown(en)
      if not row.idEdit:HasFocus() then
        row.idEdit:SetText(rObj.ids or "")
      end
      local descStr = DescribeAuraIDsString(rObj.ids or "")
      row.descTxt:SetText(descStr)
      row.colBtn.swatch:SetColorTexture(rObj.r or 0.2, rObj.g or 0.6, rObj.b or 1.0, 1.0)
      row.colBtn:SetText("#" .. FormatColorHex(rObj.r, rObj.g, rObj.b))
      row:Show()
    else
      row.ruleIdx = nil
      row:Hide()
    end
  end
  if ui.m10RulesContent then
    ui.m10RulesContent:SetHeight(math.max(200, #rules * 32 + 8))
  end
end
