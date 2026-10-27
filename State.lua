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
  if defKey == "MIND_FLAY_INSANITY" then
    if C_Spell and C_Spell.GetOverrideSpell then
      local okO, over = pcall(C_Spell.GetOverrideSpell, 15407)
      if okO and not IsSecret(over) and over == 391403 then
        isProc = true
        overlayRaw = "override(391403)"
      end
    end
    if assistedKey == "MIND_FLAY_INSANITY" then
      isProc = true
      overlayRaw = "assisted(391403)"
    end
  elseif defKey == "MIND_BLAST" and C_Spell and C_Spell.GetOverrideSpell then
    local okO, over = pcall(C_Spell.GetOverrideSpell, 8092)
    if okO and not IsSecret(over) and over == 450983 then
      isVoidBlastOverride = true
      spellID = 450983
      overlayRaw = "override(450983)"
    end
  elseif defKey == "VOID_BOLT" then
    if C_Spell and C_Spell.GetOverrideSpell then
      local okO, over = pcall(C_Spell.GetOverrideSpell, 228260)
      if okO and not IsSecret(over) and type(over) == "number" and over > 0 and over ~= 228260 then
        isProc = true
        spellID = over
        overlayRaw = "override(" .. tostring(over) .. ")"
      end
    end
    if assistedKey == "VOID_BOLT" then
      isProc = true
      overlayRaw = "assisted(VOID_BOLT)"
    end
  elseif (defKey == "BLIZZARD" or defKey == "CRIMSON_TEMPEST" or defKey == "FAN_OF_KNIVES") and assistedKey == defKey then
    isProc = true
    overlayRaw = "assisted(" .. tostring(defKey) .. ")"
  end

  local hasSpellOverlayProc = isProc
  local overrideActive = false
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
    if defKey == "AMBUSH" then
      local isStealthed = _G.IsStealthed and SafeBool(_G.IsStealthed) or false
      if isStealthed then
        isProc = true
        overlayRaw = "stealth"
      elseif not hasSpellOverlayProc and not overrideActive then
        isProc = false
      end
    elseif def.inheritedBaseSlot and not overrideActive then
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

    if maxCh > 1 or defKey == "MIND_BLAST" or defKey == "TENTACLE_SLAM" then
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
      local effCD = (defKey == "VOID_BOLT") and 5.0 or (def.baseCD or 0)
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

    if defKey == "VOID_BOLT" and assistedKey and assistedKey ~= "VOID_BOLT" and assistedKey ~= "VAMPIRIC_TOUCH" then
      isOnCD = true
      charges = 0
      cdRaw = "AssistSaysOnCD(" .. tostring(assistedKey) .. ")"
    end

    if assistedKey == "MIND_FLAY" and (defKey == "MIND_BLAST" or defKey == "VOID_TORRENT" or defKey == "TENTACLE_SLAM" or defKey == "VOID_BOLT") then
      isOnCD = true
      charges = 0
      if remSec <= 0 then
        remSec = math.max(1.8, cdDur * 0.35)
      end
      cdRaw = "AssistSaysOnCD(MF)"
      if maxCh > 1 or defKey == "MIND_BLAST" or defKey == "TENTACLE_SLAM" then
        if (st.spellChargesUsed[defKey] or 0) < maxCh then
          st.spellChargesUsed[defKey] = maxCh
          st.spellChargeStart[defKey] = now - (cdDur * 0.65)
        end
        chargesRaw = "sim:0/" .. tostring(maxCh)
      end
    elseif assistedKey == "TENTACLE_SLAM" and defKey == "MIND_BLAST" and st.targetDoTsUntil and now < st.targetDoTsUntil then
      isOnCD = true
      charges = 0
      if remSec <= 0 then
        remSec = math.max(1.8, cdDur * 0.35)
      end
      cdRaw = "AssistSaysOnCD(TS)"
      if (st.spellChargesUsed[defKey] or 0) < maxCh then
        st.spellChargesUsed[defKey] = maxCh
        st.spellChargeStart[defKey] = now - (cdDur * 0.65)
      end
      chargesRaw = "sim:0/" .. tostring(maxCh)
    elseif assistedKey == "FROSTBOLT" and (defKey == "FLURRY" or defKey == "RAY_OF_FROST" or defKey == "FROZEN_ORB" or defKey == "BLIZZARD") then
      isOnCD = true
      charges = 0
      if remSec <= 0 then
        remSec = math.max(2.5, cdDur * 0.45)
        durSec = cdDur
      end
      cdRaw = "AssistSaysOnCD(FB)"
      if maxCh > 1 or defKey == "FLURRY" then
        if (st.spellChargesUsed[defKey] or 0) < maxCh then
          st.spellChargesUsed[defKey] = maxCh
          if (st.spellChargeStart[defKey] or 0) <= 0 then
            st.spellChargeStart[defKey] = now
          end
        end
        chargesRaw = "sim:0/" .. tostring(maxCh)
      end
    elseif assistedKey == "FROZEN_ORB" and (defKey == "FLURRY" or defKey == "RAY_OF_FROST") then
      isOnCD = true
      charges = 0
      if remSec <= 0 then
        remSec = math.max(2.5, cdDur * 0.45)
        durSec = cdDur
      end
      cdRaw = "AssistSaysOnCD(FO)"
      if maxCh > 1 or defKey == "FLURRY" then
        if (st.spellChargesUsed[defKey] or 0) < maxCh then
          st.spellChargesUsed[defKey] = maxCh
          if (st.spellChargeStart[defKey] or 0) <= 0 then
            st.spellChargeStart[defKey] = now
          end
        end
        chargesRaw = "sim:0/" .. tostring(maxCh)
      end
    elseif assistedKey == "ICE_LANCE" and (defKey == "RAY_OF_FROST" or defKey == "FROZEN_ORB") then
      isOnCD = true
      charges = 0
      if remSec <= 0 then
        remSec = math.max(2.5, cdDur * 0.45)
        durSec = cdDur
      end
      cdRaw = "AssistSaysOnCD(IL)"
    end
  end

  local recentlyCast = st.lastCastAt[defKey] and ((now - st.lastCastAt[defKey]) < 2.5) or false
  local isPandemicLocked = false
  if defKey == "GARROTE" and st.lastCastAt["GARROTE"] then
    local gElapsed = now - st.lastCastAt["GARROTE"]
    if gElapsed >= 0 and gElapsed < 13.0 then
      isOnCD = true
      isPandemicLocked = true
      durSec = 13.0
      startTime = st.lastCastAt["GARROTE"]
      remSec = 13.0 - gElapsed
      charges = 0
      cdRaw = string.format("pandemic:%.1fs", remSec)
    end
  elseif defKey == "CRIMSON_TEMPEST" and st.lastCastAt["CRIMSON_TEMPEST"] then
    local ctElapsed = now - st.lastCastAt["CRIMSON_TEMPEST"]
    if ctElapsed >= 0 and ctElapsed < 12.0 then
      isOnCD = true
      isPandemicLocked = true
      isProc = false
      durSec = 12.0
      startTime = st.lastCastAt["CRIMSON_TEMPEST"]
      remSec = 12.0 - ctElapsed
      charges = 0
      cdRaw = string.format("pandemic:%.1fs", remSec)
    end
  end
  if assistedKey == defKey and not recentlyCast and not isPandemicLocked then
    isOnCD = false
    local maxCh = def.liveMaxCharges or def.maxCharges or 1
    if (maxCh > 1 or defKey == "MIND_BLAST" or defKey == "TENTACLE_SLAM" or defKey == "FLURRY") and (st.spellChargesUsed[defKey] or 0) >= maxCh then
      st.spellChargesUsed[defKey] = math.max(0, maxCh - 1)
      if st.spellChargesUsed[defKey] > 0 then
        st.spellChargeStart[defKey] = now
      else
        st.spellChargeStart[defKey] = 0
      end
      charges = 1
      chargesRaw = "sim:1/" .. tostring(maxCh)
    end
    if charges < 1 then charges = 1 end
  end

  if isOnCD and remSec > 0 and durSec > 0 and (not startTime or startTime <= 0) then
    startTime = now - math.max(0, durSec - remSec)
  end

  if defKey == "VOID_BOLT" and isOnCD then
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
  if C_Spell and C_Spell.IsSpellUsable and spellID then
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
    if IsUsableAction then
      local okA, u, noM = pcall(IsUsableAction, slot)
      if okA then
        actUsableRaw = FormatSecretOrVal(u) .. "/noM=" .. FormatSecretOrVal(noM) .. (slotActiveSpellID and ("(id:" .. slotActiveSpellID .. ")") or "")
        if not IsSecret(u) and type(u) == "boolean" then
          actUsableVal = u
          actNoManaVal = (not IsSecret(noM) and noM == true) or false
        end
      end
    end
    if btBtn and btBtn.icon and btBtn.icon.GetVertexColor then
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

    if useSlotActionState then
      local btBtn = _G["BT4Button" .. slot]
      if btBtn and btBtn.icon and btBtn.icon.GetVertexColor then
        local okV, r = pcall(btBtn.icon.GetVertexColor, btBtn.icon)
        if okV and not IsSecret(r) and type(r) == "number" and r < 0.85 then
          isUsable = false
          gotCleanUsable = true
          usableSource = "BT4VertexTint(" .. btColorRaw .. ")"
        end
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
            isUsable = false
            isProc = false
            gotCleanUsable = true
            usableSource = "ComboPoints(" .. tostring(rawCP) .. "<" .. tostring(minCP) .. ")"
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
  elseif def.overrideOf and not isProc and not def.isKnown then
    finalReady = false
    isUsable = false
    usableSource = "overrideInactive(" .. tostring(def.overrideOf) .. ")"
  end

  local isStanceWrapper = (
    slotActiveSpellID == 15473
    or slotActiveSpellID == 71
    or slotActiveSpellID == 386208
    or slotActiveSpellID == 2457
    or slotActiveSpellID == 386164
  )
  local isExplicitFallback = (
    slotActiveSpellID == 589
    or slotActiveSpellID == 528
    or slotActiveSpellID == 57755
    or (slotActiveSpellID == 34914 and defKey ~= "VAMPIRIC_TOUCH" and defKey ~= "POWER_INFUSION")
  )

  if not SpArc.testMode and not isProc and not (def.overrideOf and SPELL_DEFS[def.overrideOf] and SPELL_DEFS[def.overrideOf].isKnown) then
    if slotActiveSpellID and not (def.idSet and def.idSet[slotActiveSpellID]) and not isStanceWrapper then
      if not def.isKnown or isExplicitFallback then
        isUnavailable = true
        finalReady = false
        isUsable = false
        usableSource = "TalentUnavailable(MacroFallback:" .. tostring(slotActiveSpellID) .. ")"
      end
    elseif not def.isKnown and not (slotActiveSpellID and def.idSet and def.idSet[slotActiveSpellID]) then
      isUnavailable = true
      finalReady = false
      isUsable = false
      usableSource = "SpellNotKnown"
    end
  end

  local isNoResource = false
  local resWaitSec = 0
  local isPriestSpender = (defKey == "DEVOURING_PLAGUE") or (def.isSpender and SPELL_DEFS["DEVOURING_PLAGUE"] ~= nil)
  if isUsable and not isUnavailable and not isPriestSpender then
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
  audit.isProc = isProc
  audit.isUnavailable = isUnavailable
  audit.usableSource = usableSource

  if not finalReady and def.procOnly and not isProc then
    return false, remSec, durSec, startTime, false, false, def.liveIcon or def.fallbackIcon, def.keybind or "", 0, isUnavailable, false, 0
  end

  return finalReady, remSec, durSec, startTime, isUsable, isProc, def.liveIcon or def.fallbackIcon, def.keybind or "", charges, isUnavailable, isNoResource, resWaitSec
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
  FEROCIOUS_BITE = 25,
}

