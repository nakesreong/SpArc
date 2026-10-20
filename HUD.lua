---------------------------------------------------------------------------------------
--  SpArc/HUD.lua — Semicircle Rotation Arc, Cooldown Wings, Castbar & Smart Boss Tab
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc

local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local GetTime = _G.GetTime
local UnitExists = _G.UnitExists
local UnitCanAttack = _G.UnitCanAttack
local UnitIsDead = _G.UnitIsDead
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitInVehicle = _G.UnitInVehicle
local UnitCastingInfo = _G.UnitCastingInfo
local UnitChannelInfo = _G.UnitChannelInfo
local IsMounted = _G.IsMounted
local HasOverrideActionBar = _G.HasOverrideActionBar
local pcall = _G.pcall
local ipairs = _G.ipairs
local tonumber = _G.tonumber
local type = _G.type
local math = _G.math
local string = _G.string

local ApplyCyrFont = SpArc.ApplyCyrFont
local IsSecret = SpArc.IsSecret
local SafeBool = SpArc.SafeBool
local DEFAULT_VISUAL = SpArc.DEFAULT_VISUAL
local st = SpArc.state

local rootFrame = CreateFrame("Frame", "SpArcHUDRoot", UIParent)
rootFrame:SetAllPoints(UIParent)
rootFrame:SetFrameStrata("MEDIUM")
rootFrame:SetFrameLevel(20)

local function CreateStyledIconBox(parent, size, isPrimary)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(size, size)

  local glow = f:CreateTexture(nil, "BACKGROUND", nil, -2)
  glow:SetPoint("TOPLEFT", f, "TOPLEFT", -6, 6)
  glow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 6, -6)
  glow:SetColorTexture(1, 0.82, 0.18, isPrimary and 0.55 or 0)
  f.glow = glow

  local border = f:CreateTexture(nil, "BACKGROUND", nil, -1)
  border:SetPoint("TOPLEFT", f, "TOPLEFT", -2, 2)
  border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 2, -2)
  border:SetColorTexture(0.08, 0.08, 0.11, 0.95)
  f.border = border

  local icon = f:CreateTexture(nil, "ARTWORK")
  icon:SetAllPoints(f)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  f.icon = icon

  local cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
  cd:SetAllPoints(f)
  cd:SetDrawEdge(false)
  cd:SetHideCountdownNumbers(true)
  f.cd = cd

  local kb = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(kb, isPrimary and 16 or 13)
  kb:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
  kb:SetJustifyH("RIGHT")
  kb:SetTextColor(1, 0.96, 0.80, 1)
  kb:SetShadowColor(0, 0, 0, 1)
  kb:SetShadowOffset(1, -1)
  f.keybind = kb

  local timer = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(timer, 14)
  timer:SetPoint("CENTER", f, "CENTER", 0, 1)
  timer:SetTextColor(1, 0.88, 0.35, 1)
  timer:SetShadowColor(0, 0, 0, 1)
  timer:SetShadowOffset(1, -1)
  f.timer = timer

  if isPrimary then
    local banner = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(banner, 11)
    banner:SetPoint("BOTTOM", f, "TOP", 0, 4)
    banner:SetTextColor(1, 0.25, 0.65, 1)
    banner:SetText("")
    f.banner = banner
  end

  f:Hide()
  return f
end

local MAX_ARC_SLOTS = 6
local arcAnchors = {}
local arcSlots = {}
for i = 1, MAX_ARC_SLOTS do
  local anchor = CreateFrame("Frame", nil, rootFrame)
  anchor:SetSize(1, 1)
  anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
  local box = CreateStyledIconBox(anchor, 40, i == 1)
  box:SetPoint("CENTER", anchor, "CENTER", 0, 0)
  arcAnchors[i] = anchor
  arcSlots[i] = box
end

local emAnchor = CreateFrame("Frame", nil, rootFrame)
emAnchor:SetSize(1, 1)
emAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, -35)
local emergencyBox = CreateStyledIconBox(emAnchor, 62, true)
emergencyBox:SetPoint("CENTER", emAnchor, "CENTER", 0, 0)
emergencyBox.border:SetColorTexture(0.15, 1.0, 0.35, 1.0)
emergencyBox.glow:SetColorTexture(0.15, 1.0, 0.35, 0.65)
local emLabel = emergencyBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ApplyCyrFont(emLabel, 12)
emLabel:SetPoint("TOP", emergencyBox, "TOP", 0, 14)
emLabel:SetTextColor(0.25, 1.0, 0.45, 1)
emLabel:SetText("СЕЙВ!")

