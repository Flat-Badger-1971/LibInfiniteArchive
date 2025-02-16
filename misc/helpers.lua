local L = LibInfiniteArchive

--- determine if the supplied ability id is an avatar verse/vision
--- @param abilityId number the ability id of a verse or vision
--- @return boolean # true if the ability id is an avatar verse/vision
function L.IsAvatar(abilityId)
    for avatar, info in pairs(L.AVATAR) do
        if (ZO_IsElementInNumericallyIndexedTable(info.abilityIds, abilityId)) then
            return avatar
        end
    end

    return false
end

--- determine if the player inside the infinite archive, but not in the index/lobby area
--- @return boolean # true if the player is inside an infinite archive stage
function L.IsInsideArchive()
    return IsInstanceEndlessDungeon() and (GetCurrentMapId() ~= L.ArchiveIndex)
end

local solo = ENDLESS_DUNGEON_GROUP_TYPE_SOLO

--- get the current group size, accounting for offline players
--- @return integer|nil # actual/active group size
function L.GetActualGroupType()
    if (IsInstanceEndlessDungeon()) then
        local groupType = GetEndlessDungeonGroupType()
        local groupSize = GetGroupSize()

        if (groupSize == 0 or groupType == solo) then
            groupType = solo
        else
            local size = 0

            for unit = 1, groupSize do
                if (IsUnitOnline(string.format("group%d", unit))) then
                    size = size + 1
                end
            end

            if (size == 1) then
                groupType = solo
            end

            if (L.CurrentGroupType ~= groupType) then
                L.CurrentGroupType = groupType
            end
        end

        return groupType
    end
end

local archiveQuestIndices = {}

--- get the quest journal indices of any infinite archive quests that require you to collect items
--- @param rebuild boolean force a rebuild of the quest indices data
--- @return table # a table of quest journal indices
function L.GetArchiveQuestIndices(rebuild)
    if ((#archiveQuestIndices == 0) or rebuild) then
        ZO_ClearNumericallyIndexedTable(archiveQuestIndices)

        for index = 1, GetNumJournalQuests() do
            local name, _, _, _, _, complete = GetJournalQuestInfo(index)
            if (not complete and ZO_IsElementInNumericallyIndexedTable(L.ARCHIVE_QUESTS, name)) then
                table.insert(archiveQuestIndices, index)
            end
        end
    end

    return archiveQuestIndices
end

--- determine if the player is inside a portal to the unknown
--- @return boolean # true if the player is inside a portal to the unknown
--- @return number|nil # the map id of the current portal to the unknown area
--- @return string|nil # the name of the current portal to the unknown area
function L.IsInUnknown()
    local id = GetCurrentMapId()

    for _, mid in pairs(L.MAPS) do
        if (mid.id == id) then
            return true, mid.id, mid.name
        end
    end

    return false
end

--- determine if the Loyal Auditor is currently active
--- @return boolean # true if the Loyal Auditor is active
function L.IsAuditorActive()
    local auditor = GetString(LIBINFINITEARCHIVE_AUDITOR_NAME)

    for pet = 1, MAX_PET_UNIT_TAGS do
        local name = zo_strformat(GetUnitName(string.format("playerpet%s", tostring(pet))))

        if (name and (name ~= "")) then
            if (name == auditor) then
                return true
            end
        end
    end

    return false
end