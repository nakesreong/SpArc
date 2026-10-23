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

  local pressFlash = f:CreateTexture(nil, "OVERLAY", nil, 2)
  pressFlash:SetAllPoints(f)
  pressFlash:SetColorTexture(1.0, 0.92, 0.55, 0)
  pressFlash:SetBlendMode("ADD")
  f.pressFlash = pressFlash

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
  local slotLevel = 60 - (i * 5)
  local anchor = CreateFrame("Frame", nil, rootFrame)
  anchor:SetSize(1, 1)
  anchor:SetFrameLevel(slotLevel)
  anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
  local box = CreateStyledIconBox(anchor, 40, i == 1)
  box:SetFrameLevel(slotLevel + 1)
  if box.cd then
    box.cd:SetFrameLevel(slotLevel + 2)
  end
  box:SetPoint("CENTER", anchor, "CENTER", 0, 0)
  arcAnchors[i] = anchor
  arcSlots[i] = box
end

local emAnchor = CreateFrame("Frame", nil, rootFrame)
emAnchor:SetSize(1, 1)
emAnchor:SetFrameLevel(65)
emAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, -35)
local emergencyBox = CreateStyledIconBox(emAnchor, 62, true)
emergencyBox:SetFrameLevel(66)
if emergencyBox.cd then
  emergencyBox.cd:SetFrameLevel(67)
end
emergencyBox:SetPoint("CENTER", emAnchor, "CENTER", 0, 0)
emergencyBox.border:SetColorTexture(0.15, 1.0, 0.35, 1.0)
emergencyBox.glow:SetColorTexture(0.15, 1.0, 0.35, 0.65)
local emLabel = emergencyBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ApplyCyrFont(emLabel, 12)
emLabel:SetPoint("TOP", emergencyBox, "TOP", 0, 14)
emLabel:SetTextColor(0.25, 1.0, 0.45, 1)
emLabel:SetText(SpArc:L("HUD_SAVE_ALERT"))

local savesBoxes = {}
for i = 1, 4 do
  local wLevel = 45 - (i * 3)
  local box = CreateStyledIconBox(rootFrame, 40, false)
  box:SetFrameLevel(wLevel)
  if box.cd then box.cd:SetFrameLevel(wLevel + 1) end
  local x = -315 + (i - 1) * 46
  box:SetPoint("CENTER", UIParent, "CENTER", x, -75)
  savesBoxes[i] = box
end

local cdsBoxes = {}
for i = 1, 4 do
  local wLevel = 45 - (i * 3)
  local box = CreateStyledIconBox(rootFrame, 40, false)
  box:SetFrameLevel(wLevel)
  if box.cd then box.cd:SetFrameLevel(wLevel + 1) end
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
  local spreadDeg = tonumber(v.arcSpreadDeg) or 120
  local startDeg = 90 + (spreadDeg / 2)
  local offsetY = tonumber(v.arcOffsetY) or 0
  local count = math.max(3, math.min(MAX_ARC_SLOTS, tonumber(v.queueLength) or 5))
  local pScale = tonumber(v.primaryScale) or 1.50
  local qScale = tonumber(v.queueScale) or 1.00

  for i = 1, MAX_ARC_SLOTS do
    local slotLevel = 60 - (i * 5)
    local frac = (count > 1) and ((i - 1) / (count - 1)) or 0
    local angleDeg = startDeg - frac * spreadDeg
    local rad = math.rad(angleDeg)
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius + offsetY
    arcAnchors[i]:SetFrameLevel(slotLevel)
    arcSlots[i]:SetFrameLevel(slotLevel + 1)
    if arcSlots[i].cd then
      arcSlots[i].cd:SetFrameLevel(slotLevel + 2)
    end
    arcAnchors[i]:ClearAllPoints()
    arcAnchors[i]:SetPoint("CENTER", UIParent, "CENTER", x, y)
    arcSlots[i]:SetScale(i == 1 and pScale or qScale)
  end

  local wingsY = tonumber(v.wingsOffsetY) or -75
  for i = 1, 4 do
    local sx = -315 + (i - 1) * 46
    savesBoxes[i]:ClearAllPoints()
    savesBoxes[i]:SetPoint("CENTER", UIParent, "CENTER", sx, wingsY)
    local cx = 177 + (i - 1) * 46
    cdsBoxes[i]:ClearAllPoints()
    cdsBoxes[i]:SetPoint("CENTER", UIParent, "CENTER", cx, wingsY)
  end

  local cbW = tonumber(v.castbarWidth) or 276
  local cbY = tonumber(v.castbarOffsetY) or -135
  castbarFrame:SetSize(cbW, 26)
  castbarFrame:ClearAllPoints()
  castbarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, cbY)
  if emLabel then
    emLabel:SetText(SpArc:L("HUD_SAVE_ALERT"))
  end
