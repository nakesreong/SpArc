---------------------------------------------------------------------------------------
--  SpArc/Camera.lua — Standalone Action Combat Camera (Mouselook) Module
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
--
--  Purpose:
--  Lightweight, rock-solid replacement for CombatMode with zero bloat:
--  • Holds camera in MouselookStart() automatically during gameplay.
--  • G = strictly onHold (unlocks cursor while held; locks immediately on release).
--  • ` = strictly onPress toggle (unlocks/locks permanently on press).
--  • Direct Mouselook click-casting (LMB/RMB + Shift/Ctrl/Alt -> Bartender4 :Keybind / ActionButton 1..8).
--  • Auto-unlocks cursor when bags, map, quests, menus, or ground-targeting spells are active.
--  • Forces CursorFreelookCentering=0 & CursorStickyCentering=0 so WoW 12.x never leaves
--    a visible stuck cursor jittering in the center of the screen.
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc
if not SpArc or SpArc._cameraModuleLoaded then return end
SpArc._cameraModuleLoaded = true

local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local C_CVar = _G.C_CVar
local C_Timer = _G.C_Timer
local C_AddOns = _G.C_AddOns
local C_PetBattles = _G.C_PetBattles
local GetBindingKey = _G.GetBindingKey
local GetBindingAction = _G.GetBindingAction
local GetCursorInfo = _G.GetCursorInfo
local GetUIPanel = _G.GetUIPanel
local InCinematic = _G.InCinematic
local IsInCinematicScene = _G.IsInCinematicScene
local InCombatLockdown = _G.InCombatLockdown
local IsKeyDown = _G.IsKeyDown
local IsMouseButtonDown = _G.IsMouseButtonDown
local IsMouselooking = _G.IsMouselooking
local MouselookStart = _G.MouselookStart
local MouselookStop = _G.MouselookStop
local SetMouselookOverrideBinding = _G.SetMouselookOverrideBinding
local SetOverrideBinding = _G.SetOverrideBinding
local SetOverrideBindingClick = _G.SetOverrideBindingClick
local ClearOverrideBindings = _G.ClearOverrideBindings
local SpellIsTargeting = _G.SpellIsTargeting
local UnitExists = _G.UnitExists
local UnitCanAttack = _G.UnitCanAttack
local UnitIsDead = _G.UnitIsDead
local UnitIsGhost = _G.UnitIsGhost
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsUnit = _G.UnitIsUnit
local RegisterStateDriver = _G.RegisterStateDriver
local UnregisterStateDriver = _G.UnregisterStateDriver
local pcall = _G.pcall
local ipairs = _G.ipairs
local pairs = _G.pairs
local type = _G.type

local SafeBool = SpArc.SafeBool

---------------------------------------------------------------------------------------
--  1. STATE & CONFIGURATION
---------------------------------------------------------------------------------------
local holdCursorActive = false
local manualToggleUnlocked = false
local holdPollRunning = false
local pendingBindingSync = false
local loadingScreenActive = false
local barberShopActive = false
local hardwareCursorFlushed = false

SpArc.COMBAT_CAM_SLOT_KEYBINDS = {
  [1] = "M1",
  [2] = "M2",
  [3] = "SM1",
  [4] = "SM2",
  [5] = "CM1",
  [6] = "CM2",
  [7] = "AM1",
  [8] = "AM2",
}

local DEFAULT_MOUSE_KEY_TO_ACTION = {
  ["BUTTON1"]       = "ACTIONBUTTON1",
  ["BUTTON2"]       = "ACTIONBUTTON2",
  ["SHIFT-BUTTON1"] = "ACTIONBUTTON3",
  ["SHIFT-BUTTON2"] = "ACTIONBUTTON4",
  ["CTRL-BUTTON1"]  = "ACTIONBUTTON5",
  ["CTRL-BUTTON2"]  = "ACTIONBUTTON6",
  ["ALT-BUTTON1"]   = "ACTIONBUTTON7",
  ["ALT-BUTTON2"]   = "ACTIONBUTTON8",
}

local UNLOCK_FRAME_WATCHLIST = {
  -- Core Blizzard UI & Menus
  "GameMenuFrame",
  "SettingsPanel",
  "EditModeManagerFrame",
  "KeyBindingFrame",
  "QuickKeybindFrame",
  "KeyboundDialog",
  "KeyBoundDialog",
  "ElvUIBindPopupWindow",
  "MacroFrame",
  "WorldMapFrame",
  "CharacterFrame",
  "SpellBookFrame",
  "PlayerSpellsFrame",
  "TalentFrame",
  "ClassTalentFrame",
  "ProfessionsFrame",
  "ProfessionsBookFrame",
  "CollectionsJournal",
  "EncounterJournal",
  "AchievementFrame",
  "CommunitiesFrame",
  "PVEFrame",
  "FriendsFrame",
  "GuildFrame",
  "CalendarFrame",
  "TimeManagerFrame",
  "ColorPickerFrame",
  "HelpFrame",
  -- NPCs, Quests, Economy, Crafting
  "QuestFrame",
  "GossipFrame",
  "ItemTextFrame",
  "DUIQuestFrame",
  "DUIBookFrame",
  "ImmersionFrame",
  "MerchantFrame",
  "MailFrame",
  "OpenMailFrame",
  "TradeFrame",
  "BankFrame",
  "AccountBankPanel",
  "AuctionHouseFrame",
  "ClassTrainerFrame",
  "PlayerChoiceFrame",
  "GenericTraitFrame",
  "ItemUpgradeFrame",
  "ItemInteractionFrame",
  "ScrappingMachineFrame",
  "WeeklyRewardsFrame",
  "FlightMapFrame",
  -- Transmog, Wardrobe, Outfits, Barbershop
  "BarberShopFrame",
  "CharCustomizeFrame",
  "DressUpFrame",
  "SideDressUpFrame",
  "TransmogFrame",
  "WardrobeFrame",
  "BetterWardrobeCollectionFrame",
  "BetterWardrobeOutfitFrame",
  "MogItFrame",
  "MogItPreview1",
  "PawnUIFrame",
  -- Bags & Inventory Addons
  "ContainerFrameCombinedBags",
  "ContainerFrame1",
  "ContainerFrame2",
  "ContainerFrame3",
  "ContainerFrame4",
  "ContainerFrame5",
  "ContainerFrame6",
  "ElvUI_ContainerFrame",
  "ElvUI_BankContainerFrame",
  "Baganator_SingleViewBackpackViewFrame",
  "Baganator_SingleViewBankViewFrame",
  "Baganator_CategoryViewBackpackViewFrame",
  "Baganator_CategoryViewBankViewFrame",
  "Baganator_SingleViewBackpackViewFrameelvui",
  "Baganator_SingleViewBankViewFrameelvui",
  "Baganator_CategoryViewBackpackViewFrameelvui",
  "Baganator_CategoryViewBankViewFrameelvui",
  "Baganator_SingleViewGuildViewFrameelvui",
  "Baganator_CharacterSelectFrameelvui",
  "Baganator_CurrencyPanelFrameelvui",
  "Baganator_SingleViewBackpackViewFrameblizzard",
  "Baganator_SingleViewBankViewFrameblizzard",
  "Baganator_CategoryViewBackpackViewFrameblizzard",
  "Baganator_CategoryViewBankViewFrameblizzard",
  "Baganator_SingleViewGuildViewFrameblizzard",
  "Baganator_SingleViewBackpackViewFramedark",
  "Baganator_SingleViewBankViewFramedark",
  "Baganator_CategoryViewBackpackViewFramedark",
  "Baganator_CategoryViewBankViewFramedark",
  "Baganator_SingleViewGuildViewFramedark",
  "BagnonInventory1",
  "BetterBagsBagBackpack",
  "BetterBagsBagBank",
  -- Housing & Plumber & Companion Addons
  "PlumberLandingPage",
  "HomeBoundMainFrame",
  "DecorVendorFrame",
  "HousingDashboardFrame",
  "HousingModelPreviewFrame",
  "HousingCatalogFrame",
  "HousingEditorFrame",
  "HousingControlsFrame",
  "HousingPlotSettingsFrame",
  "HousingPermissionSettingsFrame",
  -- SpArc, MountCollector, Details, BugSack
  "SpArcControlCenter",
  "MountCollectorFrame",
  "BugSackFrame",
  "DetailsOptionsWindow",
  "DetailsBreakdownWindow",
  "DetailsForgePanel",
  -- Popups & Dropdowns
  "StaticPopup1",
  "StaticPopup2",
  "StaticPopup3",
  "StaticPopup4",
  "ElvUI_StaticPopup1",
  "ElvUI_StaticPopup2",
  "ElvUI_StaticPopup3",
  "ElvUI_StaticPopup4",
  "DeathRecapFrame",
  "DropDownList1",
  "DropDownList2",
}

function SpArc:IsCombatCameraEnabled()
  local db = SpArc:EnsureDB()
  return not (db and db.visual and db.visual.enableCombatCamera == false)
end

function SpArc:IsCamClickCastEnabled()
  local db = SpArc:EnsureDB()
  return SpArc:IsCombatCameraEnabled() and not (db and db.visual and db.visual.enableCamClickCast == false)
end

function SpArc:IsCameraCrosshairEnabled()
  local db = SpArc:EnsureDB()
  return SpArc:IsCombatCameraEnabled() and not (db and db.visual and db.visual.showCameraCrosshair == false)
end

function SpArc:IsAutoUnshiftEnabled()
  local db = SpArc:EnsureDB()
  return not (db and db.visual and db.visual.autoUnshiftOutOfCombat == false)
end

function SpArc:GetCamHoldKey()
  local db = SpArc:EnsureDB()
  local k = db and db.visual and db.visual.camHoldKey
  if type(k) == "string" then
    return k
  end
  return "G"
end

function SpArc:GetCamToggleKey()
  local db = SpArc:EnsureDB()
  local k = db and db.visual and db.visual.camToggleKey
  if type(k) == "string" then
    return k
  end
  return "`"
