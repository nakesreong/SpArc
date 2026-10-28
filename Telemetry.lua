---------------------------------------------------------------------------------------
--  SpArc/Telemetry.lua — SpellBook vs Bartender4 vs SpArc Telemetry Auditor
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc

local GetTime = _G.GetTime
local UnitPower = _G.UnitPower
local UnitPowerType = _G.UnitPowerType
local pcall = _G.pcall
local ipairs = _G.ipairs
local pairs = _G.pairs
local tostring = _G.tostring
local tonumber = _G.tonumber
local type = _G.type
local math = _G.math
local table = _G.table
local string = _G.string

local IsSecret = SpArc.IsSecret
local SPELL_DEFS = SpArc.SPELL_DEFS
local st = SpArc.state

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

local POWER_LABELS_RU = {
  [0]  = "Мана",
  [1]  = "Ярость",
  [2]  = "Фокус",
  [3]  = "Энергия",
  [6]  = "СилаРун",
  [8]  = "АстрМощь",
  [11] = "Водоворот",
  [13] = "Безумие",
  [17] = "Гнев",
  [18] = "Боль",
}

local POWER_LABELS_EN = {
  [0]  = "Mana",
  [1]  = "Rage",
  [2]  = "Focus",
  [3]  = "Energy",
  [6]  = "RunicPower",
  [8]  = "AstralPower",
  [11] = "Maelstrom",
  [13] = "Insanity",
  [17] = "Fury",
  [18] = "Pain",
}