end

SpArc:RebuildParsedProfiles()
SpArc:ApplyVisualLayout()

local function UpdateCooldownRow(boxes, spellKeys, states)
  local defs = SpArc.SPELL_DEFS
  for i = 1, #boxes do
    local box = boxes[i]
    local key = spellKeys and spellKeys[i]
    local s = key and states[key]
    if s then
      box.currentDefKey = key
      box.currentSlot = (defs and defs[key] and defs[key].slot) or nil
      box.currentKeybind = s.keybind or ""
      box.icon:SetTexture(s.icon)
      box.keybind:SetText(s.keybind or "")
      if s.isUnavailable or (not s.isUsable and s.isReady) then
        box.icon:SetDesaturated(true)
        box.icon:SetAlpha(0.35)
        box.border:SetColorTexture(0.18, 0.18, 0.22, 0.85)
        box.keybind:SetTextColor(0.52, 0.52, 0.58, 0.80)
        box.timer:SetText("")
        box.cd:Clear()
      elseif s.isReady then
        box.icon:SetDesaturated(false)
        box.icon:SetAlpha(1.0)
        box.border:SetColorTexture(0.18, 0.88, 0.42, 0.95)
        box.keybind:SetTextColor(1, 0.96, 0.80, 1)
        box.timer:SetText("")
        box.cd:Clear()
      else
        box.icon:SetDesaturated(true)
        box.icon:SetAlpha(0.55)
        box.border:SetColorTexture(0.22, 0.22, 0.26, 0.95)
        box.keybind:SetTextColor(0.80, 0.80, 0.85, 1)
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
      box.currentDefKey = nil
      box.currentSlot = nil
      box.currentKeybind = nil
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
    name = isChannel and SpArc:L("HUD_TEST_CHANNEL") or SpArc:L("HUD_TEST_CAST")
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
        name = string.format(SpArc:L("HUD_CB_CLIP"), st.lastNextKeybind or "")
      elseif st.lastIsProtectedChannel then
        cbFill:SetColorTexture(0.12, 0.72, 0.98, 0.96)
        cbBorder:SetColorTexture(0.20, 0.85, 1.0, 1.0)
        name = (name or "Void Torrent") .. SpArc:L("HUD_CB_PROTECTED")
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

local PRESS_ANIM_DUR = 0.24

local function GetPressScaleMult(box, now)
  local t0 = box.pressStartTime
  if not t0 then
    if box.pressFlash then box.pressFlash:SetAlpha(0) end
    return 1.0
  end
  local elapsed = now - t0
  if elapsed < 0 or elapsed >= PRESS_ANIM_DUR then
    box.pressStartTime = nil
    if box.pressFlash then box.pressFlash:SetAlpha(0) end
    return 1.0
  end
  local p = elapsed / PRESS_ANIM_DUR
  local mult
  if p < 0.40 then
    -- Сжатие на -20% (1.00 -> 0.80)
    local k = p / 0.40
    mult = 1.0 - 0.20 * math.sin(k * (math.pi * 0.5))
  else
    -- Отскок обратно +20% (0.80 -> 1.04 -> 1.00)
    local k = (p - 0.40) / 0.60
    mult = 0.80 + 0.20 * math.sin(k * (math.pi * 0.5)) + 0.04 * math.sin(k * math.pi)
  end
  if box.pressFlash then
    box.pressFlash:SetAlpha((1.0 - p) * 0.55)
  end
  return mult
end

local function IsSameOrPairedDefKey(a, b)
  if not a or not b then return false end
  if a == b then return true end
  if (a == "MIND_FLAY" and b == "MIND_FLAY_INSANITY") or (a == "MIND_FLAY_INSANITY" and b == "MIND_FLAY") then
    return true
  end
  if (a == "VOID_ERUPTION" and b == "VOID_BOLT") or (a == "VOID_BOLT" and b == "VOID_ERUPTION") then
    return true
  end
  return false
end

