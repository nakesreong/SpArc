---------------------------------------------------------------------------------------
--  SpArc/MacroGen.lua — SpellBook Class & Spec Wrapper Macro Generator
--                       Scans the active SpellBook (Class tab + Active Spec tab) and
--                       generates wrapper macros using a customizable template:
--                         #showtooltip
--                         /stopmacro [flying]
--                         /cast [@target] SpellName
--                       Naming convention:
--                         • Class tab spells: <1st letter of class><N> (w1, p5, r1, d1...)
--                         • Spec tab spells:  <1st letter of spec><1st letter of class><N>
--                                             (sp1, ar1, fd1, aw1, fw1, dp1, hp1...)
--                       Placement policy:
--                         • Creates in Character Macros first (up to 30 slots).
--                         • Automatically overflows to General (Account) Macros (up to 120)
--                           when Character Macro slots are full.
--                         • NEVER overwrites or deletes existing macros.
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc or _G.SparkArc or {}
_G.SpArc = SpArc
_G.SparkArc = SpArc

local CreateFrame = _G.CreateFrame
local UnitClass = _G.UnitClass
local GetSpecialization = _G.GetSpecialization
local GetSpecializationInfo = _G.GetSpecializationInfo
local GetNumMacros = _G.GetNumMacros
local GetMacroInfo = _G.GetMacroInfo
local GetMacroIndexByName = _G.GetMacroIndexByName
local CreateMacro = _G.CreateMacro
local InCombatLockdown = _G.InCombatLockdown
local C_SpellBook = _G.C_SpellBook
local C_Spell = _G.C_Spell
local Enum = _G.Enum
local IsSecret = SpArc.IsSecret

SpArc.DEFAULT_MACRO_TEMPLATE = "#showtooltip\n/stopmacro [flying]\n/cast [@target] spell"

-- Canonical 2-letter prefixes (<Spec1stLetter><Class1stLetter>) by Retail Specialization ID
local SPEC_PREFIX_BY_ID = {
  -- Warrior (w)
  [71]  = "aw", -- Arms Warrior
  [72]  = "fw", -- Fury Warrior
  [73]  = "pw", -- Protection Warrior
  -- Paladin (p)
  [65]  = "hp", -- Holy Paladin
  [66]  = "pp", -- Protection Paladin
  [70]  = "rp", -- Retribution Paladin
  -- Hunter (h)
  [253] = "bh", -- Beast Mastery Hunter
  [254] = "mh", -- Marksmanship Hunter
  [255] = "sh", -- Survival Hunter
  -- Rogue (r)
  [259] = "ar", -- Assassination Rogue
  [260] = "or", -- Outlaw Rogue
  [261] = "sr", -- Subtlety Rogue
  -- Priest (p)
  [256] = "dp", -- Discipline Priest
  [257] = "hp", -- Holy Priest
  [258] = "sp", -- Shadow Priest
  -- Death Knight (d)
  [250] = "bd", -- Blood Death Knight
  [251] = "fd", -- Frost Death Knight
  [252] = "ud", -- Unholy Death Knight
  -- Shaman (s)
  [262] = "es", -- Elemental Shaman
  [263] = "es", -- Enhancement Shaman
  [264] = "rs", -- Restoration Shaman
  -- Mage (m)
  [62]  = "am", -- Arcane Mage
  [63]  = "fm", -- Fire Mage
  [64]  = "fm", -- Frost Mage
  -- Warlock (w)
  [265] = "aw", -- Affliction Warlock
  [266] = "dw", -- Demonology Warlock
  [267] = "dw", -- Destruction Warlock
  -- Monk (m)
  [268] = "bm", -- Brewmaster Monk
  [270] = "mm", -- Mistweaver Monk
  [269] = "wm", -- Windwalker Monk
  -- Druid (d)
  [102] = "bd", -- Balance Druid
  [103] = "fd", -- Feral Druid
  [104] = "gd", -- Guardian Druid
  [105] = "rd", -- Restoration Druid
  -- Demon Hunter (d)
  [577]  = "hd", -- Havoc Demon Hunter
  [581]  = "vd", -- Vengeance Demon Hunter
  [1480] = "dd", -- Devourer Demon Hunter (Midnight)
  -- Evoker (e)
  [1467] = "de", -- Devastation Evoker
  [1468] = "pe", -- Preservation Evoker
  [1473] = "ae", -- Augmentation Evoker
}

