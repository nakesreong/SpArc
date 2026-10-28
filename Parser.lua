---------------------------------------------------------------------------------------
--  SpArc/Parser.lua — Data-Driven Markdown (.md) Pseudocode FSM Compiler
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc or _G.SparkArc or {}
_G.SpArc = SpArc
_G.SparkArc = SpArc

local type = _G.type
local tonumber = _G.tonumber
local ipairs = _G.ipairs
local pairs = _G.pairs

local function Trim(s)
  if not s then return "" end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function ParseCSVTokens(str)
  local list = {}
  if not str or str == "" then return list end
  for item in str:gmatch("([^,]+)") do
    local clean = Trim(item):gsub('^"', ''):gsub('"$', '')
    if clean ~= "" then
      list[#list + 1] = clean
    end
  end
  return list
end

-- Parses a single `SPELL KEY = ...` or `AURA KEY = ...` line from .md pseudocode
local function ParseSpellDefLine(line)
  local kind, key, rest = line:match("^(SPELL)%s+([A-Z0-9_]+)%s*=%s*(.+)$")
  if not kind then
    kind, key, rest = line:match("^(AURA)%s+([A-Z0-9_]+)%s*=%s*(.+)$")
  end
  if not key or not rest then return nil, nil, nil end
  local def = {
    key = key,
    isAuraOnly = (kind == "AURA"),
    names = {},
    macroNames = {},
    ids = {},
    auraIDs = {},
    baseCD = 0,
    maxCharges = 1,
    fallbackIcon = 134400,
    fallbackKey = "",
  }
  for part in rest:gmatch("([^|]+)") do
    local p = Trim(part)
    local prop, val = p:match("^([A-Z_]+)%s*:%s*(.+)$")
    if prop and val then
      val = Trim(val)
      if prop == "ID" or prop == "IDS" then
        for _, tok in ipairs(ParseCSVTokens(val)) do
          local n = tonumber(tok)
          if n then def.ids[#def.ids + 1] = n end
        end
      elseif prop == "NAME" or prop == "NAMES" then
        def.names = ParseCSVTokens(val)
      elseif prop == "MACRO" or prop == "MACROS" then
        def.macroNames = ParseCSVTokens(val)
      elseif prop == "SLOT" then
        def.preferredSlot = tonumber(val)
      elseif prop == "KEY" then
        def.fallbackKey = val:gsub('^"', ''):gsub('"$', '')
      elseif prop == "CD" then
        def.baseCD = tonumber(val) or 0
      elseif prop == "CHARGES" then
        def.maxCharges = tonumber(val) or 1
      elseif prop == "GAIN" then
        def.insanityGain = tonumber(val) or 0
      elseif prop == "COST" then
        def.insanityCost = tonumber(val) or 0
      elseif prop == "STACKS" or prop == "DEBUFF_STACKS" or prop == "AURA_STACKS" then
        local n = tonumber(val)
        if n then
          if n > 0 then
            def.stacksGain = n
          elseif n < 0 then
            def.stacksCost = -n
            def.consumesStacks = true
          end
        elseif val:upper() == "RESET" or val:upper() == "CONSUME" then
          def.consumesStacks = true
        end
      elseif prop == "CONSUMES_STACKS" then
        def.consumesStacks = (val:lower() == "true" or val == "1")
      elseif prop == "AURA_KEY" then
        def.auraKey = val:gsub('^"', ''):gsub('"$', '')
      elseif prop == "AURA_UNIT" or prop == "UNIT" then
        def.auraUnit = val:gsub('^"', ''):gsub('"$', ''):lower()
      elseif prop == "OVERRIDE_OF" then
        def.overrideOf = val:gsub('^"', ''):gsub('"$', '')
      elseif prop == "AURA_ID" or prop == "AURA_IDS" or prop == "DEBUFF_ID" or prop == "DEBUFF_IDS" then
        def.auraIDs = {}
        for _, tok in ipairs(ParseCSVTokens(val)) do
          local n = tonumber(tok)
          if n then def.auraIDs[#def.auraIDs + 1] = n end
        end
        def.debuffIDs = def.auraIDs
      elseif prop == "ICON" then
        def.fallbackIcon = tonumber(val) or 134400
      elseif prop == "AURA_DUR" or prop == "AURA_DURATION" or prop == "DUR" or prop == "DURATION" then
        local durSec = tonumber(val)
        if durSec and durSec > 0 then
          def.auraDuration = durSec
        end
      elseif prop == "DOTS" then
        local dotSec = tonumber(val)
        if dotSec and dotSec > 0 then
          def.appliesDoTs = true
          def.dotDuration = dotSec
          def.auraDuration = def.auraDuration or dotSec
          def.auraUnit = def.auraUnit or "target"
        else
          def.appliesDoTs = (val:lower() == "true" or val == "1")
          if def.appliesDoTs then
            def.auraDuration = def.auraDuration or 21
            def.auraUnit = def.auraUnit or "target"
          end
        end
      elseif prop == "DOT_DURATION" then
        local dotSec = tonumber(val)
        def.dotDuration = dotSec
        def.auraDuration = def.auraDuration or dotSec
      elseif prop == "GRANTS" then
        def.grantsProc = val:gsub('^"', ''):gsub('"$', '')
        if def.grantsProc == "MIND_FLAY_INSANITY" then
          def.grantsMFI = true
        end
      elseif prop == "PROC_ONLY" then
        def.procOnly = (val:lower() == "true" or val == "1")
      elseif prop == "SPENDER" then
        def.isSpender = (val:lower() == "true" or val == "1")
        if def.isSpender then def.requiresUsable = true end
      elseif prop == "EXECUTE" then
        def.isExecute = (val:lower() == "true" or val == "1")
        if def.isExecute then def.requiresUsable = true end
      elseif prop == "FILLER_INTERRUPTIBLE" then
        def.fillerInterruptible = (val:lower() == "true" or val == "1")
      elseif prop == "LOCK_CHANNEL" then
        def.lockChannel = (val:lower() == "true" or val == "1")
      elseif prop == "BURST" or prop == "BURST_DURATION" then
        local bDur = tonumber(val) or 15
        def.burstDuration = bDur
        def.auraDuration = def.auraDuration or bDur
        def.auraUnit = def.auraUnit or "player"
      end
    end
  end
  if #def.auraIDs == 0 and #def.ids > 0 then
    for _, id in ipairs(def.ids) do
      def.auraIDs[#def.auraIDs + 1] = id
    end
  end
  if def.auraDuration and not def.dotDuration then
    def.dotDuration = def.auraDuration
  end
  if def.isAuraOnly then
    def.auraUnit = def.auraUnit or "target"
    def.auraDuration = def.auraDuration or 15
  end
  return key, def, kind
end

-- Compiles a Markdown (.md) pseudocode string into a complete FSM table:
--   {
--     title, class, spec, mode,
--     spells = { [KEY] = def, ... },
--     interruptibleChannels = { [KEY] = true, ... },
--     protectedChannels = { [KEY] = true, ... },
--     rules = { { cond = "...", spell = "..." }, ... },
--     emergency = { "DISPERSION", ... },
--     saves = { "DISPERSION", ... },
--     cds = { "POWER_INFUSION", ... },
--   }
function SpArc:ParseMarkdownFSM(mdText)
  local parsed = {
    title = "Custom FSM",
    class = "PRIEST",
    spec = "Shadow",
    mode = "PVE",
    spells = {},
    auras = {},
    interruptibleChannels = {},
    protectedChannels = {},
    targetDebuffIDs = {},
    targetDebuffNames = {},
    rules = {},
    emergency = {},
    saves = {},
    cds = {},
  }
  if type(mdText) ~= "string" or mdText == "" then
    return parsed
  end

  local pendingCond = nil
  for rawLine in mdText:gmatch("[^\r\n]+") do
    local line = Trim(rawLine)
    if line ~= "" and not line:match("^```") then
      -- Metadata headers in comments
      local profTitle = line:match("^#%s*PROFILE:%s*(.+)$") or line:match("^#%s*TITLE:%s*(.+)$")
      if profTitle then parsed.title = Trim(profTitle) end
      local profClass = line:match("^#%s*CLASS:%s*([A-Z]+)")
      if profClass then parsed.class = Trim(profClass) end
      local profSpec = line:match("^#%s*SPEC:%s*(.+)$")
      if profSpec then parsed.spec = Trim(profSpec) end
      local profMode = line:match("^#%s*MODE:%s*([A-Z]+)")
      if profMode then parsed.mode = Trim(profMode) end

      local debuffHeaderOrBody = line:match("^#%s*TARGET_DEBUFF:%s*(.+)$") or line:match("^TARGET_DEBUFF:%s*(.+)$")
      if debuffHeaderOrBody then
        for part in debuffHeaderOrBody:gmatch("([^|]+)") do
          local p = Trim(part)
          local prop, val = p:match("^([A-Z_]+)%s*:%s*(.+)$")
          if prop and val then
            if prop == "ID" or prop == "IDS" then
              for _, tok in ipairs(ParseCSVTokens(val)) do
                local n = tonumber(tok)
                if n then parsed.targetDebuffIDs[#parsed.targetDebuffIDs + 1] = n end
              end
            elseif prop == "NAME" or prop == "NAMES" then
              for _, nm in ipairs(ParseCSVTokens(val)) do
                parsed.targetDebuffNames[#parsed.targetDebuffNames + 1] = nm
              end
            end
          end
        end
        local legacyAura = {
          key = "FREEZING",
          isAuraOnly = true,
          ids = parsed.targetDebuffIDs,
          auraIDs = parsed.targetDebuffIDs,
          names = parsed.targetDebuffNames,
          auraUnit = "target",
          auraDuration = 15,
        }
        parsed.auras["FREEZING"] = legacyAura
        parsed.auras["TARGET_DEBUFF"] = legacyAura
      end

      if not line:match("^#") then
        local spKey, spDef, spKind = ParseSpellDefLine(line)
        if spKey and spDef then
          if spKind == "AURA" then
            parsed.auras[spKey] = spDef
            if spDef.auraUnit ~= "player" then
              for _, did in ipairs(spDef.auraIDs or {}) do
                parsed.targetDebuffIDs[#parsed.targetDebuffIDs + 1] = did
              end
              for _, nm in ipairs(spDef.names or {}) do
                parsed.targetDebuffNames[#parsed.targetDebuffNames + 1] = nm
              end
            end
          else
            parsed.spells[spKey] = spDef
            parsed.auras[spKey] = spDef
            if spDef.fillerInterruptible then
              parsed.interruptibleChannels[spKey] = true
            end
            if spDef.lockChannel then
              parsed.protectedChannels[spKey] = true
            end
            if spDef.debuffIDs then
              for _, did in ipairs(spDef.debuffIDs) do
                parsed.targetDebuffIDs[#parsed.targetDebuffIDs + 1] = did
              end
            end
          end
        else
          local intList = line:match("^INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY:%s*(.+)$")
            or line:match("^INTERRUPTIBLE_CHANNELS:%s*(.+)$")
          if intList then
            for token in intList:gmatch("([A-Z0-9_]+)") do
              parsed.interruptibleChannels[token] = true
            end
          end

          local protList = line:match("^PROTECT_CHANNEL:%s*(.+)$")
            or line:match("^PROTECTED_CHANNELS:%s*(.+)$")
          if protList then
            for token in protList:gmatch("([A-Z0-9_]+)") do
              parsed.protectedChannels[token] = true
            end
          end

          local savesList = line:match("^TRACK_SAVES:%s*(.+)$")
          if savesList then
            for token in savesList:gmatch("([A-Z0-9_]+)") do
              parsed.saves[#parsed.saves + 1] = token
            end
          end

          local cdsList = line:match("^TRACK_CDS:%s*(.+)$")
          if cdsList then
            for token in cdsList:gmatch("([A-Z0-9_]+)") do
              parsed.cds[#parsed.cds + 1] = token
            end
          end

          local strippedLine = line:gsub("^%d+%.%s*", "")
          local inlineCond, inlineSpell = strippedLine:match("^IF%s+(.+)%s+THEN%s+RETURN%s+CAST%(%s*([A-Z0-9_]+)%s*%)$")
          if not inlineCond then
            inlineCond, inlineSpell = strippedLine:match("^ELSE%s+IF%s+(.+)%s+THEN%s+RETURN%s+CAST%(%s*([A-Z0-9_]+)%s*%)$")
          end
          if not inlineCond then
            inlineCond, inlineSpell = strippedLine:match("^IF%s+(.+)%s+THEN%s+RETURN%s+([A-Z0-9_]+)$")
          end
          local defaultSpell = strippedLine:match("^DEFAULT:%s*RETURN%s+CAST%(%s*([A-Z0-9_]+)%s*%)$")
            or strippedLine:match("^DEFAULT:%s*RETURN%s+([A-Z0-9_]+)$")

          if inlineCond and inlineSpell then
            parsed.rules[#parsed.rules + 1] = {
              cond = Trim(inlineCond),
              spell = inlineSpell,
            }
            pendingCond = nil
          elseif defaultSpell then
            parsed.rules[#parsed.rules + 1] = {
              cond = "ALWAYS",
              spell = defaultSpell,
            }
            pendingCond = nil
          else
            local condPart = strippedLine:match("^IF%s+(.+)%s+THEN$") or strippedLine:match("^ELSE%s+IF%s+(.+)%s+THEN$")
            if condPart then
              pendingCond = Trim(condPart)
            elseif strippedLine:match("^ELSE$") then
              pendingCond = "ALWAYS"
            elseif strippedLine:match("^END%s+IF") then
              pendingCond = nil
            else
              local emSpell = strippedLine:match("RETURN%s+EMERGENCY%(%s*([A-Z0-9_]+)%s*%)")
              if emSpell then
                parsed.emergency[#parsed.emergency + 1] = emSpell
                pendingCond = nil
              end
              local castSpell = strippedLine:match("RETURN%s+CAST%(%s*([A-Z0-9_]+)%s*%)")
              if castSpell then
                parsed.rules[#parsed.rules + 1] = {
                  cond = pendingCond or "ALWAYS",
                  spell = castSpell,
                }
                pendingCond = nil
              end
            end
          end
        end
      end
    end
  end

  return parsed
end
