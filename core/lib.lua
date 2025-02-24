-- TODO: account for achievement levels in portals

local lib = ZO_InitializingObject:Subclass()
local L = LibInfiniteArchiveConstants
local buffchoice = GetEndlessDungeonBuffSelectorBucketTypeChoice

local function onHiding(self)
    zo_callLater(function() self.showingBuffs = false end, 1500)
end

local function onChoiceCommitted(self)
    if (self.SelectedBuff) then
        local name = GetAbilityName(self.SelectedBuff, "player")

        self.las:Share(L.EVENT_BUFF_SELECTED, self.SelectedBuff, name, self.player)
    end
end

local function onCompassUpdate(self)
    if (self:IsInsideArchive() and self.InCombat and not self.FoundQuestItem) then
        local numPins = COMPASS.container:GetNumCenterOveredPins()

        if (numPins > 0) then
            for pin = 1, numPins do
                if (COMPASS.container:GetCenterOveredPinType(pin) == MAP_PIN_TYPE_QUEST_INTERACT) then
                    self.FoundQuestItem = true
                    self.las:Share(L.EVENT_UNIT_OR_ITEM_DETECTED, self.DETECTED_ITEM, "QuestItem")
                    break
                end
            end
        end
    end
end

local function getMap(mapId)
    for map, data in pairs(L.MAPS) do
        if (data.id == mapId) then
            return data
        end
    end
end

local function onPlayerActivated(self)
    if (not IsInstanceEndlessDungeon()) then return end

    local mapId = GetCurrentMapId()

    if (self.LastMapId ~= mapId) then
        self.LastMapId = mapId

        local wasInPortal = self.UnknownPortal ~= nil

        self.UnknownPortal = getMap(mapId)

        if (self.UnknownPortal) then
            self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED, mapId, self.UnknownPortal.name, self.UNKNOWN_PORTAL_STATE_ENTERED)
        elseif (wasInPortal) then
            self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED, -1, "", self.UNKNOWN_PORTAL_STATE_EXITED)
        end
    else
        self.UnknownPortal = nil
    end

    local groupType = self:GetEffectiveGroupType()

    if (self.CurrentGroupType ~= groupType) then
        self.CurrentGroupType = groupType
    end
end

local function hasText(msg, textid)
    local text = zo_strformat(textid)

    return zo_strfind(msg, zo_strlower(text), 1, true) ~= nil
end