local function GetActiveAuditOrder(parsed)
  local order = {}
  local seen = {}
  local function addKey(k)
    if k and not seen[k] and (st.lastSpellAudit[k] or SPELL_DEFS[k]) then
      seen[k] = true
      order[#order + 1] = k
    end
  end

  if not parsed and SpArc.SelectActiveParsedProfile then
    parsed = SpArc:SelectActiveParsedProfile()
  end

  if parsed then
    for _, r in ipairs(parsed.rules or {}) do
      addKey(r.spell)
    end
    for _, k in ipairs(parsed.cds or parsed.trackCDs or {}) do
      addKey(k)
    end
    for _, k in ipairs(parsed.saves or parsed.trackSaves or {}) do
      addKey(k)
    end
    for _, r in ipairs(parsed.emergency or {}) do
      addKey(type(r) == "table" and r.spell or r)
    end
  end

  local extra = {}
  for k in pairs(st.lastSpellAudit) do
    if not seen[k] and SPELL_DEFS[k] then
      extra[#extra + 1] = k
    end
  end
  table.sort(extra)
  for _, k in ipairs(extra) do
    addKey(k)
  end

  if #order == 0 then
    for _, k in ipairs(CORE_AUDIT_ORDER) do
      if st.lastSpellAudit[k] then
        order[#order + 1] = k
      end
    end
  end
  return order
end

local function GetPrimaryResourceString(isRU)
  local pType = 13
  if UnitPowerType then
    local okT, pt = pcall(UnitPowerType, "player")
    if okT and not IsSecret(pt) and type(pt) == "number" then
      pType = pt
    end
  end
  if SPELL_DEFS["DEVOURING_PLAGUE"] and SPELL_DEFS["MIND_FLAY"] then
    pType = 13
  end
  local label = (isRU and POWER_LABELS_RU[pType] or POWER_LABELS_EN[pType]) or (isRU and "Ресурс" or "Power")
  local rawStr = "n/a"
  if UnitPower then
    local okP, p = pcall(UnitPower, "player", pType)
    if okP then
      rawStr = IsSecret(p) and "SECRET" or tostring(p)
    end
  end
  if pType == 13 then
    return string.format("%s(книга=%s, трек=%d)", label, rawStr, st.trackedInsanity or 0)
  end
  return string.format("%s(%s)", label, rawStr)
end

local function GetTimestampStr()
  if _G.date then
    local ok, s = pcall(_G.date, "%H:%M:%S")
    if ok and type(s) == "string" then return s end
  end
  return string.format("%.1fs", GetTime())
end

local function CaptureBugGrabberErrors(db)
  local errs = {}
  local bg = _G.BugGrabber
  local list = nil
  if bg and type(bg.GetDB) == "function" then
    local ok, res = pcall(bg.GetDB, bg)
    if ok and type(res) == "table" then list = res end
  end
  if not list and _G.BugGrabberDB and type(_G.BugGrabberDB.errors) == "table" then
    list = _G.BugGrabberDB.errors
  end
  if type(list) == "table" then
    local startIdx = math.max(1, #list - 14)
    for i = #list, startIdx, -1 do
      local e = list[i]
      if type(e) == "table" and e.message then
        errs[#errs + 1] = string.format("[%dx | %s] %s", tonumber(e.counter) or 1, tostring(e.time or "-"), tostring(e.message))
      end
    end
  end
  db.capturedLuaErrors = errs
  return errs
end

function SpArc:CaptureTelemetrySnapshot(reasonTag, queue, states, parsed)
  local db = SpArc:EnsureDB()
  CaptureBugGrabberErrors(db)
  if not (db.visual and db.visual.enableTelemetry) and reasonTag ~= "MANUAL_SNAPSHOT" then
    return
  end

  if not queue or not states then
    queue, states, parsed = SpArc:BuildRotationQueue((db.visual and db.visual.queueLength) or 5)
  end

  db.lastSpellAudit = {}
  for k, v in pairs(st.lastSpellAudit) do
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

  local isRU = SpArc:IsRU()
  local resStr = GetPrimaryResourceString(isRU)
  local assistedKey, assistedID = SpArc:GetAssistedSuggestedDefKey()
  local now = GetTime()
  local auraParts = {}
  local auraMap = (parsed and parsed.auras) or SPELL_DEFS
  for aKey, aDef in pairs(auraMap) do
    if (aDef.auraDuration and aDef.auraDuration > 0) or aDef.isAuraOnly then
      local u = aDef.auraUnit or "target"
      local isAct, remSec, stacks = SpArc:GetUnitAuraState(u, aKey, parsed, assistedKey, now)
      if isAct and remSec and remSec > 0 then
        auraParts[#auraParts + 1] = string.format("%s:%s(%.1fs,x%d)", u == "player" and "P" or "T", aKey, remSec, stacks or 1)
      end
    end
  end
  table.sort(auraParts)
  local aurasStr = (#auraParts > 0) and table.concat(auraParts, ",") or "none"
  local auditOrder = GetActiveAuditOrder(parsed)

  local bookDiffs = {}
  for _, sKey in ipairs(auditOrder) do
    local a = st.lastSpellAudit[sKey]
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

  local headerLine = string.format(
    isRU
      and "[%s | %s] Загорелось: %s | %s | Ауры=[%s] | БлиззАссист=%s(%s)"
      or "[%s | %s] Queue: %s | %s | Auras=[%s] | BlizzAssist=%s(%s)",
    GetTimestampStr(),
    reasonTag or "TICK",
    qStr,
    resStr,
    aurasStr,
    tostring(assistedKey or "nil"),
    tostring(assistedID or "nil")
  )
  local entry = headerLine .. "\n  " .. table.concat(bookDiffs, "\n  ")

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
  local isRU = SpArc:IsRU()
  local errs = CaptureBugGrabberErrors(db)
  local parsed = SpArc.SelectActiveParsedProfile and SpArc:SelectActiveParsedProfile() or nil
  local auditOrder = GetActiveAuditOrder(parsed)
  local lines = {}
  if isRU then
    lines[#lines + 1] = "=== SPARC v" .. SpArc.VERSION .. " — ТЕЛЕМЕТРИЯ И СВЕРКА С КНИГОЙ ЗАКЛИНАНИЙ ==="
    lines[#lines + 1] = "Сбор телеметрии: " .. ((db.visual and db.visual.enableTelemetry) and "ВКЛЮЧЕН (пишется в WTF/.../SavedVariables/SpArc.lua)" or "ВЫКЛЮЧЕН")
    lines[#lines + 1] = ""
    lines[#lines + 1] = "--- 0. ПЕРЕХВАЧЕННЫЕ ОШИБКИ LUA (!BugGrabber / BugSack) ---"
    if #errs == 0 then
      lines[#lines + 1] = "(Ошибок Lua не зафиксировано)"
    else
      for _, msg in ipairs(errs) do
        lines[#lines + 1] = "• " .. msg
      end
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "--- 1. ТЕКУЩЕЕ СОСТОЯНИЕ ПО КНИГЕ ЗАКЛИНАНИЙ И ПАНЕЛЯМ BARTENDER4 ---"
  else
    lines[#lines + 1] = "=== SPARC v" .. SpArc.VERSION .. " — TELEMETRY & SPELLBOOK AUDITOR ==="
    lines[#lines + 1] = "Telemetry Logging: " .. ((db.visual and db.visual.enableTelemetry) and "ENABLED (saved to WTF/.../SavedVariables/SpArc.lua)" or "DISABLED")
    lines[#lines + 1] = ""
    lines[#lines + 1] = "--- 0. CAPTURED LUA ERRORS (!BugGrabber / BugSack) ---"
    if #errs == 0 then
      lines[#lines + 1] = "(No Lua errors recorded)"
    else
      for _, msg in ipairs(errs) do
        lines[#lines + 1] = "• " .. msg
      end
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "--- 1. CURRENT SPELLBOOK & BARTENDER4 STATE ---"
  end

  for _, sKey in ipairs(auditOrder) do
    local a = st.lastSpellAudit[sKey]
    if a then
      lines[#lines + 1] = string.format(
        "• %-20s [ID:%-7s Slot:%-3s Bind:%-4s] -> SpArc: Ready=%-5s Usable=%-5s Proc=%-5s (%s)",
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
        "    Book: IsSpellUsable=%s | CD=%s | Charges=%s | Overlay=%s || Bar: IsUsableAction=%s | BT4Color=%s",
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
  if isRU then
    lines[#lines + 1] = "--- 2. ИСТОРИЯ СРАБАТЫВАНИЙ (ЧТО ЗАГОРАЛОСЬ vs ЧТО БЫЛО ДОСТУПНО В КНИГЕ) ---"
  else
    lines[#lines + 1] = "--- 2. TRIGGER HISTORY (SPARC QUEUE vs SPELLBOOK AVAILABILITY) ---"
  end
  local log = db.telemetryLog or {}
  if #log == 0 then
    lines[#lines + 1] = isRU
      and "(Лог пока пуст — возьмите врага в таргет или нажмите кнопку 'Снять слепок сейчас')"
      or "(Log is empty — target an enemy or click 'Capture Snapshot Now')"
  else
    for i = #log, math.max(1, #log - 25), -1 do
      lines[#lines + 1] = log[i]
      lines[#lines + 1] = "-------------------------------------------------------------------------"
    end
  end
  return table.concat(lines, "\n")
end