local function TrimStr(s)
  if not s or IsSecret(s) or type(s) ~= "string" then return "" end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function SpArc:GetMacroNamingPrefixes()
  local classLoc, classFile = "Class", "WARRIOR"
  if UnitClass then
    local ok, cLoc, cFile = pcall(UnitClass, "player")
    if ok and not IsSecret(cFile) and type(cFile) == "string" and cFile ~= "" then
      classLoc = (not IsSecret(cLoc) and cLoc) or cFile
      classFile = cFile
    end
  end
  local classPrefix = string.lower(string.sub(classFile, 1, 1))

  local specID = nil
  local specLoc = "Spec"
  if GetSpecialization and GetSpecializationInfo then
    local okS, specIdx = pcall(GetSpecialization)
    if okS and not IsSecret(specIdx) and type(specIdx) == "number" and specIdx > 0 then
      local okI, id, name = pcall(GetSpecializationInfo, specIdx)
      if okI and not IsSecret(id) and type(id) == "number" then
        specID = id
        if not IsSecret(name) and type(name) == "string" and name ~= "" then
          specLoc = name
        end
      end
    end
  end

  local specPrefix = (specID and SPEC_PREFIX_BY_ID[specID]) or ("s" .. classPrefix)
  return classPrefix, specPrefix, classLoc, specLoc, classFile, specID
end

function SpArc:FormatMacroFromTemplate(templateStr, spellName)
  local tpl = TrimStr(templateStr)
  if tpl == "" then
    tpl = SpArc.DEFAULT_MACRO_TEMPLATE
  end
  spellName = TrimStr(spellName)
  if spellName == "" then return "" end

  local out
  if tpl:find("%%s") then
    out = tpl:gsub("%%s", spellName)
  elseif tpl:find("<spell>") then
    out = tpl:gsub("<spell>", spellName)
  elseif tpl:find("{spell}") then
    out = tpl:gsub("{spell}", spellName)
  else
    -- Replace trailing or standalone 'spell' token on /cast or /use lines
    local replaced = 0
    out, replaced = tpl:gsub("([/%a][^\n]-%s+)spell(%s*)$", "%1" .. spellName .. "%2")
    if replaced == 0 then
      out, replaced = tpl:gsub("([/%a][^\n]-%s+)spell(%s*\n)", "%1" .. spellName .. "%2")
    end
    if replaced == 0 then
      out = tpl .. "\n/cast [@target] " .. spellName
    end
  end

  if #out > 255 then
    out = string.sub(out, 1, 255)
  end
  return out
end

local function ExtractSpellsFromMacroBody(body, outMap, macroName)
  if not body or IsSecret(body) or type(body) ~= "string" or body == "" then return end
  for rawLine in body:gmatch("[^\r\n]+") do
    local line = TrimStr(rawLine)
    local lowerLine = SpArc.UTF8Lower(line)
    local rest = nil
    if lowerLine:match("^#showtooltip%s+") then
      rest = line:gsub("^#[sS][hH][oO][wW][tT][oO][oO][lL][tT][iI][pP]%s+", "")
    elseif lowerLine:match("^/castsequence%s+") then
      rest = line:gsub("^/[cC][aA][sS][tT][sS][eE][qQ][uU][eE][nN][cC][eE]%s+", "")
    elseif lowerLine:match("^/cast%s+") then
      rest = line:gsub("^/[cC][aA][sS][tT]%s+", "")
    elseif lowerLine:match("^/use%s+") then
      rest = line:gsub("^/[uU][sS][eE]%s+", "")
    elseif lowerLine:find("^/заклинание%s+") then
      rest = line:gsub("^/[^\32]+%s+", "")
    end

    if rest and rest ~= "" then
      for clause in rest:gmatch("[^;]+") do
        local cleaned = clause:gsub("%b[]", "")
        cleaned = cleaned:gsub("^%s*!?", "")
        cleaned = cleaned:gsub("^reset=[^%s]+%s*", "")
        for part in cleaned:gmatch("[^,]+") do
          local sName = TrimStr(part)
          if sName ~= "" and not tonumber(sName) then
            local key = SpArc.UTF8Lower(sName)
            if not outMap[key] then
              outMap[key] = macroName
            end
          end
        end
      end
    end
  end
