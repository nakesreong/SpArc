---------------------------------------------------------------------------------------
--  SpArc/State.lua — Spell Cooldown, Charges, Proc, DoT & Usability Evaluator
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
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

function SpArc:TriggerGCD(now)
  now = now or GetTime()
  if C_Spell and C_Spell.GetSpellCooldown then
    local ok, cd = pcall(C_Spell.GetSpellCooldown, 61304)
    if ok and type(cd) == "table" and not IsSecret(cd.startTime) and not IsSecret(cd.duration) then
      if type(cd.startTime) == "number" and cd.startTime > 0 and type(cd.duration) == "number" and cd.duration >= 0.25 and cd.duration <= 2.0 then
        if (cd.startTime + cd.duration) > now then
          st.gcdStartTime = cd.startTime
          st.gcdDuration = cd.duration
          return
        end
      end
    end
  end
  if (now - (st.gcdStartTime or 0)) > 0.12 then
    st.gcdStartTime = now
    st.gcdDuration = SpArc:GetPlayerGCDDuration()
  end
end

function SpArc:GetActiveGCD(now)
  now = now or GetTime()
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
    if defKey == "FLURRY" or defKey == "MIND_BLAST" or defKey == "TENTACLE_SLAM" then
      rawCD = def.baseCD / SpArc:GetPlayerSpellHasteMult()
    else
      rawCD = def.baseCD
    end
  end
  local cdDur = rawCD or 7.5
  if cdDur <= 0 then cdDur = 7.5 end
  local used = st.spellChargesUsed[defKey] or 0
  local chStart = st.spellChargeStart[defKey] or 0
  if used > 0 and chStart > 0 then
    local elapsed = now - chStart
    local recovered = math.floor(elapsed / cdDur)
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