local function checkMessage(self, messageParams)
    if (not self.UnknownPortal) then
        onPlayerActivated(self)
    end

    if (not self.UnknownPortal) then
        return
    end

    local message = zo_strformat(messageParams:GetMainText())
    local secondaryMessage = zo_strformat(messageParams:GetSecondaryText() or "")
    local concat = zo_strlower(message .. " " .. secondaryMessage)
    local start, fail, success

    -- Echoing Den
    if (self.UnknownPortal.id == L.MAPS.ECHOING_DEN.id) then
        start = hasText(concat, LIBINFINITEARCHIVE_HERD)
        fail = hasText(concat, LIBINFINITEARCHIVE_HERD_FAIL)
        success = hasText(concat, LIBINFINITEARCHIVE_HERD_SUCCESS)
    end

    -- Filer's Wing
    if (self.UnknownPortal.id == L.MAPS.FILERS_WING.id) then
        start = hasText(concat, L.MAPS.FILERS_WING.name)
        fail = hasText(concat, LIBINFINITEARCHIVE_FILERS_WING_FAIL)
        success = hasText(concat, LIBINFINITEARCHIVE_FILERS_WING_SUCCESS)
    end

    -- Treacherous crossing
    if (self.UnknownPortal.id == L.MAPS.TREACHEROUS_CROSSING.id) then
        start = hasText(concat, L.MAPS.TREACHEROUS_CROSSING.name)
        fail = hasText(concat, LIBINFINITEARCHIVE_CROSSING_FAIL)
        success = hasText(concat, LIBINFINITEARCHIVE_CROSSING_SUCCESS)
    end

    -- Haefal's Butchery
    if (self.UnknownPortal.id == L.MAPS.HAEFALS_BUTCHERY.id) then
        start = hasText(concat, LIBINFINITEARCHIVE_HAEFAL_START)
        fail = hasText(concat, LIBINFINITEARCHIVE_HAEFAL_FAIL)
        success = hasText(concat, LIBINFINITEARCHIVE_HAEFAL_SUCCESS)
    end

    -- Theatre of War
    if (self.UnknownPortal.id == L.MAPS.THEATRE_OF_WAR.id) then
        fail = hasText(concat, LIBINFINITEARCHIVE_THEATRE_FAIL)
        success = hasText(concat, LIBINFINITEARCHIVE_THEATRE_SUCCESS)
    end

    -- Destozuno's Library
    if (self.UnknownPortal.id == L.MAPS.DESTOZUNOS_LIBRARY.id) then
        -- no events
    end

    if (start) then
        self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED, self.UnknownPortal.id, self.UnknownPortal.name, self.UNKNOWN_PORTAL_STATE_STARTED)
    elseif (fail) then
        self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED, self.UnknownPortal.id, self.UnknownPortal.name, self.UNKNOWN_PORTAL_STATE_FAILED)
        self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED, self.UnknownPortal.id, self.UnknownPortal.name, self.UNKNOWN_PORTAL_STATE_ENDED)
    elseif (success) then
        self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED, self.UnknownPortal.id, self.UnknownPortal.name, self.UNKNOWN_PORTAL_STATE_SUCCEEDED)
        self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED, self.UnknownPortal.id, self.UnknownPortal.name, self.UNKNOWN_PORTAL_STATE_ENDED)
    end
end

local function onMessage(self, _, messageParams)
    if (not messageParams or not IsInstanceEndlessDungeon()) then
        return
    end

    checkMessage(self, messageParams)
end

local function bossHandled(self, unitTag, name)
    if (self.Bosses[unitTag] == name) then
        return true
    end

    self.Bosses[unitTag] = name

    return false
end

local function isMarauder(name)
    local bossName = name:lower()

    for _, marauder in ipairs(L.MARAUDERS) do
        if (zo_strfind(bossName, marauder, 1, true)) then
            return true
        end
    end

    return false
end

local function onNewBoss(self, _, unitTag)
    if (not IsInstanceEndlessDungeon() or unitTag == "") then
        return
    end

    local bossName = GetUnitName(unitTag)

    if (bossHandled(self, unitTag, bossName)) then
        return
    end

    if (isMarauder(bossName)) then
        self.las:Share(L.EVENT_MARAUDER_SPAWNED, bossName)
    end
end

local function onQuestCounterChanged(self, _, journalIndex)
    if (IsInstanceEndlessDungeon()) then
        local indices = self:GetArchiveQuestIndices(true)

        if (ZO_IsElementInNumericallyIndexedTable(indices, journalIndex)) then
            self.FoundQuestItem = false
        end
    end
end

local function resetValues(self)
    ZO_ClearNumericallyIndexedTable(self.Bosses)
    self.FoundQuestItem = false
    self.FoundGw = false
end

local function onStunned(self, _, stunned)
    if (not IsInstanceEndlessDungeon()) then return end

    if (stunned and not IsUnitInCombat("player")) then
        local now = GetTimeStamp()

        if ((now - (self.LastStun or 0)) > 2) then
            zo_callLater(function()
                if (not self.ShowingBuffs) then
                    resetValues(self)
                end
            end, 1000)

            self.LastStun = now
        end
    end
end

