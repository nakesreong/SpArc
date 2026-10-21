---------------------------------------------------------------------------------------
--  SpArc/Evaluator.lua — Generic .MD FSM Condition Evaluator, Queue Builder & Events
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc

local CreateFrame = _G.CreateFrame
local GetTime = _G.GetTime
local UnitIsPlayer = _G.UnitIsPlayer
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

function SpArc:SyncSpellDefsFromProfile(parsed)
  if not parsed or not parsed.spells then return end
  local changed = false
  for k, spDef in pairs(parsed.spells) do
    if not SPELL_DEFS[k] then
      SPELL_DEFS[k] = spDef
      changed = true
    else
      local dst = SPELL_DEFS[k]
      if spDef.fillerInterruptible ~= nil then dst.fillerInterruptible = spDef.fillerInterruptible end
      if spDef.lockChannel ~= nil then dst.lockChannel = spDef.lockChannel end
      if spDef.insanityGain and spDef.insanityGain > 0 then dst.insanityGain = spDef.insanityGain end
      if spDef.insanityCost and spDef.insanityCost > 0 then dst.insanityCost = spDef.insanityCost end
    end
  end
  if changed then
    SpArc:ScanActionSlotsAndSpells(true)
  end
end

function SpArc:SelectActiveParsedProfile()
  local db = SpArc:EnsureDB()
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

  if _G.UnitClass then
    local okCls, _, playerClass = pcall(_G.UnitClass, "player")
    if okCls and not IsSecret(playerClass) and type(playerClass) == "string" then
      local curPreset = db.presets and db.presets[presetID]
      if not curPreset or curPreset.class ~= playerClass then
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
    end
  end

  local parsed = (SpArc.ParsedPresets and SpArc.ParsedPresets[presetID])
    or (SpArc.ParsedPresets and SpArc.ParsedPresets["PRIEST_01_SHADOW_PVE"])
  SpArc:SyncSpellDefsFromProfile(parsed)
  return parsed, presetID
end