local function FormatSecretOrVal(v)
  if IsSecret(v) then return "SECRET" end
  return tostring(v)
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
  local hasSpellOverlayProc = isProc
  local overrideActive = false
  if C_Spell and C_Spell.GetOverrideSpell and def.ids and #def.ids > 1 then
    for i = 2, #def.ids do
      local baseID = def.ids[i]
      local okO, over = pcall(C_Spell.GetOverrideSpell, baseID)
      if okO and not IsSecret(over) and type(over) == "number" and over > 0 and over ~= baseID then
        for _, myID in ipairs(def.ids) do
          if over == myID then
            isVoidBlastOverride = true
            spellID = over
            overlayRaw = "override(" .. tostring(over) .. ")"
            break
          end
        end
      end
    end
  end
  if def.overrideOf and SPELL_DEFS[def.overrideOf] then
    local baseDef = SPELL_DEFS[def.overrideOf]
    if C_Spell and C_Spell.GetOverrideSpell then
      for _, baseID in ipairs(baseDef.ids or {}) do
        local okO, over = pcall(C_Spell.GetOverrideSpell, baseID)
        if okO and not IsSecret(over) and type(over) == "number" and over > 0 and over ~= baseID then
          for _, myID in ipairs(def.ids or {}) do
            if over == myID then
              overrideActive = true
              isProc = true
              spellID = over
              overlayRaw = "override(" .. tostring(over) .. ")"
              break
            end
          end
        end
        if overrideActive then break end
      end
      if not overrideActive and baseDef.liveSpellID then
        local okO, over = pcall(C_Spell.GetOverrideSpell, baseDef.liveSpellID)
        if okO and not IsSecret(over) and type(over) == "number" and over > 0 then
          for _, myID in ipairs(def.ids or {}) do
            if over == myID then
              overrideActive = true
              isProc = true
              spellID = over
              overlayRaw = "override(" .. tostring(over) .. ")"
              break
            end
          end
        end
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
    if okC and type(ch) == "table" then
      if not IsSecret(ch.maxCharges) and type(ch.maxCharges) == "number" and ch.maxCharges >= 1 then
        local prevMax = def.liveMaxCharges or def.maxCharges or 1
        if ch.maxCharges ~= prevMax then
          if IsSecret(ch.currentCharges) then
            local used = st.spellChargesUsed[defKey] or 0
            if ch.maxCharges > prevMax then
              st.spellChargesUsed[defKey] = used + (ch.maxCharges - prevMax)
            else
              st.spellChargesUsed[defKey] = math.min(ch.maxCharges, used)
            end
          end
          def.liveMaxCharges = ch.maxCharges
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
          elseif cd.duration > 1.6 then
            local r = cd.startTime + cd.duration - now
            if r > 0.15 then
              isOnCD = true
              remSec = r
              durSec = cd.duration
              startTime = cd.startTime
              charges = 0
              cdRaw = string.format("%.1fs/%.1fs", remSec, durSec)
            end
          end
        end
      end
    end
  end

  if not gotCleanCD and slot and GetActionCooldown then
    local okA, s, d = pcall(GetActionCooldown, slot)
    if okA then
      if IsSecret(s) or IsSecret(d) then
        if cdRaw == "0s" then cdRaw = "ACT_SECRET" end
      elseif type(d) == "number" then
        gotCleanCD = true
        if s and s > 0 then
          if d >= 0.25 and d <= 1.6 and (s + d) > now then
            st.gcdStartTime = s
            st.gcdDuration = d
          elseif d > 1.6 then
            local r = s + d - now
            if r > 0.15 then
              isOnCD = true
              remSec = r
              durSec = d
              startTime = s
              charges = 0
              cdRaw = string.format("act:%.1fs/%.1fs", remSec, durSec)
            end
          end
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
      local last = st.lastCastAt[defKey]
      local effCD = def.baseCD or 0
      if last and effCD > 1.6 then
        local elapsed = now - last
        if elapsed < (effCD - 0.15) then
          isOnCD = true
          remSec = effCD - elapsed
          durSec = effCD
          startTime = last
          charges = 0
          cdRaw = string.format("timer:%.1fs", remSec)
        end
      end
    end
  end

  if isOnCD and remSec > 0 and durSec > 0 and (not startTime or startTime <= 0) then
    startTime = now - math.max(0, durSec - remSec)
  end

  if def.procOnly and isOnCD then
    isProc = false
  end

  if isVoidBlastOverride and not isOnCD then
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
    local slotMatchesDef = (not slotActiveSpellID) or (def.idSet and def.idSet[slotActiveSpellID]) or false
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
  if def.isExecute then
    local tgtHP = SpArc:GetTargetHPPercent()
    local hasCD = (def.baseCD and def.baseCD >= 3.0) and true or false
    local alwaysCastableExecute = (defKey == "SHADOW_WORD_DEATH" or spellID == 32379)
    if isProc then
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

    if def.isSpender and UnitPower then
      if defKey == "DEVOURING_PLAGUE" or SPELL_DEFS["DEVOURING_PLAGUE"] then
        local cost = (def.insanityCost and def.insanityCost > 0) and def.insanityCost or 50
        local okP, rawP = pcall(UnitPower, "player", 13)
        if okP and not IsSecret(rawP) and type(rawP) == "number" then
          if rawP < (cost - 5) and not isProc and assistedKey ~= defKey then
            isUsable = false
            gotCleanUsable = true
            usableSource = "UnitPower(" .. tostring(rawP) .. "<" .. tostring(cost - 5) .. ")"
          elseif rawP >= cost and not gotCleanUsable then
            isUsable = true
            gotCleanUsable = true
            usableSource = "UnitPower(" .. tostring(rawP) .. ">=" .. tostring(cost) .. ")"
          end
        end
      else
        local cost = (def.insanityCost and def.insanityCost > 0) and def.insanityCost or 80
        local minCP = math.max(1, math.floor(cost / 20))
        local okCP, rawCP = pcall(UnitPower, "player", 4)
        if okCP and not IsSecret(rawCP) and type(rawCP) == "number" then
          if rawCP < minCP then
            if hasSpellOverlayProc and defKey == "FEROCIOUS_BITE" then
              isUsable = true
              isProc = true
              gotCleanUsable = true
              usableSource = "ProcOverlayFreeSpender(" .. tostring(rawCP) .. "CP)"
            else
              isUsable = false
              isProc = false
              gotCleanUsable = true
              usableSource = "ComboPoints(" .. tostring(rawCP) .. "<" .. tostring(minCP) .. ")"
            end
          else
            isUsable = true
            gotCleanUsable = true
            usableSource = "ComboPoints(" .. tostring(rawCP) .. ">=" .. tostring(minCP) .. ")"
          end
        elseif (st.trackedInsanity or 0) >= cost or isProc or assistedKey == defKey then
          isUsable = true
          gotCleanUsable = true
          usableSource = "TrackedCP(" .. tostring(st.trackedInsanity or 0) .. ">=" .. tostring(cost) .. ")"
        else
          isUsable = false
          gotCleanUsable = true
          usableSource = "TrackedCP(" .. tostring(st.trackedInsanity or 0) .. "<" .. tostring(cost) .. ")"
        end
      end
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

    if (isProc or assistedKey == defKey) and not (def.isSpender and not SPELL_DEFS["DEVOURING_PLAGUE"] and gotCleanUsable and not isUsable) then
      isUsable = true
      usableSource = isProc and "ProcOverride" or "AssistedCombat"
    end
  end

  local finalReady = (not isOnCD)
  local isUnavailable = false

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
  if isUsable and not isUnavailable and not isPriestSpender and not isFreeProcSpender then
    if bookNoPowerVal == true or (useSlotActionState and actNoManaVal == true) then
      isNoResource = true
      resWaitSec = 2.6
      usableSource = usableSource .. "+NoResource"
    end
    local eCost = SpArc.DEFAULT_ENERGY_COST and SpArc.DEFAULT_ENERGY_COST[defKey]
    if eCost and UnitPower then
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

  return finalReady, remSec, durSec, startTime, isUsable, isProc, def.liveIcon or def.fallbackIcon, def.keybind or "", charges, isUnavailable, isNoResource, resWaitSec, isOutOfRange
