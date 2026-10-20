---------------------------------------------------------------------------------------
--  SpArc/Telemetry.lua — SpellBook vs Bartender4 vs SpArc Telemetry Auditor
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc

local GetTime = _G.GetTime
local UnitPower = _G.UnitPower
local pcall = _G.pcall
local ipairs = _G.ipairs
local pairs = _G.pairs
local tostring = _G.tostring
local type = _G.type
local math = _G.math
local table = _G.table
local string = _G.string

local IsSecret = SpArc.IsSecret
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

  local rawInsStr = "n/a"
  if UnitPower then
    local okP, p = pcall(UnitPower, "player", 13)
    if okP then
      rawInsStr = IsSecret(p) and "SECRET" or tostring(p)
    end
  end

  local assistedKey, assistedID = SpArc:GetAssistedSuggestedDefKey()
  local hasDoTs = SpArc:CheckTargetHasDoTs(assistedKey)

  local bookDiffs = {}
  for _, sKey in ipairs(CORE_AUDIT_ORDER) do
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

  local entry = string.format(
    "[%s | %s] Загорелось: %s | Безумие(книга=%s, трек=%d) | Доты=%s | БлиззАссист=%s(%s)\n  " .. table.concat(bookDiffs, "\n  "),
    GetTimestampStr(),
    reasonTag or "TICK",
    qStr,
    rawInsStr,
    st.trackedInsanity or 0,
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
  lines[#lines + 1] = "=== SPARC v" .. SpArc.VERSION .. " — ТЕЛЕМЕТРИЯ И СВЕРКА С КНИГЕ ЗАКЛИНАНИЙ ==="
  lines[#lines + 1] = "Сбор телеметрии: " .. ((db.visual and db.visual.enableTelemetry) and "ВКЛЮЧЕН (пишется в WTF/.../SavedVariables/SpArc.lua)" or "ВЫКЛЮЧЕН")
  lines[#lines + 1] = ""
  lines[#lines + 1] = "--- 1. ТЕКУЩЕЕ СОСТОЯНИЕ ПО КНИГЕ ЗАКЛИНАНИЙ И ПАНЕЛЯМ BARTENDER4 ---"
  for _, sKey in ipairs(CORE_AUDIT_ORDER) do
    local a = st.lastSpellAudit[sKey]
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
