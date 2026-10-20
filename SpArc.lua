---------------------------------------------------------------------------------------
--  SpArc/SpArc.lua — Semicircle FSM Rotation, Channel-Interrupt & Cooldown HUD
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
if _G.SpArcLoaded then
  return
end
_G.SpArcLoaded = true
_G.SparkArcLoaded = true

local SpArc = _G.SpArc or _G.SparkArc or {}
_G.SpArc = SpArc
_G.SparkArc = SpArc
SpArc.VERSION = "2.2.0"
SpArc.PROFILE_SCHEMA_VERSION = 4

local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local GetTime = _G.GetTime
local UnitExists = _G.UnitExists
local UnitCanAttack = _G.UnitCanAttack
local UnitIsDead = _G.UnitIsDead
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsPlayer = _G.UnitIsPlayer
local UnitClass = _G.UnitClass
local UnitClassification = _G.UnitClassification
local UnitLevel = _G.UnitLevel
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitInVehicle = _G.UnitInVehicle
local UnitGUID = _G.UnitGUID
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitPower = _G.UnitPower
local UnitCastingInfo = _G.UnitCastingInfo
local UnitChannelInfo = _G.UnitChannelInfo
local IsMounted = _G.IsMounted
local HasOverrideActionBar = _G.HasOverrideActionBar
local GetActionInfo = _G.GetActionInfo
local GetActionText = _G.GetActionText
local GetActionTexture = _G.GetActionTexture
local GetActionCooldown = _G.GetActionCooldown
local IsUsableAction = _G.IsUsableAction
local GetMacroBody = _G.GetMacroBody
local GetBindingKey = _G.GetBindingKey
local C_Spell = _G.C_Spell
local C_ActionBar = _G.C_ActionBar
local C_UnitAuras = _G.C_UnitAuras
local C_AssistedCombat = _G.C_AssistedCombat
local C_AddOns = _G.C_AddOns
local C_CVar = _G.C_CVar
local issecretvalue = _G.issecretvalue
local pcall = _G.pcall
local ipairs = _G.ipairs
local pairs = _G.pairs
local tonumber = _G.tonumber
local tostring = _G.tostring
local type = _G.type
local math = _G.math
local table = _G.table
local string = _G.string

local FONT_PATH = (_G.GameFontNormal and select(1, _G.GameFontNormal:GetFont()))
  or (_G.StandardTextFont and select(1, _G.StandardTextFont:GetFont()))
  or "Fonts\\FRIZQT___CYR.TTF"

local function ApplyCyrFont(fs, size)
  if not fs then return end
  local fPath = (_G.GameFontNormal and select(1, _G.GameFontNormal:GetFont())) or FONT_PATH
  local ok = fs:SetFont(fPath, size, "OUTLINE")
  if not ok then
    fs:SetFont("Fonts\\FRIZQT___CYR.TTF", size, "OUTLINE")
  end
end

local function IsSecret(v)
  return issecretvalue and issecretvalue(v) or false
end

local function SafeBool(fn, ...)
  if not fn then return false end
  local ok, res = pcall(fn, ...)
  if not ok or IsSecret(res) then return false end
  return res and true or false
end

local function ForceElvUIChatAlwaysVisible()
  local E = _G.ElvUI and _G.ElvUI[1]
  if E and E.db then
    E.db.LeftChatPanelFaded = nil
    E.db.RightChatPanelFaded = nil
    if E.db.chat then
      E.db.chat.fade = false
      E.db.chat.hideChatToggles = true
      E.db.chat.inactivityTimer = 120
    end
  end
  if _G.LeftChatPanel then
    if E and E.UIFrameFadeRemoveFrame then
      pcall(E.UIFrameFadeRemoveFrame, E, _G.LeftChatPanel)
    end
    pcall(_G.LeftChatPanel.SetAlpha, _G.LeftChatPanel, 1)
    pcall(_G.LeftChatPanel.Show, _G.LeftChatPanel)
  end
  if _G.RightChatPanel then
    if E and E.UIFrameFadeRemoveFrame then
      pcall(E.UIFrameFadeRemoveFrame, E, _G.RightChatPanel)
    end
    pcall(_G.RightChatPanel.SetAlpha, _G.RightChatPanel, 1)
    pcall(_G.RightChatPanel.Show, _G.RightChatPanel)
  end
  if _G.LeftChatToggleButton then
    pcall(_G.LeftChatToggleButton.SetAlpha, _G.LeftChatToggleButton, 0)
    pcall(_G.LeftChatToggleButton.EnableMouse, _G.LeftChatToggleButton, false)
  end
  if _G.RightChatToggleButton then
    pcall(_G.RightChatToggleButton.SetAlpha, _G.RightChatToggleButton, 0)
    pcall(_G.RightChatToggleButton.EnableMouse, _G.RightChatToggleButton, false)
  end
  for i = 1, 10 do
    local cf = _G["ChatFrame" .. i]
    if cf and cf.SetFading then
      pcall(cf.SetFading, cf, false)
    end
  end
end

local function SuppressLuaErrorPopups()
  if C_CVar and C_CVar.SetCVar then
    pcall(C_CVar.SetCVar, "scriptErrors", "0")
    pcall(C_CVar.SetCVar, "assistedCombatHighlight", "1")
  end
  if C_AddOns and C_AddOns.DisableAddOn then
    pcall(C_AddOns.DisableAddOn, "WeakAuras")
    pcall(C_AddOns.DisableAddOn, "WeakAurasOptions")
    pcall(C_AddOns.DisableAddOn, "WeakAurasArchive")
    pcall(C_AddOns.DisableAddOn, "WeakAurasCompanion")
  end
  if UIParent and UIParent.UnregisterEvent then
    pcall(UIParent.UnregisterEvent, UIParent, "LUA_WARNING")
    pcall(UIParent.UnregisterEvent, UIParent, "ADDON_ACTION_FORBIDDEN")
    pcall(UIParent.UnregisterEvent, UIParent, "ADDON_ACTION_BLOCKED")
  end
  if _G.StaticPopup_Hide then
    pcall(_G.StaticPopup_Hide, "TOO_MANY_LUA_ERRORS")
    pcall(_G.StaticPopup_Hide, "ADDON_ACTION_FORBIDDEN")
  end
  if _G.ScriptErrorsFrame and _G.ScriptErrorsFrame.Hide then
    pcall(_G.ScriptErrorsFrame.Hide, _G.ScriptErrorsFrame)
  end
  ForceElvUIChatAlwaysVisible()
end

SuppressLuaErrorPopups()

---------------------------------------------------------------------------------------
--         EMBEDDED PARSER & 55 PRESETS FALLBACK (FOR LIVE /RL BOOTSTRAP)            --
---------------------------------------------------------------------------------------
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