end

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
  RAKE = 35,
  SWIPE = 35,
  BRUTAL_SLASH = 25,
  RIP = 20,
  PRIMAL_WRATH = 20,
  MOONFIRE = 30,
  FERAL_FRENZY = 25,
  FEROCIOUS_BITE = 25,
}

local DEFAULT_DOT_IDS = { 34914, 589, 772, 388539, 1943, 155722, 1079 }
local EMPTY_TABLE = {}

local DEFAULT_BURST_DURATIONS = {
  DEATHMARK = 16.0,
  KINGSBANE = 14.0,
  ICY_VEINS = 25.0,
  VOIDFORM = 20.0,
  POWER_INFUSION = 15.0,
  AVATAR = 20.0,
  COLOSSUS_SMASH = 10.0,
  COMBUSTION = 12.0,
  ARCANE_SURGE = 15.0,
  SHADOW_BLADES = 16.0,
  ADRENALINE_RUSH = 20.0,
  TIGERS_FURY = 20.0,
  BERSERK = 15.0,
}

function SpArc:IsSpellBurstActive(defKey, sObj, now)
  if not defKey then return false end
  now = now or GetTime()
  local def = SPELL_DEFS[defKey]
  local burstDur = (def and def.burstDuration) or DEFAULT_BURST_DURATIONS[defKey] or 0
  if burstDur <= 0 then
    return false
  end

  local last = st.lastCastAt and st.lastCastAt[defKey]
  if last and (now - last) >= 0 and (now - last) < burstDur then
    return true
  end

  if sObj and (not sObj.ready) and sObj.durSec and sObj.durSec >= 45 and sObj.remSec and sObj.remSec > 0 then
    local elapsed = sObj.durSec - sObj.remSec
    if elapsed >= 0 and elapsed < burstDur then
      return true
    end
  end

  if C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID and def and def.ids then
    for _, id in ipairs(def.ids) do
      local okP, auraP = pcall(C_UnitAuras.GetUnitAuraBySpellID, "player", id)
      if okP and type(auraP) == "table" then
        return true
      end
      local okT, auraT = pcall(C_UnitAuras.GetUnitAuraBySpellID, "target", id)
      if okT and type(auraT) == "table" then
        return true
      end
    end
  end

  return false
end

function SpArc:IsPlayerInBurst(states, now)
  now = now or GetTime()
  for defKey, def in pairs(SPELL_DEFS or EMPTY_TABLE) do
    local burstDur = def.burstDuration or DEFAULT_BURST_DURATIONS[defKey] or 0
    if burstDur > 0 then
      local sObj = states and states[defKey] or nil
      if SpArc:IsSpellBurstActive(defKey, sObj, now) then
        return true
      end
    end
  end
  return false
end

