---------------------------------------------------------------------------------------
--  SpArc/ResourceBar.lua — Modular Secondary & Class Resource Tracker (Under Castbar)
--                          Supports Combo Points (+Energy strip), Insanity, Arcane
--                          Charges, Freezing Stacks, Holy Power, Soul Shards, Rage, etc.
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc

local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local UnitClass = _G.UnitClass
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitExists = _G.UnitExists
local UnitCanAttack = _G.UnitCanAttack
local UnitIsDead = _G.UnitIsDead
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitInVehicle = _G.UnitInVehicle
local IsMounted = _G.IsMounted
local HasOverrideActionBar = _G.HasOverrideActionBar
local pcall = _G.pcall
local tonumber = _G.tonumber
local tostring = _G.tostring
local type = _G.type
local math = _G.math
local string = _G.string

local ApplyCyrFont = SpArc.ApplyCyrFont
local IsSecret = SpArc.IsSecret
local SafeBool = SpArc.SafeBool
local DEFAULT_VISUAL = SpArc.DEFAULT_VISUAL
local st = SpArc.state

local parentRoot = _G.SpArcHUDRoot or UIParent
local resFrame = CreateFrame("Frame", "SpArcResourceBar", parentRoot)
resFrame:SetSize(276, 16)
resFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -166)
resFrame:SetFrameStrata("MEDIUM")
resFrame:SetFrameLevel(26)

local outerBorder = resFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
outerBorder:SetPoint("TOPLEFT", resFrame, "TOPLEFT", -2, 2)
outerBorder:SetPoint("BOTTOMRIGHT", resFrame, "BOTTOMRIGHT", 2, -2)
outerBorder:SetColorTexture(0.06, 0.06, 0.09, 0.96)

local bgTex = resFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
bgTex:SetAllPoints(resFrame)
bgTex:SetColorTexture(0.09, 0.09, 0.14, 0.90)

-- Continuous Bar Fill & Threshold Tick (Insanity, Rage, Astral Power, Energy, etc.)
local barFill = resFrame:CreateTexture(nil, "ARTWORK", nil, 0)
barFill:SetPoint("TOPLEFT", resFrame, "TOPLEFT", 0, 0)
barFill:SetPoint("BOTTOMLEFT", resFrame, "BOTTOMLEFT", 0, 0)
barFill:SetWidth(1)
barFill:SetColorTexture(0.55, 0.22, 0.92, 0.95)

local thresholdTick = resFrame:CreateTexture(nil, "OVERLAY", nil, 2)
thresholdTick:SetWidth(2)
thresholdTick:SetPoint("TOP", resFrame, "TOPLEFT", 138, 1)
thresholdTick:SetPoint("BOTTOM", resFrame, "BOTTOMLEFT", 138, -1)
thresholdTick:SetColorTexture(1.0, 0.88, 0.35, 0.90)
thresholdTick:Hide()

-- Discrete Pips (Combo Points, Arcane Charges, Holy Power, Soul Shards, Freezing Stacks)
local MAX_PIPS = 7
local pipFrames = {}
for i = 1, MAX_PIPS do
  local p = CreateFrame("Frame", nil, resFrame)
  p:SetFrameLevel(27)

  local pBorder = p:CreateTexture(nil, "BACKGROUND", nil, -1)
  pBorder:SetPoint("TOPLEFT", p, "TOPLEFT", -1, 1)
  pBorder:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 1, -1)
  pBorder:SetColorTexture(0.04, 0.04, 0.06, 0.95)
  p.border = pBorder

  local pBg = p:CreateTexture(nil, "BACKGROUND", nil, 0)
  pBg:SetAllPoints(p)
  pBg:SetColorTexture(0.11, 0.11, 0.16, 0.92)
  p.bg = pBg

  local pFill = p:CreateTexture(nil, "ARTWORK", nil, 1)
  pFill:SetAllPoints(p)
  pFill:SetColorTexture(0.92, 0.28, 0.22, 0.96)
  p.fill = pFill

  p:Hide()
  pipFrames[i] = p
end

-- Sub-bar at bottom for Energy on Rogue / Feral Druid
local subBarBg = resFrame:CreateTexture(nil, "ARTWORK", nil, 2)
subBarBg:SetPoint("BOTTOMLEFT", resFrame, "BOTTOMLEFT", 0, 0)
subBarBg:SetPoint("BOTTOMRIGHT", resFrame, "BOTTOMRIGHT", 0, 0)
subBarBg:SetHeight(4)
subBarBg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
subBarBg:Hide()