local function ParseSpellDefLine(line)
  local key, rest = line:match("^SPELL%s+([A-Z0-9_]+)%s*=%s*(.+)$")
  if not key or not rest then return nil, nil end
  local def = {
    key = key,
    names = {},
    macroNames = {},
    ids = {},
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
      elseif prop == "ICON" then
        def.fallbackIcon = tonumber(val) or 134400
      elseif prop == "DOTS" then
        def.appliesDoTs = (val:lower() == "true" or val == "1")
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
      end
    end
  end
  return key, def
end

if not SpArc.ParseMarkdownFSM then
  function SpArc:ParseMarkdownFSM(mdText)
    local parsed = {
      title = "Custom FSM",
      class = "PRIEST",
      spec = "Shadow",
      mode = "PVE",
      spells = {},
      interruptibleChannels = {},
      protectedChannels = {},
      rules = {},
      emergency = {},
      saves = {},
      cds = {},
    }
    if type(mdText) ~= "string" or mdText == "" then return parsed end
    local pendingCond = nil
    for rawLine in mdText:gmatch("[^\r\n]+") do
      local line = Trim(rawLine)
      if line ~= "" and not line:match("^```") then
        local profTitle = line:match("^#%s*PROFILE:%s*(.+)$")
        if profTitle then parsed.title = Trim(profTitle) end
        local profClass = line:match("^#%s*CLASS:%s*([A-Z]+)")
        if profClass then parsed.class = Trim(profClass) end
        local profSpec = line:match("^#%s*SPEC:%s*(.+)$")
        if profSpec then parsed.spec = Trim(profSpec) end
        local profMode = line:match("^#%s*MODE:%s*([A-Z]+)")
        if profMode then parsed.mode = Trim(profMode) end

        if not line:match("^#") then
          local spKey, spDef = ParseSpellDefLine(line)
          if spKey and spDef then
            parsed.spells[spKey] = spDef
            if spDef.fillerInterruptible then parsed.interruptibleChannels[spKey] = true end
            if spDef.lockChannel then parsed.protectedChannels[spKey] = true end
          else
            local intList = line:match("^INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY:%s*(.+)$")
            if intList then
              for token in intList:gmatch("([A-Z0-9_]+)") do
                parsed.interruptibleChannels[token] = true
              end
            end
            local protList = line:match("^PROTECT_CHANNEL:%s*(.+)$")
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
            local condPart = line:match("^IF%s+(.+)%s+THEN$") or line:match("^ELSE%s+IF%s+(.+)%s+THEN$")
            if condPart then
              pendingCond = Trim(condPart)
            elseif line:match("^ELSE$") then
              pendingCond = "ALWAYS"
            elseif line:match("^END%s+IF") then
              pendingCond = nil
            else
              local emSpell = line:match("RETURN%s+EMERGENCY%(%s*([A-Z0-9_]+)%s*%)")
              if emSpell then
                parsed.emergency[#parsed.emergency + 1] = emSpell
                pendingCond = nil
              end
              local castSpell = line:match("RETURN%s+CAST%(%s*([A-Z0-9_]+)%s*%)")
              if castSpell then
                parsed.rules[#parsed.rules + 1] = { cond = pendingCond or "ALWAYS", spell = castSpell }
                pendingCond = nil
              end
            end
          end
        end
      end
    end
    return parsed
  end
end

if not SpArc.AIPromptTemplate then
  SpArc.AIPromptHeaderText =
    "Попросите своего Gemini или ChatGPT написать вам ротацию с Icy Veins / Wowhead "
    .. "на псевдокоде в формате SpArc .MD и засуньте её сюды!"
  SpArc.AIPromptTemplate = [[Привет, Gemini / ChatGPT! Напиши мне профиль ротации с Icy Veins для аддона SpArc (World of Warcraft) строго в формате псевдокода SpArc .MD.

Класс и спек: [УКАЖИ КЛАСС И СПЕК, например: Жрец Тьмы / Shadow Priest]
Тип контента: [PvE Мифик+ / Босс СТ / PvP Арена]

Синтаксис SpArc .MD:
# PROFILE: Название пресета
# CLASS: PRIEST
# SPEC: Shadow
# MODE: PVE

SPELL TENTACLE_SLAM = ID:205385,457042,1234796 | NAME:"Мощный удар щупальцем","Темное сокрушение" | MACRO:"M2","sp3" | CD:15 | GAIN:15 | DOTS:true | ICON:136201
SPELL VAMPIRIC_TOUCH = ID:34914 | NAME:"Прикосновение вампира" | MACRO:"sp1pvp","sp1" | CD:0 | GAIN:6 | DOTS:true | ICON:135978
SPELL VOID_TORRENT = ID:263165 | NAME:"Поток бездны" | MACRO:"SM2" | CD:45 | GAIN:35 | GRANTS:MIND_FLAY_INSANITY | LOCK_CHANNEL:true | ICON:1386551
SPELL DEVOURING_PLAGUE = ID:335467 | NAME:"Слово Тьмы: Безумие","Всепожирающая чума" | MACRO:"sp4" | COST:50 | GRANTS:MIND_FLAY_INSANITY | SPENDER:true | ICON:252997
SPELL MIND_BLAST = ID:450983,8092 | NAME:"Выброс Бездны","Взрыв разума" | MACRO:"M1" | CD:7.5 | CHARGES:2 | GAIN:15 | ICON:136224
SPELL MIND_FLAY_INSANITY = ID:391403 | NAME:"Пытка разума: безумие" | MACRO:"sp8" | GAIN:16 | PROC_ONLY:true | ICON:136208
SPELL MIND_FLAY = ID:15407 | NAME:"Пытка разума" | MACRO:"sp8" | GAIN:12 | FILLER_INTERRUPTIBLE:true | ICON:136208

INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, PSYFIEND

IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
END IF

IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF PROC(VOID_BOLT) AND READY(VOID_BOLT) THEN
    RETURN CAST(VOID_BOLT)
ELSE IF PROC(VOID_BLAST) AND READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF PROC(DEVOURING_PLAGUE) AND USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF PROC(MIND_FLAY_INSANITY) THEN
    RETURN CAST(MIND_FLAY_INSANITY)
ELSE IF PROC(SHADOW_WORD_DEATH) AND READY(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(HALO) THEN
    RETURN CAST(HALO)
ELSE
    RETURN CAST(MIND_FLAY)
END IF]]
end

if not SpArc.BuiltInPresets then
  SpArc.BuiltInPresetOrder = {}
  SpArc.BuiltInPresets = {}
  local function Reg(id, cls, title, mode, md)
    SpArc.BuiltInPresetOrder[#SpArc.BuiltInPresetOrder + 1] = id
    SpArc.BuiltInPresets[id] = { id = id, class = cls, title = title, mode = mode, md = md }
  end
  local BASE_PVE = [[
# PROFILE: 1. ШП: PvE / Мифик+ (Icy Veins Cleave)
# CLASS: PRIEST
# SPEC: Shadow
# MODE: PVE
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, PSYFIEND
IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
ELSE IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
END IF
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF PROC(VOID_BOLT) AND READY(VOID_BOLT) THEN
    RETURN CAST(VOID_BOLT)
ELSE IF PROC(VOID_BLAST) AND READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF PROC(DEVOURING_PLAGUE) AND USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF PROC(MIND_FLAY_INSANITY) THEN
    RETURN CAST(MIND_FLAY_INSANITY)
ELSE IF PROC(SHADOW_WORD_DEATH) AND READY(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF PROC(MIND_BLAST) AND READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(HALO) THEN
    RETURN CAST(HALO)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]]
  local BASE_BOSS = BASE_PVE:gsub("1%. ШП: PvE / Мифик%+ %(Icy Veins Cleave%)", "2. ШП: Босс / Рейд (Icy Veins СТ)"):gsub("# MODE: PVE", "# MODE: BOSS")
  local BASE_PVP = [[
# PROFILE: 3. ШП: PvP / Арена (Бурст и Экзекут)
# CLASS: PRIEST
# SPEC: Shadow
# MODE: PVP
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, PSYFIEND, SILENCE
IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
ELSE IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
END IF
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF PROC(VOID_BOLT) AND READY(VOID_BOLT) THEN
    RETURN CAST(VOID_BOLT)
ELSE IF PROC(VOID_BLAST) AND READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF PROC(MIND_FLAY_INSANITY) THEN
    RETURN CAST(MIND_FLAY_INSANITY)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]]
  Reg("PRIEST_01_SHADOW_PVE",        "PRIEST", "1. ШП: PvE / Мифик+ (Icy Veins Cleave)", "PVE",  BASE_PVE)
  Reg("PRIEST_02_SHADOW_BOSS",       "PRIEST", "2. ШП: Босс / Рейд (Icy Veins СТ)",      "BOSS", BASE_BOSS)
  Reg("PRIEST_03_SHADOW_PVP",        "PRIEST", "3. ШП: PvP / Арена (Бурст и Экзекут)",   "PVP",  BASE_PVP)
  Reg("PRIEST_04_SHADOW_ARCHON",     "PRIEST", "4. ШП: Архонт (Приоритет Сияния)",       "PVE",  BASE_PVE)
  Reg("PRIEST_05_SHADOW_VOIDWEAVER", "PRIEST", "5. ШП: Ткач Бездны (Поток Бездны)",      "PVE",  BASE_PVE)
  Reg("PRIEST_06_SHADOW_DELVES",     "PRIEST", "6. ШП: Вылазки / Соло (Сейв-билд)",      "PVE",  BASE_PVE)
  Reg("PRIEST_07_SHADOW_SPEEDRUN",   "PRIEST", "7. ШП: Ни'алота / Фарм старых рейдов",   "PVE",  BASE_PVE)
  Reg("PRIEST_08_DISC_PVE",          "PRIEST", "8. ДЦ: PvE Искупление вины (Atonement)", "PVE",  BASE_PVE)
  Reg("PRIEST_09_DISC_PVP",          "PRIEST", "9. ДЦ: PvP Арена (Ассист и Экзекут)",    "PVP",  BASE_PVP)
  Reg("PRIEST_10_HOLY_PVE",          "PRIEST", "10. Холи: PvE Урон в окно исцеления",    "PVE",  BASE_PVE)

  local EXTRA = {
    { "MAGE_01", "MAGE", "11. Маг: Тайная магия — PvE" },
    { "MAGE_02", "MAGE", "12. Маг: Тайная магия — Босс СТ" },
    { "MAGE_03", "MAGE", "13. Маг: Огонь — Мифик+" },
    { "MAGE_04", "MAGE", "14. Маг: Лёд — PvE Cleave" },
    { "MAGE_05", "MAGE", "15. Маг: Лёд — PvP Арена" },
    { "WARLOCK_01", "WARLOCK", "16. Чернокнижник: Колдовство — PvE" },
    { "WARLOCK_02", "WARLOCK", "17. Чернокнижник: Колдовство — Босс" },
    { "WARLOCK_03", "WARLOCK", "18. Чернокнижник: Демонология — PvE" },
    { "WARLOCK_04", "WARLOCK", "19. Чернокнижник: Разрушение — PvE" },
    { "WARLOCK_05", "WARLOCK", "20. Чернокнижник: Разрушение — PvP" },
    { "PALADIN_01", "PALADIN", "21. Паладин: Воздаяние — PvE" },
    { "PALADIN_02", "PALADIN", "22. Паладин: Воздаяние — Босс" },
    { "PALADIN_03", "PALADIN", "23. Паладин: Воздаяние — PvP" },
    { "PALADIN_04", "PALADIN", "24. Паладин: Защита — Танк" },
    { "HUNTER_01", "HUNTER", "25. Охотник: Повелитель зверей — PvE" },
    { "HUNTER_02", "HUNTER", "26. Охотник: Повелитель зверей — Босс" },
    { "HUNTER_03", "HUNTER", "27. Охотник: Стрельба — PvE" },
    { "HUNTER_04", "HUNTER", "28. Охотник: Выживание — PvP" },
    { "ROGUE_01", "ROGUE", "29. Разбойник: Ликвидация — PvE" },
    { "ROGUE_02", "ROGUE", "30. Разбойник: Головорез — Мифик+" },
    { "ROGUE_03", "ROGUE", "31. Разбойник: Скрытность — Босс" },
    { "ROGUE_04", "ROGUE", "32. Разбойник: Скрытность — PvP" },
    { "WARRIOR_01", "WARRIOR", "33. Воин: Неистовство — PvE" },
    { "WARRIOR_02", "WARRIOR", "34. Воин: Оружие — Босс СТ" },
    { "WARRIOR_03", "WARRIOR", "35. Воин: Оружие — PvP Арена" },
    { "WARRIOR_04", "WARRIOR", "36. Воин: Защита — Танк" },
    { "DRUID_01", "DRUID", "37. Друид: Баланс — PvE" },
    { "DRUID_02", "DRUID", "38. Друид: Баланс — Босс" },
    { "DRUID_03", "DRUID", "39. Друид: Сила зверя — PvE" },
    { "DRUID_04", "DRUID", "40. Друид: Сила зверя — PvP" },
    { "SHAMAN_01", "SHAMAN", "41. Шаман: Стихии — PvE" },
    { "SHAMAN_02", "SHAMAN", "42. Шаман: Стихии — Босс" },
    { "SHAMAN_03", "SHAMAN", "43. Шаман: Совершенствование — PvE" },
    { "SHAMAN_04", "SHAMAN", "44. Шаман: Совершенствование — PvP" },
    { "DK_01", "DEATHKNIGHT", "45. Рыцарь смерти: Нечестивость — PvE" },
    { "DK_02", "DEATHKNIGHT", "46. Рыцарь смерти: Лёд — Мифик+" },
    { "DK_03", "DEATHKNIGHT", "47. Рыцарь смерти: Кровь — Танк" },
    { "MONK_01", "MONK", "48. Монах: Танцующий с ветром — PvE" },
    { "MONK_02", "MONK", "49. Монах: Танцующий с ветром — PvP" },
    { "MONK_03", "MONK", "50. Монах: Хмелевар — Танк" },
    { "DH_01", "DEMONHUNTER", "51. Охотник на демонов: Истребление — PvE" },
    { "DH_02", "DEMONHUNTER", "52. Охотник на демонов: Истребление — PvP" },
    { "DH_03", "DEMONHUNTER", "53. Охотник на демонов: Месть — Танк" },
    { "EVOKER_01", "EVOKER", "54. Пробудитель: Опустошение — PvE" },
    { "EVOKER_02", "EVOKER", "55. Пробудитель: Насыщатель — Мифик+" },
  }
  for _, e in ipairs(EXTRA) do
    Reg(e[1], e[2], e[3], "PVE", "# PROFILE: " .. e[3] .. "\n# CLASS: " .. e[2] .. "\n" .. BASE_PVE)
  end
  SpArc.DefaultMarkdownProfiles = {
    ["PVE"]  = BASE_PVE,
    ["BOSS"] = BASE_BOSS,
    ["PVP"]  = BASE_PVP,
  }
end

---------------------------------------------------------------------------------------
--                  DEFAULT SPELL CATALOG (MERGED WITH .MD SPELL_BOOK)               --
---------------------------------------------------------------------------------------
local BASE_SPELL_DEFS = {
  TENTACLE_SLAM = {
    key = "TENTACLE_SLAM",
    names = { "Мощный удар щупальцем", "Темное сокрушение", "Shadow Crash", "Tentacle Slam" },
    macroNames = { "M1", "M2", "sp3" },
    ids = { 1227280, 205385, 457042, 1234796 },
    preferredSlot = 1,
    baseCD = 15,
    maxCharges = 2,
    insanityGain = 15,
    fallbackIcon = 136201,
    fallbackKey = "M1",
    appliesDoTs = true,
  },
  VAMPIRIC_TOUCH = {
    key = "VAMPIRIC_TOUCH",
    names = { "Прикосновение вампира", "Vampiric Touch" },
    macroNames = { "sp1pvp", "sp1" },
    ids = { 34914 },
    preferredSlot = 64,
    baseCD = 0,
    maxCharges = 1,
    insanityGain = 6,
    fallbackIcon = 135978,
    fallbackKey = "SR",
    appliesDoTs = true,
  },
  VOID_TORRENT = {
    key = "VOID_TORRENT",
    names = { "Поток бездны", "Поток Бездны", "Void Torrent" },
    macroNames = { "SM1", "SM2" },
    ids = { 263165 },
    preferredSlot = 3,
    baseCD = 45,
    maxCharges = 1,
    insanityGain = 35,
    grantsMFI = true,
    lockChannel = true,
    fallbackIcon = 1386551,
    fallbackKey = "SM1",
  },
  DEVOURING_PLAGUE = {
    key = "DEVOURING_PLAGUE",
    names = { "Слово Тьмы: Безумие", "Всепожирающая чума", "Shadow Word: Madness", "Devouring Plague" },
    macroNames = { "sp4" },
    ids = { 335467 },
    preferredSlot = 63,
    baseCD = 0,
    maxCharges = 1,
    insanityCost = 50,
    grantsMFI = true,
    fallbackIcon = 252997,
    fallbackKey = "R",
    isSpender = true,
    requiresUsable = true,
  },
  MIND_BLAST = {
    key = "MIND_BLAST",
    names = { "Выброс Бездны", "Взрыв разума", "Void Blast", "Mind Blast" },
    macroNames = { "M2", "M1", "M1_2" },
    ids = { 450983, 8092 },
    preferredSlot = 2,
    baseCD = 7.5,
    maxCharges = 1,
    insanityGain = 15,
    fallbackIcon = 136224,
    fallbackKey = "M2",
  },
  VOID_BOLT = {
    key = "VOID_BOLT",
    names = { "Стрела Бездны", "Залп Бездны", "Void Bolt", "Void Volley" },
    macroNames = { "Dps", "1_to_2", "M1" },
    ids = { 205448 },
    preferredSlot = 11,
    baseCD = 6,
    maxCharges = 1,
    insanityGain = 12,
    fallbackIcon = 1386548,
    fallbackKey = "Q",
    procOnly = true,
  },
  SHADOW_WORD_DEATH = {
    key = "SHADOW_WORD_DEATH",
    names = { "Слово Тьмы: Смерть", "Shadow Word: Death" },
    macroNames = { "SM2", "SM1" },
    ids = { 32379 },
    preferredSlot = 4,
    baseCD = 10,
    maxCharges = 1,
    insanityGain = 10,
    fallbackIcon = 136149,
    fallbackKey = "SM2",
    requiresUsable = true,
    isExecute = true,
  },
  MIND_FLAY_INSANITY = {
    key = "MIND_FLAY_INSANITY",
    names = { "Пытка разума: безумие", "Mind Flay: Insanity" },
    macroNames = { "sp8" },
    ids = { 391403 },
    preferredSlot = 10,
    baseCD = 0,
    maxCharges = 1,
    insanityGain = 16,
    fallbackIcon = 136208,
    fallbackKey = "SE",
    procOnly = true,
  },
  MIND_FLAY = {
    key = "MIND_FLAY",
    names = { "Пытка разума", "Mind Flay" },
    macroNames = { "sp8" },
    ids = { 15407, 391403 },
    preferredSlot = 10,
    baseCD = 0,
    maxCharges = 1,
    insanityGain = 12,
    fillerInterruptible = true,
    fallbackIcon = 136208,
    fallbackKey = "SE",
  },
  VOID_ERUPTION = {
    key = "VOID_ERUPTION",
    names = { "Облик Бездны", "Залп Бездны", "Вхождение в Бездну", "Извержение Бездны", "Темное вознесение", "Voidform", "Void Eruption", "Dark Ascension" },
    macroNames = { "1_to_2", "Dps", "Healer" },
    ids = { 228260, 391109 },
    preferredSlot = 11,
    baseCD = 60,
    maxCharges = 1,
    fallbackIcon = 537079,
    fallbackKey = "Q",
  },
  POWER_INFUSION = {
    key = "POWER_INFUSION",
    names = { "Придание сил", "Power Infusion" },
    macroNames = { "1_to_2" },
    ids = { 10060 },
    preferredSlot = 11,
    baseCD = 120,
    maxCharges = 1,
    fallbackIcon = 135939,
    fallbackKey = "Q",
  },
  HALO = {
    key = "HALO",
    names = { "Сияние", "Божественная звезда", "Halo", "Divine Star" },
    macroNames = { "S1" },
    ids = { 120644, 122121, 120517 },
    preferredSlot = 53,
    baseCD = 60,
    maxCharges = 1,
    insanityGain = 10,
    fallbackIcon = 632352,
    fallbackKey = "S1",
  },
  PSYFIEND = {
    key = "PSYFIEND",
    names = { "Исчадие Тьмы", "Ментальный демон", "Игры разума", "Призрак Бездны", "Shadowfiend", "Psyfiend", "Mindgames" },
    macroNames = { "pvptal" },
    ids = { 34433, 211522, 375901, 451235, 200174 },
    preferredSlot = 67,
    baseCD = 60,
    maxCharges = 1,
    fallbackIcon = 136199,
    fallbackKey = "T",
  },
  DISPERSION = {
    key = "DISPERSION",
    names = { "Слияние с тьмой", "Слияние с Тьмой", "Dispersion" },
    macroNames = { "CM2" },
    ids = { 47585 },
    preferredSlot = 6,
    baseCD = 90,
    maxCharges = 1,
    fallbackIcon = 237563,
    fallbackKey = "CM2",
  },
  DESPERATE_PRAYER = {
    key = "DESPERATE_PRAYER",
    names = { "Молитва отчаяния", "Desperate Prayer" },
    macroNames = { "CM1" },
    ids = { 19236 },
    preferredSlot = 5,
    baseCD = 90,
    maxCharges = 1,
    fallbackIcon = 237550,
    fallbackKey = "CM1",
  },
  VAMPIRIC_EMBRACE = {
    key = "VAMPIRIC_EMBRACE",
    names = { "Объятия вампира", "Vampiric Embrace" },
    macroNames = { "AM1" },
    ids = { 15286 },
    preferredSlot = 7,
    baseCD = 120,
    maxCharges = 1,
    fallbackIcon = 136230,
    fallbackKey = "AM1",
  },
  FADE = {
    key = "FADE",
    names = { "Уход в тень", "Ментальный крик", "Fade", "Psychic Scream" },
    macroNames = { "p2", "p12", "p4" },
    ids = { 586, 8122 },
    preferredSlot = 71,
    baseCD = 30,
    maxCharges = 1,
    fallbackIcon = 135994,
    fallbackKey = "Z",
  },
  POWER_WORD_SHIELD = {
    key = "POWER_WORD_SHIELD",
    names = { "Слово силы: Щит", "Power Word: Shield" },
    macroNames = { "H_Shield", "p4" },
    ids = { 17 },
    preferredSlot = 62,
    baseCD = 7.5,
    maxCharges = 1,
    fallbackIcon = 135940,
    fallbackKey = "SB3",
  },
  SILENCE = {
    key = "SILENCE",
    names = { "Безмолвие", "Silence" },
    macroNames = { "F" },
    ids = { 15487 },
    preferredSlot = 65,
    baseCD = 45,
    maxCharges = 1,
    fallbackIcon = 458230,
    fallbackKey = "F",
  },
  PSYCHIC_HORROR = {
    key = "PSYCHIC_HORROR",
    names = { "Глубинный ужас", "Psychic Horror" },
    macroNames = { "p2vp", "M3" },
    ids = { 64044 },
    preferredSlot = 12,
    baseCD = 45,
    maxCharges = 1,
    fallbackIcon = 237568,
    fallbackKey = "SQ",
  },
}

local SPELL_DEFS = {}
for k, v in pairs(BASE_SPELL_DEFS) do
  SPELL_DEFS[k] = v
end

local ACTIVE_SLOTS = {
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
  61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72,
}

local SLOT_DEFAULT_KEYBIND = {
  [1]  = "M1",
  [2]  = "M2",
  [3]  = "SM1",
  [4]  = "SM2",
  [5]  = "CM1",
  [6]  = "CM2",
  [7]  = "AM1",
  [8]  = "AM2",
  [9]  = "E",
  [10] = "SE",
  [11] = "Q",
  [12] = "SQ",
  [61] = "B3",
  [62] = "SB3",
  [63] = "R",
  [64] = "SR",
  [65] = "F",
  [66] = "SF",
  [67] = "T",
  [68] = "ST",
  [69] = "CR",
  [70] = "V",
  [71] = "Z",
  [72] = "SZ",
}

local ACTION_BAR_RANGES = {
  { base = 1,   count = 12, bind = "ACTIONBUTTON" },
  { base = 61,  count = 12, bind = "MULTIACTIONBAR1BUTTON" },
  { base = 49,  count = 12, bind = "MULTIACTIONBAR2BUTTON" },
  { base = 25,  count = 12, bind = "MULTIACTIONBAR3BUTTON" },
  { base = 37,  count = 12, bind = "MULTIACTIONBAR4BUTTON" },
}

local CLICKCAST_SHORT = {
  button1 = "M1",
  button2 = "M2",
  shiftbutton1 = "SM1",
  shiftbutton2 = "SM2",
  ctrlbutton1 = "CM1",
  ctrlbutton2 = "CM2",
  altbutton1 = "AM1",
  altbutton2 = "AM2",
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

local function GetSlotKeybind(slot)
  if not slot or slot < 1 then return nil end
  local cmd = SlotToBindingCommand(slot)

  -- 1. CombatMode Click-Cast bindings (M1, M2, SM1, SM2, CM1, CM2, AM1, AM2)
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

  -- 2. Bartender4 (LibActionButton-1.0 / LibKeyBound-1.0) live button keybind
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

  -- 3. Standard WoW Binding table for the action slot command
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

  -- 4. Fallback default slot map
  return SLOT_DEFAULT_KEYBIND[slot]
end

-- Runtime state tracking
local lastCastAt = {}
local lastSlotScanAt = 0
local targetDoTsUntil = 0
local lastTargetGUID = nil
local trackedInsanity = 0
local spellChargesUsed = {}
local spellChargeStart = {}
local mfiProcUntil = 0

local castState = {
  active = false,
  isChannel = false,
  defKey = nil,
  name = "",
  icon = 136208,
  startTime = 0,
  endTime = 0,
}

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

-- Extracts #showtooltip and /cast lines from a macro body while strictly ignoring /stopmacro and /cancelaura
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

local function ScanActionSlotsAndSpells(force)
  local now = GetTime()
  if not force and (now - lastSlotScanAt) < 1.5 then
    return
  end
  lastSlotScanAt = now

  -- 1. Resolve all valid spellIDs and live icons for every spell definition
  for _, def in pairs(SPELL_DEFS) do
    local idSet = {}
    local resolvedID, resolvedIcon
    for _, id in ipairs(def.ids or {}) do
      idSet[id] = true
      if C_Spell and C_Spell.GetOverrideSpell then
        local okO, over = pcall(C_Spell.GetOverrideSpell, id)
        if okO and type(over) == "number" and not IsSecret(over) and over > 0 then
          idSet[over] = true
        end
      end
      if C_Spell and C_Spell.GetBaseSpell then
        local okB, base = pcall(C_Spell.GetBaseSpell, id)
        if okB and type(base) == "number" and not IsSecret(base) and base > 0 then
          idSet[base] = true
        end
      end
    end
    if C_Spell and C_Spell.GetSpellInfo then
      for _, nm in ipairs(def.names or {}) do
        local ok, info = pcall(C_Spell.GetSpellInfo, nm)
        if ok and type(info) == "table" and not IsSecret(info.spellID) and info.spellID then
          idSet[info.spellID] = true
          if not resolvedID then
            resolvedID = info.spellID
            resolvedIcon = not IsSecret(info.iconID) and info.iconID or nil
          end
        end
      end
      if not resolvedID then
        for _, id in ipairs(def.ids or {}) do
          local eid = id
          if C_Spell.GetOverrideSpell then
            local okO, over = pcall(C_Spell.GetOverrideSpell, id)
            if okO and type(over) == "number" and not IsSecret(over) and over > 0 then
              eid = over
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

  -- 2. Scan Bartender4 buttons & ActionSlots purely by spellID and macro tooltip/cast content (NEVER by macro name!)
  local assistedSlots = BuildAssistedSlotSet()
  local spellIDToSlot = {}
  local tooltipLinesBySlot = {}
  local castLinesBySlot = {}
  local GetMacroSpell = _G.GetMacroSpell

  for _, slot in ipairs(ACTIVE_SLOTS) do
    if not assistedSlots[slot] then
      -- A) Bartender4 LibActionButton-1.0 :GetSpellId()
      local btBtn = _G["BT4Button" .. slot]
      if btBtn and btBtn.GetSpellId then
        local okS, btSpellID = pcall(btBtn.GetSpellId, btBtn)
        if okS and not IsSecret(btSpellID) and type(btSpellID) == "number" and btSpellID > 0 then
          if not spellIDToSlot[btSpellID] then
            spellIDToSlot[btSpellID] = slot
          end
        end
      end

      -- B) WoW GetActionInfo(slot) + macro tooltip/cast lines
      if GetActionInfo then
        local ok, aType, aID, aSubType = pcall(GetActionInfo, slot)
        if ok and not IsSecret(aType) and aType then
          if aType == "spell" and not IsSecret(aID) and type(aID) == "number" and aID > 0 then
            if not spellIDToSlot[aID] then
              spellIDToSlot[aID] = slot
            end
          elseif aType == "macro" then
            if not IsSecret(aSubType) and aSubType == "spell" and not IsSecret(aID) and type(aID) == "number" and aID > 0 then
              if not spellIDToSlot[aID] then
                spellIDToSlot[aID] = slot
              end
            elseif GetMacroSpell and not IsSecret(aID) and type(aID) == "number" and aID > 0 then
              local okMS, msID = pcall(GetMacroSpell, aID)
              if okMS and not IsSecret(msID) and type(msID) == "number" and msID > 0 and not spellIDToSlot[msID] then
                spellIDToSlot[msID] = slot
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

  -- 3. Match each spell definition to its live Bartender4 slot and keybind
  for _, def in pairs(SPELL_DEFS) do
    local foundSlot = nil

    -- Priority 1: Direct spellID match from BT4Button:GetSpellId() / GetActionInfo / GetMacroSpell
    if def.liveSpellID and spellIDToSlot[def.liveSpellID] then
      foundSlot = spellIDToSlot[def.liveSpellID]
    end
    if not foundSlot and def.idSet then
      for sid, _ in pairs(def.idSet) do
        if spellIDToSlot[sid] then
          foundSlot = spellIDToSlot[sid]
          break
        end
      end
    end

    -- Priority 2: C_ActionBar.FindSpellActionButtons(sid) (same API CombatMode uses for macro/spell slots)
    if not foundSlot and C_ActionBar and C_ActionBar.FindSpellActionButtons and def.idSet then
      for sid, _ in pairs(def.idSet) do
        local okF, slots = pcall(C_ActionBar.FindSpellActionButtons, sid)
        if okF and type(slots) == "table" and not IsSecret(slots) then
          for _, s in pairs(slots) do
            if type(s) == "number" and s > 0 and not assistedSlots[s] then
              if not foundSlot or s < foundSlot then
                foundSlot = s
              end
            end
          end
        end
        if foundSlot then break end
      end
    end

    -- Priority 3: Macro #showtooltip line (handles stance-conditional tooltips when out of Shadowform)
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
                if line:find(tostring(sid), 1, true) then
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

    -- Priority 4: Macro /cast line (strictly excluding /stopmacro and /cancelaura)
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
                if line:find(tostring(sid), 1, true) then
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
    local kb = foundSlot and GetSlotKeybind(foundSlot) or nil
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
      -- Don't overwrite spell icon with Shadowform icon (136200) when out of Shadowform on a conditional macro
      if tex and tex ~= 134400 and tex ~= 136200 and def.key ~= "MIND_FLAY_INSANITY" then
        def.liveIcon = tex
      end
    end
  end

  -- MIND_FLAY_INSANITY is an override of MIND_FLAY (15407 -> 391403) on the exact same button (e.g. SE)
  local mfDef = SPELL_DEFS["MIND_FLAY"]
  local mfiDef = SPELL_DEFS["MIND_FLAY_INSANITY"]
  if mfDef and mfiDef and not mfiDef.slot and mfDef.slot then
    mfiDef.slot = mfDef.slot
    mfiDef.keybind = mfDef.keybind
  end
end

local function MatchSpellToDefKey(spellID, spellName)
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
  end

  for k, def in pairs(SPELL_DEFS) do
    if k ~= "MIND_FLAY_INSANITY" then
      if spellID and not IsSecret(spellID) then
        if def.liveSpellID == spellID or (baseID and def.liveSpellID == baseID) then
          return k
        end
        for _, id in ipairs(def.ids or {}) do
          if id == spellID or (baseID and id == baseID) then
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

local function GetAssistedSuggestedDefKey()
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
  local defKey = MatchSpellToDefKey(spellID, nil)
  return defKey, spellID
end

local function GetTrackedSpellCharges(defKey, now)
  local def = SPELL_DEFS[defKey]
  local maxCh = (def and (def.liveMaxCharges or def.maxCharges)) or 1
  local cdDur = (def and (def.liveChargeCD or def.baseCD)) or 7.5
  if cdDur <= 0 then cdDur = 7.5 end
  local used = spellChargesUsed[defKey] or 0
  local chStart = spellChargeStart[defKey] or 0
  if used > 0 and chStart > 0 then
    local elapsed = now - chStart
    local recovered = math.floor(elapsed / cdDur)
    if recovered > 0 then
      used = math.max(0, used - recovered)
      spellChargesUsed[defKey] = used
      spellChargeStart[defKey] = used > 0 and (chStart + recovered * cdDur) or 0
    end
  end
  return math.max(0, maxCh - used), maxCh, cdDur, (spellChargeStart[defKey] or 0)
end

local function GetTargetHPPercent()
  if UnitHealth and UnitHealthMax then
    local ok1, hp = pcall(UnitHealth, "target")
    local ok2, maxHp = pcall(UnitHealthMax, "target")
    if ok1 and ok2 and not IsSecret(hp) and not IsSecret(maxHp) and type(hp) == "number" and type(maxHp) == "number" and maxHp > 0 then
      return (hp / maxHp) * 100
    end
  end
  return nil
end

local lastSpellAudit = {}

local function FormatSecretOrVal(v)
  if IsSecret(v) then return "SECRET" end
  return tostring(v)
end

local function EvaluateSpellState(defKey, assistedKey)
  local def = SPELL_DEFS[defKey]
  if not def then
    return false, 0, 0, 0, false, false, 134400, "", 0
  end
  local now = GetTime()
  local spellID = def.liveSpellID or (def.ids and def.ids[1])
  local slot = def.slot

  local isProc = false
  local isVoidBlastOverride = false
  local overlayRaw = "false"
  if C_Spell and C_Spell.IsSpellOverlayed then
    for _, id in ipairs(def.ids or {}) do
      local okP, over = pcall(C_Spell.IsSpellOverlayed, id)
      if okP then
        if IsSecret(over) then
          overlayRaw = "SECRET"
        elseif over then
          isProc = true
          overlayRaw = "true(" .. tostring(id) .. ")"
          break
        end
      end
    end
    if not isProc and spellID then
      local okP, over = pcall(C_Spell.IsSpellOverlayed, spellID)
      if okP then
        if IsSecret(over) then
          overlayRaw = "SECRET"
        elseif over then
          isProc = true
          overlayRaw = "true(" .. tostring(spellID) .. ")"
        end
      end
    end
  end
  if defKey == "MIND_FLAY_INSANITY" then
    if C_Spell and C_Spell.GetOverrideSpell then
      local okO, over = pcall(C_Spell.GetOverrideSpell, 15407)
      if okO and not IsSecret(over) and over == 391403 then
        isProc = true
        overlayRaw = "override(391403)"
      end
    end
    if assistedKey == "MIND_FLAY_INSANITY" then
      isProc = true
      overlayRaw = "assisted(391403)"
    end
  elseif defKey == "MIND_BLAST" and C_Spell and C_Spell.GetOverrideSpell then
    local okO, over = pcall(C_Spell.GetOverrideSpell, 8092)
    if okO and not IsSecret(over) and over == 450983 then
      isVoidBlastOverride = true
      spellID = 450983
      overlayRaw = "override(450983)"
    end
  elseif defKey == "VOID_BOLT" then
    if C_Spell and C_Spell.GetOverrideSpell then
      local okO, over = pcall(C_Spell.GetOverrideSpell, 228260)
      if okO and not IsSecret(over) and type(over) == "number" and over > 0 and over ~= 228260 then
        isProc = true
        spellID = over
        overlayRaw = "override(" .. tostring(over) .. ")"
      end
    end
    if assistedKey == "VOID_BOLT" then
      isProc = true
      overlayRaw = "assisted(VOID_BOLT)"
    end
  end

  local isOnCD = false
  local remSec = 0
  local durSec = def.baseCD or 0
  local startTime = 0
  local gotCleanCD = false
  local charges = def.liveMaxCharges or def.maxCharges or 1
  local cdRaw = "0s"
  local chargesRaw = "-"

  if C_Spell and C_Spell.GetSpellCharges and spellID then
    local okC, ch = pcall(C_Spell.GetSpellCharges, spellID)
    if okC and type(ch) == "table" then
      if not IsSecret(ch.maxCharges) and type(ch.maxCharges) == "number" and ch.maxCharges >= 1 then
        def.liveMaxCharges = ch.maxCharges
      end
      if not IsSecret(ch.cooldownDuration) and type(ch.cooldownDuration) == "number" and ch.cooldownDuration > 1.5 then
        def.liveChargeCD = ch.cooldownDuration
      end
      if IsSecret(ch.currentCharges) then
        chargesRaw = "SECRET"
      elseif ch.currentCharges then
        gotCleanCD = true
        charges = ch.currentCharges
        local maxCh = def.liveMaxCharges or def.maxCharges or 1
        chargesRaw = tostring(ch.currentCharges) .. "/" .. tostring(maxCh)
        spellChargesUsed[defKey] = math.max(0, maxCh - ch.currentCharges)
        if spellChargesUsed[defKey] == 0 then
          spellChargeStart[defKey] = 0
        elseif not IsSecret(ch.cooldownStartTime) and type(ch.cooldownStartTime) == "number" and ch.cooldownStartTime > 0 then
          spellChargeStart[defKey] = ch.cooldownStartTime
        end
        if ch.currentCharges >= 1 then
          isOnCD = false
        else
          isOnCD = true
          if not IsSecret(ch.cooldownStartTime) and not IsSecret(ch.cooldownDuration) then
            startTime = ch.cooldownStartTime or 0
            durSec = ch.cooldownDuration or durSec
            remSec = math.max(0, startTime + durSec - now)
            cdRaw = string.format("%.1fs/%.1fs", remSec, durSec)
          end
        end
      end
    end
  end

  if not gotCleanCD and C_Spell and C_Spell.GetSpellCooldown and spellID then
    local okCD, cd = pcall(C_Spell.GetSpellCooldown, spellID)
    if okCD and type(cd) == "table" then
      if IsSecret(cd.duration) or IsSecret(cd.startTime) then
        cdRaw = "SECRET"
      else
        gotCleanCD = true
        if cd.duration and cd.duration > 1.6 and cd.startTime and cd.startTime > 0 then
          local r = cd.startTime + cd.duration - now
          if r > 0.15 then
            isOnCD = true
            remSec = r
            durSec = cd.duration
            startTime = cd.startTime
            charges = 0
            cdRaw = string.format("%.1fs/%.1fs", remSec, durSec)
          end
        end
      end
    end
  end

  if not gotCleanCD and slot and GetActionCooldown then
    local okA, s, d = pcall(GetActionCooldown, slot)
    if okA then
      if IsSecret(s) or IsSecret(d) then
        if cdRaw == "0s" then cdRaw = "ACT_SECRET" end
      elseif type(d) == "number" then
        gotCleanCD = true
        if d > 1.6 and s and s > 0 then
          local r = s + d - now
          if r > 0.15 then
            isOnCD = true
            remSec = r
            durSec = d
            startTime = s
            charges = 0
            cdRaw = string.format("act:%.1fs/%.1fs", remSec, durSec)
          end
        end
      end
    end
  end

  -- Software cooldown / charge fallback ONLY when WoW API returned SECRET (not gotCleanCD)!
  if not gotCleanCD then
    local maxCh = def.liveMaxCharges or def.maxCharges or 1
    if maxCh > 1 or defKey == "MIND_BLAST" or defKey == "TENTACLE_SLAM" then
      local simCh, simMax, simDur, simStart = GetTrackedSpellCharges(defKey, now)
      charges = simCh
      chargesRaw = "sim:" .. tostring(simCh) .. "/" .. tostring(simMax)
      if simCh <= 0 then
        isOnCD = true
        startTime = simStart
        durSec = simDur
        remSec = math.max(0, simStart + simDur - now)
        cdRaw = string.format("sim:%.1fs", remSec)
      end
    else
      local last = lastCastAt[defKey]
      if last and def.baseCD and def.baseCD > 1.6 then
        local elapsed = now - last
        if elapsed < (def.baseCD - 0.15) then
          isOnCD = true
          remSec = def.baseCD - elapsed
          durSec = def.baseCD
          startTime = last
          charges = 0
          cdRaw = string.format("timer:%.1fs", remSec)
        end
      end
    end

    -- C_AssistedCombat C++ Cooldown Truth: when Blizzard suggests Mind Flay filler (15407),
    -- all higher-priority rotational cooldown generators are guaranteed to be on cooldown!
    if assistedKey == "MIND_FLAY" and (defKey == "MIND_BLAST" or defKey == "VOID_TORRENT" or defKey == "TENTACLE_SLAM") then
      isOnCD = true
      charges = 0
      cdRaw = "AssistSaysOnCD(MF)"
    end
  end

  if assistedKey == defKey then
    isOnCD = false
    if charges < 1 then charges = 1 end
  end

  if isVoidBlastOverride and not isOnCD then
    isProc = true
  end

  -- Detailed Spellbook & Bartender4 Usability Evaluation + Telemetry Audit
  local bookUsableRaw = "n/a"
  local actUsableRaw = "n/a"
  local btColorRaw = "n/a"
  local usableSource = "default(true)"

  local bookUsableVal, bookNoPowerVal = nil, nil
  if C_Spell and C_Spell.IsSpellUsable and spellID then
    local okU, u, noP = pcall(C_Spell.IsSpellUsable, spellID)
    if okU then
      bookUsableRaw = FormatSecretOrVal(u) .. "/noP=" .. FormatSecretOrVal(noP)
      if not IsSecret(u) and type(u) == "boolean" then
        bookUsableVal = u
        bookNoPowerVal = (not IsSecret(noP) and noP == true) or false
      end
    end
  end

  local actUsableVal, actNoManaVal = nil, nil
  local slotActiveSpellID = nil
  if slot then
    if GetActionInfo then
      local okAI, aType, aID, aSub = pcall(GetActionInfo, slot)
      if okAI and not IsSecret(aID) and type(aID) == "number" then
        slotActiveSpellID = aID
      end
    end
    if IsUsableAction then
      local okA, u, noM = pcall(IsUsableAction, slot)
      if okA then
        actUsableRaw = FormatSecretOrVal(u) .. "/noM=" .. FormatSecretOrVal(noM) .. (slotActiveSpellID and ("(id:" .. slotActiveSpellID .. ")") or "")
        if not IsSecret(u) and type(u) == "boolean" then
          actUsableVal = u
          actNoManaVal = (not IsSecret(noM) and noM == true) or false
        end
      end
    end
    local btBtn = _G["BT4Button" .. slot]
    if btBtn and btBtn.icon and btBtn.icon.GetVertexColor then
      local okV, r, g, b = pcall(btBtn.icon.GetVertexColor, btBtn.icon)
      if okV and not IsSecret(r) and type(r) == "number" then
        btColorRaw = string.format("%.2f,%.2f,%.2f", r, g or 1, b or 1)
      end
    end
  end

  local isUsable = true
  if def.isExecute then
    -- In WoW, Shadow Word: Death (32379) is always IsSpellUsable=true even at 100% Target HP!
    -- Only mark it usable in rotation during Execute range (<=20% HP), Deathspeaker overlay proc, or AssistedCombat recommendation!
    local tgtHP = GetTargetHPPercent()
    if isProc then
      isUsable = true
      usableSource = "ExecuteProcOverlay"
    elseif assistedKey == defKey then
      isUsable = true
      usableSource = "ExecuteAssistedCombat"
    elseif tgtHP and tgtHP <= 20 then
      isUsable = true
      usableSource = string.format("ExecuteHP(%.1f%%<=20%%)", tgtHP)
    else
      isUsable = false
      usableSource = "ExecuteWait(>20%HP)"
    end
  elseif def.requiresUsable then
    local gotCleanUsable = false

    -- 1. Primary truth: Spellbook C_Spell.IsSpellUsable(spellID)
    if bookUsableVal ~= nil then
      isUsable = (bookUsableVal == true) and (not bookNoPowerVal)
      gotCleanUsable = true
      usableSource = "SpellBook(" .. tostring(spellID) .. ")"
    end

    -- 2. Secondary truth: ActionSlot IsUsableAction(slot), ONLY if the macro isn't currently evaluating Shadowform (15473) or Dispel Magic (528)
    if not gotCleanUsable and actUsableVal ~= nil then
      local isFallbackMacroSpell = (slotActiveSpellID == 15473 or slotActiveSpellID == 528)
      if not isFallbackMacroSpell then
        isUsable = (actUsableVal == true) and (not actNoManaVal)
        gotCleanUsable = true
        usableSource = "ActionBar(slot:" .. tostring(slot) .. ")"
      else
        usableSource = "IgnoredMacroFallback(id:" .. tostring(slotActiveSpellID) .. ")"
      end
    end

    -- 3. Bartender4 icon vertex color check: when LibActionButton-1.0 tints the icon blue (0.5,0.5,1.0 for noInsanity/noMana) or grey (0.4,0.4,0.4 for unusable)
    if slot then
      local btBtn = _G["BT4Button" .. slot]
      if btBtn and btBtn.icon and btBtn.icon.GetVertexColor then
        local okV, r, g, b = pcall(btBtn.icon.GetVertexColor, btBtn.icon)
        if okV and not IsSecret(r) and type(r) == "number" and r < 0.85 then
          isUsable = false
          gotCleanUsable = true
          usableSource = "BT4VertexTint(" .. btColorRaw .. ")"
        end
      end
    end

    -- 4. Direct Insanity power check if UnitPower("player", 13) is not secret
    if def.isSpender and UnitPower then
      local okP, rawP = pcall(UnitPower, "player", 13)
      if okP and not IsSecret(rawP) and type(rawP) == "number" then
        if rawP < 45 and not isProc and assistedKey ~= defKey then
          isUsable = false
          gotCleanUsable = true
          usableSource = "UnitPower(" .. tostring(rawP) .. "<45)"
        elseif rawP >= 50 and not gotCleanUsable then
          isUsable = true
          gotCleanUsable = true
          usableSource = "UnitPower(" .. tostring(rawP) .. ">=50)"
        end
      end
    end

    -- 5. Fallback if everything is secret in Midnight 12.1.5
    if not gotCleanUsable then
      if def.isSpender then
        isUsable = (assistedKey == defKey) or isProc
        usableSource = "SecretFallback(AssistedOrProcOnly)"
      else
        isUsable = false
        usableSource = "SecretFallback(false)"
      end
    end

    if isProc or assistedKey == defKey then
      isUsable = true
      usableSource = isProc and "ProcOverride" or "AssistedCombat"
    end
  end

  local finalReady = (not isOnCD)
  if def.procOnly and not isProc then
    finalReady = false
    isUsable = false
    usableSource = "procOnly(false)"
  end

  -- Never recommend a spell in the rotation queue if it is NOT placed on any action bar slot with a keybind!
  if (not slot or not def.keybind or def.keybind == "") and not SpArc.testMode then
    finalReady = false
    isUsable = false
    usableSource = "NotOnActionBar"
  end

  lastSpellAudit[defKey] = {
    key = defKey,
    spellID = spellID,
    slot = slot,
    keybind = def.keybind or "",
    bookUsableRaw = bookUsableRaw,
    actUsableRaw = actUsableRaw,
    btColorRaw = btColorRaw,
    cdRaw = cdRaw,
    chargesRaw = chargesRaw,
    overlayRaw = overlayRaw,
    isReady = finalReady,
    isUsable = isUsable,
    isProc = isProc,
    usableSource = usableSource,
  }

  if not finalReady and def.procOnly and not isProc then
    return false, remSec, durSec, startTime, false, false, def.liveIcon or def.fallbackIcon, def.keybind or "", 0
  end

  return finalReady, remSec, durSec, startTime, isUsable, isProc, def.liveIcon or def.fallbackIcon, def.keybind or "", charges
end

local function CheckTargetHasDoTs(assistedKey)
  local now = GetTime()
  if assistedKey == "VAMPIRIC_TOUCH" then
    return false
  end
  if targetDoTsUntil and now < targetDoTsUntil then
    return true
  end
  if assistedKey == "TENTACLE_SLAM" then
    return false
  end
  if assistedKey and assistedKey ~= "TENTACLE_SLAM" and assistedKey ~= "VAMPIRIC_TOUCH" then
    return true
  end

  if C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID then
    for _, dotID in ipairs({ 34914, 589 }) do
      local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, "target", dotID)
      if ok and type(aura) == "table" then
        if not IsSecret(aura.expirationTime) and type(aura.expirationTime) == "number" and aura.expirationTime > 0 then
          if (aura.expirationTime - now) > 3.0 then
            return true
          end
        else
          return true
        end
      end
    end
  end

  for i = 1, 16 do
    local btn = _G["ElvUF_TargetDebuffsButton" .. i]
    if btn and SafeBool(btn.IsShown, btn) then
      local sid = btn.spellID
      if not IsSecret(sid) and (sid == 34914 or sid == 589) then
        return true
      end
      local iconTex = btn.Icon and btn.Icon.GetTexture and btn.Icon:GetTexture()
      if not IsSecret(iconTex) and (iconTex == 135978 or iconTex == 136207) then
        return true
      end
    end
  end

  return false
end

local function GetPlayerHPPercent()
  if SpArc.testMode then
    return 18
  end
  if UnitHealth and UnitHealthMax then
    local ok1, hp = pcall(UnitHealth, "player")
    local ok2, maxHp = pcall(UnitHealthMax, "player")
    if ok1 and ok2 and not IsSecret(hp) and not IsSecret(maxHp) and type(hp) == "number" and type(maxHp) == "number" and maxHp > 0 then
      return (hp / maxHp) * 100
    end
  end
  if _G.LowHealthFrame and _G.LowHealthFrame.IsShown and SafeBool(_G.LowHealthFrame.IsShown, _G.LowHealthFrame) then
    return 20
  end
  return 100
end

local function RefreshTrackedInsanity()
  if UnitPower then
    local ok, p = pcall(UnitPower, "player", 13)
    if ok and not IsSecret(p) and type(p) == "number" then
      trackedInsanity = p
    end
  end
end

---------------------------------------------------------------------------------------
--                  DATABASE, PRESETS (55) & VISUAL SETTINGS                         --
---------------------------------------------------------------------------------------
local DEFAULT_VISUAL = {
  arcRadius = 135,
  arcOffsetY = 0,
  primaryScale = 1.50,
  queueScale = 1.00,
  queueLength = 5,
  castbarWidth = 276,
  castbarOffsetY = -135,
  emergencyHP = 25,
  showInterruptAlert = true,
  showCastbar = true,
  alwaysShowCDs = false,
  enableTelemetry = true,
  showMinimapButton = true,
  minimapAngle = 205,
}

function SpArc:EnsureDB()
  _G.SpArcDB = _G.SpArcDB or _G.SparkArcDB or {}
  _G.SparkArcDB = _G.SpArcDB
  local db = _G.SpArcDB

  db.mode = db.mode or "AUTO"
  db.activePresetID = db.activePresetID or "PRIEST_01_SHADOW_PVE"
  db.autoPresets = db.autoPresets or {
    PVE  = "PRIEST_01_SHADOW_PVE",
    BOSS = "PRIEST_02_SHADOW_BOSS",
    PVP  = "PRIEST_03_SHADOW_PVP",
  }
  db.visual = db.visual or {}
  for k, v in pairs(DEFAULT_VISUAL) do
    if db.visual[k] == nil then
      db.visual[k] = v
    end
  end

  db.presets = db.presets or {}
  db.presetOrder = db.presetOrder or {}
  if db.profileSchemaVersion ~= SpArc.PROFILE_SCHEMA_VERSION or #db.presetOrder == 0 then
    db.presetOrder = {}
    for _, id in ipairs(SpArc.BuiltInPresetOrder) do
      local bp = SpArc.BuiltInPresets[id]
      if bp then
        db.presetOrder[#db.presetOrder + 1] = id
        db.presets[id] = {
          id = bp.id,
          class = bp.class,
          title = bp.title,
          mode = bp.mode,
          md = bp.md,
        }
      end
    end
    db.profileSchemaVersion = SpArc.PROFILE_SCHEMA_VERSION
  end

  db.telemetryLog = db.telemetryLog or {}
  db.lastSpellAudit = db.lastSpellAudit or {}
  return db
end

function SpArc:RebuildParsedProfiles()
  local db = SpArc:EnsureDB()
  SpArc.ParsedPresets = {}
  for id, p in pairs(db.presets) do
    if p and type(p.md) == "string" then
      local compiled = SpArc:ParseMarkdownFSM(p.md)
      SpArc.ParsedPresets[id] = compiled
    end
  end
end

local function SyncSpellDefsFromProfile(parsed)
  if not parsed or not parsed.spells then return end
  local changed = false
  for k, spDef in pairs(parsed.spells) do
    if not SPELL_DEFS[k] then
      SPELL_DEFS[k] = spDef
      changed = true
    else
      -- Merge custom attributes from .md SPELL line
      local dst = SPELL_DEFS[k]
      if spDef.fillerInterruptible ~= nil then dst.fillerInterruptible = spDef.fillerInterruptible end
      if spDef.lockChannel ~= nil then dst.lockChannel = spDef.lockChannel end
      if spDef.insanityGain and spDef.insanityGain > 0 then dst.insanityGain = spDef.insanityGain end
      if spDef.insanityCost and spDef.insanityCost > 0 then dst.insanityCost = spDef.insanityCost end
    end
  end
  if changed then
    ScanActionSlotsAndSpells(true)
  end
end

local function SelectActiveParsedProfile()
  local db = SpArc:EnsureDB()
  local mode = db.mode or "AUTO"
  local presetID = db.activePresetID or "PRIEST_01_SHADOW_PVE"

  if mode == "AUTO" then
    if SafeBool(UnitIsPlayer, "target") then
      presetID = (db.autoPresets and db.autoPresets.PVP) or "PRIEST_03_SHADOW_PVP"
    else
      local okC, classif = pcall(UnitClassification, "target")
      local okL, lvl = pcall(UnitLevel, "target")
      if (okC and not IsSecret(classif) and (classif == "worldboss" or classif == "rareelite" or classif == "elite"))
        or (okL and not IsSecret(lvl) and lvl == -1) then
        presetID = (db.autoPresets and db.autoPresets.BOSS) or "PRIEST_02_SHADOW_BOSS"
      else
        presetID = (db.autoPresets and db.autoPresets.PVE) or "PRIEST_01_SHADOW_PVE"
      end
    end
  elseif mode == "PVE" or mode == "BOSS" or mode == "PVP" then
    presetID = (db.autoPresets and db.autoPresets[mode]) or presetID
  end

  local parsed = (SpArc.ParsedPresets and SpArc.ParsedPresets[presetID])
    or (SpArc.ParsedPresets and SpArc.ParsedPresets["PRIEST_01_SHADOW_PVE"])
  SyncSpellDefsFromProfile(parsed)
  return parsed, presetID
end

---------------------------------------------------------------------------------------
--                  FSM CONDITION EVALUATOR & QUEUE BUILDER                          --
---------------------------------------------------------------------------------------
local function EvalSingleCondition(condStr, simHasDoTs, simReady, simUsable, simProcs)
  if not condStr or condStr == "ALWAYS" then
    return true
  end
  local norm = condStr:gsub("%s+AND%s+", "\1")
  for rawClause in norm:gmatch("([^\1]+)") do
    local c = rawClause:gsub("^%s+", ""):gsub("%s+$", "")
    if c ~= "" then
      if c == "NOT target.has_dots" then
        if simHasDoTs then return false end
      elseif c == "target.has_dots" then
        if not simHasDoTs then return false end
      else
        local readySp = c:match("^READY%(([A-Z0-9_]+)%)$")
        if readySp then
          if not simReady[readySp] then return false end
        else
          local notReadySp = c:match("^NOT%s+READY%(([A-Z0-9_]+)%)$")
          if notReadySp then
            if simReady[notReadySp] then return false end
          else
            local usableSp = c:match("^USABLE%(([A-Z0-9_]+)%)$")
            if usableSp then
              if not simReady[usableSp] or not simUsable[usableSp] then return false end
            else
              local procSp = c:match("^PROC%(([A-Z0-9_]+)%)$")
              if procSp then
                local pKey = (procSp == "VOID_BLAST") and "MIND_BLAST" or procSp
                if not simProcs[pKey] then return false end
              end
            end
          end
        end
      end
    end
  end
  return true
end

-- Detects what spell the player is currently channeling (if any)
local function GetActiveChannelDefKey(now)
  if UnitChannelInfo then
    local ok, n = pcall(UnitChannelInfo, "player")
    if ok and not IsSecret(n) and type(n) == "string" and n ~= "" then
      local k = MatchSpellToDefKey(nil, n)
      if k then return k end
    end
  end
  if castState.active and castState.isChannel and now < castState.endTime then
    return castState.defKey
  end
  if SpArc.testMode and (now % 6) >= 3 then
    return "MIND_FLAY"
  end
  return nil
end

local function BuildRotationQueue(maxSlots)
  local db = SpArc:EnsureDB()
  maxSlots = maxSlots or (db.visual and db.visual.queueLength) or 5
  RefreshTrackedInsanity()
  local assistedKey = GetAssistedSuggestedDefKey()
  if assistedKey == "DEVOURING_PLAGUE" and trackedInsanity < 50 then
    trackedInsanity = 55
  end

  local parsed = SelectActiveParsedProfile()
  if not parsed or not parsed.rules then
    return {}, {}, parsed, nil, false, false
  end

  local states = {}
  local simReady = {}
  local simUsable = {}
  local simProcs = {}
  local simCharges = {}

  for k, _ in pairs(SPELL_DEFS) do
    local isReady, remSec, durSec, startTime, isUsable, isProc, icon, keybind, charges = EvaluateSpellState(k, assistedKey)
    states[k] = {
      key = k,
      isReady = isReady,
      remSec = remSec,
      durSec = durSec,
      startTime = startTime,
      isUsable = isUsable,
      isProc = isProc,
      icon = icon,
      keybind = keybind,
      charges = charges,
    }
    simReady[k] = isReady
    simUsable[k] = isUsable
    simProcs[k] = isProc
    simCharges[k] = charges or (isReady and 1 or 0)
  end

  local queue = {}
  local simHasDoTs = CheckTargetHasDoTs(assistedKey)
  if states["DEVOURING_PLAGUE"] and not states["DEVOURING_PLAGUE"].isUsable then
    trackedInsanity = math.min(trackedInsanity, 25)
  elseif states["DEVOURING_PLAGUE"] and states["DEVOURING_PLAGUE"].isUsable and trackedInsanity < 50 then
    trackedInsanity = 50
  end
  local simInsanity = trackedInsanity

  local dpUsedInQueue = false

  for step = 1, maxSlots do
    -- Strictly obey the real spellbook/Bartender4 usability of Devouring Plague (and only queue it once)!
    if dpUsedInQueue then
      simUsable["DEVOURING_PLAGUE"] = false
    else
      simUsable["DEVOURING_PLAGUE"] = (states["DEVOURING_PLAGUE"] and states["DEVOURING_PLAGUE"].isUsable) or false
    end
    simReady["DEVOURING_PLAGUE"] = simUsable["DEVOURING_PLAGUE"]
    simReady["MIND_FLAY_INSANITY"] = simProcs["MIND_FLAY_INSANITY"]
    simUsable["MIND_FLAY_INSANITY"] = simProcs["MIND_FLAY_INSANITY"]

    local pickedKey = nil

    if step == 1 and assistedKey and states[assistedKey] and states[assistedKey].isReady and states[assistedKey].isUsable then
      local isCoreRot = (
        assistedKey == "TENTACLE_SLAM"
        or (assistedKey == "VAMPIRIC_TOUCH" and not simHasDoTs and not simReady["TENTACLE_SLAM"])
        or assistedKey == "VOID_BOLT"
        or assistedKey == "VOID_TORRENT"
        or assistedKey == "DEVOURING_PLAGUE"
        or assistedKey == "MIND_FLAY_INSANITY"
        or assistedKey == "SHADOW_WORD_DEATH"
        or assistedKey == "MIND_BLAST"
      )
      if isCoreRot then
        pickedKey = assistedKey
      end
    end

    if not pickedKey then
      for _, rule in ipairs(parsed.rules) do
        local sp = rule.spell
        if simReady[sp] and simUsable[sp] then
          if EvalSingleCondition(rule.cond, simHasDoTs, simReady, simUsable, simProcs) then
            pickedKey = sp
            break
          end
        end
      end
    end

    if pickedKey and states[pickedKey] then
      local st = states[pickedKey]
      local def = SPELL_DEFS[pickedKey]
      queue[#queue + 1] = {
        key = pickedKey,
        icon = st.icon,
        keybind = st.keybind,
        isProc = (step == 1 and st.isProc) or false,
      }

      if def then
        if def.appliesDoTs then simHasDoTs = true end
        if def.insanityGain then simInsanity = math.min(100, simInsanity + def.insanityGain) end
        if def.insanityCost then simInsanity = math.max(0, simInsanity - def.insanityCost) end
        if pickedKey == "MIND_FLAY_INSANITY" then
          simProcs["MIND_FLAY_INSANITY"] = false
        elseif pickedKey == "DEVOURING_PLAGUE" then
          dpUsedInQueue = true
          simProcs["DEVOURING_PLAGUE"] = false
          simUsable["DEVOURING_PLAGUE"] = false
          simReady["DEVOURING_PLAGUE"] = false
        elseif pickedKey == "VOID_BOLT" then
          simProcs["VOID_BOLT"] = false
          simReady["VOID_BOLT"] = false
        elseif pickedKey == "SHADOW_WORD_DEATH" then
          simProcs["SHADOW_WORD_DEATH"] = false
          simReady["SHADOW_WORD_DEATH"] = false
          simUsable["SHADOW_WORD_DEATH"] = false
        elseif pickedKey == "MIND_BLAST" then
          simProcs["MIND_BLAST"] = false
          simCharges["MIND_BLAST"] = (simCharges["MIND_BLAST"] or 1) - 1
          if simCharges["MIND_BLAST"] <= 0 then
            simReady["MIND_BLAST"] = false
          end
        elseif def.baseCD and def.baseCD > 1.6 then
          simReady[pickedKey] = false
        end
      end
    else
      break
    end
  end

  -- Evaluate Channel Interrupt / Protection Policy from .md profile!
  local now = GetTime()
  local activeChannelKey = GetActiveChannelDefKey(now)
  local shouldInterruptChannel = false
  local isProtectedChannel = false

  if activeChannelKey then
    local isInterruptibleFiller = (parsed.interruptibleChannels and parsed.interruptibleChannels[activeChannelKey])
      or (SPELL_DEFS[activeChannelKey] and SPELL_DEFS[activeChannelKey].fillerInterruptible)
    local isProtected = (parsed.protectedChannels and parsed.protectedChannels[activeChannelKey])
      or (SPELL_DEFS[activeChannelKey] and SPELL_DEFS[activeChannelKey].lockChannel)

    if isProtected then
      isProtectedChannel = true
    elseif isInterruptibleFiller and queue[1] and queue[1].key ~= activeChannelKey then
      -- We are channeling Mind Flay (filler), and a higher-priority spell is ready in Slot #1!
      shouldInterruptChannel = true
    end
  end

  return queue, states, parsed, activeChannelKey, shouldInterruptChannel, isProtectedChannel
end

---------------------------------------------------------------------------------------
--                         VISUAL HUD FRAMES CREATION                                --
---------------------------------------------------------------------------------------
local rootFrame = CreateFrame("Frame", "SpArcHUDRoot", UIParent)
rootFrame:SetAllPoints(UIParent)
rootFrame:SetFrameStrata("MEDIUM")
rootFrame:SetFrameLevel(20)

local function CreateStyledIconBox(parent, size, isPrimary)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(size, size)

  local glow = f:CreateTexture(nil, "BACKGROUND", nil, -2)
  glow:SetPoint("TOPLEFT", f, "TOPLEFT", -6, 6)
  glow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 6, -6)
  glow:SetColorTexture(1, 0.82, 0.18, isPrimary and 0.55 or 0)
  f.glow = glow

  local border = f:CreateTexture(nil, "BACKGROUND", nil, -1)
  border:SetPoint("TOPLEFT", f, "TOPLEFT", -2, 2)
  border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 2, -2)
  border:SetColorTexture(0.08, 0.08, 0.11, 0.95)
  f.border = border

  local icon = f:CreateTexture(nil, "ARTWORK")
  icon:SetAllPoints(f)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  f.icon = icon

  local cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
  cd:SetAllPoints(f)
  cd:SetDrawEdge(false)
  cd:SetHideCountdownNumbers(true)
  f.cd = cd

  local kb = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(kb, isPrimary and 16 or 13)
  kb:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
  kb:SetJustifyH("RIGHT")
  kb:SetTextColor(1, 0.96, 0.80, 1)
  kb:SetShadowColor(0, 0, 0, 1)
  kb:SetShadowOffset(1, -1)
  f.keybind = kb

  local timer = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ApplyCyrFont(timer, 14)
  timer:SetPoint("CENTER", f, "CENTER", 0, 1)
  timer:SetTextColor(1, 0.88, 0.35, 1)
  timer:SetShadowColor(0, 0, 0, 1)
  timer:SetShadowOffset(1, -1)
  f.timer = timer

  if isPrimary then
    local banner = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(banner, 11)
    banner:SetPoint("BOTTOM", f, "TOP", 0, 4)
    banner:SetTextColor(1, 0.25, 0.65, 1)
    banner:SetText("")
    f.banner = banner
  end

  f:Hide()
  return f
end

-- 6 slots max (default 5 shown) along the semicircle from 150 deg (10 o'clock) to 30 deg (2 o'clock)
local MAX_ARC_SLOTS = 6
local arcAnchors = {}
local arcSlots = {}
for i = 1, MAX_ARC_SLOTS do
  local anchor = CreateFrame("Frame", nil, rootFrame)
  anchor:SetSize(1, 1)
  anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
  local box = CreateStyledIconBox(anchor, 40, i == 1)
  box:SetPoint("CENTER", anchor, "CENTER", 0, 0)
  arcAnchors[i] = anchor
  arcSlots[i] = box
end

-- Center Emergency Save + Left Saves Row + Right Offensive CDs Row
local emAnchor = CreateFrame("Frame", nil, rootFrame)
emAnchor:SetSize(1, 1)
emAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, -35)
local emergencyBox = CreateStyledIconBox(emAnchor, 62, true)
emergencyBox:SetPoint("CENTER", emAnchor, "CENTER", 0, 0)
emergencyBox.border:SetColorTexture(0.15, 1.0, 0.35, 1.0)
emergencyBox.glow:SetColorTexture(0.15, 1.0, 0.35, 0.65)
local emLabel = emergencyBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ApplyCyrFont(emLabel, 12)
emLabel:SetPoint("TOP", emergencyBox, "TOP", 0, 14)
emLabel:SetTextColor(0.25, 1.0, 0.45, 1)
emLabel:SetText("СЕЙВ!")

local savesBoxes = {}
for i = 1, 4 do
  local box = CreateStyledIconBox(rootFrame, 40, false)
  local x = -315 + (i - 1) * 46
  box:SetPoint("CENTER", UIParent, "CENTER", x, -75)
  savesBoxes[i] = box
end

local cdsBoxes = {}
for i = 1, 4 do
  local box = CreateStyledIconBox(rootFrame, 40, false)
  local x = 177 + (i - 1) * 46
  box:SetPoint("CENTER", UIParent, "CENTER", x, -75)
  cdsBoxes[i] = box
end

-- Custom Dual-Direction Castbar (Left->Right for Casts, Right->Left for Channels + Interrupt Indicator)
local castbarFrame = CreateFrame("Frame", "SpArcCastbar", rootFrame)
castbarFrame:SetSize(276, 26)
castbarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -135)

local cbBorder = castbarFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
cbBorder:SetPoint("TOPLEFT", castbarFrame, "TOPLEFT", -2, 2)
cbBorder:SetPoint("BOTTOMRIGHT", castbarFrame, "BOTTOMRIGHT", 2, -2)
cbBorder:SetColorTexture(0.06, 0.06, 0.09, 0.96)

local cbBg = castbarFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
cbBg:SetAllPoints(castbarFrame)
cbBg:SetColorTexture(0.10, 0.10, 0.15, 0.88)

local cbIcon = castbarFrame:CreateTexture(nil, "ARTWORK")
cbIcon:SetSize(26, 26)
cbIcon:SetPoint("RIGHT", castbarFrame, "LEFT", -4, 0)
cbIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local cbIconBorder = castbarFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
cbIconBorder:SetPoint("TOPLEFT", cbIcon, "TOPLEFT", -2, 2)
cbIconBorder:SetPoint("BOTTOMRIGHT", cbIcon, "BOTTOMRIGHT", 2, -2)
cbIconBorder:SetColorTexture(0.06, 0.06, 0.09, 0.96)

local cbFill = castbarFrame:CreateTexture(nil, "ARTWORK")
cbFill:SetPoint("TOPLEFT", castbarFrame, "TOPLEFT", 0, 0)
cbFill:SetPoint("BOTTOMLEFT", castbarFrame, "BOTTOMLEFT", 0, 0)
cbFill:SetWidth(1)
cbFill:SetColorTexture(0.58, 0.24, 0.94, 0.95)

local cbSpark = castbarFrame:CreateTexture(nil, "OVERLAY")
cbSpark:SetSize(14, 34)
cbSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
cbSpark:SetBlendMode("ADD")

local cbSpellText = castbarFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ApplyCyrFont(cbSpellText, 13)
cbSpellText:SetPoint("LEFT", castbarFrame, "LEFT", 8, 0)
cbSpellText:SetJustifyH("LEFT")
cbSpellText:SetTextColor(1, 0.98, 1, 1)

local cbTimeText = castbarFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ApplyCyrFont(cbTimeText, 13)
cbTimeText:SetPoint("RIGHT", castbarFrame, "RIGHT", -8, 0)
cbTimeText:SetJustifyH("RIGHT")
cbTimeText:SetTextColor(0.92, 0.92, 0.98, 1)

castbarFrame:Hide()

function SpArc:ApplyVisualLayout()
  local db = SpArc:EnsureDB()
  local v = db.visual or DEFAULT_VISUAL
  local radius = tonumber(v.arcRadius) or 135
  local offsetY = tonumber(v.arcOffsetY) or 0
  local count = math.max(3, math.min(MAX_ARC_SLOTS, tonumber(v.queueLength) or 5))
  local pScale = tonumber(v.primaryScale) or 1.50
  local qScale = tonumber(v.queueScale) or 1.00

  -- Angles from 150 deg (10 o'clock) clockwise to 30 deg (2 o'clock)
  for i = 1, MAX_ARC_SLOTS do
    local frac = (count > 1) and ((i - 1) / (count - 1)) or 0
    local angleDeg = 150 - frac * 120
    local rad = math.rad(angleDeg)
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius + offsetY
    arcAnchors[i]:ClearAllPoints()
    arcAnchors[i]:SetPoint("CENTER", UIParent, "CENTER", x, y)
    arcSlots[i]:SetScale(i == 1 and pScale or qScale)
  end

  local cbW = tonumber(v.castbarWidth) or 276
  local cbY = tonumber(v.castbarOffsetY) or -135
  castbarFrame:SetSize(cbW, 26)
  castbarFrame:ClearAllPoints()
  castbarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, cbY)