end

function SpArc:ScanExistingMacros()
  local maxAcc = _G.MAX_ACCOUNT_MACROS or 120
  local maxChar = _G.MAX_CHARACTER_MACROS or 30
  local numAcc, numChar = 0, 0
  if GetNumMacros then
    local ok, a, c = pcall(GetNumMacros)
    if ok then
      numAcc = tonumber(a) or 0
      numChar = tonumber(c) or 0
    end
  end

  local usedNames = {}
  local spellToMacro = {}

  if GetMacroInfo then
    -- Scan Character Macros first (121..150) so character macro names take display priority
    for idx = maxAcc + 1, maxAcc + maxChar do
      local ok, name, _, body = pcall(GetMacroInfo, idx)
      if ok and type(name) == "string" and name ~= "" then
        usedNames[name:lower()] = idx
        ExtractSpellsFromMacroBody(body, spellToMacro, name)
      end
    end
    -- Scan Account / General Macros (1..120)
    for idx = 1, maxAcc do
      local ok, name, _, body = pcall(GetMacroInfo, idx)
      if ok and type(name) == "string" and name ~= "" then
        if not usedNames[name:lower()] then
          usedNames[name:lower()] = idx
        end
        ExtractSpellsFromMacroBody(body, spellToMacro, name)
      end
    end
  end

  return usedNames, spellToMacro, numAcc, maxAcc, numChar, maxChar
end

local function NextFreeMacroName(prefix, startCounter, usedNames)
  local n = startCounter or 1
  while n < 999 do
    local candidate = prefix .. tostring(n)
    local lowerCand = candidate:lower()
    local existsInGame = false
    if GetMacroIndexByName then
      local ok, idx = pcall(GetMacroIndexByName, candidate)
      if ok and type(idx) == "number" and idx > 0 then
        existsInGame = true
      end
    end
    if not usedNames[lowerCand] and not existsInGame then
      usedNames[lowerCand] = -1
      return candidate, n + 1
    end
    n = n + 1
  end
  return prefix .. "999", 1000
end

