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
local Trim = SpArc.Trim
local SPELL_DEFS = SpArc.SPELL_DEFS
local ACTIVE_SLOTS = SpArc.ACTIVE_SLOTS
local SLOT_DEFAULT_KEYBIND = SpArc.SLOT_DEFAULT_KEYBIND
local ACTION_BAR_RANGES = SpArc.ACTION_BAR_RANGES
local CLICKCAST_SHORT = SpArc.CLICKCAST_SHORT
local st = SpArc.state

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
  local cmd = SlotToBindingCommand(slot)

  local cm = _G.CM
  if cmd and cm and cm.DB then
    local loc = (cm.GetBindingsLocation and cm.GetBindingsLocation()) or "char"
    local root = cm.DB[loc]
    local binds = root and root.bindings
    if type(binds) == "table" then
      for dbKey, shortName in pairs(CLICKCAST_SHORT) do
        local b = binds[dbKey]
        if b and b.enabled and b.value == cmd then
          return shortName
        end
      end
    end
  end

  local btBtn = _G["BT4Button" .. slot]
  if btBtn then
    if btBtn.GetHotkey then
      local okHK, hk = pcall(btBtn.GetHotkey, btBtn)
      if okHK and not IsSecret(hk) and type(hk) == "string" and hk ~= "" then
        local c = CompactKey(hk)
        if c and c ~= "" then return c end
      end
    end
    if GetBindingKey then
      local okB, k1, k2 = pcall(GetBindingKey, "CLICK BT4Button" .. slot .. ":LeftButton")
      if okB then
        local k = (not IsSecret(k1) and k1) or (not IsSecret(k2) and k2)
        if k and k ~= "" then
          local c = CompactKey(k)
          if c and c ~= "" then return c end
        end
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

  return SLOT_DEFAULT_KEYBIND[slot]
end

local function BuildAssistedSlotSet()
  local set = {}
  if C_ActionBar and C_ActionBar.HasAssistedCombatActionButtons and C_ActionBar.FindAssistedCombatActionButtons then
    local okH, has = pcall(C_ActionBar.HasAssistedCombatActionButtons)
    if okH and not IsSecret(has) and has then
      local ok, slots = pcall(C_ActionBar.FindAssistedCombatActionButtons)
      if ok and type(slots) == "table" and not IsSecret(slots) then
        for _, v in pairs(slots) do
          if type(v) == "number" and v > 0 then
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
      if not explicitOwnerBySpellID[id] or k == "VOID_BOLT" or k == "MIND_FLAY_INSANITY" then
        explicitOwnerBySpellID[id] = k
      end
    end
  end

  for k, def in pairs(SPELL_DEFS) do
    local idSet = {}
    local resolvedID, resolvedIcon
    for _, id in ipairs(def.ids or {}) do
      idSet[id] = true
      if C_Spell and C_Spell.GetOverrideSpell then
        local okO, over = pcall(C_Spell.GetOverrideSpell, id)
        if okO and type(over) == "number" and not IsSecret(over) and over > 0 then
          local owner = explicitOwnerBySpellID[over]
          if not owner or owner == k then
            idSet[over] = true
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
    end
    if C_Spell and C_Spell.GetSpellInfo then
      for _, nm in ipairs(def.names or {}) do
        local ok, info = pcall(C_Spell.GetSpellInfo, nm)
        if ok and type(info) == "table" and not IsSecret(info.spellID) and info.spellID then
          local owner = explicitOwnerBySpellID[info.spellID]
          if not owner or owner == k then
            idSet[info.spellID] = true
            if not resolvedID then
              resolvedID = info.spellID
              resolvedIcon = not IsSecret(info.iconID) and info.iconID or nil
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
    def.liveSpellID = resolvedID or (def.ids and def.ids[1])
    def.liveIcon = resolvedIcon or def.fallbackIcon
  end

  local assistedSlots = BuildAssistedSlotSet()
  local spellIDToSlot = {}
  local tooltipLinesBySlot = {}
  local castLinesBySlot = {}
  local GetMacroSpell = _G.GetMacroSpell

  local function HasKeybind(s)
    local k = SpArc:GetSlotKeybind(s)
    return (k and k ~= "") and true or false
  end

  local function AssignSpellSlot(sid, s)
    if not sid or not s then return end
    local prev = spellIDToSlot[sid]
    if not prev or (not HasKeybind(prev) and HasKeybind(s)) then
      spellIDToSlot[sid] = s
    end
  end

  for _, slot in ipairs(ACTIVE_SLOTS) do
    if not assistedSlots[slot] then
      local btBtn = _G["BT4Button" .. slot]
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
            if GetActionText and GetMacroBody then
              local okT, mName = pcall(GetActionText, slot)
              if okT and not IsSecret(mName) and type(mName) == "string" and mName ~= "" then
                local okB, b = pcall(GetMacroBody, mName)
                if okB and not IsSecret(b) and type(b) == "string" then
                  body = b
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
            if type(s) == "number" and s > 0 and not assistedSlots[s] and HasKeybind(s) then
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

    def.slot = foundSlot
    local kb = foundSlot and SpArc:GetSlotKeybind(foundSlot) or nil
    def.keybind = (kb and kb ~= "" and kb) or ""

    if foundSlot then
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
        def.liveIcon = tex
      end
    end
  end

  local mfDef = SPELL_DEFS["MIND_FLAY"]
  local mfiDef = SPELL_DEFS["MIND_FLAY_INSANITY"]
  if mfDef and mfiDef and not mfiDef.slot and mfDef.slot then
    mfiDef.slot = mfDef.slot
    mfiDef.keybind = mfDef.keybind
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
        local lowerName = spellName:lower()
        for _, nm in ipairs(def.names or {}) do
          if nm == spellName or lowerName == nm:lower() then
            return k
          end
        end
      end
    end
  end
  return nil
end

function SpArc:GetAssistedSuggestedDefKey()
  if not (C_AssistedCombat and C_AssistedCombat.GetNextCastSpell) then
    return nil, nil
  end
  local ok, spellID = pcall(C_AssistedCombat.GetNextCastSpell)
  if not ok or IsSecret(spellID) then
    return nil, nil
  end
  spellID = tonumber(spellID)
  if not spellID or spellID <= 0 then
    return nil, nil
  end
  local defKey = SpArc:MatchSpellToDefKey(spellID, nil)
  return defKey, spellID
end
