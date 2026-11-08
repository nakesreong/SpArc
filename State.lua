---------------------------------------------------------------------------------------
--  SpArc/State.lua — Spell Cooldown, Charges, Proc, DoT & Usability Evaluator
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
--  @module State
--  @responsibility
--    1. Evaluates real-time spell readiness, cooldown remaining, charges, proc overlays,
--       resource usability, and range (`EvaluateSpellState`, `IsSpellOutOfRange`).
--    2. Provides the unified WeakAuras-style aura inspector (`GetUnitAuraState`, `GetPlayerAuraInfo`).
--    3. Evaluates `.MD` rule conditions (`IsRuleConditionMet`).
--  @contract
--    - `SpArc:EvaluateSpellState(defKey)` returns 13 values:
--      `(finalReady, remSec, durSec, startTime, isUsable, isProc, icon, keybind, charges, isUnavailable, isNoResource, resWaitSec, isOutOfRange)`
--  @techdebt [AUDIT-ST1..ST4]
--    - [AUDIT-ST1] `st.trackedInsanity` is overloaded across `State.lua`, `Evaluator.lua`, `ResourceBar.lua`, and `Telemetry.lua`
--      to store Priest Insanity (0..100), Balance Astral Power (0..100), AND Rogue/Feral Combo Points scaled by *20 (`cp * 20`).
--      Planned Refactor (Phase 2): Replace with a unified `SpArc:GetClassResourceState()` descriptor (`VALUE_0_100` vs `COMBO_POINTS`).
--    - [AUDIT-ST2] `SpArc.DEFAULT_ENERGY_COST` (lines 905–932), `CLASS_RANGE_FALLBACK_SPELLS`, and hardcoded spell checks
--      (`isVoidBlastOverride`, `AMBUSH`, `15473` Shadowform, `MOONKIN_FORM`/`CAT_FORM`/`BEAR_FORM`) live inside the generic engine.
--      Planned Refactor (Phase 2): Move class metadata into declarative `.MD` attributes or a `ClassMetadata.lua` table.
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc

local GetTime = _G.GetTime
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitPower = _G.UnitPower
local GetActionInfo = _G.GetActionInfo
local GetActionCooldown = _G.GetActionCooldown
local IsUsableAction = _G.IsUsableAction
local C_Spell = _G.C_Spell
local C_UnitAuras = _G.C_UnitAuras
local pcall = _G.pcall
local ipairs = _G.ipairs
local pairs = _G.pairs
local tostring = _G.tostring
local type = _G.type
local math = _G.math
local string = _G.string

local IsSecret = SpArc.IsSecret
local SafeBool = SpArc.SafeBool
local SPELL_DEFS = SpArc.SPELL_DEFS
local st = SpArc.state

function SpArc:GetPlayerSpellHasteMult()
  if _G.UnitSpellHaste then
    local ok, h = pcall(_G.UnitSpellHaste, "player")
    if ok and not IsSecret(h) and type(h) == "number" and h > -90 and h < 500 then
      return math.max(0.5, 1.0 + (h / 100.0))
    end
  end
  return 1.0
end

function SpArc:GetPlayerGCDDuration()
  local mult = SpArc:GetPlayerSpellHasteMult()
  return math.max(0.75, math.min(1.5, 1.5 / mult))
end

local function ReadLiveGCD(now)
  if C_Spell and C_Spell.GetSpellCooldown then
    local ok, cd = pcall(C_Spell.GetSpellCooldown, 61304)
    if ok and type(cd) == "table" and not IsSecret(cd.startTime) and not IsSecret(cd.duration) then
      if type(cd.startTime) == "number" and cd.startTime > 0 and type(cd.duration) == "number" and cd.duration >= 0.25 and cd.duration <= 2.0 then
        if (cd.startTime + cd.duration) > now then
          st.gcdStartTime = cd.startTime
          st.gcdDuration = cd.duration
          return cd.startTime, cd.duration
        end
      end
    end
  end
  return nil, nil
end

function SpArc:TriggerGCD(now)
  now = now or GetTime()
  if ReadLiveGCD(now) then
    return
  end
  if (now - (st.gcdStartTime or 0)) > 0.12 then
    st.gcdStartTime = now
    st.gcdDuration = SpArc:GetPlayerGCDDuration()
  end
end

function SpArc:GetActiveGCD(now)
  now = now or GetTime()
  local liveS, liveD = ReadLiveGCD(now)
  if liveS and liveD then
    return liveS, liveD
  end
  local s = st.gcdStartTime or 0
  local d = st.gcdDuration or 0
  if s > 0 and d > 0.1 and (s + d) > now then
    return s, d
  end
  return 0, 0
end

function SpArc:GetTrackedSpellCharges(defKey, now)
  local def = SPELL_DEFS[defKey]
  local maxCh = (def and (def.liveMaxCharges or def.maxCharges)) or 1
  local rawCD = (def and def.liveChargeCD) or nil
  if not rawCD and def and def.baseCD and def.baseCD > 0 then
    if def.hastedCD then
      rawCD = def.baseCD / SpArc:GetPlayerSpellHasteMult()
    else
      rawCD = def.baseCD
    end
  end
  local cdDur = rawCD or 7.5
  if cdDur <= 0 then cdDur = 7.5 end
  local used = st.spellChargesUsed[defKey] or 0
  local chStart = st.spellChargeStart[defKey] or 0
  if used > 0 and (not chStart or chStart <= 0) then
    chStart = now
    st.spellChargeStart[defKey] = now
  end
  if used > 0 and chStart > 0 then
    local elapsed = now - chStart
    local recovered = math.floor((elapsed + 0.05) / cdDur)
    if recovered > 0 then
      used = math.max(0, used - recovered)
      st.spellChargesUsed[defKey] = used
      st.spellChargeStart[defKey] = used > 0 and (chStart + recovered * cdDur) or 0
    end
  end
  return math.max(0, maxCh - used), maxCh, cdDur, (st.spellChargeStart[defKey] or 0)
end

function SpArc:GetTargetHPPercent()
  if UnitHealth and UnitHealthMax then
    local ok1, hp = pcall(UnitHealth, "target")
    local ok2, maxHp = pcall(UnitHealthMax, "target")
    if ok1 and ok2 and not IsSecret(hp) and not IsSecret(maxHp) and type(hp) == "number" and type(maxHp) == "number" and maxHp > 0 then
      return (hp / maxHp) * 100
    end
  end
  return nil
end

local function ResolveUnitCastTuple(isChannel, uEv, now, name, texture, startTimeMS, endTimeMS, notInterruptible, spellID)
  local isInt = false
  local rawNotInt = notInterruptible
  if not IsSecret(notInterruptible) and type(notInterruptible) == "boolean" then
    isInt = not notInterruptible
    rawNotInt = notInterruptible
  elseif uEv and uEv.active and uEv.interruptible ~= nil then
    isInt = uEv.interruptible
    rawNotInt = not isInt
  elseif _G.C_CurveUtil and _G.C_CurveUtil.EvaluateColorValueFromBoolean and notInterruptible ~= nil then
    local okEv, evVal = pcall(_G.C_CurveUtil.EvaluateColorValueFromBoolean, notInterruptible, 1, 0)
    if okEv and not IsSecret(evVal) and type(evVal) == "number" then
      isInt = (evVal < 0.5)
      rawNotInt = not isInt
    end
  end
  local sSec = (not IsSecret(startTimeMS) and type(startTimeMS) == "number" and (startTimeMS / 1000.0)) or (uEv and uEv.startTime) or now
  local eSec = (not IsSecret(endTimeMS) and type(endTimeMS) == "number" and (endTimeMS / 1000.0)) or (uEv and uEv.endTime) or (sSec + (isChannel and 3.0 or 2.0))
  local durSec = math.max(0.1, eSec - sSec)
  local remSec = math.max(0, eSec - now)
  local cleanName = (not IsSecret(name) and type(name) == "string" and name) or (uEv and uEv.name) or (isChannel and "Channel" or "Cast")
  local cleanIcon = (not IsSecret(texture) and texture) or (uEv and uEv.icon) or 136243
  local cleanID = (not IsSecret(spellID) and type(spellID) == "number" and spellID) or (uEv and uEv.spellID) or nil
  return true, isInt, isChannel, cleanName, cleanIcon, remSec, durSec, cleanID, rawNotInt
end

-- Returns: isCasting, isInterruptible, isChannel, spellName, spellIcon, remSec, durSec, spellID, rawNotInterruptible
function SpArc:GetUnitCastInterruptState(unit, now)
  unit = unit or "target"
  now = now or GetTime()
  st.unitCastState = st.unitCastState or {}
  local uEv = st.unitCastState[unit]

  if _G.UnitExists and not SafeBool(_G.UnitExists, unit) then
    if uEv then uEv.active = false end
    return false, false, false, nil, nil, 0, 0, nil, nil
  end
  if _G.UnitIsDeadOrGhost and SafeBool(_G.UnitIsDeadOrGhost, unit) then
    if uEv then uEv.active = false end
    return false, false, false, nil, nil, 0, 0, nil, nil
  end

  -- 1. Check regular cast via UnitCastingInfo (8th return = notInterruptible)
  if _G.UnitCastingInfo then
    local ok, name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible, spellID = pcall(_G.UnitCastingInfo, unit)
    if ok and name ~= nil then
      return ResolveUnitCastTuple(false, uEv, now, name, texture, startTimeMS, endTimeMS, notInterruptible, spellID)
    end
  end

  -- 2. Check channel / empowered cast via UnitChannelInfo (7th return = notInterruptible)
  if _G.UnitChannelInfo then
    local ok, name, _, texture, startTimeMS, endTimeMS, _, notInterruptible, spellID = pcall(_G.UnitChannelInfo, unit)
    if ok and name ~= nil then
      return ResolveUnitCastTuple(true, uEv, now, name, texture, startTimeMS, endTimeMS, notInterruptible, spellID)
    end
  end

  -- 3. Fallback to event-tracked cast window if UnitCastingInfo returned nil/secret during active window
  if uEv and uEv.active and uEv.endTime and now < uEv.endTime then
    local durSec = math.max(0.1, uEv.endTime - (uEv.startTime or now))
    local remSec = math.max(0, uEv.endTime - now)
    local evInt = (uEv.interruptible == true)
    return true, evInt, (uEv.isChannel or false), (uEv.name or "Cast"), (uEv.icon or 136243), remSec, durSec, uEv.spellID, (uEv.interruptible ~= nil and not uEv.interruptible or nil)
  end

  return false, false, false, nil, nil, 0, 0, nil, nil