function SpArc:ScanSpellBookForMacros(opts)
  opts = opts or {}
  local skipExisting = (opts.skipExisting ~= false)
  local includeClass = (opts.includeClass ~= false)
  local includeSpec = (opts.includeSpec ~= false)

  local classPrefix, specPrefix, classLoc, specLoc = SpArc:GetMacroNamingPrefixes()
  local usedNames, spellToMacro, numAcc, maxAcc, numChar, maxChar = SpArc:ScanExistingMacros()

  -- Clone usedNames for dry-run name reservation
  local reservedNames = {}
  for k, v in pairs(usedNames) do
    reservedNames[k] = v
  end

  local entries = {}
  local seenSpells = {}
  local nextCounterByPrefix = {}
  local simChar = numChar
  local simAcc = numAcc

  local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
  local itemTypeSpell = (Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell) or 1
  local itemTypeFuture = (Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.FutureSpell) or 2
  local itemTypeFlyout = (Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Flyout) or 4

  if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo then
    local okNum, numLines = pcall(C_SpellBook.GetNumSpellBookSkillLines)
    numLines = (okNum and tonumber(numLines)) or 0

    for lineIdx = 1, numLines do
      local okLine, lineInfo = pcall(C_SpellBook.GetSpellBookSkillLineInfo, lineIdx)
      if okLine and type(lineInfo) == "table" and not lineInfo.offSpecID and not lineInfo.shouldHide then
        local category = nil
        local prefix = nil
        if lineIdx == 2 and not lineInfo.specID then
          category = "CLASS"
          prefix = classPrefix
        elseif lineIdx >= 3 or lineInfo.specID then
          category = "SPEC"
          if lineInfo.specID and SPEC_PREFIX_BY_ID[lineInfo.specID] then
            prefix = SPEC_PREFIX_BY_ID[lineInfo.specID]
          else
            prefix = specPrefix
          end
        end

        local shouldScanLine = (category == "CLASS" and includeClass) or (category == "SPEC" and includeSpec)
        if shouldScanLine and prefix then
          local offset = tonumber(lineInfo.itemIndexOffset) or 0
          local count = tonumber(lineInfo.numSpellBookItems) or 0

          for slotIdx = offset + 1, offset + count do
            local okItem, itemInfo = pcall(C_SpellBook.GetSpellBookItemInfo, slotIdx, bank)
            if okItem and type(itemInfo) == "table" and not IsSecret(itemInfo) then
              local isPassive = (not IsSecret(itemInfo.isPassive) and itemInfo.isPassive == true) or false
              local isOffSpec = (not IsSecret(itemInfo.isOffSpec) and itemInfo.isOffSpec == true) or false
              local iType = (not IsSecret(itemInfo.itemType) and itemInfo.itemType) or nil
              local spellID = (not IsSecret(itemInfo.spellID) and itemInfo.spellID) or (not IsSecret(itemInfo.actionID) and itemInfo.actionID) or nil

              if not isPassive and spellID and C_Spell and C_Spell.IsSpellPassive then
                local okP, pVal = pcall(C_Spell.IsSpellPassive, spellID)
                if okP and not IsSecret(pVal) and pVal == true then
                  isPassive = true
                end
              end

              if not isPassive and not isOffSpec and iType == itemTypeSpell and iType ~= itemTypeFuture and iType ~= itemTypeFlyout then
                local spellName = TrimStr(itemInfo.name)
                if spellName == "" and spellID and C_Spell and C_Spell.GetSpellName then
                  local okN, nVal = pcall(C_Spell.GetSpellName, spellID)
                  if okN and not IsSecret(nVal) and type(nVal) == "string" then
                    spellName = TrimStr(nVal)
                  end
                end

                if spellName ~= "" then
                  local lowerSpell = SpArc.UTF8Lower(spellName)
                  if not seenSpells[lowerSpell] then
                    seenSpells[lowerSpell] = true
                    local existingMacro = spellToMacro[lowerSpell]
                    local willSkip = (skipExisting and existingMacro ~= nil)

                    local assignedName = nil
                    local targetPool = nil
                    if not willSkip then
                      local startIdx = nextCounterByPrefix[prefix] or 1
                      assignedName, nextCounterByPrefix[prefix] = NextFreeMacroName(prefix, startIdx, reservedNames)
                      if simChar < maxChar then
                        targetPool = "CHAR"
                        simChar = simChar + 1
                      elseif simAcc < maxAcc then
                        targetPool = "ACC"
                        simAcc = simAcc + 1
                      else
                        targetPool = "FULL"
                      end
                    end

                    entries[#entries + 1] = {
                      spellID = spellID,
                      spellName = spellName,
                      category = category,
                      tabName = lineInfo.name or category,
                      prefix = prefix,
                      macroName = assignedName,
                      existingMacro = existingMacro,
                      skipped = willSkip,
                      targetPool = targetPool,
                    }
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  return {
    entries = entries,
    classPrefix = classPrefix,
    specPrefix = specPrefix,
    classLoc = classLoc,
    specLoc = specLoc,
    numAcc = numAcc,
    maxAcc = maxAcc,
    numChar = numChar,
    maxChar = maxChar,
  }
end

