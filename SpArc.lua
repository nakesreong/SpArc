---------------------------------------------------------------------------------------
--  SpArc/SpArc.lua — Bilingual 4-Tab Control Center UI, Minimap Button & Slash Commands
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc

local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local UnitClass = _G.UnitClass
local pcall = _G.pcall
local ipairs = _G.ipairs
local pairs = _G.pairs
local tonumber = _G.tonumber
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

local function GetPlayerClassTag()
  if UnitClass then
    local ok, _, classTag = pcall(UnitClass, "player")
    if ok and not IsSecret(classTag) and type(classTag) == "string" then
      return classTag
    end
  end
  return "PRIEST"
end

local function OpenControlCenter(initialTab)
  local db = SpArc:EnsureDB()

  if not controlFrame then
    controlFrame = CreateFrame("Frame", "SpArcControlCenter", UIParent, "BackdropTemplate")
    controlFrame:SetSize(780, 580)
    controlFrame:SetPoint("CENTER")
    controlFrame:SetFrameStrata("DIALOG")
    controlFrame:SetMovable(true)
    controlFrame:EnableMouse(true)
    controlFrame:RegisterForDrag("LeftButton")
    controlFrame:SetScript("OnDragStart", controlFrame.StartMoving)
    controlFrame:SetScript("OnDragStop", controlFrame.StopMovingOrSizing)
    if controlFrame.SetBackdrop then
      controlFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
      })
      controlFrame:SetBackdropColor(0.06, 0.06, 0.09, 0.97)
      controlFrame:SetBackdropBorderColor(0.68, 0.24, 0.96, 1)
    end

    local headerIcon = controlFrame:CreateTexture(nil, "ARTWORK")
    headerIcon:SetSize(28, 28)
    headerIcon:SetPoint("TOPLEFT", 16, -12)
    headerIcon:SetTexture(1386548)
    headerIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = controlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(title, 16)
    title:SetPoint("TOPLEFT", 50, -12)

    local subTitle = controlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(subTitle, 11)
    subTitle:SetPoint("TOPLEFT", 50, -32)
    subTitle:SetTextColor(0.72, 0.72, 0.82, 1)

    local closeBtn = CreateFrame("Button", nil, controlFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)

    local langBtn = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")
    langBtn:SetSize(92, 22)
    langBtn:SetPoint("TOPRIGHT", -36, -10)
    langBtn:SetScript("OnClick", function()
      local cur = SpArc:GetActiveLang()
      db.visual.lang = (cur == "RU") and "EN" or "RU"
      SpArc:ApplyVisualLayout()
      controlFrame:RefreshUI()
    end)

    local tabKeys = { "TAB_1", "TAB_2", "TAB_3", "TAB_4" }
    local tabs = {}
    local pages = {}

    local function SelectTab(idx)
      for i = 1, #tabs do
        if i == idx then
          pages[i]:Show()
          tabs[i]:Disable()
        else
          pages[i]:Hide()
          tabs[i]:Enable()
        end
      end
      if controlFrame.RefreshUI then
        controlFrame:RefreshUI()
      end
    end
    controlFrame.SelectTab = SelectTab

    for i, tKey in ipairs(tabKeys) do
      local btn = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")
      btn:SetSize(182, 26)
      btn:SetPoint("TOPLEFT", 16 + (i - 1) * 188, -54)
      btn:SetText(SpArc:L(tKey))
      btn:SetScript("OnClick", function() SelectTab(i) end)
      btn.tKey = tKey
      tabs[i] = btn

      local page = CreateFrame("Frame", nil, controlFrame)
      page:SetPoint("TOPLEFT", 16, -88)
      page:SetPoint("BOTTOMRIGHT", -16, 16)
      page:Hide()
      pages[i] = page
    end

    -----------------------------------------------------------------------------------
    -- TAB 1: PRESETS LIBRARY (55 TOTAL / 10 PER CLASS / 1 ACTIVE)
    -----------------------------------------------------------------------------------
    local p1 = pages[1]
    local p1Summary = p1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(p1Summary, 13)
    p1Summary:SetPoint("TOPLEFT", 0, 0)
    p1Summary:SetJustifyH("LEFT")

    local filterBtn = CreateFrame("Button", nil, p1, "UIPanelButtonTemplate")
    filterBtn:SetSize(240, 24)
    filterBtn:SetPoint("TOPLEFT", 0, -26)
    filterBtn:SetScript("OnClick", function()
      filterClassOnly = not filterClassOnly
      controlFrame:RefreshUI()
    end)

    local autoModeBtn = CreateFrame("Button", nil, p1, "UIPanelButtonTemplate")
    autoModeBtn:SetSize(220, 24)
    autoModeBtn:SetPoint("LEFT", filterBtn, "RIGHT", 10, 0)
    autoModeBtn:SetScript("OnClick", function()
      db.mode = (db.mode == "AUTO") and "MANUAL" or "AUTO"
      controlFrame:RefreshUI()
    end)

    local newPresetBtn = CreateFrame("Button", nil, p1, "UIPanelButtonTemplate")
    newPresetBtn:SetSize(160, 24)
    newPresetBtn:SetPoint("LEFT", autoModeBtn, "RIGHT", 10, 0)
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

    local listScroll = CreateFrame("ScrollFrame", "SpArcPresetListScroll", p1, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", 0, -58)
    listScroll:SetSize(380, 395)

    local listContent = CreateFrame("Frame", nil, listScroll)
    listContent:SetSize(360, 1500)
    listScroll:SetScrollChild(listContent)

    local rowButtons = {}
    for idx = 1, 65 do
      local rBtn = CreateFrame("Button", nil, listContent, "UIPanelButtonTemplate")
      rBtn:SetSize(355, 24)
      rBtn:SetPoint("TOPLEFT", 0, -(idx - 1) * 26)
      rBtn:Hide()
      rowButtons[idx] = rBtn
    end

    local detailsBox = CreateFrame("Frame", nil, p1, "BackdropTemplate")
    detailsBox:SetPoint("TOPLEFT", 412, -58)
    detailsBox:SetPoint("BOTTOMRIGHT", 0, 0)
    if detailsBox.SetBackdrop then
      detailsBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
      })
      detailsBox:SetBackdropColor(0.09, 0.09, 0.14, 0.95)
      detailsBox:SetBackdropBorderColor(0.35, 0.35, 0.48, 1)
    end

    local detailsText = detailsBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(detailsText, 12)
    detailsText:SetPoint("TOPLEFT", 14, -14)
    detailsText:SetPoint("TOPRIGHT", -14, -14)
    detailsText:SetJustifyH("LEFT")
    detailsText:SetJustifyV("TOP")

    local activateBtn = CreateFrame("Button", nil, detailsBox, "UIPanelButtonTemplate")
    activateBtn:SetSize(280, 28)
    activateBtn:SetPoint("BOTTOM", 0, 82)
    activateBtn:SetScript("OnClick", function()
      db.activePresetID = selectedPresetForEdit
      db.mode = "MANUAL"
      controlFrame:RefreshUI()
      local dispTitle = SpArc:GetPresetDisplayTitle(db.presets[selectedPresetForEdit])
      print(string.format(SpArc:L("MSG_ACTIVATED"), dispTitle ~= "" and dispTitle or selectedPresetForEdit))
    end)

    local openMdBtn = CreateFrame("Button", nil, detailsBox, "UIPanelButtonTemplate")
    openMdBtn:SetSize(280, 28)
    openMdBtn:SetPoint("BOTTOM", 0, 48)
    openMdBtn:SetScript("OnClick", function()
      showingAIPrompt = false
      SelectTab(2)
    end)

    local testModeBtn1 = CreateFrame("Button", nil, detailsBox, "UIPanelButtonTemplate")
    testModeBtn1:SetSize(280, 26)
    testModeBtn1:SetPoint("BOTTOM", 0, 14)
    testModeBtn1:SetScript("OnClick", function()
      SpArc.testMode = not SpArc.testMode
      controlFrame:RefreshUI()
    end)

    -----------------------------------------------------------------------------------
    -- TAB 2: .MD PSEUDOCODE IMPORTER & AI PROMPT GENERATOR (GEMINI / CHATGPT)
    -----------------------------------------------------------------------------------
    local p2 = pages[2]
    local aiBanner = CreateFrame("Frame", nil, p2, "BackdropTemplate")
    aiBanner:SetPoint("TOPLEFT", 0, 0)
    aiBanner:SetPoint("TOPRIGHT", 0, 0)
    aiBanner:SetHeight(64)
    if aiBanner.SetBackdrop then
      aiBanner:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
      })
      aiBanner:SetBackdropColor(0.14, 0.08, 0.24, 0.95)
      aiBanner:SetBackdropBorderColor(0.85, 0.65, 0.20, 1)
    end

    local aiText = aiBanner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(aiText, 12)
    aiText:SetPoint("TOPLEFT", 12, -10)
    aiText:SetWidth(500)
    aiText:SetJustifyH("LEFT")
    aiText:SetTextColor(1, 0.92, 0.60, 1)

    local aiPromptBtn = CreateFrame("Button", nil, aiBanner, "UIPanelButtonTemplate")
    aiPromptBtn:SetSize(210, 36)
    aiPromptBtn:SetPoint("RIGHT", -12, 0)

    local editorStatus = p2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(editorStatus, 12)
    editorStatus:SetPoint("TOPLEFT", 2, -72)
    editorStatus:SetJustifyH("LEFT")

    local edScroll = CreateFrame("ScrollFrame", "SpArcMdEditorScroll", p2, "UIPanelScrollFrameTemplate")
    edScroll:SetPoint("TOPLEFT", 0, -94)
    edScroll:SetPoint("BOTTOMRIGHT", -28, 42)

    local editBox = CreateFrame("EditBox", nil, edScroll)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    ApplyCyrFont(editBox, 12)
    editBox:SetWidth(700)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)
    edScroll:SetScrollChild(editBox)

    aiPromptBtn:SetScript("OnClick", function()
      showingAIPrompt = not showingAIPrompt
      controlFrame:RefreshUI()
      if showingAIPrompt then
        editBox:SetFocus()
        editBox:HighlightText()
      end
    end)

    local saveMdBtn = CreateFrame("Button", nil, p2, "UIPanelButtonTemplate")
    saveMdBtn:SetSize(220, 28)
    saveMdBtn:SetPoint("BOTTOMRIGHT", 0, 4)
    saveMdBtn:SetScript("OnClick", function()
      if showingAIPrompt then
        showingAIPrompt = false
        controlFrame:RefreshUI()
        return
      end
      local pr = db.presets[selectedPresetForEdit]
      if pr then
        pr.md = editBox:GetText()
        local parsed = SpArc:ParseMarkdownFSM(pr.md)
        if parsed.title and parsed.title ~= "Custom FSM" then
          pr.title = parsed.title
        end
        SpArc:RebuildParsedProfiles()
        controlFrame:RefreshUI()
        print(string.format(SpArc:L("MSG_MD_SAVED"), SpArc:GetPresetDisplayTitle(pr)))
      end
    end)

    local resetMdBtn = CreateFrame("Button", nil, p2, "UIPanelButtonTemplate")
    resetMdBtn:SetSize(180, 28)
    resetMdBtn:SetPoint("BOTTOMLEFT", 0, 4)
    resetMdBtn:SetScript("OnClick", function()
      showingAIPrompt = false
      local bp = SpArc.BuiltInPresets and SpArc.BuiltInPresets[selectedPresetForEdit]
      if bp and db.presets[selectedPresetForEdit] then
        db.presets[selectedPresetForEdit].md = bp.md
        SpArc:RebuildParsedProfiles()
        controlFrame:RefreshUI()
      end
    end)

    -----------------------------------------------------------------------------------
    -- TAB 3: VISUAL, MINIMAP & TELEMETRY SETTINGS
    -----------------------------------------------------------------------------------
    local p3 = pages[3]
    local vHeader = p3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(vHeader, 14)
    vHeader:SetPoint("TOPLEFT", 0, 0)

    local function CreateVisualSlider(labelKey, key, minV, maxV, stepV, x, y)
      local sFrame = CreateFrame("Frame", nil, p3)
      sFrame:SetSize(320, 46)
      sFrame:SetPoint("TOPLEFT", x, y)

      local txt = sFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      ApplyCyrFont(txt, 12)
      txt:SetPoint("TOPLEFT", 0, 0)

      local slider = CreateFrame("Slider", nil, sFrame, "OptionsSliderTemplate")
      slider:SetPoint("TOPLEFT", 0, -18)
      slider:SetSize(300, 16)
      slider:SetMinMaxValues(minV, maxV)
      slider:SetValueStep(stepV)
      slider:SetObeyStepOnDrag(true)
      slider:SetScript("OnValueChanged", function(_, val)
        local rounded = math.floor((val / stepV) + 0.5) * stepV
        db.visual[key] = rounded
        txt:SetText(string.format("%s: |cffffd100%.2f|r", SpArc:L(labelKey), rounded))
        if not isRefreshingUI then
          SpArc:ApplyVisualLayout()
        end
      end)
      sFrame.slider = slider
      sFrame.txt = txt
      sFrame.labelKey = labelKey
      sFrame.key = key
      return sFrame
    end

    local sliders = {
      CreateVisualSlider("SL_ARC_RADIUS", "arcRadius", 50, 260, 5, 0, -28),
      CreateVisualSlider("SL_ARC_SPREAD", "arcSpreadDeg", 60, 180, 5, 360, -28),
      CreateVisualSlider("SL_PRIMARY_SCALE", "primaryScale", 1.0, 2.0, 0.05, 0, -78),
      CreateVisualSlider("SL_QUEUE_SCALE", "queueScale", 0.6, 1.4, 0.05, 360, -78),
      CreateVisualSlider("SL_QUEUE_LEN", "queueLength", 3, 6, 1, 0, -128),
      CreateVisualSlider("SL_ARC_OFFSET_Y", "arcOffsetY", -120, 180, 5, 360, -128),
      CreateVisualSlider("SL_CB_WIDTH", "castbarWidth", 180, 420, 4, 0, -178),
      CreateVisualSlider("SL_CB_OFFSET_Y", "castbarOffsetY", -240, -40, 5, 360, -178),
      CreateVisualSlider("SL_EMERG_HP", "emergencyHP", 15, 50, 5, 0, -228),
      CreateVisualSlider("SL_WINGS_Y", "wingsOffsetY", -200, 60, 5, 360, -228),
    }

    local function CreateVisualCheck(labelKey, key, y, isTestToggle, onAfterClick)
      local cb = CreateFrame("CheckButton", nil, p3, "UICheckButtonTemplate")
      cb:SetPoint("TOPLEFT", 0, y)
      local txt = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      ApplyCyrFont(txt, 13)
      txt:SetPoint("LEFT", cb, "RIGHT", 6, 0)
      txt:SetText(SpArc:L(labelKey))
      cb:SetScript("OnClick", function()
        if isTestToggle then
          SpArc.testMode = cb:GetChecked() and true or false
        else
          db.visual[key] = cb:GetChecked() and true or false
        end
        if onAfterClick then onAfterClick() end
      end)
      cb.key = key
      cb.labelKey = labelKey
      cb.txt = txt
      cb.isTestToggle = isTestToggle
      return cb
    end

    local checks = {
      CreateVisualCheck("CK_SAVES_WING", "showSavesWing", -280, false),
      CreateVisualCheck("CK_CDS_WING", "showCDsWing", -306, false),
      CreateVisualCheck("CK_EMERG_SAVE", "showEmergencySave", -332, false),
      CreateVisualCheck("CK_ALWAYS_CDS", "alwaysShowCDs", -358, false),
      CreateVisualCheck("CK_INTERRUPT", "showInterruptAlert", -384, false),
      CreateVisualCheck("CK_CASTBAR", "showCastbar", -410, false),
      CreateVisualCheck("CK_MINIMAP", "showMinimapButton", -436, false, function()
        if SpArc.UpdateMinimapButtonVisibility then SpArc:UpdateMinimapButtonVisibility() end
      end),
      CreateVisualCheck("CK_TEST_MODE", "testMode", -462, true),
    }

    -----------------------------------------------------------------------------------
    -- TAB 4: TELEMETRY & SPELLBOOK DEBUGGER
    -----------------------------------------------------------------------------------
    local p4 = pages[4]
    local tHeader = p4:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(tHeader, 13)
    tHeader:SetPoint("TOPLEFT", 0, 0)

    local snapBtn = CreateFrame("Button", nil, p4, "UIPanelButtonTemplate")
    snapBtn:SetSize(195, 26)
    snapBtn:SetPoint("TOPLEFT", 0, -26)

    local copyTelBtn = CreateFrame("Button", nil, p4, "UIPanelButtonTemplate")
    copyTelBtn:SetSize(175, 26)
    copyTelBtn:SetPoint("LEFT", snapBtn, "RIGHT", 8, 0)

    local clearTelBtn = CreateFrame("Button", nil, p4, "UIPanelButtonTemplate")
    clearTelBtn:SetSize(185, 26)
    clearTelBtn:SetPoint("LEFT", copyTelBtn, "RIGHT", 8, 0)

    local telToggleCheck = CreateFrame("CheckButton", nil, p4, "UICheckButtonTemplate")
    telToggleCheck:SetPoint("LEFT", clearTelBtn, "RIGHT", 10, 0)
    local telToggleTxt = telToggleCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(telToggleTxt, 12)
    telToggleTxt:SetPoint("LEFT", telToggleCheck, "RIGHT", 4, 0)
    telToggleCheck:SetScript("OnClick", function()
      db.visual.enableTelemetry = telToggleCheck:GetChecked() and true or false
      controlFrame:RefreshUI()
    end)

    local telScroll = CreateFrame("ScrollFrame", "SpArcTelemetryScroll", p4, "UIPanelScrollFrameTemplate")
    telScroll:SetPoint("TOPLEFT", 0, -60)
    telScroll:SetPoint("BOTTOMRIGHT", -28, 6)

    local telEditBox = CreateFrame("EditBox", nil, telScroll)
    telEditBox:SetMultiLine(true)
    telEditBox:SetFontObject("ChatFontNormal")
    ApplyCyrFont(telEditBox, 11)
    telEditBox:SetWidth(700)
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

    function controlFrame:RefreshUI()
      isRefreshingUI = true

      title:SetText(string.format(SpArc:L("WINDOW_TITLE"), SpArc.VERSION))
      subTitle:SetText(SpArc:L("WINDOW_SUBTITLE"))
      langBtn:SetText(SpArc:L("LANG_BTN"))
      for _, tb in ipairs(tabs) do
        tb:SetText(SpArc:L(tb.tKey))
      end

      local pClass = GetPlayerClassTag()
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
          rBtn:SetScript("OnClick", function()
            selectedPresetForEdit = id
            controlFrame:RefreshUI()
          end)
          rBtn:Show()
        else
          rBtn:Hide()
        end
      end
      listContent:SetHeight(math.max(380, #filteredIDs * 26 + 10))

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

      -- Tab 2 refresh
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

      -- Tab 3 refresh
      vHeader:SetText(SpArc:L("V_HEADER"))
      for _, s in ipairs(sliders) do
        local val = tonumber(db.visual[s.key]) or DEFAULT_VISUAL[s.key]
        s.slider:SetValue(val)
        s.txt:SetText(string.format("%s: |cffffd100%.2f|r", SpArc:L(s.labelKey), val))
      end
      for _, c in ipairs(checks) do
        c.txt:SetText(SpArc:L(c.labelKey))
        if c.isTestToggle then
          c:SetChecked(SpArc.testMode and true or false)
        else
          c:SetChecked(db.visual[c.key] ~= false)
        end
      end

      -- Tab 4 refresh
      tHeader:SetText(SpArc:L("TEL_HEADER"))
      snapBtn:SetText(SpArc:L("TEL_SNAP_BTN"))
      copyTelBtn:SetText(SpArc:L("TEL_COPY_BTN"))
      clearTelBtn:SetText(SpArc:L("TEL_CLEAR_BTN"))
      telToggleTxt:SetText(SpArc:L("TEL_TOGGLE"))
      telToggleCheck:SetChecked(db.visual.enableTelemetry ~= false)
      if pages[4]:IsShown() then
        local okRep, repText = pcall(SpArc.BuildTelemetryReportText, SpArc)
        telEditBox:SetText((okRep and repText) or "")
      end

      isRefreshingUI = false
    end

    SelectTab(initialTab or 1)
  else
    controlFrame:Show()
    if initialTab and controlFrame.SelectTab then
      controlFrame.SelectTab(initialTab)
    else
      controlFrame:RefreshUI()
    end
  end
end

SpArc.OpenControlCenter = OpenControlCenter

---------------------------------------------------------------------------------------
--                  MINIMAP BUTTON & ICON (SpArcMinimapButton)                       --
---------------------------------------------------------------------------------------
local minimapBtn = nil

local function UpdateMinimapButtonPosition()
  if not minimapBtn or not _G.Minimap then return end
  local parent = minimapBtn:GetParent()
  if parent and parent ~= _G.Minimap and parent:GetName() and parent:GetName():find("WTMinimap") then
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

  local bg = btn:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(btn)
  bg:SetColorTexture(0.06, 0.04, 0.10, 0.95)

  local border = btn:CreateTexture(nil, "BORDER")
  border:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 1)
  border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, -1)
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
    self.border:SetColorTexture(1.0, 0.82, 0.20, 1.0)
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
    self.border:SetColorTexture(0.75, 0.30, 1.0, 0.90)
    if _G.GameTooltip then _G.GameTooltip:Hide() end
  end)

  btn:SetScript("OnDragStart", function(self)
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
      OpenControlCenter(4)
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

CreateSpArcMinimapButton()
SpArc:ApplySmartBossTabBinding()
if _G.C_Timer and _G.C_Timer.After then
  _G.C_Timer.After(1.0, function()
    CreateSpArcMinimapButton()
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
    OpenControlCenter(4)
  elseif cmd == "en" or cmd == "ru" then
    db.visual.lang = cmd:upper()
    SpArc:ApplyVisualLayout()
    if controlFrame and controlFrame:IsShown() then controlFrame:RefreshUI() end
  elseif cmd == "pve" or cmd == "boss" or cmd == "pvp" or cmd == "auto" then
    db.mode = cmd:upper()
  elseif cmd == "import" or cmd == "edit" or cmd == "md" or cmd == "ai" then
    showingAIPrompt = (cmd == "ai")
    OpenControlCenter(2)
  elseif cmd == "visual" or cmd == "hud" then
    OpenControlCenter(3)
  elseif cmd == "always" then
    db.visual.alwaysShowCDs = not db.visual.alwaysShowCDs
  else
    OpenControlCenter(1)
  end
end
