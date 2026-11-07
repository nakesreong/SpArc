---------------------------------------------------------------------------------------
--  SpArc/EditMode.lua — Native Blizzard Edit Mode ("Редактировать") Integration
--                       & Universal Drag/Nudge Movers for All SpArc HUD Elements
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
--  @module EditMode
--  @responsibility
--    1. Provides a unified drag & 1px/10px arrow-key nudge mover system (`RegisterEditMover`)
--       for all SpArc HUD and UnitFrame widgets.
--    2. Hooks Blizzard's native `EditModeManagerFrame` so opening "Редактировать" automatically
--       unlocks all SpArc movers alongside Blizzard frames.
--  @techdebt [AUDIT-EM1]
--    - `SetMoverBackdrop` (line 38) duplicates `SetBackdropFlat` from `SpArc.lua`.
--      Planned Refactor (Phase 1): Share flat backdrop helper via `Core.lua`.
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc

local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local GetCursorPosition = _G.GetCursorPosition
local IsShiftKeyDown = _G.IsShiftKeyDown
local InCombatLockdown = _G.InCombatLockdown
local pcall = _G.pcall
local ipairs = _G.ipairs
local tonumber = _G.tonumber
local tostring = _G.tostring
local type = _G.type
local math = _G.math
local string = _G.string

local ApplyCyrFont = SpArc.ApplyCyrFont
local IsSecret = SpArc.IsSecret
local DEFAULT_VISUAL = SpArc.DEFAULT_VISUAL

SpArc.editModeActive = false
SpArc.editMovers = SpArc.editMovers or {}
local moverRegistry = {}
local moverById = {}
local selectedMover = nil
local savedTestModeBeforeEdit = nil
local editHelperBar = nil

local function RoundCoord(v)
  return math.floor((tonumber(v) or 0) + 0.5)
end

local SetMoverBackdrop = SpArc.SetBackdropFlat

local function ApplyMoverVisualState(mover)
  if not mover then return end
  local isSel = (selectedMover == mover)
  if mover.isDragging or isSel then
    SetMoverBackdrop(mover, 0.10, 0.28, 0.48, 0.72, 1.00, 0.82, 0.18, 1.00)
    mover.label:SetTextColor(1.00, 0.92, 0.35, 1.0)
  elseif mover.isHovered then
    SetMoverBackdrop(mover, 0.12, 0.32, 0.56, 0.65, 0.40, 0.85, 1.00, 1.00)
    mover.label:SetTextColor(1.00, 1.00, 1.00, 1.0)
  else
    local c = mover.spec.color or { 0.08, 0.22, 0.40 }
    local br = mover.spec.borderColor or { 0.28, 0.68, 1.00 }
    SetMoverBackdrop(mover, c[1], c[2], c[3], 0.52, br[1], br[2], br[3], 0.92)
    mover.label:SetTextColor(0.90, 0.95, 1.00, 0.98)
  end
end

local function GetMoverCoords(spec, v)
  if spec.getCoords then
    return spec.getCoords(v)
  end
  local x = tonumber(v[spec.keyX])
  if x == nil then
    x = tonumber(spec.defaultX) or tonumber(DEFAULT_VISUAL[spec.keyX]) or 0
  end
  local y = tonumber(v[spec.keyY])
  if y == nil then
    if spec.fallbackKeyY and v[spec.fallbackKeyY] ~= nil then
      y = tonumber(v[spec.fallbackKeyY])
    end
    if y == nil then
      y = tonumber(spec.defaultY) or tonumber(DEFAULT_VISUAL[spec.keyY]) or 0
    end
  end
  return RoundCoord(x), RoundCoord(y)
end

local function SetMoverCoords(spec, v, newX, newY)
  newX = math.max(-1600, math.min(1600, RoundCoord(newX)))
  newY = math.max(-1000, math.min(1000, RoundCoord(newY)))
  if spec.setCoords then
    spec.setCoords(v, newX, newY)
  else
    if spec.keyX then v[spec.keyX] = newX end
    if spec.keyY then v[spec.keyY] = newY end
  end
  if spec.onChanged then
    spec.onChanged(v, newX, newY)
  else
    if SpArc.ApplyVisualLayout then
      SpArc:ApplyVisualLayout()
    end
  end
  if SpArc.RefreshControlCenterUI then
    SpArc.RefreshControlCenterUI()
  end