end

function SpArc:GetCamInteractKey()
  local db = SpArc:EnsureDB()
  local v = db and db.visual
  if not v then
    return SpArc:GetGameInteractKey()
  end
  local k = v.camInteractKey
  if k == nil or k == "AUTO" then
    return SpArc:GetGameInteractKey()
  end
  if type(k) == "string" then
    return k
  end
  return ""
end

local function IsSpArcOwnBindingAction(action)
  if not action or action == "" or action == "NONE" then return true end
  if action:find("^SpArc") or action:find("^Combat Mode") then return true end
  if action == "CLICK SpArcCamHoldButton:LeftButton"
    or action == "CLICK SpArcCamToggleButton:LeftButton"
    or action == "CLICK SpArcCamInteractButton:LeftButton" then
    return true
  end
  return false
end

local function IsInteractBindingAction(action)
  return action == "INTERACTTARGET" or action == "INTERACTMOUSEOVER" or action == "CLICK SpArcCamInteractButton:LeftButton"
end

local function GetRawGameBindingAction(key)
  if not key or key == "" or not GetBindingAction then return "" end
  local ok, act = pcall(GetBindingAction, key)
  if ok and type(act) == "string" and not SpArc.IsSecret(act) then
    return act
  end
  return ""
end

function SpArc:RecordManualCameraBind(dbKey, bindStr)
  local db = SpArc:EnsureDB()
  local v = db and db.visual
  if not v or not dbKey then return end
  v[dbKey] = bindStr or ""
  v.camBindSnapshot = v.camBindSnapshot or {}
  if dbKey == "camInteractKey" then
    v.camInteractKeyUserSet = true
  else
    v[dbKey .. "UserSet"] = true
  end
  if bindStr and bindStr ~= "" and bindStr ~= "AUTO" then
    local act = GetRawGameBindingAction(bindStr)
    v.camBindSnapshot[dbKey] = bindStr .. "::" .. act
  else
    v.camBindSnapshot[dbKey] = nil
  end
end

local function IsUserKeybindingUIOpen()
  local frames = {
    _G.SettingsPanel,
    _G.KeyBindingFrame,
    _G.QuickKeybindFrame,
    _G.KeyboundDialog,
    _G.KeyBoundDialog,
    _G.ElvUIBindPopupWindow,
  }
  for i = 1, #frames do
    local f = frames[i]
    if f and f.IsShown and SafeBool(f.IsShown, f) then
      return true
    end
  end
  if _G.LibStub then
    local ok, lkb = pcall(_G.LibStub, "LibKeyBound-1.0", true)
    if ok and type(lkb) == "table" and lkb.dialog and lkb.dialog.IsShown and SafeBool(lkb.dialog.IsShown, lkb.dialog) then
      return true
    end
  end
  local E = _G.ElvUI and _G.ElvUI[1]
  if E and E.Bind and E.Bind.active then
    return true
  end
  return false
end