local savesBoxes = {}
for i = 1, 4 do
  local box = CreateStyledIconBox(rootFrame, 40, false)
  local x = -315 + (i - 1) * 46
  box:SetPoint("CENTER", UIParent, "CENTER", x, -75)
  savesBoxes[i] = box
end

local cdsBoxes = {}
for i = 1, 4 do
  local box = CreateStyledIconBox(rootFrame, 40, false)
  local x = 177 + (i - 1) * 46
  box:SetPoint("CENTER", UIParent, "CENTER", x, -75)
  cdsBoxes[i] = box
end

local castbarFrame = CreateFrame("Frame", "SpArcCastbar", rootFrame)
castbarFrame:SetSize(276, 26)
castbarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -135)

local cbBorder = castbarFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
cbBorder:SetPoint("TOPLEFT", castbarFrame, "TOPLEFT", -2, 2)
cbBorder:SetPoint("BOTTOMRIGHT", castbarFrame, "BOTTOMRIGHT", 2, -2)
cbBorder:SetColorTexture(0.06, 0.06, 0.09, 0.96)

local cbBg = castbarFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
cbBg:SetAllPoints(castbarFrame)
cbBg:SetColorTexture(0.10, 0.10, 0.15, 0.88)

local cbIcon = castbarFrame:CreateTexture(nil, "ARTWORK")
cbIcon:SetSize(26, 26)
cbIcon:SetPoint("RIGHT", castbarFrame, "LEFT", -4, 0)
cbIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local cbIconBorder = castbarFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
cbIconBorder:SetPoint("TOPLEFT", cbIcon, "TOPLEFT", -2, 2)
cbIconBorder:SetPoint("BOTTOMRIGHT", cbIcon, "BOTTOMRIGHT", 2, -2)
cbIconBorder:SetColorTexture(0.06, 0.06, 0.09, 0.96)

local cbFill = castbarFrame:CreateTexture(nil, "ARTWORK")
cbFill:SetPoint("TOPLEFT", castbarFrame, "TOPLEFT", 0, 0)
cbFill:SetPoint("BOTTOMLEFT", castbarFrame, "BOTTOMLEFT", 0, 0)
cbFill:SetWidth(1)
cbFill:SetColorTexture(0.58, 0.24, 0.94, 0.95)

local cbSpark = castbarFrame:CreateTexture(nil, "OVERLAY")
cbSpark:SetSize(14, 34)
cbSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
cbSpark:SetBlendMode("ADD")

local cbSpellText = castbarFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ApplyCyrFont(cbSpellText, 13)
cbSpellText:SetPoint("LEFT", castbarFrame, "LEFT", 8, 0)
cbSpellText:SetJustifyH("LEFT")
cbSpellText:SetTextColor(1, 0.98, 1, 1)

local cbTimeText = castbarFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ApplyCyrFont(cbTimeText, 13)
cbTimeText:SetPoint("RIGHT", castbarFrame, "RIGHT", -8, 0)
cbTimeText:SetJustifyH("RIGHT")
cbTimeText:SetTextColor(0.92, 0.92, 0.98, 1)

castbarFrame:Hide()

function SpArc:ApplyVisualLayout()
  local db = SpArc:EnsureDB()
  local v = db.visual or DEFAULT_VISUAL
  local radius = tonumber(v.arcRadius) or 135
  local offsetY = tonumber(v.arcOffsetY) or 0
  local count = math.max(3, math.min(MAX_ARC_SLOTS, tonumber(v.queueLength) or 5))
  local pScale = tonumber(v.primaryScale) or 1.50
  local qScale = tonumber(v.queueScale) or 1.00

  for i = 1, MAX_ARC_SLOTS do
    local frac = (count > 1) and ((i - 1) / (count - 1)) or 0
    local angleDeg = 150 - frac * 120
    local rad = math.rad(angleDeg)
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius + offsetY
    arcAnchors[i]:ClearAllPoints()
    arcAnchors[i]:SetPoint("CENTER", UIParent, "CENTER", x, y)
    arcSlots[i]:SetScale(i == 1 and pScale or qScale)
  end

  local cbW = tonumber(v.castbarWidth) or 276
  local cbY = tonumber(v.castbarOffsetY) or -135
  castbarFrame:SetSize(cbW, 26)
  castbarFrame:ClearAllPoints()
  castbarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, cbY)