function SpArc:GenerateClassMacros(opts)
  opts = opts or {}
  if InCombatLockdown and InCombatLockdown() then
    return {
      ok = false,
      errorMsg = SpArc:L("M9_ERR_COMBAT"),
      createdChar = 0,
      createdAcc = 0,
      skipped = 0,
      failedFull = 0,
      logLines = { "|cffff4040" .. SpArc:L("M9_ERR_COMBAT") .. "|r" },
    }
  end

  local templateStr = opts.template or SpArc.DEFAULT_MACRO_TEMPLATE
  local scan = SpArc:ScanSpellBookForMacros(opts)
  local usedNames, _, _, maxAcc, _, maxChar = SpArc:ScanExistingMacros()
  local nextCounterByPrefix = {}

  local createdChar = 0
  local createdAcc = 0
  local skippedCount = 0
  local failedFull = 0
  local logLines = {}

  for _, item in ipairs(scan.entries) do
    if item.skipped then
      skippedCount = skippedCount + 1
      logLines[#logLines + 1] = string.format(
        "|cff888899[SKIP]|r %s  |cffaaaaaa(%s: %s)|r",
        item.spellName,
        SpArc:L("M9_ALREADY_HAS"),
        tostring(item.existingMacro)
      )
    else
      local curAcc, curChar = 0, 0
      if GetNumMacros then
        local okC, a, c = pcall(GetNumMacros)
        if okC then
          curAcc = tonumber(a) or 0
          curChar = tonumber(c) or 0
        end
      end

      local perChar = nil
      local poolTag = nil
      if curChar < maxChar then
        perChar = true
        poolTag = "|cff00ff96[CHAR]|r"
      elseif curAcc < maxAcc then
        perChar = false
        poolTag = "|cff00ccff[GENERAL]|r"
      end

      if perChar == nil then
        failedFull = failedFull + 1
        logLines[#logLines + 1] = string.format(
          "|cffff4040[FULL]|r %s — %s",
          item.spellName,
          SpArc:L("M9_SLOTS_FULL")
        )
      else
        local startIdx = nextCounterByPrefix[item.prefix] or 1
        local mName, nextIdx = NextFreeMacroName(item.prefix, startIdx, usedNames)
        nextCounterByPrefix[item.prefix] = nextIdx

        local mBody = SpArc:FormatMacroFromTemplate(templateStr, item.spellName)
        local okCreate, createdID = pcall(CreateMacro, mName, "INV_MISC_QUESTIONMARK", mBody, perChar)
        if okCreate and type(createdID) == "number" and createdID > 0 then
          if perChar then
            createdChar = createdChar + 1
          else
            createdAcc = createdAcc + 1
          end
          logLines[#logLines + 1] = string.format(
            "%s |cffffd100%s|r -> |cff00ff00%s|r  |cffaaaaaa[%s]|r",
            poolTag,
            mName,
            item.spellName,
            item.tabName
          )
        else
          failedFull = failedFull + 1
          logLines[#logLines + 1] = string.format(
            "|cffff4040[ERR]|r %s -> %s",
            mName,
            item.spellName
          )
        end
      end
    end
  end

  if SpArc.ScanActionSlotsAndSpells then
    pcall(SpArc.ScanActionSlotsAndSpells, SpArc, true)
  end

  return {
    ok = true,
    createdChar = createdChar,
    createdAcc = createdAcc,
    skipped = skippedCount,
    failedFull = failedFull,
    logLines = logLines,
  }
end

