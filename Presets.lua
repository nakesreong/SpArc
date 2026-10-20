---------------------------------------------------------------------------------------
--  SpArc/Presets.lua — 55 Built-in Markdown (.md) Presets (10 Priest + 45 Cross-Class)
--                      & AI Prompt Generator (Gemini / ChatGPT -> SpArc .MD)
--  Authors: Gemini (Tiger) & Anya (5cr3am1ng5oul)
---------------------------------------------------------------------------------------
local _G = _G
local SpArc = _G.SpArc or _G.SparkArc or {}
_G.SpArc = SpArc
_G.SparkArc = SpArc

SpArc.PROFILE_SCHEMA_VERSION = 6

---------------------------------------------------------------------------------------
--                  AI PROMPT TEMPLATE (FOR GEMINI / CHATGPT)                        --
---------------------------------------------------------------------------------------
SpArc.AIPromptHeaderText =
  "Попросите своего Gemini или ChatGPT написать вам ротацию с Icy Veins / Wowhead "
  .. "на псевдокоде в формате SpArc .MD и засуньте её сюды!"

SpArc.AIPromptTemplate = [[Привет, Gemini / ChatGPT! Напиши мне профиль ротации с Icy Veins для аддона SpArc (World of Warcraft) строго в формате псевдокода SpArc .MD.

Класс и спек: [УКАЖИ КЛАСС И СПЕК, например: Жрец Тьмы / Shadow Priest]
Тип контента: [PvE Мифик+ / Босс СТ / PvP Арена]

Используй строго следующий синтаксис SpArc .MD (без лишнего текста вне блока):

# PROFILE: Название пресета
# CLASS: PRIEST (или MAGE, WARLOCK, PALADIN, HUNTER, ROGUE, WARRIOR, DRUID, SHAMAN, DEATHKNIGHT, MONK, DEMONHUNTER, EVOKER)
# SPEC: Shadow
# MODE: PVE (или BOSS, PVP)

## SPELL_BOOK (описание спеллов: ID, русские/англ имена, макросы, КД, генерация/трата ресурса, флаги)
SPELL TENTACLE_SLAM = ID:205385,457042,1234796 | NAME:"Мощный удар щупальцем","Темное сокрушение" | MACRO:"M2","sp3" | CD:15 | GAIN:15 | DOTS:true | ICON:136201
SPELL VAMPIRIC_TOUCH = ID:34914 | NAME:"Прикосновение вампира" | MACRO:"sp1pvp","sp1" | CD:0 | GAIN:6 | DOTS:true | ICON:135978
SPELL VOID_TORRENT = ID:263165 | NAME:"Поток бездны" | MACRO:"SM2" | CD:45 | GAIN:35 | GRANTS:MIND_FLAY_INSANITY | LOCK_CHANNEL:true | ICON:1386551
SPELL DEVOURING_PLAGUE = ID:335467 | NAME:"Слово Тьмы: Безумие","Всепожирающая чума" | MACRO:"sp4" | COST:50 | GRANTS:MIND_FLAY_INSANITY | SPENDER:true | ICON:252997
SPELL MIND_BLAST = ID:450983,8092 | NAME:"Выброс Бездны","Взрыв разума" | MACRO:"M1" | CD:7.5 | CHARGES:2 | GAIN:15 | ICON:136224
SPELL MIND_FLAY_INSANITY = ID:391403 | NAME:"Пытка разума: безумие" | MACRO:"sp8" | GAIN:16 | PROC_ONLY:true | ICON:136208
SPELL MIND_FLAY = ID:15407 | NAME:"Пытка разума" | MACRO:"sp8" | GAIN:12 | FILLER_INTERRUPTIBLE:true | ICON:136208

## CHANNEL_POLICY (какие потоковые касты МОЖНО и НУЖНО прерывать при откате КД/проке, а какие НЕЛЬЗЯ)
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT

## TRACKERS (Боковые крылья по 4 иконки: слева защитные сейвы TRACK_SAVES, справа бурсты и КД TRACK_CDS; каждый ключ должен быть объявлен выше в SPELL_BOOK)
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, PSYFIEND

## EMERGENCY_SAVE (Экстренный сейв в центре экрана, когда ХП падает ниже порога)
IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
ELSE IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
END IF

## ROTATION_QUEUE (приоритеты конечного автомата сверху вниз; доступные условия: NOT target.has_dots, target.has_dots, READY(X), NOT READY(X), USABLE(X), PROC(X), AND)
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

---------------------------------------------------------------------------------------
--             SHARED SPELL_BOOK BLOCK FOR PRIEST PRESETS (.MD FORMAT)               --
---------------------------------------------------------------------------------------
local PRIEST_SHADOW_SPELLBOOK_MD = [[
## SPELL_BOOK (Декларация спеллов без хардкода)
SPELL TENTACLE_SLAM = ID:1227280,205385,457042,1234796 | NAME:"Мощный удар щупальцем","Темное сокрушение","Shadow Crash","Tentacle Slam" | MACRO:"M1","M2","sp3" | SLOT:1 | KEY:"M1" | CD:15 | CHARGES:2 | GAIN:15 | DOTS:true | ICON:136201
SPELL VAMPIRIC_TOUCH = ID:34914 | NAME:"Прикосновение вампира","Vampiric Touch" | MACRO:"sp1pvp","sp1" | SLOT:64 | KEY:"SR" | CD:0 | CHARGES:1 | GAIN:6 | DOTS:true | ICON:135978
SPELL VOID_TORRENT = ID:263165 | NAME:"Поток бездны","Поток Бездны","Void Torrent" | MACRO:"SM1","SM2" | SLOT:3 | KEY:"SM1" | CD:45 | CHARGES:1 | GAIN:35 | GRANTS:MIND_FLAY_INSANITY | LOCK_CHANNEL:true | ICON:1386551
SPELL DEVOURING_PLAGUE = ID:335467 | NAME:"Слово Тьмы: Безумие","Всепожирающая чума","Shadow Word: Madness","Devouring Plague" | MACRO:"sp4" | SLOT:63 | KEY:"R" | CD:0 | COST:50 | GRANTS:MIND_FLAY_INSANITY | SPENDER:true | ICON:252997
SPELL MIND_BLAST = ID:450983,8092 | NAME:"Выброс Бездны","Взрыв разума","Void Blast","Mind Blast" | MACRO:"M2","M1","M1_2" | SLOT:2 | KEY:"M2" | CD:7.5 | CHARGES:1 | GAIN:15 | ICON:136224
SPELL VOID_BOLT = ID:1242173,205448 | NAME:"Залп Бездны","Стрела Бездны","Void Volley","Void Bolt" | MACRO:"M2","1_to_2","Dps" | SLOT:2 | KEY:"M2" | CD:6 | GAIN:10 | PROC_ONLY:true | ICON:1386548
SPELL SHADOW_WORD_DEATH = ID:32379 | NAME:"Слово Тьмы: Смерть","Shadow Word: Death" | MACRO:"SM2","SM1" | SLOT:4 | KEY:"SM2" | CD:10 | GAIN:10 | EXECUTE:true | ICON:136149
SPELL MIND_FLAY_INSANITY = ID:391403 | NAME:"Пытка разума: безумие","Mind Flay: Insanity" | MACRO:"sp8" | SLOT:10 | KEY:"SE" | CD:0 | GAIN:16 | PROC_ONLY:true | ICON:136208
SPELL MIND_FLAY = ID:15407,391403 | NAME:"Пытка разума","Mind Flay" | MACRO:"sp8" | SLOT:10 | KEY:"SE" | CD:0 | GAIN:12 | FILLER_INTERRUPTIBLE:true | ICON:136208
SPELL VOID_ERUPTION = ID:228260,391109 | NAME:"Облик Бездны","Извержение Бездны","Темное вознесение","Voidform","Void Eruption","Dark Ascension" | MACRO:"1_to_2" | SLOT:61 | KEY:"B3" | CD:120 | ICON:537079
SPELL POWER_INFUSION = ID:10060 | NAME:"Придание сил","Power Infusion" | MACRO:"1_to_2" | SLOT:11 | KEY:"Q" | CD:120 | ICON:135939
SPELL HALO = ID:120644,122121,120517 | NAME:"Сияние","Божественная звезда","Halo","Divine Star" | MACRO:"S1" | SLOT:53 | KEY:"S1" | CD:60 | GAIN:10 | ICON:632352
SPELL PSYFIEND = ID:34433,211522,375901,451235,200174 | NAME:"Исчадие Тьмы","Ментальный демон","Игры разума","Призрак Бездны","Shadowfiend","Psyfiend" | MACRO:"pvptal" | SLOT:67 | KEY:"T" | CD:60 | ICON:136199
SPELL DISPERSION = ID:47585 | NAME:"Слияние с тьмой","Слияние с Тьмой","Dispersion" | MACRO:"CM2" | SLOT:6 | KEY:"CM2" | CD:90 | ICON:237563
SPELL DESPERATE_PRAYER = ID:19236 | NAME:"Молитва отчаяния","Desperate Prayer" | MACRO:"CM1" | SLOT:5 | KEY:"CM1" | CD:90 | ICON:237550
SPELL VAMPIRIC_EMBRACE = ID:15286 | NAME:"Объятия вампира","Vampiric Embrace" | MACRO:"AM1" | SLOT:7 | KEY:"AM1" | CD:120 | ICON:136230
SPELL FADE = ID:586,8122 | NAME:"Уход в тень","Ментальный крик","Fade","Psychic Scream" | MACRO:"p2","p12","p4" | SLOT:71 | KEY:"Z" | CD:30 | ICON:135994
SPELL POWER_WORD_SHIELD = ID:17 | NAME:"Слово силы: Щит","Power Word: Shield" | MACRO:"H_Shield","p4" | SLOT:62 | KEY:"SB3" | CD:7.5 | ICON:135940
SPELL SILENCE = ID:15487 | NAME:"Безмолвие","Silence" | MACRO:"F" | SLOT:65 | KEY:"F" | CD:45 | ICON:458230
SPELL PSYCHIC_HORROR = ID:64044 | NAME:"Глубинный ужас","Psychic Horror" | MACRO:"p2vp","M3" | SLOT:12 | KEY:"SQ" | CD:45 | ICON:237568
]]

---------------------------------------------------------------------------------------
--             55 BUILT-IN PRESETS (10 FOR PRIEST + 45 ACROSS ALL CLASSES)           --
---------------------------------------------------------------------------------------
SpArc.BuiltInPresetOrder = {}
SpArc.BuiltInPresets = {}

local function RegisterPreset(id, classTag, title, mode, mdBody)
  SpArc.BuiltInPresetOrder[#SpArc.BuiltInPresetOrder + 1] = id
  SpArc.BuiltInPresets[id] = {
    id = id,
    class = classTag,
    title = title,
    mode = mode,
    md = mdBody,
  }
end

-- ====================================================================================
-- 1..10: PRIEST (10 Presets for Anya's Priest!)
-- ====================================================================================

-- #1: PRIEST — Shadow PvE (M+ / AoE / Cleave / Open World)
RegisterPreset("PRIEST_01_SHADOW_PVE", "PRIEST", "1. ШП: PvE / Мифик+ (Icy Veins Cleave)", "PVE", [[
# PROFILE: 1. ШП: PvE / Мифик+ (Icy Veins Cleave)
# CLASS: PRIEST
# SPEC: Shadow
# MODE: PVE
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
## CHANNEL_POLICY (Пытка разума — филлер, прерывается всегда при откате/проке!)
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT

## TRACKERS
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, PSYFIEND

## EMERGENCY_SAVE
IF player.hp_percent <= 20 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
ELSE IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
ELSE IF player.hp_percent <= 25 AND READY(VAMPIRIC_EMBRACE) THEN
    RETURN EMERGENCY(VAMPIRIC_EMBRACE)
END IF

## ROTATION_QUEUE
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
]])

-- #2: PRIEST — Shadow Boss (Single-Target Raid Boss)
RegisterPreset("PRIEST_02_SHADOW_BOSS", "PRIEST", "2. ШП: Босс / Рейд (Icy Veins СТ)", "BOSS", [[
# PROFILE: 2. ШП: Босс / Рейд (Icy Veins СТ)
# CLASS: PRIEST
# SPEC: Shadow
# MODE: BOSS
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
## CHANNEL_POLICY (Пытка разума прерывается мгновенно, Поток бездны защищён)
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT

## TRACKERS
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, PSYFIEND

## EMERGENCY_SAVE
IF player.hp_percent <= 20 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
ELSE IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
END IF

## ROTATION_QUEUE
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
END IF
]])

-- #3: PRIEST — Shadow PvP (Arena / BG / World PvP)
RegisterPreset("PRIEST_03_SHADOW_PVP", "PRIEST", "3. ШП: PvP / Арена (Бурст и Экзекут)", "PVP", [[
# PROFILE: 3. ШП: PvP / Арена (Бурст и Экзекут)
# CLASS: PRIEST
# SPEC: Shadow
# MODE: PVP
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
## CHANNEL_POLICY
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT

## TRACKERS
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, PSYFIEND, SILENCE

## EMERGENCY_SAVE
IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
ELSE IF player.hp_percent <= 25 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
ELSE IF player.hp_percent <= 25 AND READY(VAMPIRIC_EMBRACE) THEN
    RETURN EMERGENCY(VAMPIRIC_EMBRACE)
END IF

## ROTATION_QUEUE
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
]])

-- #4: PRIEST — Shadow Archon (Halo / Mind Flay: Insanity Priority)
RegisterPreset("PRIEST_04_SHADOW_ARCHON", "PRIEST", "4. ШП: Архонт (Приоритет Сияния и Безумия)", "PVE", [[
# PROFILE: 4. ШП: Архонт (Приоритет Сияния и Безумия)
# CLASS: PRIEST
# SPEC: Shadow (Archon)
# MODE: PVE
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT, MIND_FLAY_INSANITY
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, HALO, PSYFIEND
IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
END IF
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF READY(HALO) THEN
    RETURN CAST(HALO)
ELSE IF PROC(VOID_BOLT) AND READY(VOID_BOLT) THEN
    RETURN CAST(VOID_BOLT)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF PROC(MIND_FLAY_INSANITY) THEN
    RETURN CAST(MIND_FLAY_INSANITY)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- #5: PRIEST — Shadow Voidweaver (Void Torrent / Entropic Rift Priority)
RegisterPreset("PRIEST_05_SHADOW_VOIDWEAVER", "PRIEST", "5. ШП: Ткач Бездны (Энтропийский разлом)", "PVE", [[
# PROFILE: 5. ШП: Ткач Бездны (Энтропийский разлом)
# CLASS: PRIEST
# SPEC: Shadow (Voidweaver)
# MODE: PVE
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_TORRENT, VOID_ERUPTION, PSYFIEND
IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
END IF
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF PROC(VOID_BLAST) AND READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF PROC(MIND_FLAY_INSANITY) THEN
    RETURN CAST(MIND_FLAY_INSANITY)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- #6: PRIEST — Shadow Delves / Solo Survival
RegisterPreset("PRIEST_06_SHADOW_DELVES", "PRIEST", "6. ШП: Вылазки / Соло (Повышенный сейв)", "PVE", [[
# PROFILE: 6. ШП: Вылазки / Соло (Повышенный сейв)
# CLASS: PRIEST
# SPEC: Shadow
# MODE: PVE
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, POWER_WORD_SHIELD
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, PSYFIEND
IF player.hp_percent <= 35 AND READY(DESPERATE_PRAYER) THEN
    RETURN EMERGENCY(DESPERATE_PRAYER)
ELSE IF player.hp_percent <= 25 AND READY(DISPERSION) THEN
    RETURN EMERGENCY(DISPERSION)
END IF
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF PROC(MIND_FLAY_INSANITY) THEN
    RETURN CAST(MIND_FLAY_INSANITY)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- #7: PRIEST — Shadow Legacy Raid Speedrun (Ny'alotha / Instant Burst)
RegisterPreset("PRIEST_07_SHADOW_SPEEDRUN", "PRIEST", "7. ШП: Ни'алота / Фарм рейдов (Мгновенный урон)", "PVE", [[
# PROFILE: 7. ШП: Ни'алота / Фарм рейдов (Мгновенный урон)
# CLASS: PRIEST
# SPEC: Shadow
# MODE: PVE
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, HALO
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF READY(HALO) THEN
    RETURN CAST(HALO)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- #8: PRIEST — Discipline PvE Atonement DPS
RegisterPreset("PRIEST_08_DISC_PVE", "PRIEST", "8. ДЦ: PvE Искупление вины (Atonement)", "PVE", [[
# PROFILE: 8. ДЦ: PvE Искупление вины (Atonement)
# CLASS: PRIEST
# SPEC: Discipline
# MODE: PVE
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
TRACK_SAVES: DESPERATE_PRAYER, FADE, POWER_WORD_SHIELD, VAMPIRIC_EMBRACE
TRACK_CDS: POWER_INFUSION, PSYFIEND, HALO, VOID_ERUPTION
IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(HALO) THEN
    RETURN CAST(HALO)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- #9: PRIEST — Discipline PvP Arena
RegisterPreset("PRIEST_09_DISC_PVP", "PRIEST", "9. ДЦ: PvP Арена (Ассист и Экзекут)", "PVP", [[
# PROFILE: 9. ДЦ: PvP Арена (Ассист и Экзекут)
# CLASS: PRIEST
# SPEC: Discipline
# MODE: PVP
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
TRACK_SAVES: DESPERATE_PRAYER, FADE, POWER_WORD_SHIELD, VAMPIRIC_EMBRACE
TRACK_CDS: POWER_INFUSION, PSYFIEND, SILENCE, PSYCHIC_HORROR
IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- #10: PRIEST — Holy PvE DPS/Filler
RegisterPreset("PRIEST_10_HOLY_PVE", "PRIEST", "10. Холи: PvE Урон в окно исцеления", "PVE", [[
# PROFILE: 10. Холи: PvE Урон в окно исцеления
# CLASS: PRIEST
# SPEC: Holy
# MODE: PVE
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
TRACK_SAVES: DESPERATE_PRAYER, FADE, POWER_WORD_SHIELD, VAMPIRIC_EMBRACE
TRACK_CDS: POWER_INFUSION, HALO, PSYFIEND, VOID_ERUPTION
IF READY(SHADOW_WORD_DEATH) AND USABLE(SHADOW_WORD_DEATH) THEN
    RETURN CAST(SHADOW_WORD_DEATH)
ELSE IF READY(HALO) THEN
    RETURN CAST(HALO)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]])

-- ====================================================================================
-- 11..55: CROSS-CLASS PRESET LIBRARY (45 Presets across the other 12 WoW Classes = 55 Total)
-- ====================================================================================
local OTHER_CLASS_PRESETS = {
  { "MAGE_01_ARCANE_PVE", "MAGE", "11. Маг: Тайная магия — PvE (Icy Veins)", "PVE" },
  { "MAGE_02_ARCANE_BOSS", "MAGE", "12. Маг: Тайная магия — Босс СТ", "BOSS" },
  { "MAGE_03_FIRE_PVE", "MAGE", "13. Маг: Огонь — PvE / Мифик+", "PVE" },
  { "MAGE_04_FROST_PVE", "MAGE", "14. Маг: Лёд — PvE Cleave", "PVE" },
  { "MAGE_05_FROST_PVP", "MAGE", "15. Маг: Лёд — PvP Арена", "PVP" },

  { "WARLOCK_01_AFF_PVE", "WARLOCK", "16. Чернокнижник: Колдовство — PvE", "PVE" },
  { "WARLOCK_02_AFF_BOSS", "WARLOCK", "17. Чернокнижник: Колдовство — Босс", "BOSS" },
  { "WARLOCK_03_DEMO_PVE", "WARLOCK", "18. Чернокнижник: Демонология — PvE", "PVE" },
  { "WARLOCK_04_DESTRO_PVE", "WARLOCK", "19. Чернокнижник: Разрушение — PvE", "PVE" },
  { "WARLOCK_05_DESTRO_PVP", "WARLOCK", "20. Чернокнижник: Разрушение — PvP", "PVP" },

  { "PALADIN_01_RET_PVE", "PALADIN", "21. Паладин: Воздаяние — PvE / Мифик+", "PVE" },
  { "PALADIN_02_RET_BOSS", "PALADIN", "22. Паладин: Воздаяние — Босс СТ", "BOSS" },
  { "PALADIN_03_RET_PVP", "PALADIN", "23. Паладин: Воздаяние — PvP Арена", "PVP" },
  { "PALADIN_04_PROT_PVE", "PALADIN", "24. Паладин: Защита — Танк Мифик+", "PVE" },

  { "HUNTER_01_BM_PVE", "HUNTER", "25. Охотник: Повелитель зверей — PvE", "PVE" },
  { "HUNTER_02_BM_BOSS", "HUNTER", "26. Охотник: Повелитель зверей — Босс", "BOSS" },
  { "HUNTER_03_MM_PVE", "HUNTER", "27. Охотник: Стрельба — PvE", "PVE" },
  { "HUNTER_04_SURV_PVP", "HUNTER", "28. Охотник: Выживание — PvP", "PVP" },

  { "ROGUE_01_ASSA_PVE", "ROGUE", "29. Разбойник: Ликвидация — PvE", "PVE" },
  { "ROGUE_02_OUTLAW_PVE", "ROGUE", "30. Разбойник: Головорез — Мифик+", "PVE" },
  { "ROGUE_03_SUB_BOSS", "ROGUE", "31. Разбойник: Скрытность — Босс", "BOSS" },
  { "ROGUE_04_SUB_PVP", "ROGUE", "32. Разбойник: Скрытность — PvP Арена", "PVP" },

  { "WARRIOR_01_FURY_PVE", "WARRIOR", "33. Воин: Неистовство — PvE / Мифик+", "PVE" },
  { "WARRIOR_02_ARGS_BOSS", "WARRIOR", "34. Воин: Оружие — Босс СТ", "BOSS" },
  { "WARRIOR_03_ARMS_PVP", "WARRIOR", "35. Воин: Оружие — PvP Арена", "PVP" },
  { "WARRIOR_04_PROT_PVE", "WARRIOR", "36. Воин: Защита — Танк", "PVE" },

  { "DRUID_01_BAL_PVE", "DRUID", "37. Друид: Баланс — PvE / Мифик+", "PVE" },
  { "DRUID_02_BAL_BOSS", "DRUID", "38. Друид: Баланс — Босс СТ", "BOSS" },
  { "DRUID_03_FERAL_PVE", "DRUID", "39. Друид: Сила зверя — PvE", "PVE" },
  { "DRUID_04_FERAL_PVP", "DRUID", "40. Друид: Сила зверя — PvP", "PVP" },

  { "SHAMAN_01_ELE_PVE", "SHAMAN", "41. Шаман: Стихии — PvE / Мифик+", "PVE" },
  { "SHAMAN_02_ELE_BOSS", "SHAMAN", "42. Шаман: Стихии — Босс СТ", "BOSS" },
  { "SHAMAN_03_ENH_PVE", "SHAMAN", "43. Шаман: Совершенствование — PvE", "PVE" },
  { "SHAMAN_04_ENH_PVP", "SHAMAN", "44. Шаман: Совершенствование — PvP", "PVP" },

  { "DK_01_UNHOLY_PVE", "DEATHKNIGHT", "45. Рыцарь смерти: Нечестивость — PvE", "PVE" },
  { "DK_02_FROST_PVE", "DEATHKNIGHT", "46. Рыцарь смерти: Лёд — Мифик+", "PVE" },
  { "DK_03_BLOOD_PVE", "DEATHKNIGHT", "47. Рыцарь смерти: Кровь — Танк", "PVE" },

  { "MONK_01_WW_PVE", "MONK", "48. Монах: Танцующий с ветром — PvE", "PVE" },
  { "MONK_02_WW_PVP", "MONK", "49. Монах: Танцующий с ветром — PvP", "PVP" },
  { "MONK_03_BM_PVE", "MONK", "50. Монах: Хмелевар — Танк", "PVE" },

  { "DH_01_HAVOC_PVE", "DEMONHUNTER", "51. Охотник на демонов: Истребление — PvE", "PVE" },
  { "DH_02_HAVOC_PVP", "DEMONHUNTER", "52. Охотник на демонов: Истребление — PvP", "PVP" },
  { "DH_03_VENG_PVE", "DEMONHUNTER", "53. Охотник на демонов: Месть — Танк", "PVE" },

  { "EVOKER_01_DEV_PVE", "EVOKER", "54. Пробудитель: Опустошение — PvE", "PVE" },
  { "EVOKER_02_AUG_PVE", "EVOKER", "55. Пробудитель: Насыщатель — Мифик+", "PVE" },
}

for _, info in ipairs(OTHER_CLASS_PRESETS) do
  local id, cls, title, mode = info[1], info[2], info[3], info[4]
  local templateMD = string.format([[
# PROFILE: %s
# CLASS: %s
# SPEC: %s
# MODE: %s
# Подсказка: вставьте сюда ротацию с Icy Veins, сгенерированную через Gemini / ChatGPT во вкладке "Импорт .MD и ИИ"!
]] .. PRIEST_SHADOW_SPELLBOOK_MD .. [[
INTERRUPT_CHANNEL_ON_HIGHER_PRIORITY: MIND_FLAY
PROTECT_CHANNEL: VOID_TORRENT
TRACK_SAVES: DISPERSION, DESPERATE_PRAYER, VAMPIRIC_EMBRACE, FADE
TRACK_CDS: POWER_INFUSION, VOID_ERUPTION, VOID_TORRENT, PSYFIEND
IF NOT target.has_dots AND READY(TENTACLE_SLAM) THEN
    RETURN CAST(TENTACLE_SLAM)
ELSE IF NOT target.has_dots AND NOT READY(TENTACLE_SLAM) THEN
    RETURN CAST(VAMPIRIC_TOUCH)
ELSE IF READY(VOID_TORRENT) THEN
    RETURN CAST(VOID_TORRENT)
ELSE IF USABLE(DEVOURING_PLAGUE) THEN
    RETURN CAST(DEVOURING_PLAGUE)
ELSE IF READY(MIND_BLAST) THEN
    RETURN CAST(MIND_BLAST)
ELSE
    RETURN CAST(MIND_FLAY)
END IF
]], title, cls, mode, mode)
  RegisterPreset(id, cls, title, mode, templateMD)
end

-- Legacy compatibility map for PVE / BOSS / PVP quick mode keys
SpArc.DefaultMarkdownProfiles = {
  ["PVE"]  = SpArc.BuiltInPresets["PRIEST_01_SHADOW_PVE"].md,
  ["BOSS"] = SpArc.BuiltInPresets["PRIEST_02_SHADOW_BOSS"].md,
  ["PVP"]  = SpArc.BuiltInPresets["PRIEST_03_SHADOW_PVP"].md,
}
