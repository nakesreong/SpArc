---------------------------------------------------------------------------------------
--  SpArc/Scanner.lua — Bartender4 Keybind, ActionSlot & Macro Scanner
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc

local GetTime = _G.GetTime
local GetActionInfo = _G.GetActionInfo
local GetActionText = _G.GetActionText
local GetActionTexture = _G.GetActionTexture
local GetMacroBody = _G.GetMacroBody
local GetBindingKey = _G.GetBindingKey
local C_Spell = _G.C_Spell
local C_ActionBar = _G.C_ActionBar
local C_AssistedCombat = _G.C_AssistedCombat
local pcall = _G.pcall
local ipairs = _G.ipairs
local pairs = _G.pairs
local tonumber = _G.tonumber
local tostring = _G.tostring
local type = _G.type

local IsSecret = SpArc.IsSecret
local SafeBool = SpArc.SafeBool
local Trim = SpArc.Trim
local SPELL_DEFS = SpArc.SPELL_DEFS
local ACTIVE_SLOTS = SpArc.ACTIVE_SLOTS
local SLOT_DEFAULT_KEYBIND = SpArc.SLOT_DEFAULT_KEYBIND
local ACTION_BAR_RANGES = SpArc.ACTION_BAR_RANGES
local CLICKCAST_SHORT = SpArc.CLICKCAST_SHORT
local st = SpArc.state

local PVP_TALENT_SPELL_IDS = {
  [211522] = true, -- Psyfiend (Ментальный демон)
  [236077] = true, -- Disarm (Обезоруживание)
  [198817] = true, -- Sharpen Blade (Заточка клинка)
  [328530] = true, -- Divine Ascension (Божественное вознесение)
  [213610] = true, -- Holy Ward (Священный оберег)
  [236320] = true, -- War Banner (Боевое знамя)
}

function SpArc:IsPvPActiveNow()
  if _G.C_PvP then
    if _G.C_PvP.IsArena and SafeBool(_G.C_PvP.IsArena) then return true end
    if _G.C_PvP.IsBattleground and SafeBool(_G.C_PvP.IsBattleground) then return true end
    if _G.C_PvP.IsPVPMap and SafeBool(_G.C_PvP.IsPVPMap) then return true end
  end
  if _G.IsInInstance then
    local ok, inInst, instType = pcall(_G.IsInInstance)
    if ok and not IsSecret(inInst) and inInst and not IsSecret(instType) then
      return (instType == "pvp" or instType == "arena")
    end
  end
  if _G.C_PvP and _G.C_PvP.IsWarModeActive and SafeBool(_G.C_PvP.IsWarModeActive) then
    return true
  end
  return false
end

local function IsSpellIDKnown(id)
  if not id or type(id) ~= "number" or id <= 0 then return false end
  if PVP_TALENT_SPELL_IDS[id] and not SpArc:IsPvPActiveNow() then
    return false
  end
  if _G.IsPlayerSpell and SafeBool(_G.IsPlayerSpell, id) then return true end
  if _G.IsSpellKnownOrOverridesKnown and SafeBool(_G.IsSpellKnownOrOverridesKnown, id) then return true end
  if _G.IsSpellKnown and SafeBool(_G.IsSpellKnown, id) then return true end
  if _G.C_SpellBook and _G.C_SpellBook.IsSpellInSpellBook and SafeBool(_G.C_SpellBook.IsSpellInSpellBook, id) then return true end
  return false
end

local MACRO_NAME_KEYBINDS = {
  M1 = "M1", M2 = "M2", M3 = "B3", B3 = "B3", SB3 = "SB3", CB3 = "CB3", AB3 = "AB3", M4 = "M4", M5 = "M5",
  SM1 = "SM1", SM2 = "SM2", CM1 = "CM1", CM2 = "CM2", AM1 = "AM1", AM2 = "AM2",
  ["1"] = "1", ["2"] = "2", ["3"] = "3", ["4"] = "4", ["5"] = "5",
  Q = "Q", SQ = "SQ", E = "E", SE = "SE", R = "R", SR = "SR",
  F = "F", SF = "SF", T = "T", ST = "ST", C = "C", V = "V", SV = "SV", Z = "Z", SZ = "SZ", G = "G",
}