local function OnExternalKeyBindingAssigned(rawKey, rawAction)
  if loadingScreenActive then return end
  if not IsUserKeybindingUIOpen() then return end
  if type(rawKey) ~= "string" or rawKey == "" then return end
  if type(rawAction) ~= "string" or rawAction == "" then return end
  if IsSpArcOwnBindingAction(rawAction) then return end

  local key = rawKey:upper()
  local db = SpArc:EnsureDB()
  local v = db and db.visual
  if not v then return end

  local changed = false
  local isInteract = IsInteractBindingAction(rawAction)
  local slots = { "camHoldKey", "camToggleKey", "camInteractKey" }

  for _, slotKey in ipairs(slots) do
    local curSlotKey = (slotKey == "camHoldKey" and SpArc:GetCamHoldKey())
      or (slotKey == "camToggleKey" and SpArc:GetCamToggleKey())
      or SpArc:GetCamInteractKey()
    if type(curSlotKey) == "string" and curSlotKey:upper() == key then
      if slotKey == "camInteractKey" and isInteract then
        -- User bound this key to Interact in Game Settings; keep it in sync
        v.camInteractKey = key
      else
        v[slotKey] = ""
        if slotKey == "camInteractKey" then
          v.camInteractKeyUserSet = true
        else
          v[slotKey .. "UserSet"] = true
        end
        changed = true
        print(string.format(SpArc:L("MSG_BIND_CONFLICT_CLEARED"), key, rawAction))
      end
    end
  end

  if changed then
    if SpArc.RefreshControlCenterUI then
      pcall(SpArc.RefreshControlCenterUI)
    end
    if C_Timer and C_Timer.After then
      C_Timer.After(0, function()
        if SpArc.ApplyCombatCameraBindings then
          SpArc:ApplyCombatCameraBindings("EXTERNAL_BIND")
        end
      end)
    end
  end
end

if _G.hooksecurefunc then
  if _G.SetBinding then
    _G.hooksecurefunc("SetBinding", function(key, command)
      OnExternalKeyBindingAssigned(key, command)
    end)
  end
  if _G.SetBindingClick then
    _G.hooksecurefunc("SetBindingClick", function(key, buttonName, mouseButton)
      if type(buttonName) == "string" and buttonName ~= "" then
        local act = "CLICK " .. buttonName .. ":" .. tostring(mouseButton or "LeftButton")
        OnExternalKeyBindingAssigned(key, act)
      end
    end)
  end
  if _G.SetBindingSpell then
    _G.hooksecurefunc("SetBindingSpell", function(key, spellName)
      if type(spellName) == "string" and spellName ~= "" then
        OnExternalKeyBindingAssigned(key, "SPELL " .. spellName)
      end
    end)
  end
  if _G.SetBindingItem then
    _G.hooksecurefunc("SetBindingItem", function(key, itemName)
      if type(itemName) == "string" and itemName ~= "" then
        OnExternalKeyBindingAssigned(key, "ITEM " .. itemName)
      end
    end)
  end
  if _G.SetBindingMacro then
    _G.hooksecurefunc("SetBindingMacro", function(key, macroName)
      if type(macroName) == "string" and macroName ~= "" then
        OnExternalKeyBindingAssigned(key, "MACRO " .. tostring(macroName))
      end
    end)
  end
end

function SpArc:CheckAndResolveCameraBindConflicts(reason)
  local db = SpArc:EnsureDB()
  local v = db and db.visual
  if not v then return false end
  v.camBindSnapshot = v.camBindSnapshot or {}

  -- One-time heal if G / ` / Interact were wiped by v2.8.0-v2.8.2 UPDATE_BINDINGS login race
  if not v._restoredKeysV283 then
    if v.camHoldKey == "" or v.camHoldKey == nil then
      v.camHoldKey = "G"
      v.camHoldKeyUserSet = false
    end
    if v.camToggleKey == "" or v.camToggleKey == nil then
      v.camToggleKey = "`"
      v.camToggleKeyUserSet = false
    end
    if v.camInteractKey == "" or v.camInteractKey == nil then
      v.camInteractKey = "AUTO"
      v.camInteractKeyUserSet = false
    end
    v._restoredKeysV283 = true
    if SpArc.RefreshControlCenterUI then
      pcall(SpArc.RefreshControlCenterUI)
    end
  end

  return false
end

---------------------------------------------------------------------------------------
--  2. NEUTRALIZE EXTERNAL COMBATMODE & SYNC CROSSHAIR MOUSEOVER CVARS
---------------------------------------------------------------------------------------
local crosshairFrame
local crosshairVisual
local lockBounceToken = 0
local lastSyncedNormY = nil
local lastFreelookCentering = nil

local function SyncCursorCenteredYPos(force)
  if not (C_CVar and C_CVar.SetCVar) then return end
  if InCombatLockdown and InCombatLockdown() then
    pendingBindingSync = true
    return
  end
  local db = SpArc:EnsureDB()
  local v = (db and db.visual) or SpArc.DEFAULT_VISUAL or {}
  local offsetY = tonumber(v.camCrosshairOffsetY)
  if offsetY == nil then offsetY = 20 end

  local normY = 0.5
  if UIParent and UIParent.GetHeight then
    local okH, uiH = pcall(UIParent.GetHeight, UIParent)
    if okH and type(uiH) == "number" and not SpArc.IsSecret(uiH) and uiH > 0 then
      normY = 0.5 + (offsetY / uiH)
    end
  end
  normY = math.max(0.01, math.min(0.99, normY))
  if force or not lastSyncedNormY or math.abs(normY - lastSyncedNormY) > 0.0002 then
    lastSyncedNormY = normY
    pcall(C_CVar.SetCVar, "CursorCenteredYPos", string.format("%.4f", normY))
  end
end

local function SetFreelookCenteringCVar(enabled, force)
  if not (C_CVar and C_CVar.SetCVar) then return end
  if InCombatLockdown and InCombatLockdown() then
    pendingBindingSync = true
    return
  end
  local val = enabled and "1" or "0"
  if not force and lastFreelookCentering == val then return end
  lastFreelookCentering = val
  pcall(C_CVar.SetCVar, "CursorFreelookCentering", val)
end

local function EnsureBaseCameraCVars()
  if not (C_CVar and C_CVar.SetCVar) then return end
  if InCombatLockdown and InCombatLockdown() then
    pendingBindingSync = true
    return
  end
  -- Critical fix for WoW 10.2 / 12.x Bug #504:
  -- CursorStickyCentering must ALWAYS stay 0.
  -- CursorFreelookCentering is set to 0 before MouselookStart(), then deferred to 1 after MouselookStart()
  -- so @mouseover and @cursor macros hit the exact crosshair position without unhiding the OS cursor.
  pcall(C_CVar.SetCVar, "CursorStickyCentering", "0")
  SyncCursorCenteredYPos(false)
  -- Keep SoftTarget Interact, Enemy & Friend active so E / interact key both targets and interacts smoothly
  pcall(C_CVar.SetCVar, "SoftTargetInteract", "3")
  pcall(C_CVar.SetCVar, "SoftTargetInteractArc", "1")
  pcall(C_CVar.SetCVar, "SoftTargetInteractRange", "15")
  pcall(C_CVar.SetCVar, "SoftTargetEnemy", "1")
  pcall(C_CVar.SetCVar, "SoftTargetFriend", "0")
  pcall(C_CVar.SetCVar, "interactKeyWarningTutorial", "1")
end

