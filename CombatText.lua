-- =====================================================================================
--  SpArc — CombatText.lua (v2.9.5)
--  Module 11: MSBT Movable Scroll Zones, Tactile Haptic Numbers & Nameplate Distance Fade
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
-- =====================================================================================

local _G = _G
local SpArc = _G.SpArc

local issecretvalue = _G.issecretvalue or function() return false end
local function IsSecret(v)
  return issecretvalue(v)
end

local function SafeSetCVar(cvar, val)
  if C_CVar and C_CVar.SetCVar then
    pcall(C_CVar.SetCVar, cvar, tostring(val))
  elseif _G.SetCVar then
    pcall(_G.SetCVar, cvar, tostring(val))
  end
end

local function SafeGetCVar(cvar)
  if C_CVar and C_CVar.GetCVar then
    local ok, v = pcall(C_CVar.GetCVar, cvar)
    if ok then return v end
  elseif _G.GetCVar then
    local ok, v = pcall(_G.GetCVar, cvar)
    if ok then return v end
  end
  return nil
end

function SpArc:IsCombatTextEnabled()
  local db = SpArc:EnsureDB()
  return not (db and db.visual and db.visual.enableCombatText == false)
end

---------------------------------------------------------------------------------------
--  1. MSBT MOVABLE SCROLL ZONES ENGINE (INCOMING & OUTGOING)
---------------------------------------------------------------------------------------
local CYR_FONT = "Fonts\\FRIZQT___CYR.TTF"
local STD_FONT = "Fonts\\FRIZQT__.TTF"

local msbtContainer = nil
local msbtIncomingAnchor = nil
local msbtOutgoingAnchor = nil
local msbtPool = {}
local msbtActive = {}
local MAX_MSBT_POOL = 44
local lastSpawnTimeByZone = { INCOMING = 0, OUTGOING = 0, OVERHEAD = 0 }
local lastOverheadRawTime = 0
local demoStreamAccum = 0
local demoStep = 0

local function ApplyMSBTFont(fs, size, outline)
  local flags = outline or "OUTLINE"
  if not fs:SetFont(CYR_FONT, size, flags) then
    if not fs:SetFont(STD_FONT, size, flags) then
      fs:SetFont( STANDARD_TEXT_FONT or STD_FONT, size, flags)
    end
  end
end

local function StyleMSBTAnchorBox(frame, r, g, b)
  frame:SetSize(186, 190)
  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")

  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.05, 0.06, 0.09, 0.78)
  frame.bg = bg

  local bTop = frame:CreateTexture(nil, "BORDER")
  bTop:SetPoint("TOPLEFT", 0, 0)
  bTop:SetPoint("TOPRIGHT", 0, 0)
  bTop:SetHeight(2)
  bTop:SetColorTexture(r, g, b, 0.95)

  local bBot = frame:CreateTexture(nil, "BORDER")
  bBot:SetPoint("BOTTOMLEFT", 0, 0)
  bBot:SetPoint("BOTTOMRIGHT", 0, 0)
  bBot:SetHeight(2)
  bBot:SetColorTexture(r, g, b, 0.95)

  local bLeft = frame:CreateTexture(nil, "BORDER")
  bLeft:SetPoint("TOPLEFT", 0, 0)
  bLeft:SetPoint("BOTTOMLEFT", 0, 0)
  bLeft:SetWidth(2)
  bLeft:SetColorTexture(r, g, b, 0.95)

  local bRight = frame:CreateTexture(nil, "BORDER")
  bRight:SetPoint("TOPRIGHT", 0, 0)
  bRight:SetPoint("BOTTOMRIGHT", 0, 0)
  bRight:SetWidth(2)
  bRight:SetColorTexture(r, g, b, 0.95)

  -- Center crosshair guide inside zone
  local cHoriz = frame:CreateTexture(nil, "ARTWORK")
  cHoriz:SetSize(40, 1)
  cHoriz:SetPoint("CENTER", 0, 0)
  cHoriz:SetColorTexture(r, g, b, 0.45)

  local cVert = frame:CreateTexture(nil, "ARTWORK")
  cVert:SetSize(1, 140)
  cVert:SetPoint("CENTER", 0, 0)
  cVert:SetColorTexture(r, g, b, 0.35)

  local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyMSBTFont(lbl, 12, "OUTLINE")
  lbl:SetPoint("TOP", frame, "TOP", 0, -12)
  lbl:SetJustifyH("CENTER")
  lbl:SetTextColor(r, g, b, 1)
  frame.titleLbl = lbl

  local coordLbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyMSBTFont(coordLbl, 11, "OUTLINE")
  coordLbl:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
  coordLbl:SetTextColor(0.85, 0.90, 1.0, 0.95)
  frame.coordLbl = coordLbl
end

function SpArc:UpdateMSBTZonePositions()
  if not msbtIncomingAnchor or not msbtOutgoingAnchor then return end
  local db = SpArc:EnsureDB()
  local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL

  local incX = tonumber(vis.ctIncomingX) or -260
  local incY = tonumber(vis.ctIncomingY) or -20
  local outX = tonumber(vis.ctOutgoingX) or 260
  local outY = tonumber(vis.ctOutgoingY) or 20

  msbtIncomingAnchor:ClearAllPoints()
  msbtIncomingAnchor:SetPoint("CENTER", UIParent, "CENTER", incX, incY)
  if msbtIncomingAnchor.titleLbl then
    msbtIncomingAnchor.titleLbl:SetText(SpArc:L("M11_ZONE_INC_TITLE"))
  end
  if msbtIncomingAnchor.coordLbl then
    msbtIncomingAnchor.coordLbl:SetText(string.format("X: %d   Y: %d", incX, incY))
  end

  msbtOutgoingAnchor:ClearAllPoints()
  msbtOutgoingAnchor:SetPoint("CENTER", UIParent, "CENTER", outX, outY)
  if msbtOutgoingAnchor.titleLbl then
    msbtOutgoingAnchor.titleLbl:SetText(SpArc:L("M11_ZONE_OUT_TITLE"))
  end
  if msbtOutgoingAnchor.coordLbl then
    msbtOutgoingAnchor.coordLbl:SetText(string.format("X: %d   Y: %d", outX, outY))
  end
end