end

local function ResetMoverCoords(spec, v)
  if spec.resetCoords then
    spec.resetCoords(v)
  else
    local defX = tonumber(spec.defaultX)
    if defX == nil and spec.keyX then defX = tonumber(DEFAULT_VISUAL[spec.keyX]) end
    local defY = tonumber(spec.defaultY)
    if defY == nil and spec.keyY then defY = tonumber(DEFAULT_VISUAL[spec.keyY]) end
    if spec.keyX then v[spec.keyX] = defX or 0 end
    if spec.keyY then
      if spec.fallbackKeyY then
        v[spec.keyY] = nil
      else
        v[spec.keyY] = defY or 0
      end
    end
  end
  if spec.onChanged then
    local rx, ry = GetMoverCoords(spec, v)
    spec.onChanged(v, rx, ry)
  else
    if SpArc.ApplyVisualLayout then
      SpArc:ApplyVisualLayout()
    end
  end
  if SpArc.RefreshControlCenterUI then
    SpArc.RefreshControlCenterUI()
  end
end

local function SyncSingleMover(mover)
  if not mover or not mover.spec then return end
  local db = SpArc:EnsureDB()
  local v = db.visual or DEFAULT_VISUAL
  local spec = mover.spec

  local w, h = spec.width or 160, spec.height or 44
  if spec.getSize then
    local dw, dh = spec.getSize(v)
    if dw and dw > 0 then w = dw end
    if dh and dh > 0 then h = dh end
  end
  mover:SetSize(w, h)

  local cx, cy = GetMoverCoords(spec, v)
  local visualOffsetX, visualOffsetY = 0, 0
  if spec.getVisualDelta then
    visualOffsetX, visualOffsetY = spec.getVisualDelta(v)
  end

  if not mover.isDragging then
    mover:ClearAllPoints()
    mover:SetPoint("CENTER", UIParent, "CENTER", cx + (visualOffsetX or 0), cy + (visualOffsetY or 0))
  end

  local titleStr = spec.labelKey and SpArc:L(spec.labelKey) or (spec.label or spec.id)
  mover.label:SetText(string.format("%s\n|cffffd100(%d, %d)|r", titleStr, cx, cy))
  ApplyMoverVisualState(mover)
end

function SpArc:SyncEditModeMovers()
  if not SpArc.editModeActive then return end
  for _, mover in ipairs(moverRegistry) do
    if mover:IsShown() then
      SyncSingleMover(mover)
    end
  end
  if editHelperBar and editHelperBar.RefreshTexts then
    editHelperBar:RefreshTexts()
  end
end

local function SelectMover(mover)
  local prev = selectedMover
  selectedMover = mover
  if prev and prev ~= mover then
    prev:EnableKeyboard(false)
    ApplyMoverVisualState(prev)
  end
  if mover then
    mover:EnableKeyboard(true)
    if mover.SetPropagateKeyboardInput then
      pcall(mover.SetPropagateKeyboardInput, mover, true)
    end
    ApplyMoverVisualState(mover)
  end
end