local function ForceCleanCursorCVars()
  SetFreelookCenteringCVar(false, true)
  EnsureBaseCameraCVars()
end

local function NeutralizeExternalCombatMode()
  if not SpArc:IsCombatCameraEnabled() then return end

  if C_AddOns and C_AddOns.DisableAddOn then
    pcall(C_AddOns.DisableAddOn, "CombatMode")
  end

  if _G.CombatModeFrame then
    pcall(_G.CombatModeFrame.UnregisterAllEvents, _G.CombatModeFrame)
    pcall(_G.CombatModeFrame.SetScript, _G.CombatModeFrame, "OnUpdate", nil)
    pcall(_G.CombatModeFrame.SetScript, _G.CombatModeFrame, "OnEvent", nil)
    pcall(_G.CombatModeFrame.Hide, _G.CombatModeFrame)
  end
  if _G.CombatModeCrosshairFrame then
    pcall(_G.CombatModeCrosshairFrame.Hide, _G.CombatModeCrosshairFrame)
  end
  if _G.CombatModeShoulderOffsetFrame then
    pcall(_G.CombatModeShoulderOffsetFrame.SetScript, _G.CombatModeShoulderOffsetFrame, "OnUpdate", nil)
  end

  local cm = _G.CM or _G.CombatMode
  if type(cm) == "table" then
    if cm.OnDisable then pcall(cm.OnDisable, cm, true) end
    cm.OnEnable = function() end
    cm.OnInitialize = function() end
    cm.BootstrapFeatureModules = function() end
    cm.RuntimeRematch = function() end
    cm.ReconcileFreeLook = function() return false end
    cm.LockFreeLook = function() end
    cm.UnlockFreeLook = function() end
    cm.SetCursorFreelookCentering = function() end
    cm.SetCursorFreelookCenteringCVar = function() end
    cm.OnUpdate = function() end
    cm.DisplayCrosshair = function() end
    cm.ApplyGroundCastKeyOverrides = function() end
    cm.ApplyToggleFocusTargetBinding = function() end
    cm.ApplyCycleFocusBindings = function() end
    cm.OverrideDefaultButtons = function() end
    cm.RefreshClickCastMacros = function() end
  end

  _G.CombatMode_OnEvent = function() end
  _G.CombatMode_OnUpdate = function() end
  _G.CombatMode_CursorModeKey = function(keystate)
    if _G.SpArc_CameraHoldKey then
      _G.SpArc_CameraHoldKey(keystate)
    end
  end
end

function SpArc:FlushHardwareCursor(useGxRestart)
  if IsMouselooking and IsMouselooking() and MouselookStop then
    pcall(MouselookStop)
  end
  if _G.ResetCursor then pcall(_G.ResetCursor) end
  if _G.SetCursor then pcall(_G.SetCursor, nil) end
  if InCombatLockdown and InCombatLockdown() then
    pendingBindingSync = true
    return
  end
  ForceCleanCursorCVars()
  if C_CVar and C_CVar.SetCVar then
    pcall(C_CVar.SetCVar, "gxCursor", "1")
  end
  if useGxRestart and _G.RestartGx then
    pcall(_G.RestartGx)
  end
end

---------------------------------------------------------------------------------------
--  3. CENTER CROSSHAIR & TOOLTIP GUARD
---------------------------------------------------------------------------------------
crosshairFrame = CreateFrame("Frame", "SpArcCameraCrosshair", UIParent)
crosshairFrame:SetSize(24, 24)
crosshairFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
crosshairFrame:SetFrameStrata("LOW")
crosshairFrame:EnableMouse(false)
crosshairFrame:Hide()

crosshairVisual = CreateFrame("Frame", nil, crosshairFrame)
crosshairVisual:SetSize(24, 24)
crosshairVisual:SetPoint("CENTER", crosshairFrame, "CENTER", 0, 0)
crosshairVisual:EnableMouse(false)

local chDot = crosshairVisual:CreateTexture(nil, "OVERLAY")
chDot:SetSize(3, 3)
chDot:SetPoint("CENTER", crosshairVisual, "CENTER", 0, 0)
chDot:SetColorTexture(1, 1, 1, 0.9)

local chTop = crosshairVisual:CreateTexture(nil, "ARTWORK")
chTop:SetSize(2, 5)
chTop:SetPoint("BOTTOM", chDot, "TOP", 0, 3)
chTop:SetColorTexture(1, 1, 1, 0.75)

local chBottom = crosshairVisual:CreateTexture(nil, "ARTWORK")
chBottom:SetSize(2, 5)
chBottom:SetPoint("TOP", chDot, "BOTTOM", 0, -3)
chBottom:SetColorTexture(1, 1, 1, 0.75)

local chLeft = crosshairVisual:CreateTexture(nil, "ARTWORK")
chLeft:SetSize(5, 2)
chLeft:SetPoint("RIGHT", chDot, "LEFT", -3, 0)
chLeft:SetColorTexture(1, 1, 1, 0.75)

local chRight = crosshairVisual:CreateTexture(nil, "ARTWORK")
chRight:SetSize(5, 2)
chRight:SetPoint("LEFT", chDot, "RIGHT", 3, 0)
chRight:SetColorTexture(1, 1, 1, 0.75)

local chShadow = crosshairVisual:CreateTexture(nil, "BACKGROUND")
chShadow:SetSize(5, 5)
chShadow:SetPoint("CENTER", crosshairVisual, "CENTER", 0, 0)
chShadow:SetColorTexture(0, 0, 0, 0.65)

local function SetCrosshairColor(r, g, b, a)
  chDot:SetColorTexture(r, g, b, a)
  chTop:SetColorTexture(r, g, b, a * 0.85)
  chBottom:SetColorTexture(r, g, b, a * 0.85)
  chLeft:SetColorTexture(r, g, b, a * 0.85)
  chRight:SetColorTexture(r, g, b, a * 0.85)
end

local UpdateCrosshairVisual

local function ApplyCrosshairGeometry()
  local db = SpArc:EnsureDB()
  local v = (db and db.visual) or SpArc.DEFAULT_VISUAL or {}
  local offsetY = tonumber(v.camCrosshairOffsetY)
  if offsetY == nil then offsetY = 20 end
  local scale = tonumber(v.camCrosshairScale) or 1.00
  if scale < 0.4 then scale = 0.4 elseif scale > 3.0 then scale = 3.0 end

  crosshairFrame:ClearAllPoints()
  crosshairFrame:SetPoint("CENTER", UIParent, "CENTER", 0, offsetY)
  crosshairVisual:SetScale(scale)
  SyncCursorCenteredYPos(false)
end

function SpArc:ApplyCameraCrosshairLayout()
  ApplyCrosshairGeometry()
  if UpdateCrosshairVisual then
    UpdateCrosshairVisual()
  end
end

