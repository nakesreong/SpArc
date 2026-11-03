---------------------------------------------------------------------------------------
--  SpArc/UnitFrames.lua — Standalone Circular-Portrait & Metro UnitFrames Suite
--                         (Player, Target, Target Castbar, ToT, Focus, Pet, Boss 1..5)
--                         Designed to replace ElvUI UnitFrames with 0-Taint & High FPS
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc

local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local GetTime = _G.GetTime
local UnitExists = _G.UnitExists
local UnitIsUnit = _G.UnitIsUnit
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsEnemy = _G.UnitIsEnemy
local UnitIsFriend = _G.UnitIsFriend
local UnitCanAttack = _G.UnitCanAttack
local UnitReaction = _G.UnitReaction
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitName = _G.UnitName
local UnitLevel = _G.UnitLevel
local UnitClassification = _G.UnitClassification
local UnitClass = _G.UnitClass
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerType = _G.UnitPowerType
local UnitCastingDuration = _G.UnitCastingDuration
local UnitChannelDuration = _G.UnitChannelDuration
local SetPortraitTexture = _G.SetPortraitTexture
local IsResting = _G.IsResting
local InCombatLockdown = _G.InCombatLockdown
local RegisterUnitWatch = _G.RegisterUnitWatch
local UnregisterUnitWatch = _G.UnregisterUnitWatch
local C_UnitAuras = _G.C_UnitAuras
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS
local CLASS_ICON_TCOORDS = _G.CLASS_ICON_TCOORDS
local pcall = _G.pcall
local ipairs = _G.ipairs
local pairs = _G.pairs
local tonumber = _G.tonumber
local tostring = _G.tostring
local type = _G.type
local math = _G.math
local string = _G.string

local ApplyCyrFont = SpArc.ApplyCyrFont
local IsSecret = SpArc.IsSecret
local SafeBool = SpArc.SafeBool
local DEFAULT_VISUAL = SpArc.DEFAULT_VISUAL

local FLAT_TEX = "Interface\\Buttons\\WHITE8x8"
local PORTRAIT_MASK_TEX = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local CLASS_ICONS_TEX = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"

-- Reaction & Power Colors
local COLOR_HOSTILE_RED    = { r = 0.85, g = 0.18, b = 0.16 }
local COLOR_NEUTRAL_YELLOW = { r = 0.92, g = 0.78, b = 0.16 }
local COLOR_FRIENDLY_GREEN = { r = 0.18, g = 0.80, b = 0.32 }
local COLOR_OBSIDIAN_DARK  = { r = 0.14, g = 0.15, b = 0.20 }
local COLOR_CAST_GOLD      = { r = 1.00, g = 0.80, b = 0.15 }
local COLOR_CAST_GREY      = { r = 0.45, g = 0.47, b = 0.50 }

local POWER_COLORS = {
  [0]  = { r = 0.12, g = 0.52, b = 0.98 }, -- Mana
  [1]  = { r = 0.90, g = 0.18, b = 0.18 }, -- Rage
  [2]  = { r = 0.98, g = 0.52, b = 0.16 }, -- Focus
  [3]  = { r = 0.98, g = 0.86, b = 0.18 }, -- Energy
  [6]  = { r = 0.15, g = 0.82, b = 0.98 }, -- Runic Power
  [8]  = { r = 0.35, g = 0.55, b = 0.98 }, -- Lunar Power
  [11] = { r = 0.12, g = 0.58, b = 0.98 }, -- Maelstrom
  [13] = { r = 0.65, g = 0.22, b = 0.96 }, -- Insanity
  [17] = { r = 0.80, g = 0.20, b = 0.90 }, -- Fury
  [18] = { r = 0.95, g = 0.45, b = 0.15 }, -- Pain
}

---------------------------------------------------------------------------------------
--  LOCALIZATION STRINGS FOR MODULE 12 (UNITFRAMES)
---------------------------------------------------------------------------------------
if SpArc.RegisterStrings then
  SpArc:RegisterStrings({
    NAV_12 = "UnitFrames",
    M12_TITLE = "UnitFrames Suite (Player, Target, Castbar, ToT, Focus, Pet & Bosses)",
    M12_EDIT_POS_BTN = "Move UnitFrames (Edit Mode)",
    M12_DISABLE_ELVUF_BTN = "Disable ElvUI UnitFrames",
    M12_GRP_STYLE = "1. Portrait Style, Bar Colors & Active UnitFrames",
    M12_PORTRAIT_LBL = "Portrait Style:",
    M12_PORT_CIRCLE = "Circular Ring (Default)",
    M12_PORT_SQUARE = "Metro Square",
    M12_PORT_NONE = "No Portrait",
    M12_COLOR_LBL = "Health Bar Color:",
    M12_COLOR_CLASS = "Class & Reaction Color",
    M12_COLOR_DARK = "Dark Obsidian",
    CK_UF_HIDE_BLIZZ = "Hide default Blizzard Player / Target / Focus frames",
    CK_UF_POWER = "Show Power / Mana Bar along bottom",
    CK_UF_TGT_CAST = "Show Target Castbar below Target",
    CK_UF_TGT_AURAS = "Show Target DoTs / Buffs above Target",
    CK_UF_TOT = "Show Target of Target (ToT)",
    CK_UF_FOCUS = "Show Focus Frame (+ Castbar)",
    CK_UF_PET = "Show Pet Frame",
    CK_UF_BOSS = "Show Boss Frames (Boss 1..5)",
    M12_GRP_GEO = "2. Frame Dimensions, Portrait Size & Typography",
    SL_UF_WIDTH = "Main Bar Width (px)",
    SL_UF_HEIGHT = "Main Bar Height (px)",
    SL_UF_PORT_SIZE = "Circular Portrait Size (px)",
    SL_UF_FONT_SIZE = "Font Size (pt)",
    SL_UF_CAST_H = "Target Castbar Height (px)",
    SL_UF_OOC_ALPHA = "Out-of-Combat Opacity",
    M12_GRP_POS = "3. Player & Target Coordinates (or drag in 'Edit HUD' / Blizzard Edit Mode)",
    SL_UF_PLAYER_X = "Player Frame X (px)",
    SL_UF_PLAYER_Y = "Player Frame Y (px)",
    SL_UF_TARGET_X = "Target Frame X (px)",
    SL_UF_TARGET_Y = "Target Frame Y (px)",
    SL_UF_TCAST_X = "Target Castbar X (px)",
    SL_UF_TCAST_Y = "Target Castbar Y (px)",
    EM_MOVER_UF_PLAYER = "Player Frame",
    EM_MOVER_UF_TARGET = "Target Frame",
    EM_MOVER_UF_TCAST = "Target Castbar",
    EM_MOVER_UF_TOT = "Target of Target (ToT)",
    EM_MOVER_UF_FOCUS = "Focus Frame",
    EM_MOVER_UF_PET = "Pet Frame",
    EM_MOVER_UF_BOSS = "Boss Frames (1..5)",
    MSG_ELVUF_DISABLED = "|cffa335eeSpArc UnitFrames:|r Disabled ElvUI UnitFrames in current profile. Type |cffffd100/reload|r to apply cleanly.",
  }, {
    NAV_12 = "Юнитфреймы",
    M12_TITLE = "Юнитфреймы SpArc (Игрок, Цель, Кастбар цели, Цель цели, Фокус, Питомец и Боссы)",
    M12_EDIT_POS_BTN = "Двигать фреймы (Редактировать)",
    M12_DISABLE_ELVUF_BTN = "Отключить фреймы ElvUI",
    M12_GRP_STYLE = "1. Стиль портрета, Окраска полос и Включённые фреймы",
    M12_PORTRAIT_LBL = "Портрет:",
    M12_PORT_CIRCLE = "Круг с кольцом (Скриншот)",
    M12_PORT_SQUARE = "Квадрат Metro",
    M12_PORT_NONE = "Без портрета",
    M12_COLOR_LBL = "Окраска ХП:",
    M12_COLOR_CLASS = "Цвет класса и реакции",
    M12_COLOR_DARK = "Тёмный обсидиан",
    CK_UF_HIDE_BLIZZ = "Скрывать стандартные фреймы Blizzard (Игрок, Цель, Фокус, Боссы)",
    CK_UF_POWER = "Полоска маны / ресурса снизу",
    CK_UF_TGT_CAST = "Кастбар цели под фреймом цели",
    CK_UF_TGT_AURAS = "Доты и баффы над фреймом цели",
    CK_UF_TOT = "Цель цели (ToT)",
    CK_UF_FOCUS = "Фокус (+ Кастбар фокуса)",
    CK_UF_PET = "Фрейм питомца (Pet)",
    CK_UF_BOSS = "Фреймы боссов (Boss 1..5)",
    M12_GRP_GEO = "2. Размеры полосы здоровья, Диаметр портрета и Шрифт",
    SL_UF_WIDTH = "Ширина полосы ХП (px)",
    SL_UF_HEIGHT = "Высота полосы ХП (px)",
    SL_UF_PORT_SIZE = "Диаметр портрета (px)",
    SL_UF_FONT_SIZE = "Размер шрифта (pt)",
    SL_UF_CAST_H = "Высота кастбара цели (px)",
    SL_UF_OOC_ALPHA = "Прозрачность вне боя",
    M12_GRP_POS = "3. Координаты Игрока и Цели (или тяни мышкой через «Редактировать HUD»)",
    SL_UF_PLAYER_X = "Фрейм Игрока X (px)",
    SL_UF_PLAYER_Y = "Фрейм Игрока Y (px)",
    SL_UF_TARGET_X = "Фрейм Цели X (px)",
    SL_UF_TARGET_Y = "Фрейм Цели Y (px)",
    SL_UF_TCAST_X = "Кастбар Цели X (px)",
    SL_UF_TCAST_Y = "Кастбар Цели Y (px)",
    EM_MOVER_UF_PLAYER = "Юнитфрейм: Игрок",
    EM_MOVER_UF_TARGET = "Юнитфрейм: Цель",
    EM_MOVER_UF_TCAST = "Кастбар Цели",
    EM_MOVER_UF_TOT = "Цель цели (ToT)",
    EM_MOVER_UF_FOCUS = "Юнитфрейм: Фокус",
    EM_MOVER_UF_PET = "Юнитфрейм: Питомец",
    EM_MOVER_UF_BOSS = "Фреймы Боссов (1..5)",
    MSG_ELVUF_DISABLED = "|cffa335eeSpArc Юнитфреймы:|r Юнитфреймы ElvUI отключены. Напиши |cffffd100/reload|r для чистого применения.",
  })