function SpArc:BuildMacroGenPreviewText(opts)
  local scan = SpArc:ScanSpellBookForMacros(opts)
  local lines = {}
  local toCreateChar = 0
  local toCreateAcc = 0
  local toSkip = 0
  local toOverflowFail = 0

  for _, item in ipairs(scan.entries) do
    if item.skipped then
      toSkip = toSkip + 1
      lines[#lines + 1] = string.format(
        "|cff777788[SKIP] %-4s|r %s  |cff888899(%s: |cffffd100%s|cff888899)|r",
        item.prefix .. "*",
        item.spellName,
        SpArc:L("M9_ALREADY_HAS"),
        tostring(item.existingMacro)
      )
    else
      local poolBadge
      if item.targetPool == "CHAR" then
        toCreateChar = toCreateChar + 1
        poolBadge = "|cff00ff96[CHAR]|r   "
      elseif item.targetPool == "ACC" then
        toCreateAcc = toCreateAcc + 1
        poolBadge = "|cff00ccff[GENERAL]|r"
      else
        toOverflowFail = toOverflowFail + 1
        poolBadge = "|cffff4040[FULL]|r   "
      end
      lines[#lines + 1] = string.format(
        "%s |cffffd100%-5s|r -> |cffffffff%s|r  |cff888899(%s)|r",
        poolBadge,
        item.macroName or "?",
        item.spellName,
        item.tabName
      )
    end
  end

  local header = string.format(
    SpArc:L("M9_PREVIEW_HEADER"),
    #scan.entries,
    toCreateChar,
    toCreateAcc,
    toSkip
  )
  if toOverflowFail > 0 then
    header = header .. "\n|cffff4040" .. string.format(SpArc:L("M9_OVERFLOW_WARN"), toOverflowFail) .. "|r"
  end

  return header .. "\n\n" .. table.concat(lines, "\n"), scan
end