end

local function FormatSecretOrVal(v)
  if IsSecret(v) then return "SECRET" end
  return tostring(v)
end

local function FindMatchingOverrideID(baseID, candidateIDs)
  if not (baseID and candidateIDs and C_Spell and C_Spell.GetOverrideSpell) then
    return nil
  end
  local okO, over = pcall(C_Spell.GetOverrideSpell, baseID)
  if okO and not IsSecret(over) and type(over) == "number" and over > 0 and over ~= baseID then
    for _, myID in ipairs(candidateIDs) do
      if over == myID then
        return over
      end
    end
  end
  return nil
end

-- Spells whose AURA_ID on `player` represents a proc buff they CONSUME (rather than a self-buff they apply on cast)
SpArc.PROC_CONSUMER_AURA_SPELLS = {
  REGROWTH            = true,
  VIVIFY              = true,
  SPINNING_CRANE_KICK = true,
  BLACKOUT_KICK       = true,
  FEROCIOUS_BITE      = true,
}

local function EvaluateSpenderPowerUsability(defKey, def, isProc, hasSpellOverlayProc, assistedKey, gotCleanUsable, isUsable, usableSource)
  if not UnitPower then
    return gotCleanUsable, isUsable, isProc, usableSource
  end
  if defKey == "DEVOURING_PLAGUE" or SPELL_DEFS["DEVOURING_PLAGUE"] then
    local cost = (def.insanityCost and def.insanityCost > 0) and def.insanityCost or 50
    local okP, rawP = pcall(UnitPower, "player", 13)
    if okP and not IsSecret(rawP) and type(rawP) == "number" then
      if rawP < (cost - 5) and not isProc and assistedKey ~= defKey then
        return true, false, isProc, "UnitPower(" .. tostring(rawP) .. "<" .. tostring(cost - 5) .. ")"
      elseif rawP >= cost and not gotCleanUsable then
        return true, true, isProc, "UnitPower(" .. tostring(rawP) .. ">=" .. tostring(cost) .. ")"
      end
    end
    return gotCleanUsable, isUsable, isProc, usableSource
  end

  local isAstral = (defKey == "STARSURGE" or defKey == "STARFALL" or SPELL_DEFS["STARSURGE"] ~= nil or SPELL_DEFS["STARFALL"] ~= nil)
  local isChi = (not isAstral) and (SPELL_DEFS["RISING_SUN_KICK"] ~= nil or SPELL_DEFS["TIGER_PALM"] ~= nil or SPELL_DEFS["BLACKOUT_KICK"] ~= nil)
  local isFocus = (not isAstral) and (not isChi) and (
    SPELL_DEFS["KILL_COMMAND"] ~= nil
    or SPELL_DEFS["MONGOOSE_BITE"] ~= nil
    or SPELL_DEFS["WILDFIRE_BOMB"] ~= nil
    or (st.activeParsed and st.activeParsed.class == "HUNTER")
  )
  if isFocus then
    local cost = (def.insanityCost and def.insanityCost > 0) and def.insanityCost or 30
    local okF, rawF = pcall(UnitPower, "player", 2)
    if okF and not IsSecret(rawF) and type(rawF) == "number" then
      st.trackedInsanity = math.min(100, rawF)
      st.lastFocusUpdateAt = GetTime()
      if rawF < (cost - 5) and not isProc and assistedKey ~= defKey then
        return true, false, false, "Focus(" .. tostring(rawF) .. "<" .. tostring(cost) .. ")"
      end
      return true, true, isProc, "Focus(" .. tostring(rawF) .. ">=" .. tostring(cost) .. ")"
    end
    -- In WoW 12.x, UnitPower("player", 2) is secret, while C_Spell.IsSpellUsable / IsUsableAction
    -- returns a non-secret boolean that directly reflects whether the Hunter has >= 30 Focus!
    if gotCleanUsable then
      if isUsable then
        if (st.trackedInsanity or 0) < cost then
          st.trackedInsanity = math.max(cost, 60)
        end
      else
        if (st.trackedInsanity or 0) >= cost then
          st.trackedInsanity = math.max(0, cost - 10)
        end
      end
      return gotCleanUsable, isUsable, isProc, usableSource
    end
    local trackedF = st.trackedInsanity or 100
    if trackedF >= cost or isProc or assistedKey == defKey then
      return true, true, isProc, "TrackedFocus(" .. tostring(math.floor(trackedF)) .. ">=" .. tostring(cost) .. ")"
    end
    return true, false, isProc, "TrackedFocus(" .. tostring(math.floor(trackedF)) .. "<" .. tostring(cost) .. ")"
  end

  local powerType = isAstral and 8 or (isChi and 12 or 4)
  local defaultCost = isAstral and 40 or (isChi and 40 or 80)
  local cost = (def.insanityCost and def.insanityCost > 0) and def.insanityCost or defaultCost
  local minRaw = isAstral and (cost - 5) or math.max(1, math.floor(cost / 20))
  local freeOverlayAllowed = (isAstral and (hasSpellOverlayProc or isProc))
    or ((hasSpellOverlayProc or isProc) and (defKey == "FEROCIOUS_BITE" or defKey == "BLACKOUT_KICK" or defKey == "SPINNING_CRANE_KICK"))
  local tagName = isAstral and "AstralPower" or (isChi and "Chi" or "ComboPoints")
  local trackedTag = isAstral and "TrackedAP" or (isChi and "TrackedChi" or "TrackedCP")

  local okP, rawP = pcall(UnitPower, "player", powerType)
  if okP and not IsSecret(rawP) and type(rawP) == "number" then
    if rawP < minRaw then
      if freeOverlayAllowed then
        local procTag = isAstral and ("ProcOverlayFreeAstral(" .. tostring(rawP) .. "AP)")
          or (isChi and ("ProcOverlayFreeChi(" .. tostring(rawP) .. "Chi)") or ("ProcOverlayFreeSpender(" .. tostring(rawP) .. "CP)"))
        return true, true, true, procTag
      end
      return true, false, false, tagName .. "(" .. tostring(rawP) .. "<" .. tostring(isAstral and cost or minRaw) .. ")"
    end
    return true, true, isProc, tagName .. "(" .. tostring(rawP) .. ">=" .. tostring(isAstral and cost or minRaw) .. ")"
  end

  local trackedVal = st.trackedInsanity or 0
  if trackedVal >= cost or isProc or (isAstral and hasSpellOverlayProc) or assistedKey == defKey then
    return true, true, isProc, trackedTag .. "(" .. tostring(trackedVal) .. ">=" .. tostring(cost) .. ")"
  end
  return true, false, isProc, trackedTag .. "(" .. tostring(trackedVal) .. "<" .. tostring(cost) .. ")"
end