local function CreateMoverFrame(spec)
  local mover = CreateFrame("Frame", "SpArcEditMover_" .. tostring(spec.id), UIParent, "BackdropTemplate")
  mover.spec = spec
  mover:SetSize(spec.width or 160, spec.height or 44)
  mover:SetFrameStrata("DIALOG")
  mover:SetFrameLevel(spec.frameLevel or 120)
  mover:EnableMouse(true)
  mover:SetMovable(true)
  mover:RegisterForDrag("LeftButton")
  mover:Hide()

  -- Center crosshair lines inside mover
  local hLine = mover:CreateTexture(nil, "ARTWORK")
  hLine:SetHeight(1)
  hLine:SetPoint("LEFT", mover, "LEFT", 2, 0)
  hLine:SetPoint("RIGHT", mover, "RIGHT", -2, 0)
  hLine:SetColorTexture(0.45, 0.80, 1.0, 0.25)

  local vLine = mover:CreateTexture(nil, "ARTWORK")
  vLine:SetWidth(1)
  vLine:SetPoint("TOP", mover, "TOP", 0, -2)
  vLine:SetPoint("BOTTOM", mover, "BOTTOM", 0, 2)
  vLine:SetColorTexture(0.45, 0.80, 1.0, 0.25)

  local label = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(label, 11)
  label:SetPoint("CENTER", mover, "CENTER", 0, 0)
  label:SetJustifyH("CENTER")
  mover.label = label

  mover:SetScript("OnEnter", function(self)
    self.isHovered = true
    ApplyMoverVisualState(self)
  end)
  mover:SetScript("OnLeave", function(self)
    self.isHovered = false
    ApplyMoverVisualState(self)
  end)

  mover:SetScript("OnMouseDown", function(self, btn)
    if btn == "RightButton" then
      local db = SpArc:EnsureDB()
      ResetMoverCoords(self.spec, db.visual)
      SyncSingleMover(self)
    elseif btn == "LeftButton" then
      SelectMover(self)
    end
  end)

  mover:SetScript("OnDragStart", function(self)
    SelectMover(self)
    self.isDragging = true
    local db = SpArc:EnsureDB()
    local v = db.visual or DEFAULT_VISUAL
    local startX, startY = GetMoverCoords(self.spec, v)
    self.dragStartCoordX = startX
    self.dragStartCoordY = startY

    local okP, cx, cy = pcall(GetCursorPosition)
    local okS, scale = pcall(UIParent.GetEffectiveScale, UIParent)
    if okP and okS and not IsSecret(cx) and not IsSecret(cy) and not IsSecret(scale) and scale and scale > 0 then
      self.dragCursorStartX = cx / scale
      self.dragCursorStartY = cy / scale
    else
      self.dragCursorStartX = 0
      self.dragCursorStartY = 0
    end

    self:SetScript("OnUpdate", function(m)
      local okP2, ncx, ncy = pcall(GetCursorPosition)
      local okS2, nscale = pcall(UIParent.GetEffectiveScale, UIParent)
      if not okP2 or not okS2 or IsSecret(ncx) or IsSecret(ncy) or IsSecret(nscale) or not nscale or nscale <= 0 then
        return
      end
      local curX = ncx / nscale
      local curY = ncy / nscale
      local dx = curX - (m.dragCursorStartX or curX)
      local dy = curY - (m.dragCursorStartY or curY)
      local newX = RoundCoord((m.dragStartCoordX or 0) + dx)
      local newY = RoundCoord((m.dragStartCoordY or 0) + dy)

      local curDB = SpArc:EnsureDB()
      local curV = curDB.visual or DEFAULT_VISUAL
      local vdx, vdy = 0, 0
      if m.spec.getVisualDelta then
        vdx, vdy = m.spec.getVisualDelta(curV)
      end
      m:ClearAllPoints()
      m:SetPoint("CENTER", UIParent, "CENTER", newX + (vdx or 0), newY + (vdy or 0))
      SetMoverCoords(m.spec, curV, newX, newY)
      local titleStr = m.spec.labelKey and SpArc:L(m.spec.labelKey) or (m.spec.label or m.spec.id)
      m.label:SetText(string.format("%s\n|cffffd100(%d, %d)|r", titleStr, newX, newY))
    end)
    ApplyMoverVisualState(self)
  end)

  mover:SetScript("OnDragStop", function(self)
    self.isDragging = false
    self:SetScript("OnUpdate", nil)
    SyncSingleMover(self)
  end)

  mover:SetScript("OnKeyDown", function(self, key)
    if selectedMover ~= self then
      if self.SetPropagateKeyboardInput then
        pcall(self.SetPropagateKeyboardInput, self, true)
      end
      return
    end
    local step = (IsShiftKeyDown and IsShiftKeyDown()) and 10 or 1
    local dx, dy = 0, 0
    if key == "LEFT" then
      dx = -step
    elseif key == "RIGHT" then
      dx = step
    elseif key == "UP" then
      dy = step
    elseif key == "DOWN" then
      dy = -step
    else
      if self.SetPropagateKeyboardInput then
        pcall(self.SetPropagateKeyboardInput, self, true)
      end
      return
    end
    if self.SetPropagateKeyboardInput then
      pcall(self.SetPropagateKeyboardInput, self, false)
    end
    local db = SpArc:EnsureDB()
    local v = db.visual or DEFAULT_VISUAL
    local cx, cy = GetMoverCoords(self.spec, v)
    SetMoverCoords(self.spec, v, cx + dx, cy + dy)
    SyncSingleMover(self)
  end)

  return mover
end