end

SpArc:RebuildParsedProfiles()
SpArc:ApplyVisualLayout()

---------------------------------------------------------------------------------------
--                              HUD UPDATE LOOP                                      --
---------------------------------------------------------------------------------------
local function UpdateCooldownRow(boxes, spellKeys, states)
  for i = 1, #boxes do
    local box = boxes[i]
    local key = spellKeys and spellKeys[i]
    local st = key and states[key]
    if st then
      box.icon:SetTexture(st.icon)
      box.keybind:SetText(st.keybind or "")
      if st.isReady then
        box.icon:SetDesaturated(false)
        box.icon:SetAlpha(1.0)
        box.border:SetColorTexture(0.18, 0.88, 0.42, 0.95)
        box.timer:SetText("")
        box.cd:Clear()
      else
        box.icon:SetDesaturated(true)
        box.icon:SetAlpha(0.55)
        box.border:SetColorTexture(0.22, 0.22, 0.26, 0.95)
        if st.remSec and st.remSec > 0 then
          if st.remSec >= 60 then
            box.timer:SetText(string.format("%dm", math.ceil(st.remSec / 60)))
          else
            box.timer:SetText(string.format("%d", math.ceil(st.remSec)))
          end
          if st.startTime and st.startTime > 0 and st.durSec and st.durSec > 0 then
            pcall(box.cd.SetCooldown, box.cd, st.startTime, st.durSec)
          end
        else
          box.timer:SetText("")
        end
      end
      box:Show()
    else
      box:Hide()
    end
  end