local function EnsureMSBTFrames()
  if msbtContainer then return end

  msbtContainer = CreateFrame("Frame", "SpArcMSBTContainer", UIParent)
  msbtContainer:SetAllPoints(UIParent)
  msbtContainer:SetFrameStrata("HIGH")

  -- 1. Incoming Zone Anchor (Cyan / Emerald)
  msbtIncomingAnchor = CreateFrame("Frame", "SpArcMSBTIncomingAnchor", UIParent)
  StyleMSBTAnchorBox(msbtIncomingAnchor, 0.15, 0.95, 0.65)
  msbtIncomingAnchor:Hide()

  msbtIncomingAnchor:SetScript("OnMouseUp", function(_, button)
    if button == "RightButton" then
      SpArc:SetMSBTZonesUnlocked(false)
      if SpArc.controlFrame and SpArc.controlFrame.RefreshUI and SpArc.controlFrame:IsShown() then
        SpArc.controlFrame:RefreshUI()
      end
    end
  end)
  msbtIncomingAnchor:SetScript("OnDragStart", function(self)
    self:StartMoving()
  end)
  msbtIncomingAnchor:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local cx, cy = self:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if cx and cy and ux and uy then
      local db = SpArc:EnsureDB()
      db.visual.ctIncomingX = math.floor((cx - ux) + 0.5)
      db.visual.ctIncomingY = math.floor((cy - uy) + 0.5)
      SpArc:UpdateMSBTZonePositions()
      if SpArc.controlFrame and SpArc.controlFrame.RefreshUI and SpArc.controlFrame:IsShown() then
        SpArc.controlFrame:RefreshUI()
      end
    end
  end)

  -- 2. Outgoing Zone Anchor (Gold / Arcane Orange)
  msbtOutgoingAnchor = CreateFrame("Frame", "SpArcMSBTOutgoingAnchor", UIParent)
  StyleMSBTAnchorBox(msbtOutgoingAnchor, 1.00, 0.78, 0.20)
  msbtOutgoingAnchor:Hide()

  msbtOutgoingAnchor:SetScript("OnMouseUp", function(_, button)
    if button == "RightButton" then
      SpArc:SetMSBTZonesUnlocked(false)
      if SpArc.controlFrame and SpArc.controlFrame.RefreshUI and SpArc.controlFrame:IsShown() then
        SpArc.controlFrame:RefreshUI()
      end
    end
  end)
  msbtOutgoingAnchor:SetScript("OnDragStart", function(self)
    self:StartMoving()
  end)
  msbtOutgoingAnchor:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local cx, cy = self:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if cx and cy and ux and uy then
      local db = SpArc:EnsureDB()
      db.visual.ctOutgoingX = math.floor((cx - ux) + 0.5)
      db.visual.ctOutgoingY = math.floor((cy - uy) + 0.5)
      SpArc:UpdateMSBTZonePositions()
      if SpArc.controlFrame and SpArc.controlFrame.RefreshUI and SpArc.controlFrame:IsShown() then
        SpArc.controlFrame:RefreshUI()
      end
    end
  end)

  for i = 1, MAX_MSBT_POOL do
    local fs = msbtContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ApplyMSBTFont(fs, 16, "OUTLINE")
    fs:SetShadowColor(0, 0, 0, 0.90)
    fs:SetShadowOffset(1.5, -1.5)
    fs:Hide()
    msbtPool[i] = {
      fs = fs,
      active = false,
      zone = "INCOMING",
      elapsed = 0,
      duration = 1.65,
      startX = -260,
      startY = -20,
      isCrit = false,
      baseSize = 16,
      jitterX = 0,
    }
  end

  SpArc:UpdateMSBTZonePositions()

  -- 60 FPS MSBT Trajectory Animator
  msbtContainer:SetScript("OnUpdate", function(_, dt)
    if dt > 0.1 then dt = 0.1 end

    -- Demo stream while MSBT zones are unlocked for live drag preview
    if SpArc.msbtZonesUnlocked then
      demoStreamAccum = demoStreamAccum + dt
      if demoStreamAccum >= 0.55 then
        demoStreamAccum = 0
        demoStep = (demoStep % 6) + 1
        if demoStep == 1 then
          SpArc:SpawnMSBTText("INCOMING", "+1,840", 0.20, 1.00, 0.45, false)
          SpArc:SpawnMSBTText("OUTGOING", "4,290", 1.00, 0.92, 0.30, false)
          SpArc:SpawnOverheadTargetText("4 290", false, true)
        elseif demoStep == 2 then
          SpArc:SpawnMSBTText("INCOMING", "Щит +3,100", 0.35, 0.88, 1.00, false)
          SpArc:SpawnMSBTText("OUTGOING", "* 12,650 *", 1.00, 0.45, 0.15, true)
          SpArc:SpawnOverheadTargetText("12 650", true, true)
        elseif demoStep == 3 then
          SpArc:SpawnMSBTText("INCOMING", "-920", 1.00, 0.35, 0.35, false)
          SpArc:SpawnMSBTText("OUTGOING", "2,810", 0.82, 0.55, 1.00, false)
        elseif demoStep == 4 then
          SpArc:SpawnMSBTText("INCOMING", "* +5,420 *", 0.25, 1.00, 0.55, true)
          SpArc:SpawnMSBTText("OUTGOING", "6,140", 1.00, 0.85, 0.25, false)
          SpArc:SpawnOverheadTargetText("6 140", false, true)
        elseif demoStep == 5 then
          SpArc:SpawnMSBTText("INCOMING", "+740", 0.20, 0.95, 0.45, false)
          SpArc:SpawnMSBTText("OUTGOING", "* 15,900 *", 1.00, 0.38, 0.12, true)
        else
          SpArc:SpawnMSBTText("INCOMING", "-1,350", 1.00, 0.40, 0.40, false)
          SpArc:SpawnMSBTText("OUTGOING", "3,750", 0.85, 0.60, 1.00, false)
          SpArc:SpawnOverheadTargetText("3 750", false, true)
        end
      end
    end

    if #msbtActive == 0 then return end

    local db = SpArc:EnsureDB()
    local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL
    local style = vis.ctScrollStyle or "ARC"
    local overheadBaseY = tonumber(vis.ctOverheadY) or 55
    local overheadMaxAlpha = math.max(0.20, math.min(1.00, tonumber(vis.ctOverheadAlpha) or 0.60))

    -- Resolve target nameplate anchor once per frame if any OVERHEAD numbers are active
    local targetAnchorFrame = nil
    local checkedTargetPlate = false

    for i = #msbtActive, 1, -1 do
      local item = msbtActive[i]
      item.elapsed = item.elapsed + dt
      local p = item.elapsed / item.duration

      if p >= 1 then
        item.active = false
        item.fs:Hide()
        table.remove(msbtActive, i)
      elseif item.zone == "OVERHEAD" then
        if not checkedTargetPlate then
          checkedTargetPlate = true
          if C_NamePlate and C_NamePlate.GetNamePlateForUnit then
            local okP, plate = pcall(C_NamePlate.GetNamePlateForUnit, "target")
            if okP and plate and not IsSecret(plate) and plate:IsShown() then
              targetAnchorFrame = (plate.sparcMetro and plate.sparcMetro.hpBar) or plate.sparcMetro or plate
            end
          end
        end

        local dx = item.jitterX
        local dy = p * 36
        local alpha = overheadMaxAlpha
        if p < 0.10 then
          alpha = overheadMaxAlpha * (p / 0.10)
        elseif p > 0.64 then
          alpha = math.max(0, overheadMaxAlpha * (1.0 - ((p - 0.64) / 0.36)))
        end

        if item.isCrit then
          local scale = 1.0
          if p < 0.08 then
            scale = 1.0 + (p / 0.08) * 0.16
          elseif p < 0.22 then
            scale = 1.16 - ((p - 0.08) / 0.14) * 0.16
          end
          item.fs:SetScale(scale)
        else
          item.fs:SetScale(1.0)
        end

        item.fs:ClearAllPoints()
        if targetAnchorFrame and targetAnchorFrame:IsShown() then
          item.fs:SetPoint("BOTTOM", targetAnchorFrame, "TOP", dx, overheadBaseY + dy)
        else
          item.fs:SetPoint("CENTER", UIParent, "CENTER", dx, 95 + overheadBaseY + dy)
        end
        item.fs:SetAlpha(alpha)
      else
        local dx, dy = 0, 0
        local travelH = 148
        local dir = (item.zone == "INCOMING") and -1 or 1

        if style == "UP" then
          dx = item.jitterX
          dy = (p - 0.5) * travelH
        elseif style == "FOUNTAIN" then
          dx = dir * math.sin(p * math.pi * 1.35) * 38 + item.jitterX
          dy = (p - 0.45) * travelH
        else
          -- Classic MSBT Outward Arc: Incoming curves left (away from center), Outgoing curves right
          local arcBulge = 4 * p * (1 - p) -- peaks at 1.0 when p = 0.5
          dx = dir * arcBulge * 46 + (item.jitterX * 0.4)
          dy = (p - 0.5) * travelH
        end

        -- Alpha envelope: crisp fade-in (0..0.10), solid hold, smooth fade-out (0.72..1.0)
        local alpha = 1.0
        if p < 0.10 then
          alpha = p / 0.10
        elseif p > 0.72 then
          alpha = math.max(0, 1.0 - ((p - 0.72) / 0.28))
        end

        -- Crit pop scale animation during first 0.20s
        if item.isCrit then
          local scale = 1.0
          if p < 0.08 then
            scale = 1.0 + (p / 0.08) * 0.35
          elseif p < 0.22 then
            scale = 1.35 - ((p - 0.08) / 0.14) * 0.35
          end
          item.fs:SetScale(scale)
        else
          item.fs:SetScale(1.0)
        end

        item.fs:ClearAllPoints()
        item.fs:SetPoint("CENTER", UIParent, "CENTER", item.startX + dx, item.startY + dy)
        item.fs:SetAlpha(alpha)
      end
    end
  end)
