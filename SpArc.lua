---------------------------------------------------------------------------------------
--  SpArc/SpArc.lua — ElvUI-Style Modular Control Center UI, Minimap & Slash Commands
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc

local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local UnitClass = _G.UnitClass
local IsShiftKeyDown = _G.IsShiftKeyDown
local IsControlKeyDown = _G.IsControlKeyDown
local IsAltKeyDown = _G.IsAltKeyDown
local pcall = _G.pcall
local ipairs = _G.ipairs
local pairs = _G.pairs
local tonumber = _G.tonumber
local tostring = _G.tostring
local type = _G.type
local math = _G.math
local table = _G.table
local string = _G.string

local ApplyCyrFont = SpArc.ApplyCyrFont
local IsSecret = SpArc.IsSecret
local DEFAULT_VISUAL = SpArc.DEFAULT_VISUAL

local controlFrame
local selectedPresetForEdit = "PRIEST_01_SHADOW_PVE"
local filterClassOnly = true
local showingAIPrompt = false
local isRefreshingUI = false
local currentTabIdx = 1
local activeKeybindCapture = nil

local function GetPlayerClassTag()
  if UnitClass then
    local ok, _, classTag = pcall(UnitClass, "player")
    if ok and not IsSecret(classTag) and type(classTag) == "string" then
      return classTag
    end
  end
  return "PRIEST"
end

---------------------------------------------------------------------------------------
--  ELVUI-STYLE UI COMPONENT BUILDERS
---------------------------------------------------------------------------------------
local function SetBackdropFlat(frame, bgR, bgG, bgB, bgA, brR, brG, brB, brA)
  if not frame.SetBackdrop then return end
  frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  frame:SetBackdropColor(bgR or 0.06, bgG or 0.06, bgB or 0.08, bgA or 0.95)
  frame:SetBackdropBorderColor(brR or 0.20, brG or 0.20, brB or 0.26, brA or 1.0)
end

local function CreateElvButton(parent, width, height, text)
  local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
  btn:SetSize(width, height)
  SetBackdropFlat(btn, 0.12, 0.12, 0.16, 0.96, 0.26, 0.26, 0.34, 1.0)

  local accent = btn:CreateTexture(nil, "OVERLAY")
  accent:SetSize(3, height - 2)
  accent:SetPoint("LEFT", btn, "LEFT", 1, 0)
  accent:SetColorTexture(0.25, 0.65, 1.0, 0)
  btn.accent = accent

  local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(fs, 12)
  fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
  fs:SetTextColor(0.92, 0.92, 0.96, 1)
  fs:SetText(text or "")
  btn.fs = fs

  function btn:SetText(str)
    self.fs:SetText(str or "")
  end

  function btn:SetSelected(isSelected)
    self._isSelected = isSelected and true or false
    if self._isSelected then
      SetBackdropFlat(self, 0.16, 0.32, 0.54, 0.98, 0.32, 0.65, 0.98, 1.0)
      self.fs:SetTextColor(1.0, 0.95, 0.70, 1)
      self.accent:SetColorTexture(0.35, 0.78, 1.0, 1)
    else
      SetBackdropFlat(self, 0.12, 0.12, 0.16, 0.96, 0.26, 0.26, 0.34, 1.0)
      self.fs:SetTextColor(0.90, 0.90, 0.95, 1)
      self.accent:SetColorTexture(0.25, 0.65, 1.0, 0)
    end
  end

  btn:SetScript("OnEnter", function(self)
    if not self._isSelected then
      SetBackdropFlat(self, 0.18, 0.22, 0.32, 0.98, 0.38, 0.62, 0.95, 1.0)
      self.fs:SetTextColor(1, 1, 1, 1)
    end
  end)
  btn:SetScript("OnLeave", function(self)
    self:SetSelected(self._isSelected)
  end)

  return btn
end

local function CreateElvGroupBox(parent, titleKey, x, y, w, h)
  local container = CreateFrame("Frame", nil, parent)
  container:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  container:SetSize(w, h)

  local header = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(header, 13)
  header:SetPoint("TOPLEFT", container, "TOPLEFT", 2, 0)
  header:SetTextColor(1.0, 0.82, 0.18, 1)
  header:SetText(SpArc:L(titleKey))
  container.header = header
  container.titleKey = titleKey

  local box = CreateFrame("Frame", nil, container, "BackdropTemplate")
  box:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -20)
  box:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
  SetBackdropFlat(box, 0.08, 0.08, 0.11, 0.92, 0.20, 0.20, 0.27, 1.0)
  container.box = box

  return container, box
end