local function CompactKey(raw)
  if not raw or raw == "" then return nil end
  local s = raw:upper()
  s = s:gsub("SHIFT%-", "S")
  s = s:gsub("CTRL%-", "C")
  s = s:gsub("ALT%-", "A")
  s = s:gsub("BUTTON1", "M1"):gsub("MOUSE1", "M1"):gsub("LEFTBUTTON", "M1")
  s = s:gsub("BUTTON2", "M2"):gsub("MOUSE2", "M2"):gsub("RIGHTBUTTON", "M2")
  s = s:gsub("BUTTON3", "B3"):gsub("MOUSE3", "B3"):gsub("MIDDLEBUTTON", "B3")
  s = s:gsub("BUTTON4", "M4"):gsub("MOUSE4", "M4")
  s = s:gsub("BUTTON5", "M5"):gsub("MOUSE5", "M5")
  s = s:gsub("MOUSEWHEELUP", "WU"):gsub("MOUSEWHEELDOWN", "WD")
  s = s:gsub("NUMPAD", "N")
  s = s:gsub("SPACE", "SP")
  if s:byte(1) and s:byte(1) > 127 then
    return nil
  end
  return s
end

local function SlotToBindingCommand(slot)
  for _, r in ipairs(ACTION_BAR_RANGES) do
    if slot >= r.base and slot < r.base + r.count then
      return r.bind .. (slot - r.base + 1)
    end
  end
  return nil
end

function SpArc:GetSlotKeybind(slot)
  if not slot or slot < 1 then return nil end
  -- Slots 1 & 2 use M1 / M2 via Mouselook override in Combat Camera Click-Cast mode
  if (slot == 1 or slot == 2) and SpArc.IsCamClickCastEnabled and SpArc:IsCamClickCastEnabled() and SpArc.COMBAT_CAM_SLOT_KEYBINDS and SpArc.COMBAT_CAM_SLOT_KEYBINDS[slot] then
    return SpArc.COMBAT_CAM_SLOT_KEYBINDS[slot]
  end
  local cmd = SlotToBindingCommand(slot)

  -- 1. Check live WoW & Bartender4 bindings FIRST so user changes in /kb always win
  if cmd and GetBindingKey then
    local ok, k1, k2 = pcall(GetBindingKey, cmd)
    if ok then
      local k = (not IsSecret(k1) and k1) or (not IsSecret(k2) and k2)
      if k and k ~= "" then
        local c = CompactKey(k)
        if c and c ~= "" then return c end
      end
    end
  end

  local btBtn = _G["BT4Button" .. slot]
  if btBtn then
    if GetBindingKey then
      local okK, bk1, bk2 = pcall(GetBindingKey, "CLICK BT4Button" .. slot .. ":Keybind")
      if okK then
        local k = (not IsSecret(bk1) and bk1) or (not IsSecret(bk2) and bk2)
        if k and k ~= "" then
          local c = CompactKey(k)
          if c and c ~= "" then return c end
        end
      end
      local okB, k1, k2 = pcall(GetBindingKey, "CLICK BT4Button" .. slot .. ":LeftButton")
      if okB then
        local k = (not IsSecret(k1) and k1) or (not IsSecret(k2) and k2)
        if k and k ~= "" then
          local c = CompactKey(k)
          if c and c ~= "" then return c end
        end
      end
    end
    if btBtn.GetHotkey then
      local okHK, hk = pcall(btBtn.GetHotkey, btBtn)
      if okHK and not IsSecret(hk) and type(hk) == "string" and hk ~= "" then
        local c = CompactKey(hk)
        if c and c ~= "" then return c end
      end
    end
    if btBtn.HotKey and btBtn.HotKey.GetText then
      local okT, txt = pcall(btBtn.HotKey.GetText, btBtn.HotKey)
      if okT and not IsSecret(txt) and type(txt) == "string" and txt ~= "" and txt ~= _G.RANGE_INDICATOR then
        local c = CompactKey(txt)
        if c and c ~= "" then return c end
      end
    end
  end

  -- 2. Fallback to Combat Camera default slot keybinds (slots 3..8) or CombatModeDB if unbound
  if SpArc.IsCamClickCastEnabled and SpArc:IsCamClickCastEnabled() and SpArc.COMBAT_CAM_SLOT_KEYBINDS and SpArc.COMBAT_CAM_SLOT_KEYBINDS[slot] then
    return SpArc.COMBAT_CAM_SLOT_KEYBINDS[slot]
  end

  if cmd then
    local binds = nil
    local cm = _G.CM
    if cm and cm.DB then
      local loc = (cm.GetBindingsLocation and cm.GetBindingsLocation()) or "char"
      local root = cm.DB[loc]
      binds = root and root.bindings
    end
    if not binds and type(_G.CombatModeDB) == "table" then
      local uName = _G.UnitName and _G.UnitName("player")
      local rName = _G.GetRealmName and _G.GetRealmName()
      local charKey = (uName and rName) and (uName .. " - " .. rName) or nil
      if charKey and _G.CombatModeDB.char and _G.CombatModeDB.char[charKey] and _G.CombatModeDB.char[charKey].bindings then
        binds = _G.CombatModeDB.char[charKey].bindings
      elseif _G.CombatModeDB.global and _G.CombatModeDB.global.bindings then
        binds = _G.CombatModeDB.global.bindings
      end
    end
    if type(binds) == "table" then
      for dbKey, shortName in pairs(CLICKCAST_SHORT) do
        local b = binds[dbKey]
        if b and b.enabled ~= false and b.value == cmd then
          return shortName
        end
      end
    end
  end

  if GetActionText then
    local okT, mName = pcall(GetActionText, slot)
    if okT and not IsSecret(mName) and type(mName) == "string" and mName ~= "" then
      local up = Trim(mName):upper()
      if MACRO_NAME_KEYBINDS[up] then
        return MACRO_NAME_KEYBINDS[up]
      end
    end
  end

  if _G.UnitClass then
    local okC, _, cls = pcall(_G.UnitClass, "player")
    if okC and not IsSecret(cls) and cls == "PRIEST" then
      return SLOT_DEFAULT_KEYBIND[slot]
    end
  end
  return nil
