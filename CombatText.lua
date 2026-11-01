-- =====================================================================================
--  SpArc — CombatText.lua (v2.9.5)
--  Module 11: Tactile Haptic Combat Text, Anti-Clutter Filters & Nameplate Anti-Overlap
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
--  1. ACTIVE COMBAT ENEMY COUNTER & SMART AOE PERIODIC DOT FILTER
---------------------------------------------------------------------------------------
local lastAppliedPeriodicVal = nil
local lastCombatPlateCount = 0
local pendingPostCombatCVars = false
local combatTextHooked = false
local windToolsHooked = false

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
  local db = SpArc:EnsureDB()
  local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL
  if vis.ctShowDirectDamage == false then
    if forceApply or lastAppliedPeriodicVal ~= "0" then
      SafeSetCVar("floatingCombatTextCombatLogPeriodicSpells", "0")
      lastAppliedPeriodicVal = "0"
    end
    return
  end

  local mode = vis.ctDotTickMode or "AUTO_AOE"
  local targetVal = "1"
  local activeCount = SpArc:CountActiveCombatEnemyPlates()

  if mode == "OFF" then
    targetVal = "0"
  elseif mode == "ON" then
    targetVal = "1"
  else
    -- AUTO_AOE: Show periodic ticks on 1-2 targets; suppress periodic tick flood on 3+ pack
    if activeCount >= 3 then
      targetVal = "0"
    else
      targetVal = "1"
    end
  end

  if forceApply or lastAppliedPeriodicVal ~= targetVal then
    SafeSetCVar("floatingCombatTextCombatLogPeriodicSpells", targetVal)
    lastAppliedPeriodicVal = targetVal
  end
end