local subBarFill = resFrame:CreateTexture(nil, "OVERLAY", nil, 1)
subBarFill:SetPoint("BOTTOMLEFT", resFrame, "BOTTOMLEFT", 0, 0)
subBarFill:SetHeight(3)
subBarFill:SetWidth(1)
subBarFill:SetColorTexture(1.0, 0.84, 0.22, 0.95)
subBarFill:Hide()

-- Text Overlays
local leftText = resFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ApplyCyrFont(leftText, 11)
leftText:SetPoint("LEFT", resFrame, "LEFT", 6, 1)
leftText:SetJustifyH("LEFT")
leftText:SetTextColor(0.92, 0.92, 0.98, 0.95)
leftText:SetShadowColor(0, 0, 0, 1)
leftText:SetShadowOffset(1, -1)

local rightText = resFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ApplyCyrFont(rightText, 11)
rightText:SetPoint("RIGHT", resFrame, "RIGHT", -6, 1)
rightText:SetJustifyH("RIGHT")
rightText:SetTextColor(1.0, 0.96, 0.80, 1.0)
rightText:SetShadowColor(0, 0, 0, 1)
rightText:SetShadowOffset(1, -1)

resFrame:Hide()

local function SafeReadPower(powerType)
  if not UnitPower then return nil end
  local ok, val = pcall(UnitPower, "player", powerType)
  if ok and not IsSecret(val) and type(val) == "number" then
    return val
  end
  return nil
end

local function SafeReadPowerMax(powerType, fallbackMax)
  if UnitPowerMax then
    local ok, val = pcall(UnitPowerMax, "player", powerType)
    if ok and not IsSecret(val) and type(val) == "number" and val > 0 then
      return val
    end
  end
  return fallbackMax or 100
end