UpdateCrosshairVisual = function()
  local showPreview = SpArc.previewCrosshairInConfig or SpArc.testMode
  local mouselooking = IsMouselooking and IsMouselooking()
  if not SpArc:IsCameraCrosshairEnabled() or (not mouselooking and not showPreview) then
    if crosshairFrame:IsShown() then
      crosshairFrame:Hide()
    end
    return
  end

  local wantStrata = showPreview and "TOOLTIP" or "LOW"
  if crosshairFrame.GetFrameStrata and crosshairFrame:GetFrameStrata() ~= wantStrata then
    crosshairFrame:SetFrameStrata(wantStrata)
  end

  if not crosshairFrame:IsShown() then
    ApplyCrosshairGeometry()
    crosshairFrame:Show()
  end

  if showPreview and not mouselooking then
    SetCrosshairColor(0.35, 0.90, 1.0, 0.95)
  elseif UnitExists and SafeBool(UnitExists, "mouseover") and not SafeBool(UnitIsDeadOrGhost, "mouseover") then
    if UnitCanAttack and SafeBool(UnitCanAttack, "player", "mouseover") then
      SetCrosshairColor(1.0, 0.22, 0.22, 0.98)
    else
      SetCrosshairColor(0.20, 0.95, 0.40, 0.95)
    end
  elseif UnitExists and SafeBool(UnitExists, "softinteract") then
    SetCrosshairColor(1.0, 0.82, 0.20, 0.95)
  elseif UnitExists and SafeBool(UnitExists, "target") and UnitCanAttack and SafeBool(UnitCanAttack, "player", "target") and not SafeBool(UnitIsDeadOrGhost, "target") then
    SetCrosshairColor(1.0, 0.25, 0.25, 0.90)
  elseif UnitExists and SafeBool(UnitExists, "softenemy") and UnitCanAttack and SafeBool(UnitCanAttack, "player", "softenemy") then
    SetCrosshairColor(1.0, 0.45, 0.20, 0.90)
  else
    SetCrosshairColor(0.90, 0.92, 0.98, 0.75)
  end
end

local tooltipHooked = false
local function EnsureTooltipHook()
  if tooltipHooked or not _G.GameTooltip or not _G.GameTooltip.HookScript then return end
  _G.GameTooltip:HookScript("OnShow", function(self)
    if SpArc:IsCombatCameraEnabled() and IsMouselooking and IsMouselooking() then
      local owner = self:GetOwner()
      if owner == UIParent or owner == _G.WorldFrame then
        self:Hide()
      end
    end
  end)
  tooltipHooked = true
end

---------------------------------------------------------------------------------------
--  4. AUTO-UNLOCK DETECTION (UI WINDOWS, BAGS, GROUND SPELLS)
---------------------------------------------------------------------------------------
local UI_PANEL_SLOTS = { "left", "center", "right", "doublewide", "fullscreen" }

local function IsAnyWatchedFrameVisible()
  if GetUIPanel then
    for i = 1, #UI_PANEL_SLOTS do
      local ok, panel = pcall(GetUIPanel, UI_PANEL_SLOTS[i])
      if ok and panel then
        return true
      end
    end
  end

  for i = 1, #UNLOCK_FRAME_WATCHLIST do
    local f = _G[UNLOCK_FRAME_WATCHLIST[i]]
    if f and f.IsVisible and SafeBool(f.IsVisible, f) then
      if not f.GetAlpha then return true end
      local okA, alpha = pcall(f.GetAlpha, f)
      if not okA or (not SpArc.IsSecret(alpha) and type(alpha) == "number" and alpha > 0.05) then
        return true
      end
    end
  end

  if type(_G.UISpecialFrames) == "table" then
    for i = 1, #_G.UISpecialFrames do
      local fName = _G.UISpecialFrames[i]
      if type(fName) == "string" and (
        fName:find("^Baganator")
        or fName:find("^Syndicator")
        or fName:find("^Auctionator")
        or fName:find("^BetterBags")
        or fName:find("^Bagnon")
        or fName:find("^AdiBags")
        or fName:find("^ArkInventory")
        or fName:find("^BarberShop")
        or fName:find("^CharCustomize")
      ) then
        local f = _G[fName]
        if f and f.IsVisible and SafeBool(f.IsVisible, f) then
          if not f.GetAlpha then return true end
          local okA, alpha = pcall(f.GetAlpha, f)
          if not okA or (not SpArc.IsSecret(alpha) and type(alpha) == "number" and alpha > 0.05) then
            return true
          end
        end
      end
    end
  end

  if _G.MovieFrame and _G.MovieFrame.IsVisible and SafeBool(_G.MovieFrame.IsVisible, _G.MovieFrame) then
    return true
  end

  if IsUserKeybindingUIOpen() then
    return true
  end

  if _G.LibStub then
    local ok, acd = pcall(_G.LibStub, "AceConfigDialog-3.0", true)
    if ok and type(acd) == "table" and type(acd.OpenFrames) == "table" then
      for _, widget in pairs(acd.OpenFrames) do
        local wf = widget and widget.frame
        if wf and wf.IsVisible and SafeBool(wf.IsVisible, wf) then
          return true
        end
      end
    end
  end

  return false
end

local function ShouldUnlockCamera()
  if not SpArc:IsCombatCameraEnabled() then
    return true
  end
  if loadingScreenActive then
    return true
  end
  if holdCursorActive or manualToggleUnlocked then
    return true
  end
  if SpellIsTargeting and SafeBool(SpellIsTargeting) then
    return true
  end
  if GetCursorInfo then
    local ok, infoType = pcall(GetCursorInfo)
    if ok and not SpArc.IsSecret(infoType) and infoType ~= nil then
      return true
    end
  end
  if InCinematic and SafeBool(InCinematic) then
    return true
  end
  if IsInCinematicScene and SafeBool(IsInCinematicScene) then
    return true
  end
  if barberShopActive then
    return true
  end
  if (_G.BarberShopFrame and _G.BarberShopFrame.IsShown and SafeBool(_G.BarberShopFrame.IsShown, _G.BarberShopFrame))
    or (_G.CharCustomizeFrame and _G.CharCustomizeFrame.IsShown and SafeBool(_G.CharCustomizeFrame.IsShown, _G.CharCustomizeFrame)) then
    return true
  end
  if C_PetBattles and C_PetBattles.IsInBattle and SafeBool(C_PetBattles.IsInBattle) then
    return true
  end
  -- Unlock cursor when dead on the ground (before releasing spirit),
  -- but keep Combat Camera active while running in Ghost form!
  if UnitIsDead and SafeBool(UnitIsDead, "player") and not (UnitIsGhost and SafeBool(UnitIsGhost, "player")) then
    return true
  end
  if IsAnyWatchedFrameVisible() then
    return true
  end
  return false
end