local function tomeCheck(self, ...)
    local result = select(2, ...)
    local sourceName, _, targetName = select(7, ...)

    if (result == ACTION_RESULT_DIED or result == ACTION_RESULT_DIED_XP) then
        targetName = zo_strlower(zo_strformat(targetName))
        sourceName = zo_strlower(zo_strformat(sourceName))

        if (zo_strfind(targetName, self.tomeName, 1, true) or zo_strfind(sourceName, self.tomeName, 1, true)) then
            self.TomesFound = self.TomesFound + 1

            local tomesLeft = self.MaxTomes - self.TomesFound

            tomesLeft = (tomesLeft < 0) and 0 or tomesLeft

            self.las:Share(L.EVENT_TOMESHELL_DESTROYED, self.TomesFound, tomesLeft)
        end
    end
end

local function startTomeCheck(self)
    self.MaxTomes = self:GetMaxTomes()
    self.TomesFound = 0

    EVENT_MANAGER:RegisterForEvent(L.Name .. "_Tome", EVENT_COMBAT_EVENT, function(...) tomeCheck(self, ...) end)
end

local function stopTomeCheck()
    EVENT_MANAGER:UnregisterForEvent(L.Name .. "_Tome", _G.EVENT_COMBAT_EVENT)
end

local function onHotBarChange(self, _, changed, shouldUpdate, category)
    if (not IsInstanceEndlessDungeon()) then return end

    if (GetCurrentMapId() == L.MAPS.FILERS_WING.id) then
        if (category == HOTBAR_CATEGORY_TEMPORARY and shouldUpdate and changed) then
            self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED, L.MAPS.FILERS_WING.id, L.MAPS.FILERS_WING.name, self.UNKNOWN_PORTAL_STATE_STARTED)
            startTomeCheck(self)
        end

        if (category == HOTBAR_CATEGORY_PRIMARY and changed and not shouldUpdate) then
            self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED, L.MAPS.FILERS_WING.id, L.MAPS.FILERS_WING.name, self.UNKNOWN_PORTAL_STATE_ENDED)
            stopTomeCheck()
        end
    end
end

local function onReticleTargetChanged(self)
    if (self:IsInsideArchive() and not self.FoundGw) then
        local unit = GetUnitName("reticleover")

        if (zo_strfind(unit, self.gw, 1, true)) then
            self.las:Share(L.EVENT_UNIT_OR_ITEM_DETECTED, self.DETECTED_UNIT, "Gw")
        end
    end
end

local function onCombatStateChanged(self, _, inCombat)
    if (not IsInstanceEndlessDungeon()) then return end

    self.InCombat = inCombat

    if (self.UnknownPortal) then
        if (self.UnknownPortal.id == L.MAPS.THEATRE_OF_WAR.id) then
            if (self.InCombat) then
                self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED, L.MAPS.THEATRE_OF_WAR.id, L.MAPS.THEATRE_OF_WAR.name, self.UNKNOWN_PORTAL_STATE_STARTED)
            end
        end
    end

    if (inCombat) then
        EVENT_MANAGER:RegisterForEvent(L.Name .. "_Reticle", EVENT_RETICLE_TARGET_CHANGED, function() onReticleTargetChanged(self) end)
    else
        EVENT_MANAGER:UnregisterForEvent(L.Name .. "_Reticle", EVENT_RETICLE_TARGET_CHANGED)
    end
end

local function onSingleSlotUpdate(self, _, _, previousSlotData)
    if (not IsInstanceEndlessDungeon()) then return end

    if (previousSlotData) then
        local icon = previousSlotData.iconFile

        for _, iconname in pairs(L.MYSTERY) do
            if (icon:find(iconname)) then
                self.MysteryVerse = true
                return
            end
        end

        self.MysteryVerse = false
    end
end

local function onBuffStackCountChanged(self, _, abilityId)
    if (not IsInstanceEndlessDungeon()) then return end

    zo_callLater(function()
        if (self.MysteryVerse) then
            self.las:Share(L.EVENT_MYSTERY_VERSE_USED, abilityId, GetAbilityName(abilityId, "player"))
            self.MysteryVerse = false
        end
    end, 1000)