---------------------------------------------------------------------------------------
--  MODULE 9 UI BUILDER & REFRESH (Called from SpArc.lua OpenControlCenter)
---------------------------------------------------------------------------------------
function SpArc:BuildMacroGenPage(p9, ui, helpers)
  local ApplyCyrFont = helpers.ApplyCyrFont
  local CreateElvButton = helpers.CreateElvButton
  local RegisterGroupBox = helpers.RegisterGroupBox
  local SetBackdropFlat = helpers.SetBackdropFlat
  local CreateElvCheck = helpers.CreateElvCheck
  local controlFrame = helpers.controlFrame

  local db = SpArc:EnsureDB()
  if db.visual.macroGenSkipExisting == nil then db.visual.macroGenSkipExisting = true end
  if db.visual.macroGenIncludeClass == nil then db.visual.macroGenIncludeClass = true end
  if db.visual.macroGenIncludeSpec == nil then db.visual.macroGenIncludeSpec = true end
  if type(db.visual.macroGenTemplate) ~= "string" or db.visual.macroGenTemplate == "" then
    db.visual.macroGenTemplate = SpArc.DEFAULT_MACRO_TEMPLATE
  end

  ui.m9Title = p9:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(ui.m9Title, 15)
  ui.m9Title:SetPoint("TOPLEFT", 0, 0)
  ui.m9Title:SetTextColor(1, 0.85, 0.25, 1)

  -- Top Summary GroupBox
  local m9InfoBox = RegisterGroupBox(p9, "M9_GRP_INFO", 0, -32, 640, 74)
  ui.m9SummaryText = m9InfoBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(ui.m9SummaryText, 12)
  ui.m9SummaryText:SetPoint("TOPLEFT", 14, -10)
  ui.m9SummaryText:SetPoint("TOPRIGHT", -14, -10)
  ui.m9SummaryText:SetJustifyH("LEFT")
  ui.m9SummaryText:SetSpacing(4)

  -- Template & Filters GroupBox
  local m9TplBox = RegisterGroupBox(p9, "M9_GRP_TPL", 0, -118, 640, 148)

  local tplEditFrame = CreateFrame("Frame", nil, m9TplBox, "BackdropTemplate")
  tplEditFrame:SetPoint("TOPLEFT", 14, -12)
  tplEditFrame:SetSize(290, 84)
  SetBackdropFlat(tplEditFrame, 0.03, 0.03, 0.05, 0.98, 0.24, 0.24, 0.34, 1.0)

  ui.m9TplEdit = CreateFrame("EditBox", nil, tplEditFrame)
  ui.m9TplEdit:SetMultiLine(true)
  ui.m9TplEdit:SetFontObject("ChatFontNormal")
  ApplyCyrFont(ui.m9TplEdit, 12)
  ui.m9TplEdit:SetPoint("TOPLEFT", 8, -8)
  ui.m9TplEdit:SetPoint("BOTTOMRIGHT", -8, 8)
  ui.m9TplEdit:SetAutoFocus(false)
  ui.m9TplEdit:SetText(db.visual.macroGenTemplate or SpArc.DEFAULT_MACRO_TEMPLATE)
  ui.m9TplEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  ui.m9TplEdit:SetScript("OnTextChanged", function(self, userInput)
    if userInput then
      local d = SpArc:EnsureDB()
      d.visual.macroGenTemplate = self:GetText()
    end
  end)

  ui.m9ResetTplBtn = CreateElvButton(m9TplBox, 142, 24, "")
  ui.m9ResetTplBtn:SetPoint("TOPLEFT", 14, -102)
  ui.m9ResetTplBtn:SetScript("OnClick", function()
    local d = SpArc:EnsureDB()
    d.visual.macroGenTemplate = SpArc.DEFAULT_MACRO_TEMPLATE
    ui.m9TplEdit:SetText(SpArc.DEFAULT_MACRO_TEMPLATE)
    ui.m9LastGenReport = nil
    controlFrame:RefreshUI()
  end)

  ui.m9MouseoverTplBtn = CreateElvButton(m9TplBox, 142, 24, "")
  ui.m9MouseoverTplBtn:SetPoint("LEFT", ui.m9ResetTplBtn, "RIGHT", 6, 0)
  ui.m9MouseoverTplBtn:SetScript("OnClick", function()
    local d = SpArc:EnsureDB()
    local moTpl = "#showtooltip\n/stopmacro [flying]\n/cast [@mouseover,harm,nodead][@target] spell"
    d.visual.macroGenTemplate = moTpl
    ui.m9TplEdit:SetText(moTpl)
    ui.m9LastGenReport = nil
    controlFrame:RefreshUI()
  end)

  local function OnFilterChanged()
    ui.m9LastGenReport = nil
    controlFrame:RefreshUI()
  end

  local cSkip = CreateElvCheck(m9TplBox, "CK_M9_SKIP_EXISTING", "macroGenSkipExisting", 318, -14, false, false, OnFilterChanged)
  cSkip:SetWidth(305)
  local cClass = CreateElvCheck(m9TplBox, "CK_M9_INC_CLASS", "macroGenIncludeClass", 318, -46, false, false, OnFilterChanged)
  cClass:SetWidth(305)
  local cSpec = CreateElvCheck(m9TplBox, "CK_M9_INC_SPEC", "macroGenIncludeSpec", 318, -78, false, false, OnFilterChanged)
  cSpec:SetWidth(305)

  -- Preview & Action Log GroupBox
  local m9PreviewBox = RegisterGroupBox(p9, "M9_GRP_PREVIEW", 0, -278, 640, 240)

  ui.m9PreviewBtn = CreateElvButton(m9PreviewBox, 210, 28, "")
  ui.m9PreviewBtn:SetPoint("TOPLEFT", 14, -10)
  ui.m9PreviewBtn:SetScript("OnClick", function()
    ui.m9LastGenReport = nil
    controlFrame:RefreshUI()
  end)

  ui.m9GenerateBtn = CreateElvButton(m9PreviewBox, 250, 28, "")
  ui.m9GenerateBtn:SetPoint("LEFT", ui.m9PreviewBtn, "RIGHT", 10, 0)
  ui.m9GenerateBtn:SetScript("OnClick", function()
    local d = SpArc:EnsureDB()
    local tpl = ui.m9TplEdit:GetText()
    d.visual.macroGenTemplate = tpl
    local res = SpArc:GenerateClassMacros({
      template = tpl,
      skipExisting = (d.visual.macroGenSkipExisting ~= false),
      includeClass = (d.visual.macroGenIncludeClass ~= false),
      includeSpec = (d.visual.macroGenIncludeSpec ~= false),
    })
    if not res.ok then
      print("|cffa335eeSpArc:|r |cffff4040" .. tostring(res.errorMsg) .. "|r")
      ui.m9LastGenReport = "|cffff4040" .. tostring(res.errorMsg) .. "|r"
    else
      local summaryMsg = string.format(
        SpArc:L("MSG_M9_DONE"),
        res.createdChar,
        res.createdAcc,
        res.skipped
      )
      print(summaryMsg)
      ui.m9LastGenReport = summaryMsg .. "\n\n" .. table.concat(res.logLines or {}, "\n")
    end
    controlFrame:RefreshUI()
  end)

  ui.m9OpenBlizzMacroBtn = CreateElvButton(m9PreviewBox, 132, 28, "")
  ui.m9OpenBlizzMacroBtn:SetPoint("LEFT", ui.m9GenerateBtn, "RIGHT", 10, 0)
  ui.m9OpenBlizzMacroBtn:SetScript("OnClick", function()
    if _G.ShowMacroFrame then
      pcall(_G.ShowMacroFrame)
    end
  end)

  local logFrame = CreateFrame("Frame", nil, m9PreviewBox, "BackdropTemplate")
  logFrame:SetPoint("TOPLEFT", 14, -44)
  logFrame:SetPoint("BOTTOMRIGHT", -14, 10)
  SetBackdropFlat(logFrame, 0.03, 0.03, 0.05, 0.98, 0.22, 0.22, 0.30, 1.0)

  local logScroll = CreateFrame("ScrollFrame", "SpArcMacroGenScroll", logFrame, "UIPanelScrollFrameTemplate")
  logScroll:SetPoint("TOPLEFT", 8, -8)
  logScroll:SetPoint("BOTTOMRIGHT", -28, 8)

  ui.m9LogEdit = CreateFrame("EditBox", nil, logScroll)
  ui.m9LogEdit:SetMultiLine(true)
  ui.m9LogEdit:SetFontObject("ChatFontNormal")
  ApplyCyrFont(ui.m9LogEdit, 11)
  ui.m9LogEdit:SetWidth(570)
  ui.m9LogEdit:SetAutoFocus(false)
  ui.m9LogEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  logScroll:SetScrollChild(ui.m9LogEdit)