end

local lastShouldInterrupt = false
local lastIsProtectedChannel = false
local lastNextKeybind = ""

local function UpdateCastbar(now)
  local db = SpArc:EnsureDB()
  if db.visual and db.visual.showCastbar == false then
    castbarFrame:Hide()
    return
  end

  local isCasting, isChannel = false, false
  local name, icon, startSec, endSec

  if UnitCastingInfo then
    local ok, n, _, tex, sMS, eMS = pcall(UnitCastingInfo, "player")
    if ok and not IsSecret(n) and n then
      isCasting = true
      name = n
      icon = (not IsSecret(tex) and tex) or 136208
      if not IsSecret(sMS) and not IsSecret(eMS) and type(sMS) == "number" and type(eMS) == "number" then
        startSec = sMS / 1000
        endSec = eMS / 1000
      end
    end
  end

  if not isCasting and UnitChannelInfo then
    local ok, n, _, tex, sMS, eMS = pcall(UnitChannelInfo, "player")
    if ok and not IsSecret(n) and n then
      isChannel = true
      name = n
      icon = (not IsSecret(tex) and tex) or 136208
      if not IsSecret(sMS) and not IsSecret(eMS) and type(sMS) == "number" and type(eMS) == "number" then
        startSec = sMS / 1000
        endSec = eMS / 1000
      end
    end
  end

  if (isCasting or isChannel) and (not startSec or not endSec) then
    if castState.active and now < castState.endTime then
      startSec = castState.startTime
      endSec = castState.endTime
    end
  elseif not isCasting and not isChannel and castState.active and now < castState.endTime then
    isCasting = not castState.isChannel
    isChannel = castState.isChannel
    name = castState.name
    icon = castState.icon
    startSec = castState.startTime
    endSec = castState.endTime
  end

  if SpArc.testMode and not isCasting and not isChannel then
    local cycle = now % 6
    isChannel = (cycle >= 3)
    isCasting = not isChannel
    name = isChannel and "Пытка разума (Филлер <-)" or "Прикосновение вампира (Каст ->)"
    icon = isChannel and 136208 or 135978
    startSec = now - (cycle % 3)
    endSec = startSec + 3.0
  end

  if (isCasting or isChannel) and startSec and endSec and endSec > startSec then
    local total = endSec - startSec
    local rem = math.max(0, endSec - now)
    local elapsed = math.max(0, now - startSec)
    local cbW = (db.visual and tonumber(db.visual.castbarWidth)) or 276
    local frac
    if isChannel then
      frac = math.max(0.01, math.min(1.0, rem / total))
      if lastShouldInterrupt and (not db.visual or db.visual.showInterruptAlert ~= false) then
        -- Interruptible filler channel when a higher priority spell is ready!
        cbFill:SetColorTexture(1.0, 0.18, 0.52, 0.96)
        cbBorder:SetColorTexture(1.0, 0.25, 0.60, 1.0)
        name = "ПРЕРВИ ФИЛЛЕР -> ЖМИ [" .. (lastNextKeybind or "") .. "]!"
      elseif lastIsProtectedChannel then
        -- Protected channel (Void Torrent) - never clip!
        cbFill:SetColorTexture(0.12, 0.72, 0.98, 0.96)
        cbBorder:SetColorTexture(0.20, 0.85, 1.0, 1.0)
        name = (name or "Поток бездны") .. " [НЕ ПРЕРЫВАЙ]"
      else
        cbFill:SetColorTexture(0.20, 0.58, 0.96, 0.95)
        cbBorder:SetColorTexture(0.06, 0.06, 0.09, 0.96)
      end
    else
      frac = math.max(0.01, math.min(1.0, elapsed / total))
      cbFill:SetColorTexture(0.58, 0.24, 0.94, 0.95)
      cbBorder:SetColorTexture(0.06, 0.06, 0.09, 0.96)
    end
    cbFill:SetWidth(cbW * frac)
    cbSpark:ClearAllPoints()
    cbSpark:SetPoint("CENTER", cbFill, "RIGHT", 0, 0)
    cbIcon:SetTexture(icon or 136208)
    cbSpellText:SetText(name or "")
    cbTimeText:SetText(string.format("%.1f", rem))
    castbarFrame:Show()
  else
    castbarFrame:Hide()
  end