end

function SpArc:IsUnitFramesEnabled()
  local db = SpArc:EnsureDB()
  return (db and db.visual and db.visual.enableUnitFrames ~= false) or false
end

local function FormatAbbrevHP(val)
  if type(val) ~= "number" or IsSecret(val) then return "" end
  if val >= 1000000000 then
    return string.format("%.1fB", val / 1000000000)
  elseif val >= 1000000 then
    return string.format("%.1fM", val / 1000000)
  elseif val >= 1000 then
    return string.format("%.0fK", val / 1000)
  end
  return tostring(math.floor(val + 0.5))
end

local function CreateFlatBorder(parent, thickness, r, g, b, a, levelOffset)
  local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  f:SetAllPoints(parent)
  f:SetFrameLevel(parent:GetFrameLevel() + (levelOffset or 2))
  f:SetBackdrop({
    edgeFile = FLAT_TEX,
    edgeSize = thickness or 1,
  })
  f:SetBackdropBorderColor(r or 0.04, g or 0.04, b or 0.06, a or 1.0)
  return f
end

---------------------------------------------------------------------------------------
--  1. BLIZZARD DEFAULT UNITFRAMES SUPPRESSION (SAFE OUT OF COMBAT)
---------------------------------------------------------------------------------------
local hiddenBlizzParent = CreateFrame("Frame", "SpArcHiddenBlizzUFParent", UIParent)
hiddenBlizzParent:Hide()
local suppressedBlizzFrames = {}

local function SuppressSingleBlizzFrame(f)
  if not f or suppressedBlizzFrames[f] then return end
  if InCombatLockdown and InCombatLockdown() then return end
  suppressedBlizzFrames[f] = true
  pcall(f.UnregisterAllEvents, f)
  if f.healthbar then pcall(f.healthbar.UnregisterAllEvents, f.healthbar) end
  if f.manabar then pcall(f.manabar.UnregisterAllEvents, f.manabar) end
  if f.spellbar then pcall(f.spellbar.UnregisterAllEvents, f.spellbar) end
  if f.UnregisterEvent then
    pcall(UnregisterUnitWatch, f)
  end
  pcall(f.Hide, f)
  pcall(f.SetParent, f, hiddenBlizzParent)
end

local function SyncBlizzardUnitFramesSuppression()
  if InCombatLockdown and InCombatLockdown() then return end
  local db = SpArc:EnsureDB()
  local v = db.visual or DEFAULT_VISUAL
  if not SpArc:IsUnitFramesEnabled() or v.ufHideBlizzard == false then
    return
  end
  SuppressSingleBlizzFrame(_G.PlayerFrame)
  SuppressSingleBlizzFrame(_G.TargetFrame)
  SuppressSingleBlizzFrame(_G.TargetFrameToT)
  if v.ufShowFocus ~= false then
    SuppressSingleBlizzFrame(_G.FocusFrame)
    SuppressSingleBlizzFrame(_G.FocusFrameToT)
  end
  if v.ufShowPet ~= false then
    SuppressSingleBlizzFrame(_G.PetFrame)
  end
  if v.ufShowBoss ~= false and _G.BossTargetFrameContainer then
    SuppressSingleBlizzFrame(_G.BossTargetFrameContainer)
    for i = 1, 5 do
      SuppressSingleBlizzFrame(_G["Boss" .. i .. "TargetFrame"])
    end
  end
end

---------------------------------------------------------------------------------------
--  2. UNIT COLOR & TEXT RESOLVERS (SECRET-SAFE 12.X)
---------------------------------------------------------------------------------------
local function GetUnitBarColor(unit, colorMode, isDemo, demoIsHostile)
  if colorMode == "DARK" then
    return COLOR_OBSIDIAN_DARK.r, COLOR_OBSIDIAN_DARK.g, COLOR_OBSIDIAN_DARK.b
  end
  if isDemo then
    if demoIsHostile then
      return COLOR_HOSTILE_RED.r, COLOR_HOSTILE_RED.g, COLOR_HOSTILE_RED.b
    end
    local _, pClass = UnitClass("player")
    local c = (pClass and not IsSecret(pClass) and RAID_CLASS_COLORS and RAID_CLASS_COLORS[pClass]) or nil
    if c then return c.r, c.g, c.b end
    return 0.90, 0.55, 0.12
  end
  if not unit or not SafeBool(UnitExists, unit) then
    return COLOR_HOSTILE_RED.r, COLOR_HOSTILE_RED.g, COLOR_HOSTILE_RED.b
  end
  local canAttack = SafeBool(UnitCanAttack, "player", unit)
  if SafeBool(UnitIsPlayer, unit) then
    if canAttack and unit ~= "player" and colorMode == "REACTION" then
      return COLOR_HOSTILE_RED.r, COLOR_HOSTILE_RED.g, COLOR_HOSTILE_RED.b
    end
    local okC, _, classFile = pcall(UnitClass, unit)
    if okC and not IsSecret(classFile) and type(classFile) == "string" and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] then
      local c = RAID_CLASS_COLORS[classFile]
      return c.r, c.g, c.b
    end
    if canAttack then
      return COLOR_HOSTILE_RED.r, COLOR_HOSTILE_RED.g, COLOR_HOSTILE_RED.b
    end
    return COLOR_FRIENDLY_GREEN.r, COLOR_FRIENDLY_GREEN.g, COLOR_FRIENDLY_GREEN.b
  end
  if not canAttack then
    return COLOR_FRIENDLY_GREEN.r, COLOR_FRIENDLY_GREEN.g, COLOR_FRIENDLY_GREEN.b
  end
  local okR, reaction = pcall(UnitReaction, unit, "player")
  if not okR or reaction == nil or IsSecret(reaction) then
    okR, reaction = pcall(UnitReaction, "player", unit)
  end
  local reactNum = (okR and not IsSecret(reaction) and type(reaction) == "number" and reaction) or 4
  local isHostile = SafeBool(UnitIsEnemy, "player", unit)
  local inCombat = SafeBool(UnitAffectingCombat, unit)
  local playerInCombat = (InCombatLockdown and InCombatLockdown()) or SafeBool(UnitAffectingCombat, "player")

  if reactNum <= 3 or isHostile or (inCombat and (playerInCombat or SafeBool(UnitIsUnit, unit .. "target", "player"))) then
    return COLOR_HOSTILE_RED.r, COLOR_HOSTILE_RED.g, COLOR_HOSTILE_RED.b
  else
    return COLOR_NEUTRAL_YELLOW.r, COLOR_NEUTRAL_YELLOW.g, COLOR_NEUTRAL_YELLOW.b
  end
end

local function GetUnitPowerBarColor(unit, isDemo)
  if isDemo then
    local p = POWER_COLORS[13]
    return p.r, p.g, p.b
  end
  if unit and UnitPowerType then
    local ok, pType = pcall(UnitPowerType, unit)
    if ok and not IsSecret(pType) and type(pType) == "number" and POWER_COLORS[pType] then
      local c = POWER_COLORS[pType]
      return c.r, c.g, c.b
    end
  end
  return 0.15, 0.55, 0.98
end

---------------------------------------------------------------------------------------
--  3. UNITFRAME FACTORY (CIRCULAR MASKED PORTRAIT + METRO BAR + CASTBAR + AURAS)
---------------------------------------------------------------------------------------
local ufFrames = {}
local bossFrames = {}
local targetCastbarFrame = nil