function SpArc:TargetHasSpellDoT(defKey, now)
  if not defKey then return false end
  now = now or GetTime()
  if not (_G.UnitExists and SafeBool(_G.UnitExists, "target")) then
    return false
  end
  if _G.UnitIsDeadOrGhost and SafeBool(_G.UnitIsDeadOrGhost, "target") then
    return false
  end

  local def = SPELL_DEFS[defKey]
  local refreshLeadSec = 1.0

  if C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID and def then
    for _, dID in ipairs(def.debuffIDs or EMPTY_TABLE) do
      local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, "target", dID)
      if ok and type(aura) == "table" then
        if not IsSecret(aura.expirationTime) and type(aura.expirationTime) == "number" and aura.expirationTime > 0 then
          return (aura.expirationTime - now) > refreshLeadSec
        end
      end
    end
    for _, sID in ipairs(def.ids or EMPTY_TABLE) do
      local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, "target", sID)
      if ok and type(aura) == "table" then
        if not IsSecret(aura.expirationTime) and type(aura.expirationTime) == "number" and aura.expirationTime > 0 then
          return (aura.expirationTime - now) > refreshLeadSec
        end
      end
    end
  end

  if def then
    local wantIcon = def.liveIcon or def.fallbackIcon
    for i = 1, 16 do
      local btn = _G["ElvUF_TargetDebuffsButton" .. i]
      if btn and SafeBool(btn.IsShown, btn) then
        local sid = btn.spellID
        local matched = false
        if not IsSecret(sid) and type(sid) == "number" then
          if def.idSet and def.idSet[sid] then
            matched = true
          elseif def.debuffIDs then
            for _, dID in ipairs(def.debuffIDs) do
              if sid == dID then matched = true; break end
            end
          end
        end
        if not matched and wantIcon and btn.Icon and btn.Icon.GetTexture then
          local okTex, iconTex = pcall(btn.Icon.GetTexture, btn.Icon)
          if okTex and not IsSecret(iconTex) and iconTex == wantIcon then
            matched = true
          end
        end
        if matched and not IsSecret(btn.expiration) and type(btn.expiration) == "number" and btn.expiration > 0 then
          return (btn.expiration - now) > refreshLeadSec
        end
      end
    end
  end

  local dotMap = st.targetSpellDoTs
  if dotMap then
    local untilT = dotMap[defKey]
    if (not untilT or untilT <= now) and def and def.debuffIDs then
      for _, dID in ipairs(def.debuffIDs) do
        local u = dotMap[dID]
        if u and u > now then
          untilT = u
          break
        end
      end
    end
    if untilT and untilT > 0 then
      return now < untilT
    end
  end

  return false
end

function SpArc:CheckTargetHasDoTs(assistedKey)
  local now = GetTime()
  if not (_G.UnitExists and SafeBool(_G.UnitExists, "target")) then
    return false
  end
  if _G.UnitIsDeadOrGhost and SafeBool(_G.UnitIsDeadOrGhost, "target") then
    return false
  end

  local refreshLeadSec = 1.2

  if C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID then
    for _, def in pairs(SPELL_DEFS or EMPTY_TABLE) do
      if def.appliesDoTs then
        for _, dID in ipairs(def.debuffIDs or EMPTY_TABLE) do
          local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, "target", dID)
          if ok and type(aura) == "table" then
            if not IsSecret(aura.expirationTime) and type(aura.expirationTime) == "number" and aura.expirationTime > 0 then
              return (aura.expirationTime - now) > refreshLeadSec
            end
          end
        end
        for _, dotID in ipairs(def.ids or EMPTY_TABLE) do
          local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, "target", dotID)
          if ok and type(aura) == "table" then
            if not IsSecret(aura.expirationTime) and type(aura.expirationTime) == "number" and aura.expirationTime > 0 then
              return (aura.expirationTime - now) > refreshLeadSec
            end
          end
        end
      end
    end
    for _, dotID in ipairs(DEFAULT_DOT_IDS) do
      local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, "target", dotID)
      if ok and type(aura) == "table" then
        if not IsSecret(aura.expirationTime) and type(aura.expirationTime) == "number" and aura.expirationTime > 0 then
          return (aura.expirationTime - now) > refreshLeadSec
        end
      end
    end
  end

  for i = 1, 16 do
    local btn = _G["ElvUF_TargetDebuffsButton" .. i]
    if btn and SafeBool(btn.IsShown, btn) then
      local sid = btn.spellID
      local isDotBtn = false
      if not IsSecret(sid) and (sid == 34914 or sid == 589 or sid == 772 or sid == 388539 or sid == 1943) then
        isDotBtn = true
      else
        local okTex, iconTex = false, nil
        if btn.Icon and btn.Icon.GetTexture then
          okTex, iconTex = pcall(btn.Icon.GetTexture, btn.Icon)
        end
        if okTex and not IsSecret(iconTex) and (iconTex == 135978 or iconTex == 136207 or iconTex == 132155 or iconTex == 132302) then
          isDotBtn = true
        end
      end
      if isDotBtn then
        if not IsSecret(btn.expiration) and type(btn.expiration) == "number" and btn.expiration > 0 then
          return (btn.expiration - now) > refreshLeadSec
        end
      end
    end
  end

  if st.targetDoTsUntil and st.targetDoTsUntil > 0 then
    return now < st.targetDoTsUntil
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
  if UnitPower then
    if not SPELL_DEFS["DEVOURING_PLAGUE"] then
      local okCP, cp = pcall(UnitPower, "player", 4)
      if okCP and not IsSecret(cp) and type(cp) == "number" then
        st.trackedInsanity = math.min(100, cp * 20)
        return
      end
    end
    local ok, p = pcall(UnitPower, "player", 13)
    if ok and not IsSecret(p) and type(p) == "number" then
      st.trackedInsanity = p
    end
  end
