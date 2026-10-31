---------------------------------------------------------------------------------------
--  SpArc/Nameplates.lua — Minimalist Windows Metro Tile Nameplates, Castbar & Aura Colors
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
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
local UnitClass = _G.UnitClass
local UnitGUID = _G.UnitGUID
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitCastingInfo = _G.UnitCastingInfo
local UnitChannelInfo = _G.UnitChannelInfo
local UnitCastingDuration = _G.UnitCastingDuration
local UnitChannelDuration = _G.UnitChannelDuration
local UnitEmpoweredChannelDuration = _G.UnitEmpoweredChannelDuration
local UnitNameplateShowsWidgetsOnly = _G.UnitNameplateShowsWidgetsOnly
local UnitIsGameObject = _G.UnitIsGameObject
local UnitIsTapDenied = _G.UnitIsTapDenied
local InCombatLockdown = _G.InCombatLockdown
local C_NamePlate = _G.C_NamePlate
local C_UnitAuras = _G.C_UnitAuras
local C_Spell = _G.C_Spell
local C_QuestLog = _G.C_QuestLog
local C_TooltipInfo = _G.C_TooltipInfo
local C_ClassColor = _G.C_ClassColor
local C_CVar = _G.C_CVar
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
local st = SpArc.state
local FLAT_TEX = "Interface\\Buttons\\WHITE8x8"
local CLASS_ICONS_TEX = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
-- Base Metro Colors
local COLOR_HOSTILE_RED   = { r = 0.85, g = 0.15, b = 0.15 } -- #D92626 Ruby Red
local COLOR_TAPPED_GREY   = { r = 0.50, g = 0.50, b = 0.54 }
local COLOR_CAST_GOLD     = { r = 1.00, g = 0.80, b = 0.15 } -- #FFCC26 Interruptible Gold
local COLOR_CAST_GREY     = { r = 0.45, g = 0.47, b = 0.50 } -- #737780 Uninterruptible Grey
-- Known Cast Spell ID <-> Debuff Aura ID aliases (so either Wowhead ID works seamlessly)
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
  [205385]  = { 34914, 589 },     -- Shadow Crash -> VT + SW:P
  [457042]  = { 34914, 589 },     -- Tentacle Slam / Shadow Crash -> VT + SW:P
  [1247227] = { 121411 },         -- Crimson Tempest
  [121411]  = { 1247227 },
  [384318]  = { 772, 388539 },    -- Thunderous Roar / Rend
  [772]     = { 388539 },
}
-- AoE DoT spells that apply their debuff to nearby engaged enemies as well as target
local AOE_DOT_SPELLS = {
  [93402]   = { auras = { 164815, 93402 },  dur = 18.0 }, -- Sunfire
  [164815]  = { auras = { 164815, 93402 },  dur = 18.0 },
  [205385]  = { auras = { 34914, 589 },     dur = 21.0 }, -- Shadow Crash
  [457042]  = { auras = { 34914, 589 },     dur = 21.0 }, -- Tentacle Slam
  [285381]  = { auras = { 1079, 285381 },   dur = 16.0 }, -- Primal Wrath
  [106832]  = { auras = { 405233, 106832 }, dur = 15.0 }, -- Thrash
  [121411]  = { auras = { 121411 },         dur = 12.0 }, -- Crimson Tempest
  [1247227] = { auras = { 121411 },         dur = 12.0 },
  [6343]    = { auras = { 772 },            dur = 15.0 }, -- Thunder Clap (Rend)
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
---------------------------------------------------------------------------------------
--  1. AURA RULE COMPILER & RESOLVER
---------------------------------------------------------------------------------------
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
local function GetSpellNameAndIconSafe(spellID)
  if not spellID or spellID <= 0 then return nil, nil end
  if C_Spell and C_Spell.GetSpellInfo then
    local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
    if ok and type(info) == "table" then
      local nm = (not IsSecret(info.name) and type(info.name) == "string" and info.name ~= "") and info.name or nil
      local ic = (not IsSecret(info.iconID) and info.iconID) or nil
      return nm, ic
    end
  end
  if _G.GetSpellInfo then
    local ok, nm, _, ic = pcall(_G.GetSpellInfo, spellID)
    if ok and not IsSecret(nm) and type(nm) == "string" and nm ~= "" then
      return nm, (not IsSecret(ic) and ic) or nil
    end
  end
  return nil, nil
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
--  2. CAST-BASED AURA FALLBACK TRACKER (FOR WOW 12.X SECRET AURA SAFETY)
---------------------------------------------------------------------------------------
local function RecordAuraOnUnitAndGUID(unit, guid, auraID, lowName, untilTime)
  st.nameplateAuras = st.nameplateAuras or {}
  st.nameplateUnitAuras = st.nameplateUnitAuras or {}
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
function SpArc:RecordNameplateAuraCast(spellID, defKey, now)
  now = now or GetTime()
  local def = defKey and SpArc.SPELL_DEFS and SpArc.SPELL_DEFS[defKey]
  local castID = (not IsSecret(spellID) and type(spellID) == "number" and spellID)
    or (def and def.liveSpellID)
    or (def and def.ids and def.ids[1])
  if not castID then return end
  local dur = (def and def.auraDuration and def.auraDuration > 0 and def.auraDuration)
    or DEFAULT_AURA_DURATIONS[castID]
    or 18.0
  local untilTime = now + dur
  local idsToRecord = { castID }
  local seen = { [castID] = true }
  if SPELL_AURA_ALIASES[castID] then
    for _, al in ipairs(SPELL_AURA_ALIASES[castID]) do
      if not seen[al] then seen[al] = true; idsToRecord[#idsToRecord + 1] = al end
    end
  end
  if def then
    local dList = def.auraIDs or def.debuffIDs or def.ids
    if dList then
      for _, id in ipairs(dList) do
        if not seen[id] then seen[id] = true; idsToRecord[#idsToRecord + 1] = id end
        if SPELL_AURA_ALIASES[id] then
          for _, al in ipairs(SPELL_AURA_ALIASES[id]) do
            if not seen[al] then seen[al] = true; idsToRecord[#idsToRecord + 1] = al end
          end
        end
      end
    end
  end
  local nm = GetSpellNameAndIconSafe(castID)
  local lowName = (nm and SpArc.UTF8Lower and SpArc.UTF8Lower(nm)) or (nm and nm:lower()) or nil
  -- 1. Record on current target (GUID + matching nameplate unit)
  local tGUID = nil
  if UnitGUID and SafeBool(UnitExists, "target") then
    local okG, g = pcall(UnitGUID, "target")
    if okG and not IsSecret(g) and type(g) == "string" then
      tGUID = g
    end
  end
  local targetPlateUnit = nil
  for npUnit, _ in pairs(unitToMetro) do
    if SafeBool(UnitIsUnit, npUnit, "target") then
      targetPlateUnit = npUnit
      break
    end
  end
  for _, aID in ipairs(idsToRecord) do
    RecordAuraOnUnitAndGUID(targetPlateUnit, tGUID, aID, lowName, untilTime)
  end
  -- 2. If AoE DoT (e.g. Sunfire, Shadow Crash, Thrash, Primal Wrath), also tag nearby enemy nameplates
  local aoeInfo = AOE_DOT_SPELLS[castID]
  if aoeInfo then
    local aoeUntil = now + (aoeInfo.dur or dur)
    for npUnit, metro in pairs(unitToMetro) do
      if metro and metro.isEnemy and (SafeBool(UnitAffectingCombat, npUnit) or SafeBool(UnitIsUnit, npUnit, "target") or metro.reaction == 4) then
        local npGUID = metro.unitGUID
        for _, aID in ipairs(aoeInfo.auras) do
          RecordAuraOnUnitAndGUID(npUnit, npGUID, aID, lowName, aoeUntil)
        end
      end
    end
  elseif castID == 8921 or castID == 164812 then
    -- Twin Moons (279620): Moonfire also hits a 2nd nearby enemy
    local hasTwinMoons = (_G.IsPlayerSpell and SafeBool(_G.IsPlayerSpell, 279620)) or false
    if hasTwinMoons then
      for npUnit, metro in pairs(unitToMetro) do
        if metro and metro.isEnemy and not SafeBool(UnitIsUnit, npUnit, "target") and (SafeBool(UnitAffectingCombat, npUnit) or metro.reaction == 4) then
          local npGUID = metro.unitGUID
          for _, aID in ipairs(idsToRecord) do
            RecordAuraOnUnitAndGUID(npUnit, npGUID, aID, lowName, untilTime)
          end
          break
        end
      end
    end
  end
end
local function DoesUnitHaveAuraGroup(unit, metro, group, liveIDSet, liveNameSet, now)
  -- 1. Check live scanned player debuffs on unit
  for id in pairs(group.idSet) do
    if liveIDSet[id] then
      return true
    end
  end
  if group.lowerName and liveNameSet[group.lowerName] then
    return true
  end
  -- 2. Direct C_UnitAuras.GetUnitAuraBySpellID check
  if C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID then
    for _, id in ipairs(group.idList) do
      local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, unit, id)
      if ok and type(aura) == "table" then
        local src = aura.sourceUnit
        if IsSecret(src) or src == nil or src == "player" or src == "pet" then
          local exp = aura.expirationTime
          if IsSecret(exp) or type(exp) ~= "number" or exp == 0 or exp > now then
            return true
          end
        end
      end
    end
  end
  -- 3. Fallback: SpArc GUID & Unit Aura Tracker (works even when 12.x marks unit auras secret)
  local guid = metro and metro.unitGUID
  if guid and st.nameplateAuras and st.nameplateAuras[guid] then
    local gMap = st.nameplateAuras[guid]
    for id in pairs(group.idSet) do
      local uTime = gMap[id]
      if uTime and uTime > now then return true end
    end
    if group.lowerName and gMap[group.lowerName] and gMap[group.lowerName] > now then
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
  if metro and metro.isTarget and st.unitAuras and st.unitAuras.target then
    local tMap = st.unitAuras.target
    for id in pairs(group.idSet) do
      local entry = tMap[id] or tMap[tostring(id)]
      local exp = entry and (entry.expiresAt or entry.untilTime)
      if exp and exp > now then return true end
    end
  end
  return false
end
local reusableLiveIDSet = {}
local reusableLiveNameSet = {}
local function EvaluateNameplateAuraColor(unit, metro, now)
  if not compiledAuraRules or #compiledAuraRules == 0 then
    return nil, nil, nil
  end
  for k in pairs(reusableLiveIDSet) do reusableLiveIDSet[k] = nil end
  for k in pairs(reusableLiveNameSet) do reusableLiveNameSet[k] = nil end
  if C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex then
    for i = 1, 16 do
      local ok, aura = pcall(C_UnitAuras.GetDebuffDataByIndex, unit, i, "HARMFUL|PLAYER")
      if not ok or type(aura) ~= "table" then
        break
      end
      local exp = aura.expirationTime
      if IsSecret(exp) or type(exp) ~= "number" or exp == 0 or exp > now then
        if not IsSecret(aura.spellId) and type(aura.spellId) == "number" then
          reusableLiveIDSet[aura.spellId] = true
        end
        if not IsSecret(aura.name) and type(aura.name) == "string" and aura.name ~= "" then
          local low = SpArc.UTF8Lower and SpArc.UTF8Lower(aura.name) or aura.name:lower()
          reusableLiveNameSet[low] = true
        end
      end
    end
  end
  for _, rule in ipairs(compiledAuraRules) do
    local allMatched = true
    for _, grp in ipairs(rule.reqGroups) do
      if not DoesUnitHaveAuraGroup(unit, metro, grp, reusableLiveIDSet, reusableLiveNameSet, now) then
        allMatched = false
        break
      end
    end
    if allMatched then
      return rule.r, rule.g, rule.b
    end
  end
  return nil, nil, nil
end
---------------------------------------------------------------------------------------
--  3. QUEST NPC DETECTION (NATIVE + TOOLTIP SCAN CACHE)
---------------------------------------------------------------------------------------
local function IsUnitQuestRelated(unit, guid)
  local db = SpArc:EnsureDB()
  if db and db.visual and db.visual.npShowQuestNPCs == false then
    return false
  end
  if not unit or SafeBool(UnitIsPlayer, unit) then
    return false
  end
  if C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest then
    local okQ, isRel = pcall(C_QuestLog.UnitIsRelatedToActiveQuest, unit)
    if okQ and not IsSecret(isRel) and isRel == true then
      if guid and not IsSecret(guid) then questCacheByGUID[guid] = true end
      return true
    end
  end
  if guid and not IsSecret(guid) and questCacheByGUID[guid] ~= nil then
    return questCacheByGUID[guid]
  end
  if C_TooltipInfo and C_TooltipInfo.GetUnit then
    local okT, tip = pcall(C_TooltipInfo.GetUnit, unit)
    if okT and type(tip) == "table" and type(tip.lines) == "table" then
      for i = 2, #tip.lines do
        local ln = tip.lines[i]
        if type(ln) == "table" and not IsSecret(ln.type) then
          -- 17 = QuestTitle, 8 = QuestObjective
          if ln.type == 17 or ln.type == 8 then
            if guid and not IsSecret(guid) then questCacheByGUID[guid] = true end
            return true
          end
        end
      end
    end
  end
  if guid and not IsSecret(guid) then
    questCacheByGUID[guid] = false
  end
  return false
end
---------------------------------------------------------------------------------------
--  4. BLIZZARD & ELVUI NAMEPLATE SUPPRESSION (ZERO-TAINT)
---------------------------------------------------------------------------------------
local function SuppressSubFrameEvents(sf)
  if sf and sf.UnregisterAllEvents then
    pcall(sf.UnregisterAllEvents, sf)
  end
end
local function SuppressBlizzardUnitFrame(plate, metro)
  if not plate then return end
  local uFrame = plate.UnitFrame
  if uFrame then
    pcall(uFrame.Hide, uFrame)
    pcall(uFrame.SetAlpha, uFrame, 0)
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
      pcall(_G.hooksecurefunc, uFrame, "Show", function(self)
        if SpArc:IsNameplatesEnabled() then
          pcall(self.Hide, self)
          pcall(self.SetAlpha, self, 0)
        end
      end)
    end
    -- Preserve SoftTargetFrame (Interact E icon) and WidgetContainer on our Metro frame
    if metro and not metro._reparentedSoftTarget then
      metro._reparentedSoftTarget = true
      if uFrame.SoftTargetFrame then
        pcall(uFrame.SoftTargetFrame.SetParent, uFrame.SoftTargetFrame, metro)
        pcall(uFrame.SoftTargetFrame.SetIgnoreParentAlpha, uFrame.SoftTargetFrame, true)
      end
      if uFrame.WidgetContainer then
        pcall(uFrame.WidgetContainer.SetParent, uFrame.WidgetContainer, metro)
        pcall(uFrame.WidgetContainer.SetIgnoreParentAlpha, uFrame.WidgetContainer, true)
      end
    end
  end
  -- Also hide ElvUI's per-plate unitFrame if ElvUI spawned one before suppression
  if plate.unitFrame and plate.unitFrame ~= metro then
    pcall(plate.unitFrame.UnregisterAllEvents, plate.unitFrame)
    pcall(plate.unitFrame.Hide, plate.unitFrame)
    pcall(plate.unitFrame.SetAlpha, plate.unitFrame, 0)
  end
end
function SpArc:SyncExternalNameplateAddons()
  local enabled = SpArc:IsNameplatesEnabled()
  if _G.ElvUI then
    local okE, E = pcall(_G.unpack, _G.ElvUI)
    if okE and type(E) == "table" and E.GetModule then
      local okNP, NP = pcall(E.GetModule, E, "NamePlates", true)
      if okNP and type(NP) == "table" then
        if enabled then
          if NP.PlateDriver then
            pcall(NP.PlateDriver.UnregisterAllEvents, NP.PlateDriver)
          end
          if NP.PlayerFrame then pcall(NP.PlayerFrame.Hide, NP.PlayerFrame) end
          if NP.TargetClassPower then pcall(NP.TargetClassPower.Hide, NP.TargetClassPower) end
          if NP.PlayerNamePlateAnchor then pcall(NP.PlayerNamePlateAnchor.Hide, NP.PlayerNamePlateAnchor) end
          elvUINPSuppressed = true
        elseif elvUINPSuppressed then
          if NP.PlateDriver then
            pcall(NP.PlateDriver.RegisterEvent, NP.PlateDriver, "NAME_PLATE_UNIT_ADDED")
            pcall(NP.PlateDriver.RegisterEvent, NP.PlateDriver, "NAME_PLATE_UNIT_REMOVED")
            pcall(NP.PlateDriver.RegisterEvent, NP.PlateDriver, "PLAYER_TARGET_CHANGED")
          end
          elvUINPSuppressed = false
        end
      end
    end
  end
  if enabled and C_CVar and C_CVar.SetCVar and not (InCombatLockdown and InCombatLockdown()) then
    pcall(C_CVar.SetCVar, "nameplateShowEnemies", "1")
    local db = SpArc:EnsureDB()
    if db and db.visual and db.visual.npShowFriendlyPlayers ~= false then
      pcall(C_CVar.SetCVar, "nameplateShowFriends", "1")
      pcall(C_CVar.SetCVar, "nameplateShowOnlyNameForFriendlyPlayerUnits", "0")
    end
    pcall(C_CVar.SetCVar, "nameplateMinScale", "1")
    pcall(C_CVar.SetCVar, "nameplateMaxScale", "1")
    pcall(C_CVar.SetCVar, "nameplateSelectedScale", "1")
  end
end
---------------------------------------------------------------------------------------
--  5. METRO TILE FRAME FACTORY & UPDATER
---------------------------------------------------------------------------------------
local function CreateBorderFrame(parent, thickness, r, g, b, a, levelOffset)
  local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  f:SetAllPoints(parent)
  f:SetFrameLevel(parent:GetFrameLevel() + (levelOffset or 2))
  f:SetBackdrop({
    edgeFile = FLAT_TEX,
    edgeSize = thickness or 1,
  })
  f:SetBackdropBorderColor(r or 0.05, g or 0.05, b or 0.08, a or 1.0)
  return f
end
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
  -- 2px Target Highlight Border
  local tBorder = CreateFrame("Frame", nil, hb, "BackdropTemplate")
  tBorder:SetPoint("TOPLEFT", hb, "TOPLEFT", -1, 1)
  tBorder:SetPoint("BOTTOMRIGHT", hb, "BOTTOMRIGHT", 1, -1)
  tBorder:SetFrameLevel(hb:GetFrameLevel() + 4)
  tBorder:SetBackdrop({
    edgeFile = FLAT_TEX,
    edgeSize = 2,
  })
  tBorder:SetBackdropBorderColor(1.00, 0.96, 0.82, 1.0)
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
  local fSize = tonumber(vis.npFontSize) or 11
  if metro._appliedW == w and metro._appliedH == h and metro._appliedCbH == cbH and metro._appliedFSize == fSize then
    return
  end
  metro._appliedW = w
  metro._appliedH = h
  metro._appliedCbH = cbH
  metro._appliedFSize = fSize
  metro:SetSize(w, h)
  metro.classBox:SetSize(h, h)
  local qSize = math.max(18, math.min(26, h - 4))
  metro.questBadge:SetSize(qSize, qSize)
  metro.castBar:SetHeight(cbH)
  metro.castBar.iconBox:SetSize(cbH, cbH)
  ApplyCyrFont(metro.nameText, fSize)
  ApplyCyrFont(metro.hpText, math.max(8, fSize - 1))
  local cbFont = math.max(8, math.min(12, cbH - 4))
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
  local isEnemy = SafeBool(UnitIsEnemy, "player", unit) or SafeBool(UnitCanAttack, "player", unit)
  local isFriend = SafeBool(UnitIsFriend, "player", unit) and not isEnemy
  local okR, reaction = pcall(UnitReaction, "player", unit)
  local reactNum = (okR and not IsSecret(reaction) and type(reaction) == "number" and reaction) or (isEnemy and 2 or 5)
  local isTarget = SafeBool(UnitIsUnit, unit, "target")
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
    metro.classFile = (okC and classFile) or nil
    if isEnemy or reactNum <= 4 then
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
  -- NPC Logic
  metro.classFile = nil
  local isQuest = IsUnitQuestRelated(unit, cleanGUID)
  metro.isQuestNPC = isQuest
  -- Hostile NPC (reaction <= 3)
  if reactNum <= 3 or SafeBool(UnitIsEnemy, "player", unit) then
    metro.plateCategory = "ENEMY_NPC"
    return true
  end
  -- Quest NPC (even if neutral or friendly)
  if isQuest then
    metro.plateCategory = "QUEST_NPC"
    return true
  end
  -- Neutral (yellow) NPC that is in combat, targeted, or attackable dummy
  if reactNum == 4 and (SafeBool(UnitAffectingCombat, unit) or isTarget) then
    metro.plateCategory = "ENEMY_NPC"
    return true
  end
  -- Non-quest Friendly/Neutral out-of-combat NPCs are hidden to keep towns clean
  return false
end
local function UpdateMetroHealthAndColor(metro, now)
  local unit = metro and metro.unit
  if not unit then return end
  now = now or GetTime()
  -- 1. Health Values (Secret-Safe C++ StatusBar pass-through)
  local ok1, hp = pcall(UnitHealth, unit)
  local ok2, maxHp = pcall(UnitHealthMax, unit)
  if ok1 and ok2 and hp ~= nil and maxHp ~= nil then
    pcall(metro.healthBar.SetMinMaxValues, metro.healthBar, 0, maxHp)
    pcall(metro.healthBar.SetValue, metro.healthBar, hp)
    if not IsSecret(hp) and not IsSecret(maxHp) and type(hp) == "number" and type(maxHp) == "number" and maxHp > 0 then
      local pct = math.floor((hp / maxHp) * 100 + 0.5)
      if metro.plateCategory == "FRIENDLY_PLAYER" and pct >= 100 then
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
  -- 2. Color Evaluation
  local r, g, b = COLOR_HOSTILE_RED.r, COLOR_HOSTILE_RED.g, COLOR_HOSTILE_RED.b
  if metro.plateCategory == "FRIENDLY_PLAYER" then
    local cf = metro.classFile
    local cObj = nil
    if cf then
      if IsSecret(cf) and C_ClassColor and C_ClassColor.GetClassColor then
        local okCC, cc = pcall(C_ClassColor.GetClassColor, cf)
        if okCC then cObj = cc end
      elseif not IsSecret(cf) and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cf] then
        cObj = RAID_CLASS_COLORS[cf]
      end
    end
    if cObj and cObj.r then
      r, g, b = cObj.r, cObj.g, cObj.b
    else
      r, g, b = 0.25, 0.78, 0.92
    end
  else
    -- Hostile NPC, Hostile Player, or Quest NPC:
    -- First check Dynamic Aura / DoT Color Rules!
    local auraR, auraG, auraB = EvaluateNameplateAuraColor(unit, metro, now)
    if auraR and auraG and auraB then
      r, g, b = auraR, auraG, auraB
    elseif not metro.isPlayer and UnitIsTapDenied and SafeBool(UnitIsTapDenied, unit) then
      r, g, b = COLOR_TAPPED_GREY.r, COLOR_TAPPED_GREY.g, COLOR_TAPPED_GREY.b
    else
      r, g, b = COLOR_HOSTILE_RED.r, COLOR_HOSTILE_RED.g, COLOR_HOSTILE_RED.b
    end
  end
  metro.healthBar:SetStatusBarColor(r, g, b, 1.0)
end
local function UpdateMetroCastbar(metro, now)
  local unit = metro and metro.unit
  if not unit then return end
  now = now or GetTime()
  local cbCont = metro.castBar
  local isCasting, isInterruptible, isChannel, spellName, spellIcon, remSec, durSec = SpArc:GetUnitCastInterruptState(unit, now)
  if not isCasting then
    if cbCont:IsShown() then
      cbCont:Hide()
    end
    return
  end
  cbCont.iconBox.icon:SetTexture(spellIcon or 136243)
  pcall(cbCont.spellText.SetText, cbCont.spellText, spellName or "Cast")
  -- Check if startTime/endTime were secret and use 12.x SetTimerDuration if needed
  local usedTimerDuration = false
  if cbCont.bar.SetTimerDuration then
    local durObj = nil
    if isChannel and UnitChannelDuration then
      local okD, d = pcall(UnitChannelDuration, unit)
      if okD and d then durObj = d end
    elseif not isChannel and UnitCastingDuration then
      local okD, d = pcall(UnitCastingDuration, unit)
      if okD and d then durObj = d end
    end
    if durObj and _G.Enum and _G.Enum.StatusBarTimerDirection and _G.Enum.StatusBarInterpolation then
      local dir = isChannel and _G.Enum.StatusBarTimerDirection.RemainingTime or _G.Enum.StatusBarTimerDirection.ElapsedTime
      local okTD = pcall(cbCont.bar.SetTimerDuration, cbCont.bar, durObj, _G.Enum.StatusBarInterpolation.Immediate, dir)
      if okTD then
        usedTimerDuration = true
      end
    end
  end
  if not usedTimerDuration then
    local total = math.max(0.1, durSec or 1.5)
    local val = isChannel and math.max(0, remSec or 0) or math.max(0, total - (remSec or 0))
    cbCont.bar:SetMinMaxValues(0, total)
    cbCont.bar:SetValue(val)
  end
  if remSec and remSec > 0 and remSec < 60 then
    cbCont.timeText:SetText(string.format("%.1f", remSec))
  else
    cbCont.timeText:SetText("")
  end
  if isInterruptible then
    cbCont.bar:SetStatusBarColor(COLOR_CAST_GOLD.r, COLOR_CAST_GOLD.g, COLOR_CAST_GOLD.b, 1.0)
    cbCont.border:SetBackdropBorderColor(1.00, 0.85, 0.20, 1.0)
    local pulse = 0.72 + 0.28 * math.abs(math.sin(now * 6.5))
    cbCont.glow:SetBackdropBorderColor(1.00, 0.86, 0.20, pulse)
    cbCont.glow.outerGlow:SetColorTexture(1.00, 0.82, 0.15, 0.18 + 0.18 * pulse)
    cbCont.glow:Show()
  else
    cbCont.bar:SetStatusBarColor(COLOR_CAST_GREY.r, COLOR_CAST_GREY.g, COLOR_CAST_GREY.b, 1.0)
    cbCont.border:SetBackdropBorderColor(0.05, 0.05, 0.08, 1.0)
    cbCont.glow:Hide()
  end
  if not cbCont:IsShown() then
    cbCont:Show()
  end
end
local function FullUpdateMetroPlate(metro)
  if not metro or not metro.unit then return end
  if not SpArc:IsNameplatesEnabled() then
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
  -- Hostile Player Left Class Icon Square
  local db = SpArc:EnsureDB()
  local showClassIcon = (not db or not db.visual or db.visual.npShowHostileClassIcon ~= false)
  if showClassIcon and metro.plateCategory == "ENEMY_PLAYER" and metro.classFile and not IsSecret(metro.classFile) and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[metro.classFile] then
    local coords = CLASS_ICON_TCOORDS[metro.classFile]
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
  if not metro:IsShown() then
    metro:Show()
  end
end
function SpArc:RefreshAllNameplates()
  SpArc:CompileNameplateAuraRules()
  SpArc:SyncExternalNameplateAddons()
  local enabled = SpArc:IsNameplatesEnabled()
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
npDriver:RegisterEvent("UNIT_HEALTH")
npDriver:RegisterEvent("UNIT_MAXHEALTH")
npDriver:RegisterEvent("UNIT_AURA")
npDriver:RegisterEvent("UNIT_FACTION")
npDriver:RegisterEvent("UNIT_NAME_UPDATE")
npDriver:RegisterEvent("UNIT_FLAGS")
npDriver:SetScript("OnEvent", function(_, event, arg1)
  if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
    questCacheByGUID = {}
    SpArc:RefreshAllNameplates()
    return
  end
  if event == "QUEST_LOG_UPDATE" then
    if InCombatLockdown and InCombatLockdown() then
      return
    end
    local now = GetTime()
    if npDriver._lastQuestRefreshAt and (now - npDriver._lastQuestRefreshAt) < 1.5 then
      return
    end
    npDriver._lastQuestRefreshAt = now
    questCacheByGUID = {}
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
      if SpArc:IsNameplatesEnabled() then
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
    unitToMetro[unit] = metro
    FullUpdateMetroPlate(metro)
    return
  end
  if event == "NAME_PLATE_UNIT_REMOVED" then
    local unit = arg1
    if unit then
      local metro = unitToMetro[unit]
      if metro then
        metro:Hide()
        metro.unit = nil
        metro.unitGUID = nil
        metro.isTarget = false
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
      for _, metro in pairs(unitToMetro) do
        if metro and metro.unit then
          local wasTarget = metro.isTarget
          local isNowTarget = SafeBool(UnitIsUnit, metro.unit, "target")
          if wasTarget ~= isNowTarget or not metro:IsShown() then
            FullUpdateMetroPlate(metro)
          elseif isNowTarget then
            UpdateMetroHealthAndColor(metro, now)
            UpdateMetroCastbar(metro, now)
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
  -- Unit-specific events (UNIT_HEALTH, UNIT_AURA, UNIT_FACTION, UNIT_NAME_UPDATE, UNIT_FLAGS)
  local unit = arg1
  if unit and not IsSecret(unit) and type(unit) == "string" then
    local metro = unitToMetro[unit]
    if metro then
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
    if metro and metro.unit and metro:IsShown() then
      if doAuraRefresh then
        UpdateMetroHealthAndColor(metro, now)
      end
      local uEv = st.unitCastState and st.unitCastState[metro.unit]
      if doAuraRefresh or metro.castBar:IsShown() or (uEv and uEv.active) then
        UpdateMetroCastbar(metro, now)
      end
    end
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
  -- Top Row Checkboxes
  local cEnable = CreateElvCheck(page, "MOD_ENABLE", "enableNameplates", 0, -22, true, false, function()
    SpArc:RefreshAllNameplates()
  end)
  cEnable:SetWidth(130)
  local cClassIcon = CreateElvCheck(page, "CK_NP_CLASS_ICON", "npShowHostileClassIcon", 135, -22, false, false, function()
    SpArc:RefreshAllNameplates()
  end)
  cClassIcon:SetWidth(240)
  local cFriendly = CreateElvCheck(page, "CK_NP_FRIENDLY", "npShowFriendlyPlayers", 385, -22, false, false, function()
    SpArc:RefreshAllNameplates()
  end)
  cFriendly:SetWidth(255)
  -- Group 1: Geometry Sliders + Live Metro Preview Tile (Top Box)
  local geoBox = RegisterGroupBox(page, "M10_GRP_GEO", 0, -52, 640, 154)
  CreateElvSlider(geoBox, "SL_NP_WIDTH", "npWidth", 90, 240, 2, 16, -12, 195, function()
    SpArc:RefreshAllNameplates()
    if SpArc.RefreshNameplatesPage then SpArc:RefreshNameplatesPage(ui) end
  end)
  CreateElvSlider(geoBox, "SL_NP_HEIGHT", "npHeight", 18, 46, 1, 224, -12, 195, function()
    SpArc:RefreshAllNameplates()
    if SpArc.RefreshNameplatesPage then SpArc:RefreshNameplatesPage(ui) end
  end)
  CreateElvSlider(geoBox, "SL_NP_CAST_H", "npCastHeight", 8, 24, 1, 16, -74, 195, function()
    SpArc:RefreshAllNameplates()
    if SpArc.RefreshNameplatesPage then SpArc:RefreshNameplatesPage(ui) end
  end)
  CreateElvSlider(geoBox, "SL_NP_FONT", "npFontSize", 8, 16, 1, 224, -74, 195, function()
    SpArc:RefreshAllNameplates()
    if SpArc.RefreshNameplatesPage then SpArc:RefreshNameplatesPage(ui) end
  end)
  -- Live Metro Tile Preview Box on the right side of geoBox
  local prevPanel = CreateFrame("Frame", nil, geoBox, "BackdropTemplate")
  prevPanel:SetPoint("TOPLEFT", geoBox, "TOPLEFT", 432, -10)
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
  -- Group 2: Dynamic Aura / DoT Color Rules ("Добавить ауру" + условия И)
  local rulesBox = RegisterGroupBox(page, "M10_GRP_AURAS", 0, -218, 640, 306)
  local hintTxt = rulesBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyCyrFont(hintTxt, 11)
  hintTxt:SetPoint("TOPLEFT", rulesBox, "TOPLEFT", 14, -10)
  hintTxt:SetPoint("TOPRIGHT", rulesBox, "TOPRIGHT", -14, -10)
  hintTxt:SetJustifyH("LEFT")
  hintTxt:SetTextColor(0.82, 0.86, 0.94, 1)
  ui.m10HintTxt = hintTxt
  -- Add New Rule Bar
  local newIDBg = CreateFrame("Frame", nil, rulesBox, "BackdropTemplate")
  newIDBg:SetPoint("TOPLEFT", rulesBox, "TOPLEFT", 14, -32)
  newIDBg:SetSize(185, 26)
  SetBackdropFlat(newIDBg, 0.03, 0.03, 0.05, 1.0, 0.30, 0.30, 0.42, 1.0)
  local newIDEdit = CreateFrame("EditBox", nil, newIDBg)
  newIDEdit:SetPoint("TOPLEFT", 6, -2)
  newIDEdit:SetPoint("BOTTOMRIGHT", -6, 2)
  newIDEdit:SetFontObject("ChatFontNormal")
  ApplyCyrFont(newIDEdit, 12)
  newIDEdit:SetAutoFocus(false)
  local defSampleIDs = "164812, 164815"
  if UnitClass then
    local okC, _, pCls = pcall(UnitClass, "player")
    if okC and pCls == "PRIEST" then
      defSampleIDs = "34914, 589"
    elseif okC and pCls == "ROGUE" then
      defSampleIDs = "703, 1943"
    elseif okC and pCls == "WARRIOR" then
      defSampleIDs = "772"
    end
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
  listFrame:SetPoint("TOPLEFT", rulesBox, "TOPLEFT", 14, -64)
  listFrame:SetPoint("BOTTOMRIGHT", rulesBox, "BOTTOMRIGHT", -14, 10)
  SetBackdropFlat(listFrame, 0.04, 0.04, 0.06, 0.96, 0.20, 0.20, 0.27, 1.0)
  local rulesScroll = CreateFrame("ScrollFrame", "SpArcNPAuraRulesScroll", listFrame, "UIPanelScrollFrameTemplate")
  rulesScroll:SetPoint("TOPLEFT", 4, -4)
  rulesScroll:SetPoint("BOTTOMRIGHT", -26, 4)
  local rulesContent = CreateFrame("Frame", nil, rulesScroll)
  rulesContent:SetSize(576, 400)
  rulesScroll:SetScrollChild(rulesContent)
  ui.m10RulesContent = rulesContent
  ui.m10RuleRows = {}
  for idx = 1, 20 do
    local row = CreateFrame("Frame", nil, rulesContent, "BackdropTemplate")
    row:SetSize(576, 30)
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
    idBoxBg:SetSize(134, 22)
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
    descTxt:SetWidth(265)
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
    ApplyCyrFont(demo.nameText, fSize)
    ApplyCyrFont(demo.hpText, math.max(8, fSize - 1))
    local pName = (UnitName and UnitName("player"))
    if not pName or IsSecret(pName) or pName == "" then pName = "Котастрофа" end
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