local function CreateCircularPortraitWidget(parent, side)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetSize(48, 48)
  holder:SetFrameLevel(parent:GetFrameLevel() + 8)
  holder.side = side -- "LEFT" or "RIGHT"

  -- 1. Outer Dark Obsidian Circle (Mask 1)
  local outerTex = holder:CreateTexture(nil, "BACKGROUND", nil, 0)
  outerTex:SetPoint("TOPLEFT", holder, "TOPLEFT", -3, 3)
  outerTex:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 3, -3)
  outerTex:SetColorTexture(0.04, 0.04, 0.06, 0.98)
  if holder.CreateMaskTexture then
    local m1 = holder:CreateMaskTexture()
    m1:SetTexture(PORTRAIT_MASK_TEX, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    m1:SetAllPoints(outerTex)
    outerTex:AddMaskTexture(m1)
    holder.outerMask = m1
  end
  holder.outerTex = outerTex

  -- 2. Middle Metallic / Class / Reaction Ring Circle (Mask 2)
  local ringTex = holder:CreateTexture(nil, "BACKGROUND", nil, 2)
  ringTex:SetPoint("TOPLEFT", holder, "TOPLEFT", -1, 1)
  ringTex:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 1, -1)
  ringTex:SetColorTexture(0.85, 0.72, 0.32, 0.96)
  if holder.CreateMaskTexture then
    local m2 = holder:CreateMaskTexture()
    m2:SetTexture(PORTRAIT_MASK_TEX, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    m2:SetAllPoints(ringTex)
    ringTex:AddMaskTexture(m2)
    holder.ringMask = m2
  end
  holder.ringTex = ringTex

  -- 3. Inner Dark Backing Circle (Mask 3)
  local innerBg = holder:CreateTexture(nil, "BORDER", nil, 0)
  innerBg:SetAllPoints(holder)
  innerBg:SetColorTexture(0.07, 0.07, 0.10, 1.0)
  if holder.CreateMaskTexture then
    local m3 = holder:CreateMaskTexture()
    m3:SetTexture(PORTRAIT_MASK_TEX, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    m3:SetAllPoints(innerBg)
    innerBg:AddMaskTexture(m3)
    holder.innerMask = m3
  end
  holder.innerBg = innerBg

  -- 4. 2D Portrait Texture (Masked Circle in CIRCLE mode, or unmasked in SQUARE mode)
  local portTex = holder:CreateTexture(nil, "ARTWORK", nil, 1)
  portTex:SetAllPoints(holder)
  if holder.CreateMaskTexture then
    local mPort = holder:CreateMaskTexture()
    mPort:SetTexture(PORTRAIT_MASK_TEX, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mPort:SetAllPoints(portTex)
    portTex:AddMaskTexture(mPort)
    holder.portMask = mPort
  end
  holder.portTex = portTex

  -- Square Border (only shown in SQUARE mode)
  local sqBorder = CreateFlatBorder(holder, 1, 0.04, 0.04, 0.06, 1.0, 3)
  sqBorder:Hide()
  holder.sqBorder = sqBorder

  -- Combat / Resting Badge on Portrait Corner
  local statusIcon = holder:CreateTexture(nil, "OVERLAY", nil, 4)
  statusIcon:SetSize(18, 18)
  statusIcon:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", -2, -2)
  statusIcon:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
  statusIcon:Hide()
  holder.statusIcon = statusIcon

  return holder
end

local function CreateStandaloneCastbar(name, parent, isTargetCastbar)
  local cbCont = CreateFrame("Frame", name, parent or UIParent)
  cbCont:SetSize(176, 16)
  cbCont:SetFrameStrata("MEDIUM")
  cbCont:SetFrameLevel(35)

  local iconBox = CreateFrame("Frame", nil, cbCont, "BackdropTemplate")
  iconBox:SetPoint("TOPLEFT", cbCont, "TOPLEFT", 0, 0)
  iconBox:SetSize(16, 16)
  iconBox:SetBackdrop({
    bgFile = FLAT_TEX,
    edgeFile = FLAT_TEX,
    edgeSize = 1,
  })
  iconBox:SetBackdropColor(0.06, 0.06, 0.08, 0.96)
  iconBox:SetBackdropBorderColor(0.04, 0.04, 0.06, 1.0)
  local icon = iconBox:CreateTexture(nil, "ARTWORK")
  icon:SetPoint("TOPLEFT", iconBox, "TOPLEFT", 1, -1)
  icon:SetPoint("BOTTOMRIGHT", iconBox, "BOTTOMRIGHT", -1, 1)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  iconBox.icon = icon
  cbCont.iconBox = iconBox

  local bar = CreateFrame("StatusBar", nil, cbCont)
  bar:SetPoint("TOPLEFT", iconBox, "TOPRIGHT", 1, 0)
  bar:SetPoint("BOTTOMRIGHT", cbCont, "BOTTOMRIGHT", 0, 0)
  bar:SetStatusBarTexture(FLAT_TEX)
  bar:SetMinMaxValues(0, 1)
  bar:SetValue(0)
  bar:SetStatusBarColor(COLOR_CAST_GOLD.r, COLOR_CAST_GOLD.g, COLOR_CAST_GOLD.b, 1.0)
  cbCont.bar = bar

  local bg = bar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(bar)
  bg:SetColorTexture(0.06, 0.06, 0.09, 0.94)
  cbCont.bg = bg

  cbCont.border = CreateFlatBorder(bar, 1, 0.04, 0.04, 0.06, 1.0, 2)

  local glow = CreateFrame("Frame", nil, cbCont, "BackdropTemplate")
  glow:SetPoint("TOPLEFT", cbCont, "TOPLEFT", -1, 1)
  glow:SetPoint("BOTTOMRIGHT", cbCont, "BOTTOMRIGHT", 1, -1)
  glow:SetFrameLevel(bar:GetFrameLevel() + 4)
  glow:SetBackdrop({
    edgeFile = FLAT_TEX,
    edgeSize = 1,
  })
  glow:SetBackdropBorderColor(1.00, 0.85, 0.20, 0.95)
  glow:Hide()
  cbCont.glow = glow

  local txtFrame = CreateFrame("Frame", nil, bar)
  txtFrame:SetAllPoints(bar)
  txtFrame:SetFrameLevel(bar:GetFrameLevel() + 6)

  local timeText = txtFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyCyrFont(timeText, 10)
  timeText:SetPoint("RIGHT", txtFrame, "RIGHT", -4, 0)
  timeText:SetJustifyH("RIGHT")
  timeText:SetWordWrap(false)
  timeText:SetTextColor(1.0, 0.98, 0.90, 1.0)
  cbCont.timeText = timeText

  local spellText = txtFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyCyrFont(spellText, 10)
  spellText:SetPoint("LEFT", txtFrame, "LEFT", 5, 0)
  spellText:SetPoint("RIGHT", timeText, "LEFT", -4, 0)
  spellText:SetJustifyH("LEFT")
  spellText:SetWordWrap(false)
  spellText:SetTextColor(1.0, 1.0, 1.0, 1.0)
  cbCont.spellText = spellText

  cbCont.isTargetCastbar = isTargetCastbar
  cbCont:Hide()
  return cbCont
end

local function CreateSpArcUnitFrame(frameName, unitToken, portraitSide, isCompact)
  local f = CreateFrame("Button", frameName, UIParent, "SecureUnitButtonTemplate, BackdropTemplate")
  f.unit = unitToken
  f.portraitSide = portraitSide -- "LEFT", "RIGHT", or nil
  f.isCompact = isCompact and true or false

  f:SetSize(isCompact and 130 or 176, isCompact and 24 or 28)
  f:SetFrameStrata("LOW")
  f:SetFrameLevel(20)
  f:SetAttribute("unit", unitToken)
  f:SetAttribute("*type1", "target")
  f:SetAttribute("*type2", "togglemenu")
  f:RegisterForClicks("AnyUp")

  -- Tooltip on hover
  f:SetScript("OnEnter", function(self)
    if _G.UnitFrame_OnEnter then
      pcall(_G.UnitFrame_OnEnter, self)
    elseif _G.GameTooltip and self.unit and SafeBool(UnitExists, self.unit) then
      _G.GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
      _G.GameTooltip:SetUnit(self.unit)
      _G.GameTooltip:Show()
    end
  end)
  f:SetScript("OnLeave", function(self)
    if _G.UnitFrame_OnLeave then
      pcall(_G.UnitFrame_OnLeave, self)
    elseif _G.GameTooltip then
      _G.GameTooltip:Hide()
    end
  end)

  -- Bar Container
  local barContainer = CreateFrame("Frame", nil, f, "BackdropTemplate")
  barContainer:SetAllPoints(f)
  barContainer:SetFrameLevel(f:GetFrameLevel() + 1)
  CreateFlatBorder(barContainer, 1, 0.03, 0.03, 0.05, 1.0, 4)
  f.barContainer = barContainer

  local barBg = barContainer:CreateTexture(nil, "BACKGROUND")
  barBg:SetAllPoints(barContainer)
  barBg:SetColorTexture(0.06, 0.06, 0.09, 0.94)
  f.barBg = barBg

  -- Health StatusBar
  local hb = CreateFrame("StatusBar", nil, barContainer)
  hb:SetPoint("TOPLEFT", barContainer, "TOPLEFT", 1, -1)
  hb:SetPoint("BOTTOMRIGHT", barContainer, "BOTTOMRIGHT", -1, isCompact and 1 or 6)
  hb:SetStatusBarTexture(FLAT_TEX)
  hb:SetMinMaxValues(0, 100)
  hb:SetValue(100)
  hb:SetStatusBarColor(COLOR_HOSTILE_RED.r, COLOR_HOSTILE_RED.g, COLOR_HOSTILE_RED.b, 1.0)
  f.healthBar = hb

  -- Top specular sheen
  local sheen = hb:CreateTexture(nil, "ARTWORK")
  sheen:SetPoint("TOPLEFT", hb, "TOPLEFT", 0, 0)
  sheen:SetPoint("TOPRIGHT", hb, "TOPRIGHT", 0, 0)
  sheen:SetHeight(1)
  sheen:SetColorTexture(1.0, 1.0, 1.0, 0.16)
  f.sheen = sheen

  -- Power StatusBar (bottom strip)
  local pb = CreateFrame("StatusBar", nil, barContainer)
  pb:SetPoint("TOPLEFT", hb, "BOTTOMLEFT", 0, -1)
  pb:SetPoint("BOTTOMRIGHT", barContainer, "BOTTOMRIGHT", -1, 1)
  pb:SetStatusBarTexture(FLAT_TEX)
  pb:SetMinMaxValues(0, 100)
  pb:SetValue(100)
  pb:SetStatusBarColor(0.15, 0.55, 0.98, 1.0)
  f.powerBar = pb

  local pbSep = barContainer:CreateTexture(nil, "OVERLAY")
  pbSep:SetPoint("TOPLEFT", hb, "BOTTOMLEFT", 0, 0)
  pbSep:SetPoint("TOPRIGHT", hb, "BOTTOMRIGHT", 0, 0)
  pbSep:SetHeight(1)
  pbSep:SetColorTexture(0.03, 0.03, 0.05, 1.0)
  f.powerSep = pbSep

  -- Text Layer Frame
  local txtFrame = CreateFrame("Frame", nil, barContainer)
  txtFrame:SetAllPoints(hb)
  txtFrame:SetFrameLevel(barContainer:GetFrameLevel() + 6)
  f.txtFrame = txtFrame

  -- Name Text (Above the bar for primary frames, matching screenshot!)
  local nameText = txtFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(nameText, isCompact and 10 or 11)
  if isCompact then
    nameText:SetPoint("LEFT", txtFrame, "LEFT", 5, 0)
    nameText:SetJustifyH("LEFT")
  else
    nameText:SetPoint("BOTTOM", barContainer, "TOP", 0, 3)
    nameText:SetJustifyH("CENTER")
  end
  nameText:SetWordWrap(false)
  nameText:SetTextColor(1.0, 1.0, 1.0, 1.0)
  f.nameText = nameText

  -- Centered Health Value Text ("94% | 78K" for primary frames, right-aligned "%" for compact frames)
  local hpText = txtFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyCyrFont(hpText, isCompact and 10 or 11)
  if isCompact then
    hpText:SetPoint("RIGHT", txtFrame, "RIGHT", -5, 0)
    hpText:SetJustifyH("RIGHT")
    nameText:SetPoint("RIGHT", hpText, "LEFT", -4, 0)
  else
    hpText:SetPoint("CENTER", txtFrame, "CENTER", 0, 0)
    hpText:SetJustifyH("CENTER")
  end
  hpText:SetWordWrap(false)
  hpText:SetTextColor(1.0, 1.0, 1.0, 1.0)
  f.hpText = hpText

  -- Optional Circular Portrait (Left on Player/Focus, Right on Target)
  if portraitSide then
    local port = CreateCircularPortraitWidget(f, portraitSide)
    if portraitSide == "LEFT" then
      port:SetPoint("RIGHT", barContainer, "LEFT", 4, 0)
    else
      port:SetPoint("LEFT", barContainer, "RIGHT", -4, 0)
    end
    f.portrait = port
  end

  -- Aura Icons Row (for Target Frame)
  if unitToken == "target" then
    f.auraIcons = {}
    for i = 1, 8 do
      local aBox = CreateFrame("Frame", nil, f, "BackdropTemplate")
      aBox:SetSize(22, 22)
      aBox:SetPoint("BOTTOMLEFT", barContainer, "TOPLEFT", (i - 1) * 24, 18)
      aBox:SetBackdrop({
        bgFile = FLAT_TEX,
        edgeFile = FLAT_TEX,
        edgeSize = 1,
      })
      aBox:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
      aBox:SetBackdropBorderColor(0.15, 0.15, 0.22, 1.0)
      local tex = aBox:CreateTexture(nil, "ARTWORK")
      tex:SetPoint("TOPLEFT", 1, -1)
      tex:SetPoint("BOTTOMRIGHT", -1, 1)
      tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      aBox.icon = tex
      local cnt = aBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      ApplyCyrFont(cnt, 9)
      cnt:SetPoint("BOTTOMRIGHT", aBox, "BOTTOMRIGHT", -1, 1)
      cnt:SetTextColor(1, 0.92, 0.25, 1)
      aBox.count = cnt
      aBox:Hide()
      f.auraIcons[i] = aBox
    end
  end

  -- Attached Castbar for Focus & Boss frames
  if unitToken == "focus" or unitToken:find("^boss") then
    local cb = CreateStandaloneCastbar(frameName .. "_Castbar", f, false)
    cb:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -3)
    cb:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -3)
    cb:SetHeight(14)
    cb.iconBox:SetSize(14, 14)
    f.attachedCastbar = cb
  end

  if RegisterUnitWatch and not (InCombatLockdown and InCombatLockdown()) then
    pcall(RegisterUnitWatch, f)
    f._unitWatchRegistered = true
  end

  return f
end

-- Create all UnitFrames at load time
ufFrames.player = CreateSpArcUnitFrame("SpArcUF_Player", "player", "LEFT", false)
ufFrames.target = CreateSpArcUnitFrame("SpArcUF_Target", "target", "RIGHT", false)
ufFrames.tot    = CreateSpArcUnitFrame("SpArcUF_ToT", "targettarget", nil, true)
ufFrames.focus  = CreateSpArcUnitFrame("SpArcUF_Focus", "focus", "LEFT", true)
ufFrames.pet    = CreateSpArcUnitFrame("SpArcUF_Pet", "pet", nil, true)

targetCastbarFrame = CreateStandaloneCastbar("SpArcUF_TargetCastbar", UIParent, true)

for i = 1, 5 do
  bossFrames[i] = CreateSpArcUnitFrame("SpArcUF_Boss" .. i, "boss" .. i, nil, false)
end

---------------------------------------------------------------------------------------
--  4. LIVE UPDATERS (PORTRAIT, HEALTH/POWER, AURAS, CASTBARS)
---------------------------------------------------------------------------------------
local function UpdatePortraitForUnitFrame(f, unit, r, g, b, isDemo)
  local port = f.portrait
  if not port then return end
  local db = SpArc:EnsureDB()
  local v = db.visual or DEFAULT_VISUAL
  local style = v.ufPortraitStyle or "CIRCLE"
  if style == "NONE" then
    port:Hide()
    return
  end
  port:Show()

  if style == "SQUARE" then
    port.outerTex:Hide()
    port.ringTex:Hide()
    port.innerBg:Hide()
    if port.portMask then
      pcall(port.portTex.RemoveMaskTexture, port.portTex, port.portMask)
      port._maskRemoved = true
    end
    port.sqBorder:Show()
    port.sqBorder:SetBackdropBorderColor(r or 0.3, g or 0.3, b or 0.3, 1.0)
  else
    port.outerTex:Show()
    port.ringTex:Show()
    port.innerBg:Show()
    port.ringTex:SetColorTexture(r or 0.85, g or 0.72, b or 0.32, 0.96)
    if port._maskRemoved and port.portMask then
      pcall(port.portTex.AddMaskTexture, port.portTex, port.portMask)
      port._maskRemoved = false
    end
    port.sqBorder:Hide()
  end

  if isDemo then
    local pUnit = SafeBool(UnitExists, unit) and unit or "player"
    if SetPortraitTexture then
      pcall(SetPortraitTexture, port.portTex, pUnit)
      port.portTex:SetTexCoord(0, 1, 0, 1)
    end
  elseif unit and SafeBool(UnitExists, unit) then
    if SetPortraitTexture then
      pcall(SetPortraitTexture, port.portTex, unit)
      port.portTex:SetTexCoord(0, 1, 0, 1)
    end
  end

  if unit == "player" and port.statusIcon then
    if SafeBool(UnitAffectingCombat, "player") then
      port.statusIcon:SetTexCoord(0.5, 1.0, 0.0, 0.49)
      port.statusIcon:Show()
    elseif IsResting and SafeBool(IsResting) then
      port.statusIcon:SetTexCoord(0.0, 0.5, 0.0, 0.421875)
      port.statusIcon:Show()
    else
      port.statusIcon:Hide()
    end
  elseif port.statusIcon then
    port.statusIcon:Hide()
  end
end

local function UpdateTargetAuras(f, isDemo)
  if not f or not f.auraIcons then return end
  local db = SpArc:EnsureDB()
  local v = db.visual or DEFAULT_VISUAL
  if v.ufShowTargetAuras == false then
    for i = 1, #f.auraIcons do f.auraIcons[i]:Hide() end
    return
  end

  if isDemo and not SafeBool(UnitExists, "target") then
    local demoIcons = { 34914, 589, 335467 }
    for i = 1, #f.auraIcons do
      local box = f.auraIcons[i]
      if demoIcons[i] then
        local tex = (i == 1 and 136208) or (i == 2 and 136207) or 252997
        box.icon:SetTexture(tex)
        box.count:SetText("")
        box:SetBackdropBorderColor(0.68, 0.32, 1.0, 1.0)
        box:Show()
      else
        box:Hide()
      end
    end
    return
  end

  if not SafeBool(UnitExists, "target") or not (C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex) then
    for i = 1, #f.auraIcons do f.auraIcons[i]:Hide() end
    return
  end

  local shown = 0
  -- 1. Player's own debuffs on target first
  for idx = 1, 16 do
    if shown >= #f.auraIcons then break end
    local ok, aura = pcall(C_UnitAuras.GetDebuffDataByIndex, "target", idx, "PLAYER")
    if not ok or type(aura) ~= "table" then break end
    shown = shown + 1
    local box = f.auraIcons[shown]
    pcall(box.icon.SetTexture, box.icon, aura.icon or 136243)
    if not IsSecret(aura.applications) and type(aura.applications) == "number" and aura.applications > 1 then
      box.count:SetText(tostring(aura.applications))
    else
      box.count:SetText("")
    end
    box:SetBackdropBorderColor(0.72, 0.35, 1.0, 1.0)
    box:Show()
  end

  -- 2. Target buffs (if room remains)
  if C_UnitAuras.GetBuffDataByIndex and shown < #f.auraIcons then
    for idx = 1, 8 do
      if shown >= #f.auraIcons then break end
      local ok, aura = pcall(C_UnitAuras.GetBuffDataByIndex, "target", idx)
      if not ok or type(aura) ~= "table" then break end
      shown = shown + 1
      local box = f.auraIcons[shown]
      pcall(box.icon.SetTexture, box.icon, aura.icon or 136243)
      if not IsSecret(aura.applications) and type(aura.applications) == "number" and aura.applications > 1 then
        box.count:SetText(tostring(aura.applications))
      else
        box.count:SetText("")
      end
      box:SetBackdropBorderColor(0.28, 0.65, 0.95, 0.95)
      box:Show()
    end
  end

  for i = shown + 1, #f.auraIcons do
    f.auraIcons[i]:Hide()
  end
end

local function UpdateSingleCastbarWidget(cbCont, unit, now, isDemo)
  if not cbCont then return end
  local db = SpArc:EnsureDB()
  local v = db.visual or DEFAULT_VISUAL
  if cbCont.isTargetCastbar and v.ufShowTargetCastbar == false then
    cbCont:Hide()
    return
  end

  local isCasting, isInterruptible, isChannel, spellName, spellIcon, remSec, durSec, _, rawNotInterruptible =
    SpArc:GetUnitCastInterruptState(unit, now)

  if not isCasting and isDemo then
    local cycle = now % 4.0
    isCasting = true
    isInterruptible = true
    isChannel = false
    spellName = "Arcane Salvo"
    spellIcon = 135734
    durSec = 2.5
    remSec = math.max(0.1, 2.5 - (cycle % 2.5))
  end

  if not isCasting then
    if cbCont:IsShown() then cbCont:Hide() end
    return
  end

  cbCont.iconBox.icon:SetTexture(spellIcon or 136243)
  pcall(cbCont.spellText.SetText, cbCont.spellText, spellName or "Cast")

  local usedTimerDuration = false
  if not isDemo and cbCont.bar.SetTimerDuration then
    local durObj = nil
    if isChannel and UnitChannelDuration then
      local okD, d = pcall(UnitChannelDuration, unit)
      if okD and d then durObj = d end
    elseif not isChannel and UnitCastingDuration then
      local okD, d = pcall(UnitCastingDuration, unit)
      if okD and d then durObj = d end
    end
    if durObj and _G.Enum and _G.Enum.StatusBarTimerDirection and _G.Enum.StatusBarInterpolation then
      local dir = isChannel and _G.Enum.StatusBarTimerDirection.RemainingTime or _G.Enum.StatusBarTimerDirection.ElapsedTime
      local okTD = pcall(cbCont.bar.SetTimerDuration, cbCont.bar, durObj, _G.Enum.StatusBarInterpolation.Immediate, dir)
      if okTD then usedTimerDuration = true end
    end
  end

  if not usedTimerDuration then
    local total = math.max(0.1, durSec or 1.5)
    local val = isChannel and math.max(0, remSec or 0) or math.max(0, total - (remSec or 0))
    cbCont.bar:SetMinMaxValues(0, total)
    cbCont.bar:SetValue(val)
  end

  if remSec and remSec > 0 and remSec < 60 then
    cbCont.timeText:SetText(string.format("%.1f", remSec))
  else
    cbCont.timeText:SetText("")
  end

  if rawNotInterruptible ~= nil and IsSecret(rawNotInterruptible) then
    if _G.C_CurveUtil and _G.C_CurveUtil.EvaluateColorValueFromBoolean then
      local okR, cR = pcall(_G.C_CurveUtil.EvaluateColorValueFromBoolean, rawNotInterruptible, COLOR_CAST_GREY.r, COLOR_CAST_GOLD.r)
      local okG, cG = pcall(_G.C_CurveUtil.EvaluateColorValueFromBoolean, rawNotInterruptible, COLOR_CAST_GREY.g, COLOR_CAST_GOLD.g)
      local okB, cB = pcall(_G.C_CurveUtil.EvaluateColorValueFromBoolean, rawNotInterruptible, COLOR_CAST_GREY.b, COLOR_CAST_GOLD.b)
      if okR and okG and okB then
        pcall(cbCont.bar.SetStatusBarColor, cbCont.bar, cR, cG, cB, 1.0)
      end
    end
    cbCont.glow:Show()
    if cbCont.glow.SetAlphaFromBoolean then
      pcall(cbCont.glow.SetAlphaFromBoolean, cbCont.glow, rawNotInterruptible, 0, 1)
    end
  elseif isInterruptible then
    cbCont.bar:SetStatusBarColor(COLOR_CAST_GOLD.r, COLOR_CAST_GOLD.g, COLOR_CAST_GOLD.b, 1.0)
    cbCont.glow:SetAlpha(1.0)
    cbCont.glow:Show()
  else
    cbCont.bar:SetStatusBarColor(COLOR_CAST_GREY.r, COLOR_CAST_GREY.g, COLOR_CAST_GREY.b, 1.0)
    cbCont.glow:Hide()
  end

  if not cbCont:IsShown() then
    cbCont:Show()
  end
end

local function UpdateSingleUnitFrame(f, now, isDemo)
  if not f then return end
  local unit = f.unit
  local exists = SafeBool(UnitExists, unit)
  if not exists and not isDemo then
    return
  end

  local db = SpArc:EnsureDB()
  local v = db.visual or DEFAULT_VISUAL
  local colorMode = v.ufColorMode or "CLASS"
  local demoHostile = (unit ~= "player" and unit ~= "pet")
  local r, g, b = GetUnitBarColor(unit, colorMode, isDemo and not exists, demoHostile)
  f.healthBar:SetStatusBarColor(r, g, b, 1.0)

  -- Portrait
  if f.portrait then
    UpdatePortraitForUnitFrame(f, unit, r, g, b, isDemo and not exists)
  end

  -- Name
  if exists then
    local okN, uName = pcall(UnitName, unit)
    if okN and uName ~= nil then
      pcall(f.nameText.SetText, f.nameText, uName)
    end
  else
    local demoNames = {
      player = (UnitName and UnitName("player")) or "Yoxzene",
      target = "Raiding Caster",
      targettarget = (UnitName and UnitName("player")) or "Yoxzene",
      focus = "Void Ascendant",
      pet = "Shadowfiend",
      boss1 = "Harbinger Xal'atath",
      boss2 = "Nether-Prince",
      boss3 = "Voidweaver",
      boss4 = "Shadowguard",
      boss5 = "Dark Conduit",
    }
    f.nameText:SetText(demoNames[unit] or unit)
  end

  -- Health Bar & Value Text ("94% | 78K")
  if exists then
    local ok1, hp = pcall(UnitHealth, unit)
    local ok2, maxHp = pcall(UnitHealthMax, unit)
    if ok1 and ok2 and hp ~= nil and maxHp ~= nil then
      pcall(f.healthBar.SetMinMaxValues, f.healthBar, 0, maxHp)
      pcall(f.healthBar.SetValue, f.healthBar, hp)
      if not IsSecret(hp) and not IsSecret(maxHp) and type(hp) == "number" and type(maxHp) == "number" and maxHp > 0 then
        local pct = (hp / maxHp) * 100
        if f.isCompact then
          f.hpText:SetText(string.format("%.0f%%", pct))
        else
          local pctStr = (pct < 99.95 and pct > 0 and unit ~= "player") and string.format("%.1f%%", pct) or string.format("%.0f%%", pct)
          f.hpText:SetText(string.format("%s | %s", pctStr, FormatAbbrevHP(hp)))
        end
      elseif _G.UnitHealthPercent then
        local okP, sPct = pcall(_G.UnitHealthPercent, unit, true, _G.CurveConstants and _G.CurveConstants.ScaleTo100)
        if okP and sPct ~= nil then
          pcall(f.hpText.SetFormattedText, f.hpText, "%.0f%%", sPct)
        else
          f.hpText:SetText("")
        end
      else
        f.hpText:SetText("")
      end
    end
  else
    f.healthBar:SetMinMaxValues(0, 100)
    local demoPct = (unit == "player" and 94) or (unit == "target" and 82.9) or 76
    f.healthBar:SetValue(demoPct)
    if f.isCompact then
      f.hpText:SetText(string.format("%.0f%%", demoPct))
    elseif unit == "player" then
      f.hpText:SetText("94% | 78K")
    else
      f.hpText:SetText("82.9% | 190K")
    end
  end

  -- Power Bar
  if f.powerBar then
    if not f.isCompact and v.ufShowPowerBar ~= false then
      f.powerBar:Show()
      f.powerSep:Show()
      local pr, pg, pb = GetUnitPowerBarColor(unit, isDemo and not exists)
      f.powerBar:SetStatusBarColor(pr, pg, pb, 1.0)
      if exists and UnitPower and UnitPowerMax then
        local okP1, pw = pcall(UnitPower, unit)
        local okP2, maxPw = pcall(UnitPowerMax, unit)
        if okP1 and okP2 and pw ~= nil and maxPw ~= nil then
          pcall(f.powerBar.SetMinMaxValues, f.powerBar, 0, maxPw)
          pcall(f.powerBar.SetValue, f.powerBar, pw)
        end
      else
        f.powerBar:SetMinMaxValues(0, 100)
        f.powerBar:SetValue(80)
      end
    else
      f.powerBar:Hide()
      f.powerSep:Hide()
    end
  end

  -- Out-of-Combat Alpha
  local inCombat = SafeBool(UnitAffectingCombat, "player")
  local oocAlpha = tonumber(v.ufOocAlpha) or 0.85
  if inCombat or isDemo or SafeBool(UnitExists, "target") then
    f:SetAlpha(1.0)
  else
    f:SetAlpha(oocAlpha)
  end

  if unit == "target" then
    UpdateTargetAuras(f, isDemo)
  end
  if f.attachedCastbar then
    UpdateSingleCastbarWidget(f.attachedCastbar, unit, now, isDemo and unit == "focus")
  end
end

---------------------------------------------------------------------------------------
--  5. LAYOUT, GEOMETRY & UNIT WATCH SYNCHRONIZATION
---------------------------------------------------------------------------------------
local function SyncUnitFrameWatchState(f, shouldEnable, forceDemoShow)
  if not f then return end
  local inLockdown = InCombatLockdown and InCombatLockdown()
  if not shouldEnable then
    if not inLockdown then
      if f._unitWatchRegistered and UnregisterUnitWatch then
        pcall(UnregisterUnitWatch, f)
        f._unitWatchRegistered = false
      end
      f:Hide()
    else
      f:SetAlpha(0)
    end
    return
  end

  if forceDemoShow then
    if not inLockdown then
      if f._unitWatchRegistered and UnregisterUnitWatch then
        pcall(UnregisterUnitWatch, f)
        f._unitWatchRegistered = false
      end
      f:Show()
    end
  else
    if not inLockdown then
      if not f._unitWatchRegistered and RegisterUnitWatch then
        pcall(RegisterUnitWatch, f)
        f._unitWatchRegistered = true
      end
      if SafeBool(UnitExists, f.unit) then
        f:Show()
      else
        f:Hide()
      end
    end
  end
end

function SpArc:ApplyUnitFramesSettings()
  local db = SpArc:EnsureDB()
  local v = db.visual or DEFAULT_VISUAL
  local enabled = SpArc:IsUnitFramesEnabled()
  local isDemo = (SpArc.testMode or SpArc.editModeActive) and true or false

  SyncBlizzardUnitFramesSuppression()

  local w = tonumber(v.ufWidth) or 176
  local h = tonumber(v.ufHeight) or 28
  local portSize = tonumber(v.ufPortraitSize) or 48
  local fSize = tonumber(v.ufFontSize) or 11
  local cbH = tonumber(v.ufTargetCastHeight) or 16
  local showPower = (v.ufShowPowerBar ~= false)
  local pbHeight = showPower and math.max(4, math.floor(h * 0.20 + 0.5)) or 0

  local function ApplyPrimaryGeometry(f, x, y)
    if not (InCombatLockdown and InCombatLockdown()) then
      f:SetSize(w, h)
      f:ClearAllPoints()
      f:SetPoint("CENTER", UIParent, "CENTER", x, y)
    end
    f.healthBar:SetPoint("BOTTOMRIGHT", f.barContainer, "BOTTOMRIGHT", -1, showPower and (pbHeight + 1) or 1)
    if f.portrait then
      f.portrait:SetSize(portSize, portSize)
    end
    ApplyCyrFont(f.nameText, fSize)
    ApplyCyrFont(f.hpText, fSize)
  end

  local function ApplyCompactGeometry(f, x, y, cw, ch)
    if not (InCombatLockdown and InCombatLockdown()) then
      f:SetSize(cw, ch)
      f:ClearAllPoints()
      f:SetPoint("CENTER", UIParent, "CENTER", x, y)
    end
    if f.portrait then
      local cps = math.max(28, ch + 8)
      f.portrait:SetSize(cps, cps)
    end
    ApplyCyrFont(f.nameText, math.max(9, fSize - 1))
    ApplyCyrFont(f.hpText, math.max(9, fSize - 1))
  end

  ApplyPrimaryGeometry(ufFrames.player, tonumber(v.ufPlayerX) or -260, tonumber(v.ufPlayerY) or -145)
  ApplyPrimaryGeometry(ufFrames.target, tonumber(v.ufTargetX) or 260, tonumber(v.ufTargetY) or -145)
  ApplyCompactGeometry(ufFrames.tot, tonumber(v.ufToTX) or 425, tonumber(v.ufToTY) or -145, math.max(110, math.floor(w * 0.68)), math.max(20, h - 6))
  ApplyCompactGeometry(ufFrames.focus, tonumber(v.ufFocusX) or -430, tonumber(v.ufFocusY) or -40, math.max(130, math.floor(w * 0.84)), math.max(22, h - 4))
  ApplyCompactGeometry(ufFrames.pet, tonumber(v.ufPetX) or -260, tonumber(v.ufPetY) or -194, math.max(120, math.floor(w * 0.76)), math.max(20, h - 6))

  local bossBaseX = tonumber(v.ufBossX) or 460
  local bossBaseY = tonumber(v.ufBossY) or 140
  for i = 1, 5 do
    ApplyPrimaryGeometry(bossFrames[i], bossBaseX, bossBaseY - (i - 1) * (h + 34))
  end

  if targetCastbarFrame then
    targetCastbarFrame:SetSize(w, cbH)
    targetCastbarFrame.iconBox:SetSize(cbH, cbH)
    targetCastbarFrame:ClearAllPoints()
    targetCastbarFrame:SetPoint("CENTER", UIParent, "CENTER", tonumber(v.ufTargetCastX) or 260, tonumber(v.ufTargetCastY) or -182)
    local cbf = math.max(9, math.min(13, cbH - 4))
    ApplyCyrFont(targetCastbarFrame.spellText, cbf)
    ApplyCyrFont(targetCastbarFrame.timeText, cbf)
  end

  SyncUnitFrameWatchState(ufFrames.player, enabled, isDemo)
  SyncUnitFrameWatchState(ufFrames.target, enabled, isDemo)
  SyncUnitFrameWatchState(ufFrames.tot,    enabled and (v.ufShowToT ~= false), isDemo)
  SyncUnitFrameWatchState(ufFrames.focus,  enabled and (v.ufShowFocus ~= false), isDemo)
  SyncUnitFrameWatchState(ufFrames.pet,    enabled and (v.ufShowPet ~= false), isDemo)
  for i = 1, 5 do
    SyncUnitFrameWatchState(bossFrames[i], enabled and (v.ufShowBoss ~= false), isDemo and i <= 2)
  end

  SpArc:UpdateUnitFrames()
  if SpArc.SyncEditModeMovers then
    SpArc:SyncEditModeMovers()
  end
end

function SpArc:UpdateUnitFrames(now)
  if not SpArc:IsUnitFramesEnabled() then
    if targetCastbarFrame and targetCastbarFrame:IsShown() then
      targetCastbarFrame:Hide()
    end
    return
  end
  now = now or GetTime()
  local isDemo = (SpArc.testMode or SpArc.editModeActive) and true or false

  for _, f in pairs(ufFrames) do
    if f:IsShown() then
      UpdateSingleUnitFrame(f, now, isDemo)
    end
  end
  for i = 1, 5 do
    if bossFrames[i]:IsShown() then
      UpdateSingleUnitFrame(bossFrames[i], now, isDemo)
    end
  end
  if targetCastbarFrame then
    UpdateSingleCastbarWidget(targetCastbarFrame, "target", now, isDemo)
  end
end

---------------------------------------------------------------------------------------
--  6. REGISTER UNITFRAME MOVERS WITH SPARC EDIT MODE ("РЕДАКТИРОВАТЬ")
---------------------------------------------------------------------------------------
if SpArc.RegisterEditMover then
  SpArc:RegisterEditMover({
    id = "UF_PLAYER",
    labelKey = "EM_MOVER_UF_PLAYER",
    keyX = "ufPlayerX",
    keyY = "ufPlayerY",
    defaultX = -260,
    defaultY = -145,
    width = 216,
    height = 48,
    color = { 0.08, 0.28, 0.44 },
    borderColor = { 0.30, 0.82, 1.00 },
    isEnabled = function() return SpArc:IsUnitFramesEnabled() end,
    getSize = function(v)
      return (tonumber(v and v.ufWidth) or 176) + 44, math.max(36, tonumber(v and v.ufPortraitSize) or 48)
    end,
    onChanged = function() SpArc:ApplyUnitFramesSettings() end,
  })

  SpArc:RegisterEditMover({
    id = "UF_TARGET",
    labelKey = "EM_MOVER_UF_TARGET",
    keyX = "ufTargetX",
    keyY = "ufTargetY",
    defaultX = 260,
    defaultY = -145,
    width = 216,
    height = 48,
    color = { 0.36, 0.12, 0.14 },
    borderColor = { 1.00, 0.42, 0.42 },
    isEnabled = function() return SpArc:IsUnitFramesEnabled() end,
    getSize = function(v)
      return (tonumber(v and v.ufWidth) or 176) + 44, math.max(36, tonumber(v and v.ufPortraitSize) or 48)
    end,
    onChanged = function() SpArc:ApplyUnitFramesSettings() end,
  })

  SpArc:RegisterEditMover({
    id = "UF_TARGET_CAST",
    labelKey = "EM_MOVER_UF_TCAST",
    keyX = "ufTargetCastX",
    keyY = "ufTargetCastY",
    defaultX = 260,
    defaultY = -182,
    width = 176,
    height = 22,
    color = { 0.34, 0.26, 0.08 },
    borderColor = { 1.00, 0.82, 0.20 },
    isEnabled = function()
      local db = SpArc:EnsureDB()
      return SpArc:IsUnitFramesEnabled() and (not db.visual or db.visual.ufShowTargetCastbar ~= false)
    end,
    getSize = function(v)
      return tonumber(v and v.ufWidth) or 176, math.max(20, (tonumber(v and v.ufTargetCastHeight) or 16) + 6)
    end,
    onChanged = function() SpArc:ApplyUnitFramesSettings() end,
  })

  SpArc:RegisterEditMover({
    id = "UF_TOT",
    labelKey = "EM_MOVER_UF_TOT",
    keyX = "ufToTX",
    keyY = "ufToTY",
    defaultX = 425,
    defaultY = -145,
    width = 124,
    height = 28,
    color = { 0.24, 0.14, 0.34 },
    borderColor = { 0.78, 0.48, 1.00 },
    isEnabled = function()
      local db = SpArc:EnsureDB()
      return SpArc:IsUnitFramesEnabled() and (not db.visual or db.visual.ufShowToT ~= false)
    end,
    onChanged = function() SpArc:ApplyUnitFramesSettings() end,
  })

  SpArc:RegisterEditMover({
    id = "UF_FOCUS",
    labelKey = "EM_MOVER_UF_FOCUS",
    keyX = "ufFocusX",
    keyY = "ufFocusY",
    defaultX = -430,
    defaultY = -40,
    width = 165,
    height = 36,
    color = { 0.12, 0.28, 0.38 },
    borderColor = { 0.38, 0.88, 1.00 },
    isEnabled = function()
      local db = SpArc:EnsureDB()
      return SpArc:IsUnitFramesEnabled() and (not db.visual or db.visual.ufShowFocus ~= false)
    end,
    onChanged = function() SpArc:ApplyUnitFramesSettings() end,
  })

  SpArc:RegisterEditMover({
    id = "UF_PET",
    labelKey = "EM_MOVER_UF_PET",
    keyX = "ufPetX",
    keyY = "ufPetY",
    defaultX = -260,
    defaultY = -194,
    width = 136,
    height = 26,
    color = { 0.08, 0.26, 0.20 },
    borderColor = { 0.25, 0.90, 0.65 },
    isEnabled = function()
      local db = SpArc:EnsureDB()
      return SpArc:IsUnitFramesEnabled() and (not db.visual or db.visual.ufShowPet ~= false)
    end,
    onChanged = function() SpArc:ApplyUnitFramesSettings() end,
  })

  SpArc:RegisterEditMover({
    id = "UF_BOSS",
    labelKey = "EM_MOVER_UF_BOSS",
    keyX = "ufBossX",
    keyY = "ufBossY",
    defaultX = 460,
    defaultY = 140,
    width = 180,
    height = 96,
    color = { 0.34, 0.12, 0.26 },
    borderColor = { 1.00, 0.38, 0.78 },
    isEnabled = function()
      local db = SpArc:EnsureDB()
      return SpArc:IsUnitFramesEnabled() and (not db.visual or db.visual.ufShowBoss ~= false)
    end,
    onChanged = function() SpArc:ApplyUnitFramesSettings() end,
  })
end

---------------------------------------------------------------------------------------
--  7. EVENT DRIVER & FAST TICKER
---------------------------------------------------------------------------------------
local ufDriver = CreateFrame("Frame")
ufDriver:RegisterEvent("PLAYER_ENTERING_WORLD")
ufDriver:RegisterEvent("PLAYER_TARGET_CHANGED")
ufDriver:RegisterEvent("PLAYER_FOCUS_CHANGED")
ufDriver:RegisterEvent("PLAYER_REGEN_ENABLED")
ufDriver:RegisterEvent("PLAYER_REGEN_DISABLED")
ufDriver:RegisterEvent("PLAYER_UPDATE_RESTING")
ufDriver:RegisterEvent("UNIT_PET")
ufDriver:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
ufDriver:RegisterEvent("UNIT_AURA")

local lastUFTick = 0
local lastWatchDemoState = false

ufDriver:SetScript("OnEvent", function(_, event, arg1)
  if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED" then
    SpArc:ApplyUnitFramesSettings()
  elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
    SpArc:UpdateUnitFrames(GetTime())
  elseif event == "UNIT_AURA" and (arg1 == "target" or arg1 == "focus") then
    SpArc:UpdateUnitFrames(GetTime())
  end
end)

ufDriver:SetScript("OnUpdate", function()
  local now = GetTime()
  if (now - lastUFTick) < 0.05 then return end
  lastUFTick = now

  local curDemo = (SpArc.testMode or SpArc.editModeActive) and true or false
  if curDemo ~= lastWatchDemoState and not (InCombatLockdown and InCombatLockdown()) then
    lastWatchDemoState = curDemo
    SpArc:ApplyUnitFramesSettings()
    return
  end

  SpArc:UpdateUnitFrames(now)
end)

---------------------------------------------------------------------------------------
--  8. MODULE 12 CONTROL CENTER PAGE BUILDER (/sparc -> ЮНИТФРЕЙМЫ)
---------------------------------------------------------------------------------------
function SpArc:BuildUnitFramesPage(page, ui, helpers)
  local ApplyCyrFont = helpers.ApplyCyrFont
  local CreateElvButton = helpers.CreateElvButton
  local RegisterGroupBox = helpers.RegisterGroupBox
  local CreateElvCheck = helpers.CreateElvCheck
  local CreateElvSlider = helpers.CreateElvSlider
  local controlFrame = helpers.controlFrame

  ui.m12Title = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(ui.m12Title, 15)
  ui.m12Title:SetPoint("TOPLEFT", 0, 0)
  ui.m12Title:SetTextColor(1, 0.85, 0.25, 1)

  local cMaster = CreateElvCheck(page, "MOD_ENABLE", "enableUnitFrames", 0, -24, true, false, function()
    SpArc:ApplyUnitFramesSettings()
  end)
  cMaster:SetWidth(130)

  ui.m12EditPosBtn = CreateElvButton(page, 240, 24, "")
  ui.m12EditPosBtn:SetPoint("LEFT", cMaster, "RIGHT", 10, 0)
  ui.m12EditPosBtn:SetScript("OnClick", function()
    if SpArc.ToggleEditMode then
      SpArc:ToggleEditMode()
    end
    if controlFrame and controlFrame.RefreshUI then
      controlFrame:RefreshUI()
    end
  end)

  ui.m12DisableElvBtn = CreateElvButton(page, 220, 24, "")
  ui.m12DisableElvBtn:SetPoint("LEFT", ui.m12EditPosBtn, "RIGHT", 8, 0)
  ui.m12DisableElvBtn:SetScript("OnClick", function()
    if _G.ElvUI then
      local okE, E = pcall(_G.unpack, _G.ElvUI)
      if okE and type(E) == "table" and E.private and E.private.unitframe then
        E.private.unitframe.enable = false
        print(SpArc:L("MSG_ELVUF_DISABLED"))
      end
    end
  end)

  -- Group 1: Portrait Style, Color Mode & Frame Toggles
  local grpStyle = RegisterGroupBox(page, "M12_GRP_STYLE", 0, -56, 640, 174)

  ui.m12PortLbl = grpStyle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyCyrFont(ui.m12PortLbl, 11)
  ui.m12PortLbl:SetPoint("TOPLEFT", grpStyle, "TOPLEFT", 16, -14)
  ui.m12PortLbl:SetTextColor(1, 0.85, 0.25, 1)

  ui.m12PortBtns = {}
  local portModes = {
    { key = "CIRCLE", lKey = "M12_PORT_CIRCLE", w = 190, x = 110 },
    { key = "SQUARE", lKey = "M12_PORT_SQUARE", w = 135, x = 306 },
    { key = "NONE",   lKey = "M12_PORT_NONE",   w = 125, x = 447 },
  }
  for _, pm in ipairs(portModes) do
    local b = CreateElvButton(grpStyle, pm.w, 22, "")
    b:SetPoint("TOPLEFT", grpStyle, "TOPLEFT", pm.x, -10)
    b.modeKey = pm.key
    b.lKey = pm.lKey
    b:SetScript("OnClick", function()
      local db = SpArc:EnsureDB()
      db.visual.ufPortraitStyle = pm.key
      SpArc:ApplyUnitFramesSettings()
      SpArc:RefreshUnitFramesPage(ui)
    end)
    ui.m12PortBtns[#ui.m12PortBtns + 1] = b
  end

  ui.m12ColLbl = grpStyle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyCyrFont(ui.m12ColLbl, 11)
  ui.m12ColLbl:SetPoint("TOPLEFT", grpStyle, "TOPLEFT", 16, -42)
  ui.m12ColLbl:SetTextColor(1, 0.85, 0.25, 1)

  ui.m12ColBtns = {}
  local colModes = {
    { key = "CLASS", lKey = "M12_COLOR_CLASS", w = 190, x = 110 },
    { key = "DARK",  lKey = "M12_COLOR_DARK",  w = 165, x = 306 },
  }
  for _, cm in ipairs(colModes) do
    local b = CreateElvButton(grpStyle, cm.w, 22, "")
    b:SetPoint("TOPLEFT", grpStyle, "TOPLEFT", cm.x, -38)
    b.modeKey = cm.key
    b.lKey = cm.lKey
    b:SetScript("OnClick", function()
      local db = SpArc:EnsureDB()
      db.visual.ufColorMode = cm.key
      SpArc:ApplyUnitFramesSettings()
      SpArc:RefreshUnitFramesPage(ui)
    end)
    ui.m12ColBtns[#ui.m12ColBtns + 1] = b
  end

  local function AddUFCheck(labelKey, dbKey, x, y, w)
    local c = CreateElvCheck(grpStyle, labelKey, dbKey, x, y, false, false, function()
      SpArc:ApplyUnitFramesSettings()
    end)
    c:SetWidth(w or 250)
    return c
  end

  AddUFCheck("CK_UF_POWER",     "ufShowPowerBar",      16,  -68, 255)
  AddUFCheck("CK_UF_TGT_CAST",  "ufShowTargetCastbar", 282, -68, 255)
  AddUFCheck("CK_UF_TGT_AURAS", "ufShowTargetAuras",   548, -68, 255)

  AddUFCheck("CK_UF_TOT",       "ufShowToT",           16,  -94, 255)
  AddUFCheck("CK_UF_FOCUS",     "ufShowFocus",         282, -94, 255)
  AddUFCheck("CK_UF_PET",       "ufShowPet",           548, -94, 255)

  AddUFCheck("CK_UF_BOSS",      "ufShowBoss",          16,  -120, 255)
  AddUFCheck("CK_UF_HIDE_BLIZZ","ufHideBlizzard",      282, -120, 510)

  -- Group 2: Geometry & Typography Sliders
  local grpGeo = RegisterGroupBox(page, "M12_GRP_GEO", 0, -242, 640, 186)
  CreateElvSlider(grpGeo, "SL_UF_WIDTH",     "ufWidth",            120, 280, 2, 16,  -12, 190, function() SpArc:ApplyUnitFramesSettings() end)
  CreateElvSlider(grpGeo, "SL_UF_HEIGHT",    "ufHeight",           18,  48,  1, 224, -12, 190, function() SpArc:ApplyUnitFramesSettings() end)
  CreateElvSlider(grpGeo, "SL_UF_PORT_SIZE", "ufPortraitSize",     32,  76,  2, 432, -12, 190, function() SpArc:ApplyUnitFramesSettings() end)

  CreateElvSlider(grpGeo, "SL_UF_FONT_SIZE", "ufFontSize",         8,   16,  1, 16,  -72, 190, function() SpArc:ApplyUnitFramesSettings() end)
  CreateElvSlider(grpGeo, "SL_UF_CAST_H",    "ufTargetCastHeight", 10,  28,  1, 224, -72, 190, function() SpArc:ApplyUnitFramesSettings() end)
  CreateElvSlider(grpGeo, "SL_UF_OOC_ALPHA", "ufOocAlpha",         0.20, 1.00, 0.05, 432, -72, 190, function() SpArc:ApplyUnitFramesSettings() end)

  -- Group 3: Coordinates Sliders
  local grpPos = RegisterGroupBox(page, "M12_GRP_POS", 0, -440, 640, 186)
  CreateElvSlider(grpPos, "SL_UF_PLAYER_X", "ufPlayerX",     -800, 800, 2, 16,  -12, 190, function() SpArc:ApplyUnitFramesSettings() end)
  CreateElvSlider(grpPos, "SL_UF_PLAYER_Y", "ufPlayerY",     -500, 500, 2, 224, -12, 190, function() SpArc:ApplyUnitFramesSettings() end)
  CreateElvSlider(grpPos, "SL_UF_TCAST_X",  "ufTargetCastX", -800, 800, 2, 432, -12, 190, function() SpArc:ApplyUnitFramesSettings() end)

  CreateElvSlider(grpPos, "SL_UF_TARGET_X", "ufTargetX",     -800, 800, 2, 16,  -72, 190, function() SpArc:ApplyUnitFramesSettings() end)
  CreateElvSlider(grpPos, "SL_UF_TARGET_Y", "ufTargetY",     -500, 500, 2, 224, -72, 190, function() SpArc:ApplyUnitFramesSettings() end)
  CreateElvSlider(grpPos, "SL_UF_TCAST_Y",  "ufTargetCastY", -500, 500, 2, 432, -72, 190, function() SpArc:ApplyUnitFramesSettings() end)
end

function SpArc:RefreshUnitFramesPage(ui)
  if not ui or not ui.m12Title then return end
  local db = SpArc:EnsureDB()
  local v = db.visual or DEFAULT_VISUAL

  ui.m12Title:SetText(SpArc:L("M12_TITLE"))
  if ui.m12EditPosBtn then
    ui.m12EditPosBtn:SetText(SpArc:L("M12_EDIT_POS_BTN"))
    ui.m12EditPosBtn:SetSelected(SpArc.editModeActive and true or false)
  end
  if ui.m12DisableElvBtn then
    ui.m12DisableElvBtn:SetText(SpArc:L("M12_DISABLE_ELVUF_BTN"))
    ui.m12DisableElvBtn:SetShown(_G.ElvUI ~= nil)
  end
  if ui.m12PortLbl then ui.m12PortLbl:SetText(SpArc:L("M12_PORTRAIT_LBL")) end
  if ui.m12ColLbl then ui.m12ColLbl:SetText(SpArc:L("M12_COLOR_LBL")) end

  local curPort = v.ufPortraitStyle or "CIRCLE"
  for _, b in ipairs(ui.m12PortBtns or {}) do
    b:SetText(SpArc:L(b.lKey))
    b:SetSelected(b.modeKey == curPort)
  end

  local curCol = v.ufColorMode or "CLASS"
  for _, b in ipairs(ui.m12ColBtns or {}) do
    b:SetText(SpArc:L(b.lKey))
    b:SetSelected(b.modeKey == curCol)
  end
end

SpArc:ApplyUnitFramesSettings()