end

local function BuildAssistedSlotSet()
  local set = {}
  if C_ActionBar and C_ActionBar.HasAssistedCombatActionButtons and C_ActionBar.FindAssistedCombatActionButtons then
    local okH, has = pcall(C_ActionBar.HasAssistedCombatActionButtons)
    if okH and not IsSecret(has) and has then
      local ok, slots = pcall(C_ActionBar.FindAssistedCombatActionButtons)
      if ok and type(slots) == "table" and not IsSecret(slots) then
        for _, v in pairs(slots) do
          if not IsSecret(v) and type(v) == "number" and v > 0 then
            set[v] = true
          end
        end
      end
    end
  end
  return set
end

local function ExtractMacroCastLines(body)
  local tooltipLines = {}
  local castLines = {}
  if type(body) ~= "string" or body == "" then
    return tooltipLines, castLines
  end
  for rawLine in body:gmatch("[^\r\n]+") do
    local line = Trim(rawLine)
    local lower = line:lower()
    if lower:match("^#showtooltip") then
      tooltipLines[#tooltipLines + 1] = line
    elseif not lower:match("^/stopmacro") and not lower:match("^/cancelaura") and not lower:match("^/stopcasting") then
      if lower:match("^/cast") or lower:match("^/use") or lower:match("^/castrandom") or lower:match("^/castsequence") then
        castLines[#castLines + 1] = line
      end
    end
  end
  return tooltipLines, castLines
end

function SpArc:ScanActionSlotsAndSpells(force)
  local now = GetTime()
  if not force and (now - st.lastSlotScanAt) < 1.5 then
    return
  end
  st.lastSlotScanAt = now

  local explicitOwnerBySpellID = {}
  for k, def in pairs(SPELL_DEFS) do
    for _, id in ipairs(def.ids or {}) do
      if not explicitOwnerBySpellID[id] or def.overrideOf or def.procOnly or k == "VOID_BOLT" or k == "MIND_FLAY_INSANITY" then
        explicitOwnerBySpellID[id] = k
      end
    end
  end

  for k, def in pairs(SPELL_DEFS) do
    local idSet = {}
    local resolvedID, resolvedIcon
    local isKnown = false
    for _, id in ipairs(def.ids or {}) do
      idSet[id] = true
      local eid = id
      if C_Spell and C_Spell.GetOverrideSpell then
        local okO, over = pcall(C_Spell.GetOverrideSpell, id)
        if okO and type(over) == "number" and not IsSecret(over) and over > 0 then
          local owner = explicitOwnerBySpellID[over]
          if not owner or owner == k then
            idSet[over] = true
            eid = over
          end
        end
      end
      if C_Spell and C_Spell.GetBaseSpell then
        local okB, base = pcall(C_Spell.GetBaseSpell, id)
        if okB and type(base) == "number" and not IsSecret(base) and base > 0 then
          local owner = explicitOwnerBySpellID[base]
          if not owner or owner == k then
            idSet[base] = true
          end
        end
      end
      if not isKnown and (IsSpellIDKnown(eid) or IsSpellIDKnown(id)) then
        isKnown = true
        resolvedID = eid
        if C_Spell and C_Spell.GetSpellInfo then
          local okI, info = pcall(C_Spell.GetSpellInfo, eid)
          if okI and type(info) == "table" and not IsSecret(info.iconID) and info.iconID then
            resolvedIcon = info.iconID
          end
        end
      end
    end
    if C_Spell and C_Spell.GetSpellInfo then
      for _, nm in ipairs(def.names or {}) do
        local ok, info = pcall(C_Spell.GetSpellInfo, nm)
        if ok and type(info) == "table" and not IsSecret(info.spellID) and info.spellID then
          local owner = explicitOwnerBySpellID[info.spellID]
          if not owner or owner == k then
            idSet[info.spellID] = true
            if IsSpellIDKnown(info.spellID) then
              isKnown = true
              if not resolvedID then
                resolvedID = info.spellID
                resolvedIcon = not IsSecret(info.iconID) and info.iconID or nil
              end
            end
          end
        end
      end
      if not resolvedID then
        for _, id in ipairs(def.ids or {}) do
          local eid = id
          if C_Spell.GetOverrideSpell then
            local okO, over = pcall(C_Spell.GetOverrideSpell, id)
            if okO and type(over) == "number" and not IsSecret(over) and over > 0 then
              local owner = explicitOwnerBySpellID[over]
              if not owner or owner == k then
                eid = over
              end
            end
          end
          local ok, info = pcall(C_Spell.GetSpellInfo, eid)
          if ok and type(info) == "table" and not IsSecret(info.iconID) and info.iconID then
            resolvedID = eid
            resolvedIcon = info.iconID
            break
          end
        end
      end
    end
    def.idSet = idSet
    def.isKnown = isKnown
    def.resolvedIcon = resolvedIcon
    def.liveSpellID = resolvedID or (def.ids and def.ids[1])
    def.liveIcon = resolvedIcon or def.fallbackIcon
  end

  local assistedSlots = BuildAssistedSlotSet()
  local spellIDToSlot = {}
  local slotDirectSpellID = {}
  local tooltipLinesBySlot = {}
  local castLinesBySlot = {}
  local GetMacroSpell = _G.GetMacroSpell

  local function HasKeybind(s)
    local k = SpArc:GetSlotKeybind(s)
    return (k and k ~= "") and true or false
  end

  local function AssignSpellSlot(sid, s)
    if not sid or not s then return end
    if not slotDirectSpellID[s] then
      slotDirectSpellID[s] = sid
    end
    local prev = spellIDToSlot[sid]
    if not prev or (not HasKeybind(prev) and HasKeybind(s)) then
      spellIDToSlot[sid] = s
    end
  end

  local isBonusBarActive = _G.HasBonusActionBar and SafeBool(_G.HasBonusActionBar) or false
  for _, slot in ipairs(ACTIVE_SLOTS) do
    if not assistedSlots[slot] then
      local btBtn = (not (isBonusBarActive and slot <= 12)) and _G["BT4Button" .. slot] or nil
      if btBtn and btBtn.GetSpellId then
        local okS, btSpellID = pcall(btBtn.GetSpellId, btBtn)
        if okS and not IsSecret(btSpellID) and type(btSpellID) == "number" and btSpellID > 0 then
          AssignSpellSlot(btSpellID, slot)
        end
      end

      if GetActionInfo then
        local ok, aType, aID, aSubType = pcall(GetActionInfo, slot)
        if ok and not IsSecret(aType) and aType then
          if aType == "spell" and not IsSecret(aID) and type(aID) == "number" and aID > 0 then
            AssignSpellSlot(aID, slot)
          elseif aType == "macro" then
            if not IsSecret(aSubType) and aSubType == "spell" and not IsSecret(aID) and type(aID) == "number" and aID > 0 then
              AssignSpellSlot(aID, slot)
            elseif GetMacroSpell and not IsSecret(aID) and type(aID) == "number" and aID > 0 then
              local okMS, msID = pcall(GetMacroSpell, aID)
              if okMS and not IsSecret(msID) and type(msID) == "number" and msID > 0 then
                AssignSpellSlot(msID, slot)
              end
            end

            local body = nil
            local GetMacroInfo = _G.GetMacroInfo
            if GetActionText and GetMacroBody then
              local okT, mName = pcall(GetActionText, slot)
              if okT and not IsSecret(mName) and type(mName) == "string" and mName ~= "" then
                -- Prefer character-specific macros (indices 121..150) when names collide with account macros
                if GetMacroInfo then
                  local maxAcc = _G.MAX_ACCOUNT_MACROS or 120
                  local maxChar = _G.MAX_CHARACTER_MACROS or 30
                  for mIdx = maxAcc + maxChar, maxAcc + 1, -1 do
                    local okMI, miName, _, miBody = pcall(GetMacroInfo, mIdx)
                    if okMI and not IsSecret(miName) and miName == mName and not IsSecret(miBody) and type(miBody) == "string" and miBody ~= "" then
                      body = miBody
                      break
                    end
                  end
                end
                if not body then
                  local okB, b = pcall(GetMacroBody, mName)
                  if okB and not IsSecret(b) and type(b) == "string" then
                    body = b
                  end
                end
              end
            end
            if not body and GetMacroBody and not IsSecret(aID) and type(aID) == "number" and aID > 0 then
              local okB, b = pcall(GetMacroBody, aID)
              if okB and not IsSecret(b) and type(b) == "string" then
                body = b
              end
            end
            if body then
              local tLines, cLines = ExtractMacroCastLines(body)
              tooltipLinesBySlot[slot] = tLines
              castLinesBySlot[slot] = cLines
            end
          end
        end
      end
    end
  end

  for _, def in pairs(SPELL_DEFS) do
    local foundSlot = nil

    if def.liveSpellID and spellIDToSlot[def.liveSpellID] and HasKeybind(spellIDToSlot[def.liveSpellID]) then
      foundSlot = spellIDToSlot[def.liveSpellID]
    end
    if not foundSlot and def.idSet then
      for sid, _ in pairs(def.idSet) do
        if spellIDToSlot[sid] and HasKeybind(spellIDToSlot[sid]) then
          foundSlot = spellIDToSlot[sid]
          break
        end
      end
    end

    if not foundSlot and C_ActionBar and C_ActionBar.FindSpellActionButtons and def.idSet then
      for sid, _ in pairs(def.idSet) do
        local okF, slots = pcall(C_ActionBar.FindSpellActionButtons, sid)
        if okF and type(slots) == "table" and not IsSecret(slots) then
          for _, s in pairs(slots) do
            if not IsSecret(s) and type(s) == "number" and s > 0 and not assistedSlots[s] and HasKeybind(s) then
              if not foundSlot or (HasKeybind(s) and not HasKeybind(foundSlot)) or s < foundSlot then
                foundSlot = s
              end
            end
          end
        end
        if foundSlot then break end
      end
    end

    if not foundSlot then
      for _, slot in ipairs(ACTIVE_SLOTS) do
        local tLines = tooltipLinesBySlot[slot]
        if tLines then
          for _, line in ipairs(tLines) do
            for _, nm in ipairs(def.names or {}) do
              if line:find(nm, 1, true) then
                foundSlot = slot
                break
              end
            end
            if not foundSlot and def.idSet then
              for sid, _ in pairs(def.idSet) do
                if line:match("%f[%d]" .. tostring(sid) .. "%f[%D]") then
                  foundSlot = slot
                  break
                end
              end
            end
            if foundSlot then break end
          end
        end
        if foundSlot then break end
      end
    end

    if not foundSlot then
      for _, slot in ipairs(ACTIVE_SLOTS) do
        local cLines = castLinesBySlot[slot]
        if cLines then
          for _, line in ipairs(cLines) do
            for _, nm in ipairs(def.names or {}) do
              if line:find(nm, 1, true) then
                foundSlot = slot
                break
              end
            end
            if not foundSlot and def.idSet then
              for sid, _ in pairs(def.idSet) do
                if line:match("%f[%d]" .. tostring(sid) .. "%f[%D]") then
                  foundSlot = slot
                  break
                end
              end
            end
            if foundSlot then break end
          end
        end
        if foundSlot then break end
      end
    end

    if not foundSlot and def.idSet then
      for sid, _ in pairs(def.idSet) do
        if spellIDToSlot[sid] then
          foundSlot = spellIDToSlot[sid]
          break
        end
      end
    end

    if not foundSlot and C_ActionBar and C_ActionBar.FindSpellActionButtons and def.idSet then
      for sid, _ in pairs(def.idSet) do
        local okF, slots = pcall(C_ActionBar.FindSpellActionButtons, sid)
        if okF and type(slots) == "table" and not IsSecret(slots) then
          for _, s in pairs(slots) do
            if not IsSecret(s) and type(s) == "number" and s > 0 and not assistedSlots[s] then
              foundSlot = s
              if IsSpellIDKnown(sid) then
                def.isKnown = true
              end
              break
            end
          end
        end
        if foundSlot then break end
      end
    end

    def.slot = foundSlot
    def.slotCastLineCount = (foundSlot and castLinesBySlot[foundSlot] and #castLinesBySlot[foundSlot]) or 0
    local kb = foundSlot and SpArc:GetSlotKeybind(foundSlot) or nil
    def.keybind = (kb and kb ~= "" and kb) or ""

    if foundSlot then
      local dirSID = slotDirectSpellID[foundSlot]
      if dirSID and def.idSet and def.idSet[dirSID] and not (PVP_TALENT_SPELL_IDS[dirSID] and not SpArc:IsPvPActiveNow()) then
        def.isKnown = true
        def.liveSpellID = dirSID
      end
      local btBtn = _G["BT4Button" .. foundSlot]
      local tex = nil
      if btBtn and btBtn.GetTexture then
        local okBtTex, btTex = pcall(btBtn.GetTexture, btBtn)
        if okBtTex and not IsSecret(btTex) and btTex then
          tex = btTex
        end
      end
      if not tex and GetActionTexture then
        local okTex, aTex = pcall(GetActionTexture, foundSlot)
        if okTex and not IsSecret(aTex) and aTex then
          tex = aTex
        end
      end
      if tex and tex ~= 134400 and tex ~= 136200 and def.key ~= "MIND_FLAY_INSANITY" then
        if not def.resolvedIcon or (dirSID and def.idSet and def.idSet[dirSID]) then
          def.liveIcon = tex
        end
      end
      if def.key == "BLIZZARD" and def.liveIcon == 135857 then
        def.liveIcon = 135858
      end
    end
  end

  local mfDef = SPELL_DEFS["MIND_FLAY"]
  local mfiDef = SPELL_DEFS["MIND_FLAY_INSANITY"]
  if mfDef and mfiDef and not mfiDef.slot and mfDef.slot then
    mfiDef.slot = mfDef.slot
    mfiDef.keybind = mfDef.keybind
  end

  for _, def in pairs(SPELL_DEFS) do
    def.inheritedBaseSlot = false
    if def.overrideOf then
      local baseDef = SPELL_DEFS[def.overrideOf]
      if baseDef then
        if baseDef.slot and not def.slot then
          def.slot = baseDef.slot
          def.keybind = baseDef.keybind
          def.inheritedBaseSlot = true
        elseif not baseDef.slot and def.slot then
          baseDef.slot = def.slot
          baseDef.keybind = def.keybind
        end
      end
    end
  end
end

function SpArc:MatchSpellToDefKey(spellID, spellName)
  local baseID = nil
  if spellID and not IsSecret(spellID) and type(spellID) == "number" and spellID > 0 then
    if C_Spell and C_Spell.GetBaseSpell then
      local okB, b = pcall(C_Spell.GetBaseSpell, spellID)
      if okB and not IsSecret(b) and type(b) == "number" and b > 0 then
        baseID = b
      end
    end
    if not spellName and C_Spell and C_Spell.GetSpellInfo then
      local okI, info = pcall(C_Spell.GetSpellInfo, spellID)
      if okI and type(info) == "table" and not IsSecret(info.name) then
        spellName = info.name
      end
    end
  end

  if spellID == 391403 then
    return "MIND_FLAY_INSANITY"
  elseif spellID == 1242173 or spellID == 205448 then
    return "VOID_BOLT"
  elseif spellID == 228260 or spellID == 391109 or spellID == 194249 then
    return "VOID_ERUPTION"
  elseif spellID == 450983 or spellID == 8092 then
    return "MIND_BLAST"
  elseif spellID == 1227280 or spellID == 205385 or spellID == 457042 or spellID == 1234796 then
    return "TENTACLE_SLAM"
  end

  if spellID and not IsSecret(spellID) then
    for k, def in pairs(SPELL_DEFS) do
      if def.overrideOf or def.procOnly then
        for _, id in ipairs(def.ids or {}) do
          if id == spellID then
            return k
          end
        end
      end
    end
    for k, def in pairs(SPELL_DEFS) do
      if k ~= "MIND_FLAY_INSANITY" then
        for _, id in ipairs(def.ids or {}) do
          if id == spellID then
            return k
          end
        end
      end
    end
  end

  for k, def in pairs(SPELL_DEFS) do
    if k ~= "MIND_FLAY_INSANITY" then
      if spellID and not IsSecret(spellID) then
        if def.liveSpellID == spellID or (baseID and def.liveSpellID == baseID) then
          return k
        end
        for _, id in ipairs(def.ids or {}) do
          if baseID and id == baseID then
            return k
          end
        end
      end
      if spellName and not IsSecret(spellName) and type(spellName) == "string" then
        local lowerName = SpArc.UTF8Lower(spellName)
        for _, nm in ipairs(def.names or {}) do
          if nm == spellName or lowerName == SpArc.UTF8Lower(nm) then
            return k
          end
        end
      end
    end
  end
  return nil
end

local AOE_ASSIST_KEYS = {
  FAN_OF_KNIVES = true,
  CRIMSON_TEMPEST = true,
  BLIZZARD = true,
  MULTI_SHOT = true,
  CHAIN_LIGHTNING = true,
  WHIRLWIND = true,
}

function SpArc:GetAssistedSuggestedDefKey()
  if not (C_AssistedCombat and C_AssistedCombat.GetNextCastSpell) then
    return nil, nil
  end
  local now = GetTime()
  local ok, spellID = pcall(C_AssistedCombat.GetNextCastSpell)
  if not ok or IsSecret(spellID) then
    return nil, nil
  end
  spellID = tonumber(spellID)
  if not spellID or spellID <= 0 then
    if st.lastStableAssistKey and (now - (st.lastStableAssistAt or 0)) < 1.5 then
      local lastCast = st.lastCastAt[st.lastStableAssistKey] or 0
      if lastCast < (st.lastStableAssistAt or 0) then
        return st.lastStableAssistKey, st.lastStableAssistID
      end
    end
    return nil, nil
  end
  local defKey = SpArc:MatchSpellToDefKey(spellID, nil)
  if not defKey then
    -- Ignore transient non-rotational utility/poison prompts (e.g. 5761 Numbing Poison when stepping out of 5yd melee cone)
    if st.lastStableAssistKey and (now - (st.lastStableAssistAt or 0)) < 1.5 then
      local lastCast = st.lastCastAt[st.lastStableAssistKey] or 0
      if lastCast < (st.lastStableAssistAt or 0) then
        return st.lastStableAssistKey, spellID
      end
    end
    return nil, spellID
  end

  local prevKey = st.lastStableAssistKey
  if not prevKey or prevKey == defKey then
    st.lastStableAssistKey = defKey
    st.lastStableAssistID = spellID
    st.lastStableAssistAt = now
    st.assistCandidateKey = defKey
    st.assistCandidateSince = now
    return defKey, spellID
  end

  local prevCastAt = st.lastCastAt[prevKey] or 0
  local prevWasJustCast = prevCastAt >= ((st.lastStableAssistAt or 0) - 0.15) or (now - prevCastAt) < 0.8
  local prevStale = (now - (st.lastStableAssistAt or 0)) > 2.0

  if prevWasJustCast or prevStale then
    st.lastStableAssistKey = defKey
    st.lastStableAssistID = spellID
    st.lastStableAssistAt = now
    st.assistCandidateKey = defKey
    st.assistCandidateSince = now
    return defKey, spellID
  end

  if st.assistCandidateKey ~= defKey then
    st.assistCandidateKey = defKey
    st.assistCandidateSince = now
  end

  local holdNeeded = (AOE_ASSIST_KEYS[defKey] or AOE_ASSIST_KEYS[prevKey]) and 0.85 or 0.30
  if (now - (st.assistCandidateSince or now)) >= holdNeeded then
    st.lastStableAssistKey = defKey
    st.lastStableAssistID = spellID
    st.lastStableAssistAt = now
    return defKey, spellID
  end

  return prevKey, st.lastStableAssistID or spellID
end