local function LockCamera()
  if not SpArc:IsCombatCameraEnabled() then return end
  if IsMouselooking and not IsMouselooking() then
    lockBounceToken = lockBounceToken + 1
    local myToken = lockBounceToken
    -- 1. Force CursorFreelookCentering=0 BEFORE MouselookStart() so OS cursor hides cleanly
    SetFreelookCenteringCVar(false, true)
    EnsureBaseCameraCVars()
    if MouselookStart then
      pcall(MouselookStart)
    end
    -- 2. Deferred on next frame: enable CursorFreelookCentering=1 so @mouseover & @cursor sit on the crosshair!
    if C_Timer and C_Timer.After then
      C_Timer.After(0, function()
        if myToken ~= lockBounceToken then return end
        if SpArc:IsCombatCameraEnabled() and IsMouselooking and IsMouselooking() then
          SyncCursorCenteredYPos(true)
          SetFreelookCenteringCVar(true, true)
        end
      end)
    else
      SyncCursorCenteredYPos(true)
      SetFreelookCenteringCVar(true, true)
    end
    if _G.GameTooltip and _G.GameTooltip:IsShown() then
      local owner = _G.GameTooltip:GetOwner()
      if owner == UIParent or owner == _G.WorldFrame then
        _G.GameTooltip:Hide()
      end
    end
  end
  UpdateCrosshairVisual()
end

local function UnlockCamera()
  local wasLooking = IsMouselooking and IsMouselooking()
  if wasLooking or lastFreelookCentering ~= "0" then
    lockBounceToken = lockBounceToken + 1
    SetFreelookCenteringCVar(false, true)
    if C_CVar and C_CVar.SetCVar then
      pcall(C_CVar.SetCVar, "CursorStickyCentering", "0")
    end
    if wasLooking and MouselookStop then
      pcall(MouselookStop)
    end
  end
  UpdateCrosshairVisual()
end