local function ResolveResourceSpec(now)
  local classTag = "PRIEST"
  if UnitClass then
    local ok, _, c = pcall(UnitClass, "player")
    if ok and not IsSecret(c) and type(c) == "string" then
      classTag = c
    end
  end
  local specID = SpArc.GetPlayerSpecID and SpArc:GetPlayerSpecID() or nil
  local isRU = SpArc.IsRU and SpArc:IsRU()

  -- 1. ROGUE (All specs) or FERAL DRUID (103): Combo Points + Energy sub-bar
  if classTag == "ROGUE" or (classTag == "DRUID" and specID == 103) then
    local maxCP = math.max(5, math.min(MAX_PIPS, SafeReadPowerMax(4, 5)))
    local curCP = SafeReadPower(4)
    if curCP == nil then
      curCP = math.floor(((st.trackedInsanity or 0) + 5) / 20)
    end
    if SpArc.testMode and curCP == 0 then
      curCP = (math.floor(now * 1.2) % maxCP) + 1
    end
    curCP = math.max(0, math.min(maxCP, curCP))

    local curEnergy = SafeReadPower(3)
    local maxEnergy = SafeReadPowerMax(3, 100)
    if SpArc.testMode and (not curEnergy or curEnergy >= maxEnergy) then
      curEnergy = math.floor(30 + ((now * 28) % 70))
    end

    local label = isRU and "Приёмы серии" or "Combo Points"
    if curEnergy then
      label = string.format("%s: %d", isRU and "Энергия" or "Energy", curEnergy)
    end
    return {
      mode = "PIPS",
      cur = curCP,
      max = maxCP,
      finisherThreshold = 4,
      r1 = 0.90, g1 = 0.25, b1 = 0.22,
      r2 = 1.00, g2 = 0.80, b2 = 0.16,
      subCur = curEnergy,
      subMax = maxEnergy,
      leftLabel = label,
      rightLabel = string.format("%d / %d", curCP, maxCP),
    }
  end

  -- 2. PRIEST (Shadow 258 or default Priest with Devouring Plague): Insanity (Безумие)
  if classTag == "PRIEST" then
    local maxIns = SafeReadPowerMax(13, 100)
    local curIns = SafeReadPower(13)
    if curIns == nil then
      curIns = st.trackedInsanity or 0
    end
    if SpArc.testMode and curIns == 0 then
      curIns = math.floor((now * 22) % (maxIns + 1))
    end
    curIns = math.max(0, math.min(maxIns, curIns))
    local readyPlague = (curIns >= 50)
    return {
      mode = "BAR",
      cur = curIns,
      max = maxIns,
      threshold = 50,
      r = readyPlague and 0.90 or 0.56,
      g = readyPlague and 0.22 or 0.20,
      b = readyPlague and 1.00 or 0.92,
      glowBorder = readyPlague,
      leftLabel = isRU and "Безумие" or "Insanity",
      rightLabel = string.format("%d / %d", curIns, maxIns),
    }
  end

  -- 3. MAGE: Arcane Charges (62) or Frost Freezing Stacks (64)
  if classTag == "MAGE" then
    if specID == 62 then
      local maxAC = 4
      local curAC = SafeReadPower(16) or 0
      if SpArc.testMode and curAC == 0 then
        curAC = (math.floor(now) % 5)
      end
      return {
        mode = "PIPS",
        cur = curAC,
        max = maxAC,
        finisherThreshold = 4,
        r1 = 0.30, g1 = 0.62, b1 = 1.00,
        r2 = 0.72, g2 = 0.38, b2 = 1.00,
        leftLabel = isRU and "Чародейские заряды" or "Arcane Charges",
        rightLabel = string.format("%d / %d", curAC, maxAC),
      }
    else
      local curSt = st.targetDebuffStacks or 0
      if SpArc.testMode and curSt == 0 then
        curSt = (math.floor(now) % 5)
      end
      local dispPips = math.min(5, curSt)
      return {
        mode = "PIPS",
        cur = dispPips,
        max = 5,
        finisherThreshold = 4,
        r1 = 0.22, g1 = 0.68, b1 = 0.98,
        r2 = 0.45, g2 = 0.92, b2 = 1.00,
        leftLabel = isRU and "Обледенение" or "Freezing",
        rightLabel = tostring(curSt),
      }
    end
  end

  -- 4. PALADIN: Holy Power (9)
  if classTag == "PALADIN" then
    local maxHP = math.max(5, math.min(MAX_PIPS, SafeReadPowerMax(9, 5)))
    local curHP = SafeReadPower(9) or 0
    if SpArc.testMode and curHP == 0 then curHP = (math.floor(now) % maxHP) + 1 end
    return {
      mode = "PIPS",
      cur = curHP,
      max = maxHP,
      finisherThreshold = 3,
      r1 = 0.95, g1 = 0.75, b1 = 0.18,
      r2 = 1.00, g2 = 0.92, b2 = 0.35,
      leftLabel = isRU and "Энергия Света" or "Holy Power",
      rightLabel = string.format("%d / %d", curHP, maxHP),
    }
  end

  -- 5. WARLOCK: Soul Shards (7)
  if classTag == "WARLOCK" then
    local maxSS = 5
    local curSS = SafeReadPower(7) or 0
    if SpArc.testMode and curSS == 0 then curSS = (math.floor(now) % 5) + 1 end
    return {
      mode = "PIPS",
      cur = curSS,
      max = maxSS,
      finisherThreshold = 3,
      r1 = 0.58, g1 = 0.32, b1 = 0.90,
      r2 = 0.82, g2 = 0.38, b2 = 1.00,
      leftLabel = isRU and "Осколки души" or "Soul Shards",
      rightLabel = string.format("%d / %d", curSS, maxSS),
    }
  end

  -- 6. MONK: Chi (12)
  if classTag == "MONK" then
    local maxChi = math.max(5, math.min(MAX_PIPS, SafeReadPowerMax(12, 5)))
    local curChi = SafeReadPower(12) or 0
    if SpArc.testMode and curChi == 0 then curChi = (math.floor(now) % maxChi) + 1 end
    return {
      mode = "PIPS",
      cur = curChi,
      max = maxChi,
      finisherThreshold = 3,
      r1 = 0.15, g1 = 0.85, b1 = 0.55,
      r2 = 0.35, g2 = 1.00, b2 = 0.72,
      leftLabel = isRU and "Ци" or "Chi",
      rightLabel = string.format("%d / %d", curChi, maxChi),
    }
  end

  -- 7. EVOKER: Essence (19)
  if classTag == "EVOKER" then
    local maxEss = math.max(5, math.min(MAX_PIPS, SafeReadPowerMax(19, 5)))
    local curEss = SafeReadPower(19) or 0
    if SpArc.testMode and curEss == 0 then curEss = (math.floor(now) % maxEss) + 1 end
    return {
      mode = "PIPS",
      cur = curEss,
      max = maxEss,
      finisherThreshold = 3,
      r1 = 0.22, g1 = 0.78, b1 = 0.62,
      r2 = 0.95, g2 = 0.80, b2 = 0.28,
      leftLabel = isRU and "Сущность" or "Essence",
      rightLabel = string.format("%d / %d", curEss, maxEss),
    }
  end

  -- 8. WARRIOR / GUARDIAN DRUID: Rage (1)
  if classTag == "WARRIOR" or (classTag == "DRUID" and specID == 104) then
    local maxRg = SafeReadPowerMax(1, 100)
    local curRg = SafeReadPower(1) or 0
    if SpArc.testMode and curRg == 0 then curRg = math.floor((now * 20) % 100) end
    return {
      mode = "BAR",
      cur = curRg,
      max = maxRg,
      r = 0.85, g = 0.20, b = 0.20,
      leftLabel = isRU and "Ярость" or "Rage",
      rightLabel = string.format("%d / %d", curRg, maxRg),
    }
  end

  -- 9. BALANCE DRUID: Astral Power (8)
  if classTag == "DRUID" then
    local maxAP = SafeReadPowerMax(8, 100)
    local curAP = SafeReadPower(8) or 0
    if SpArc.testMode and curAP == 0 then curAP = math.floor((now * 20) % 100) end
    return {
      mode = "BAR",
      cur = curAP,
      max = maxAP,
      threshold = 40,
      r = 0.25, g = 0.58, b = 0.96,
      leftLabel = isRU and "Астральная мощь" or "Astral Power",
      rightLabel = string.format("%d / %d", curAP, maxAP),
    }
  end

  -- 10. DEATH KNIGHT: Runic Power (6)
  if classTag == "DEATHKNIGHT" then
    local maxRP = SafeReadPowerMax(6, 100)
    local curRP = SafeReadPower(6) or 0
    if SpArc.testMode and curRP == 0 then curRP = math.floor((now * 20) % 100) end
    return {
      mode = "BAR",
      cur = curRP,
      max = maxRP,
      r = 0.15, g = 0.75, b = 0.95,
      leftLabel = isRU and "Сила рун" or "Runic Power",
      rightLabel = string.format("%d / %d", curRP, maxRP),
    }
  end

  -- 11. DEMON HUNTER: Fury (17)
  if classTag == "DEMONHUNTER" then
    local maxF = SafeReadPowerMax(17, 100)
    local curF = SafeReadPower(17) or 0
    if SpArc.testMode and curF == 0 then curF = math.floor((now * 20) % 100) end
    return {
      mode = "BAR",
      cur = curF,
      max = maxF,
      r = 0.65, g = 0.20, b = 0.88,
      leftLabel = isRU and "Гнев" or "Fury",
      rightLabel = string.format("%d / %d", curF, maxF),
    }
  end

  -- 12. HUNTER: Focus (2)
  if classTag == "HUNTER" then
    local maxFc = SafeReadPowerMax(2, 100)
    local curFc = SafeReadPower(2) or 0
    if SpArc.testMode and curFc == 0 then curFc = math.floor((now * 20) % 100) end
    return {
      mode = "BAR",
      cur = curFc,
      max = maxFc,
      r = 0.92, g = 0.52, b = 0.18,
      leftLabel = isRU and "Концентрация" or "Focus",
      rightLabel = string.format("%d / %d", curFc, maxFc),
    }
  end

  -- 13. SHAMAN: Maelstrom (11)
  local maxM = SafeReadPowerMax(11, 100)
  local curM = SafeReadPower(11) or 0
  if SpArc.testMode and curM == 0 then curM = math.floor((now * 20) % 100) end
  return {
    mode = "BAR",
    cur = curM,
    max = maxM,
    r = 0.18, g = 0.55, b = 0.96,
    leftLabel = isRU and "Водоворот" or "Maelstrom",
    rightLabel = string.format("%d / %d", curM, maxM),
  }
