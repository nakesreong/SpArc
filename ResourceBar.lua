---------------------------------------------------------------------------------------
--  SpArc/ResourceBar.lua — Modular Secondary & Class Resource Tracker (Under Castbar)
--                          Supports Continuous 0..100 Scales (Insanity, Astral Power,
--                          Rage, Mana, Focus) and Discrete Pips (Combo Points,
--                          Maelstrom Weapon, Arcane Charges, Holy Power, Soul Shards).
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
--  @module ResourceBar
--  @responsibility
--    1. Resolves the active class/spec resource model (`BAR` 0..100 vs `PIPS` 1..10)
--       and renders `SpArcResourceBar` underneath the player Castbar.
--  @contract
--    - `SpArc:UpdateResourceBar(now, hudActive)` updates `SpArc.resourceFrame` and
--      never errors even when `UnitPower` returns a WoW 12.x Secret Value.
--  @techdebt [AUDIT-RB1]
--    - `ResolveActiveResourceMode()` and `QueryResourceData()` duplicate the resource
--      queries already performed in `State.lua` (`RefreshTrackedInsanity`) and `Telemetry.lua`
--      (`GetPrimaryResourceString`), and proliferate 12+ ad-hoc mode strings (`INSANITY`,
--      `ASTRAL_POWER`, `MAELSTROM_WEAPON`, `COMBO_POINTS`, `FERAL_COMBO`, etc.).
--      Planned Refactor (Phase 2): Unify into a single `SpArc:GetClassResourceState()` API
--      with strictly two presentation archetypes: `SCALE` (0/100 bar) and `PIPS` (combo/stack pips).
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

-- Discrete Pips (Combo Points, Arcane Charges, Holy Power, Soul Shards, Freezing Stacks, Maelstrom Weapon)
local MAX_PIPS = 10
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

---------------------------------------------------------------------------------------
--  UNIFIED CLASS RESOURCE DESCRIPTOR (2 Archetypes: "BAR" 0..100 vs "PIPS" 1..10)
---------------------------------------------------------------------------------------
local BAR_RESOURCE_BY_CLASS = {
  WARRIOR     = { powerType = 1,  r = 0.85, g = 0.20, b = 0.20, ru = "Ярость",          en = "Rage" },
  DRUID       = { powerType = 8,  r = 0.25, g = 0.58, b = 0.96, ru = "Астральная мощь", en = "Astral Power", threshold = 40 },
  DEATHKNIGHT = { powerType = 6,  r = 0.15, g = 0.75, b = 0.95, ru = "Сила рун",        en = "Runic Power" },
  DEMONHUNTER = { powerType = 17, r = 0.65, g = 0.20, b = 0.88, ru = "Гнев",            en = "Fury" },
  HUNTER      = { powerType = 2,  r = 0.92, g = 0.52, b = 0.18, ru = "Концентрация",    en = "Focus" },
  SHAMAN      = { powerType = 11, r = 0.18, g = 0.55, b = 0.96, ru = "Водоворот",       en = "Maelstrom" },
}

local PIP_RESOURCE_BY_CLASS = {
  PALADIN = { powerType = 9,  max = 5, finisher = 3, r1 = 0.95, g1 = 0.75, b1 = 0.18, r2 = 1.00, g2 = 0.92, b2 = 0.35, ru = "Энергия Света", en = "Holy Power" },
  WARLOCK = { powerType = 7,  max = 5, finisher = 3, r1 = 0.58, g1 = 0.32, b1 = 0.90, r2 = 0.82, g2 = 0.38, b2 = 1.00, ru = "Осколки души",  en = "Soul Shards" },
  MONK    = { powerType = 12, max = 5, finisher = 3, r1 = 0.15, g1 = 0.85, b1 = 0.55, r2 = 0.35, g2 = 1.00, b2 = 0.72, ru = "Ци",            en = "Chi" },
  EVOKER  = { powerType = 19, max = 5, finisher = 3, r1 = 0.22, g1 = 0.78, b1 = 0.62, r2 = 0.95, g2 = 0.80, b2 = 0.28, ru = "Сущность",      en = "Essence" },
}