end

function SpArc:GetTargetDebuffStacks(parsed, assistedKey)
  if SpArc.testMode then
    return 4
  end
  local now = GetTime()
  if st.targetDebuffUntil and st.targetDebuffUntil > 0 and now >= st.targetDebuffUntil then
    st.targetDebuffStacks = 0
    st.targetDebuffUntil = 0
  end

  local debuffIDs = (parsed and parsed.targetDebuffIDs) or {}
  local debuffNames = (parsed and parsed.targetDebuffNames) or {}
  local idLookup = {}
  for _, id in ipairs(debuffIDs) do
    idLookup[id] = true
  end

  if C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID and #debuffIDs > 0 then
    for _, debuffID in ipairs(debuffIDs) do
      local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, "target", debuffID)
      if ok and type(aura) == "table" then
        if not IsSecret(aura.applications) and type(aura.applications) == "number" then
          local apps = math.max(1, aura.applications)
          st.targetDebuffStacks = apps
          st.targetDebuffUntil = now + 15.0
          return apps
        end
      end
    end
  end

  if C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex then
    local bestPlayerApps = nil
    for i = 1, 16 do
      local ok, aura = pcall(C_UnitAuras.GetDebuffDataByIndex, "target", i, "HARMFUL|PLAYER")
      if not ok or type(aura) ~= "table" then
        break
      end
      local apps = (not IsSecret(aura.applications) and type(aura.applications) == "number") and aura.applications or nil
      local sid = (not IsSecret(aura.spellId) and type(aura.spellId) == "number") and aura.spellId or nil
      local nm = (not IsSecret(aura.name) and type(aura.name) == "string") and aura.name or nil

      if sid and idLookup[sid] and apps then
        local c = math.max(1, apps)
        st.targetDebuffStacks = c
        st.targetDebuffUntil = now + 15.0
        return c
      end
      if nm and #debuffNames > 0 and apps then
        local lowerNm = SpArc.UTF8Lower(nm)
        for _, wantNm in ipairs(debuffNames) do
          local lowerWant = SpArc.UTF8Lower(wantNm)
          if nm == wantNm or lowerNm == lowerWant or lowerNm:find(lowerWant, 1, true) then
            local c = math.max(1, apps)
            st.targetDebuffStacks = c
            st.targetDebuffUntil = now + 15.0
            return c
          end
        end
      end
      if apps and apps > 0 and (not bestPlayerApps or apps > bestPlayerApps) then
        bestPlayerApps = apps
      end
    end
    if bestPlayerApps and (#debuffIDs > 0 or #debuffNames > 0) then
      st.targetDebuffStacks = bestPlayerApps
      st.targetDebuffUntil = now + 15.0
      return bestPlayerApps
    end
  end

  if assistedKey then
    local aDef = SPELL_DEFS[assistedKey]
    local aAudit = st.lastSpellAudit and st.lastSpellAudit[assistedKey]
    if aDef and aDef.consumesStacks and not (aAudit and aAudit.isProc) then
      local needed = aDef.stacksCost or 4
      if (st.targetDebuffStacks or 0) < needed then
        st.targetDebuffStacks = needed
        st.targetDebuffUntil = now + 12.0
      end
    elseif assistedKey == "FROSTBOLT" and (st.targetDebuffStacks or 0) >= 4 then
      st.targetDebuffStacks = 3
    end
  end

  return st.targetDebuffStacks or 0
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
  if _G.UnitName then
    local okN, nm = pcall(_G.UnitName, unit)
    if okN and not IsSecret(nm) and type(nm) == "string" then
      local low = SpArc.UTF8Lower(nm)
      if low:find("манекен", 1, true) or low:find("dummy", 1, true) or low:find("тренировоч", 1, true) then
        return true
      end
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
  if isMelee and _G.CheckInteractDistance then
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

  local isMelee = (MELEE_RANGE_CHECK_SPELLS[playerClass] ~= nil)
  local checkSpellIDs = MELEE_RANGE_CHECK_SPELLS[playerClass] or RANGED_RANGE_CHECK_SPELLS[playerClass]
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

local EXTRA_BUFF_SPELL_IDS = {
  DEADLY_POISON        = { 2823, 315584, 8679 },
  CRIPPLING_POISON     = { 3408, 5761 },
  SLICE_AND_DICE       = { 315496 },
  STEALTH              = { 1784, 115191, 115192, 5215 },
  PROWL                = { 5215 },
  CAT_FORM             = { 768 },
  MARK_OF_THE_WILD     = { 1126 },
  TIGERS_FURY          = { 5217 },
  BERSERK              = { 106951, 102543 },
  SWEEPING_STRIKES     = { 260708 },
  BATTLE_SHOUT         = { 6673 },
  ARCANE_INTELLECT     = { 1459 },
  ICE_BARRIER          = { 11426, 235313, 431038, 235450 },
  POWER_WORD_FORTITUDE = { 21562 },
  SHADOWFORM           = { 232698 },
  POWER_WORD_SHIELD    = { 17 },
}

local DEFAULT_BUFF_REM_DUR = {
  DEADLY_POISON        = 3600,
  CRIPPLING_POISON     = 3600,
  BATTLE_SHOUT         = 3600,
  ARCANE_INTELLECT     = 3600,
  POWER_WORD_FORTITUDE = 3600,
  MARK_OF_THE_WILD     = 3600,
  SHADOWFORM           = 3600,
  CAT_FORM             = 3600,
  ICE_BARRIER          = 60,
  SLICE_AND_DICE       = 30,
  SWEEPING_STRIKES     = 15,
  TIGERS_FURY          = 20,
  BERSERK              = 15,
  POWER_WORD_SHIELD    = 15,
}

function SpArc:PlayerHasBuff(defKey, now)
  if not defKey then return false end
  now = now or GetTime()
  if defKey == "STEALTH" then
    return _G.IsStealthed and SafeBool(_G.IsStealthed) or false
  elseif defKey == "SHADOWFORM" and _G.GetShapeshiftForm then
    local okF, form = pcall(_G.GetShapeshiftForm)
    if okF and not IsSecret(form) and type(form) == "number" and form > 0 then
      return true
    end
  end

  local def = SPELL_DEFS[defKey]
  local checkIDs = EXTRA_BUFF_SPELL_IDS[defKey] or (def and def.ids) or {}

  if C_UnitAuras then
    for _, id in ipairs(checkIDs) do
      if C_UnitAuras.GetPlayerAuraBySpellID then
        local okA, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
        if okA and type(aura) == "table" then
          return true
        end
      end
      if C_UnitAuras.GetUnitAuraBySpellID then
        local okU, auraU = pcall(C_UnitAuras.GetUnitAuraBySpellID, "player", id)
        if okU and type(auraU) == "table" then
          return true
        end
      end
    end
  end

  local last = st.lastCastAt and st.lastCastAt[defKey]
  local remDur = (def and def.burstDuration) or DEFAULT_BUFF_REM_DUR[defKey] or 20
  if last and (now - last) >= 0 and (now - last) < remDur then
    return true
  end

  return false
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
}

local CLASS_RANGE_FALLBACK_SPELLS = {
  ROGUE   = { 1329, 1752, 53, 8676 },
  WARRIOR = { 12294, 1464, 23881, 6552 },
  MAGE    = { 116, 30455, 133, 30451 },
  PRIEST  = { 8092, 589, 34914, 15407 },
  DRUID   = { 5221, 1822, 22568, 1079 },
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

  for otherKey, otherDef in pairs(SPELL_DEFS or EMPTY_TABLE) do
    if not NO_RANGE_CHECK_SPELLS[otherKey] and otherDef.slot then
      local pSlot = (otherDef.slot >= 73 and otherDef.slot <= 120) and (((otherDef.slot - 73) % 12) + 1) or otherDef.slot
      if pSlot > 12 then
        local btRes = CheckBT4ButtonOutOfRange(_G["BT4Button" .. pSlot])
        if btRes ~= nil then
          return btRes
        end
      end
    end
  end

  return false
end
