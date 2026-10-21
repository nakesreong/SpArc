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
local tostring = _G.tostring
local type = _G.type
local math = _G.math
local string = _G.string

local IsSecret = SpArc.IsSecret
local SafeBool = SpArc.SafeBool
local SPELL_DEFS = SpArc.SPELL_DEFS
local st = SpArc.state

function SpArc:GetTrackedSpellCharges(defKey, now)
  local def = SPELL_DEFS[defKey]
  local maxCh = (def and (def.liveMaxCharges or def.maxCharges)) or 1
  local cdDur = (def and (def.liveChargeCD or def.baseCD)) or 7.5
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
        chargesRaw = tostring(ch.currentCharges) .. "/" .. tostring(maxCh)
        st.spellChargesUsed[defKey] = math.max(0, maxCh - ch.currentCharges)
        if st.spellChargesUsed[defKey] == 0 then
          st.spellChargeStart[defKey] = 0
        elseif not IsSecret(ch.cooldownStartTime) and type(ch.cooldownStartTime) == "number" and ch.cooldownStartTime > 0 then
          st.spellChargeStart[defKey] = ch.cooldownStartTime
        end
        if ch.currentCharges >= 1 then
          isOnCD = false
        else
          isOnCD = true
          if not IsSecret(ch.cooldownStartTime) and not IsSecret(ch.cooldownDuration) then
            startTime = ch.cooldownStartTime or 0
            durSec = ch.cooldownDuration or durSec
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
        if cd.duration and cd.duration > 1.6 and cd.startTime and cd.startTime > 0 then
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

  if not gotCleanCD and slot and GetActionCooldown then
    local okA, s, d = pcall(GetActionCooldown, slot)
    if okA then
      if IsSecret(s) or IsSecret(d) then
        if cdRaw == "0s" then cdRaw = "ACT_SECRET" end
      elseif type(d) == "number" then
        gotCleanCD = true
        if d > 1.6 and s and s > 0 then
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

  if not gotCleanCD then
    local maxCh = def.liveMaxCharges or def.maxCharges or 1
    local cdDur = (def and (def.liveChargeCD or def.baseCD)) or 7.5
    if cdDur <= 0 then cdDur = 7.5 end

    if maxCh > 1 or defKey == "MIND_BLAST" or defKey == "TENTACLE_SLAM" then
      local simCh, simMax, simDur, simStart = SpArc:GetTrackedSpellCharges(defKey, now)
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
      cdRaw = "AssistSaysOnCD(TS)"
      if (st.spellChargesUsed[defKey] or 0) < maxCh then
        st.spellChargesUsed[defKey] = maxCh
        st.spellChargeStart[defKey] = now - (cdDur * 0.65)
      end
      chargesRaw = "sim:0/" .. tostring(maxCh)
    end
  end

  if assistedKey == defKey then
    isOnCD = false
    local maxCh = def.liveMaxCharges or def.maxCharges or 1
    if (maxCh > 1 or defKey == "MIND_BLAST" or defKey == "TENTACLE_SLAM") and (st.spellChargesUsed[defKey] or 0) >= maxCh then
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
  if slot then
    if GetActionInfo then
      local okAI, _, aID = pcall(GetActionInfo, slot)
      if okAI and not IsSecret(aID) and type(aID) == "number" then
        slotActiveSpellID = aID
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
    local btBtn = _G["BT4Button" .. slot]
    if btBtn and btBtn.icon and btBtn.icon.GetVertexColor then
      local okV, r, g, b = pcall(btBtn.icon.GetVertexColor, btBtn.icon)
      if okV and not IsSecret(r) and type(r) == "number" then
        btColorRaw = string.format("%.2f,%.2f,%.2f", r, g or 1, b or 1)
      end
    end
  end

  local isUsable = true
  if def.isExecute then
    local tgtHP = SpArc:GetTargetHPPercent()
    if isProc then
      isUsable = true
      usableSource = "ExecuteProcOverlay"
    elseif assistedKey == defKey then
      isUsable = true
      usableSource = "ExecuteAssistedCombat"
    elseif tgtHP and tgtHP <= 20 then
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

    if slot then
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
      local okP, rawP = pcall(UnitPower, "player", 13)
      if okP and not IsSecret(rawP) and type(rawP) == "number" then
        if rawP < 45 and not isProc and assistedKey ~= defKey then
          isUsable = false
          gotCleanUsable = true
          usableSource = "UnitPower(" .. tostring(rawP) .. "<45)"
        elseif rawP >= 50 and not gotCleanUsable then
          isUsable = true
          gotCleanUsable = true
          usableSource = "UnitPower(" .. tostring(rawP) .. ">=50)"
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

    if isProc or assistedKey == defKey then
      isUsable = true
      usableSource = isProc and "ProcOverride" or "AssistedCombat"
    end
  end

  local finalReady = (not isOnCD)
  if def.procOnly and not isProc then
    finalReady = false
    isUsable = false
    usableSource = "procOnly(false)"
  end

  if (not slot or not def.keybind or def.keybind == "") and not SpArc.testMode then
    finalReady = false
    isUsable = false
    usableSource = "NotOnActionBar"
  elseif slotActiveSpellID and (slotActiveSpellID == 528 or slotActiveSpellID == 130) and not (def.idSet and def.idSet[slotActiveSpellID]) then
    finalReady = false
    isUsable = false
    usableSource = "TalentNotKnown(MacroFallback:" .. tostring(slotActiveSpellID) .. ")"
  end

  st.lastSpellAudit[defKey] = {
    key = defKey,
    spellID = spellID,
    slot = slot,
    keybind = def.keybind or "",
    bookUsableRaw = bookUsableRaw,
    actUsableRaw = actUsableRaw,
    btColorRaw = btColorRaw,
    cdRaw = cdRaw,
    chargesRaw = chargesRaw,
    overlayRaw = overlayRaw,
    isReady = finalReady,
    isUsable = isUsable,
    isProc = isProc,
    usableSource = usableSource,
  }

  if not finalReady and def.procOnly and not isProc then
    return false, remSec, durSec, startTime, false, false, def.liveIcon or def.fallbackIcon, def.keybind or "", 0
  end

  return finalReady, remSec, durSec, startTime, isUsable, isProc, def.liveIcon or def.fallbackIcon, def.keybind or "", charges
end

function SpArc:CheckTargetHasDoTs(assistedKey)
  local now = GetTime()
  if assistedKey == "VAMPIRIC_TOUCH" then
    return false
  end
  if st.targetDoTsUntil and now < st.targetDoTsUntil then
    return true
  end
  if assistedKey == "TENTACLE_SLAM" then
    return false
  end
  if assistedKey and assistedKey ~= "TENTACLE_SLAM" and assistedKey ~= "VAMPIRIC_TOUCH" then
    return true
  end

  if C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID then
    for _, dotID in ipairs({ 34914, 589 }) do
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
      if not IsSecret(sid) and (sid == 34914 or sid == 589) then
        return true
      end
      local iconTex = btn.Icon and btn.Icon.GetTexture and btn.Icon:GetTexture()
      if not IsSecret(iconTex) and (iconTex == 135978 or iconTex == 136207) then
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
    local ok, p = pcall(UnitPower, "player", 13)
    if ok and not IsSecret(p) and type(p) == "number" then
      st.trackedInsanity = p
    end
  end
end