end

SpArc:RebuildParsedProfiles()
SpArc:ApplyVisualLayout()

local function UpdateCooldownRow(boxes, spellKeys, states)
  for i = 1, #boxes do
    local box = boxes[i]
    local key = spellKeys and spellKeys[i]
    local s = key and states[key]
    if s then
      box.icon:SetTexture(s.icon)
      box.keybind:SetText(s.keybind or "")
      if s.isReady then
        box.icon:SetDesaturated(false)
        box.icon:SetAlpha(1.0)
        box.border:SetColorTexture(0.18, 0.88, 0.42, 0.95)
        box.timer:SetText("")
        box.cd:Clear()
      else
        box.icon:SetDesaturated(true)
        box.icon:SetAlpha(0.55)
        box.border:SetColorTexture(0.22, 0.22, 0.26, 0.95)
        if s.remSec and s.remSec > 0 then
          if s.remSec >= 60 then
            box.timer:SetText(string.format("%dm", math.ceil(s.remSec / 60)))
          else
            box.timer:SetText(string.format("%d", math.ceil(s.remSec)))
          end
          if s.startTime and s.startTime > 0 and s.durSec and s.durSec > 0 then
            pcall(box.cd.SetCooldown, box.cd, s.startTime, s.durSec)
          end
        else
          box.timer:SetText("")
        end
      end
      box:Show()
    else
      box:Hide()
    end
  end
end

local function UpdateCastbar(now)
  local db = SpArc:EnsureDB()
  if db.visual and db.visual.showCastbar == false then
    castbarFrame:Hide()
    return
  end

  local isCasting, isChannel = false, false
  local name, icon, startSec, endSec

  if UnitCastingInfo then
    local ok, n, _, tex, sMS, eMS = pcall(UnitCastingInfo, "player")
    if ok and not IsSecret(n) and n then
      isCasting = true
      name = n
      icon = (not IsSecret(tex) and tex) or 136208
      if not IsSecret(sMS) and not IsSecret(eMS) and type(sMS) == "number" and type(eMS) == "number" then
        startSec = sMS / 1000
        endSec = eMS / 1000
      end
    end
  end

  if not isCasting and UnitChannelInfo then
    local ok, n, _, tex, sMS, eMS = pcall(UnitChannelInfo, "player")
    if ok and not IsSecret(n) and n then
      isChannel = true
      name = n
      icon = (not IsSecret(tex) and tex) or 136208
      if not IsSecret(sMS) and not IsSecret(eMS) and type(sMS) == "number" and type(eMS) == "number" then
        startSec = sMS / 1000
        endSec = eMS / 1000
      end
    end
  end

  if (isCasting or isChannel) and (not startSec or not endSec) then
    if st.castState.active and now < st.castState.endTime then
      startSec = st.castState.startTime
      endSec = st.castState.endTime
    end
  elseif not isCasting and not isChannel and st.castState.active and now < st.castState.endTime then
    isCasting = not st.castState.isChannel
    isChannel = st.castState.isChannel
    name = st.castState.name
    icon = st.castState.icon
    startSec = st.castState.startTime
    endSec = st.castState.endTime
  end

  if SpArc.testMode and not isCasting and not isChannel then
    local cycle = now % 6
    isChannel = (cycle >= 3)
    isCasting = not isChannel
    name = isChannel and "Пытка разума (Филлер <-)" or "Прикосновение вампира (Каст ->)"
    icon = isChannel and 136208 or 135978
    startSec = now - (cycle % 3)
    endSec = startSec + 3.0
  end

  if (isCasting or isChannel) and startSec and endSec and endSec > startSec then
    local total = endSec - startSec
    local rem = math.max(0, endSec - now)
    local elapsed = math.max(0, now - startSec)
    local cbW = (db.visual and tonumber(db.visual.castbarWidth)) or 276
    local frac
    if isChannel then
      frac = math.max(0.01, math.min(1.0, rem / total))
      if st.lastShouldInterrupt and (not db.visual or db.visual.showInterruptAlert ~= false) then
        cbFill:SetColorTexture(1.0, 0.18, 0.52, 0.96)
        cbBorder:SetColorTexture(1.0, 0.25, 0.60, 1.0)
        name = "ПРЕРВИ ФИЛЛЕР -> ЖМИ [" .. (st.lastNextKeybind or "") .. "]!"
      elseif st.lastIsProtectedChannel then
        cbFill:SetColorTexture(0.12, 0.72, 0.98, 0.96)
        cbBorder:SetColorTexture(0.20, 0.85, 1.0, 1.0)
        name = (name or "Поток бездны") .. " [НЕ ПРЕРЫВАЙ]"
      else
        cbFill:SetColorTexture(0.20, 0.58, 0.96, 0.95)
        cbBorder:SetColorTexture(0.06, 0.06, 0.09, 0.96)
      end
    else
      frac = math.max(0.01, math.min(1.0, elapsed / total))
      cbFill:SetColorTexture(0.58, 0.24, 0.94, 0.95)
      cbBorder:SetColorTexture(0.06, 0.06, 0.09, 0.96)
    end
    cbFill:SetWidth(cbW * frac)
    cbSpark:ClearAllPoints()
    cbSpark:SetPoint("CENTER", cbFill, "RIGHT", 0, 0)
    cbIcon:SetTexture(icon or 136208)
    cbSpellText:SetText(name or "")
    cbTimeText:SetText(string.format("%.1f", rem))
    castbarFrame:Show()
  else
    castbarFrame:Hide()
  end
