LibInfiniteArchiveConstants = { Name = "LibInfiniteArchive" }
local L = LibInfiniteArchiveConstants
local lia = "LIBINFINITEARCHIVE_"

L.DEBUG = true

L.ENUMS = {
    UNKNOWN_PORTAL_STATE_UNKNOWN = 0,
    UNKNOWN_PORTAL_STATE_EXITED = 1,
    UNKNOWN_PORTAL_STATE_ENTERED = 2,
    UNKNOWN_PORTAL_STATE_STARTED = 3,
    UNKNOWN_PORTAL_STATE_FAILED = 4,
    UNKNOWN_PORTAL_STATE_SUCCEEDED = 5
}

L.PROTOCOL_ID_EVENTS = 51

L.EVENT_BUFF_SELECTED = 1
L.EVENT_ITEM_DETECTED = 2
L.EVENT_MARAUDER_SPAWNED = 3
L.EVENT_MYSTERY_VERSE_USED = 4
L.EVENT_SWEETROLL_CONSUMED = 5
L.EVENT_TOMESHELL_DESTROYED = 6
L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED = 7

L.EVENTS = {
    [L.EVENT_BUFF_SELECTED] = "EVENT_BUFF_SELECTED",
    [L.EVENT_MARAUDER_SPAWNED] = "EVENT_MARAUDER_SPAWNED",
    [L.EVENT_MYSTERY_VERSE_USED] = "EVENT_MYSTERY_VERSE_USED",
    [L.EVENT_SWEETROLL_CONSUMED] = "EVENT_SWEETROLL_CONSUMED",
    [L.EVENT_TOMESHELL_DESTROYED] = "EVENT_TOMESHELL_DESTROYED",
    [L.EVENT_ITEM_DETECTED] = "EVENT_ITEM_DETECTED",
    [L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED] = "EVENT_UNKNOWN_PORTAL_STATE_CHANGED"
}

-- map id of the archive index/lobby
L.ARCHIVE_INDEX = 2407

L.MAPS = {
    TREACHEROUS_CROSSING = { id = 2420, name = GetString(_G[lia .. "MAP_TREACHEROUS_CROSSING"]) },
    HAEFALS_BUTCHERY = { id = 2421, name = GetString(_G[lia .. "MAP_HAEFALS_BUTCHERY"]) },
    FILERS_WING = { id = 2422, name = GetString(_G[lia .. "MAP_FILERS_WING"]) },
    ECHOING_DEN = { id = 2423, name = GetString(_G[lia .. "MAP_ECHOING_DEN"]) },
    THEATRE_OF_WAR = { id = 2424, name = GetString(_G[lia .. "MAP_THEATRE_OF_WAR"]) },
    DESTOZUNOS_LIBRARY = { id = 2425, name = GetString(_G[lia .. "MAP_DESTOZUNOS_LIBRARY"]) }
}

L.CLASSES = {
    AVATAR = SI_ENDLESSDUNGEONBUFFTYPE_AVATAR2,
    DEFENCE = SI_ENDLESSDUNGEONBUFFBUCKETTYPE1,
    OFFENCE = SI_ENDLESSDUNGEONBUFFBUCKETTYPE0,
    UTILITY = SI_ENDLESSDUNGEONBUFFBUCKETTYPE2
}

L.AVATAR = {
    ICE = { id = 3795, abilityIds = { 202134, 202510, 200494, 199997 }, class = L.CLASSES.DEFENCE, transform = 202134 },
    WOLF = { id = 3796, abilityIds = { 202743, 200421, 199990, 191802 }, class = L.CLASSES.OFFENCE, transform = 191802 },
    IRON = { id = 3797, abilityIds = { 202804, 200679, 200004, 196018 }, class = L.CLASSES.UTILITY, transform = 196018 },
    UNDEAD = { id = 4155, abilityIds = { 220557, 220563, 220568, 220189 }, class = L.CLASSES.OFFENCE, transform = 220189 }
}

L.MARAUDERS = {
    GetString(_G[lia .. "MARAUDER_GOTHMAU"]),
    GetString(_G[lia .. "MARAUDER_HILKARAX"]),
    GetString(_G[lia .. "MARAUDER_ULMOR"]),
    GetString(_G[lia .. "MARAUDER_BITTOG"]),
    GetString(_G[lia .. "MARAUDER_ZULFIMBUL"])
}

-- quests that require you to collect objects in the infinite archive
L.ARCHIVE_QUESTS = { GetQuestName(7091), GetQuestName(7101), GetQuestName(7102) }

-- mystery verse ids and texture names
L.MYSTERY = {
    [203611] = "u40_verse_item_offense", -- offensive
    [203612] = "u40_verse_item_defense", -- defensive
    [203613] = "u40_verse_item_utility"  -- utility
}

L.TOMESHELLS = { SOLO = 4, DUO = 8 }
L.LGB = LibGroupBroadcast