function SpArc:EvaluateSpellState(defKey, assistedKey)
  local def = SPELL_DEFS[defKey]
  if not def then
    return false, 0, 0, 0, false, false, 134400, "", 0
  end
  local now = GetTime()
  local spellID = def.liveSpellID or (def.ids and def.ids[1])
  local slot = def.slot

  local isProc = false
  local isVoidBlastOverride = false
  local overlayRaw = "false"
  if C_Spell and C_Spell.IsSpellOverlayed then
    for _, id in ipairs(def.ids or {}) do
      local okP, over = pcall(C_Spell.IsSpellOverlayed, id)
      if okP then
        if IsSecret(over) then
          overlayRaw = "SECRET"
        elseif over then
          isProc = true
          overlayRaw = "true(" .. tostring(id) .. ")"
          break
        end
      end
    end
    if not isProc and spellID then
      local okP, over = pcall(C_Spell.IsSpellOverlayed, spellID)
      if okP then
        if IsSecret(over) then
          overlayRaw = "SECRET"
        elseif over then
          isProc = true
          overlayRaw = "true(" .. tostring(spellID) .. ")"
        end
      end
    end
  end
  if not isProc and _G.C_SpellActivationOverlay and _G.C_SpellActivationOverlay.IsSpellOverlayed and spellID then
    local okS, overS = pcall(_G.C_SpellActivationOverlay.IsSpellOverlayed, spellID)
    if okS and not IsSecret(overS) and overS then
      isProc = true
      overlayRaw = "sao(" .. tostring(spellID) .. ")"
    end
  end
  if not isProc and (SpArc.PROC_CONSUMER_AURA_SPELLS[defKey] or def.procOnly) and def.auraUnit == "player" and (not def.burstDuration or def.burstDuration <= 0) and def.auraIDs and #def.auraIDs > 0 and def.auraIDs[1] ~= spellID and SpArc.GetUnitAuraState then
    local aActive = SpArc:GetUnitAuraState("player", defKey, st.activeParsed, assistedKey, now)
    if aActive then
      isProc = true
      overlayRaw = "auraProc(" .. tostring(defKey) .. ")"
    end
  end
  local hasSpellOverlayProc = isProc
  local overrideActive = false
  if def.ids and #def.ids > 1 then
    for i = 2, #def.ids do
      local over = FindMatchingOverrideID(def.ids[i], def.ids)
      if over then
        isVoidBlastOverride = true
        spellID = over
        overlayRaw = "override(" .. tostring(over) .. ")"
        if not hasSpellOverlayProc and _G.C_SpellActivationOverlay and _G.C_SpellActivationOverlay.IsSpellOverlayed then
          local okS2, overS2 = pcall(_G.C_SpellActivationOverlay.IsSpellOverlayed, over)
          if okS2 and not IsSecret(overS2) and overS2 then
            hasSpellOverlayProc = true
            isProc = true
            overlayRaw = "sao(" .. tostring(over) .. ")"
          end
        end
        break
      end
    end
  end
  st.lastOverlayProcAt = st.lastOverlayProcAt or {}
  if hasSpellOverlayProc then
    st.lastOverlayProcAt[defKey] = now
  end
  if def.overrideOf and SPELL_DEFS[def.overrideOf] then
    local baseDef = SPELL_DEFS[def.overrideOf]
    for _, baseID in ipairs(baseDef.ids or {}) do
      local over = FindMatchingOverrideID(baseID, def.ids)
      if over then
        overrideActive = true
        isProc = true
        spellID = over
        overlayRaw = "override(" .. tostring(over) .. ")"
        break
      end
    end
    if not overrideActive and baseDef.liveSpellID then
      local over = FindMatchingOverrideID(baseDef.liveSpellID, def.ids)
      if over then
        overrideActive = true
        isProc = true
        spellID = over
        overlayRaw = "override(" .. tostring(over) .. ")"
      end
    end
    if def.inheritedBaseSlot and not overrideActive and not hasSpellOverlayProc then
      isProc = false
    elseif assistedKey == defKey then
      isProc = true
      overlayRaw = "assisted(" .. tostring(defKey) .. ")"
    end
  end

  local isOnCD = false
  local remSec = 0
  local durSec = def.baseCD or 0
  local startTime = 0
  local gotCleanCD = false
  local charges = def.liveMaxCharges or def.maxCharges or 1
  local cdRaw = "0s"
  local chargesRaw = "-"

  if C_Spell and C_Spell.GetSpellCharges and spellID then
    local okC, ch = pcall(C_Spell.GetSpellCharges, spellID)
    if (not okC or type(ch) ~= "table" or (not IsSecret(ch.maxCharges) and (tonumber(ch.maxCharges) or 0) < 2)) and isVoidBlastOverride and def.liveSpellID and def.liveSpellID ~= spellID then
      local okBaseC, baseCh = pcall(C_Spell.GetSpellCharges, def.liveSpellID)
      if okBaseC and type(baseCh) == "table" then
        ch = baseCh
        okC = true
      end
    end
    if okC and type(ch) == "table" then
      if not IsSecret(ch.maxCharges) and type(ch.maxCharges) == "number" and ch.maxCharges >= 1 then
        local effectiveMax = ch.maxCharges
        local prevMax = def.liveMaxCharges or def.maxCharges or 1
        if effectiveMax ~= prevMax then
          if IsSecret(ch.currentCharges) and effectiveMax < prevMax then
            local used = st.spellChargesUsed[defKey] or 0
            st.spellChargesUsed[defKey] = math.min(effectiveMax, used)
          end
          def.liveMaxCharges = effectiveMax
        end
      end
      if not IsSecret(ch.cooldownDuration) and type(ch.cooldownDuration) == "number" and ch.cooldownDuration > 1.5 then
        def.liveChargeCD = ch.cooldownDuration
      end
      if IsSecret(ch.currentCharges) then
        chargesRaw = "SECRET"
      elseif ch.currentCharges then
        gotCleanCD = true
        charges = ch.currentCharges
        local maxCh = def.liveMaxCharges or def.maxCharges or 1
        local chCDDur = def.liveChargeCD or def.baseCD or 7.5
        chargesRaw = tostring(ch.currentCharges) .. "/" .. tostring(maxCh)
        local prevUsed = st.spellChargesUsed[defKey] or 0
        local newUsed = math.max(0, maxCh - ch.currentCharges)
        st.spellChargesUsed[defKey] = newUsed
        if newUsed == 0 then
          st.spellChargeStart[defKey] = 0
          if st.lastCastAt[defKey] and (now - st.lastCastAt[defKey]) > 1.6 then
            st.lastCastAt[defKey] = nil
          end
        elseif not IsSecret(ch.cooldownStartTime) and type(ch.cooldownStartTime) == "number" and ch.cooldownStartTime > 0 then
          st.spellChargeStart[defKey] = ch.cooldownStartTime
        elseif (st.spellChargeStart[defKey] or 0) <= 0 or newUsed > prevUsed or (now - (st.spellChargeStart[defKey] or 0)) >= chCDDur then
          st.spellChargeStart[defKey] = now
        end
        if ch.currentCharges >= 1 then
          isOnCD = false
        else
          isOnCD = true
          if not IsSecret(ch.cooldownStartTime) and not IsSecret(ch.cooldownDuration) and type(ch.cooldownStartTime) == "number" and ch.cooldownStartTime > 0 then
            startTime = ch.cooldownStartTime
            durSec = ch.cooldownDuration or chCDDur
            remSec = math.max(0, startTime + durSec - now)
            cdRaw = string.format("%.1fs/%.1fs", remSec, durSec)
          else
            startTime = (st.spellChargeStart[defKey] and st.spellChargeStart[defKey] > 0) and st.spellChargeStart[defKey] or now
            durSec = chCDDur
            remSec = math.max(0, startTime + durSec - now)
            cdRaw = string.format("%.1fs/%.1fs", remSec, durSec)
          end
        end
      end
    end
  end

  -- Resolve active spell on the assigned action slot FIRST so multi-spell/conditional macros
  -- (e.g. 1_to_2 switching between Power Infusion, Void Eruption, and Mind Blast across Bar 1/2)
  -- never contaminate one spell's cooldown with another spell's action slot cooldown!
  local slotActiveSpellID = nil
  local isBonusBarActive = _G.HasBonusActionBar and SafeBool(_G.HasBonusActionBar) or false
  local useSlotActionState = slot and (not (isBonusBarActive and slot <= 12))
  if useSlotActionState then
    local btBtn = _G["BT4Button" .. slot]
    if btBtn and btBtn.GetSpellId then
      local okBS, btSID = pcall(btBtn.GetSpellId, btBtn)
      if okBS and not IsSecret(btSID) and type(btSID) == "number" and btSID > 0 then
        slotActiveSpellID = btSID
      end
    end
    if not slotActiveSpellID and GetActionInfo then
      local okAI, aType, aID, aSub = pcall(GetActionInfo, slot)
      if okAI and not IsSecret(aID) and type(aID) == "number" and aID > 0 then
        if aType == "spell" or aSub == "spell" then
          slotActiveSpellID = aID
        elseif aType == "macro" and _G.GetMacroSpell then
          local okMS, msID = pcall(_G.GetMacroSpell, aID)
          if okMS and not IsSecret(msID) and type(msID) == "number" and msID > 0 then
            slotActiveSpellID = msID
          end
        end
      end
    end
  end
  local slotMatchesDef = useSlotActionState and ((not slotActiveSpellID and (def.slotCastLineCount or 0) <= 1) or (slotActiveSpellID and def.idSet and def.idSet[slotActiveSpellID] == true)) or false

  st.knownCDStart = st.knownCDStart or {}
  st.knownCDDur = st.knownCDDur or {}
  local db = SpArc:EnsureDB()
  db.runtimeCDs = db.runtimeCDs or {}

  local function SaveKnownCD(sTime, dTime)
    st.knownCDStart[defKey] = sTime
    st.knownCDDur[defKey] = dTime
    db.runtimeCDs[defKey] = { s = sTime, d = dTime }
  end

  local function ClearKnownCD()
    st.knownCDStart[defKey] = nil
    st.knownCDDur[defKey] = nil
    db.runtimeCDs[defKey] = nil
    if st.lastCastAt[defKey] and (now - st.lastCastAt[defKey]) > 1.6 then
      st.lastCastAt[defKey] = nil
    end
  end

  if not gotCleanCD and C_Spell and C_Spell.GetSpellCooldown and spellID then
    local okCD, cd = pcall(C_Spell.GetSpellCooldown, spellID)
    if okCD and type(cd) == "table" then
      if IsSecret(cd.duration) or IsSecret(cd.startTime) then
        cdRaw = "SECRET"
      else
        gotCleanCD = true
        if cd.duration and cd.startTime and cd.startTime > 0 then
          if cd.duration >= 0.25 and cd.duration <= 1.6 and (cd.startTime + cd.duration) > now then
            st.gcdStartTime = cd.startTime
            st.gcdDuration = cd.duration
            ClearKnownCD()
          elseif cd.duration > 1.6 then
            local r = cd.startTime + cd.duration - now
            if r > 0.15 then
              isOnCD = true
              remSec = r
              durSec = cd.duration
              startTime = cd.startTime
              charges = 0
              cdRaw = string.format("%.1fs/%.1fs", remSec, durSec)
              SaveKnownCD(cd.startTime, cd.duration)
            else
              ClearKnownCD()
            end
          else
            ClearKnownCD()
          end
        else
          ClearKnownCD()
        end
      end
    end
  end

  if not gotCleanCD and slot and slotMatchesDef and GetActionCooldown then
    local okA, s, d = pcall(GetActionCooldown, slot)
    if okA then
      if IsSecret(s) or IsSecret(d) then
        if cdRaw == "0s" then cdRaw = "ACT_SECRET" end
      elseif type(d) == "number" then
        if s and s > 0 and d > 1.6 then
          local r = s + d - now
          if r > 0.15 then
            gotCleanCD = true
            isOnCD = true
            remSec = r
            durSec = d
            startTime = s
            charges = 0
            cdRaw = string.format("act:%.1fs/%.1fs", remSec, durSec)
            SaveKnownCD(s, d)
          elseif cdRaw ~= "SECRET" then
            gotCleanCD = true
            ClearKnownCD()
          end
        elseif s and s > 0 and d >= 0.25 and d <= 1.6 and (s + d) > now then
          st.gcdStartTime = s
          st.gcdDuration = d
          if cdRaw ~= "SECRET" then
            gotCleanCD = true
            ClearKnownCD()
          end
        elseif cdRaw ~= "SECRET" then
          -- Never trust a 0s macro cooldown when C_Spell.GetSpellCooldown returned SECRET in combat
          -- (e.g., [@target] macros return 0,0 when the target dies, which would wipe active CDs)
          gotCleanCD = true
          ClearKnownCD()
        end
      end
    end
  end

  if not gotCleanCD then
    local maxCh = def.liveMaxCharges or def.maxCharges or 1
    local cdDur = (def and (def.liveChargeCD or def.baseCD)) or 7.5
    if cdDur <= 0 then cdDur = 7.5 end

    if maxCh > 1 then
      local simCh, simMax, simDur, simStart = SpArc:GetTrackedSpellCharges(defKey, now)
      cdDur = simDur
      charges = simCh
      chargesRaw = "sim:" .. tostring(simCh) .. "/" .. tostring(simMax)
      if simCh <= 0 then
        isOnCD = true
        startTime = simStart
        durSec = simDur
        remSec = math.max(0, simStart + simDur - now)
        cdRaw = string.format("sim:%.1fs", remSec)
      end
    else
      local kStart = st.knownCDStart[defKey]
      local kDur = st.knownCDDur[defKey]
      if (not kStart or not kDur) and db.runtimeCDs and db.runtimeCDs[defKey] then
        local saved = db.runtimeCDs[defKey]
        if type(saved) == "table" and saved.s and saved.d and saved.s <= now and (saved.s + saved.d) > now then
          kStart = saved.s
          kDur = saved.d
          st.knownCDStart[defKey] = kStart
          st.knownCDDur[defKey] = kDur
        else
          db.runtimeCDs[defKey] = nil
        end
      end

      local bestRem = 0
      local bestDur = 0
      local bestStart = 0
      local bestTag = "timer"

      if kStart and kDur and kDur > 1.6 and kStart <= (now + 0.5) then
        local rK = (kStart + kDur) - now
        if rK > 0.15 and rK <= (kDur + 5) then
          bestRem = rK
          bestDur = kDur
          bestStart = kStart
          bestTag = "cached"
        else
          ClearKnownCD()
        end
      end

      local last = st.lastCastAt[defKey]
      local effCD = def.liveChargeCD or def.baseCD or 0
      if not def.liveChargeCD and def.hastedCD and effCD > 0 then
        effCD = effCD / SpArc:GetPlayerSpellHasteMult()
      end
      if bestRem <= 0 and last and effCD > 1.6 then
        local elapsed = now - last
        if elapsed >= 0 and elapsed < (effCD - 0.15) then
          local rCast = effCD - elapsed
          if rCast > bestRem then
            bestRem = rCast
            bestDur = effCD
            bestStart = last
            bestTag = "timer"
          end
        end
      end

      if bestRem > 0.15 then
        isOnCD = true
        remSec = bestRem
        durSec = bestDur
        startTime = bestStart
        charges = 0
        cdRaw = string.format("%s:%.1fs", bestTag, remSec)
      end
    end

    -- Non-destructive readiness override when C++ AssistedCombat or a non-execute proc overlay
    -- proves a spell is castable right now (never wipe underlying timers, and never let execute
    -- <20% HP overlays bypass an active execute cooldown like Shadow Word: Death)
    local sinceLastCast = now - (st.lastCastAt[defKey] or 0)
    local allowProcCDReset = (not def.isExecute) and ((def.baseCD or 0) < 25) and (not def.isBossSkill) and hasSpellOverlayProc and (sinceLastCast > 0.35)
    local allowAssistCDReset = (assistedKey == defKey) and ((def.baseCD or 0) < 25) and (sinceLastCast > 1.4)
    if isOnCD and (allowProcCDReset or allowAssistCDReset) then
      isOnCD = false
      remSec = 0
      charges = math.max(1, charges)
      if (def.baseCD or 0) <= 25 and not (def.burstDuration and def.burstDuration > 0) and not def.isBossSkill then
        ClearKnownCD()
        if maxCh > 1 and (st.spellChargesUsed[defKey] or 0) >= maxCh then
          st.spellChargesUsed[defKey] = math.max(0, maxCh - 1)
        end
      end
      if maxCh > 1 then
        chargesRaw = "sim:" .. tostring(charges) .. "/" .. tostring(maxCh)
      end
      cdRaw = allowProcCDReset and "proc:0s" or "assist:0s"
    end
  end

  if isOnCD and remSec > 0 and durSec > 0 and (not startTime or startTime <= 0) then
    startTime = now - math.max(0, durSec - remSec)
  end

  if isOnCD then
    isProc = false
  elseif isVoidBlastOverride then
    isProc = true
  end

  local bookUsableRaw = "n/a"
  local actUsableRaw = "n/a"
  local btColorRaw = "n/a"
  local usableSource = "default(true)"

  local bookUsableVal, bookNoPowerVal = nil, nil
  if def.isKnown and C_Spell and C_Spell.IsSpellUsable and spellID then
    local okU, u, noP = pcall(C_Spell.IsSpellUsable, spellID)
    if okU then
      bookUsableRaw = FormatSecretOrVal(u) .. "/noP=" .. FormatSecretOrVal(noP)
      if not IsSecret(u) and type(u) == "boolean" then
        bookUsableVal = u
        bookNoPowerVal = (not IsSecret(noP) and noP == true) or false
      end
    end
  end

  local actUsableVal, actNoManaVal = nil, nil
  if useSlotActionState then
    local btBtn = _G["BT4Button" .. slot]
    if slotMatchesDef and IsUsableAction then
      local okA, u, noM = pcall(IsUsableAction, slot)
      if okA then
        actUsableRaw = FormatSecretOrVal(u) .. "/noM=" .. FormatSecretOrVal(noM) .. (slotActiveSpellID and ("(id:" .. slotActiveSpellID .. ")") or "")
        if not IsSecret(u) and type(u) == "boolean" then
          actUsableVal = u
          actNoManaVal = (not IsSecret(noM) and noM == true) or false
        end
      end
    end
    if slotMatchesDef and btBtn and btBtn.icon and btBtn.icon.GetVertexColor then
      local okV, r, g, b = pcall(btBtn.icon.GetVertexColor, btBtn.icon)
      if okV and not IsSecret(r) and not IsSecret(g) and not IsSecret(b) and type(r) == "number" then
        btColorRaw = string.format("%.2f,%.2f,%.2f", r, g or 1, b or 1)
      end
    end
  end

  local isUsable = true
  local blockedBySpellBookState = (bookUsableVal == false and not bookNoPowerVal)
  if def.isExecute then
    local tgtHP = SpArc:GetTargetHPPercent()
    local hasCD = (def.baseCD and def.baseCD >= 3.0) and true or false
    local alwaysCastableExecute = (defKey == "SHADOW_WORD_DEATH" or spellID == 32379)
    if blockedBySpellBookState then
      isUsable = false
      isProc = false
      usableSource = "ExecuteSpellBook(false)"
    elseif bookUsableVal == true and not bookNoPowerVal then
      isUsable = true
      usableSource = isProc and "ExecuteProcOverlay" or "ExecuteSpellBook(true)"
    elseif isProc then
      isUsable = true
      usableSource = "ExecuteProcOverlay"
    elseif assistedKey == defKey then
      isUsable = true
      usableSource = "ExecuteAssistedCombat"
    elseif alwaysCastableExecute then
      if tgtHP and tgtHP <= 20 then
        isUsable = true
        usableSource = string.format("ExecuteHP(%.1f%%<=20%%)", tgtHP)
      else
        isUsable = false
        usableSource = "ExecuteWait(>20%HP)"
      end
    elseif bookUsableVal ~= nil then
      isUsable = (bookUsableVal == true) and (not bookNoPowerVal)
      usableSource = "ExecuteSpellBook(" .. tostring(isUsable) .. ")"
    elseif actUsableVal ~= nil then
      isUsable = (actUsableVal == true) and (not actNoManaVal)
      usableSource = "ExecuteActionBar(" .. tostring(isUsable) .. ")"
    elseif hasCD and tgtHP and tgtHP <= 20 then
      isUsable = true
      usableSource = string.format("ExecuteHP(%.1f%%<=20%%)", tgtHP)
    else
      isUsable = false
      usableSource = "ExecuteWait(>20%HP)"
    end
  elseif def.requiresUsable then
    local gotCleanUsable = false

    if bookUsableVal ~= nil then
      isUsable = (bookUsableVal == true) and (not bookNoPowerVal)
      gotCleanUsable = true
      usableSource = "SpellBook(" .. tostring(spellID) .. ")"
    end

    if not gotCleanUsable and actUsableVal ~= nil then
      local isFallbackMacroSpell = (slotActiveSpellID == 15473 or slotActiveSpellID == 528)
      if not isFallbackMacroSpell then
        isUsable = (actUsableVal == true) and (not actNoManaVal)
        gotCleanUsable = true
        usableSource = "ActionBar(slot:" .. tostring(slot) .. ")"
      else
        usableSource = "IgnoredMacroFallback(id:" .. tostring(slotActiveSpellID) .. ")"
      end
    end

    if def.isSpender and not blockedBySpellBookState and UnitPower then
      gotCleanUsable, isUsable, isProc, usableSource = EvaluateSpenderPowerUsability(defKey, def, isProc, hasSpellOverlayProc, assistedKey, gotCleanUsable, isUsable, usableSource)
    end

    if not gotCleanUsable then
      if def.isSpender then
        isUsable = (assistedKey == defKey) or isProc
        usableSource = "SecretFallback(AssistedOrProcOnly)"
      elseif not def.isKnown then
        isUsable = true
        usableSource = "ForeignClassSim(true)"
      else
        isUsable = false
        usableSource = "SecretFallback(false)"
      end
    end

    if not blockedBySpellBookState and (isProc or assistedKey == defKey) and not (def.isSpender and not SPELL_DEFS["DEVOURING_PLAGUE"] and gotCleanUsable and not isUsable) then
      isUsable = true
      usableSource = isProc and "ProcOverride" or "AssistedCombat"
    end
  elseif bookUsableVal ~= nil then
    isUsable = (bookUsableVal == true) and (not bookNoPowerVal)
    usableSource = "SpellBook(" .. tostring(spellID) .. ")"
    if blockedBySpellBookState then
      isProc = false
    elseif not isUsable and (isProc or assistedKey == defKey) then
      isUsable = true
      usableSource = isProc and "ProcOverride" or "AssistedCombat"
    end
  end

  local finalReady = (not isOnCD)
  local isKnownInBook = (def.isKnown == true) or (def.overrideOf and SPELL_DEFS[def.overrideOf] and SPELL_DEFS[def.overrideOf].isKnown == true) or false
  local pClass = nil
  if _G.UnitClass then
    local okC, _, cTag = pcall(_G.UnitClass, "player")
    if okC and not IsSecret(cTag) then pClass = cTag end
  end
  local isForeignClassTest = SpArc.testMode and st.activeParsed and st.activeParsed.class and pClass and (st.activeParsed.class ~= pClass)
  local isUnavailable = (not isForeignClassTest) and (not isKnownInBook)
  if isUnavailable then
    finalReady = false
    isUsable = false
    isProc = false
    usableSource = "NotInSpellBook"
  end

  if def.overrideOf and def.inheritedBaseSlot and slotActiveSpellID and def.idSet and def.idSet[slotActiveSpellID] then
    isProc = true
    isOnCD = false
    finalReady = true
    overlayRaw = "slotOverride(" .. tostring(slotActiveSpellID) .. ")"
  end

  if defKey == "AMBUSH" then
    if bookUsableVal == false and not bookNoPowerVal then
      isProc = false
      finalReady = false
      isUsable = false
      usableSource = "AmbushNotStealthedOrProc"
    end
  end

  if def.procOnly and not isProc then
    finalReady = false
    isUsable = false
    usableSource = "procOnly(false)"
  end

  local isNoResource = false
  local resWaitSec = 0
  local isPriestSpender = (defKey == "DEVOURING_PLAGUE") or (def.isSpender and SPELL_DEFS["DEVOURING_PLAGUE"] ~= nil)
  local isFreeProcSpender = (defKey == "FEROCIOUS_BITE" and isProc)
  if not isUnavailable and not isPriestSpender and not isFreeProcSpender then
    if bookNoPowerVal == true or (useSlotActionState and actNoManaVal == true) then
      isNoResource = true
      resWaitSec = 2.0
      if not usableSource:find("NoResource", 1, true) then
        usableSource = usableSource .. "+NoResource"
      end
    end
    local eCost = SpArc.DEFAULT_ENERGY_COST and SpArc.DEFAULT_ENERGY_COST[defKey]
    if isUsable and eCost and UnitPower then
      local okE, curE = pcall(UnitPower, "player", 3)
      if okE and not IsSecret(curE) and type(curE) == "number" then
        if curE < eCost then
          isNoResource = true
          local regen = 12.0
          if _G.GetPowerRegen then
            local okR, rVal = pcall(_G.GetPowerRegen)
            if okR and not IsSecret(rVal) and type(rVal) == "number" and rVal > 1 then
              regen = rVal
            end
          end
          resWaitSec = math.max(1.4, math.min(5.0, (eCost - curE) / regen))
          usableSource = string.format("NoEnergy(%d<%d,%.1fs)", curE, eCost, resWaitSec)
        elseif not bookNoPowerVal and not (useSlotActionState and actNoManaVal) then
          isNoResource = false
          resWaitSec = 0
        end
      end
    end
  end

  local slotMatchesForRange = useSlotActionState and ((not slotActiveSpellID) or (def.idSet and def.idSet[slotActiveSpellID]) or false)
  local isOutOfRange = false
  if not isUnavailable and SpArc.IsSpellOutOfRange then
    isOutOfRange = SpArc:IsSpellOutOfRange(defKey, def, spellID, slot, slotMatchesForRange)
  end

  local audit = st.lastSpellAudit[defKey]
  if not audit then
    audit = {}
    st.lastSpellAudit[defKey] = audit
  end
  audit.key = defKey
  audit.spellID = spellID
  audit.slot = slot
  audit.keybind = def.keybind or ""
  audit.bookUsableRaw = bookUsableRaw
  audit.actUsableRaw = actUsableRaw
  audit.btColorRaw = btColorRaw
  audit.cdRaw = cdRaw
  audit.chargesRaw = chargesRaw
  audit.overlayRaw = overlayRaw
  audit.isReady = finalReady
  audit.isUsable = isUsable
  audit.isNoResource = isNoResource
  audit.isOutOfRange = isOutOfRange
  audit.isProc = isProc
  audit.isUnavailable = isUnavailable
  audit.usableSource = usableSource

  if not finalReady and def.procOnly and not isProc then
    return false, remSec, durSec, startTime, false, false, def.liveIcon or def.fallbackIcon, def.keybind or "", 0, isUnavailable, false, 0, isOutOfRange
  end

  if SpArc.RecordModuleTick then
    SpArc:RecordModuleTick("State", defKey)
  end

  return finalReady, remSec, durSec, startTime, isUsable, isProc, def.liveIcon or def.fallbackIcon, def.keybind or "", charges, isUnavailable, isNoResource, resWaitSec, isOutOfRange