function SpArc:UpdateCameraState()
  if not SpArc:IsCombatCameraEnabled() then
    if crosshairFrame:IsShown() then crosshairFrame:Hide() end
    return
  end

  if ShouldUnlockCamera() then
    UnlockCamera()
  else
    -- Do not snatch the cursor away while the user is actively holding LMB/RMB while unlocked
    if IsMouselooking and not IsMouselooking() and IsMouseButtonDown and (IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")) then
      UpdateCrosshairVisual()
      return
    end
    LockCamera()
  end
end

---------------------------------------------------------------------------------------
--  5. KEYBINDS: CONFIGURABLE ON-HOLD FREE CURSOR & ON-PRESS TOGGLE CAMERA
---------------------------------------------------------------------------------------
local MOUSE_KEY_TO_BTN = {
  BUTTON1 = "LeftButton",
  BUTTON2 = "RightButton",
  BUTTON3 = "MiddleButton",
  BUTTON4 = "Button4",
  BUTTON5 = "Button5",
}

local function IsBindKeyPhysicallyDown(bindStr)
  if type(bindStr) ~= "string" or bindStr == "" then return false end
  local baseKey = bindStr:gsub("^SHIFT%-", ""):gsub("^CTRL%-", ""):gsub("^ALT%-", "")
  if baseKey == "" then return false end
  local mBtn = MOUSE_KEY_TO_BTN[baseKey]
  if mBtn and IsMouseButtonDown then
    return IsMouseButtonDown(mBtn) and true or false
  end
  if IsKeyDown then
    return IsKeyDown(baseKey) and true or false
  end
  return false
end

local function IsHoldKeyPhysicallyDown()
  local holdKey = SpArc:GetCamHoldKey()
  if IsBindKeyPhysicallyDown(holdKey) then
    return true
  end
  if GetBindingKey then
    local ok, k1, k2 = pcall(GetBindingKey, "SpArc - Hold Free Cursor")
    if ok then
      if k1 and not SpArc.IsSecret(k1) and k1 ~= "" and IsBindKeyPhysicallyDown(k1) then return true end
      if k2 and not SpArc.IsSecret(k2) and k2 ~= "" and IsBindKeyPhysicallyDown(k2) then return true end
    end
  end
  return false
end

local function StartHoldKeyPoll()
  if holdPollRunning or not (C_Timer and C_Timer.After) then return end
  holdPollRunning = true

  local function poll()
    if not holdCursorActive then
      holdPollRunning = false
      return
    end
    if IsHoldKeyPhysicallyDown() then
      C_Timer.After(0.03, poll)
      return
    end
    -- Key G is released: immediately relock camera!
    holdCursorActive = false
    holdPollRunning = false
    SpArc:UpdateCameraState()
  end

  C_Timer.After(0.03, poll)
end

function _G.SpArc_CameraHoldKey(keystate)
  if not SpArc:IsCombatCameraEnabled() then return end
  if keystate == "down" then
    holdCursorActive = true
    UnlockCamera()
    StartHoldKeyPoll()
  elseif keystate == "up" then
    if not IsHoldKeyPhysicallyDown() then
      holdCursorActive = false
      SpArc:UpdateCameraState()
    end
  end
end

function _G.SpArc_CameraToggleKey(keystate)
  if not SpArc:IsCombatCameraEnabled() then return end
  if keystate and keystate ~= "down" then return end
  if holdCursorActive then
    holdCursorActive = false
    manualToggleUnlocked = false
  else
    manualToggleUnlocked = not manualToggleUnlocked
  end
  SpArc:UpdateCameraState()
end

---------------------------------------------------------------------------------------
--  6. OVERRIDE BINDINGS & DIRECT BARTENDER4 MOUSELOOK CLICK-CASTING
---------------------------------------------------------------------------------------
local bindOwner = CreateFrame("Frame", "SpArcCameraBindOwner", UIParent)

local holdBtn = CreateFrame("Button", "SpArcCamHoldButton", UIParent)
holdBtn:RegisterForClicks("AnyDown", "AnyUp")
holdBtn:SetScript("OnClick", function(_, _, down)
  _G.SpArc_CameraHoldKey(down and "down" or "up")
end)

local toggleBtn = CreateFrame("Button", "SpArcCamToggleButton", UIParent)
toggleBtn:RegisterForClicks("AnyDown")
toggleBtn:SetScript("OnClick", function()
  _G.SpArc_CameraToggleKey("down")
end)

local BASE_INTERACT_MACRO = "/target [@mouseover,nodead,exists]"

function SpArc:ClearPendingAutoUnshift()
end

local function UpdateAutoUnshiftBindings()
end

local interactBtn = CreateFrame("Button", "SpArcCamInteractButton", UIParent, "SecureActionButtonTemplate")
interactBtn:RegisterForClicks("AnyDown")
interactBtn:SetAttribute("type", "macro")
interactBtn:SetAttribute("macrotext", BASE_INTERACT_MACRO)

local lastInteractMode = nil
local lastInteractKey = nil

local function ComputeDesiredInteractMode()
  -- 1. If any soft-interact object/corpse/chest/NPC is in range, ALWAYS use native INTERACTTARGET so looting/chests never fail!
  if UnitExists and SafeBool(UnitExists, "softinteract") then
    return "INTERACT"
  end

  -- 2. Only when pointing directly at a LIVE unit under crosshair (not a corpse!) that is not already our target, target it on E
  if UnitExists and SafeBool(UnitExists, "mouseover") then
    local isDead = UnitIsDead and SafeBool(UnitIsDead, "mouseover")
    if not isDead then
      local alreadyTarget = UnitExists and SafeBool(UnitExists, "target") and UnitIsUnit and SafeBool(UnitIsUnit, "target", "mouseover")
      if not alreadyTarget then
        return "TARGET"
      end
    end
  end

  return "INTERACT"
end

local function UpdateInteractBindingMode(force)
  if InCombatLockdown and InCombatLockdown() then return end
  if not SpArc:IsCombatCameraEnabled() then return end
  local interactKey = SpArc:GetCamInteractKey()
  if not interactKey or interactKey == "" then
    if lastInteractKey ~= "" then
      if ClearOverrideBindings then pcall(ClearOverrideBindings, interactBtn) end
      lastInteractKey = ""
      lastInteractMode = nil
    end
    return
  end

  -- Never swap the binding while the user is physically holding the interact key down!
  if not force and IsBindKeyPhysicallyDown(interactKey) then
    return
  end

  local mode = ComputeDesiredInteractMode()
  if not force and mode == lastInteractMode and interactKey == lastInteractKey then
    return
  end

  lastInteractMode = mode
  lastInteractKey = interactKey
  if ClearOverrideBindings then
    pcall(ClearOverrideBindings, interactBtn)
  end
  if mode == "TARGET" and SetOverrideBindingClick then
    pcall(SetOverrideBindingClick, interactBtn, true, interactKey, "SpArcCamInteractButton", "LeftButton")
  elseif SetOverrideBinding then
    pcall(SetOverrideBinding, interactBtn, true, interactKey, "INTERACTTARGET")
  end
end

local function ResolveBartenderKeybindCommand(key, fallbackAction)
  if not key or key == "" then return nil end
  local action = fallbackAction or DEFAULT_MOUSE_KEY_TO_ACTION[key]
  if key ~= "BUTTON1" and key ~= "BUTTON2" and GetBindingAction then
    local ok, userBind = pcall(GetBindingAction, key)
    if ok and not SpArc.IsSecret(userBind) then
      if userBind and userBind ~= "" and userBind ~= "CAMERAORSELECTORMOVE" and userBind ~= "TURNORACTION" then
        action = userBind
      elseif action and GetBindingKey then
        -- If the user unbound this modifier-mouse key (e.g. ALT-BUTTON1) and bound another key (e.g. BUTTON3)
        -- to the default slot (e.g. ACTIONBUTTON7), respect their unbind instead of forcing the fallback!
        local okK, k1 = pcall(GetBindingKey, action)
        if okK and k1 and not SpArc.IsSecret(k1) and k1 ~= "" and k1 ~= key then
          return nil
        end
      end
    end
  end
  if not action or action == "" then return nil end

  if action:match("^CLICK ") then
    return action:gsub("^(CLICK%s+BT4Button%d+):%S+$", "%1:Keybind")
  end

  local num = action:match("^ACTIONBUTTON(%d+)$")
  if num and _G["BT4Button" .. num] then
    return "CLICK BT4Button" .. num .. ":Keybind"
  end
  return action
end

local isApplyingBindings = false

function SpArc:ApplyCombatCameraBindings(reason)
  if isApplyingBindings then return end
  if InCombatLockdown and InCombatLockdown() then
    pendingBindingSync = true
    return
  end
  pendingBindingSync = false
  isApplyingBindings = true

  if ClearOverrideBindings then
    pcall(ClearOverrideBindings, bindOwner)
    pcall(ClearOverrideBindings, interactBtn)
  end

  SpArc:CheckAndResolveCameraBindConflicts(reason or "SYNC")

  if not SpArc:IsCombatCameraEnabled() then
    interactBtn:SetAttribute("camenabled", false)
    if UnregisterStateDriver then
      pcall(UnregisterStateDriver, interactBtn, "caminteract")
    end
    if SetMouselookOverrideBinding then
      for key in pairs(DEFAULT_MOUSE_KEY_TO_ACTION) do
        pcall(SetMouselookOverrideBinding, key, nil)
      end
    end
    isApplyingBindings = false
    UnlockCamera()
    return
  end

  NeutralizeExternalCombatMode()
  EnsureBaseCameraCVars()
  SpArc:ApplyCameraCrosshairLayout()

  -- 1. Bind configured Hold Free Cursor, Toggle Combat Camera & Interact keys
  local holdKey = SpArc:GetCamHoldKey()
  local toggleKey = SpArc:GetCamToggleKey()
  local interactKey = SpArc:GetCamInteractKey()

  if SetOverrideBindingClick then
    if holdKey and holdKey ~= "" then
      pcall(SetOverrideBindingClick, bindOwner, true, holdKey, "SpArcCamHoldButton")
    end
    if toggleKey and toggleKey ~= "" then
      pcall(SetOverrideBindingClick, bindOwner, true, toggleKey, "SpArcCamToggleButton")
    end

    if GetBindingKey then
      local okH, hk1, hk2 = pcall(GetBindingKey, "SpArc - Hold Free Cursor")
      if okH then
        if hk1 and not SpArc.IsSecret(hk1) and hk1 ~= "" then pcall(SetOverrideBindingClick, bindOwner, true, hk1, "SpArcCamHoldButton") end
        if hk2 and not SpArc.IsSecret(hk2) and hk2 ~= "" then pcall(SetOverrideBindingClick, bindOwner, true, hk2, "SpArcCamHoldButton") end
      end

      local okT, tk1, tk2 = pcall(GetBindingKey, "SpArc - Toggle Combat Camera")
      if okT then
        if tk1 and not SpArc.IsSecret(tk1) and tk1 ~= "" then pcall(SetOverrideBindingClick, bindOwner, true, tk1, "SpArcCamToggleButton") end
        if tk2 and not SpArc.IsSecret(tk2) and tk2 ~= "" then pcall(SetOverrideBindingClick, bindOwner, true, tk2, "SpArcCamToggleButton") end
      end
    end
  end

  if UnregisterStateDriver then
    pcall(UnregisterStateDriver, interactBtn, "caminteract")
  end
  UpdateInteractBindingMode(true)

  -- 2. Bind LMB/RMB + Shift/Ctrl/Alt Mouselook Click-Casting directly to Bartender4 :Keybind (or ActionButton 1..8)
  if SetMouselookOverrideBinding then
    if SpArc:IsCamClickCastEnabled() then
      for key, defaultAction in pairs(DEFAULT_MOUSE_KEY_TO_ACTION) do
        local cmd = ResolveBartenderKeybindCommand(key, defaultAction)
        if cmd then
          pcall(SetMouselookOverrideBinding, key, cmd)
        end
      end
    else
      for key in pairs(DEFAULT_MOUSE_KEY_TO_ACTION) do
        pcall(SetMouselookOverrideBinding, key, nil)
      end
    end
  end

  isApplyingBindings = false
end

---------------------------------------------------------------------------------------
--  7. EVENT DRIVER, RELOAD SAFETY & 20HZ UPDATE LOOP
---------------------------------------------------------------------------------------
local camDriver = CreateFrame("Frame", "SpArcCameraDriver", UIParent)
camDriver:RegisterEvent("PLAYER_LOGIN")
camDriver:RegisterEvent("PLAYER_ENTERING_WORLD")
camDriver:RegisterEvent("PLAYER_REGEN_ENABLED")
camDriver:RegisterEvent("PLAYER_DEAD")
camDriver:RegisterEvent("PLAYER_ALIVE")
camDriver:RegisterEvent("PLAYER_UNGHOST")
camDriver:RegisterEvent("UPDATE_BINDINGS")
camDriver:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
camDriver:RegisterEvent("LOADING_SCREEN_ENABLED")
camDriver:RegisterEvent("LOADING_SCREEN_DISABLED")
camDriver:RegisterEvent("PLAYER_LOGOUT")
camDriver:RegisterEvent("BARBER_SHOP_OPEN")
camDriver:RegisterEvent("BARBER_SHOP_CLOSE")
camDriver:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
camDriver:RegisterEvent("PLAYER_TARGET_CHANGED")
camDriver:RegisterUnitEvent("UNIT_TARGET", "player")
pcall(camDriver.RegisterEvent, camDriver, "PLAYER_SOFT_INTERACT_CHANGED")
pcall(camDriver.RegisterEvent, camDriver, "PLAYER_SOFT_ENEMY_CHANGED")
pcall(camDriver.RegisterEvent, camDriver, "PLAYER_SOFT_FRIEND_CHANGED")

-- Critical: Always stop Mouselook BEFORE ReloadUI so WoW's Win32 ShowCursor counter never desyncs!
if _G.hooksecurefunc and _G.ReloadUI then
  _G.hooksecurefunc("ReloadUI", function()
    loadingScreenActive = true
    ForceCleanCursorCVars()
    if IsMouselooking and IsMouselooking() and MouselookStop then
      pcall(MouselookStop)
    end
  end)
end

camDriver:SetScript("OnEvent", function(_, event)
  if event == "LOADING_SCREEN_ENABLED" or event == "PLAYER_LOGOUT" then
    loadingScreenActive = true
    ForceCleanCursorCVars()
    if IsMouselooking and IsMouselooking() and MouselookStop then
      pcall(MouselookStop)
    end
    return
  end

  if event == "LOADING_SCREEN_DISABLED" then
    loadingScreenActive = false
  end

  if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
    loadingScreenActive = false
    EnsureTooltipHook()
    NeutralizeExternalCombatMode()
    ForceCleanCursorCVars()

    if not hardwareCursorFlushed and SpArc:IsCombatCameraEnabled() then
      hardwareCursorFlushed = true
      SpArc:FlushHardwareCursor(false)
    end

    SpArc:ApplyCombatCameraBindings()

    if C_Timer and C_Timer.After then
      C_Timer.After(0.25, function()
        NeutralizeExternalCombatMode()
        EnsureBaseCameraCVars()
        SpArc:ApplyCombatCameraBindings()
        -- Bounce mouselook once after PEW so CursorFreelookCentering=1 locks onto crosshair
        if IsMouselooking and IsMouselooking() then
          UnlockCamera()
        end
        SpArc:UpdateCameraState()
      end)
      C_Timer.After(1.2, function()
        NeutralizeExternalCombatMode()
        EnsureBaseCameraCVars()
        SpArc:ApplyCombatCameraBindings()
        SpArc:UpdateCameraState()
        if SpArc:IsCombatCameraEnabled() and IsMouselooking and IsMouselooking() then
          SyncCursorCenteredYPos()
          SetFreelookCenteringCVar(true)
        end
      end)
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    pendingPostCombatUnshift = true
    if SpArc.state then
      SpArc.state.lastManualFormCastAt = 0
    end
    if pendingBindingSync then
      SpArc:ApplyCombatCameraBindings("REGEN_ENABLED")
    end
    UpdateAutoUnshiftBindings(true)
    UpdateInteractBindingMode(true)
  elseif event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
    loadingScreenActive = false
    if pendingBindingSync and not (InCombatLockdown and InCombatLockdown()) then
      SpArc:ApplyCombatCameraBindings(event)
    end
    SpArc:UpdateCameraState()
    if C_Timer and C_Timer.After then
      C_Timer.After(0.15, function()
        loadingScreenActive = false
        SpArc:UpdateCameraState()
      end)
    end
  elseif event == "UPDATE_BINDINGS" then
    if not isApplyingBindings then
      SpArc:ApplyCombatCameraBindings("UPDATE_BINDINGS")
    end
  elseif event == "ACTIONBAR_PAGE_CHANGED" then
    if not isApplyingBindings then
      SpArc:ApplyCombatCameraBindings("ACTIONBAR_PAGE_CHANGED")
    end
  elseif event == "BARBER_SHOP_OPEN" then
    barberShopActive = true
    SpArc:UpdateCameraState()
  elseif event == "BARBER_SHOP_CLOSE" then
    barberShopActive = false
    SpArc:UpdateCameraState()
  elseif event == "UPDATE_MOUSEOVER_UNIT"
    or event == "PLAYER_TARGET_CHANGED"
    or event == "UNIT_TARGET"
    or event == "PLAYER_SOFT_INTERACT_CHANGED"
    or event == "PLAYER_SOFT_ENEMY_CHANGED"
    or event == "PLAYER_SOFT_FRIEND_CHANGED" then
    UpdateInteractBindingMode(false)
  end
end)

local elapsedAccum = 0
camDriver:SetScript("OnUpdate", function(_, elapsed)
  elapsedAccum = elapsedAccum + (elapsed or 0)
  if elapsedAccum < 0.05 then return end
  elapsedAccum = 0

  if not SpArc:IsCombatCameraEnabled() then
    if crosshairFrame:IsShown() then crosshairFrame:Hide() end
    return
  end

  UpdateAutoUnshiftBindings(false)
  UpdateInteractBindingMode(false)
  SpArc:UpdateCameraState()
end)

NeutralizeExternalCombatMode()
ForceCleanCursorCVars()