end

local lastLogicTick = 0
local lastChatCheck = 0
rootFrame:SetScript("OnUpdate", function()
  local now = GetTime()
  local db = SpArc:EnsureDB()
  local v = db.visual or DEFAULT_VISUAL
  local pScale = tonumber(v.primaryScale) or 1.50

  UpdateCastbar(now)
  if arcSlots[1]:IsShown() then
    local speed = st.lastShouldInterrupt and 12.0 or 6.0
    local amp = st.lastShouldInterrupt and 0.08 or 0.04
    arcSlots[1]:SetScale(pScale + amp * math.sin(now * speed))
  end
  if emergencyBox:IsShown() then
    emergencyBox:SetScale(1.10 + 0.07 * math.sin(now * 8.0))
  end

  if (now - lastLogicTick) < 0.07 then
    return
  end
  lastLogicTick = now

  if (now - lastChatCheck) > 2.0 then
    lastChatCheck = now
    if _G.LeftChatPanel and (not SafeBool(_G.LeftChatPanel.IsShown, _G.LeftChatPanel) or (_G.LeftChatPanel.GetAlpha and _G.LeftChatPanel:GetAlpha() < 0.9)) then
      SpArc.ForceElvUIChatAlwaysVisible()
    end
  end

  SpArc:ScanActionSlotsAndSpells(false)

  local isMounted = SafeBool(IsMounted) or SafeBool(UnitInVehicle, "player") or SafeBool(HasOverrideActionBar)
  local isDead = SafeBool(UnitIsDeadOrGhost, "player")
  if (isMounted or isDead) and not SpArc.testMode then
    for i = 1, MAX_ARC_SLOTS do arcSlots[i]:Hide() end
    for i = 1, #savesBoxes do savesBoxes[i]:Hide() end
    for i = 1, #cdsBoxes do cdsBoxes[i]:Hide() end
    emergencyBox:Hide()
    return
  end

  local hasHostileTarget = SpArc.testMode or (
    SafeBool(UnitExists, "target")
    and SafeBool(UnitCanAttack, "player", "target")
    and not SafeBool(UnitIsDead, "target")
  )
  local inCombat = SafeBool(UnitAffectingCombat, "player")
  local maxQueue = math.max(3, math.min(MAX_ARC_SLOTS, tonumber(v.queueLength) or 5))

  local queue, states, parsed, activeChannelKey, shouldInterruptChannel, isProtectedChannel = SpArc:BuildRotationQueue(maxQueue)
  st.lastShouldInterrupt = shouldInterruptChannel and (v.showInterruptAlert ~= false)
  st.lastIsProtectedChannel = isProtectedChannel
  st.lastNextKeybind = (queue[1] and queue[1].keybind) or ""
  if SpArc.RecordTelemetryTick then
    SpArc:RecordTelemetryTick(queue, states, parsed, hasHostileTarget, inCombat, activeChannelKey, shouldInterruptChannel)
  end

  -- 1. Update Top Semicircle Rotation Arc
  if hasHostileTarget then
    for i = 1, MAX_ARC_SLOTS do
      local box = arcSlots[i]
      local item = (i <= maxQueue) and queue[i] or nil
      if item then
        box.icon:SetTexture(item.icon)
        box.keybind:SetText(item.keybind or "")
        box.timer:SetText("")
        if i == 1 then
          if st.lastShouldInterrupt then
            box.border:SetColorTexture(1.0, 0.18, 0.56, 1.0)
            box.glow:SetColorTexture(1.0, 0.18, 0.56, 0.78)
            if box.banner then
              box.banner:SetTextColor(1.0, 0.30, 0.68, 1)
              box.banner:SetText("ПРЕРВИ КАСТ!")
            end
          elseif isProtectedChannel then
            box.border:SetColorTexture(0.20, 0.85, 1.0, 1.0)
            box.glow:SetColorTexture(0.20, 0.85, 1.0, 0.55)
            if box.banner then
              box.banner:SetTextColor(0.35, 0.90, 1.0, 1)
              box.banner:SetText("КАНАЛ...")
            end
          elseif item.isProc then
            box.border:SetColorTexture(0.35, 0.92, 1.0, 1.0)
            box.glow:SetColorTexture(0.35, 0.92, 1.0, 0.65)
            if box.banner then box.banner:SetText("") end
          else
            box.border:SetColorTexture(1.0, 0.80, 0.15, 1.0)
            box.glow:SetColorTexture(1.0, 0.80, 0.15, 0.55)
            if box.banner then box.banner:SetText("") end
          end
        end
        box:Show()
      else
        box:Hide()
      end
    end
  else
    for i = 1, MAX_ARC_SLOTS do
      arcSlots[i]:Hide()
    end
  end

  -- 2. Update Left Saves Row & Right Offensive CDs Row
  if hasHostileTarget or inCombat or v.alwaysShowCDs then
    UpdateCooldownRow(savesBoxes, parsed and parsed.saves, states)
    UpdateCooldownRow(cdsBoxes, parsed and parsed.cds, states)
  else
    for i = 1, #savesBoxes do savesBoxes[i]:Hide() end
    for i = 1, #cdsBoxes do cdsBoxes[i]:Hide() end
  end

  -- 3. Update Center Emergency Save
  local hpPct = SpArc:GetPlayerHPPercent()
  local emThreshold = tonumber(v.emergencyHP) or 25
  if hpPct <= emThreshold and (inCombat or hasHostileTarget or SpArc.testMode) then
    local pickedEm = nil
    for _, emKey in ipairs((parsed and parsed.emergency) or { "DISPERSION", "DESPERATE_PRAYER", "VAMPIRIC_EMBRACE" }) do
      local s = states[emKey]
      if s and s.isReady then
        pickedEm = s
        break
      end
    end
    if pickedEm then
      emergencyBox.icon:SetTexture(pickedEm.icon)
      emergencyBox.keybind:SetText(pickedEm.keybind or "")
      emergencyBox:Show()
    else
      emergencyBox:Hide()
    end
  else
    emergencyBox:Hide()
  end
end)

---------------------------------------------------------------------------------------
--                SMART BOSS TAB-TARGETING (@boss1..5 PRIORITY)                      --
---------------------------------------------------------------------------------------
local smartTabBtn = CreateFrame("Button", "SpArcSmartTabButton", UIParent, "SecureActionButtonTemplate")
smartTabBtn:RegisterForClicks("AnyDown", "AnyUp")
smartTabBtn:SetAttribute("type", "macro")
smartTabBtn:SetAttribute("macrotext", "/targetenemy\n/target [@boss1,harm,nodead][@boss2,harm,nodead][@boss3,harm,nodead][@boss4,harm,nodead][@boss5,harm,nodead]")

function SpArc:ApplySmartBossTabBinding()
  if _G.InCombatLockdown and _G.InCombatLockdown() then
    return
  end
  local db = SpArc:EnsureDB()
  local enabled = (not db.visual) or (db.visual.smartBossTab ~= false)
  if _G.ClearOverrideBindings then
    pcall(_G.ClearOverrideBindings, smartTabBtn)
  end
  if enabled and _G.SetOverrideBindingClick then
    pcall(_G.SetOverrideBindingClick, smartTabBtn, true, "TAB", "SpArcSmartTabButton", "LeftButton")
  end
end