end

local lastLogicTick = 0
local lastChatCheck = 0
rootFrame:SetScript("OnUpdate", function()
  local now = GetTime()
  local db = SpArc:EnsureDB()
  local v = db.visual or DEFAULT_VISUAL
  local pScale = tonumber(v.primaryScale) or 1.50

  UpdateCastbar(now)
  if arcSlots[1]:IsShown() then
    local speed = lastShouldInterrupt and 12.0 or 6.0
    local amp = lastShouldInterrupt and 0.08 or 0.04
    arcSlots[1]:SetScale(pScale + amp * math.sin(now * speed))
  end
  if emergencyBox:IsShown() then
    emergencyBox:SetScale(1.10 + 0.07 * math.sin(now * 8.0))
  end

  if (now - lastLogicTick) < 0.07 then
    return
  end
  lastLogicTick = now

  if (now - lastChatCheck) > 2.0 then
    lastChatCheck = now
    if _G.LeftChatPanel and (not SafeBool(_G.LeftChatPanel.IsShown, _G.LeftChatPanel) or (_G.LeftChatPanel.GetAlpha and _G.LeftChatPanel:GetAlpha() < 0.9)) then
      ForceElvUIChatAlwaysVisible()
    end
  end

  ScanActionSlotsAndSpells(false)

  local isMounted = SafeBool(IsMounted) or SafeBool(UnitInVehicle, "player") or SafeBool(HasOverrideActionBar)
  local isDead = SafeBool(UnitIsDeadOrGhost, "player")
  if (isMounted or isDead) and not SpArc.testMode then
    for i = 1, MAX_ARC_SLOTS do arcSlots[i]:Hide() end
    for i = 1, #savesBoxes do savesBoxes[i]:Hide() end
    for i = 1, #cdsBoxes do cdsBoxes[i]:Hide() end
    emergencyBox:Hide()
    return
  end

  local hasHostileTarget = SpArc.testMode or (
    SafeBool(UnitExists, "target")
    and SafeBool(UnitCanAttack, "player", "target")
    and not SafeBool(UnitIsDead, "target")
  )
  local inCombat = SafeBool(UnitAffectingCombat, "player")
  local maxQueue = math.max(3, math.min(MAX_ARC_SLOTS, tonumber(v.queueLength) or 5))

    local queue, states, parsed, activeChannelKey, shouldInterruptChannel, isProtectedChannel = BuildRotationQueue(maxQueue)
  lastShouldInterrupt = shouldInterruptChannel and (v.showInterruptAlert ~= false)
  lastIsProtectedChannel = isProtectedChannel
  lastNextKeybind = (queue[1] and queue[1].keybind) or ""
  if SpArc.RecordTelemetryTick then
    SpArc:RecordTelemetryTick(queue, states, parsed, hasHostileTarget, inCombat, activeChannelKey, shouldInterruptChannel)
  end

  -- 1. Update Top Semicircle Rotation Arc
  if hasHostileTarget then
    for i = 1, MAX_ARC_SLOTS do
      local box = arcSlots[i]
      local item = (i <= maxQueue) and queue[i] or nil
      if item then
        box.icon:SetTexture(item.icon)
        box.keybind:SetText(item.keybind or "")
        box.timer:SetText("")
        if i == 1 then
          if lastShouldInterrupt then
            box.border:SetColorTexture(1.0, 0.18, 0.56, 1.0)
            box.glow:SetColorTexture(1.0, 0.18, 0.56, 0.78)
            if box.banner then
              box.banner:SetTextColor(1.0, 0.30, 0.68, 1)
              box.banner:SetText("ПРЕРВИ КАСТ!")
            end
          elseif isProtectedChannel then
            box.border:SetColorTexture(0.20, 0.85, 1.0, 1.0)
            box.glow:SetColorTexture(0.20, 0.85, 1.0, 0.55)
            if box.banner then
              box.banner:SetTextColor(0.35, 0.90, 1.0, 1)
              box.banner:SetText("КАНАЛ...")
            end
          elseif item.isProc then
            box.border:SetColorTexture(0.35, 0.92, 1.0, 1.0)
            box.glow:SetColorTexture(0.35, 0.92, 1.0, 0.65)
            if box.banner then box.banner:SetText("") end
          else
            box.border:SetColorTexture(1.0, 0.80, 0.15, 1.0)
            box.glow:SetColorTexture(1.0, 0.80, 0.15, 0.55)
            if box.banner then box.banner:SetText("") end
          end
        end
        box:Show()
      else
        box:Hide()
      end
    end
  else
    for i = 1, MAX_ARC_SLOTS do
      arcSlots[i]:Hide()
    end
  end

  -- 2. Update Left Saves Row & Right Offensive CDs Row
  if hasHostileTarget or inCombat or v.alwaysShowCDs then
    UpdateCooldownRow(savesBoxes, parsed and parsed.saves, states)
    UpdateCooldownRow(cdsBoxes, parsed and parsed.cds, states)
  else
    for i = 1, #savesBoxes do savesBoxes[i]:Hide() end
    for i = 1, #cdsBoxes do cdsBoxes[i]:Hide() end
  end

  -- 3. Update Center Emergency Save
  local hpPct = GetPlayerHPPercent()
  local emThreshold = tonumber(v.emergencyHP) or 25
  if hpPct <= emThreshold and (inCombat or hasHostileTarget or SpArc.testMode) then
    local pickedEm = nil
    for _, emKey in ipairs((parsed and parsed.emergency) or { "DISPERSION", "DESPERATE_PRAYER", "VAMPIRIC_EMBRACE" }) do
      local st = states[emKey]
      if st and st.isReady then
        pickedEm = st
        break
      end
    end
    if pickedEm then
      emergencyBox.icon:SetTexture(pickedEm.icon)
      emergencyBox.keybind:SetText(pickedEm.keybind or "")
      emergencyBox:Show()
    else
      emergencyBox:Hide()
    end
  else
    emergencyBox:Hide()
  end
end)