end

function SpArc:SpawnOverheadTargetText(textValue, isCrit, isPreview)
  if not SpArc:IsCombatTextEnabled() then return end
  EnsureMSBTFrames()

  local db = SpArc:EnsureDB()
  local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL
  if vis.ctShowDirectDamage == false and not isPreview then
    return
  end

  local now = GetTime and GetTime() or 0
  if not isPreview then
    local mode = vis.ctDotTickMode or "AUTO_AOE"
    if not isCrit and (mode == "OFF" or (mode == "AUTO_AOE" and (lastCombatPlateCount or 0) >= 3)) then
      if (now - lastOverheadRawTime) < 0.42 then
        return
      end
    end
    lastOverheadRawTime = now
  end

  local entry = nil
  for i = 1, MAX_MSBT_POOL do
    if not msbtPool[i].active then
      entry = msbtPool[i]
      break
    end
  end
  if not entry then
    entry = table.remove(msbtActive, 1)
  end
  if not entry then return end

  local prevT = lastSpawnTimeByZone["OVERHEAD"] or 0
  if (now - prevT) < 0.14 then
    for j = 1, #msbtActive do
      local act = msbtActive[j]
      if act.zone == "OVERHEAD" and act.elapsed < 0.22 then
        act.elapsed = act.elapsed + 0.14
      end
    end
  end
  lastSpawnTimeByZone["OVERHEAD"] = now

  local worldScale = tonumber(vis.ctWorldTextScale) or 0.65
  local baseSize = math.max(9, math.min(22, math.floor(18 * worldScale + 0.5)))
  local finalSize = isCrit and math.min(26, baseSize + 2) or baseSize
  ApplyMSBTFont(entry.fs, finalSize, "OUTLINE")
  entry.fs:SetShadowColor(0, 0, 0, 0.55)
  entry.fs:SetShadowOffset(1.0, -1.0)

  local okText = pcall(entry.fs.SetText, entry.fs, textValue)
  if not okText then
    return
  end

  -- Soft, warm muted yellow-gold (never blinding #FFFF00)
  if isCrit then
    entry.fs:SetTextColor(1.00, 0.78, 0.24, 1.0)
  else
    entry.fs:SetTextColor(0.95, 0.84, 0.32, 1.0)
  end

  local maxAlpha = math.max(0.20, math.min(1.00, tonumber(vis.ctOverheadAlpha) or 0.60))
  local baseOffsetY = tonumber(vis.ctOverheadY) or 55

  entry.active = true
  entry.zone = "OVERHEAD"
  entry.elapsed = 0
  entry.duration = 1.25
  entry.isCrit = isCrit and true or false
  entry.baseSize = finalSize
  entry.jitterX = math.random(-9, 9)

  entry.fs:ClearAllPoints()
  local anchorFrame = nil
  if C_NamePlate and C_NamePlate.GetNamePlateForUnit then
    local okP, plate = pcall(C_NamePlate.GetNamePlateForUnit, "target")
    if okP and plate and not IsSecret(plate) and plate:IsShown() then
      anchorFrame = (plate.sparcMetro and plate.sparcMetro.hpBar) or plate.sparcMetro or plate
    end
  end
  if anchorFrame and anchorFrame:IsShown() then
    entry.fs:SetPoint("BOTTOM", anchorFrame, "TOP", entry.jitterX, baseOffsetY)
  else
    entry.fs:SetPoint("CENTER", UIParent, "CENTER", entry.jitterX, 95 + baseOffsetY)
  end
  entry.fs:SetAlpha(maxAlpha)
  entry.fs:Show()

  msbtActive[#msbtActive + 1] = entry
end

function SpArc:SpawnMSBTText(zone, textValue, r, g, b, isCrit)
  if not SpArc:IsCombatTextEnabled() then return end
  EnsureMSBTFrames()

  local db = SpArc:EnsureDB()
  local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL

  if zone == "INCOMING" and vis.ctShowIncomingZone == false and not SpArc.msbtZonesUnlocked then
    return
  end
  if zone == "OUTGOING" and vis.ctShowOutgoingZone == false and not SpArc.msbtZonesUnlocked then
    return
  end

  -- Acquire pool entry (or recycle oldest active entry)
  local entry = nil
  for i = 1, MAX_MSBT_POOL do
    if not msbtPool[i].active then
      entry = msbtPool[i]
      break
    end
  end
  if not entry then
    entry = table.remove(msbtActive, 1)
  end
  if not entry then return end

  local now = GetTime and GetTime() or 0
  local prevT = lastSpawnTimeByZone[zone] or 0
  -- Anti-collision stagger if multiple numbers arrive in the same 0.09s window
  local initialElapsed = 0
  if (now - prevT) < 0.09 then
    for j = 1, #msbtActive do
      local act = msbtActive[j]
      if act.zone == zone and act.elapsed < 0.16 then
        act.elapsed = act.elapsed + 0.11
      end
    end
  end
  lastSpawnTimeByZone[zone] = now

  local baseFontSize = tonumber(vis.ctFontSize) or 16
  local finalSize = isCrit and math.min(34, math.floor(baseFontSize * 1.28 + 0.5)) or baseFontSize
  ApplyMSBTFont(entry.fs, finalSize, isCrit and "THICKOUTLINE" or "OUTLINE")

  -- Midnight 12.0 Secret-Value Safe SetText
  local okText = pcall(entry.fs.SetText, entry.fs, textValue)
  if not okText then
    return
  end

  local cr = (not IsSecret(r) and tonumber(r)) or 1.0
  local cg = (not IsSecret(g) and tonumber(g)) or 0.90
  local cb = (not IsSecret(b) and tonumber(b)) or 0.30
  entry.fs:SetTextColor(cr, cg, cb, 1.0)

  entry.active = true
  entry.zone = zone
  entry.elapsed = initialElapsed
  entry.duration = isCrit and 1.85 or 1.55
  entry.isCrit = isCrit and true or false
  entry.baseSize = finalSize
  entry.jitterX = math.random(-8, 8)

  if zone == "INCOMING" then
    entry.startX = tonumber(vis.ctIncomingX) or -260
    entry.startY = tonumber(vis.ctIncomingY) or -20
  else
    entry.startX = tonumber(vis.ctOutgoingX) or 260
    entry.startY = tonumber(vis.ctOutgoingY) or 20
  end

  entry.fs:ClearAllPoints()
  entry.fs:SetPoint("CENTER", UIParent, "CENTER", entry.startX, entry.startY - 70)
  entry.fs:SetAlpha(1.0)
  entry.fs:Show()

  msbtActive[#msbtActive + 1] = entry
end

function SpArc:SetMSBTZonesUnlocked(unlocked)
  EnsureMSBTFrames()
  SpArc.msbtZonesUnlocked = unlocked and true or false
  SpArc:UpdateMSBTZonePositions()
  if SpArc.msbtZonesUnlocked then
    msbtIncomingAnchor:Show()
    msbtOutgoingAnchor:Show()
    demoStreamAccum = 0.50
  else
    msbtIncomingAnchor:Hide()
    msbtOutgoingAnchor:Hide()
  end
end

function SpArc:TriggerMSBTTestFountain()
  EnsureMSBTFrames()
  SpArc:UpdateMSBTZonePositions()
  local samples = {
    { delay = 0.00, zone = "INCOMING", txt = "+2,140",       r = 0.20, g = 1.00, b = 0.45, crit = false },
    { delay = 0.05, zone = "OUTGOING", txt = "4,820",        r = 1.00, g = 0.90, b = 0.30, crit = false, overhead = "4 820" },
    { delay = 0.22, zone = "INCOMING", txt = "Щит +3,850",   r = 0.35, g = 0.90, b = 1.00, crit = false },
    { delay = 0.28, zone = "OUTGOING", txt = "* 14,920 *",   r = 1.00, g = 0.42, b = 0.15, crit = true,  overhead = "14 920" },
    { delay = 0.46, zone = "INCOMING", txt = "-1,120",       r = 1.00, g = 0.35, b = 0.35, crit = false },
    { delay = 0.52, zone = "OUTGOING", txt = "6,310",        r = 0.82, g = 0.55, b = 1.00, crit = false, overhead = "6 310" },
    { delay = 0.70, zone = "INCOMING", txt = "* +6,700 *",   r = 0.25, g = 1.00, b = 0.55, crit = true  },
    { delay = 0.76, zone = "OUTGOING", txt = "* 19,450 *",   r = 1.00, g = 0.35, b = 0.10, crit = true,  overhead = "19 450" },
  }
  for _, s in ipairs(samples) do
    if C_Timer and C_Timer.After then
      C_Timer.After(s.delay, function()
        SpArc:SpawnMSBTText(s.zone, s.txt, s.r, s.g, s.b, s.crit)
        if s.overhead then
          SpArc:SpawnOverheadTargetText(s.overhead, s.crit, true)
        end
      end)
    else
      SpArc:SpawnMSBTText(s.zone, s.txt, s.r, s.g, s.b, s.crit)
      if s.overhead then
        SpArc:SpawnOverheadTargetText(s.overhead, s.crit, true)
      end
    end
  end
end

---------------------------------------------------------------------------------------
--  2. ACTIVE COMBAT ENEMY COUNTER & SMART AOE PERIODIC DOT FILTER
---------------------------------------------------------------------------------------
local lastAppliedPeriodicVal = nil
local lastCombatPlateCount = 0
local pendingPostCombatCVars = false
local combatTextHooked = false
local windToolsHooked = false
local lastBlizzIncomingTime = 0

function SpArc:CountActiveCombatEnemyPlates()
  if not (C_NamePlate and C_NamePlate.GetNamePlates) then
    return 0
  end
  local ok, plates = pcall(C_NamePlate.GetNamePlates)
  if not ok or type(plates) ~= "table" then
    return 0
  end
  local count = 0
  for i = 1, #plates do
    local plate = plates[i]
    local unit = plate and (plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit))
    if unit and UnitExists(unit) and UnitCanAttack("player", unit) then
      local dead = UnitIsDeadOrGhost(unit)
      if not IsSecret(dead) and not dead then
        local inCombat = UnitAffectingCombat(unit)
        local isTarget = UnitIsUnit(unit, "target")
        if (not IsSecret(inCombat) and inCombat) or (not IsSecret(isTarget) and isTarget) then
          count = count + 1
        end
      end
    end
  end
  lastCombatPlateCount = count
  return count
end

function SpArc:UpdateDynamicAoEPeriodicFilter(forceApply)
  if not SpArc:IsCombatTextEnabled() then return end
  SpArc:CountActiveCombatEnemyPlates()
  if forceApply or lastAppliedPeriodicVal ~= "0" then
    SafeSetCVar("floatingCombatTextCombatDamage", "0")
    SafeSetCVar("floatingCombatTextCombatLogPeriodicSpells", "0")
    lastAppliedPeriodicVal = "0"
  end
end

---------------------------------------------------------------------------------------
--  3. BLIZZARD FLOATING COMBAT TEXT, MSBT CAPTURE & WINDTOOLS ALERT SUPPRESSION
---------------------------------------------------------------------------------------
local function SyncBlizzardScrollingCombatText(hidePlayerScrolling, showIncomingMSBT)
  -- If Incoming MSBT Zone is active, keep enableFloatingCombatText = 1 so Blizzard feeds heals/absorbs
  -- into CombatText_AddMessage, and we intercept + wipe the center column so it never draws over the player!
  if showIncomingMSBT or not hidePlayerScrolling then
    SafeSetCVar("enableFloatingCombatText", "1")
  else
    SafeSetCVar("enableFloatingCombatText", "0")
  end

  local ctFrame = _G.CombatText
  if ctFrame then
    if hidePlayerScrolling then
      pcall(ctFrame.SetAlpha, ctFrame, 0)
    else
      pcall(ctFrame.SetAlpha, ctFrame, 1)
      pcall(ctFrame.Show, ctFrame)
      if type(_G.COMBAT_TEXT_LOCATIONS) == "table" then
        local db = SpArc:EnsureDB()
        local incX = (db and db.visual and tonumber(db.visual.ctIncomingX)) or -260
        _G.COMBAT_TEXT_LOCATIONS.startX = incX
        _G.COMBAT_TEXT_LOCATIONS.endX = incX
      end
    end
  end

  if not combatTextHooked and type(_G.CombatText_AddMessage) == "function" then
    combatTextHooked = true
    pcall(_G.hooksecurefunc, "CombatText_AddMessage", function(message, _, r, g, b, displayType)
      if not SpArc:IsCombatTextEnabled() then return end
      local db = SpArc:EnsureDB()
      local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL

      -- 1. Forward to MSBT Incoming Scroll Zone if enabled
      if vis.ctShowIncomingZone ~= false and message ~= nil then
        local skipAlert = false
        if not IsSecret(message) and type(message) == "string" then
          if vis.ctSuppressAlerts ~= false then
            if message == _G.ENTERING_COMBAT or message == _G.LEAVING_COMBAT then
              skipAlert = true
            end
          end
        end
        if not skipAlert then
          local isCrit = (not IsSecret(displayType)) and (displayType == "crit")
          lastBlizzIncomingTime = GetTime and GetTime() or 0
          SpArc:SpawnMSBTText("INCOMING", message, r, g, b, isCrit)
        end
      end

      -- 2. Wipe Blizzard's center column so nothing ever covers the character or Rotation Arc
      if vis.ctHidePlayerScrolling ~= false and _G.CombatText then
        pcall(_G.CombatText.SetAlpha, _G.CombatText, 0)
        if type(_G.COMBAT_TEXT_TO_ANIMATE) == "table" then
          wipe(_G.COMBAT_TEXT_TO_ANIMATE)
        end
      end
    end)
  end
end

local function SyncWindToolsAndCenterAlerts(suppressAlerts)
  if not suppressAlerts then return end

  -- Suppress ElvUI_WindTools CombatAlert (giant shield / crossed swords + "Вход в бой" in center screen)
  local WT = _G.WindTools
  local W = type(WT) == "table" and WT[1]
  if W and type(W.GetModule) == "function" then
    local ok, CA = pcall(W.GetModule, W, "CombatAlert")
    if ok and CA then
      if CA.db then
        CA.db.enable = false
        CA.db.animation = false
        CA.db.text = false
      end
      if _G.ElvUI and type(_G.ElvUI[1]) == "table" then
        local E = _G.ElvUI[1]
        if E.db and E.db.WT and E.db.WT.combat and E.db.WT.combat.combatAlert then
          E.db.WT.combat.combatAlert.enable = false
        end
      end
      if CA.UnregisterEvent then
        pcall(CA.UnregisterEvent, CA, "PLAYER_REGEN_ENABLED")
        pcall(CA.UnregisterEvent, CA, "PLAYER_REGEN_DISABLED")
      end
      if CA.alert then
        pcall(CA.alert.Hide, CA.alert)
        pcall(CA.alert.SetAlpha, CA.alert, 0)
      end
      if not windToolsHooked then
        windToolsHooked = true
        if type(CA.ShowAlert) == "function" then
          pcall(_G.hooksecurefunc, CA, "ShowAlert", function(self)
            local db = SpArc:EnsureDB()
            if SpArc:IsCombatTextEnabled() and db and db.visual and db.visual.ctSuppressAlerts ~= false then
              if self.alert then
                pcall(self.alert.Hide, self.alert)
                pcall(self.alert.SetAlpha, self.alert, 0)
              end
            end
          end)
        end
        if type(CA.PLAYER_REGEN_DISABLED) == "function" then
          CA.PLAYER_REGEN_DISABLED = function() end
        end
        if type(CA.PLAYER_REGEN_ENABLED) == "function" then
          CA.PLAYER_REGEN_ENABLED = function() end
        end
      end
    end
  end
end

local function HandleUnitCombatForMSBT(unit, action, flags, amount, school)
  if not SpArc:IsCombatTextEnabled() then return end
  if IsSecret(unit) then return end
  if unit ~= "target" and unit ~= "player" then return end

  local db = SpArc:EnsureDB()
  local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL

  local isCrit = (not IsSecret(flags)) and (flags == "CRITICAL" or flags == "CRUSHING")
  local act = (not IsSecret(action)) and action or "WOUND"

  if unit == "target" then
    local wantMSBT = (vis.ctShowOutgoingZone ~= false)
    local wantOverhead = (vis.ctShowDirectDamage ~= false)
    if not wantMSBT and not wantOverhead then return end
    if act == "HEAL" or act == "ENERGIZE" then return end
    if act == "MISS" or act == "DODGE" or act == "PARRY" or act == "IMMUNE" then
      if vis.ctHideDodgeParryMiss ~= false then return end
      if wantMSBT then
        SpArc:SpawnMSBTText("OUTGOING", tostring(act), 0.75, 0.78, 0.85, false)
      end
      return
    end
    if amount == nil then return end

    local r, g, b = 1.00, 0.88, 0.28
    if isCrit then
      r, g, b = 1.00, 0.42, 0.14
    elseif not IsSecret(school) and type(school) == "number" and school > 1 then
      -- Shadow / Arcane / Elemental tint for spell hits
      if bit and bit.band and bit.band(school, 32) ~= 0 then
        r, g, b = 0.82, 0.52, 1.00 -- Shadow
      elseif bit and bit.band and bit.band(school, 64) ~= 0 then
        r, g, b = 0.55, 0.82, 1.00 -- Arcane
      end
    end

    if not IsSecret(amount) and type(amount) == "number" then
      if amount <= 0 then return end
      local cleanTxt = (_G.BreakUpLargeNumbers and _G.BreakUpLargeNumbers(amount)) or tostring(amount)
      if wantOverhead then
        SpArc:SpawnOverheadTargetText(cleanTxt, isCrit, false)
      end
      if wantMSBT then
        local msbtTxt = isCrit and ("* " .. cleanTxt .. " *") or cleanTxt
        SpArc:SpawnMSBTText("OUTGOING", msbtTxt, r, g, b, isCrit)
      end
    else
      if wantOverhead then
        SpArc:SpawnOverheadTargetText(amount, isCrit, false)
      end
      if wantMSBT then
        SpArc:SpawnMSBTText("OUTGOING", amount, r, g, b, isCrit)
      end
    end
  elseif unit == "player" then
    if vis.ctShowIncomingZone == false then return end
    -- Avoid duplicating if Blizzard_CombatText already forwarded this event within the last 0.05s
    local now = GetTime and GetTime() or 0
    if combatTextHooked and (now - lastBlizzIncomingTime) < 0.05 then
      return
    end
    if amount == nil then return end
    local r, g, b = 1.00, 0.35, 0.35
    local prefix = "-"
    if act == "HEAL" then
      r, g, b = 0.22, 1.00, 0.48
      prefix = "+"
    elseif act == "ABSORB" then
      r, g, b = 0.35, 0.90, 1.00
      prefix = "+"
    end
    if not IsSecret(amount) and type(amount) == "number" then
      if amount <= 0 then return end
      local txt = prefix .. ((_G.BreakUpLargeNumbers and _G.BreakUpLargeNumbers(amount)) or tostring(amount))
      if isCrit then txt = "* " .. txt .. " *" end
      SpArc:SpawnMSBTText("INCOMING", txt, r, g, b, isCrit)
    else
      SpArc:SpawnMSBTText("INCOMING", amount, r, g, b, isCrit)
    end
  end
end

---------------------------------------------------------------------------------------
--  4. MASTER APPLY FUNCTION (CVARS, MSBT ZONES, NAMEPLATE DISTANCE & FADING)
---------------------------------------------------------------------------------------
function SpArc:ApplyCombatTextSettings()
  EnsureMSBTFrames()
  SpArc:UpdateMSBTZonePositions()

  if not SpArc:IsCombatTextEnabled() then
    return
  end

  local db = SpArc:EnsureDB()
  local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL

  local hidePlayer = (vis.ctHidePlayerScrolling ~= false)
  local showIncMSBT = (vis.ctShowIncomingZone ~= false)
  local suppressAlerts = (vis.ctSuppressAlerts ~= false)
  local showDirect = (vis.ctShowDirectDamage ~= false)
  local hidePet = (vis.ctHidePetDamage ~= false)
  local hideHeal = (vis.ctHideWorldHealing ~= false)
  local hideMiss = (vis.ctHideDodgeParryMiss ~= false)
  local worldScale = tonumber(vis.ctWorldTextScale) or 0.65
  local dirScale = math.floor((tonumber(vis.ctDirectionalScale) or 0) + 0.5)
  local spreadNP = (vis.ctSpreadNameplates ~= false)
  local overlapV = tonumber(vis.ctNameplateOverlapV) or 1.35
  local overlapH = tonumber(vis.ctNameplateOverlapH) or 0.90

  -- 1. Center HUD, MSBT Hook & Alert Suppression
  SyncBlizzardScrollingCombatText(hidePlayer, showIncMSBT)
  SyncWindToolsAndCenterAlerts(suppressAlerts)

  if suppressAlerts then
    SafeSetCVar("floatingCombatTextCombatState", "0")
    SafeSetCVar("floatingCombatTextReactives", "0")
    SafeSetCVar("floatingCombatTextFriendlyHealers", "0")
    SafeSetCVar("floatingCombatTextComboPoints", "0")
    SafeSetCVar("floatingCombatTextEnergyGains", "0")
    SafeSetCVar("floatingCombatTextPeriodicEnergyGains", "0")
    SafeSetCVar("floatingCombatTextHonorGains", "0")
    SafeSetCVar("floatingCombatTextAuras", "0")
    SafeSetCVar("floatingCombatTextLowManaHealth", "0")
  else
    SafeSetCVar("floatingCombatTextCombatState", "1")
    SafeSetCVar("floatingCombatTextReactives", "1")
  end

  -- 2. Center Target Haptic Numbers (rendered by SpArc with custom alpha, smaller font & high Y offset)
  -- Turn off Blizzard's un-dimmable 100%-bright #FFFF00 3D text so it never sits on the character's head
  SafeSetCVar("floatingCombatTextCombatDamage", "0")
  SafeSetCVar("floatingCombatTextCombatLogPeriodicSpells", "0")
  SafeSetCVar("floatingCombatTextPetMeleeDamage", (showDirect and not hidePet) and "1" or "0")
  SafeSetCVar("floatingCombatTextPetSpellDamage", (showDirect and not hidePet) and "1" or "0")

  SafeSetCVar("floatingCombatTextCombatHealing", hideHeal and "0" or "1")
  SafeSetCVar("floatingCombatTextCombatHealingAbsorbTarget", hideHeal and "0" or "1")
  SafeSetCVar("floatingCombatTextCombatHealingAbsorbSelf", hideHeal and "0" or "1")
  SafeSetCVar("floatingCombatTextDodgeParryMiss", hideMiss and "0" or "1")

  -- 3. Number Scale & Fountain Spread
  SafeSetCVar("WorldTextScale", string.format("%.2f", math.max(0.40, math.min(1.50, worldScale))))
  SafeSetCVar("WorldTextRampPow", "1.0")
  SafeSetCVar("WorldTextRampPowCrit", "1.5")
  SafeSetCVar("floatingCombatTextCombatDamageDirectionalScale", tostring(math.max(0, math.min(2, dirScale))))
  SafeSetCVar("floatingCombatTextFloatMode", "1")

  -- 4. Periodic DoT Ticks (Smart AoE / ON / OFF)
  SpArc:CountActiveCombatEnemyPlates()

  -- 5. Nameplate View Distance, Distance Fade & Stacking Anti-Overlap
  if SpArc.SyncExternalNameplateAddons then
    SpArc:SyncExternalNameplateAddons()
  end
  if SpArc.RefreshAllNameplates then
    SpArc:RefreshAllNameplates()
  end

  if InCombatLockdown and InCombatLockdown() then
    pendingPostCombatCVars = true
  else
    pendingPostCombatCVars = false
    if spreadNP then
      SafeSetCVar("nameplateMotion", "1")
      SafeSetCVar("nameplateOverlapV", string.format("%.2f", math.max(0.50, math.min(2.20, overlapV))))
      SafeSetCVar("nameplateOverlapH", string.format("%.2f", math.max(0.40, math.min(1.80, overlapH))))
    end
  end
end

function SpArc:ApplyCleanHapticPreset()
  local db = SpArc:EnsureDB()
  local vis = db.visual
  vis.enableCombatText = true
  vis.ctShowIncomingZone = true
  vis.ctShowOutgoingZone = true
  vis.ctIncomingX = -260
  vis.ctIncomingY = -20
  vis.ctOutgoingX = 260
  vis.ctOutgoingY = 20
  vis.ctScrollStyle = "ARC"
  vis.ctFontSize = 16
  vis.ctHidePlayerScrolling = true
  vis.ctSuppressAlerts = true
  vis.ctShowDirectDamage = true
  vis.ctDotTickMode = "AUTO_AOE"
  vis.ctHidePetDamage = true
  vis.ctHideWorldHealing = true
  vis.ctHideDodgeParryMiss = true
  vis.ctWorldTextScale = 0.65
  vis.ctOverheadAlpha = 0.60
  vis.ctOverheadY = 55
  vis.ctDirectionalScale = 0
  vis.ctSpreadNameplates = true
  vis.ctNameplateOverlapV = 1.35
  vis.ctNameplateOverlapH = 0.90
  vis.npMaxDistance = 40
  vis.npDistanceFade = true
  vis.npMinAlpha = 0.30
  SpArc:ApplyCombatTextSettings()
end

function SpArc:RestoreBlizzardCombatTextDefaults()
  local db = SpArc:EnsureDB()
  local vis = db.visual
  vis.ctShowIncomingZone = false
  vis.ctShowOutgoingZone = false
  vis.ctHidePlayerScrolling = false
  vis.ctSuppressAlerts = false
  vis.ctShowDirectDamage = true
  vis.ctDotTickMode = "ON"
  vis.ctHidePetDamage = false
  vis.ctHideWorldHealing = false
  vis.ctHideDodgeParryMiss = false
  vis.ctWorldTextScale = 1.00
  vis.ctDirectionalScale = 1
  vis.ctSpreadNameplates = true
  vis.ctNameplateOverlapV = 1.10
  vis.ctNameplateOverlapH = 0.80
  vis.npMaxDistance = 60
  vis.npDistanceFade = false
  vis.npMinAlpha = 0.90
  SpArc:ApplyCombatTextSettings()
end

---------------------------------------------------------------------------------------
--  5. EVENT WATCHER (UNIT_COMBAT, NAMEPLATE COUNTING, COMBAT STATE & ADDON LOADED)
---------------------------------------------------------------------------------------
local ctEventFrame = CreateFrame("Frame")
ctEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
ctEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
ctEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
ctEventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
ctEventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
ctEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
ctEventFrame:RegisterEvent("UNIT_COMBAT")
ctEventFrame:RegisterEvent("ADDON_LOADED")

ctEventFrame:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4, arg5)
  if event == "UNIT_COMBAT" then
    HandleUnitCombatForMSBT(arg1, arg2, arg3, arg4, arg5)
    return
  end

  if event == "ADDON_LOADED" then
    if arg1 == "Blizzard_CombatText" or arg1 == "ElvUI_WindTools" then
      SpArc:ApplyCombatTextSettings()
    end
    return
  end

  if event == "PLAYER_ENTERING_WORLD" then
    SpArc:ApplyCombatTextSettings()
    if C_Timer and C_Timer.After then
      C_Timer.After(1.5, function()
        SpArc:ApplyCombatTextSettings()
      end)
    end
    return
  end

  if event == "PLAYER_REGEN_ENABLED" then
    if pendingPostCombatCVars then
      SpArc:ApplyCombatTextSettings()
    else
      SpArc:UpdateDynamicAoEPeriodicFilter(false)
    end
    return
  end

  SpArc:UpdateDynamicAoEPeriodicFilter(false)
end)