local function ResolveResourceSpec(now)
  now = now or _G.GetTime()
  local classTag = "PRIEST"
  if UnitClass then
    local ok, _, c = pcall(UnitClass, "player")
    if ok and not IsSecret(c) and type(c) == "string" then
      classTag = c
    end
  end
  local specID = SpArc.GetPlayerSpecID and SpArc:GetPlayerSpecID() or nil
  local isRU = SpArc.IsRU and SpArc:IsRU()

  -- 1. PIPS: Rogue or Feral Druid (103) -> Combo Points + Energy sub-bar
  if classTag == "ROGUE" or (classTag == "DRUID" and specID == 103) then
    local maxCP = math.max(5, math.min(MAX_PIPS, SafeReadPowerMax(4, 5)))
    local curCP = SafeReadPower(4)
    if curCP == nil then
      curCP = st.trackedComboPoints or math.floor(((st.trackedInsanity or 0) + 5) / 20)
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

  -- 2. PIPS: Enhancement Shaman (263) -> Maelstrom Weapon (1..10 stacks)
  if specID == 263 then
    local curMW = nil
    local auraPresent = nil
    if _G.C_UnitAuras and _G.C_UnitAuras.GetPlayerAuraBySpellID then
      local okA, aura = pcall(_G.C_UnitAuras.GetPlayerAuraBySpellID, 344179)
      if okA then
        if aura == nil then
          auraPresent = false
          curMW = 0
          st.maelstromWeaponStacks = 0
        else
          auraPresent = true
          if not IsSecret(aura.applications) and type(aura.applications) == "number" then
            curMW = math.max(1, aura.applications)
            st.maelstromWeaponStacks = curMW
          end
        end
      end
    end
    if curMW == nil then
      if st.maelstromWeaponStacks and st.maelstromWeaponStacks > 0 then
        curMW = st.maelstromWeaponStacks
      elseif auraPresent then
        curMW = 1
      end
    end
    curMW = math.max(0, math.min(10, curMW or 0))
    if SpArc.testMode and curMW == 0 then
      curMW = (math.floor(now * 1.5) % 10) + 1
    end
    return {
      mode = "PIPS",
      cur = curMW,
      max = 10,
      finisherThreshold = 5,
      r1 = 0.18, g1 = 0.62, b1 = 0.98,
      r2 = 1.00, g2 = 0.80, b2 = 0.16,
      leftLabel = isRU and "Водоворот" or "Maelstrom",
      rightLabel = string.format("%d / 10", curMW),
    }
  end

  -- 3. PIPS: Mage -> Arcane Charges (62) or Frost Freezing Stacks (64)
  if classTag == "MAGE" then
    if specID == 62 then
      local maxAC = 4
      local curAC = SafeReadPower(16) or 0
      if SpArc.testMode and curAC == 0 then curAC = (math.floor(now) % 5) end
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
      if SpArc.testMode and curSt == 0 then curSt = (math.floor(now) % 5) end
      return {
        mode = "PIPS",
        cur = math.min(5, curSt),
        max = 5,
        finisherThreshold = 4,
        r1 = 0.22, g1 = 0.68, b1 = 0.98,
        r2 = 0.45, g2 = 0.92, b2 = 1.00,
        leftLabel = isRU and "Обледенение" or "Freezing",
        rightLabel = tostring(curSt),
      }
    end
  end

  -- 4. PIPS: Standard Discrete Power Classes (Paladin, Warlock, Monk, Evoker)
  local pipCfg = PIP_RESOURCE_BY_CLASS[classTag]
  if pipCfg then
    local maxP = math.max(pipCfg.max, math.min(MAX_PIPS, SafeReadPowerMax(pipCfg.powerType, pipCfg.max)))
    local curP = SafeReadPower(pipCfg.powerType) or 0
    if SpArc.testMode and curP == 0 then curP = (math.floor(now) % maxP) + 1 end
    return {
      mode = "PIPS",
      cur = curP,
      max = maxP,
      finisherThreshold = pipCfg.finisher,
      r1 = pipCfg.r1, g1 = pipCfg.g1, b1 = pipCfg.b1,
      r2 = pipCfg.r2, g2 = pipCfg.g2, b2 = pipCfg.b2,
      leftLabel = isRU and pipCfg.ru or pipCfg.en,
      rightLabel = string.format("%d / %d", curP, maxP),
    }
  end

  -- 5. BAR (0..100): Shadow Priest Insanity (with 50+ Devouring Plague glow)
  if classTag == "PRIEST" then
    local maxIns = SafeReadPowerMax(13, 100)
    local curIns = SafeReadPower(13)
    if curIns == nil then curIns = st.trackedInsanity or 0 end
    if SpArc.testMode and curIns == 0 then curIns = math.floor((now * 22) % (maxIns + 1)) end
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

  -- 6. BAR (0..100): Standard Continuous Scale Classes (Warrior, Guardian/Balance Druid, DK, DH, Hunter, Ele Shaman)
  local barCfg = (classTag == "DRUID" and specID == 104) and BAR_RESOURCE_BY_CLASS.WARRIOR or BAR_RESOURCE_BY_CLASS[classTag] or BAR_RESOURCE_BY_CLASS.SHAMAN
  local maxB = SafeReadPowerMax(barCfg.powerType, 100)
  local curB = SafeReadPower(barCfg.powerType) or 0
  if SpArc.testMode and curB == 0 then curB = math.floor((now * 20) % 100) end
  return {
    mode = "BAR",
    cur = curB,
    max = maxB,
    threshold = barCfg.threshold,
    r = barCfg.r, g = barCfg.g, b = barCfg.b,
    leftLabel = isRU and barCfg.ru or barCfg.en,
    rightLabel = string.format("%d / %d", curB, maxB),
  }
end

function SpArc:GetClassResourceState(now)
  return ResolveResourceSpec(now)
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

  if SpArc.RecordModuleTick then
    SpArc:RecordModuleTick("ResourceBar", mode)
  end

  resFrame:Show()
end

SpArc:ApplyResourceBarLayout()