function SpArc:TriggerSpellPress(defKey, slot, keybind)
  local db = SpArc:EnsureDB()
  if db and db.visual and db.visual.enablePressFeedback == false then
    return
  end
  local now = GetTime()
  local defs = SpArc.SPELL_DEFS
  if not slot and defKey and defs and defs[defKey] then
    slot = defs[defKey].slot
  end

  local function CheckAndTriggerBox(box)
    if not box or not box:IsShown() then return false end
    local matched = false
    if defKey and box.currentDefKey and IsSameOrPairedDefKey(defKey, box.currentDefKey) then
      matched = true
    elseif slot and slot > 0 and box.currentSlot and box.currentSlot == slot then
      matched = true
    elseif not defKey and not slot and keybind and keybind ~= "" and box.currentKeybind == keybind then
      matched = true
    end
    if matched then
      if not box.pressStartTime or (now - box.pressStartTime) > 0.10 then
        box.pressStartTime = now
      end
      return true
    end
    return false
  end

  for i = 1, MAX_ARC_SLOTS do
    CheckAndTriggerBox(arcSlots[i])
  end
  for i = 1, #savesBoxes do
    CheckAndTriggerBox(savesBoxes[i])
  end
  for i = 1, #cdsBoxes do
    CheckAndTriggerBox(cdsBoxes[i])
  end
  CheckAndTriggerBox(emergencyBox)
end

local hookedBT4Buttons = {}
local function EnsureBT4PressHooks()
  for slot = 1, 180 do
    if not hookedBT4Buttons[slot] then
      local btn = _G["BT4Button" .. slot]
      if btn and btn.HookScript then
        hookedBT4Buttons[slot] = true
        local capturedSlot = slot
        pcall(btn.HookScript, btn, "PostClick", function()
          local defKey = nil
          if _G.GetActionInfo then
            local okA, aType, aID = pcall(_G.GetActionInfo, capturedSlot)
            if okA and not IsSecret(aType) and not IsSecret(aID) and aType == "spell" and type(aID) == "number" and aID > 0 then
              defKey = SpArc:MatchSpellToDefKey(aID, nil)
            end
          end
          local kb = SpArc.GetSlotKeybind and SpArc:GetSlotKeybind(capturedSlot) or nil
          SpArc:TriggerSpellPress(defKey, capturedSlot, kb)
        end)
      end
    end
  end
end

if _G.hooksecurefunc and _G.UseAction then
  _G.hooksecurefunc("UseAction", function(slot)
    if not slot or IsSecret(slot) or type(slot) ~= "number" or slot <= 0 then return end
    local defKey = nil
    if _G.GetActionInfo then
      local okA, aType, aID = pcall(_G.GetActionInfo, slot)
      if okA and not IsSecret(aType) and not IsSecret(aID) and aType == "spell" and type(aID) == "number" and aID > 0 then
        defKey = SpArc:MatchSpellToDefKey(aID, nil)
      end
    end
    local kb = SpArc.GetSlotKeybind and SpArc:GetSlotKeybind(slot) or nil
    SpArc:TriggerSpellPress(defKey, slot, kb)
  end)
end