function SpArc:RegisterEditMover(spec)
  if type(spec) ~= "table" or not spec.id then return nil end
  if moverById[spec.id] then
    moverById[spec.id].spec = spec
    return moverById[spec.id]
  end
  local mover = CreateMoverFrame(spec)
  moverRegistry[#moverRegistry + 1] = mover
  moverById[spec.id] = mover
  SpArc.editMovers[spec.id] = mover
  if SpArc.editModeActive then
    mover:Show()
    SyncSingleMover(mover)
  end
  return mover
end

local function EnsureEditHelperBar()
  if editHelperBar then return editHelperBar end

  local bar = CreateFrame("Frame", "SpArcEditModeHelperBar", UIParent, "BackdropTemplate")
  bar:SetSize(780, 40)
  bar:SetPoint("TOP", UIParent, "TOP", 0, -14)
  bar:SetFrameStrata("FULLSCREEN_DIALOG")
  bar:SetFrameLevel(200)
  bar:EnableMouse(true)
  bar:SetMovable(true)
  bar:RegisterForDrag("LeftButton")
  bar:SetScript("OnDragStart", bar.StartMoving)
  bar:SetScript("OnDragStop", bar.StopMovingOrSizing)
  SetMoverBackdrop(bar, 0.05, 0.05, 0.08, 0.96, 0.35, 0.72, 1.00, 1.00)
  bar:Hide()

  local title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(title, 12)
  title:SetPoint("LEFT", bar, "LEFT", 14, 0)
  title:SetJustifyH("LEFT")
  bar.title = title

  local function CreateHelperBtn(width, text)
    local btn = CreateFrame("Button", nil, bar, "BackdropTemplate")
    btn:SetSize(width, 26)
    SetMoverBackdrop(btn, 0.14, 0.18, 0.28, 0.96, 0.30, 0.55, 0.85, 1.0)
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(fs, 11)
    fs:SetPoint("CENTER")
    fs:SetTextColor(0.95, 0.95, 1.0, 1)
    fs:SetText(text or "")
    btn.fs = fs
    btn:SetScript("OnEnter", function(self)
      SetMoverBackdrop(self, 0.20, 0.34, 0.56, 0.98, 1.0, 0.82, 0.20, 1.0)
    end)
    btn:SetScript("OnLeave", function(self)
      SetMoverBackdrop(self, 0.14, 0.18, 0.28, 0.96, 0.30, 0.55, 0.85, 1.0)
    end)
    return btn
  end

  local doneBtn = CreateHelperBtn(135, "")
  doneBtn:SetPoint("RIGHT", bar, "RIGHT", -10, 0)
  doneBtn:SetScript("OnClick", function()
    SpArc:SetEditMode(false)
    if _G.EditModeManagerFrame and _G.EditModeManagerFrame:IsShown() and _G.HideUIPanel then
      if not (InCombatLockdown and InCombatLockdown()) then
        pcall(_G.HideUIPanel, _G.EditModeManagerFrame)
      end
    end
  end)
  bar.doneBtn = doneBtn

  local resetAllBtn = CreateHelperBtn(165, "")
  resetAllBtn:SetPoint("RIGHT", doneBtn, "LEFT", -8, 0)
  resetAllBtn:SetScript("OnClick", function()
    local db = SpArc:EnsureDB()
    for _, mover in ipairs(moverRegistry) do
      ResetMoverCoords(mover.spec, db.visual)
      SyncSingleMover(mover)
    end
    if db.visual then
      db.visual.ctIncomingX = DEFAULT_VISUAL.ctIncomingX or -260
      db.visual.ctIncomingY = DEFAULT_VISUAL.ctIncomingY or -20
      db.visual.ctOutgoingX = DEFAULT_VISUAL.ctOutgoingX or 260
      db.visual.ctOutgoingY = DEFAULT_VISUAL.ctOutgoingY or 20
      if SpArc.ApplyCombatTextSettings then
        SpArc:ApplyCombatTextSettings()
      end
    end
  end)
  bar.resetAllBtn = resetAllBtn

  function bar:RefreshTexts()
    self.title:SetText(SpArc:L("EM_BAR_TITLE"))
    self.resetAllBtn.fs:SetText(SpArc:L("EM_RESET_ALL_BTN"))
    self.doneBtn.fs:SetText(SpArc:L("EM_DONE_BTN"))
  end

  editHelperBar = bar
  return bar
end

function SpArc:SetEditMode(enabled, fromBlizzEditMode)
  local want = enabled and true or false
  if want and InCombatLockdown and InCombatLockdown() then
    return
  end
  if SpArc.editModeActive == want then
    if want then
      SpArc:SyncEditModeMovers()
    end
    return
  end

  SpArc.editModeActive = want
  if want then
    savedTestModeBeforeEdit = SpArc.testMode
    SpArc.testMode = true
    if SpArc.SetMSBTZonesUnlocked then
      SpArc:SetMSBTZonesUnlocked(true)
    end
    local bar = EnsureEditHelperBar()
    bar:ClearAllPoints()
    if fromBlizzEditMode or (_G.EditModeManagerFrame and _G.EditModeManagerFrame:IsShown()) then
      bar:SetPoint("TOP", UIParent, "TOP", 0, -56)
    else
      bar:SetPoint("TOP", UIParent, "TOP", 0, -14)
    end
    bar:RefreshTexts()
    bar:Show()

    for _, mover in ipairs(moverRegistry) do
      if not mover.spec.isEnabled or mover.spec.isEnabled() then
        mover:Show()
        SyncSingleMover(mover)
      else
        mover:Hide()
      end
    end
  else
    SelectMover(nil)
    if savedTestModeBeforeEdit ~= nil then
      SpArc.testMode = savedTestModeBeforeEdit
      savedTestModeBeforeEdit = nil
    end
    if SpArc.SetMSBTZonesUnlocked then
      SpArc:SetMSBTZonesUnlocked(false)
    end
    if editHelperBar then
      editHelperBar:Hide()
    end
    for _, mover in ipairs(moverRegistry) do
      mover.isDragging = false
      mover:SetScript("OnUpdate", nil)
      mover:Hide()
    end
  end

  if SpArc.ApplyVisualLayout then
    SpArc:ApplyVisualLayout()
  end
  if SpArc.UpdateCameraState then
    SpArc:UpdateCameraState()
  end
  if SpArc.UpdateUnitFrames then
    SpArc:UpdateUnitFrames()
  end
  if SpArc.RefreshControlCenterUI then
    SpArc.RefreshControlCenterUI()
  end
end

function SpArc:ToggleEditMode()
  SpArc:SetEditMode(not SpArc.editModeActive, false)
end

---------------------------------------------------------------------------------------
--  REGISTER CORE SPARC HUD MOVERS
---------------------------------------------------------------------------------------
-- 1. Rotation Arc
SpArc:RegisterEditMover({
  id = "ARC",
  labelKey = "EM_MOVER_ARC",
  keyX = "arcOffsetX",
  keyY = "arcOffsetY",
  defaultX = 0,
  defaultY = 0,
  width = 270,
  height = 96,
  color = { 0.16, 0.10, 0.34 },
  borderColor = { 0.68, 0.35, 1.00 },
  getVisualDelta = function(v)
    local radius = tonumber(v and v.arcRadius) or 135
    return 0, math.floor(0.72 * radius + 0.5)
  end,
})

-- 2. Left Wing (Defensive Saves)
SpArc:RegisterEditMover({
  id = "SAVES_WING",
  labelKey = "EM_MOVER_SAVES",
  keyX = "savesOffsetX",
  keyY = "savesOffsetY",
  fallbackKeyY = "wingsOffsetY",
  defaultX = -246,
  defaultY = -75,
  width = 184,
  height = 46,
  color = { 0.08, 0.28, 0.22 },
  borderColor = { 0.20, 0.90, 0.60 },
})

-- 3. Right Wing (Offensive Cooldowns)
SpArc:RegisterEditMover({
  id = "CDS_WING",
  labelKey = "EM_MOVER_CDS",
  keyX = "cdsOffsetX",
  keyY = "cdsOffsetY",
  fallbackKeyY = "wingsOffsetY",
  defaultX = 246,
  defaultY = -75,
  width = 184,
  height = 46,
  color = { 0.32, 0.16, 0.08 },
  borderColor = { 1.00, 0.58, 0.20 },
})

-- 4. Center Emergency Save Alert
SpArc:RegisterEditMover({
  id = "EMERGENCY",
  labelKey = "EM_MOVER_EMERG",
  keyX = "emergencyOffsetX",
  keyY = "emergencyOffsetY",
  defaultX = 0,
  defaultY = -35,
  width = 72,
  height = 72,
  frameLevel = 135,
  color = { 0.08, 0.32, 0.14 },
  borderColor = { 0.25, 1.00, 0.45 },
})

-- 5. Player Castbar
SpArc:RegisterEditMover({
  id = "CASTBAR",
  labelKey = "EM_MOVER_CASTBAR",
  keyX = "castbarOffsetX",
  keyY = "castbarOffsetY",
  defaultX = 0,
  defaultY = -135,
  width = 276,
  height = 30,
  color = { 0.22, 0.10, 0.36 },
  borderColor = { 0.72, 0.38, 1.00 },
  getSize = function(v)
    return (tonumber(v and v.castbarWidth) or 276) + 30, 30
  end,
})

-- 6. Secondary Resource Bar
SpArc:RegisterEditMover({
  id = "RESOURCE_BAR",
  labelKey = "EM_MOVER_RESBAR",
  keyX = "resourceBarOffsetX",
  keyY = "resourceBarOffsetY",
  defaultX = 0,
  defaultY = -166,
  width = 276,
  height = 24,
  color = { 0.08, 0.22, 0.38 },
  borderColor = { 0.28, 0.75, 1.00 },
  getSize = function(v)
    return tonumber(v and v.resourceBarWidth) or 276, math.max(20, (tonumber(v and v.resourceBarHeight) or 16) + 6)
  end,
})

-- 7. Action Combat Camera Crosshair
SpArc:RegisterEditMover({
  id = "CROSSHAIR",
  labelKey = "EM_MOVER_CROSSHAIR",
  keyX = "camCrosshairOffsetX",
  keyY = "camCrosshairOffsetY",
  defaultX = 0,
  defaultY = 20,
  width = 48,
  height = 48,
  frameLevel = 140,
  color = { 0.08, 0.26, 0.34 },
  borderColor = { 0.35, 0.92, 1.00 },
  onChanged = function()
    if SpArc.ApplyCameraCrosshairLayout then
      SpArc:ApplyCameraCrosshairLayout()
    end
  end,
})

---------------------------------------------------------------------------------------
--  HOOK BLIZZARD EDIT MODE ("РЕДАКТИРОВАТЬ" / EditModeManagerFrame)
---------------------------------------------------------------------------------------
local blizzEditModeHooked = false

local function TryHookBlizzardEditMode()
  if blizzEditModeHooked then return end
  local emf = _G.EditModeManagerFrame
  if emf and emf.HookScript then
    blizzEditModeHooked = true
    emf:HookScript("OnShow", function()
      SpArc:SetEditMode(true, true)
    end)
    emf:HookScript("OnHide", function()
      if SpArc.editModeActive then
        SpArc:SetEditMode(false, true)
      end
    end)
  end
  if _G.EventRegistry and _G.EventRegistry.RegisterCallback then
    pcall(_G.EventRegistry.RegisterCallback, _G.EventRegistry, "EditMode.Enter", function()
      SpArc:SetEditMode(true, true)
    end, SpArc)
    pcall(_G.EventRegistry.RegisterCallback, _G.EventRegistry, "EditMode.Exit", function()
      if SpArc.editModeActive then
        SpArc:SetEditMode(false, true)
      end
    end, SpArc)
  end
end

TryHookBlizzardEditMode()

local emWatcher = CreateFrame("Frame")
emWatcher:RegisterEvent("ADDON_LOADED")
emWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
emWatcher:RegisterEvent("PLAYER_REGEN_DISABLED")
emWatcher:SetScript("OnEvent", function(_, event, arg1)
  if event == "PLAYER_REGEN_DISABLED" then
    if SpArc.editModeActive then
      SpArc:SetEditMode(false)
    end
  elseif event == "ADDON_LOADED" and arg1 == "Blizzard_EditMode" then
    if SpArc.EnsureChatVisibleWithoutElvUI then
      SpArc:EnsureChatVisibleWithoutElvUI()
    end
    TryHookBlizzardEditMode()
  elseif event == "PLAYER_ENTERING_WORLD" then
    if SpArc.EnsureChatVisibleWithoutElvUI then
      SpArc:EnsureChatVisibleWithoutElvUI()
    end
    TryHookBlizzardEditMode()
    if SpArc.RecordModuleTick then
      SpArc:RecordModuleTick("EditMode", "PEW_Hooked:" .. tostring(#moverRegistry))
    end
  end
end)