---------------------------------------------------------------------------------------
--  MAIN CONTROL CENTER WINDOW (ELVUI MODULAR LAYOUT)
---------------------------------------------------------------------------------------
local function OpenControlCenter(initialTab)
  local db = SpArc:EnsureDB()

  -- Legacy 4-tab index compatibility: 4 -> 7 (Telemetry)
  if initialTab == 4 then
    initialTab = 7
  end

  if not controlFrame then
    controlFrame = CreateFrame("Frame", "SpArcControlCenter", UIParent, "BackdropTemplate")
    controlFrame:SetSize(880, 620)
    controlFrame:SetPoint("CENTER")
    controlFrame:SetFrameStrata("DIALOG")
    controlFrame:SetMovable(true)
    controlFrame:EnableMouse(true)
    controlFrame:RegisterForDrag("LeftButton")
    controlFrame:SetScript("OnDragStart", controlFrame.StartMoving)
    controlFrame:SetScript("OnDragStop", controlFrame.StopMovingOrSizing)
    SetBackdropFlat(controlFrame, 0.05, 0.05, 0.07, 0.97, 0.24, 0.24, 0.32, 1.0)

    controlFrame:SetScript("OnHide", function()
      SpArc.previewCrosshairInConfig = false
      if activeKeybindCapture and activeKeybindCapture.CancelCapture then
        activeKeybindCapture:CancelCapture()
      end
      if SpArc.UpdateCameraState then
        SpArc:UpdateCameraState()
      end
    end)

    -- Top Header Bar
    local topBar = CreateFrame("Frame", nil, controlFrame, "BackdropTemplate")
    topBar:SetPoint("TOPLEFT", controlFrame, "TOPLEFT", 1, -1)
    topBar:SetPoint("TOPRIGHT", controlFrame, "TOPRIGHT", -1, -1)
    topBar:SetHeight(50)
    SetBackdropFlat(topBar, 0.07, 0.07, 0.10, 0.98, 0.18, 0.18, 0.24, 1.0)

    local headerIcon = topBar:CreateTexture(nil, "ARTWORK")
    headerIcon:SetSize(30, 30)
    headerIcon:SetPoint("LEFT", topBar, "LEFT", 14, 0)
    headerIcon:SetTexture(1386548)
    headerIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local logoTitle = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(logoTitle, 18)
    logoTitle:SetPoint("LEFT", headerIcon, "RIGHT", 10, 5)
    logoTitle:SetText("|cffa335eeSpArc|r")

    local verText = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(verText, 11)
    verText:SetPoint("TOPLEFT", logoTitle, "BOTTOMLEFT", 0, -1)
    verText:SetTextColor(0.55, 0.80, 1.0, 1)
    verText:SetText("v" .. tostring(SpArc.VERSION))

    local subTitle = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(subTitle, 12)
    subTitle:SetPoint("LEFT", topBar, "LEFT", 218, 0)
    subTitle:SetTextColor(0.80, 0.80, 0.88, 1)

    local closeBtn = CreateElvButton(topBar, 28, 26, "X")
    closeBtn:SetPoint("RIGHT", topBar, "RIGHT", -10, 0)
    closeBtn:SetScript("OnClick", function() controlFrame:Hide() end)

    local langBtn = CreateElvButton(topBar, 92, 26, "")
    langBtn:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)
    langBtn:SetScript("OnClick", function()
      local cur = SpArc:GetActiveLang()
      db.visual.lang = (cur == "RU") and "EN" or "RU"
      SpArc:ApplyVisualLayout()
      controlFrame:RefreshUI()
    end)

    local fixCursorTopBtn = CreateElvButton(topBar, 125, 26, "")
    fixCursorTopBtn:SetPoint("RIGHT", langBtn, "LEFT", -6, 0)
    fixCursorTopBtn:SetScript("OnClick", function()
      if SpArc.FlushHardwareCursor then
        SpArc:FlushHardwareCursor(true)
      end
      print(SpArc:L("MSG_CURSOR_FIXED"))
    end)

    local testHudTopBtn = CreateElvButton(topBar, 135, 26, "")
    testHudTopBtn:SetPoint("RIGHT", fixCursorTopBtn, "LEFT", -6, 0)
    testHudTopBtn:SetScript("OnClick", function()
      SpArc.testMode = not SpArc.testMode
      if SpArc.UpdateCameraState then SpArc:UpdateCameraState() end
      controlFrame:RefreshUI()
    end)

    subTitle:SetPoint("RIGHT", testHudTopBtn, "LEFT", -10, 0)
    subTitle:SetJustifyH("LEFT")
    subTitle:SetWordWrap(false)

    -- Left Sidebar (ElvUI Navigation Column)
    local sidebar = CreateFrame("Frame", nil, controlFrame, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", controlFrame, "TOPLEFT", 1, -50)
    sidebar:SetPoint("BOTTOMLEFT", controlFrame, "BOTTOMLEFT", 1, 1)
    sidebar:SetWidth(204)
    SetBackdropFlat(sidebar, 0.04, 0.04, 0.06, 0.98, 0.18, 0.18, 0.24, 1.0)

    local navKeys = { "NAV_1", "NAV_2", "NAV_3", "NAV_4", "NAV_5", "NAV_6", "NAV_7", "NAV_8" }
    local navButtons = {}
    local pages = {}
    local groupBoxes = {}
    local allSliders = {}
    local allChecks = {}

    local function SelectTab(idx)
      currentTabIdx = idx or 1
      if activeKeybindCapture and activeKeybindCapture.CancelCapture then
        activeKeybindCapture:CancelCapture()
      end
      for i = 1, #navButtons do
        if i == currentTabIdx then
          pages[i]:Show()
          navButtons[i]:SetSelected(true)
        else
          pages[i]:Hide()
          navButtons[i]:SetSelected(false)
        end
      end
      SpArc.previewCrosshairInConfig = (currentTabIdx == 6) and controlFrame:IsShown()
      if SpArc.UpdateCameraState then
        SpArc:UpdateCameraState()
      end
      if controlFrame.RefreshUI then
        controlFrame:RefreshUI()
      end
    end
    controlFrame.SelectTab = SelectTab

    for i, nKey in ipairs(navKeys) do
      local yPos = -12 - (i - 1) * 35
      if i >= 3 and i <= 6 then
        yPos = yPos - 6
      elseif i >= 7 then
        yPos = yPos - 14
      end
      local btn = CreateElvButton(sidebar, 184, 30, SpArc:L(nKey))
      btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 10, yPos)
      btn.fs:ClearAllPoints()
      btn.fs:SetPoint("LEFT", btn, "LEFT", 12, 0)
      btn.fs:SetJustifyH("LEFT")
      btn.nKey = nKey
      btn:SetScript("OnClick", function() SelectTab(i) end)
      navButtons[i] = btn

      local page = CreateFrame("Frame", nil, controlFrame)
      page:SetPoint("TOPLEFT", controlFrame, "TOPLEFT", 220, -64)
      page:SetPoint("BOTTOMRIGHT", controlFrame, "BOTTOMRIGHT", -16, 16)
      page:Hide()
      pages[i] = page
    end

    -- Sidebar Divider & Bottom Minimap Checkbox
    local sideDiv = sidebar:CreateTexture(nil, "ARTWORK")
    sideDiv:SetHeight(1)
    sideDiv:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 12, 54)
    sideDiv:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -12, 54)
    sideDiv:SetColorTexture(0.22, 0.22, 0.30, 1)

    local function RegisterGroupBox(parent, titleKey, x, y, w, h)
      local c, b = CreateElvGroupBox(parent, titleKey, x, y, w, h)
      groupBoxes[#groupBoxes + 1] = c
      return b
    end

    local function CreateElvCheck(parent, labelKey, dbKey, x, y, isMasterEnable, isTestToggle, onAfterClick)
      local btn = CreateFrame("Button", nil, parent)
      btn:SetSize(560, 24)
      btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

      local box = CreateFrame("Frame", nil, btn, "BackdropTemplate")
      box:SetSize(18, 18)
      box:SetPoint("LEFT", btn, "LEFT", 0, 0)
      SetBackdropFlat(box, 0.04, 0.04, 0.06, 1.0, 0.32, 0.32, 0.42, 1.0)

      local fill = box:CreateTexture(nil, "ARTWORK")
      fill:SetPoint("TOPLEFT", box, "TOPLEFT", 3, -3)
      fill:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -3, 3)
      if isMasterEnable then
        fill:SetColorTexture(0.18, 0.86, 0.32, 1.0)
      else
        fill:SetColorTexture(0.24, 0.58, 0.96, 1.0)
      end
      btn.fill = fill

      local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      ApplyCyrFont(txt, isMasterEnable and 13 or 12)
      txt:SetPoint("LEFT", box, "RIGHT", 8, 0)
      txt:SetJustifyH("LEFT")
      btn.txt = txt

      btn.labelKey = labelKey
      btn.key = dbKey
      btn.isMasterEnable = isMasterEnable
      btn.isTestToggle = isTestToggle

      function btn:UpdateVisual(checked)
        self._checked = checked and true or false
        if self._checked then
          self.fill:Show()
          if self.isMasterEnable then
            self.txt:SetTextColor(0.22, 0.95, 0.38, 1)
          else
            self.txt:SetTextColor(0.94, 0.94, 0.98, 1)
          end
        else
          self.fill:Hide()
          if self.isMasterEnable then
            self.txt:SetTextColor(0.95, 0.32, 0.32, 1)
          else
            self.txt:SetTextColor(0.62, 0.62, 0.70, 1)
          end
        end
      end

      btn:SetScript("OnClick", function(self)
        local newVal = not self._checked
        if self.isTestToggle then
          SpArc.testMode = newVal
        else
          db.visual[self.key] = newVal
        end
        self:UpdateVisual(newVal)
        SpArc:ApplyVisualLayout()
        if onAfterClick then onAfterClick(newVal) end
        if controlFrame.RefreshUI then controlFrame:RefreshUI() end
      end)

      allChecks[#allChecks + 1] = btn
      return btn
    end

    local mmCheck = CreateElvCheck(sidebar, "CK_MINIMAP", "showMinimapButton", 12, -528, false, false, function()
      if SpArc.UpdateMinimapButtonVisibility then SpArc:UpdateMinimapButtonVisibility() end
    end)
    mmCheck:SetWidth(180)
    mmCheck.txt:SetWidth(155)
    mmCheck.txt:SetWordWrap(true)

    local function CreateElvSlider(parent, labelKey, dbKey, minV, maxV, stepV, x, y, width, onAfterChange)
      local sWidth = width or 280
      local holder = CreateFrame("Frame", nil, parent)
      holder:SetSize(sWidth, 56)
      holder:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

      local title = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      ApplyCyrFont(title, 12)
      title:SetPoint("TOP", holder, "TOP", 0, 0)
      title:SetTextColor(1.0, 0.82, 0.18, 1)
      holder.title = title

      local slider = CreateFrame("Slider", nil, holder, "BackdropTemplate")
      slider:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -18)
      slider:SetSize(sWidth, 12)
      slider:SetOrientation("HORIZONTAL")
      slider:SetMinMaxValues(minV, maxV)
      slider:SetValueStep(stepV)
      slider:SetObeyStepOnDrag(true)
      SetBackdropFlat(slider, 0.04, 0.04, 0.06, 1.0, 0.26, 0.26, 0.34, 1.0)

      local fillBar = slider:CreateTexture(nil, "ARTWORK")
      fillBar:SetPoint("TOPLEFT", slider, "TOPLEFT", 1, -1)
      fillBar:SetPoint("BOTTOMLEFT", slider, "BOTTOMLEFT", 1, 1)
      fillBar:SetWidth(1)
      fillBar:SetColorTexture(0.20, 0.48, 0.82, 0.85)
      slider.fillBar = fillBar

      local thumb = slider:CreateTexture(nil, "OVERLAY")
      thumb:SetSize(10, 16)
      thumb:SetColorTexture(0.45, 0.78, 1.0, 1.0)
      slider:SetThumbTexture(thumb)

      local minTxt = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      ApplyCyrFont(minTxt, 10)
      minTxt:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -4)
      minTxt:SetTextColor(0.65, 0.65, 0.72, 1)
      minTxt:SetText(tostring(minV))

      local maxTxt = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      ApplyCyrFont(maxTxt, 10)
      maxTxt:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -4)
      maxTxt:SetTextColor(0.65, 0.65, 0.72, 1)
      maxTxt:SetText(tostring(maxV))

      local valBox = CreateFrame("Frame", nil, holder, "BackdropTemplate")
      valBox:SetSize(68, 18)
      valBox:SetPoint("TOP", slider, "BOTTOM", 0, -2)
      SetBackdropFlat(valBox, 0.04, 0.04, 0.06, 1.0, 0.24, 0.24, 0.32, 1.0)

      local valTxt = valBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      ApplyCyrFont(valTxt, 11)
      valTxt:SetPoint("CENTER", valBox, "CENTER", 0, 0)
      valTxt:SetTextColor(0.95, 0.95, 1.0, 1)
      holder.valTxt = valTxt

      local function FormatVal(v)
        if stepV >= 1 then
          return string.format("%d", math.floor(v + 0.5))
        end
        return string.format("%.2f", v)
      end

      local function UpdateFill(v)
        local pct = (v - minV) / math.max(0.0001, (maxV - minV))
        pct = math.max(0, math.min(1, pct))
        fillBar:SetWidth(math.max(1, (sWidth - 2) * pct))
      end

      slider:SetScript("OnValueChanged", function(_, val)
        local rounded = math.floor((val / stepV) + 0.5) * stepV
        valTxt:SetText(FormatVal(rounded))
        UpdateFill(rounded)
        if isRefreshingUI then return end
        if db.visual[dbKey] == rounded then return end
        db.visual[dbKey] = rounded
        SpArc:ApplyVisualLayout()
        if SpArc.ApplyCameraCrosshairLayout then
          SpArc:ApplyCameraCrosshairLayout()
        end
        if onAfterChange then
          onAfterChange(rounded)
        end
      end)

      holder.slider = slider
      holder.labelKey = labelKey
      holder.key = dbKey
      holder.FormatVal = FormatVal
      holder.UpdateFill = UpdateFill
      allSliders[#allSliders + 1] = holder
      return holder
    end

    -----------------------------------------------------------------------------------
    -- MODULE 1: ROTATION PRESETS (55)
    -----------------------------------------------------------------------------------
    local p1 = pages[1]
    local p1Summary = p1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(p1Summary, 13)
    p1Summary:SetPoint("TOPLEFT", 0, 0)
    p1Summary:SetJustifyH("LEFT")

    local filterBtn = CreateElvButton(p1, 210, 26, "")
    filterBtn:SetPoint("TOPLEFT", 0, -26)
    filterBtn:SetScript("OnClick", function()
      filterClassOnly = not filterClassOnly
      controlFrame:RefreshUI()
    end)

    local autoModeBtn = CreateElvButton(p1, 210, 26, "")
    autoModeBtn:SetPoint("LEFT", filterBtn, "RIGHT", 8, 0)
    autoModeBtn:SetScript("OnClick", function()
      db.mode = (db.mode == "AUTO") and "MANUAL" or "AUTO"
      controlFrame:RefreshUI()
    end)

    local newPresetBtn = CreateElvButton(p1, 160, 26, "")
    newPresetBtn:SetPoint("LEFT", autoModeBtn, "RIGHT", 8, 0)
    newPresetBtn:SetScript("OnClick", function()
      local newIdx = #db.presetOrder + 1
      local cls = GetPlayerClassTag()
      local newID = string.format("%s_CUSTOM_%d", cls, newIdx)
      local newTitle = string.format(SpArc:L("NEW_PRESET_TITLE"), newIdx, cls, newIdx)
      local baseMD = (db.presets[selectedPresetForEdit] and db.presets[selectedPresetForEdit].md) or SpArc.DefaultMarkdownProfiles["PVE"]
      db.presetOrder[#db.presetOrder + 1] = newID
      db.presets[newID] = { id = newID, class = cls, title = newTitle, mode = "PVE", md = baseMD }
      selectedPresetForEdit = newID
      db.activePresetID = newID
      db.mode = "MANUAL"
      SpArc:RebuildParsedProfiles()
      controlFrame:RefreshUI()
    end)

    local listBoxFrame = CreateFrame("Frame", nil, p1, "BackdropTemplate")
    listBoxFrame:SetPoint("TOPLEFT", 0, -60)
    listBoxFrame:SetSize(330, 468)
    SetBackdropFlat(listBoxFrame, 0.07, 0.07, 0.10, 0.95, 0.20, 0.20, 0.27, 1.0)

    local listScroll = CreateFrame("ScrollFrame", "SpArcPresetListScroll", listBoxFrame, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", 4, -4)
    listScroll:SetPoint("BOTTOMRIGHT", -26, 4)

    local listContent = CreateFrame("Frame", nil, listScroll)
    listContent:SetSize(296, 1500)
    listScroll:SetScrollChild(listContent)

    local rowButtons = {}
    for idx = 1, 65 do
      local rBtn = CreateElvButton(listContent, 294, 24, "")
      rBtn:SetPoint("TOPLEFT", 0, -(idx - 1) * 26)
      rBtn.fs:ClearAllPoints()
      rBtn.fs:SetPoint("LEFT", rBtn, "LEFT", 8, 0)
      rBtn.fs:SetPoint("RIGHT", rBtn, "RIGHT", -6, 0)
      rBtn.fs:SetJustifyH("LEFT")
      rBtn.fs:SetWordWrap(false)
      rBtn:Hide()
      rowButtons[idx] = rBtn
    end

    local detailsBox = CreateFrame("Frame", nil, p1, "BackdropTemplate")
    detailsBox:SetPoint("TOPLEFT", 342, -60)
    detailsBox:SetPoint("BOTTOMRIGHT", 0, 0)
    SetBackdropFlat(detailsBox, 0.08, 0.08, 0.11, 0.95, 0.20, 0.20, 0.27, 1.0)

    local detailsText = detailsBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(detailsText, 12)
    detailsText:SetPoint("TOPLEFT", 14, -14)
    detailsText:SetPoint("TOPRIGHT", -14, -14)
    detailsText:SetJustifyH("LEFT")
    detailsText:SetJustifyV("TOP")
    detailsText:SetSpacing(3)

    local activateBtn = CreateElvButton(detailsBox, 270, 28, "")
    activateBtn:SetPoint("BOTTOM", 0, 82)
    activateBtn:SetScript("OnClick", function()
      if selectedPresetForEdit and db.presets[selectedPresetForEdit] then
        db.activePresetID = selectedPresetForEdit
        db.mode = "MANUAL"
        SpArc:SelectActiveParsedProfile()
        controlFrame:RefreshUI()
        print(string.format(SpArc:L("MSG_ACTIVATED"), SpArc:GetPresetDisplayTitle(db.presets[selectedPresetForEdit])))
      end
    end)

    local openMdBtn = CreateElvButton(detailsBox, 270, 28, "")
    openMdBtn:SetPoint("BOTTOM", 0, 48)
    openMdBtn:SetScript("OnClick", function()
      showingAIPrompt = false
      SelectTab(2)
    end)

    local testModeBtn1 = CreateElvButton(detailsBox, 270, 28, "")
    testModeBtn1:SetPoint("BOTTOM", 0, 14)
    testModeBtn1:SetScript("OnClick", function()
      SpArc.testMode = not SpArc.testMode
      controlFrame:RefreshUI()
    end)

    -----------------------------------------------------------------------------------
    -- MODULE 2: .MD PSEUDOCODE EDITOR & AI PROMPT GENERATOR
    -----------------------------------------------------------------------------------
    local p2 = pages[2]
    local aiBanner = CreateFrame("Frame", nil, p2, "BackdropTemplate")
    aiBanner:SetPoint("TOPLEFT", 0, 0)
    aiBanner:SetPoint("TOPRIGHT", 0, 0)
    aiBanner:SetHeight(48)
    SetBackdropFlat(aiBanner, 0.09, 0.08, 0.14, 0.96, 0.35, 0.24, 0.55, 1.0)

    local aiText = aiBanner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(aiText, 12)
    aiText:SetPoint("TOPLEFT", 12, -8)
    aiText:SetPoint("BOTTOMRIGHT", -195, 8)
    aiText:SetJustifyH("LEFT")
    aiText:SetTextColor(1, 0.88, 0.30, 1)

    local aiPromptBtn = CreateElvButton(aiBanner, 175, 28, "")
    aiPromptBtn:SetPoint("RIGHT", -10, 0)

    local editorStatus = p2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(editorStatus, 12)
    editorStatus:SetPoint("TOPLEFT", 0, -56)

    local editorBoxFrame = CreateFrame("Frame", nil, p2, "BackdropTemplate")
    editorBoxFrame:SetPoint("TOPLEFT", 0, -78)
    editorBoxFrame:SetPoint("BOTTOMRIGHT", 0, 40)
    SetBackdropFlat(editorBoxFrame, 0.04, 0.04, 0.06, 0.98, 0.22, 0.22, 0.30, 1.0)

    local mdScroll = CreateFrame("ScrollFrame", "SpArcMDEditorScroll", editorBoxFrame, "UIPanelScrollFrameTemplate")
    mdScroll:SetPoint("TOPLEFT", 8, -8)
    mdScroll:SetPoint("BOTTOMRIGHT", -28, 8)

    local editBox = CreateFrame("EditBox", nil, mdScroll)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    ApplyCyrFont(editBox, 12)
    editBox:SetWidth(590)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)
    mdScroll:SetScrollChild(editBox)

    local saveMdBtn = CreateElvButton(p2, 230, 30, "")
    saveMdBtn:SetPoint("BOTTOMLEFT", 0, 2)
    saveMdBtn:SetScript("OnClick", function()
      if showingAIPrompt then return end
      local txt = editBox:GetText() or ""
      if selectedPresetForEdit and db.presets[selectedPresetForEdit] then
        db.presets[selectedPresetForEdit].md = txt
        local compiled = SpArc:ParseMarkdownFSM(txt)
        SpArc.ParsedPresets[selectedPresetForEdit] = compiled
        if compiled.title and compiled.title ~= "" then
          db.presets[selectedPresetForEdit].title = compiled.title
        end
        if compiled.class and compiled.class ~= "" then
          db.presets[selectedPresetForEdit].class = compiled.class
        end
        if compiled.mode and compiled.mode ~= "" then
          db.presets[selectedPresetForEdit].mode = compiled.mode
        end
        db.activePresetID = selectedPresetForEdit
        SpArc:SelectActiveParsedProfile()
        SpArc:ScanActionSlotsAndSpells(true)
        controlFrame:RefreshUI()
        print(string.format(SpArc:L("MSG_MD_SAVED"), SpArc:GetPresetDisplayTitle(db.presets[selectedPresetForEdit])))
      end
    end)

    local resetMdBtn = CreateElvButton(p2, 210, 30, "")
    resetMdBtn:SetPoint("LEFT", saveMdBtn, "RIGHT", 10, 0)
    resetMdBtn:SetScript("OnClick", function()
      showingAIPrompt = false
      local bp = SpArc.BuiltInPresets and SpArc.BuiltInPresets[selectedPresetForEdit]
      if bp and db.presets[selectedPresetForEdit] then
        db.presets[selectedPresetForEdit].md = bp.md
        db.presets[selectedPresetForEdit].title = bp.title
        SpArc:RebuildParsedProfiles()
        SpArc:SelectActiveParsedProfile()
        controlFrame:RefreshUI()
      end
    end)

    aiPromptBtn:SetScript("OnClick", function()
      showingAIPrompt = not showingAIPrompt
      controlFrame:RefreshUI()
      if showingAIPrompt then
        editBox:SetFocus()
        editBox:HighlightText()
      end
    end)

    -----------------------------------------------------------------------------------
    -- MODULE 3: ROTATION ARC (ДУГА РОТАЦИИ)
    -----------------------------------------------------------------------------------
    local p3 = pages[3]
    local m3Title = p3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(m3Title, 15)
    m3Title:SetPoint("TOPLEFT", 0, 0)
    m3Title:SetTextColor(1, 0.85, 0.25, 1)

    CreateElvCheck(p3, "MOD_ENABLE", "enableArcHUD", 0, -24, true, false)

    local m3GeoBox = RegisterGroupBox(p3, "M3_GRP_GEO", 0, -56, 640, 162)
    CreateElvSlider(m3GeoBox, "SL_ARC_RADIUS", "arcRadius", 50, 260, 5, 18, -14, 280)
    CreateElvSlider(m3GeoBox, "SL_ARC_SPREAD", "arcSpreadDeg", 60, 180, 5, 336, -14, 280)
    CreateElvSlider(m3GeoBox, "SL_ARC_OFFSET_Y", "arcOffsetY", -120, 180, 5, 18, -76, 280)

    local m3IconsBox = RegisterGroupBox(p3, "M3_GRP_ICONS", 0, -230, 640, 162)
    CreateElvSlider(m3IconsBox, "SL_PRIMARY_SCALE", "primaryScale", 1.0, 2.0, 0.05, 18, -14, 280)
    CreateElvSlider(m3IconsBox, "SL_QUEUE_SCALE", "queueScale", 0.6, 1.4, 0.05, 336, -14, 280)
    CreateElvSlider(m3IconsBox, "SL_QUEUE_LEN", "queueLength", 3, 6, 1, 18, -76, 280)

    local m3FbBox = RegisterGroupBox(p3, "M3_GRP_FEEDBACK", 0, -404, 640, 96)
    CreateElvCheck(m3FbBox, "CK_PRESS_FEEDBACK", "enablePressFeedback", 14, -12, false, false)
    CreateElvCheck(m3FbBox, "CK_TEST_MODE", "testMode", 14, -40, false, true)

    -----------------------------------------------------------------------------------
    -- MODULE 4: SAVES & CDS WINGS (КРЫЛЬЯ СЕЙВОВ И КД)
    -----------------------------------------------------------------------------------
    local p4 = pages[4]
    local m4Title = p4:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(m4Title, 15)
    m4Title:SetPoint("TOPLEFT", 0, 0)
    m4Title:SetTextColor(1, 0.85, 0.25, 1)

    local cSavesMaster = CreateElvCheck(p4, "MOD_ENABLE_SAVES", "showSavesWing", 0, -24, true, false)
    cSavesMaster:SetWidth(290)
    local cCDsMaster = CreateElvCheck(p4, "MOD_ENABLE_CDS", "showCDsWing", 310, -24, true, false)
    cCDsMaster:SetWidth(310)

    local m4PosBox = RegisterGroupBox(p4, "M4_GRP_POS", 0, -58, 640, 130)
    CreateElvSlider(m4PosBox, "SL_WINGS_Y", "wingsOffsetY", -200, 60, 5, 18, -16, 280)
    CreateElvCheck(m4PosBox, "CK_ALWAYS_CDS", "alwaysShowCDs", 18, -76, false, false)

    local m4EmergBox = RegisterGroupBox(p4, "M4_GRP_EMERG", 0, -204, 640, 130)
    CreateElvCheck(m4EmergBox, "CK_EMERG_SAVE", "showEmergencySave", 18, -14, false, false)
    CreateElvSlider(m4EmergBox, "SL_EMERG_HP", "emergencyHP", 15, 50, 5, 18, -46, 280)

    -----------------------------------------------------------------------------------
    -- MODULE 5: DUAL CASTBAR (ДВОЙНОЙ КАСТБАР)
    -----------------------------------------------------------------------------------
    local p5 = pages[5]
    local m5Title = p5:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(m5Title, 15)
    m5Title:SetPoint("TOPLEFT", 0, 0)
    m5Title:SetTextColor(1, 0.85, 0.25, 1)

    CreateElvCheck(p5, "MOD_ENABLE", "showCastbar", 0, -24, true, false)

    local m5SizeBox = RegisterGroupBox(p5, "M5_GRP_SIZE", 0, -58, 640, 105)
    CreateElvSlider(m5SizeBox, "SL_CB_WIDTH", "castbarWidth", 180, 420, 4, 18, -16, 280)
    CreateElvSlider(m5SizeBox, "SL_CB_OFFSET_Y", "castbarOffsetY", -240, -40, 5, 336, -16, 280)

    local m5ClipBox = RegisterGroupBox(p5, "M5_GRP_CLIP", 0, -180, 640, 75)
    CreateElvCheck(m5ClipBox, "CK_INTERRUPT", "showInterruptAlert", 18, -14, false, false)

    -----------------------------------------------------------------------------------
    -- MODULE 6: COMBAT CAMERA (БОЕВАЯ КАМЕРА)
    -----------------------------------------------------------------------------------
    local p6 = pages[6]
    local m6Title = p6:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(m6Title, 15)
    m6Title:SetPoint("TOPLEFT", 0, 0)
    m6Title:SetTextColor(1, 0.85, 0.25, 1)

    CreateElvCheck(p6, "MOD_ENABLE", "enableCombatCamera", 0, -24, true, false, function()
      if SpArc.ApplyCombatCameraBindings then SpArc:ApplyCombatCameraBindings() end
      if SpArc.UpdateCameraState then SpArc:UpdateCameraState() end
    end)

    local m6KeysBox = RegisterGroupBox(p6, "M6_GRP_KEYS", 0, -58, 640, 180)

    -- Interactive Keybind Capture Overlay
    local captureFrame = CreateFrame("Button", "SpArcKeyCaptureOverlay", controlFrame)
    captureFrame:SetAllPoints(controlFrame)
    captureFrame:SetFrameLevel(controlFrame:GetFrameLevel() + 50)
    captureFrame:EnableKeyboard(true)
    captureFrame:EnableMouse(true)
    captureFrame:RegisterForClicks("AnyDown")
    captureFrame:Hide()

    local IGNORED_MODIFIERS = {
      LSHIFT = true, RSHIFT = true, SHIFT = true,
      LCTRL = true, RCTRL = true, CTRL = true,
      LALT = true, RALT = true, ALT = true,
      UNKNOWN = true,
    }

    local function BuildCapturedBindString(rawKey)
      if not rawKey or rawKey == "" then return nil end
      local prefix = ""
      if IsShiftKeyDown and IsShiftKeyDown() then prefix = prefix .. "SHIFT-" end
      if IsControlKeyDown and IsControlKeyDown() then prefix = prefix .. "CTRL-" end
      if IsAltKeyDown and IsAltKeyDown() then prefix = prefix .. "ALT-" end
      return prefix .. rawKey:upper()
    end

    function captureFrame:CancelCapture()
      self:Hide()
      activeKeybindCapture = nil
      if controlFrame and controlFrame.RefreshUI then
        controlFrame:RefreshUI()
      end
    end

    captureFrame:SetScript("OnKeyDown", function(self, key)
      if key == "ESCAPE" then
        self:CancelCapture()
        return
      end
      if key == "BACKSPACE" or key == "DELETE" then
        if self.targetDBKey then
          if SpArc.RecordManualCameraBind then
            SpArc:RecordManualCameraBind(self.targetDBKey, "")
          else
            db.visual[self.targetDBKey] = ""
          end
          if SpArc.ApplyCombatCameraBindings then SpArc:ApplyCombatCameraBindings("MANUAL_UNBIND") end
        end
        self:CancelCapture()
        return
      end
      if IGNORED_MODIFIERS[key] then
        return
      end
      local bindStr = BuildCapturedBindString(key)
      if bindStr and self.targetDBKey then
        if SpArc.RecordManualCameraBind then
          SpArc:RecordManualCameraBind(self.targetDBKey, bindStr)
        else
          db.visual[self.targetDBKey] = bindStr
        end
        if SpArc.ApplyCombatCameraBindings then SpArc:ApplyCombatCameraBindings("MANUAL_BIND") end
      end
      self:CancelCapture()
    end)

    captureFrame:SetScript("OnMouseDown", function(self, mouseBtn)
      if mouseBtn == "LeftButton" or mouseBtn == "RightButton" then
        self:CancelCapture()
        return
      end
      local mapped = nil
      if mouseBtn == "MiddleButton" then mapped = "BUTTON3"
      elseif mouseBtn == "Button4" then mapped = "BUTTON4"
      elseif mouseBtn == "Button5" then mapped = "BUTTON5"
      end
      if mapped and self.targetDBKey then
        local bindStr = BuildCapturedBindString(mapped)
        if SpArc.RecordManualCameraBind then
          SpArc:RecordManualCameraBind(self.targetDBKey, bindStr)
        else
          db.visual[self.targetDBKey] = bindStr
        end
        if SpArc.ApplyCombatCameraBindings then SpArc:ApplyCombatCameraBindings("MANUAL_BIND") end
      end
      self:CancelCapture()
    end)

    local keybindRows = {}
    local function CreateKeybindCaptureRow(parent, labelKey, dbKey, defaultVal, y)
      local row = CreateFrame("Frame", nil, parent)
      row:SetSize(610, 30)
      row:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)

      local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      ApplyCyrFont(lbl, 12)
      lbl:SetPoint("LEFT", row, "LEFT", 0, 0)
      lbl:SetTextColor(0.92, 0.92, 0.96, 1)
      row.lbl = lbl
      row.labelKey = labelKey
      row.dbKey = dbKey
      row.defaultVal = defaultVal

      local bindBtn = CreateElvButton(row, 138, 26, "")
      bindBtn:SetPoint("LEFT", row, "LEFT", 282, 0)
      row.bindBtn = bindBtn

      local unbindBtn = CreateElvButton(row, 82, 26, "")
      unbindBtn:SetPoint("LEFT", bindBtn, "RIGHT", 6, 0)
      row.unbindBtn = unbindBtn

      local resetBtn = CreateElvButton(row, 95, 26, "")
      resetBtn:SetPoint("LEFT", unbindBtn, "RIGHT", 6, 0)
      row.resetBtn = resetBtn

      bindBtn:SetScript("OnClick", function()
        activeKeybindCapture = captureFrame
        captureFrame.targetDBKey = dbKey
        captureFrame:Show()
        bindBtn:SetSelected(true)
        bindBtn:SetText("|cff00ffcc" .. SpArc:L("M6_BIND_WAIT") .. "|r")
      end)

      unbindBtn:SetScript("OnClick", function()
        if SpArc.RecordManualCameraBind then
          SpArc:RecordManualCameraBind(dbKey, "")
        else
          db.visual[dbKey] = ""
        end
        if SpArc.ApplyCombatCameraBindings then SpArc:ApplyCombatCameraBindings("MANUAL_UNBIND") end
        controlFrame:RefreshUI()
      end)

      resetBtn:SetScript("OnClick", function()
        local def = (defaultVal == "AUTO") and SpArc:GetGameInteractKey() or defaultVal
        if SpArc.RecordManualCameraBind then
          SpArc:RecordManualCameraBind(dbKey, def)
          if dbKey == "camInteractKey" then
            db.visual.camInteractKeyUserSet = false
          else
            db.visual[dbKey .. "UserSet"] = false
          end
        else
          db.visual[dbKey] = def
        end
        if SpArc.ApplyCombatCameraBindings then SpArc:ApplyCombatCameraBindings("MANUAL_RESET") end
        controlFrame:RefreshUI()
      end)

      keybindRows[#keybindRows + 1] = row
      return row
    end

    CreateKeybindCaptureRow(m6KeysBox, "M6_HOLD_LABEL", "camHoldKey", "G", -10)
    CreateKeybindCaptureRow(m6KeysBox, "M6_TOGGLE_LABEL", "camToggleKey", "`", -44)
    CreateKeybindCaptureRow(m6KeysBox, "M6_INTERACT_LABEL", "camInteractKey", "AUTO", -78)

    local m6FixCursorBtn = CreateElvButton(m6KeysBox, 360, 26, "")
    m6FixCursorBtn:SetPoint("TOPLEFT", m6KeysBox, "TOPLEFT", 16, -118)
    m6FixCursorBtn:SetScript("OnClick", function()
      if SpArc.FlushHardwareCursor then
        SpArc:FlushHardwareCursor(true)
      end
      print(SpArc:L("MSG_CURSOR_FIXED"))
    end)

    local m6CrossBox = RegisterGroupBox(p6, "M6_GRP_CROSS", 0, -252, 640, 135)
    CreateElvCheck(m6CrossBox, "CK_CAM_CROSSHAIR", "showCameraCrosshair", 16, -12, false, false, function()
      if SpArc.ApplyCameraCrosshairLayout then SpArc:ApplyCameraCrosshairLayout() end
      if SpArc.UpdateCameraState then SpArc:UpdateCameraState() end
    end)
    CreateElvSlider(m6CrossBox, "SL_CAM_CROSS_Y", "camCrosshairOffsetY", -200, 250, 2, 16, -46, 280)
    CreateElvSlider(m6CrossBox, "SL_CAM_CROSS_SCALE", "camCrosshairScale", 0.50, 2.50, 0.05, 336, -46, 280)

    local m6ClickBox = RegisterGroupBox(p6, "M6_GRP_CLICK", 0, -402, 640, 75)
    CreateElvCheck(m6ClickBox, "CK_CAM_CLICKCAST", "enableCamClickCast", 16, -14, false, false, function()
      if SpArc.ApplyCombatCameraBindings then SpArc:ApplyCombatCameraBindings() end
      SpArc:ScanActionSlotsAndSpells(true)
    end)

    -----------------------------------------------------------------------------------
    -- MODULE 7: TELEMETRY & DEBUGGER (ТЕЛЕМЕТРИЯ И ДЕБАГ)
    -----------------------------------------------------------------------------------
    local p7 = pages[7]
    local m7Title = p7:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(m7Title, 15)
    m7Title:SetPoint("TOPLEFT", 0, 0)
    m7Title:SetTextColor(1, 0.85, 0.25, 1)

    CreateElvCheck(p7, "MOD_ENABLE", "enableTelemetry", 0, -24, true, false)

    local snapBtn = CreateElvButton(p7, 195, 26, "")
    snapBtn:SetPoint("TOPLEFT", 0, -54)

    local copyTelBtn = CreateElvButton(p7, 180, 26, "")
    copyTelBtn:SetPoint("LEFT", snapBtn, "RIGHT", 8, 0)

    local clearTelBtn = CreateElvButton(p7, 195, 26, "")
    clearTelBtn:SetPoint("LEFT", copyTelBtn, "RIGHT", 8, 0)

    local telBoxFrame = CreateFrame("Frame", nil, p7, "BackdropTemplate")
    telBoxFrame:SetPoint("TOPLEFT", 0, -88)
    telBoxFrame:SetPoint("BOTTOMRIGHT", 0, 0)
    SetBackdropFlat(telBoxFrame, 0.04, 0.04, 0.06, 0.98, 0.22, 0.22, 0.30, 1.0)

    local telScroll = CreateFrame("ScrollFrame", "SpArcTelemetryScroll", telBoxFrame, "UIPanelScrollFrameTemplate")
    telScroll:SetPoint("TOPLEFT", 8, -8)
    telScroll:SetPoint("BOTTOMRIGHT", -28, 8)

    local telEditBox = CreateFrame("EditBox", nil, telScroll)
    telEditBox:SetMultiLine(true)
    telEditBox:SetFontObject("ChatFontNormal")
    ApplyCyrFont(telEditBox, 11)
    telEditBox:SetWidth(590)
    telEditBox:SetAutoFocus(false)
    telEditBox:SetScript("OnEscapePressed", function() telEditBox:ClearFocus() end)
    telScroll:SetScrollChild(telEditBox)

    snapBtn:SetScript("OnClick", function()
      pcall(SpArc.CaptureTelemetrySnapshot, SpArc, "MANUAL_SNAPSHOT")
      controlFrame:RefreshUI()
    end)
    copyTelBtn:SetScript("OnClick", function()
      telEditBox:SetFocus()
      telEditBox:HighlightText()
    end)
    clearTelBtn:SetScript("OnClick", function()
      db.telemetryLog = {}
      db.capturedLuaErrors = {}
      if _G.BugSack and type(_G.BugSack.Reset) == "function" then
        pcall(_G.BugSack.Reset, _G.BugSack)
      elseif _G.BugGrabber and type(_G.BugGrabber.Reset) == "function" then
        pcall(_G.BugGrabber.Reset, _G.BugGrabber)
      end
      controlFrame:RefreshUI()
    end)

    -----------------------------------------------------------------------------------
    -- MODULE 8: CHARACTER PROFILES (ПРОФИЛИ ПЕРСОНАЖЕЙ)
    -----------------------------------------------------------------------------------
    local p8 = pages[8]
    local selectedProfileForOps = SpArc:GetActiveProfileName()

    local m8Title = p8:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(m8Title, 15)
    m8Title:SetPoint("TOPLEFT", 0, 0)
    m8Title:SetTextColor(1, 0.85, 0.25, 1)

    local m8CurBox = RegisterGroupBox(p8, "M8_GRP_CUR", 0, -34, 640, 102)
    local m8CurSummary = m8CurBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(m8CurSummary, 12)
    m8CurSummary:SetPoint("TOPLEFT", 16, -12)
    m8CurSummary:SetPoint("TOPRIGHT", -16, -12)
    m8CurSummary:SetJustifyH("LEFT")
    m8CurSummary:SetSpacing(4)

    local m8CharProfBtn = CreateElvButton(m8CurBox, 198, 26, "")
    m8CharProfBtn:SetPoint("BOTTOMLEFT", 16, 12)
    m8CharProfBtn:SetScript("OnClick", function()
      local charProf = SpArc:GetCurrentCharKey()
      SpArc:SetProfile(charProf)
      selectedProfileForOps = charProf
      print(string.format(SpArc:L("MSG_PROF_SWITCHED"), charProf))
      controlFrame:RefreshUI()
    end)

    local m8DefProfBtn = CreateElvButton(m8CurBox, 198, 26, "")
    m8DefProfBtn:SetPoint("LEFT", m8CharProfBtn, "RIGHT", 8, 0)
    m8DefProfBtn:SetScript("OnClick", function()
      SpArc:SetProfile("Default")
      selectedProfileForOps = "Default"
      print(string.format(SpArc:L("MSG_PROF_SWITCHED"), "Default"))
      controlFrame:RefreshUI()
    end)

    local m8ResetProfBtn = CreateElvButton(m8CurBox, 198, 26, "")
    m8ResetProfBtn:SetPoint("LEFT", m8DefProfBtn, "RIGHT", 8, 0)
    m8ResetProfBtn:SetScript("OnClick", function()
      local curProf = SpArc:GetActiveProfileName()
      SpArc:ResetCurrentProfile()
      print(string.format(SpArc:L("MSG_PROF_RESET"), curProf))
      controlFrame:RefreshUI()
    end)

    local m8ListBox = RegisterGroupBox(p8, "M8_GRP_LIST", 0, -152, 640, 366)

    local profListFrame = CreateFrame("Frame", nil, m8ListBox, "BackdropTemplate")
    profListFrame:SetPoint("TOPLEFT", 14, -14)
    profListFrame:SetSize(270, 338)
    SetBackdropFlat(profListFrame, 0.05, 0.05, 0.07, 0.96, 0.20, 0.20, 0.27, 1.0)

    local profScroll = CreateFrame("ScrollFrame", "SpArcProfileListScroll", profListFrame, "UIPanelScrollFrameTemplate")
    profScroll:SetPoint("TOPLEFT", 4, -4)
    profScroll:SetPoint("BOTTOMRIGHT", -26, 4)

    local profListContent = CreateFrame("Frame", nil, profScroll)
    profListContent:SetSize(236, 600)
    profScroll:SetScrollChild(profListContent)

    local profRowButtons = {}
    for idx = 1, 24 do
      local prBtn = CreateElvButton(profListContent, 234, 26, "")
      prBtn:SetPoint("TOPLEFT", 0, -(idx - 1) * 28)
      prBtn.fs:ClearAllPoints()
      prBtn.fs:SetPoint("LEFT", prBtn, "LEFT", 8, 0)
      prBtn.fs:SetPoint("RIGHT", prBtn, "RIGHT", -6, 0)
      prBtn.fs:SetJustifyH("LEFT")
      prBtn.fs:SetWordWrap(false)
      prBtn:Hide()
      profRowButtons[idx] = prBtn
    end

    local profDetailsBox = CreateFrame("Frame", nil, m8ListBox, "BackdropTemplate")
    profDetailsBox:SetPoint("TOPLEFT", 296, -14)
    profDetailsBox:SetPoint("BOTTOMRIGHT", -14, 14)
    SetBackdropFlat(profDetailsBox, 0.06, 0.06, 0.09, 0.96, 0.20, 0.20, 0.27, 1.0)

    local profDetailsText = profDetailsBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(profDetailsText, 12)
    profDetailsText:SetPoint("TOPLEFT", 14, -14)
    profDetailsText:SetPoint("TOPRIGHT", -14, -14)
    profDetailsText:SetJustifyH("LEFT")
    profDetailsText:SetJustifyV("TOP")
    profDetailsText:SetSpacing(3)

    local m8ActivateBtn = CreateElvButton(profDetailsBox, 300, 28, "")
    m8ActivateBtn:SetPoint("BOTTOM", 0, 82)
    m8ActivateBtn:SetScript("OnClick", function()
      if selectedProfileForOps and selectedProfileForOps ~= "" then
        SpArc:SetProfile(selectedProfileForOps)
        print(string.format(SpArc:L("MSG_PROF_SWITCHED"), selectedProfileForOps))
        controlFrame:RefreshUI()
      end
    end)

    local m8CopyBtn = CreateElvButton(profDetailsBox, 300, 28, "")
    m8CopyBtn:SetPoint("BOTTOM", 0, 48)
    m8CopyBtn:SetScript("OnClick", function()
      local curProf = SpArc:GetActiveProfileName()
      if selectedProfileForOps and selectedProfileForOps ~= "" and selectedProfileForOps ~= curProf then
        if SpArc:CopyProfileFrom(selectedProfileForOps) then
          print(string.format(SpArc:L("MSG_PROF_COPIED"), selectedProfileForOps, curProf))
          controlFrame:RefreshUI()
        end
      end
    end)

    local m8DeleteBtn = CreateElvButton(profDetailsBox, 300, 28, "")
    m8DeleteBtn:SetPoint("BOTTOM", 0, 14)
    m8DeleteBtn:SetScript("OnClick", function()
      local curProf = SpArc:GetActiveProfileName()
      if selectedProfileForOps and selectedProfileForOps ~= "Default" and selectedProfileForOps ~= curProf then
        local delName = selectedProfileForOps
        if SpArc:DeleteProfile(delName) then
          selectedProfileForOps = curProf
          print(string.format(SpArc:L("MSG_PROF_DELETED"), delName))
          controlFrame:RefreshUI()
        end
      end
    end)

    -----------------------------------------------------------------------------------
    -- MASTER REFRESH UI
    -----------------------------------------------------------------------------------
    function controlFrame:RefreshUI()
      isRefreshingUI = true
      db = SpArc:EnsureDB()

      subTitle:SetText(SpArc:L("WINDOW_SUBTITLE"))
      langBtn:SetText(SpArc:L("LANG_BTN"))
      fixCursorTopBtn:SetText(SpArc:L("TOP_FIX_CURSOR"))
      testHudTopBtn:SetText(string.format(SpArc:L("TOP_TEST_HUD"), SpArc.testMode and SpArc:L("MSG_ON") or SpArc:L("MSG_OFF")))
      testHudTopBtn:SetSelected(SpArc.testMode and true or false)

      for i, nb in ipairs(navButtons) do
        nb:SetText(SpArc:L(nb.nKey))
        nb:SetSelected(i == currentTabIdx)
      end

      for _, gb in ipairs(groupBoxes) do
        gb.header:SetText(SpArc:L(gb.titleKey))
      end

      m3Title:SetText(SpArc:L("M3_TITLE"))
      m4Title:SetText(SpArc:L("M4_TITLE"))
      m5Title:SetText(SpArc:L("M5_TITLE"))
      m6Title:SetText(SpArc:L("M6_TITLE"))
      m7Title:SetText(SpArc:L("M7_TITLE"))
      m8Title:SetText(SpArc:L("M8_TITLE"))
      m6FixCursorBtn:SetText(SpArc:L("M6_FIX_BTN"))

      local notBoundLabel = SpArc:L("M6_NOT_BOUND")
      for _, kbRow in ipairs(keybindRows) do
        kbRow.lbl:SetText(SpArc:L(kbRow.labelKey))
        kbRow.unbindBtn:SetText(SpArc:L("M6_UNBIND_KEY"))
        kbRow.resetBtn:SetText(SpArc:L("M6_RESET_KEY"))
        if activeKeybindCapture and activeKeybindCapture:IsShown() and activeKeybindCapture.targetDBKey == kbRow.dbKey then
          kbRow.bindBtn:SetSelected(true)
          kbRow.bindBtn:SetText("|cff00ffcc" .. SpArc:L("M6_BIND_WAIT") .. "|r")
        else
          kbRow.bindBtn:SetSelected(false)
          local curKey = db.visual[kbRow.dbKey]
          if curKey == nil or curKey == "AUTO" then
            curKey = (kbRow.defaultVal == "AUTO") and SpArc:GetGameInteractKey() or kbRow.defaultVal
          end
          if type(curKey) ~= "string" or curKey == "" then
            kbRow.bindBtn:SetText("|cff888899[ " .. notBoundLabel .. " ]|r")
          else
            kbRow.bindBtn:SetText("|cffffd100[ " .. curKey .. " ]|r")
          end
        end
      end

      if SpArc.SelectActiveParsedProfile then
        SpArc:SelectActiveParsedProfile()
      end
      local pClass = GetPlayerClassTag()
      local curSelPr = db.presets[selectedPresetForEdit]
      if not curSelPr or (filterClassOnly and curSelPr.class ~= pClass) then
        selectedPresetForEdit = db.activePresetID or selectedPresetForEdit
      end
      local totalCount = #db.presetOrder
      local classCount = 0
      local filteredIDs = {}
      for _, id in ipairs(db.presetOrder) do
        local pr = db.presets[id]
        if pr then
          if pr.class == pClass then
            classCount = classCount + 1
          end
          if not filterClassOnly or pr.class == pClass then
            filteredIDs[#filteredIDs + 1] = id
          end
        end
      end

      local activePr = db.presets[db.activePresetID]
      local activeTitle = (activePr and SpArc:GetPresetDisplayTitle(activePr)) or db.activePresetID
      p1Summary:SetText(string.format(
        SpArc:L("P1_SUMMARY"),
        totalCount, pClass, classCount, activeTitle, db.mode
      ))
      filterBtn:SetText(filterClassOnly and string.format(SpArc:L("FILTER_CLASS"), pClass, classCount) or string.format(SpArc:L("FILTER_ALL"), totalCount))
      autoModeBtn:SetText(db.mode == "AUTO" and SpArc:L("MODE_AUTO") or SpArc:L("MODE_MANUAL"))
      newPresetBtn:SetText(SpArc:L("NEW_PRESET_BTN"))
      activateBtn:SetText(SpArc:L("ACTIVATE_BTN"))
      openMdBtn:SetText(SpArc:L("OPEN_MD_BTN"))
      testModeBtn1:SetText(SpArc:L("TEST_HUD_BTN"))

      for idx = 1, #rowButtons do
        local rBtn = rowButtons[idx]
        local id = filteredIDs[idx]
        if id and db.presets[id] then
          local pr = db.presets[id]
          local prefix = (id == db.activePresetID and SpArc:L("PREFIX_ACTIVE")) or (id == selectedPresetForEdit and SpArc:L("PREFIX_SELECTED")) or ""
          rBtn:SetText(prefix .. SpArc:GetPresetDisplayTitle(pr))
          rBtn:SetSelected(id == selectedPresetForEdit)
          rBtn:SetScript("OnClick", function()
            selectedPresetForEdit = id
            controlFrame:RefreshUI()
          end)
          rBtn:Show()
        else
          rBtn:Hide()
        end
      end
      listContent:SetHeight(math.max(450, #filteredIDs * 26 + 10))

      local selPr = db.presets[selectedPresetForEdit]
      local selParsed = SpArc.ParsedPresets and SpArc.ParsedPresets[selectedPresetForEdit]
      if selPr and selParsed then
        local intList = {}
        for k, _ in pairs(selParsed.interruptibleChannels or {}) do intList[#intList + 1] = k end
        local protList = {}
        for k, _ in pairs(selParsed.protectedChannels or {}) do protList[#protList + 1] = k end
        local noneStr = SpArc:L("NONE_STR")
        detailsText:SetText(string.format(
          SpArc:L("DETAILS_BODY"),
          SpArc:GetPresetDisplayTitle(selPr),
          selPr.class or "ANY", selPr.mode or "PVE",
          #(selParsed.rules or {}),
          (#(selParsed.saves or {}) > 0 and table.concat(selParsed.saves, ", ") or noneStr),
          (#(selParsed.cds or {}) > 0 and table.concat(selParsed.cds, ", ") or noneStr),
          (#intList > 0 and table.concat(intList, ", ") or noneStr),
          (#protList > 0 and table.concat(protList, ", ") or noneStr)
        ))
      end

      -- Module 2 refresh
      aiText:SetText(SpArc:L("AI_BANNER_PREFIX") .. SpArc:GetAIPromptHeader())
      saveMdBtn:SetText(SpArc:L("SAVE_MD_BTN"))
      resetMdBtn:SetText(SpArc:L("RESET_MD_BTN"))
      if showingAIPrompt then
        aiPromptBtn:SetText(SpArc:L("AI_BACK_BTN"))
        editorStatus:SetText(SpArc:L("AI_STATUS_COPY"))
        editBox:SetText(SpArc:GetAIPromptTemplate())
      else
        aiPromptBtn:SetText(SpArc:L("AI_PROMPT_BTN"))
        local pr = db.presets[selectedPresetForEdit]
        local cp = SpArc.ParsedPresets and SpArc.ParsedPresets[selectedPresetForEdit]
        editorStatus:SetText(string.format(
          SpArc:L("EDITOR_STATUS"),
          (pr and SpArc:GetPresetDisplayTitle(pr)) or selectedPresetForEdit,
          (cp and cp.rules and #cp.rules) or 0,
          (cp and cp.saves and #cp.saves) or 0,
          (cp and cp.cds and #cp.cds) or 0
        ))
        editBox:SetText((pr and pr.md) or "")
      end

      -- Sliders & Checkboxes refresh
      for _, s in ipairs(allSliders) do
        local val = tonumber(db.visual[s.key])
        if val == nil then val = DEFAULT_VISUAL[s.key] or 0 end
        s.title:SetText(SpArc:L(s.labelKey))
        s.slider:SetValue(val)
        s.valTxt:SetText(s.FormatVal(val))
        s.UpdateFill(val)
      end

      for _, c in ipairs(allChecks) do
        c.txt:SetText(SpArc:L(c.labelKey))
        local checked
        if c.isTestToggle then
          checked = SpArc.testMode and true or false
        else
          checked = (db.visual[c.key] ~= false)
        end
        c:UpdateVisual(checked)
      end

      -- Module 7 refresh
      snapBtn:SetText(SpArc:L("TEL_SNAP_BTN"))
      copyTelBtn:SetText(SpArc:L("TEL_COPY_BTN"))
      clearTelBtn:SetText(SpArc:L("TEL_CLEAR_BTN"))
      if pages[7]:IsShown() then
        local okRep, repText = pcall(SpArc.BuildTelemetryReportText, SpArc)
        telEditBox:SetText((okRep and repText) or "")
      end

      -- Module 8 (Profiles) refresh
      local curChar = SpArc:GetCurrentCharKey()
      local activeProfName = SpArc:GetActiveProfileName()
      local profList = SpArc:GetProfileList()
      if not selectedProfileForOps or not (db.profiles and db.profiles[selectedProfileForOps]) then
        selectedProfileForOps = activeProfName
      end

      local function fmtBind(val, isInteract)
        if val == nil or (isInteract and val == "AUTO") then
          val = isInteract and SpArc:GetGameInteractKey() or ""
        end
        if type(val) ~= "string" or val == "" then
          return notBoundLabel
        end
        return val
      end

      local curVis = db.visual or {}
      m8CurSummary:SetText(string.format(
        SpArc:L("M8_CUR_SUMMARY"),
        curChar,
        activeProfName,
        fmtBind(curVis.camHoldKey, false),
        fmtBind(curVis.camToggleKey, false),
        fmtBind(curVis.camInteractKey, true)
      ))
      m8CharProfBtn:SetText(SpArc:L("M8_CHAR_PROF_BTN"))
      m8CharProfBtn:SetSelected(activeProfName == curChar)
      m8DefProfBtn:SetText(SpArc:L("M8_DEF_PROF_BTN"))
      m8DefProfBtn:SetSelected(activeProfName == "Default")
      m8ResetProfBtn:SetText(SpArc:L("M8_RESET_BTN"))

      for idx = 1, #profRowButtons do
        local prBtn = profRowButtons[idx]
        local pName = profList[idx]
        if pName then
          local prefix = (pName == activeProfName and SpArc:L("PREFIX_ACTIVE"))
            or (pName == selectedProfileForOps and SpArc:L("PREFIX_SELECTED"))
            or ""
          prBtn:SetText(prefix .. pName)
          prBtn:SetSelected(pName == selectedProfileForOps)
          prBtn:SetScript("OnClick", function()
            selectedProfileForOps = pName
            controlFrame:RefreshUI()
          end)
          prBtn:Show()
        else
          prBtn:Hide()
        end
      end
      profListContent:SetHeight(math.max(320, #profList * 28 + 10))

      local selProfObj = db.profiles and db.profiles[selectedProfileForOps]
      local selVis = (selProfObj and selProfObj.visual) or curVis
      profDetailsText:SetText(string.format(
        SpArc:L("M8_DETAILS_HEADER"),
        selectedProfileForOps or activeProfName,
        fmtBind(selVis.camHoldKey, false),
        fmtBind(selVis.camToggleKey, false),
        fmtBind(selVis.camInteractKey, true),
        tonumber(selVis.camCrosshairOffsetY) or 20,
        tonumber(selVis.camCrosshairScale) or 1.0,
        tonumber(selVis.arcRadius) or 108,
        tonumber(selVis.arcSpreadDeg) or 116
      ))
      m8ActivateBtn:SetText(SpArc:L("M8_ACTIVATE_BTN"))
      m8CopyBtn:SetText(SpArc:L("M8_COPY_BTN"))
      m8DeleteBtn:SetText(SpArc:L("M8_DELETE_BTN"))

      isRefreshingUI = false
    end

    SelectTab(initialTab or 1)
  else
    controlFrame:Show()
    if initialTab and controlFrame.SelectTab then
      controlFrame.SelectTab(initialTab)
    else
      SpArc.previewCrosshairInConfig = (currentTabIdx == 6) and controlFrame:IsShown()
      if SpArc.UpdateCameraState then SpArc:UpdateCameraState() end
      controlFrame:RefreshUI()
    end
  end
end

SpArc.OpenControlCenter = OpenControlCenter
SpArc.RefreshControlCenterUI = function()
  if controlFrame and controlFrame:IsShown() and controlFrame.RefreshUI then
    controlFrame:RefreshUI()
  end
end

---------------------------------------------------------------------------------------
--                  MINIMAP BUTTON & ICON (SpArcMinimapButton)                       --
---------------------------------------------------------------------------------------
local minimapBtn = nil

local function UpdateMinimapButtonPosition()
  if not minimapBtn or not _G.Minimap then return end
  local parent = minimapBtn:GetParent()
  -- Do not override position if ElvUI_WindTools MinimapButtons or another bar has adopted the button
  if (parent and parent ~= _G.Minimap) or minimapBtn.isSkinned or minimapBtn.original then
    return
  end
  local db = SpArc:EnsureDB()
  local angle = math.rad(tonumber(db.visual and db.visual.minimapAngle) or 205)
  local okW, rawW = pcall(_G.Minimap.GetWidth, _G.Minimap)
  local mmW = (okW and type(rawW) == "number" and not IsSecret(rawW) and rawW > 0) and rawW or 140
  local radius = (mmW / 2) + 8
  local x = math.cos(angle) * radius
  local y = math.sin(angle) * radius
  minimapBtn:ClearAllPoints()
  minimapBtn:SetPoint("CENTER", _G.Minimap, "CENTER", x, y)
end

function SpArc:UpdateMinimapButtonVisibility()
  if not minimapBtn then return end
  local db = SpArc:EnsureDB()
  if db.visual and db.visual.showMinimapButton == false then
    minimapBtn:Hide()
  else
    minimapBtn:Show()
  end
end

local function CreateSpArcMinimapButton()
  if minimapBtn or not _G.Minimap then return end
  local btn = CreateFrame("Button", "SpArcMinimapButton", _G.Minimap)
  minimapBtn = btn
  btn:SetSize(28, 28)
  btn:SetFrameStrata("MEDIUM")
  btn:SetFrameLevel(8)
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  btn:RegisterForDrag("LeftButton")

  -- Keep ONLY the main icon texture as a direct region of btn so WindTools MinimapButtons
  -- skins the icon cleanly instead of stretching solid background/border textures over ARTWORK!
  local frameDecor = CreateFrame("Frame", nil, btn)
  frameDecor:SetAllPoints(btn)
  frameDecor:SetFrameLevel(math.max(1, btn:GetFrameLevel() - 1))

  local bg = frameDecor:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(frameDecor)
  bg:SetColorTexture(0.06, 0.04, 0.10, 0.95)

  local border = frameDecor:CreateTexture(nil, "BORDER")
  border:SetPoint("TOPLEFT", frameDecor, "TOPLEFT", -1, 1)
  border:SetPoint("BOTTOMRIGHT", frameDecor, "BOTTOMRIGHT", 1, -1)
  border:SetColorTexture(0.75, 0.30, 1.0, 0.90)
  btn.border = border

  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
  icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
  icon:SetTexture(1386548)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  btn.icon = icon

  local label = btn:CreateFontString(nil, "OVERLAY")
  ApplyCyrFont(label, 9)
  label:SetPoint("BOTTOM", btn, "BOTTOM", 0, 1)
  label:SetTextColor(1, 0.85, 0.25, 1)
  label:SetText("SpArc")

  btn:SetScript("OnEnter", function(self)
    if self.border then self.border:SetColorTexture(1.0, 0.82, 0.20, 1.0) end
    if _G.GameTooltip then
      _G.GameTooltip:SetOwner(self, "ANCHOR_LEFT")
      _G.GameTooltip:AddLine(string.format(SpArc:L("MM_TT_TITLE"), SpArc.VERSION))
      _G.GameTooltip:AddLine(SpArc:L("MM_TT_LEFT"), 0.9, 0.9, 0.9)
      _G.GameTooltip:AddLine(SpArc:L("MM_TT_RIGHT"), 0.9, 0.9, 0.9)
      _G.GameTooltip:AddLine(SpArc:L("MM_TT_SHIFT"), 0.9, 0.9, 0.9)
      _G.GameTooltip:AddLine(SpArc:L("MM_TT_DRAG"), 0.7, 0.7, 0.7)
      _G.GameTooltip:Show()
    end
  end)
  btn:SetScript("OnLeave", function(self)
    if self.border then self.border:SetColorTexture(0.75, 0.30, 1.0, 0.90) end
    if _G.GameTooltip then _G.GameTooltip:Hide() end
  end)

  btn:SetScript("OnDragStart", function(self)
    if (self:GetParent() and self:GetParent() ~= _G.Minimap) or self.isSkinned then return end
    self:SetScript("OnUpdate", function()
      if not _G.Minimap or not _G.GetCursorPosition then return end
      local okC, mx, my = pcall(_G.Minimap.GetCenter, _G.Minimap)
      local okP, cx, cy = pcall(_G.GetCursorPosition)
      local okS, scale = pcall(_G.Minimap.GetEffectiveScale, _G.Minimap)
      if not okC or not okP or not okS or IsSecret(mx) or IsSecret(my) or IsSecret(cx) or IsSecret(cy) or IsSecret(scale) or not scale or scale <= 0 then
        return
      end
      cx, cy = cx / scale, cy / scale
      local db = SpArc:EnsureDB()
      db.visual.minimapAngle = math.deg(math.atan2(cy - my, cx - mx))
      UpdateMinimapButtonPosition()
    end)
  end)
  btn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
  end)

  btn:SetScript("OnClick", function(_, mouseBtn)
    if _G.IsShiftKeyDown and _G.IsShiftKeyDown() then
      SpArc.testMode = not SpArc.testMode
      print(string.format(SpArc:L("MSG_TEST_TOGGLE"), SpArc.testMode and SpArc:L("MSG_ON") or SpArc:L("MSG_OFF")))
      return
    end
    if mouseBtn == "RightButton" then
      pcall(SpArc.CaptureTelemetrySnapshot, SpArc, "MANUAL_SNAPSHOT")
      OpenControlCenter(7)
    else
      if controlFrame and controlFrame:IsShown() then
        controlFrame:Hide()
      else
        OpenControlCenter(1)
      end
    end
  end)

  UpdateMinimapButtonPosition()
  SpArc:UpdateMinimapButtonVisibility()
end

---------------------------------------------------------------------------------------
--         BLIZZARD ADDON SETTINGS PANEL (ESC -> ПАРАМЕТРЫ -> МОДИФИКАЦИИ)           --
---------------------------------------------------------------------------------------
local blizzardSettingsRegistered = false
local function RegisterSpArcBlizzardSettings()
  if blizzardSettingsRegistered then return end
  if not (_G.Settings and _G.Settings.RegisterCanvasLayoutCategory and _G.Settings.RegisterAddOnCategory) then
    return
  end
  blizzardSettingsRegistered = true

  local panel = CreateFrame("Frame", "SpArcBlizzardSettingsPanel", UIParent)
  panel.name = "SpArc"

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  ApplyCyrFont(title, 18)
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("|cffa335eeSpArc v" .. tostring(SpArc.VERSION) .. "|r — Semicircle FSM Rotation & Action Combat Camera")

  local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  ApplyCyrFont(desc, 13)
  desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
  desc:SetWidth(580)
  desc:SetJustifyH("LEFT")
  desc:SetSpacing(4)
  desc:SetText("Авторы: |cffffd100Gemini (Tiger) & Anya (5cr3am1ng5oul)|r\n\nМодульный визуализатор FSM-ротаций (.MD псевдокод), двунаправленный кастбар, крылья сейвов/бурстов, автономная Боевая Камера (Mouselook) и индивидуальные профили персонажей.")

  local function CreateQuickBtn(text, x, y, tabIdx)
    local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    b:SetSize(250, 32)
    b:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    b:SetText(text)
    b:SetScript("OnClick", function()
      if _G.HideUIPanel and _G.SettingsPanel and _G.SettingsPanel:IsShown() then
        pcall(_G.HideUIPanel, _G.SettingsPanel)
      end
      OpenControlCenter(tabIdx or 1)
    end)
    return b
  end

  CreateQuickBtn("Открыть центр управления SpArc (/sparc)", 16, -110, 1)
  CreateQuickBtn("Боевая Камера и клавиши (/sparc cam)", 280, -110, 6)
  CreateQuickBtn("Дуга ротации и HUD (/sparc hud)", 16, -152, 3)
  CreateQuickBtn("Профили персонажей (/sparc profiles)", 280, -152, 8)

  local okCat, category = pcall(_G.Settings.RegisterCanvasLayoutCategory, panel, "SpArc")
  if okCat and category then
    pcall(_G.Settings.RegisterAddOnCategory, category)
    SpArc.settingsCategoryID = category.GetID and category:GetID() or nil
  end
end

CreateSpArcMinimapButton()
RegisterSpArcBlizzardSettings()
SpArc:ApplySmartBossTabBinding()
if _G.C_Timer and _G.C_Timer.After then
  _G.C_Timer.After(1.0, function()
    CreateSpArcMinimapButton()
    RegisterSpArcBlizzardSettings()
    UpdateMinimapButtonPosition()
    SpArc:UpdateMinimapButtonVisibility()
    SpArc:ApplySmartBossTabBinding()
  end)
end

_G.SLASH_SPARC1 = "/sparc"
_G.SLASH_SPARC2 = "/sa"
_G.SLASH_SPARC3 = "/sparkarc"
_G.SlashCmdList["SPARC"] = function(msg)
  local cmd = (msg or ""):match("^(%S*)")
  cmd = (cmd or ""):lower()
  local db = SpArc:EnsureDB()
  if cmd == "test" then
    SpArc.testMode = not SpArc.testMode
    print(string.format(SpArc:L("MSG_TEST_TOGGLE"), SpArc.testMode and SpArc:L("MSG_ON") or SpArc:L("MSG_OFF")))
  elseif cmd == "debug" or cmd == "tel" or cmd == "telemetry" then
    pcall(SpArc.CaptureTelemetrySnapshot, SpArc, "MANUAL_SNAPSHOT")
    OpenControlCenter(7)
  elseif cmd == "en" or cmd == "ru" then
    db.visual.lang = cmd:upper()
    SpArc:ApplyVisualLayout()
    if controlFrame and controlFrame:IsShown() then controlFrame:RefreshUI() end
  elseif cmd == "pve" or cmd == "boss" or cmd == "pvp" or cmd == "auto" then
    db.mode = cmd:upper()
  elseif cmd == "import" or cmd == "edit" or cmd == "md" or cmd == "ai" then
    showingAIPrompt = (cmd == "ai")
    OpenControlCenter(2)
  elseif cmd == "visual" or cmd == "hud" or cmd == "arc" then
    OpenControlCenter(3)
  elseif cmd == "cam" or cmd == "camera" then
    OpenControlCenter(6)
  elseif cmd == "prof" or cmd == "profile" or cmd == "profiles" then
    OpenControlCenter(8)
  elseif cmd == "fixcursor" or cmd == "cursor" then
    if SpArc.FlushHardwareCursor then
      SpArc:FlushHardwareCursor(true)
    end
    print(SpArc:L("MSG_CURSOR_FIXED"))
  elseif cmd == "always" then
    db.visual.alwaysShowCDs = not db.visual.alwaysShowCDs
  else
    OpenControlCenter(1)
  end
end