local DEFAULT_DOT_IDS = { 34914, 589, 772, 388539, 1943 }
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

function SpArc:CheckTargetHasDoTs(assistedKey)
  local now = GetTime()
  local aDef = assistedKey and SPELL_DEFS[assistedKey] or nil
  local hasComboSpenderDoT = (SPELL_DEFS["RUPTURE"] ~= nil) or (SPELL_DEFS["RIP"] ~= nil)

  if hasComboSpenderDoT then
    if assistedKey == "RUPTURE" or assistedKey == "RIP" then
      if st.targetDoTsUntil and (st.targetDoTsUntil - now) > 6.0 then
        return true
      end
      return false
    end
    if assistedKey == "ENVENOM" or assistedKey == "FEROCIOUS_BITE" then
      st.targetDoTsUntil = math.max(st.targetDoTsUntil or 0, now + 6.0)
      return true
    end
    if st.targetDoTsUntil and now < st.targetDoTsUntil then
      return true
    end
  else
    if assistedKey == "VAMPIRIC_TOUCH" or (aDef and aDef.appliesDoTs and (aDef.baseCD or 0) <= 1.5) then
      return false
    end
    if st.targetDoTsUntil and now < st.targetDoTsUntil then
      return true
    end
    if assistedKey == "TENTACLE_SLAM" or (aDef and aDef.appliesDoTs) then
      return false
    end
    if assistedKey and not (aDef and aDef.appliesDoTs) then
      st.targetDoTsUntil = math.max(st.targetDoTsUntil or 0, now + 2.5)
      return true
    end
  end

  if C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID then
    for _, def in pairs(SPELL_DEFS or EMPTY_TABLE) do
      if def.appliesDoTs and def.ids then
        for _, dotID in ipairs(def.ids) do
          local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, "target", dotID)
          if ok and type(aura) == "table" then
            if not IsSecret(aura.expirationTime) and type(aura.expirationTime) == "number" and aura.expirationTime > 0 then
              if (aura.expirationTime - now) > 3.0 then
                return true
              end
            else
              return true
            end
          end
        end
      end
    end
    for _, dotID in ipairs(DEFAULT_DOT_IDS) do
      local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, "target", dotID)
      if ok and type(aura) == "table" then
        if not IsSecret(aura.expirationTime) and type(aura.expirationTime) == "number" and aura.expirationTime > 0 then
          if (aura.expirationTime - now) > 3.0 then
            return true
          end
        else
          return true
        end
      end
    end
  end

  for i = 1, 16 do
    local btn = _G["ElvUF_TargetDebuffsButton" .. i]
    if btn and SafeBool(btn.IsShown, btn) then
      local sid = btn.spellID
      if not IsSecret(sid) and (sid == 34914 or sid == 589 or sid == 772 or sid == 388539 or sid == 1943) then
        return true
      end
      local okTex, iconTex = false, nil
      if btn.Icon and btn.Icon.GetTexture then
        okTex, iconTex = pcall(btn.Icon.GetTexture, btn.Icon)
      end
      if okTex and not IsSecret(iconTex) and (iconTex == 135978 or iconTex == 136207 or iconTex == 132155 or iconTex == 132302) then
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