end

-- @techdebt [AUDIT-ST2]: Hardcoded Energy costs for Rogue/Feral; move to declarative metadata in Phase 2
SpArc.DEFAULT_ENERGY_COST = {
  MUTILATE = 50,
  AMBUSH = 50,
  GARROTE = 45,
  FAN_OF_KNIVES = 35,
  ENVENOM = 35,
  CRIMSON_TEMPEST = 30,
  RUPTURE = 25,
  KINGSBANE = 35,
  SHIV = 20,
  SINISTER_STRIKE = 45,
  DISPATCH = 35,
  BETWEEN_THE_EYES = 25,
  SHADOWSTRIKE = 40,
  BACKSTAB = 35,
  GLOOMBLADE = 35,
  EVISCERATE = 35,
  BLACK_POWDER = 35,
  SHRED = 40,
  TIGER_PALM = 50,
  DETOX = 20,
  DISABLE = 15,
  RAKE = 35,
  SWIPE = 35,
  BRUTAL_SLASH = 25,
  RIP = 20,
  PRIMAL_WRATH = 20,
  MOONFIRE = 30,
  FERAL_FRENZY = 25,
  FEROCIOUS_BITE = 25,
}

local EMPTY_TABLE = {}

-- Unified WeakAuras-style Aura Inspector:
-- Returns (isActive: boolean, remSec: number, stacks: number) for any Aura (DoT, Debuff, Buff, Burst, Enrage)
-- on `unit` ("target" or "player") by `.MD` Spell/Aura KEY or numeric Wowhead Aura Spell ID.
function SpArc:GetUnitAuraState(unit, keyOrID, parsed, assistedKey, now)
  if not keyOrID then return false, 0, 0 end
  unit = (unit and unit:lower() == "player") and "player" or "target"
  now = now or GetTime()

  if SpArc.testMode then
    if keyOrID == "FREEZING" or keyOrID == "TARGET_DEBUFF" then
      return true, 12.0, 4
    end
  end

  if unit == "target" then
    if not (_G.UnitExists and SafeBool(_G.UnitExists, "target")) then
      return false, 0, 0
    end
    if _G.UnitIsDeadOrGhost and SafeBool(_G.UnitIsDeadOrGhost, "target") then
      return false, 0, 0
    end
  end

  local numID = tonumber(keyOrID)
  if type(parsed) ~= "table" then
    parsed = st.activeParsed
  end
  local def = (not numID) and ((parsed and parsed.auras and parsed.auras[keyOrID]) or SPELL_DEFS[keyOrID]) or nil
  local checkIDs = (def and (def.auraIDs or def.debuffIDs or def.ids)) or (numID and { numID }) or EMPTY_TABLE
  local checkNames = (def and def.names) or EMPTY_TABLE
  local wantIcon = def and (def.liveIcon or def.fallbackIcon) or nil
  local defaultDur = (def and (def.auraDuration or def.dotDuration or def.burstDuration)) or 15.0

  if unit == "player" then
    if keyOrID == "STEALTH" or keyOrID == "PROWL" or numID == 1784 or numID == 5215 then
      if _G.IsStealthed and SafeBool(_G.IsStealthed) then
        return true, 3600, 1
      end
    elseif (keyOrID == "CAT_FORM" or numID == 768) and _G.GetShapeshiftFormID then
      local okF, formID = pcall(_G.GetShapeshiftFormID)
      if okF and not IsSecret(formID) and formID == 1 then
        return true, 3600, 1
      end
    elseif (keyOrID == "MOONKIN_FORM" or numID == 24858 or numID == 197625) and _G.GetShapeshiftFormID then
      local okF, formID = pcall(_G.GetShapeshiftFormID)
      if okF and not IsSecret(formID) and (formID == 31 or formID == 35) then
        return true, 3600, 1
      end
    elseif (keyOrID == "BEAR_FORM" or numID == 5487) and _G.GetShapeshiftFormID then
      local okF, formID = pcall(_G.GetShapeshiftFormID)
      if okF and not IsSecret(formID) and formID == 5 then
        return true, 3600, 1
      end
    elseif (keyOrID == "SHADOWFORM" or numID == 232698) and _G.GetShapeshiftForm then
      local okF, form = pcall(_G.GetShapeshiftForm)
      if okF and not IsSecret(form) and type(form) == "number" and form > 0 then
        return true, 3600, 1
      end
    end
  end

  local uMap = st.unitAuras and st.unitAuras[unit]

  local function ExtractAuraRemAndStacks(aura, matchedID)
    local rem = nil
    if not IsSecret(aura.expirationTime) and type(aura.expirationTime) == "number" then
      if aura.expirationTime == 0 then
        rem = 3600
      else
        rem = math.max(0, aura.expirationTime - now)
      end
    else
      local fb = uMap and ((matchedID and uMap[matchedID]) or uMap[keyOrID])
      local fbExp = fb and (fb.expiresAt or fb.untilTime)
      if fbExp and fbExp > now then
        rem = fbExp - now
      else
        rem = defaultDur
      end
    end
    local stacks = 1
    if not IsSecret(aura.applications) and type(aura.applications) == "number" then
      stacks = math.max(1, aura.applications)
    else
      local fb = uMap and ((matchedID and uMap[matchedID]) or uMap[keyOrID])
      if fb and fb.stacks and fb.stacks > 0 then
        stacks = fb.stacks
      end
    end
    return rem, stacks
  end

  -- 1. Direct lookup by Aura Spell ID via C_UnitAuras
  if C_UnitAuras and #checkIDs > 0 then
    for _, id in ipairs(checkIDs) do
      if C_UnitAuras.GetUnitAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, unit, id)
        if ok and type(aura) == "table" then
          local rem, stacks = ExtractAuraRemAndStacks(aura, id)
          if rem > 0 then
            return true, rem, stacks
          end
        end
      end
      if unit == "player" and C_UnitAuras.GetPlayerAuraBySpellID then
        local okP, auraP = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
        if okP and type(auraP) == "table" then
          local rem, stacks = ExtractAuraRemAndStacks(auraP, id)
          if rem > 0 then
            return true, rem, stacks
          end
        end
      end
    end
  end

  -- 2. Indexed Aura Scan (lightweight fallback across player's own debuffs/buffs)
  if C_UnitAuras and (#checkIDs > 0 or #checkNames > 0) then
    local idLookup = (def and def.auraIDSet) or nil
    if not idLookup then
      idLookup = {}
      for _, id in ipairs(checkIDs) do
        idLookup[id] = true
      end
      if def then def.auraIDSet = idLookup end
    end
    local lowerWantNames = (def and def.lowerNames) or nil
    if not lowerWantNames and #checkNames > 0 then
      lowerWantNames = {}
      for _, wantNm in ipairs(checkNames) do
        lowerWantNames[#lowerWantNames + 1] = SpArc.UTF8Lower(wantNm)
      end
      if def then def.lowerNames = lowerWantNames end
    end

    local function ScanAuraSlots(fetchFn, filter, maxSlots)
      if not fetchFn then return nil, nil end
      for i = 1, (maxSlots or 12) do
        local ok, aura = pcall(fetchFn, unit, i, filter)
        if not ok or type(aura) ~= "table" then
          break
        end
        local sid = (not IsSecret(aura.spellId) and type(aura.spellId) == "number") and aura.spellId or nil
        local matched = false
        if sid and idLookup[sid] then
          matched = true
        elseif lowerWantNames and #lowerWantNames > 0 then
          local nm = (not IsSecret(aura.name) and type(aura.name) == "string") and aura.name or nil
          if nm then
            local lowerNm = SpArc.UTF8Lower(nm)
            for idx, wantNm in ipairs(checkNames) do
              local lowerWant = lowerWantNames[idx]
              if nm == wantNm or lowerNm == lowerWant or (lowerWant and lowerNm:find(lowerWant, 1, true)) then
                matched = true
                break
              end
            end
          end
        end
        if matched then
          local rem, stacks = ExtractAuraRemAndStacks(aura, sid)
          if rem > 0 then
            return rem, stacks
          end
        end
      end
      return nil, nil
    end

    if unit == "target" then
      local rem, stacks = ScanAuraSlots(C_UnitAuras.GetDebuffDataByIndex, "HARMFUL|PLAYER", 10)
      if not rem and (not C_UnitAuras.GetUnitAuraBySpellID or #checkIDs == 0 or (def and def.isAuraOnly)) then
        rem, stacks = ScanAuraSlots(C_UnitAuras.GetDebuffDataByIndex, "HARMFUL", 12)
      end
      if rem and rem > 0 then
        return true, rem, stacks
      end
    elseif not C_UnitAuras.GetUnitAuraBySpellID or #checkIDs == 0 then
      local rem, stacks = ScanAuraSlots(C_UnitAuras.GetBuffDataByIndex, "HELPFUL", 16)
      if rem and rem > 0 then
        return true, rem, stacks
      end
    end
  end

  -- 3. ElvUI Target Debuff Frames fallback (when C_UnitAuras is restricted in 12.0 combat)
  if unit == "target" and (#checkIDs > 0 or wantIcon) then
    local idLookup = {}
    for _, id in ipairs(checkIDs) do
      idLookup[id] = true
    end
    for i = 1, 16 do
      local btn = _G["ElvUF_TargetDebuffsButton" .. i]
      if btn and SafeBool(btn.IsShown, btn) then
        local sid = btn.spellID
        local matched = false
        if not IsSecret(sid) and type(sid) == "number" and idLookup[sid] then
          matched = true
        elseif wantIcon and btn.Icon and btn.Icon.GetTexture then
          local okTex, iconTex = pcall(btn.Icon.GetTexture, btn.Icon)
          if okTex and not IsSecret(iconTex) and iconTex == wantIcon then
            matched = true
          end
        end
        if matched and not IsSecret(btn.expiration) and type(btn.expiration) == "number" and btn.expiration > now then
          return true, (btn.expiration - now), 1
        end
      end
    end
  end

  -- 4. Unified Cast-Timer & Stack Fallback (st.unitAuras[unit])
  if uMap then
    local entry = uMap[keyOrID]
    local exp = entry and (entry.expiresAt or entry.untilTime)
    if not (exp and exp > now) then
      for _, id in ipairs(checkIDs) do
        local e = uMap[id]
        local eExp = e and (e.expiresAt or e.untilTime)
        if eExp and eExp > now then
          entry = e
          exp = eExp
          break
        end
      end
    end
    if exp and exp > now then
      return true, (exp - now), math.max(1, entry.stacks or 1)
    end
  end

  return false, 0, 0
end

function SpArc:IsSpellBurstActive(defKey, sObj, parsed, now)
  if not defKey then return false end
  if type(parsed) == "number" then
    now = parsed
    parsed = st.activeParsed
  end
  now = now or GetTime()
  local def = SPELL_DEFS[defKey]
  local burstDur = def and def.burstDuration or 0
  if burstDur <= 0 then
    return false
  end
  local unit = (def and def.auraUnit) or "player"
  local active = SpArc:GetUnitAuraState(unit, defKey, parsed, nil, now)
  if active then
    return true
  end
  if sObj and (not sObj.isReady) and sObj.durSec and sObj.durSec >= 30 and sObj.remSec and sObj.remSec > 0 then
    local elapsed = sObj.durSec - sObj.remSec
    if elapsed >= 0 and elapsed < burstDur then
      return true
    end
  end
  local lastAt = st.lastCastAt and st.lastCastAt[defKey]
  if lastAt and (now - lastAt) >= 0 and (now - lastAt) < burstDur then
    return true
  end
  local chStart = st.spellChargeStart and st.spellChargeStart[defKey]
  if chStart and chStart > 0 and (now - chStart) >= 0 and (now - chStart) < burstDur then
    return true
  end
  return false
end

function SpArc:IsPlayerInBurst(states, parsed, now)
  if type(parsed) == "number" then
    now = parsed
    parsed = st.activeParsed
  end
  now = now or GetTime()
  for defKey, def in pairs(SPELL_DEFS or EMPTY_TABLE) do
    if def.burstDuration and def.burstDuration > 0 then
      local sObj = states and states[defKey] or nil
      if SpArc:IsSpellBurstActive(defKey, sObj, parsed, now) then
        return true
      end
    end
  end
  return false
end

function SpArc:GetPlayerHPPercent()
  if SpArc.testMode then
    return 18
  end
  if UnitHealth and UnitHealthMax then
    local ok1, hp = pcall(UnitHealth, "player")
    local ok2, maxHp = pcall(UnitHealthMax, "player")
    if ok1 and ok2 and not IsSecret(hp) and not IsSecret(maxHp) and type(hp) == "number" and type(maxHp) == "number" and maxHp > 0 then
      return (hp / maxHp) * 100
    end
  end
  if _G.LowHealthFrame and _G.LowHealthFrame.IsShown and SafeBool(_G.LowHealthFrame.IsShown, _G.LowHealthFrame) then
    return 20
  end
  return 100
end

function SpArc:GetPlayerEnergy(now)
  now = now or GetTime()
  if st.trackedEnergy and st.lastEnergyUpdateAt and now > st.lastEnergyUpdateAt then
    local dt = math.min(10.0, now - st.lastEnergyUpdateAt)
    local regen = 12.0
    if _G.GetPowerRegen then
      local okR, rVal = pcall(_G.GetPowerRegen)
      if okR and not IsSecret(rVal) and type(rVal) == "number" and rVal > 1 then
        regen = rVal
      end
    end
    st.trackedEnergy = math.min(100, st.trackedEnergy + dt * regen)
    st.lastEnergyUpdateAt = now
  end
  if UnitPower then
    local okE, curE = pcall(UnitPower, "player", 3)
    if okE and not IsSecret(curE) and type(curE) == "number" then
      st.trackedEnergy = curE
      st.lastEnergyUpdateAt = now
      return curE
    end
  end
  return st.trackedEnergy or 100
end

function SpArc:RefreshTrackedInsanity()
  local now = GetTime()
  if UnitPower then
    if SPELL_DEFS["STARSURGE"] or SPELL_DEFS["STARFALL"] then
      local okAP, ap = pcall(UnitPower, "player", 8)
      if okAP and not IsSecret(ap) and type(ap) == "number" then
        st.trackedInsanity = math.min(100, ap)
        return
      end
    elseif SPELL_DEFS["RISING_SUN_KICK"] or SPELL_DEFS["TIGER_PALM"] or SPELL_DEFS["BLACKOUT_KICK"] then
      local okChi, chi = pcall(UnitPower, "player", 12)
      if okChi and not IsSecret(chi) and type(chi) == "number" then
        st.trackedInsanity = math.min(120, chi * 20)
        return
      end
    elseif SPELL_DEFS["KILL_COMMAND"] or SPELL_DEFS["MONGOOSE_BITE"] or SPELL_DEFS["WILDFIRE_BOMB"] or (st.activeParsed and st.activeParsed.class == "HUNTER") then
      local okF, f = pcall(UnitPower, "player", 2)
      if okF and not IsSecret(f) and type(f) == "number" then
        st.trackedInsanity = math.min(100, f)
        st.lastFocusUpdateAt = now
        return
      end
      local inCombat = _G.UnitAffectingCombat and SafeBool(_G.UnitAffectingCombat, "player")
      if not st.lastFocusUpdateAt or (not inCombat and (st.trackedInsanity or 0) <= 0) then
        st.trackedInsanity = 100
        st.lastFocusUpdateAt = now
        return
      end
      if now > st.lastFocusUpdateAt then
        local dt = math.min(10.0, now - st.lastFocusUpdateAt)
        local regen = inCombat and 10.0 or 20.0
        if _G.GetPowerRegen then
          local okR, rVal = pcall(_G.GetPowerRegen)
          if okR and not IsSecret(rVal) and type(rVal) == "number" and rVal > 1 then
            regen = rVal
          end
        end
        st.trackedInsanity = math.min(100, (st.trackedInsanity or 100) + dt * regen)
        st.lastFocusUpdateAt = now
      end
      return
    elseif SPELL_DEFS["ENVENOM"] or SPELL_DEFS["EVISCERATE"] or SPELL_DEFS["DISPATCH"] or SPELL_DEFS["FEROCIOUS_BITE"] or SPELL_DEFS["RIP"] or SPELL_DEFS["RUPTURE"] then
      local okCP, cp = pcall(UnitPower, "player", 4)
      if okCP and not IsSecret(cp) and type(cp) == "number" then
        st.trackedInsanity = math.min(100, cp * 20)
        return
      end
    end
    if SPELL_DEFS["DEVOURING_PLAGUE"] or (st.activeParsed and st.activeParsed.class == "PRIEST") then
      local ok, p = pcall(UnitPower, "player", 13)
      if ok and not IsSecret(p) and type(p) == "number" then
        st.trackedInsanity = p
      end
    end
  end
end

local MELEE_RANGE_CHECK_SPELLS = {
  WARRIOR     = { 12294, 23881, 1464, 7384, 6552, 23922, 163201, 5308 },
  ROGUE       = { 1329, 1752, 193315, 703, 1943, 32645, 1766, 2098 },
  PALADIN     = { 35395, 184575, 85256, 96231 },
  DEATHKNIGHT = { 49998, 49143, 85948, 55090, 47528 },
  MONK        = { 100780, 100784, 107428, 116705 },
  DEMONHUNTER = { 162794, 201427, 203782, 183752 },
  DRUID       = { 5221, 1822, 33917, 106832 },
  SHAMAN      = { 17364, 60103, 73899 },
}

local RANGED_RANGE_CHECK_SPELLS = {
  PRIEST      = { 589, 8092, 34914, 15407 },
  MAGE        = { 116, 30455, 44614, 133, 30451 },
  WARLOCK     = { 686, 172, 29722 },
  HUNTER      = { 193455, 56641, 259489 },
  EVOKER      = { 361469, 362969 },
}

local AOE_ASSIST_HINTS = {
  FAN_OF_KNIVES    = 3,
  CRIMSON_TEMPEST  = 2,
  SWEEPING_STRIKES = 2,
  CLEAVE           = 3,
  BLADESTORM       = 3,
  WHIRLWIND        = 3,
  THUNDER_CLAP     = 3,
  BLIZZARD         = 3,
  COMET_STORM      = 2,
  FROZEN_ORB       = 2,
  SWIPE            = 2,
  PRIMAL_WRATH     = 2,
  STARFALL         = 2,
  CRASH_LIGHTNING  = 2,
  CHAIN_LIGHTNING  = 3,
  SPINNING_CRANE_KICK = 3,
}

local function IsUnitDummyOrInCombat(unit)
  if not unit then return false end
  if _G.UnitIsUnit and SafeBool(_G.UnitIsUnit, unit, "target") then
    return true
  end
  if _G.UnitAffectingCombat and SafeBool(_G.UnitAffectingCombat, unit) then
    return true
  end
  if _G.UnitThreatSituation then
    local okT, threat = pcall(_G.UnitThreatSituation, "player", unit)
    if okT and not IsSecret(threat) and type(threat) == "number" and threat >= 0 then
      return true
    end
  end
  -- Only count non-target training dummies if the player has actively tagged them with a debuff/DoT
  if C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex then
    local okD, dData = pcall(C_UnitAuras.GetDebuffDataByIndex, unit, 1, "PLAYER")
    if okD and dData ~= nil then
      return true
    end
  end
  return false
end

local function IsUnitInClassRange(unit, isMelee, checkSpellIDs, checkSlot)
  if C_Spell and C_Spell.IsSpellInRange and checkSpellIDs then
    for _, sid in ipairs(checkSpellIDs) do
      local okR, inR = pcall(C_Spell.IsSpellInRange, sid, unit)
      if okR and not IsSecret(inR) and inR ~= nil then
        if inR == true or inR == 1 then
          return true
        elseif inR == false or inR == 0 then
          return false
        end
      end
    end
  end
  if checkSlot and _G.IsActionInRange then
    local okA, inA = pcall(_G.IsActionInRange, checkSlot, unit)
    if okA and not IsSecret(inA) and inA ~= nil then
      if inA == true or inA == 1 then
        return true
      elseif inA == false or inA == 0 then
        return false
      end
    end
  end
  if isMelee and not (_G.InCombatLockdown and SafeBool(_G.InCombatLockdown)) and _G.CheckInteractDistance then
    local okI, inI = pcall(_G.CheckInteractDistance, unit, 3)
    if okI and not IsSecret(inI) and type(inI) == "boolean" then
      return inI
    end
  end
  -- Fallback when WoW 12.0 marks range secret in combat: count only units actively fighting
  return IsUnitDummyOrInCombat(unit)
end

-- WeakAuras-style nearby enemy counter using Nameplates + Spell/Action/Interact Range + 2.0s anti-jitter hysteresis
function SpArc:GetNearbyEnemyCount(now, assistedKey)
  if SpArc.testMode then
    return 3
  end
  now = now or GetTime()
  if st.lastEnemyScanAt and (now - st.lastEnemyScanAt) < 0.20 then
    return st.enemyCount or 1
  end
  st.lastEnemyScanAt = now

  local playerClass = "PRIEST"
  if _G.UnitClass then
    local okC, _, cls = pcall(_G.UnitClass, "player")
    if okC and not IsSecret(cls) and type(cls) == "string" then
      playerClass = cls
    end
  end

  local isBalanceDruid = (playerClass == "DRUID" and (SPELL_DEFS["STARSURGE"] ~= nil or SPELL_DEFS["STARFALL"] ~= nil))
  local isMelee = (MELEE_RANGE_CHECK_SPELLS[playerClass] ~= nil) and not isBalanceDruid
  local checkSpellIDs = isBalanceDruid and { 8921, 93402, 190984, 194153, 78674 }
    or MELEE_RANGE_CHECK_SPELLS[playerClass]
    or RANGED_RANGE_CHECK_SPELLS[playerClass]
  local checkSlot = nil
  for _, def in pairs(SPELL_DEFS or EMPTY_TABLE) do
    if def.slot and not def.isSpender and (def.baseCD or 0) <= 6 then
      checkSlot = def.slot
      break
    end
  end

  local rawCount = 0
  local seenUnits = {}

  if _G.C_NamePlate and _G.C_NamePlate.GetNamePlates then
    local okNP, plates = pcall(_G.C_NamePlate.GetNamePlates)
    if okNP and type(plates) == "table" and not IsSecret(plates) then
      for _, plate in ipairs(plates) do
        local u = type(plate) == "table" and plate.namePlateUnitToken or nil
        if u and not IsSecret(u) and type(u) == "string" then
          seenUnits[u] = true
          if _G.UnitExists and SafeBool(_G.UnitExists, u)
            and _G.UnitCanAttack and SafeBool(_G.UnitCanAttack, "player", u)
            and not (_G.UnitIsDeadOrGhost and SafeBool(_G.UnitIsDeadOrGhost, u)) then
            if IsUnitDummyOrInCombat(u) and IsUnitInClassRange(u, isMelee, checkSpellIDs, checkSlot) then
              rawCount = rawCount + 1
            end
          end
        end
      end
    end
  end

  if rawCount == 0 then
    for i = 1, 40 do
      local u = "nameplate" .. i
      if not seenUnits[u] and _G.UnitExists and SafeBool(_G.UnitExists, u) then
        if _G.UnitCanAttack and SafeBool(_G.UnitCanAttack, "player", u)
          and not (_G.UnitIsDeadOrGhost and SafeBool(_G.UnitIsDeadOrGhost, u)) then
          if IsUnitDummyOrInCombat(u) and IsUnitInClassRange(u, isMelee, checkSpellIDs, checkSlot) then
            rawCount = rawCount + 1
          end
        end
      end
    end
  end

  local hasValidTarget = _G.UnitExists and SafeBool(_G.UnitExists, "target")
    and _G.UnitCanAttack and SafeBool(_G.UnitCanAttack, "player", "target")
    and not (_G.UnitIsDeadOrGhost and SafeBool(_G.UnitIsDeadOrGhost, "target"))
  if hasValidTarget and rawCount < 1 then
    rawCount = 1
  end

  local aoeHint = assistedKey and AOE_ASSIST_HINTS[assistedKey] or nil
  if aoeHint and rawCount < aoeHint then
    rawCount = aoeHint
  end

  local prev = st.enemyCount or (hasValidTarget and 1 or 0)
  local inCombat = _G.InCombatLockdown and SafeBool(_G.InCombatLockdown) or false

  if rawCount > prev then
    if prev <= 1 and rawCount >= 2 then
      if not st.enemyUpCandidateSince then
        st.enemyUpCandidateSince = now
      end
      if (now - st.enemyUpCandidateSince) >= 0.25 then
        st.enemyCount = rawCount
        st.enemyHoldUntil = now + 2.0
        st.enemyUpCandidateSince = nil
      end
    else
      st.enemyCount = rawCount
      st.enemyHoldUntil = now + 2.0
      st.enemyUpCandidateSince = nil
    end
  elseif rawCount < prev then
    st.enemyUpCandidateSince = nil
    if not inCombat and not hasValidTarget then
      st.enemyCount = 0
      st.enemyHoldUntil = 0
    elseif not st.enemyHoldUntil or now >= st.enemyHoldUntil then
      st.enemyCount = rawCount
    end
  else
    st.enemyUpCandidateSince = nil
    if rawCount >= 2 then
      st.enemyHoldUntil = now + 2.0
    end
  end

  return st.enemyCount or rawCount
end

local PICK_POCKET_CREATURE_TYPES = {
  ["Гуманоид"] = true,
  ["Humanoid"] = true,
}

function SpArc:MarkTargetPickPocketed(markNameToo)
  local now = GetTime()
  st.lastCastAt = st.lastCastAt or {}
  st.lastCastAt["PICK_POCKET"] = now
  st.targetPickPocketed = true
  if _G.UnitGUID then
    local okG, guid = pcall(_G.UnitGUID, "target")
    if okG and not IsSecret(guid) and type(guid) == "string" and guid ~= "" then
      st.pickPocketedGUIDs = st.pickPocketedGUIDs or {}
      st.pickPocketedGUIDs[guid] = true
    end
  end
  if markNameToo and _G.UnitName then
    local okN, tName = pcall(_G.UnitName, "target")
    if okN and not IsSecret(tName) and type(tName) == "string" and tName ~= "" then
      st.noPocketsNames = st.noPocketsNames or {}
      st.noPocketsNames[tName] = true
    end
  end
end

function SpArc:CanPickPocketTarget(now)
  now = now or GetTime()
  if st.targetPickPocketed then
    return false
  end
  if not (_G.IsStealthed and SafeBool(_G.IsStealthed)) then
    return false
  end
  if _G.InCombatLockdown and SafeBool(_G.InCombatLockdown) then
    return false
  end
  if not (_G.UnitExists and SafeBool(_G.UnitExists, "target")) then
    return false
  end
  if not (_G.UnitCanAttack and SafeBool(_G.UnitCanAttack, "player", "target")) then
    return false
  end
  if _G.UnitIsDeadOrGhost and SafeBool(_G.UnitIsDeadOrGhost, "target") then
    return false
  end
  if _G.UnitIsPlayer and SafeBool(_G.UnitIsPlayer, "target") then
    return false
  end

  local lastPP = st.lastCastAt and st.lastCastAt["PICK_POCKET"]
  if lastPP and (now - lastPP) < 10.0 then
    return false
  end

  if _G.UnitGUID then
    local okG, guid = pcall(_G.UnitGUID, "target")
    if okG and not IsSecret(guid) and type(guid) == "string" and st.pickPocketedGUIDs and st.pickPocketedGUIDs[guid] then
      return false
    end
  end

  if _G.UnitName then
    local okN, tName = pcall(_G.UnitName, "target")
    if okN and not IsSecret(tName) and type(tName) == "string" and tName ~= "" then
      if st.noPocketsNames and st.noPocketsNames[tName] then
        return false
      end
      local lowN = SpArc.UTF8Lower and SpArc.UTF8Lower(tName) or tName:lower()
      if lowN:find("бездн", 1, true) or lowN:find("void", 1, true) or lowN:find("элементал", 1, true) or lowN:find("elemental", 1, true) or lowN:find("порожден", 1, true) or lowN:find("призрак", 1, true) or lowN:find("дух", 1, true) then
        return false
      end
    end
  end

  if _G.UnitCreatureType then
    local okCT, cType = pcall(_G.UnitCreatureType, "target")
    if not okCT or IsSecret(cType) or type(cType) ~= "string" or not PICK_POCKET_CREATURE_TYPES[cType] then
      return false
    end
  else
    return false
  end

  local ppDef = SPELL_DEFS["PICK_POCKET"]
  local ppSlot = ppDef and ppDef.slot or nil
  if SpArc.IsSpellOutOfRange and SpArc:IsSpellOutOfRange("PICK_POCKET", ppDef, 921, ppSlot, true) then
    return false
  end

  if C_Spell and C_Spell.IsSpellInRange then
    local okR, inR = pcall(C_Spell.IsSpellInRange, 921, "target")
    if okR and not IsSecret(inR) and inR ~= nil then
      return (inR == true or inR == 1)
    end
  end
  if _G.CheckInteractDistance then
    local okI, inI = pcall(_G.CheckInteractDistance, "target", 3)
    if okI and not IsSecret(inI) and type(inI) == "boolean" then
      return inI
    end
  end

  return false
end

local NO_RANGE_CHECK_SPELLS = {
  STEALTH              = true,
  VANISH               = true,
  SLICE_AND_DICE       = true,
  CRIMSON_VIAL         = true,
  EVASION              = true,
  CLOAK_OF_SHADOWS     = true,
  FEINT                = true,
  THISTLE_TEA          = true,
  SPRINT               = true,
  SHADOW_DANCE         = true,
  SYMBOLS_OF_DEATH     = true,
  ADRENALINE_RUSH      = true,
  BLADE_FLURRY         = true,
  DEADLY_POISON        = true,
  CRIPPLING_POISON     = true,
  BATTLE_SHOUT         = true,
  AVATAR               = true,
  SWEEPING_STRIKES     = true,
  DIE_BY_THE_SWORD     = true,
  RALLYING_CRY         = true,
  SPELL_REFLECTION     = true,
  ARCANE_INTELLECT     = true,
  ICE_BARRIER          = true,
  ICE_BLOCK            = true,
  ALTER_TIME           = true,
  COLD_SNAP            = true,
  ICY_VEINS            = true,
  MIRROR_IMAGE         = true,
  SHIFTING_POWER       = true,
  POWER_WORD_FORTITUDE = true,
  SHADOWFORM           = true,
  DISPERSION           = true,
  DESPERATE_PRAYER     = true,
  VAMPIRIC_EMBRACE     = true,
  FADE                 = true,
  POWER_WORD_SHIELD    = true,
  POWER_INFUSION       = true,
  VOIDFORM             = true,
  DARK_ASCENSION       = true,
  PROWL                = true,
  CAT_FORM             = true,
  MARK_OF_THE_WILD     = true,
  TIGERS_FURY          = true,
  BERSERK              = true,
  SURVIVAL_INSTINCTS   = true,
  BARKSKIN             = true,
  RENEWAL              = true,
  FRENZIED_REGENERATION = true,
  REGROWTH             = true,
  MOONKIN_FORM         = true,
  BEAR_FORM            = true,
  CELESTIAL_ALIGNMENT  = true,
  SOLAR_ECLIPSE        = true,
  FORCE_OF_NATURE      = true,
  STARFALL             = true,
  WARRIOR_OF_ELUNE     = true,
  LIGHTNING_SHIELD     = true,
  ASTRAL_SHIFT         = true,
  HEALING_SURGE        = true,
  HEALING_STREAM_TOTEM = true,
  EARTH_ELEMENTAL      = true,
  GROUNDING_TOTEM      = true,
  DOOM_WINDS           = true,
  FERAL_SPIRIT         = true,
  ASCENDANCE           = true,
  THUNDERSTORM         = true,
  SPIRIT_WALK          = true,
  TOTEMIC_PROJECTION   = true,
  FORTIFYING_BREW      = true,
  TOUCH_OF_KARMA       = true,
  VIVIFY               = true,
  EXPEL_HARM           = true,
  DIFFUSE_MAGIC        = true,
  DAMPEN_HARM          = true,
  INVOKE_XUEN          = true,
  STORM_EARTH_AND_FIRE = true,
  SPINNING_CRANE_KICK  = true,
  SLICING_WINDS        = true,
  LEG_SWEEP            = true,
  CELESTIAL_CONDUIT    = true,
  WHIRLING_DRAGON_PUNCH = true,
}

local CLASS_RANGE_FALLBACK_SPELLS = {
  ROGUE   = { 1329, 1752, 53, 8676 },
  WARRIOR = { 12294, 1464, 23881, 6552 },
  MAGE    = { 116, 30455, 133, 30451 },
  PRIEST  = { 8092, 589, 34914, 15407 },
  DRUID   = { 5221, 1822, 22568, 1079, 8921, 93402, 190984, 194153, 78674 },
  SHAMAN  = { 17364, 60103, 188196, 188389 },
  MONK    = { 100780, 100784, 107428, 116705 },
}

local function CheckBT4ButtonOutOfRange(btBtn)
  if not btBtn then return nil end
  if not IsSecret(btBtn.outOfRange) and type(btBtn.outOfRange) == "boolean" then
    if btBtn.outOfRange then
      return true
    end
  end
  if btBtn.HotKey then
    if btBtn.HotKey.GetVertexColor then
      local okHV, vr, vg, vb = pcall(btBtn.HotKey.GetVertexColor, btBtn.HotKey)
      if okHV and not IsSecret(vr) and not IsSecret(vg) and not IsSecret(vb) and type(vr) == "number" then
        if vr > 0.70 and (vg or 1) < 0.25 and (vb or 1) < 0.25 then
          return true
        elseif vr > 0.50 and (vg or 0) > 0.50 and (vb or 0) > 0.50 then
          return false
        end
      end
    end
    if btBtn.HotKey.GetTextColor then
      local okHK, hr, hg, hb = pcall(btBtn.HotKey.GetTextColor, btBtn.HotKey)
      if okHK and not IsSecret(hr) and not IsSecret(hg) and not IsSecret(hb) and type(hr) == "number" then
        if hr > 0.70 and (hg or 1) < 0.25 and (hb or 1) < 0.25 then
          return true
        end
      end
    end
  end
  if btBtn.icon and btBtn.icon.GetVertexColor then
    local okV, vr, vg, vb = pcall(btBtn.icon.GetVertexColor, btBtn.icon)
    if okV and not IsSecret(vr) and not IsSecret(vg) and not IsSecret(vb) and type(vr) == "number" then
      if vr > 0.65 and (vg or 1) < 0.30 and (vb or 1) < 0.30 then
        return true
      end
    end
  end
  if not IsSecret(btBtn.outOfRange) and btBtn.outOfRange == false then
    return false
  end
  return nil
end

function SpArc:IsSpellOutOfRange(defKey, def, spellID, slot, slotMatchesDef)
  if SpArc.testMode or not defKey or NO_RANGE_CHECK_SPELLS[defKey] then
    return false
  end
  if not (_G.UnitExists and SafeBool(_G.UnitExists, "target")) then
    return false
  end
  if not (_G.UnitCanAttack and SafeBool(_G.UnitCanAttack, "player", "target")) then
    return false
  end
  if _G.UnitIsDeadOrGhost and SafeBool(_G.UnitIsDeadOrGhost, "target") then
    return false
  end

  if C_Spell and C_Spell.IsSpellInRange then
    if spellID then
      local okR, inR = pcall(C_Spell.IsSpellInRange, spellID, "target")
      if okR and not IsSecret(inR) and inR ~= nil then
        return (inR == false or inR == 0)
      end
    end
    if def and def.ids then
      for _, id in ipairs(def.ids) do
        if id ~= spellID then
          local okR, inR = pcall(C_Spell.IsSpellInRange, id, "target")
          if okR and not IsSecret(inR) and inR ~= nil then
            return (inR == false or inR == 0)
          end
        end
      end
    end
  end

  if slot and _G.IsActionInRange then
    local okAR, inAR = pcall(_G.IsActionInRange, slot, "target")
    if not okAR or inAR == nil then
      okAR, inAR = pcall(_G.IsActionInRange, slot)
    end
    if okAR and not IsSecret(inAR) and inAR ~= nil then
      return (inAR == false or inAR == 0)
    end
  end

  if slot then
    local physSlot = (slot >= 73 and slot <= 120) and (((slot - 73) % 12) + 1) or slot
    local btRes = CheckBT4ButtonOutOfRange(_G["BT4Button" .. physSlot])
    if btRes ~= nil then
      return btRes
    end
  end

  if _G.UnitClass and C_Spell and C_Spell.IsSpellInRange then
    local okC, _, playerClass = pcall(_G.UnitClass, "player")
    if okC and not IsSecret(playerClass) and type(playerClass) == "string" then
      local fallbackIDs = CLASS_RANGE_FALLBACK_SPELLS[playerClass]
      if fallbackIDs then
        for _, fID in ipairs(fallbackIDs) do
          local okFR, inFR = pcall(C_Spell.IsSpellInRange, fID, "target")
          if okFR and not IsSecret(inFR) and inFR ~= nil then
            return (inFR == false or inFR == 0)
          end
        end
      end
    end
  end

  return false
end