local ctAccum = 0
ctEventFrame:SetScript("OnUpdate", function(_, elapsed)
  ctAccum = ctAccum + (elapsed or 0)
  if ctAccum < 0.60 then return end
  ctAccum = 0
  if not SpArc:IsCombatTextEnabled() then return end
  SpArc:UpdateDynamicAoEPeriodicFilter(false)
  if SpArc.controlFrame and SpArc.controlFrame:IsShown() and SpArc.controlFrame.ui and SpArc.controlFrame.ui.m11StatusTxt then
    local ui = SpArc.controlFrame.ui
    if ui.m11StatusTxt:IsVisible() then
      SpArc:RefreshCombatTextPage(ui)
    end
  end
end)

---------------------------------------------------------------------------------------
--  6. CONTROL CENTER UI PAGE (TAB 11: MSBT ZONES, COMBAT TEXT & DISTANCE FADE)
---------------------------------------------------------------------------------------
function SpArc:BuildCombatTextPage(page, ui, helpers)
  local ApplyCyrFont = helpers.ApplyCyrFont
  local CreateElvButton = helpers.CreateElvButton
  local RegisterGroupBox = helpers.RegisterGroupBox
  local CreateElvCheck = helpers.CreateElvCheck
  local CreateElvSlider = helpers.CreateElvSlider
  local StyleToggleButton = helpers.StyleToggleButton
  local controlFrame = helpers.controlFrame

  ui.m11Title = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(ui.m11Title, 15)
  ui.m11Title:SetPoint("TOPLEFT", 0, 0)
  ui.m11Title:SetTextColor(1, 0.85, 0.25, 1)

  -- Top Row: Master Enable + Move MSBT Zones + Test Fountain + Clean Haptic Preset
  local cEnable = CreateElvCheck(page, "MOD_ENABLE", "enableCombatText", 0, -22, true, false, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
  end)
  cEnable:SetWidth(105)

  local btnUnlock = CreateElvButton(page, 228, 22, "")
  btnUnlock:SetPoint("TOPLEFT", page, "TOPLEFT", 110, -22)
  btnUnlock:SetScript("OnClick", function()
    SpArc:SetMSBTZonesUnlocked(not SpArc.msbtZonesUnlocked)
    SpArc:RefreshCombatTextPage(ui)
  end)
  ui.m11UnlockBtn = btnUnlock

  local btnTest = CreateElvButton(page, 148, 22, "")
  btnTest:SetPoint("LEFT", btnUnlock, "RIGHT", 6, 0)
  btnTest:SetScript("OnClick", function()
    SpArc:TriggerMSBTTestFountain()
  end)
  ui.m11TestBtn = btnTest

  local btnHaptic = CreateElvButton(page, 148, 22, "")
  btnHaptic:SetPoint("LEFT", btnTest, "RIGHT", 6, 0)
  btnHaptic:SetScript("OnClick", function()
    SpArc:ApplyCleanHapticPreset()
    if controlFrame and controlFrame.RefreshUI then
      controlFrame:RefreshUI()
    end
  end)
  ui.m11HapticBtn = btnHaptic

  -- Group 1: MSBT Movable Scroll Zones (Incoming & Outgoing) & Center HUD Protection
  local grpCenter = RegisterGroupBox(page, "M11_GRP_CENTER", 0, -50, 640, 192)
  CreateElvCheck(grpCenter, "CK_CT_INCOMING_ZONE", "ctShowIncomingZone", 14, -8, false, false, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
  end)
  CreateElvCheck(grpCenter, "CK_CT_OUTGOING_ZONE", "ctShowOutgoingZone", 330, -8, false, false, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
  end)
  CreateElvCheck(grpCenter, "CK_CT_HIDE_PLAYER", "ctHidePlayerScrolling", 14, -32, false, false, function(val)
    local db = SpArc:EnsureDB()
    db.visual.ctSuppressAlerts = val
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
  end)

  local styleLbl = grpCenter:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyCyrFont(styleLbl, 11)
  styleLbl:SetPoint("TOPLEFT", grpCenter, "TOPLEFT", 16, -61)
  styleLbl:SetTextColor(1, 0.85, 0.25, 1)
  ui.m11StyleLbl = styleLbl

  ui.m11StyleBtns = {}
  local scrollStyles = {
    { key = "ARC",      lKey = "M11_STYLE_ARC",      w = 175, x = 148 },
    { key = "UP",       lKey = "M11_STYLE_UP",       w = 150, x = 329 },
    { key = "FOUNTAIN", lKey = "M11_STYLE_FOUNTAIN", w = 143, x = 485 },
  }
  for _, st in ipairs(scrollStyles) do
    local b = CreateElvButton(grpCenter, st.w, 20, "")
    b:SetPoint("TOPLEFT", grpCenter, "TOPLEFT", st.x, -56)
    b.styleKey = st.key
    b.lKey = st.lKey
    b:SetScript("OnClick", function()
      local db = SpArc:EnsureDB()
      db.visual.ctScrollStyle = st.key
      SpArc:RefreshCombatTextPage(ui)
      SpArc:TriggerMSBTTestFountain()
    end)
    ui.m11StyleBtns[#ui.m11StyleBtns + 1] = b
  end

  CreateElvSlider(grpCenter, "SL_CT_INC_X", "ctIncomingX", -550, 0, 5, 16, -84, 190, function()
    SpArc:UpdateMSBTZonePositions()
  end)
  CreateElvSlider(grpCenter, "SL_CT_INC_Y", "ctIncomingY", -250, 250, 5, 224, -84, 190, function()
    SpArc:UpdateMSBTZonePositions()
  end)
  CreateElvSlider(grpCenter, "SL_CT_FONT_SIZE", "ctFontSize", 11, 28, 1, 432, -84, 190, function()
    SpArc:UpdateMSBTZonePositions()
  end)

  CreateElvSlider(grpCenter, "SL_CT_OUT_X", "ctOutgoingX", 0, 550, 5, 16, -138, 290, function()
    SpArc:UpdateMSBTZonePositions()
  end)
  CreateElvSlider(grpCenter, "SL_CT_OUT_Y", "ctOutgoingY", -250, 250, 5, 332, -138, 290, function()
    SpArc:UpdateMSBTZonePositions()
  end)

  -- Group 2: 3D Enemy Damage Numbers & Smart AoE Filter
  local grpEnemy = RegisterGroupBox(page, "M11_GRP_ENEMY", 0, -250, 640, 126)
  CreateElvCheck(grpEnemy, "CK_CT_DIRECT_DMG", "ctShowDirectDamage", 14, -8, false, false, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
  end)
  CreateElvCheck(grpEnemy, "CK_CT_HIDE_PET", "ctHidePetDamage", 300, -8, false, false, function()
    SpArc:ApplyCombatTextSettings()
  end)
  CreateElvCheck(grpEnemy, "CK_CT_HIDE_MISS", "ctHideDodgeParryMiss", 480, -8, false, false, function()
    SpArc:ApplyCombatTextSettings()
  end)

  local dotLbl = grpEnemy:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyCyrFont(dotLbl, 11)
  dotLbl:SetPoint("TOPLEFT", grpEnemy, "TOPLEFT", 16, -38)
  dotLbl:SetTextColor(1, 0.85, 0.25, 1)
  ui.m11DotModeLbl = dotLbl

  ui.m11DotBtns = {}
  local dotModes = {
    { key = "AUTO_AOE", lKey = "M11_DOT_AUTO", w = 225, x = 148 },
    { key = "OFF",      lKey = "M11_DOT_OFF",  w = 165, x = 378 },
    { key = "ON",       lKey = "M11_DOT_ON",   w = 80,  x = 548 },
  }
  for _, dm in ipairs(dotModes) do
    local b = CreateElvButton(grpEnemy, dm.w, 20, "")
    b:SetPoint("TOPLEFT", grpEnemy, "TOPLEFT", dm.x, -33)
    b.modeKey = dm.key
    b.lKey = dm.lKey
    b:SetScript("OnClick", function()
      local db = SpArc:EnsureDB()
      db.visual.ctDotTickMode = dm.key
      SpArc:ApplyCombatTextSettings()
      SpArc:RefreshCombatTextPage(ui)
    end)
    ui.m11DotBtns[#ui.m11DotBtns + 1] = b
  end

  CreateElvSlider(grpEnemy, "SL_CT_WORLD_SCALE", "ctWorldTextScale", 0.40, 1.30, 0.05, 16, -66, 190, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
    SpArc:SpawnOverheadTargetText("4 318", false, true)
  end)
  CreateElvSlider(grpEnemy, "SL_CT_OVERHEAD_ALPHA", "ctOverheadAlpha", 0.20, 1.00, 0.05, 224, -66, 190, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
    SpArc:SpawnOverheadTargetText("4 318", false, true)
  end)
  CreateElvSlider(grpEnemy, "SL_CT_OVERHEAD_Y", "ctOverheadY", 10, 140, 5, 432, -66, 190, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
    SpArc:SpawnOverheadTargetText("4 318", false, true)
  end)

  -- Group 3: Nameplate View Distance, Smooth Distance Fade & Stacking Anti-Overlap
  local grpScale = RegisterGroupBox(page, "M11_GRP_SCALE", 0, -384, 640, 150)
  CreateElvCheck(grpScale, "CK_NP_DIST_FADE", "npDistanceFade", 14, -8, false, false, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
  end)
  CreateElvCheck(grpScale, "CK_CT_SPREAD_NP", "ctSpreadNameplates", 356, -8, false, false, function()
    SpArc:ApplyCombatTextSettings()
  end)

  CreateElvSlider(grpScale, "SL_NP_MAX_DIST", "npMaxDistance", 20, 60, 2, 16, -42, 190, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
  end)
  CreateElvSlider(grpScale, "SL_NP_MIN_ALPHA", "npMinAlpha", 0.10, 1.00, 0.05, 224, -42, 190, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
  end)
  CreateElvSlider(grpScale, "SL_CT_OVERLAP_V", "ctNameplateOverlapV", 0.60, 2.00, 0.05, 432, -42, 190, function()
    SpArc:ApplyCombatTextSettings()
  end)

  local statusTxt = grpScale:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyCyrFont(statusTxt, 11)
  statusTxt:SetPoint("BOTTOMLEFT", grpScale, "BOTTOMLEFT", 16, 10)
  statusTxt:SetTextColor(0.82, 0.86, 0.94, 1)
  ui.m11StatusTxt = statusTxt
  ui.m11StyleToggle = StyleToggleButton
end

function SpArc:RefreshCombatTextPage(ui)
  if not ui or not ui.m11Title then return end
  local db = SpArc:EnsureDB()
  local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL

  ui.m11Title:SetText(SpArc:L("M11_TITLE"))

  if ui.m11UnlockBtn then
    ui.m11UnlockBtn:SetText(SpArc:L(SpArc.msbtZonesUnlocked and "M11_UNLOCK_ZONES_ON" or "M11_UNLOCK_ZONES_OFF"))
    if ui.m11StyleToggle then
      ui.m11StyleToggle(ui.m11UnlockBtn, SpArc.msbtZonesUnlocked and true or false)
    end
  end
  if ui.m11TestBtn then
    ui.m11TestBtn:SetText(SpArc:L("M11_TEST_STREAM_BTN"))
  end
  if ui.m11HapticBtn then
    ui.m11HapticBtn:SetText(SpArc:L("M11_PRESET_HAPTIC_BTN"))
    if ui.m11StyleToggle then
      local isHaptic = (vis.ctHidePlayerScrolling ~= false)
        and (vis.ctShowIncomingZone ~= false)
        and ((vis.ctDotTickMode or "AUTO_AOE") == "AUTO_AOE")
        and (math.abs((tonumber(vis.ctWorldTextScale) or 0.65) - 0.65) < 0.03)
      ui.m11StyleToggle(ui.m11HapticBtn, isHaptic)
    end
  end

  if ui.m11StyleLbl then
    ui.m11StyleLbl:SetText(SpArc:L("M11_SCROLL_STYLE_LBL"))
  end
  local curStyle = vis.ctScrollStyle or "ARC"
  if ui.m11StyleBtns then
    for _, b in ipairs(ui.m11StyleBtns) do
      b:SetText(SpArc:L(b.lKey))
      if ui.m11StyleToggle then
        ui.m11StyleToggle(b, b.styleKey == curStyle)
      end
    end
  end

  if ui.m11DotModeLbl then
    ui.m11DotModeLbl:SetText(SpArc:L("M11_DOT_MODE_LBL"))
  end
  local curMode = vis.ctDotTickMode or "AUTO_AOE"
  if ui.m11DotBtns then
    for _, b in ipairs(ui.m11DotBtns) do
      b:SetText(SpArc:L(b.lKey))
      if ui.m11StyleToggle then
        ui.m11StyleToggle(b, b.modeKey == curMode)
      end
    end
  end

  if ui.m11StatusTxt then
    local scaleVal = tonumber(vis.ctWorldTextScale) or 0.65
    local overheadAlphaPct = math.floor(((tonumber(vis.ctOverheadAlpha) or 0.60) * 100) + 0.5)
    local overheadYVal = math.floor((tonumber(vis.ctOverheadY) or 55) + 0.5)
    local periodicStr = "|cff00ff00ON|r"
    if curMode == "OFF" then
      periodicStr = "|cffff5555OFF|r"
    elseif curMode == "AUTO_AOE" and (lastCombatPlateCount or 0) >= 3 then
      periodicStr = "|cffff5555OFF (AoE)|r"
    end
    local maxDist = math.floor((tonumber(vis.npMaxDistance) or 40) + 0.5)
    local minAlphaPct = math.floor(((tonumber(vis.npMinAlpha) or 0.30) * 100) + 0.5)
    ui.m11StatusTxt:SetText(string.format(
      SpArc:L("M11_STATUS_FMT"),
      scaleVal,
      overheadAlphaPct,
      overheadYVal,
      periodicStr,
      maxDist,
      minAlphaPct,
      lastCombatPlateCount or 0
    ))
  end
end