function SpArc:EvalSingleCondition(condStr, simHasDoTs, simReady, simUsable, simProcs)
  if not condStr or condStr == "ALWAYS" then
    return true
  end
  local norm = condStr:gsub("%s+AND%s+", "\1")
  for rawClause in norm:gmatch("([^\1]+)") do
    local c = rawClause:gsub("^%s+", ""):gsub("%s+$", "")
    if c ~= "" then
      if c == "NOT target.has_dots" then
        if simHasDoTs then return false end
      elseif c == "target.has_dots" then
        if not simHasDoTs then return false end
      else
        local readySp = c:match("^READY%(([A-Z0-9_]+)%)$")
        if readySp then
          if not simReady[readySp] then return false end
        else
          local notReadySp = c:match("^NOT%s+READY%(([A-Z0-9_]+)%)$")
          if notReadySp then
            if simReady[notReadySp] then return false end
          else
            local usableSp = c:match("^USABLE%(([A-Z0-9_]+)%)$")
            if usableSp then
              if not simReady[usableSp] or not simUsable[usableSp] then return false end
            else
              local procSp = c:match("^PROC%(([A-Z0-9_]+)%)$")
              if procSp then
                local pKey = (procSp == "VOID_BLAST") and "MIND_BLAST" or procSp
                if not simProcs[pKey] then return false end
              end
            end
          end
        end
      end
    end
  end
  return true
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
    return {}, {}, parsed, nil, false, false
  end

  local states = {}
  local simReady = {}
  local simUsable = {}
  local simProcs = {}
  local simCharges = {}

  for k, _ in pairs(SPELL_DEFS) do
    local isReady, remSec, durSec, startTime, isUsable, isProc, icon, keybind, charges = SpArc:EvaluateSpellState(k, assistedKey)
    states[k] = {
      key = k,
      isReady = isReady,
      remSec = remSec,
      durSec = durSec,
      startTime = startTime,
      isUsable = isUsable,
      isProc = isProc,
      icon = icon,
      keybind = keybind,
      charges = charges,
    }
    simReady[k] = isReady
    simUsable[k] = isUsable
    simProcs[k] = isProc
    simCharges[k] = charges or (isReady and 1 or 0)
  end

  local queue = {}
  local simHasDoTs = SpArc:CheckTargetHasDoTs(assistedKey)
  if states["DEVOURING_PLAGUE"] and not states["DEVOURING_PLAGUE"].isUsable then
    st.trackedInsanity = math.min(st.trackedInsanity, 25)
  elseif states["DEVOURING_PLAGUE"] and states["DEVOURING_PLAGUE"].isUsable and st.trackedInsanity < 50 then
    st.trackedInsanity = 50
  end
  local simInsanity = st.trackedInsanity

  for step = 1, maxSlots do
    local pickedKey = nil
    for _, rule in ipairs(parsed.rules) do
      local sp = rule.spell
      if simReady[sp] and simUsable[sp] then
        if SpArc:EvalSingleCondition(rule.cond, simHasDoTs, simReady, simUsable, simProcs) then
          pickedKey = sp
          break
        end
      end
    end

    if pickedKey and states[pickedKey] then
      local s = states[pickedKey]
      local def = SPELL_DEFS[pickedKey]
      queue[#queue + 1] = {
        key = pickedKey,
        icon = s.icon,
        keybind = s.keybind,
        isProc = (step == 1 and s.isProc) or false,
      }

      simProcs[pickedKey] = false
      if def then
        if def.appliesDoTs then simHasDoTs = true end
        if def.insanityGain then simInsanity = math.min(100, simInsanity + def.insanityGain) end
        if def.insanityCost then simInsanity = math.max(0, simInsanity - def.insanityCost) end
        if def.procOnly or def.isSpender or def.isExecute then
          simReady[pickedKey] = false
          simUsable[pickedKey] = false
        elseif (def.liveMaxCharges or def.maxCharges or 1) > 1 then
          simCharges[pickedKey] = (simCharges[pickedKey] or 1) - 1
          if simCharges[pickedKey] <= 0 or (def.baseCD and def.baseCD > 1.6) then
            simReady[pickedKey] = false
          end
        elseif def.baseCD and def.baseCD > 0 then
          simReady[pickedKey] = false
        end
      end
      for spK, spD in pairs(SPELL_DEFS) do
        if spD.isSpender and spD.insanityCost then
          local canAfford = simInsanity >= spD.insanityCost
          simUsable[spK] = canAfford
          if canAfford then
            simReady[spK] = true
          end
        end
      end
    end
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
  local maxCh = def.liveMaxCharges or def.maxCharges or 1
  if maxCh > 1 or defKey == "MIND_BLAST" or defKey == "TENTACLE_SLAM" then
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
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")

eventFrame:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
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

  if event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" or event == "UPDATE_MACROS" or event == "UPDATE_BINDINGS" or event == "SPELLS_CHANGED" then
    if event == "UPDATE_BINDINGS" and SpArc.ApplySmartBossTabBinding then
      SpArc:ApplySmartBossTabBinding()
    end
    SpArc:ScanActionSlotsAndSpells(true)
    return
  end

  if event == "PLAYER_TARGET_CHANGED" then
    local okG, guid = pcall(UnitGUID, "target")
    local newGUID = (okG and not IsSecret(guid) and guid) or nil
    if not newGUID or newGUID ~= st.lastTargetGUID then
      st.targetDoTsUntil = 0
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
    local dur = (defKey == "VOID_TORRENT") and 3.0 or 2.8
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
    if defKey and defKey ~= "VOID_TORRENT" and defKey ~= "MIND_FLAY" and defKey ~= "MIND_FLAY_INSANITY" then
      SpArc:RecordSpellCastSuccess(defKey, now)
    end
  end
end)