local lastLogicTick = 0
rootFrame:SetScript("OnUpdate", function()
  local now = GetTime()
  local db = SpArc:EnsureDB()
  local v = db.visual or DEFAULT_VISUAL
  local pScale = tonumber(v.primaryScale) or 1.50
  local qScale = tonumber(v.queueScale) or 1.00

  UpdateCastbar(now)
  if arcSlots[1]:IsShown() then
    local speed = st.lastShouldInterrupt and 12.0 or 6.0
    local amp = st.lastShouldInterrupt and 0.08 or 0.04
    local mult = GetPressScaleMult(arcSlots[1], now)
    arcSlots[1]:SetScale((pScale + amp * math.sin(now * speed)) * mult)
  end
  for i = 2, MAX_ARC_SLOTS do
    if arcSlots[i]:IsShown() then
      local mult = GetPressScaleMult(arcSlots[i], now)
      arcSlots[i]:SetScale(qScale * mult)
    end
  end
  for i = 1, #savesBoxes do
    if savesBoxes[i]:IsShown() then
      local mult = GetPressScaleMult(savesBoxes[i], now)
      savesBoxes[i]:SetScale(1.0 * mult)
    end
  end
  for i = 1, #cdsBoxes do
    if cdsBoxes[i]:IsShown() then
      local mult = GetPressScaleMult(cdsBoxes[i], now)
      cdsBoxes[i]:SetScale(1.0 * mult)
    end
  end
  if emergencyBox:IsShown() then
    local mult = GetPressScaleMult(emergencyBox, now)
    emergencyBox:SetScale((1.10 + 0.07 * math.sin(now * 8.0)) * mult)
  end

  if (now - lastLogicTick) < 0.07 then
    return
  end
  lastLogicTick = now

  EnsureBT4PressHooks()
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
  local defs = SpArc.SPELL_DEFS
  if hasHostileTarget and (v.enableArcHUD ~= false) then
    for i = 1, MAX_ARC_SLOTS do
      local box = arcSlots[i]
      local item = (i <= maxQueue) and queue[i] or nil
      if item then
        box.currentDefKey = item.key
        box.currentSlot = (defs and item.key and defs[item.key] and defs[item.key].slot) or nil
        box.currentKeybind = item.keybind or ""
        box.icon:SetTexture(item.icon)
        box.keybind:SetText(item.keybind or "")
        box.timer:SetText("")
        local isDisabledArcItem = item.isUnavailable or (i == 1 and (item.isReady == false or item.isUsable == false))
        if isDisabledArcItem then
          box.icon:SetDesaturated(true)
          box.icon:SetAlpha(0.45)
          box.border:SetColorTexture(0.22, 0.22, 0.26, 0.95)
          box.glow:SetColorTexture(0, 0, 0, 0)
          if box.banner then box.banner:SetText("") end
        else
          box.icon:SetDesaturated(false)
          box.icon:SetAlpha(1.0)
          if i == 1 then
            if st.lastShouldInterrupt then
              box.border:SetColorTexture(1.0, 0.18, 0.56, 1.0)
              box.glow:SetColorTexture(1.0, 0.18, 0.56, 0.78)
              if box.banner then
                box.banner:SetTextColor(1.0, 0.30, 0.68, 1)
                box.banner:SetText(SpArc:L("HUD_CLIP_BANNER"))
              end
            elseif isProtectedChannel then
              box.border:SetColorTexture(0.20, 0.85, 1.0, 1.0)
              box.glow:SetColorTexture(0.20, 0.85, 1.0, 0.55)
              if box.banner then
                box.banner:SetTextColor(0.35, 0.90, 1.0, 1)
                box.banner:SetText(SpArc:L("HUD_CHANNEL_BANNER"))
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
          else
            box.border:SetColorTexture(0.08, 0.08, 0.11, 0.95)
            box.glow:SetColorTexture(0, 0, 0, 0)
          end
        end
        box:Show()
      else
        box.currentDefKey = nil
        box.currentSlot = nil
        box.currentKeybind = nil
        box:Hide()
      end
    end
  else
    for i = 1, MAX_ARC_SLOTS do
      arcSlots[i].currentDefKey = nil
      arcSlots[i].currentSlot = nil
      arcSlots[i].currentKeybind = nil
      arcSlots[i]:Hide()
    end
  end

  -- 2. Update Left Saves Row & Right Offensive CDs Row
  local showWingsNow = hasHostileTarget or inCombat or v.alwaysShowCDs
  if showWingsNow and v.showSavesWing ~= false then
    UpdateCooldownRow(savesBoxes, parsed and parsed.saves, states)
  else
    for i = 1, #savesBoxes do savesBoxes[i]:Hide() end
  end

  if showWingsNow and v.showCDsWing ~= false then
    UpdateCooldownRow(cdsBoxes, parsed and parsed.cds, states)
  else
    for i = 1, #cdsBoxes do cdsBoxes[i]:Hide() end
  end

  -- 3. Update Center Emergency Save
  local hpPct = SpArc:GetPlayerHPPercent()
  local emThreshold = tonumber(v.emergencyHP) or 25
  if v.showEmergencySave ~= false and hpPct <= emThreshold and (inCombat or hasHostileTarget or SpArc.testMode) then
    local pickedEm = nil
    local pickedEmKey = nil
    for _, emKey in ipairs((parsed and parsed.emergency) or { "DISPERSION", "DESPERATE_PRAYER", "VAMPIRIC_EMBRACE" }) do
      local s = states[emKey]
      if s and s.isReady and s.isUsable and not s.isUnavailable then
        pickedEm = s
        pickedEmKey = emKey
        break
      end
    end
    if pickedEm then
      emergencyBox.currentDefKey = pickedEmKey
      emergencyBox.currentSlot = (defs and pickedEmKey and defs[pickedEmKey] and defs[pickedEmKey].slot) or nil
      emergencyBox.currentKeybind = pickedEm.keybind or ""
      emergencyBox.icon:SetTexture(pickedEm.icon)
      emergencyBox.keybind:SetText(pickedEm.keybind or "")
      emergencyBox:Show()
    else
      emergencyBox.currentDefKey = nil
      emergencyBox.currentSlot = nil
      emergencyBox.currentKeybind = nil
      emergencyBox:Hide()
    end
  else
    emergencyBox.currentDefKey = nil
    emergencyBox.currentSlot = nil
    emergencyBox.currentKeybind = nil
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