---------------------------------------------------------------------------------------
--  2. BLIZZARD FLOATING COMBAT TEXT & WINDTOOLS COMBAT ALERT SUPPRESSION
---------------------------------------------------------------------------------------
local function SyncBlizzardScrollingCombatText(hidePlayerScrolling, suppressAlerts)
  if hidePlayerScrolling then
    SafeSetCVar("enableFloatingCombatText", "0")
    local ctFrame = _G.CombatText
    if ctFrame then
      pcall(ctFrame.UnregisterAllEvents, ctFrame)
      pcall(ctFrame.Hide, ctFrame)
      pcall(ctFrame.SetAlpha, ctFrame, 0)
    end
  else
    SafeSetCVar("enableFloatingCombatText", "1")
    -- Shift player scrolling combat text column to the left (-260px) so it never covers the center Rotation Arc
    if type(_G.COMBAT_TEXT_LOCATIONS) == "table" then
      _G.COMBAT_TEXT_LOCATIONS.startX = -260
      _G.COMBAT_TEXT_LOCATIONS.endX = -260
    end
    local ctFrame = _G.CombatText
    if ctFrame then
      pcall(ctFrame.SetAlpha, ctFrame, 1)
      pcall(ctFrame.Show, ctFrame)
    end
  end

  if not combatTextHooked and type(_G.CombatText_AddMessage) == "function" then
    combatTextHooked = true
    pcall(_G.hooksecurefunc, "CombatText_AddMessage", function()
      if not SpArc:IsCombatTextEnabled() then return end
      local db = SpArc:EnsureDB()
      local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL
      if vis.ctHidePlayerScrolling ~= false and _G.CombatText then
        pcall(_G.CombatText.Hide, _G.CombatText)
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

  -- 1. Suppress ElvUI_WindTools CombatAlert (giant shield / crossed swords + "Вход в бой" in center screen)
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

---------------------------------------------------------------------------------------
--  3. MASTER APPLY FUNCTION (CVARS, STACKING NAMEPLATES & FILTERS)
---------------------------------------------------------------------------------------
function SpArc:ApplyCombatTextSettings()
  if not SpArc:IsCombatTextEnabled() then
    return
  end

  local db = SpArc:EnsureDB()
  local vis = (db and db.visual) or SpArc.DEFAULT_VISUAL

  local hidePlayer = (vis.ctHidePlayerScrolling ~= false)
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

  -- 1. Center HUD & Alert Suppression
  SyncBlizzardScrollingCombatText(hidePlayer, suppressAlerts)
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

  -- 2. Tactile Enemy 3D Damage Numbers & Clutter Filters
  SafeSetCVar("floatingCombatTextCombatDamage", showDirect and "1" or "0")
  SafeSetCVar("floatingCombatTextPetMeleeDamage", (showDirect and not hidePet) and "1" or "0")
  SafeSetCVar("floatingCombatTextPetSpellDamage", (showDirect and not hidePet) and "1" or "0")

  SafeSetCVar("floatingCombatTextCombatHealing", hideHeal and "0" or "1")
  SafeSetCVar("floatingCombatTextCombatHealingAbsorbTarget", hideHeal and "0" or "1")
  SafeSetCVar("floatingCombatTextCombatHealingAbsorbSelf", hideHeal and "0" or "1")
  SafeSetCVar("floatingCombatTextDodgeParryMiss", hideMiss and "0" or "1")

  -- 3. Number Scale & Fountain Spread
  SafeSetCVar("WorldTextScale", string.format("%.2f", math.max(0.40, math.min(1.50, worldScale))))
  SafeSetCVar("floatingCombatTextCombatDamageDirectionalScale", tostring(math.max(0, math.min(2, dirScale))))
  SafeSetCVar("floatingCombatTextFloatMode", "1")

  -- 4. Periodic DoT Ticks (Smart AoE / ON / OFF)
  SpArc:UpdateDynamicAoEPeriodicFilter(true)

  -- 5. Nameplate Stacking Anti-Overlap (Protected outside combat lockdown)
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
  vis.ctHidePlayerScrolling = true
  vis.ctSuppressAlerts = true
  vis.ctShowDirectDamage = true
  vis.ctDotTickMode = "AUTO_AOE"
  vis.ctHidePetDamage = true
  vis.ctHideWorldHealing = true
  vis.ctHideDodgeParryMiss = true
  vis.ctWorldTextScale = 0.65
  vis.ctDirectionalScale = 0
  vis.ctSpreadNameplates = true
  vis.ctNameplateOverlapV = 1.35
  vis.ctNameplateOverlapH = 0.90
  SpArc:ApplyCombatTextSettings()
end

function SpArc:RestoreBlizzardCombatTextDefaults()
  local db = SpArc:EnsureDB()
  local vis = db.visual
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
  SpArc:ApplyCombatTextSettings()
end

---------------------------------------------------------------------------------------
--  4. EVENT WATCHER (NAMEPLATE COUNTING, COMBAT STATE & ADDON LOADED)
---------------------------------------------------------------------------------------
local ctEventFrame = CreateFrame("Frame")
ctEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
ctEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
ctEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
ctEventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
ctEventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
ctEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
ctEventFrame:RegisterEvent("ADDON_LOADED")

ctEventFrame:SetScript("OnEvent", function(_, event, arg1)
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

  -- Dynamic AoE periodic DoT check on nameplate changes & combat start
  SpArc:UpdateDynamicAoEPeriodicFilter(false)
end)

-- Periodic 0.6s lightweight check during combat to catch mobs entering combat after pull
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
--  5. CONTROL CENTER UI PAGE (TAB 11: COMBAT TEXT / БОЕВОЙ ТЕКСТ)
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

  -- Top Row: Master Enable + Quick Preset Buttons
  local cEnable = CreateElvCheck(page, "MOD_ENABLE", "enableCombatText", 0, -22, true, false, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
  end)
  cEnable:SetWidth(120)

  local btnHaptic = CreateElvButton(page, 260, 22, "")
  btnHaptic:SetPoint("TOPLEFT", page, "TOPLEFT", 130, -22)
  btnHaptic:SetScript("OnClick", function()
    SpArc:ApplyCleanHapticPreset()
    if controlFrame and controlFrame.RefreshUI then
      controlFrame:RefreshUI()
    end
  end)
  ui.m11HapticBtn = btnHaptic

  local btnBlizz = CreateElvButton(page, 240, 22, "")
  btnBlizz:SetPoint("LEFT", btnHaptic, "RIGHT", 8, 0)
  btnBlizz:SetScript("OnClick", function()
    SpArc:RestoreBlizzardCombatTextDefaults()
    if controlFrame and controlFrame.RefreshUI then
      controlFrame:RefreshUI()
    end
  end)
  ui.m11BlizzBtn = btnBlizz

  -- Group 1: Center HUD & Rotation Arc Protection
  local grpCenter = RegisterGroupBox(page, "M11_GRP_CENTER", 0, -52, 640, 74)
  CreateElvCheck(grpCenter, "CK_CT_HIDE_PLAYER", "ctHidePlayerScrolling", 14, -10, false, false, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
  end)
  CreateElvCheck(grpCenter, "CK_CT_SUPPRESS_ALERTS", "ctSuppressAlerts", 14, -38, false, false, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
  end)

  -- Group 2: Tactile Enemy Damage Numbers & Smart AoE Filter
  local grpEnemy = RegisterGroupBox(page, "M11_GRP_ENEMY", 0, -138, 640, 166)
  CreateElvCheck(grpEnemy, "CK_CT_DIRECT_DMG", "ctShowDirectDamage", 14, -10, false, false, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
  end)

  -- 3-Way Selector for Periodic DoT Ticks (AUTO_AOE / OFF / ON)
  local dotLbl = grpEnemy:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyCyrFont(dotLbl, 11)
  dotLbl:SetPoint("TOPLEFT", grpEnemy, "TOPLEFT", 16, -42)
  dotLbl:SetTextColor(1, 0.85, 0.25, 1)
  ui.m11DotModeLbl = dotLbl

  ui.m11DotBtns = {}
  local dotModes = {
    { key = "AUTO_AOE", lKey = "M11_DOT_AUTO", w = 225, x = 148 },
    { key = "OFF",      lKey = "M11_DOT_OFF",  w = 165, x = 378 },
    { key = "ON",       lKey = "M11_DOT_ON",   w = 80,  x = 548 },
  }
  for _, dm in ipairs(dotModes) do
    local b = CreateElvButton(grpEnemy, dm.w, 22, "")
    b:SetPoint("TOPLEFT", grpEnemy, "TOPLEFT", dm.x, -37)
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

  CreateElvCheck(grpEnemy, "CK_CT_HIDE_PET", "ctHidePetDamage", 14, -68, false, false, function()
    SpArc:ApplyCombatTextSettings()
  end)
  CreateElvCheck(grpEnemy, "CK_CT_HIDE_HEAL", "ctHideWorldHealing", 14, -96, false, false, function()
    SpArc:ApplyCombatTextSettings()
  end)
  CreateElvCheck(grpEnemy, "CK_CT_HIDE_MISS", "ctHideDodgeParryMiss", 14, -124, false, false, function()
    SpArc:ApplyCombatTextSettings()
  end)

  -- Group 3: Scale, Spread & Nameplate Anti-Overlap Stacking
  local grpScale = RegisterGroupBox(page, "M11_GRP_SCALE", 0, -316, 640, 208)
  CreateElvSlider(grpScale, "SL_CT_WORLD_SCALE", "ctWorldTextScale", 0.40, 1.50, 0.05, 16, -14, 285, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
  end)
  CreateElvSlider(grpScale, "SL_CT_DIR_SCALE", "ctDirectionalScale", 0, 2, 1, 332, -14, 285, function()
    SpArc:ApplyCombatTextSettings()
    SpArc:RefreshCombatTextPage(ui)
  end)

  CreateElvCheck(grpScale, "CK_CT_SPREAD_NP", "ctSpreadNameplates", 14, -78, false, false, function()
    SpArc:ApplyCombatTextSettings()
  end)

  CreateElvSlider(grpScale, "SL_CT_OVERLAP_V", "ctNameplateOverlapV", 0.60, 2.00, 0.05, 16, -112, 285, function()
    SpArc:ApplyCombatTextSettings()
  end)
  CreateElvSlider(grpScale, "SL_CT_OVERLAP_H", "ctNameplateOverlapH", 0.40, 1.60, 0.05, 332, -112, 285, function()
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
  if ui.m11HapticBtn then
    ui.m11HapticBtn:SetText(SpArc:L("M11_PRESET_HAPTIC_BTN"))
    if ui.m11StyleToggle then
      local isHaptic = (vis.ctHidePlayerScrolling ~= false)
        and (vis.ctSuppressAlerts ~= false)
        and ((vis.ctDotTickMode or "AUTO_AOE") == "AUTO_AOE")
        and (math.abs((tonumber(vis.ctWorldTextScale) or 0.65) - 0.65) < 0.03)
      ui.m11StyleToggle(ui.m11HapticBtn, isHaptic)
    end
  end
  if ui.m11BlizzBtn then
    ui.m11BlizzBtn:SetText(SpArc:L("M11_PRESET_BLIZZ_BTN"))
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
    local cvarPeriodic = SafeGetCVar("floatingCombatTextCombatLogPeriodicSpells") or "1"
    local periodicStr = (cvarPeriodic == "1") and "|cff00ff00ON|r" or "|cffff5555OFF (AoE Suppressed)|r"
    if curMode == "OFF" then
      periodicStr = "|cffff5555OFF|r"
    end
    ui.m11StatusTxt:SetText(string.format(
      SpArc:L("M11_STATUS_FMT"),
      scaleVal,
      periodicStr,
      lastCombatPlateCount or 0
    ))
  end
end