---------------------------------------------------------------------------------------
--                        EVENT HANDLER & CAST TRACKER                               --
---------------------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
eventFrame:RegisterEvent("UPDATE_MACROS")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")

local function RecordSpellCastSuccess(defKey, now)
  if not defKey then return end
  lastCastAt[defKey] = now
  local def = SPELL_DEFS[defKey]
  if not def then return end
  if def.appliesDoTs then
    targetDoTsUntil = now + 21.0
  end
  if def.insanityGain then
    trackedInsanity = math.min(100, trackedInsanity + def.insanityGain)
  end
  if def.insanityCost then
    trackedInsanity = math.max(0, trackedInsanity - def.insanityCost)
  end
  if def.grantsMFI then
    mfiProcUntil = now + 10.0
  end
  if defKey == "MIND_FLAY_INSANITY" then
    mfiProcUntil = 0
  end
  local maxCh = def.liveMaxCharges or def.maxCharges or 1
  if maxCh > 1 or defKey == "MIND_BLAST" or defKey == "TENTACLE_SLAM" then
    GetTrackedSpellCharges(defKey, now)
    local used = spellChargesUsed[defKey] or 0
    if used == 0 then
      spellChargeStart[defKey] = now
    end
    spellChargesUsed[defKey] = math.min(maxCh, used + 1)
  end