end

function SpArc:ApplyResourceBarLayout()
  local db = SpArc:EnsureDB()
  local v = db.visual or DEFAULT_VISUAL
  local w = math.max(120, math.min(480, tonumber(v.resourceBarWidth) or 276))
  local h = math.max(10, math.min(36, tonumber(v.resourceBarHeight) or 16))
  local ox = tonumber(v.resourceBarOffsetX) or 0
  local oy = tonumber(v.resourceBarOffsetY) or -166
  local scale = math.max(0.5, math.min(2.5, tonumber(v.resourceBarScale) or 1.00))

  resFrame:SetSize(w, h)
  resFrame:SetScale(scale)
  resFrame:ClearAllPoints()
  resFrame:SetPoint("CENTER", UIParent, "CENTER", ox, oy)
end

function SpArc:UpdateResourceBar(now)
  now = now or _G.GetTime()
  local db = SpArc:EnsureDB()
  local v = db.visual or DEFAULT_VISUAL
  if v.showResourceBar == false then
    resFrame:Hide()
    return
  end

  local isMounted = SafeBool(IsMounted) or SafeBool(UnitInVehicle, "player") or SafeBool(HasOverrideActionBar)
  local isDead = SafeBool(UnitIsDeadOrGhost, "player")
  if (isMounted or isDead) and not SpArc.testMode then
    resFrame:Hide()
    return
  end

  local hasHostileTarget = SpArc.testMode or (
    SafeBool(UnitExists, "target")
    and SafeBool(UnitCanAttack, "player", "target")
    and not SafeBool(UnitIsDead, "target")
  )
  local inCombat = SafeBool(UnitAffectingCombat, "player")
  local inConfig = (_G.SpArcControlCenter and _G.SpArcControlCenter:IsShown()) or false
  if not hasHostileTarget and not inCombat and not v.alwaysShowResourceBar and not v.alwaysShowCDs and not SpArc.testMode and not inConfig then
    resFrame:Hide()
    return
  end

  local info = ResolveResourceSpec(now)
  if not info then
    resFrame:Hide()
    return
  end

  local totalW = resFrame:GetWidth()
  local totalH = resFrame:GetHeight()
  if not totalW or totalW <= 10 then
    totalW = tonumber(v.resourceBarWidth) or 276
    totalH = tonumber(v.resourceBarHeight) or 16
  end

  leftText:SetText(info.leftLabel or "")
  rightText:SetText(info.rightLabel or "")

  if info.mode == "PIPS" then
    barFill:Hide()
    thresholdTick:Hide()
    bgTex:SetColorTexture(0.05, 0.05, 0.08, 0.70)

    local hasSubBar = (info.subCur ~= nil and info.subMax and info.subMax > 0)
    local subH = hasSubBar and 4 or 0
    local pipH = math.max(6, totalH - subH)
    local nPips = math.max(1, math.min(MAX_PIPS, info.max or 5))
    local gap = 3
    local pipW = (totalW - gap * (nPips - 1)) / nPips
    local isHigh = (info.finisherThreshold and info.cur >= info.finisherThreshold)

    if isHigh then
      outerBorder:SetColorTexture(1.0, 0.78, 0.18, 0.96)
    else
      outerBorder:SetColorTexture(0.06, 0.06, 0.09, 0.96)
    end

    for i = 1, MAX_PIPS do
      local p = pipFrames[i]
      if i <= nPips then
        p:ClearAllPoints()
        p:SetSize(pipW, pipH)
        p:SetPoint("TOPLEFT", resFrame, "TOPLEFT", (i - 1) * (pipW + gap), 0)
        if i <= info.cur then
          if isHigh then
            p.fill:SetColorTexture(info.r2 or 1.0, info.g2 or 0.80, info.b2 or 0.16, 0.98)
          else
            p.fill:SetColorTexture(info.r1 or 0.90, info.g1 or 0.25, info.b1 or 0.22, 0.95)
          end
          p.fill:Show()
        else
          p.fill:Hide()
        end
        p:Show()
      else
        p:Hide()
      end
    end

    if hasSubBar then
      local eFrac = math.max(0.01, math.min(1.0, info.subCur / info.subMax))
      subBarBg:Show()
      subBarFill:SetWidth(totalW * eFrac)
      if info.subCur < 35 then
        subBarFill:SetColorTexture(0.45, 0.65, 0.95, 0.95)
      else
        subBarFill:SetColorTexture(1.0, 0.84, 0.22, 0.95)
      end
      subBarFill:Show()
    else
      subBarBg:Hide()
      subBarFill:Hide()
    end
  else
    for i = 1, MAX_PIPS do
      pipFrames[i]:Hide()
    end
    subBarBg:Hide()
    subBarFill:Hide()
    bgTex:SetColorTexture(0.09, 0.09, 0.14, 0.90)

    local maxV = math.max(1, info.max or 100)
    local curV = math.max(0, math.min(maxV, info.cur or 0))
    local frac = math.max(0.01, math.min(1.0, curV / maxV))
    barFill:SetWidth(totalW * frac)
    barFill:SetColorTexture(info.r or 0.56, info.g or 0.20, info.b or 0.92, 0.96)
    barFill:Show()

    if info.glowBorder then
      outerBorder:SetColorTexture(0.95, 0.30, 1.0, 0.98)
    else
      outerBorder:SetColorTexture(0.06, 0.06, 0.09, 0.96)
    end

    if info.threshold and info.threshold > 0 and info.threshold < maxV then
      local tickX = totalW * (info.threshold / maxV)
      thresholdTick:ClearAllPoints()
      thresholdTick:SetPoint("TOP", resFrame, "TOPLEFT", tickX, 1)
      thresholdTick:SetPoint("BOTTOM", resFrame, "BOTTOMLEFT", tickX, -1)
      thresholdTick:Show()
    else
      thresholdTick:Hide()
    end
  end

  resFrame:Show()
end

SpArc:ApplyResourceBarLayout()