end

function SpArc:RefreshMacroGenPage(ui)
  if not ui or not ui.m9Title then return end
  local db = SpArc:EnsureDB()

  ui.m9Title:SetText(SpArc:L("M9_TITLE"))
  ui.m9ResetTplBtn:SetText(SpArc:L("M9_TPL_DEFAULT_BTN"))
  ui.m9MouseoverTplBtn:SetText(SpArc:L("M9_TPL_MO_BTN"))
  ui.m9PreviewBtn:SetText(SpArc:L("M9_PREVIEW_BTN"))
  ui.m9GenerateBtn:SetText(SpArc:L("M9_GENERATE_BTN"))
  ui.m9OpenBlizzMacroBtn:SetText(SpArc:L("M9_OPEN_MACROS_BTN"))

  if not ui.m9TplEdit:HasFocus() then
    ui.m9TplEdit:SetText(db.visual.macroGenTemplate or SpArc.DEFAULT_MACRO_TEMPLATE)
  end

  local opts = {
    template = db.visual.macroGenTemplate or SpArc.DEFAULT_MACRO_TEMPLATE,
    skipExisting = (db.visual.macroGenSkipExisting ~= false),
    includeClass = (db.visual.macroGenIncludeClass ~= false),
    includeSpec = (db.visual.macroGenIncludeSpec ~= false),
  }

  local previewText, scan = SpArc:BuildMacroGenPreviewText(opts)
  ui.m9SummaryText:SetText(string.format(
    SpArc:L("M9_SUMMARY_TEXT"),
    scan.classLoc,
    scan.classPrefix .. "1, " .. scan.classPrefix .. "2...",
    scan.specLoc,
    scan.specPrefix .. "1, " .. scan.specPrefix .. "2...",
    scan.numChar,
    scan.maxChar,
    scan.numAcc,
    scan.maxAcc
  ))

  if ui.m9LastGenReport then
    ui.m9LogEdit:SetText(ui.m9LastGenReport)
  else
    ui.m9LogEdit:SetText(previewText)
  end
end