end

eventFrame:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
  if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
    SuppressLuaErrorPopups()
    SpArc:RebuildParsedProfiles()
    SpArc:ApplyVisualLayout()
    ScanActionSlotsAndSpells(true)
    return
  end

  if event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" or event == "UPDATE_MACROS" or event == "UPDATE_BINDINGS" or event == "SPELLS_CHANGED" then
    ScanActionSlotsAndSpells(true)
    return
  end

  if event == "PLAYER_TARGET_CHANGED" then
    local okG, guid = pcall(UnitGUID, "target")
    local newGUID = (okG and not IsSecret(guid) and guid) or nil
    if not newGUID or newGUID ~= lastTargetGUID then
      targetDoTsUntil = 0
      lastTargetGUID = newGUID
    end
    return
  end

  local now = GetTime()
  local sName, sIcon, sCastMS
  if spellID and not IsSecret(spellID) and C_Spell and C_Spell.GetSpellInfo then
    local okI, info = pcall(C_Spell.GetSpellInfo, spellID)
    if okI and type(info) == "table" then
      sName = not IsSecret(info.name) and info.name or nil
      sIcon = not IsSecret(info.iconID) and info.iconID or nil
      sCastMS = not IsSecret(info.castTime) and info.castTime or nil
    end
  end

  if event == "UNIT_SPELLCAST_START" then
    local defKey = MatchSpellToDefKey(spellID, sName)
    local dur = (sCastMS and sCastMS > 0 and (sCastMS / 1000)) or 1.4
    castState.active = true
    castState.isChannel = false
    castState.defKey = defKey
    castState.name = sName or "Заклинание"
    castState.icon = sIcon or 136208
    castState.startTime = now
    castState.endTime = now + dur
  elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
    local defKey = MatchSpellToDefKey(spellID, sName)
    local dur = (defKey == "VOID_TORRENT") and 3.0 or 2.8
    castState.active = true
    castState.isChannel = true
    castState.defKey = defKey
    castState.name = sName or "Поток"
    castState.icon = sIcon or 136208
    castState.startTime = now
    castState.endTime = now + dur
    if defKey then
      RecordSpellCastSuccess(defKey, now)
    end
  elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
    castState.active = false
    castState.defKey = nil
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    local defKey = MatchSpellToDefKey(spellID, sName)
    if defKey and defKey ~= "VOID_TORRENT" and defKey ~= "MIND_FLAY" and defKey ~= "MIND_FLAY_INSANITY" then
      RecordSpellCastSuccess(defKey, now)
    end
  end
end)

---------------------------------------------------------------------------------------
--            TELEMETRY & SPELLBOOK AUDITOR (SAVEDVARIABLES + LIVE UI)               --
---------------------------------------------------------------------------------------
local lastLoggedTopKey = nil
local lastTelemetrySampleAt = 0

local CORE_AUDIT_ORDER = {
  "TENTACLE_SLAM",
  "VAMPIRIC_TOUCH",
  "DEVOURING_PLAGUE",
  "VOID_TORRENT",
  "MIND_BLAST",
  "VOID_BOLT",
  "SHADOW_WORD_DEATH",
  "MIND_FLAY_INSANITY",
  "MIND_FLAY",
  "HALO",
  "POWER_INFUSION",
  "VOID_ERUPTION",
  "DISPERSION",
}

local function GetTimestampStr()
  if _G.date then
    local ok, s = pcall(_G.date, "%H:%M:%S")
    if ok and type(s) == "string" then return s end
  end
  return string.format("%.1fs", GetTime())
end