end

local function onPowerUpdate(self, _, unitTag, _, powerType, powerValue)
    if (self:IsInsideArchive() and AreUnitsEqual(unitTag, "player") and powerType == POWERTYPE_ULTIMATE) then
        local unk, mapId = self:IsInUnknown()

        if (unk and mapId == self.MAPS.HAEFALS_BUTCHERY.id and powerValue > 0) then
            self.las:Share(self.EVENT_SWEETROLL_CONSUMED, self.player)
        end
    end
end

function lib:Initialize()
    self.auditor = GetString(LIBINFINITEARCHIVE_AUDITOR_NAME)
    self.gw = zo_strlower(GetString(LIBINFINITEARCHIVE_GW))
    --- @diagnostic disable-next-line undefined-field
    self.las = LibInfiniteArchiveSharing:New()
    self.player = zo_strformat(GetUnitName("player"))
    self.solo = ENDLESS_DUNGEON_GROUP_TYPE_SOLO
    self.tomeName = zo_strlower(GetString(LIBINFINITEARCHIVE_TOMESHELL))

    self.ArchiveQuestIndices = {}
    self.Bosses = {}
    self.FoundGw = false
    self.LastStun = 0
    self.SelectedBuff = 0
    self.ShowingBuffs = false
    self.TomesFound = 0
    self.TomesTotal = 0

    -- buff selector references
    local selector_short = "ZO_EndDunBuffSelector_%s"
    local selector = "ZO_EndlessDungeonBuffSelector_%s"
    local selectorObject = "ENDLESS_DUNGEON_BUFF_SELECTOR_%s"

    if (IsInGamepadPreferredMode()) then
        self.SELECTOR_SHORT = string.format(selector_short, "Gamepad")
        self.SELECTOR = string.format(selector, "Gamepad")
        self.SELECTOR_OBJECT = string.format(selectorObject, "GAMEPAD")
    else
        self.SELECTOR_SHORT = string.format(selector_short, "Keyboard")
        self.SELECTOR = string.format(selector, "Keyboard")
        self.SELECTOR_OBJECT = string.format(selectorObject, "KEYBOARD")
    end

    -- add constants
    for state, value in pairs(L.ENUMS) do
        self[state] = value
    end

    -- add event ids
    for id, eventInfo in pairs(L.EVENTS) do
        self[eventInfo.name] = id
    end

    -- add lookups
    self.ARCHIVE_INDEX = L.ARCHIVE_INDEX
    self.ARCHIVE_QUESTS = ZO_ShallowNumericallyIndexedTableCopy(L.ARCHIVE_QUESTS)
    self.AVATAR = ZO_ShallowTableCopy(L.AVATAR)
    self.CLASSES = ZO_ShallowTableCopy(L.CLASSES)
    self.MAPS = ZO_ShallowTableCopy(L.MAPS)
    self.MARAUDERS = ZO_ShallowNumericallyIndexedTableCopy(L.MARAUDERS)
    self.MYSTERY = ZO_ShallowTableCopy(L.MYSTERY)
    self.TOMESHELLS = ZO_ShallowTableCopy(L.TOMESHELLS)

    -- hooks
    SecurePostHook(_G[self.SELECTOR], "OnHiding", function() onHiding(self) end)
    SecurePostHook(_G[self.SELECTOR], "CommitChoice", function() onChoiceCommitted(self) end)
    SecurePostHook(_G[self.SELECTOR], "OnShowing", function() self.ShowingBuffs = true end)
    SecurePostHook(COMPASS, "OnUpdate", function() onCompassUpdate(self) end)
    SecurePostHook(CENTER_SCREEN_ANNOUNCE, "AddMessageWithParams", function(...) onMessage(self, ...) end)
    SecurePostHook(_G[self.SELECTOR], "SelectBuff", function(_, buffControl) self.SelectedBuff = buffchoice(buffControl.bucketType) end)
    ZO_PreHook(BOSS_BAR, "AddBoss", function(...) onNewBoss(self, ...) end)

    -- events
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_PLAYER_ACTIVATED, function() onPlayerActivated(self) end)
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_QUEST_CONDITION_COUNTER_CHANGED, function(...) onQuestCounterChanged(self, ...) end)
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_PLAYER_STUNNED_STATE_CHANGED, function(...) onStunned(self, ...) end)
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED, function(...) onHotBarChange(self, ...) end)
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_PLAYER_COMBAT_STATE, function(...) onCombatStateChanged(self, ...) end)
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_POWER_UPDATE, function(...) onPowerUpdate(self, ...) end)

    -- callbacks
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", function(...) onSingleSlotUpdate(self, ...) end)
    ENDLESS_DUNGEON_MANAGER:RegisterCallback("BuffStackCountChanged", function(...) onBuffStackCountChanged(self, ...) end)