function SpArc:CaptureTelemetrySnapshot(reasonTag, queue, states, parsed)
  local db = SpArc:EnsureDB()
  if not (db.visual and db.visual.enableTelemetry) and reasonTag ~= "MANUAL_SNAPSHOT" then
    return
  end

  if not queue or not states then
    queue, states, parsed = BuildRotationQueue((db.visual and db.visual.queueLength) or 5)
  end

  db.lastSpellAudit = {}
  for k, v in pairs(lastSpellAudit) do
    db.lastSpellAudit[k] = v
  end

  local qParts = {}
  for i = 1, #(queue or {}) do
    local it = queue[i]
    if it then
      qParts[#qParts + 1] = string.format("#%d:%s[%s]%s", i, it.key, it.keybind or "-", it.isProc and "(PROC)" or "")
    end
  end
  local qStr = (#qParts > 0) and table.concat(qParts, " -> ") or "EMPTY"

  local rawInsStr = "n/a"
  if UnitPower then
    local okP, p = pcall(UnitPower, "player", 13)
    if okP then
      rawInsStr = IsSecret(p) and "SECRET" or tostring(p)
    end
  end

  local assistedKey, assistedID = GetAssistedSuggestedDefKey()
  local hasDoTs = CheckTargetHasDoTs(assistedKey)

  local bookDiffs = {}
  for _, sKey in ipairs(CORE_AUDIT_ORDER) do
    local a = lastSpellAudit[sKey]
    if a then
      bookDiffs[#bookDiffs + 1] = string.format(
        "%s(id=%s,slot=%s,bind=%s): SpArc[R=%s,U=%s,P=%s,src=%s] | Книга[U=%s,CD=%s,Ch=%s,Ov=%s] | Бар[U=%s,RGB=%s]",
        sKey,
        tostring(a.spellID or "?"),
        tostring(a.slot or "-"),
        tostring(a.keybind or "-"),
        tostring(a.isReady),
        tostring(a.isUsable),
        tostring(a.isProc),
        tostring(a.usableSource or "-"),
        tostring(a.bookUsableRaw or "-"),
        tostring(a.cdRaw or "-"),
        tostring(a.chargesRaw or "-"),
        tostring(a.overlayRaw or "-"),
        tostring(a.actUsableRaw or "-"),
        tostring(a.btColorRaw or "-")
      )
    end
  end

  local entry = string.format(
    "[%s | %s] Загорелось: %s | Безумие(книга=%s, трек=%d) | Доты=%s | БлиззАссист=%s(%s)\n  " .. table.concat(bookDiffs, "\n  "),
    GetTimestampStr(),
    reasonTag or "TICK",
    qStr,
    rawInsStr,
    trackedInsanity or 0,
    tostring(hasDoTs),
    tostring(assistedKey or "nil"),
    tostring(assistedID or "nil")
  )

  db.telemetryLog = db.telemetryLog or {}
  db.telemetryLog[#db.telemetryLog + 1] = entry
  while #db.telemetryLog > 60 do
    table.remove(db.telemetryLog, 1)
  end
end

function SpArc:RecordTelemetryTick(queue, states, parsed, hasHostileTarget, inCombat, activeChannelKey, shouldInterruptChannel)
  local db = SpArc:EnsureDB()
  if not (db.visual and db.visual.enableTelemetry) then return end
  if not hasHostileTarget and not inCombat then return end

  local now = GetTime()
  local topKey = queue and queue[1] and queue[1].key or "NONE"
  if topKey ~= lastLoggedTopKey then
    lastLoggedTopKey = topKey
    lastTelemetrySampleAt = now
    SpArc:CaptureTelemetrySnapshot(shouldInterruptChannel and "INTERRUPT_ALERT" or "QUEUE_TOP_CHANGED", queue, states, parsed)
  elseif (now - lastTelemetrySampleAt) >= 2.5 then
    lastTelemetrySampleAt = now
    SpArc:CaptureTelemetrySnapshot("PERIODIC_2.5S", queue, states, parsed)
  end
end

function SpArc:BuildTelemetryReportText()
  local db = SpArc:EnsureDB()
  local lines = {}
  lines[#lines + 1] = "=== SPARC v" .. SpArc.VERSION .. " — ТЕЛЕМЕТРИЯ И СВЕРКА С КНИГОЙ ЗАКЛИНАНИЙ ==="
  lines[#lines + 1] = "Сбор телеметрии: " .. ((db.visual and db.visual.enableTelemetry) and "ВКЛЮЧЕН (пишется в WTF/.../SavedVariables/SpArc.lua)" or "ВЫКЛЮЧЕН")
  lines[#lines + 1] = ""
  lines[#lines + 1] = "--- 1. ТЕКУЩЕЕ СОСТОЯНИЕ ПО КНИГЕ ЗАКЛИНАНИЙ И ПАНЕЛЯМ BARTENDER4 ---"
  for _, sKey in ipairs(CORE_AUDIT_ORDER) do
    local a = lastSpellAudit[sKey]
    if a then
      lines[#lines + 1] = string.format(
        "• %-20s [ID:%-7s Слот:%-3s Бинд:%-4s] -> SpArc: Ready=%-5s Usable=%-5s Proc=%-5s (%s)",
        sKey,
        tostring(a.spellID or "?"),
        tostring(a.slot or "-"),
        tostring(a.keybind or "-"),
        tostring(a.isReady),
        tostring(a.isUsable),
        tostring(a.isProc),
        tostring(a.usableSource or "-")
      )
      lines[#lines + 1] = string.format(
        "    Книга: IsSpellUsable=%s | CD=%s | Charges=%s | Overlay=%s || Бар: IsUsableAction=%s | BT4Color=%s",
        tostring(a.bookUsableRaw),
        tostring(a.cdRaw),
        tostring(a.chargesRaw),
        tostring(a.overlayRaw),
        tostring(a.actUsableRaw),
        tostring(a.btColorRaw)
      )
    end
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "--- 2. ИСТОРИЯ СРАБАТЫВАНИЙ (ЧТО ЗАГОРАЛОСЬ vs ЧТО БЫЛО ДОСТУПНО В КНИГЕ) ---"
  local log = db.telemetryLog or {}
  if #log == 0 then
    lines[#lines + 1] = "(Лог пока пуст — возьмите врага в таргет или нажмите кнопку 'Снять слепок сейчас')"
  else
    for i = #log, math.max(1, #log - 25), -1 do
      lines[#lines + 1] = log[i]
      lines[#lines + 1] = "-------------------------------------------------------------------------"
    end
  end
  return table.concat(lines, "\n")
end

---------------------------------------------------------------------------------------
--      SPARC CONTROL CENTER UI (4 TABS: PRESETS / .MD & AI / VISUALS / TELEMETRY)   --
---------------------------------------------------------------------------------------
local controlFrame
local selectedPresetForEdit = "PRIEST_01_SHADOW_PVE"
local filterClassOnly = true
local showingAIPrompt = false

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
    title:SetText("|cffa335eeSpArc v2.1|r — Визуализатор FSM-ротаций (.MD Псевдокод, ИИ & Телеметрия)")

    local subTitle = controlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(subTitle, 11)
    subTitle:SetPoint("TOPLEFT", 50, -32)
    subTitle:SetTextColor(0.72, 0.72, 0.82, 1)
    subTitle:SetText("Авторы: |cffffd100Gemini (Tiger) & Anya (5cr3am1ng5oul)|r  •  SpellID + Bartender4 Keybind Resolver")

    local closeBtn = CreateFrame("Button", nil, controlFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)

    local tabNames = {
      "1. Пресеты (55)",
      "2. Импорт .MD и ИИ",
      "3. Визуал и HUD",
      "4. Телеметрия / Дебаг",
    }
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

    for i, tName in ipairs(tabNames) do
      local btn = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")
      btn:SetSize(182, 26)
      btn:SetPoint("TOPLEFT", 16 + (i - 1) * 188, -54)
      btn:SetText(tName)
      btn:SetScript("OnClick", function() SelectTab(i) end)
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
    newPresetBtn:SetText("+ Новый пресет")
    newPresetBtn:SetScript("OnClick", function()
      local newIdx = #db.presetOrder + 1
      local cls = GetPlayerClassTag()
      local newID = string.format("%s_CUSTOM_%d", cls, newIdx)
      local newTitle = string.format("%d. Кастомный %s #%d", newIdx, cls, newIdx)
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
    activateBtn:SetText("Сделать активным пресетом")
    activateBtn:SetScript("OnClick", function()
      db.activePresetID = selectedPresetForEdit
      db.mode = "MANUAL"
      controlFrame:RefreshUI()
      print("|cffa335eeSpArc:|r Активирован пресет: |cffffd100" .. ((db.presets[selectedPresetForEdit] and db.presets[selectedPresetForEdit].title) or selectedPresetForEdit) .. "|r")
    end)

    local openMdBtn = CreateFrame("Button", nil, detailsBox, "UIPanelButtonTemplate")
    openMdBtn:SetSize(280, 28)
    openMdBtn:SetPoint("BOTTOM", 0, 48)
    openMdBtn:SetText("Открыть псевдокод .MD / ИИ ->")
    openMdBtn:SetScript("OnClick", function()
      showingAIPrompt = false
      SelectTab(2)
    end)

    local testModeBtn1 = CreateFrame("Button", nil, detailsBox, "UIPanelButtonTemplate")
    testModeBtn1:SetSize(280, 26)
    testModeBtn1:SetPoint("BOTTOM", 0, 14)
    testModeBtn1:SetText("Тест HUD на экране (ВКЛ/ВЫКЛ)")
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
    aiText:SetText("ИИ-Подсказка: " .. SpArc.AIPromptHeaderText)

    local aiPromptBtn = CreateFrame("Button", nil, aiBanner, "UIPanelButtonTemplate")
    aiPromptBtn:SetSize(210, 36)
    aiPromptBtn:SetPoint("RIGHT", -12, 0)
    aiPromptBtn:SetText("Промпт для ИИ (Ctrl+C)")

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
    saveMdBtn:SetText("Сохранить .MD в пресет")
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
        print("|cffa335eeSpArc:|r Псевдокод .MD сохранён и скомпилирован для |cffffd100" .. pr.title .. "|r!")
      end
    end)

    local resetMdBtn = CreateFrame("Button", nil, p2, "UIPanelButtonTemplate")
    resetMdBtn:SetSize(180, 28)
    resetMdBtn:SetPoint("BOTTOMLEFT", 0, 4)
    resetMdBtn:SetText("Сброс пресета по умолч.")
    resetMdBtn:SetScript("OnClick", function()
      showingAIPrompt = false
      local bp = SpArc.BuiltInPresets[selectedPresetForEdit]
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
    vHeader:SetText("Настройки полукруга ротации, кастбара, кнопки у миникарты и телеметрии:")

    local function CreateVisualSlider(label, key, minV, maxV, stepV, x, y)
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
        txt:SetText(string.format("%s: |cffffd100%.2f|r", label, rounded))
        SpArc:ApplyVisualLayout()
      end)
      sFrame.slider = slider
      sFrame.txt = txt
      sFrame.label = label
      sFrame.key = key
      return sFrame
    end

    local sliders = {
      CreateVisualSlider("Радиус полукруга ротации (px)", "arcRadius", 80, 220, 5, 0, -30),
      CreateVisualSlider("Масштаб главной иконки #1", "primaryScale", 1.0, 2.0, 0.05, 0, -86),
      CreateVisualSlider("Масштаб очереди (#2..#6)", "queueScale", 0.6, 1.4, 0.05, 0, -142),
      CreateVisualSlider("Кол-во иконок в дуге (3..6)", "queueLength", 3, 6, 1, 0, -198),
      CreateVisualSlider("Смещение дуги по Y (px)", "arcOffsetY", -80, 140, 5, 360, -30),
      CreateVisualSlider("Ширина кастбара (px)", "castbarWidth", 180, 420, 4, 360, -86),
      CreateVisualSlider("Смещение кастбара по Y (px)", "castbarOffsetY", -240, -40, 5, 360, -142),
      CreateVisualSlider("Порог ХП для экстренного сейва (%)", "emergencyHP", 15, 50, 5, 360, -198),
    }

    local function CreateVisualCheck(label, key, y, isTestToggle, onAfterClick)
      local cb = CreateFrame("CheckButton", nil, p3, "UICheckButtonTemplate")
      cb:SetPoint("TOPLEFT", 0, y)
      local txt = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      ApplyCyrFont(txt, 13)
      txt:SetPoint("LEFT", cb, "RIGHT", 6, 0)
      txt:SetText(label)
      cb:SetScript("OnClick", function()
        if isTestToggle then
          SpArc.testMode = cb:GetChecked() and true or false
        else
          db.visual[key] = cb:GetChecked() and true or false
        end
        if onAfterClick then onAfterClick() end
      end)
      cb.key = key
      cb.isTestToggle = isTestToggle
      return cb
    end

    local checks = {
      CreateVisualCheck("Подсвечивать 'ПРЕРВИ КАСТ!', когда во время филлера (Пытка разума) откатился спелл", "showInterruptAlert", -262, false),
      CreateVisualCheck("Показывать двойной кастбар SpArc (слева->направо каст / справа->налево потоковый)", "showCastbar", -292, false),
      CreateVisualCheck("Всегда показывать крылья сейвов и боевых КД (даже вне боя и без цели)", "alwaysShowCDs", -322, false),
      CreateVisualCheck("Включить сбор телеметрии / дебаг (что загоралось vs что доступно по книге заклинаний)", "enableTelemetry", -352, false),
      CreateVisualCheck("Показывать иконку-кнопку SpArc у миникарты (ЛКМ — настройки, ПКМ — телеметрия)", "showMinimapButton", -382, false, function()
        if SpArc.UpdateMinimapButtonVisibility then SpArc:UpdateMinimapButtonVisibility() end
      end),
      CreateVisualCheck("Тестовый режим (показать превью всей дуги, кастбара и сейвов прямо сейчас)", "testMode", -412, true),
    }

    -----------------------------------------------------------------------------------
    -- TAB 4: TELEMETRY & SPELLBOOK DEBUGGER
    -----------------------------------------------------------------------------------
    local p4 = pages[4]
    local tHeader = p4:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(tHeader, 13)
    tHeader:SetPoint("TOPLEFT", 0, 0)
    tHeader:SetText("|cffffd100Телеметрия и Дебаг:|r сравнивает выбор SpArc с реальным ответом книги заклинаний и панелей Bartender4")

    local snapBtn = CreateFrame("Button", nil, p4, "UIPanelButtonTemplate")
    snapBtn:SetSize(200, 26)
    snapBtn:SetPoint("TOPLEFT", 0, -26)
    snapBtn:SetText("Снять слепок сейчас")

    local copyTelBtn = CreateFrame("Button", nil, p4, "UIPanelButtonTemplate")
    copyTelBtn:SetSize(180, 26)
    copyTelBtn:SetPoint("LEFT", snapBtn, "RIGHT", 8, 0)
    copyTelBtn:SetText("Выделить всё (Ctrl+C)")

    local clearTelBtn = CreateFrame("Button", nil, p4, "UIPanelButtonTemplate")
    clearTelBtn:SetSize(160, 26)
    clearTelBtn:SetPoint("LEFT", copyTelBtn, "RIGHT", 8, 0)
    clearTelBtn:SetText("Очистить лог")

    local telToggleCheck = CreateFrame("CheckButton", nil, p4, "UICheckButtonTemplate")
    telToggleCheck:SetPoint("LEFT", clearTelBtn, "RIGHT", 12, 0)
    local telToggleTxt = telToggleCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyCyrFont(telToggleTxt, 12)
    telToggleTxt:SetPoint("LEFT", telToggleCheck, "RIGHT", 4, 0)
    telToggleTxt:SetText("Сбор ВКЛ")
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
      SpArc:CaptureTelemetrySnapshot("MANUAL_SNAPSHOT")
      controlFrame:RefreshUI()
    end)
    copyTelBtn:SetScript("OnClick", function()
      telEditBox:SetFocus()
      telEditBox:HighlightText()
    end)
    clearTelBtn:SetScript("OnClick", function()
      db.telemetryLog = {}
      controlFrame:RefreshUI()
    end)

    function controlFrame:RefreshUI()
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

      local activeTitle = (db.presets[db.activePresetID] and db.presets[db.activePresetID].title) or db.activePresetID
      p1Summary:SetText(string.format(
        "Всего пресетов в базе: |cffffd100%d|r  |  Для вашего класса (%s): |cff00ff00%d|r  |  Активный: |cffa335ee%s|r (%s)",
        totalCount, pClass, classCount, activeTitle, db.mode
      ))
      filterBtn:SetText(filterClassOnly and ("Фильтр: Только " .. pClass .. " (" .. classCount .. ")") or ("Фильтр: Все классы (" .. totalCount .. ")"))
      autoModeBtn:SetText(db.mode == "AUTO" and "Режим: AUTO (ПвЕ/Босс/ПвП)" or "Режим: Ручной пресет")

      for idx = 1, #rowButtons do
        local rBtn = rowButtons[idx]
        local id = filteredIDs[idx]
        if id and db.presets[id] then
          local pr = db.presets[id]
          local prefix = (id == db.activePresetID and "|cff00ff00[АКТИВЕН]|r ") or (id == selectedPresetForEdit and "|cffffd100[>]|r ") or ""
          rBtn:SetText(prefix .. pr.title)
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
        detailsText:SetText(string.format(
          "|cffffd100%s|r\n\n"
          .. "• Класс / Режим: |cff00ccff%s (%s)|r\n"
          .. "• Правил ротации в автомате: |cff00ff00%d|r\n"
          .. "• Трекинг сейвов слева: |cff00ff00%s|r\n"
          .. "• Трекинг бурстов справа: |cff00ff00%s|r\n"
          .. "• Прерываемый филлер: |cffff40a0%s|r\n"
          .. "• Защищённый канал: |cff40d0ff%s|r\n\n"
          .. "|cffaaaaaaВся логика этого пресета читается напрямую из текстового .MD псевдокода без единой захардкоженной ветки!|r",
          selPr.title,
          selPr.class or "ANY", selPr.mode or "PVE",
          #(selParsed.rules or {}),
          table.concat(selParsed.saves or {}, ", "),
          table.concat(selParsed.cds or {}, ", "),
          (#intList > 0 and table.concat(intList, ", ") or "нет"),
          (#protList > 0 and table.concat(protList, ", ") or "нет")
        ))
      end

      -- Tab 2 refresh
      if showingAIPrompt then
        aiPromptBtn:SetText("<- Вернуться к .MD коду")
        editorStatus:SetText("|cff00ff00Скопируйте этот промпт (Ctrl+C) и отправьте своему Gemini или ChatGPT:|r")
        editBox:SetText(SpArc.AIPromptTemplate)
      else
        aiPromptBtn:SetText("Промпт для ИИ (Ctrl+C)")
        local pr = db.presets[selectedPresetForEdit]
        local cp = SpArc.ParsedPresets and SpArc.ParsedPresets[selectedPresetForEdit]
        editorStatus:SetText(string.format(
          "Пресет: |cffffd100%s|r  |  Правил FSM: |cff00ff00%d|r  |  Сейвов: |cff00ff00%d|r  |  КД: |cff00ff00%d|r",
          (pr and pr.title) or selectedPresetForEdit,
          (cp and cp.rules and #cp.rules) or 0,
          (cp and cp.saves and #cp.saves) or 0,
          (cp and cp.cds and #cp.cds) or 0
        ))
        editBox:SetText((pr and pr.md) or "")
      end

      -- Tab 3 refresh
      for _, s in ipairs(sliders) do
        local val = tonumber(db.visual[s.key]) or DEFAULT_VISUAL[s.key]
        s.slider:SetValue(val)
        s.txt:SetText(string.format("%s: |cffffd100%.2f|r", s.label, val))
      end
      for _, c in ipairs(checks) do
        if c.isTestToggle then
          c:SetChecked(SpArc.testMode and true or false)
        else
          c:SetChecked(db.visual[c.key] ~= false)
        end
      end

      -- Tab 4 refresh
      telToggleCheck:SetChecked(db.visual.enableTelemetry ~= false)
      if pages[4]:IsShown() then
        telEditBox:SetText(SpArc:BuildTelemetryReportText())
      end
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
  local radius = (_G.Minimap:GetWidth() / 2) + 8
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
      _G.GameTooltip:AddLine("|cffa335eeSpArc v" .. SpArc.VERSION .. "|r — Rotation & Cooldown HUD")
      _G.GameTooltip:AddLine("|cffffd100ЛКМ:|r Открыть окно настроек и пресетов", 0.9, 0.9, 0.9)
      _G.GameTooltip:AddLine("|cffffd100ПКМ:|r Открыть Телеметрию / Дебаг книги заклинаний", 0.9, 0.9, 0.9)
      _G.GameTooltip:AddLine("|cffffd100Shift + ЛКМ:|r Тестовый режим HUD (ВКЛ/ВЫКЛ)", 0.9, 0.9, 0.9)
      _G.GameTooltip:AddLine("|cffaaaaaaЗажать ЛКМ: Перетащить кнопку вокруг миникарты|r", 0.7, 0.7, 0.7)
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
      local mx, my = _G.Minimap:GetCenter()
      local cx, cy = _G.GetCursorPosition()
      local scale = _G.Minimap:GetEffectiveScale()
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
      print("|cffa335eeSpArc:|r Тестовый режим: " .. (SpArc.testMode and "|cff00ff00ВКЛ|r" or "|cffff4040ВЫКЛ|r"))
      return
    end
    if mouseBtn == "RightButton" then
      SpArc:CaptureTelemetrySnapshot("MANUAL_SNAPSHOT")
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
if _G.C_Timer and _G.C_Timer.After then
  _G.C_Timer.After(1.0, function()
    CreateSpArcMinimapButton()
    UpdateMinimapButtonPosition()
    SpArc:UpdateMinimapButtonVisibility()
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
    print("|cffa335eeSpArc:|r Тестовый режим (показ всех элементов): " .. (SpArc.testMode and "|cff00ff00ВКЛ|r" or "|cffff4040ВЫКЛ|r"))
  elseif cmd == "debug" or cmd == "tel" or cmd == "telemetry" then
    SpArc:CaptureTelemetrySnapshot("MANUAL_SNAPSHOT")
    OpenControlCenter(4)
  elseif cmd == "pve" or cmd == "boss" or cmd == "pvp" or cmd == "auto" then
    db.mode = cmd:upper()
    print("|cffa335eeSpArc:|r Активный режим ротации: |cffffd100" .. db.mode .. "|r")
  elseif cmd == "import" or cmd == "edit" or cmd == "md" or cmd == "ai" then
    showingAIPrompt = (cmd == "ai")
    OpenControlCenter(2)
  elseif cmd == "visual" or cmd == "hud" then
    OpenControlCenter(3)
  elseif cmd == "always" then
    db.visual.alwaysShowCDs = not db.visual.alwaysShowCDs
    print("|cffa335eeSpArc:|r Постоянный показ сейвов и КД вне боя: " .. (db.visual.alwaysShowCDs and "|cff00ff00ВКЛ|r" or "|cffff4040ВЫКЛ|r"))
  else
    OpenControlCenter(1)
  end
end