end

function lib:IsInsideArchive()
    return IsInstanceEndlessDungeon() and GetCurrentMapId() ~= L.ArchiveIndex
end

-- account for offline members and companions
-- return the effective group type to get unknown portal target paramaters correctly
function lib:GetEffectiveGroupType()
    if (IsInstanceEndlessDungeon()) then
        local groupType = GetEndlessDungeonGroupType()
        local groupSize = GetGroupSize()

        if (groupSize == 0 or groupType == self.Solo) then
            groupType = self.Solo
        else
            local size = 0

            for unit = 1, groupSize do
                if (IsUnitOnline(string.format("group%d", unit))) then
                    size = size + 1
                end
            end

            if (size == 1) then
                groupType = self.Solo
            end
        end

        return groupType
    end

    return nil
end

function lib:GetArchiveQuestIndices(rebuild)
    if (#self.ArchiveQuestIndices == 0 or rebuild) then
        ZO_ClearNumericallyIndexedTable(self.ArchiveQuestIndices)

        for index = 1, GetNumJournalQuests() do
            local name, _, _, _, _, complete = GetJournalQuestInfo(index)

            if (not complete and ZO_IsElementInNumericallyIndexedTable(L.ARCHIVE_QUESTS, name)) then
                table.insert(self.ArchiveQuestIndices, index)
            end
        end
    end

    return self.ArchiveQuestIndices
end

function lib:GetMaxTomes()
    local tomeGroupType = self:GetEffectiveGroupType()

    return tomeGroupType == ENDLESS_DUNGEON_GROUP_TYPE_SOLO and L.TOMESHELLS.SOLO or L.TOMESHELLS.DUO
end

function lib:IsAvatar(abilityId)
    for avatar, info in pairs(L.AVATAR) do
        if (ZO_IsElementInNumericallyIndexedTable(info.abilityIds, abilityId)) then
            return avatar
        end
    end

    return false
end

function lib:IsInUnknown()
    local id = GetCurrentMapId()

    for _, mid in pairs(L.MAPS) do
        if (mid.id == id) then
            return true, mid.id, mid.name
        end
    end

    return false
end

function lib:IsAuditorActive()
    for pet = 1, MAX_PET_UNIT_TAGS do
        local name = zo_strformat(GetUnitName(string.format("playerpet%s", tostring(pet))))

        if (name and name ~= "" and name == self.auditor) then
            return true
        end
    end

    return false
end

function lib:RegisterForEvent(event, callback)
    assert(L.EVENTS[event], "Invalid event " .. (event or "nil"))
    assert(callback and type(callback) == "function", "Callback function is mandatory")
    self.las:RegisterCallback(L.EVENTS[event].name, callback, event)
end

function lib:UnregisterForEvent(event, callback)
    assert(L.EVENTS[event], "Invalid event")
    assert(callback and type(callback) == "function", "Callback function is mandatory")
    self.las:UnregisterCallback(L.EVENTS[event].name, callback, event)
end

LibInfiniteArchive = lib
