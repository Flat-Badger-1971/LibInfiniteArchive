local lib = ZO_InitializingObject():Subclass()
local L = LibInfiniteArchiveConstants

local function onHiding()
    zo_callLater(function() LibInifiniteArchive.showingBuffs = false end, 1500)
end

local function onChoiceCommitted(self)
    if (self.SelectedBuff) then
        local name = GetAbilityName(self.SelectedBuff, "player")

        self.las:Share(L.EVENT_BUFF_SELECTED, self.SelectedBuff, name)
    end
end

local function onCompassUpdate(self)
    if (self:IsInsideArchive() and self.InCombat) then
        if (self.FoundQuestItem == false) then
            local numPins = COMPASS.container:GetNumCenterOveredPins()

            if (numPins > 0) then
                for pin = 1, numPins do
                    local pinType = COMPASS.container:GetCenterOveredPinType(pin)

                    if (pinType == MAP_PIN_TYPE_QUEST_INTERACT) then
                        self.FoundQuestItem = true
                        self.las:Share(L.EVENT_UNIT_OR_ITEM_DETECTED, L.DETECTED_ITEM, "QuestItem")
                    end
                end
            end
        end
    end
end

local function onPlayerActivated(self)
    local mapId = GetCurrentMapId()
    local unknownportal

    if (self.LastMapId ~= mapId) then
        self.LastMapId = mapId

        if (mapId == L.MAPS.FILERS_WING.id) then
            unknownportal = L.MAPS.FILERS_WING
        elseif (mapId == L.MAPS.ECHOING_DEN.id) then
            unknownportal = L.MAPS.ECHOING_DEN
        elseif (mapId == L.MAPS.THEATRE_OF_WAR.id) then
            unknownportal = L.MAPS.THEATRE_OF_WAR
        elseif (mapId == L.MAPS.DESTOZUNOS_LIBRARY.id) then
            unknownportal = L.MAPS.DESTOZUNOS_LIBRARY
        elseif (mapId == L.MAPS.HAEFELS_BUTCHERY.id) then
            unknownportal = L.MAPS.HAEFELS_BUTCHERY
        elseif (mapId == L.MAPS.TREACHEROUS_CROSSING.id) then
            unknownportal = L.MAPS.TREACHEROUS_CROSSING
        end

        if (unknownportal) then
            self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                { id = mapId, name = unknownportal.name, state = L.UNKNOWN_PORTAL_STATE_ENTERED })
        end
    end

    self:GetActualGroupType()
end

local function checkMessage(self, messageParams)
    if (not self.DenStarted) then
        onPlayerActivated(self)
    end

    -- Herd the Ghost Lights
    if (self.IsInEchoingDen) then
        local message = zo_strlower(zo_strformat(messageParams:GetMainText()))
        local secondaryMessage = zo_strlower(zo_strformat(messageParams:GetSecondaryText() or ""))
        local start = zo_strlower(zo_strformat(_G[L.lia .. "HERD"]))
        local fail = zo_strlower(zo_strformat(_G[L.lia .. "HERD_FAIL"]))
        local success = zo_strlower(zo_strformat(_G[L.lia .. "HERD_SUCCESS"]))

        if (zo_strfind(message, start, 1, true)) then
            self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                { id = L.MAPS.ECHOING_DEN.id, name = L.MAPS.ECHOING_DEN.name, state = L.UNKNOWN_PORTAL_STATE_STARTED })
        elseif (zo_strfind(message, fail, 1, true)) or (zo_strfind(secondaryMessage, fail, 1, true)) then
            self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                { id = L.MAPS.ECHOING_DEN.id, name = L.MAPS.ECHOING_DEN.name, state = L.UNKNOWN_PORTAL_STATE_FAILED })
            self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                { id = L.MAPS.ECHOING_DEN.id, name = L.MAPS.ECHOING_DEN.name, state = L.UNKNOWN_PORTAL_STATE_ENDED })
        elseif (zo_strfind(message, success, 1, true)) or zo_strfind(secondaryMessage, success, 1, true) then
            self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                {
                    id = L.MAPS.ECHOING_DEN.id,
                    name = L.MAPS.ECHOING_DEN.name,
                    state = L.UNKNOWN_PORTAL_STATE_SUCCEEDED
                })
            self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                { id = L.MAPS.ECHOING_DEN.id, name = L.MAPS.ECHOING_DEN.name, state = L.UNKNOWN_PORTAL_STATE_ENDED })
        end
    end
end

local function onMessage(self, _, messageParams)
    if ((not messageParams) or (not IsInstanceEndlessDungeon())) then
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
    if (not IsInstanceEndlessDungeon() or ((unitTag or "") == "")) then
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
    if (stunned and not IsUnitInCombat("player")) then
        local now = GetTimeStamp()

        if ((now - (self.LastStun or 0)) > 2) then
            zo_callLater(
                function()
                    if (not LibInifiniteArchive.ShowingBuffs) then
                        resetValues(self)
                    end
                end,
                1000
            )

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
            self.TomesTotal = self.TomesTotal + 1

            local tomesLeft = self.MaxTomes - self.TomesTotal

            tomesLeft = (tomesLeft < 0) and 0 or tomesLeft

            self.las.Share(L.EVENT_TOMESHELL_DESTROYED, self.TomesFound, tomesLeft)
        end
    end
end

local function startTomeCheck(self)
    self.MaxTomes = self:GetMaxTomes()
    self.TomesFound = 0
    self.TomesTotal = 0

    EVENT_MANAGER:RegisterForEvent(L.Name .. "_Tome", EVENT_COMBAT_EVENT, function(...) tomeCheck(self, ...) end)
end

local function stopTomeCheck()
    EVENT_MANAGER:UnregisterForEvent(L.Name .. "_Tome", _G.EVENT_COMBAT_EVENT)
end

local function onHotBarChange(self, _, changed, shouldUpdate, category)
    if (GetCurrentMapId() == L.MAPS.FILERS_WING.id) then
        if ((category == HOTBAR_CATEGORY_TEMPORARY) and shouldUpdate and changed) then
            self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                { id = L.MAPS.FILERS_WING.id, name = L.MAPS.FILERS_WING.name, state = L.UNKNOWN_PORTAL_STATE_STARTED })
            startTomeCheck(self)
        end

        if ((category == HOTBAR_CATEGORY_PRIMARY) and changed and not shouldUpdate) then
            self.las:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                { id = L.MAPS.FILERS_WING.id, name = L.MAPS.FILERS_WING.name, state = L.UNKNOWN_PORTAL_STATE_ENDED })
            stopTomeCheck()
        end
    end
end

local function onReticleTargetChanged(self)
    if (self:IsInsideArchive()) then
        if (not self.FoundGw) then
            local unit = GetUnitName("reticleover")

            if (zo_strfind(unit, self.gw, 1, true)) then
                self.las:Share(L.EVENT_UNIT_OR_ITEM_DETECTED, L.DETECTED_UNIT, "Gw")
            end
        end
    end
end

local function onCombatStateChanged(self, _, inCombat)
    self.InCombat = inCombat

    if (inCombat) then
        EVENT_MANAGER:RegisterForEvent(L.Name .. "_Reticle", EVENT_RETICLE_TARGET_CHANGED,
            function() onReticleTargetChanged(self) end)
    else
        EVENT_MANAGER:UnregisterForEvent(L.Name .. "_Reticle", EVENT_RETICLE_TARGET_CHANGED)
    end
end

local function onSingleSlotUpdate(self, _, _, previousSlotData)
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
    zo_callLater(
        function()
            if (self.MysteryVerse) then
                self.las:Share(L.EVENT_MYSTERY_VERSE_USED, { id = abilityId, name = GetAbilityName(abilityId, "player") })
                self.MysteryVerse = false
            end
        end,
        1000
    )
end

function lib:Initialize()
    self.auditor = GetString(LIBINFINITEARCHIVE_AUDITOR_NAME)
    self.gw = zo_strlower(GetString(LIBINFINITEARCHIVE_GW))
    self.las = LibInfiniteArchiveSharing
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

    -- hooks
    SecurePostHook(_G[self.SELECTOR], "OnHiding", onHiding)
    SecurePostHook(_G[self.SELECTOR], "CommitChoice", function() onChoiceCommitted(self) end)
    SecurePostHook(_G[self.SELECTOR], "OnShowing", function() self.ShowingBuffs = true end)
    SecurePostHook(COMPASS, "OnUpdate", function() onCompassUpdate(self) end)
    SecurePostHook(CENTER_SCREEN_ANNOUNCE, "AddMessageWithParams", function(...) onMessage(self, ...) end)
    SecurePostHook(_G[self.SELECTOR], "SelectBuff",
        function(_, buffControl)
            self.SelectedBuff = GetEndlessDungeonBuffSelectorBucketTypeChoice(buffControl.bucketType)
        end)
    ZO_PreHook(BOSS_BAR, "AddBoss", function(...) onNewBoss(self, ...) end)

    -- events
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_PLAYER_ACTIVATED, function() onPlayerActivated(self) end)
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_QUEST_CONDITION_COUNTER_CHANGED,
        function(...) onQuestCounterChanged(self, ...) end)
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_PLAYER_STUNNED_STATE_CHANGED, function(...) onStunned(self, ...) end)
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED,
        function(...) onHotBarChange(self, ...) end)
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_PLAYER_COMBAT_STATE, function(...) onCombatStateChanged(self, ...) end)

    -- callbacks
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", function(...) onSingleSlotUpdate(self, ...) end)
    ENDLESS_DUNGEON_MANAGER:RegisterCallback("BuffStackCountChanged",
        function(...) onBuffStackCountChanged(self, ...) end)
end

--- determine if the player inside the infinite archive, but not in the index/lobby area
--- @return boolean # true if the player is inside an infinite archive stage
function lib:IsInsideArchive()
    return IsInstanceEndlessDungeon() and (GetCurrentMapId() ~= L.ArchiveIndex)
end

--- get the current group size, accounting for offline players
--- @diagnostic disable-next-line: undefined-doc-name
--- @return EndlessDungeonGroupType|nil # actual/active group size
function lib:GetActualGroupType()
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

            if (self.CurrentGroupType ~= groupType) then
                self.CurrentGroupType = groupType
            end
        end

        return groupType
    end

    return nil
end

--- get the quest journal indices of any infinite archive quests that require you to collect items
--- @param rebuild boolean force a rebuild of the quest indices data
--- @return table # a table of quest journal indices
function lib:GetArchiveQuestIndices(rebuild)
    if ((#self.ArchiveQuestIndices == 0) or rebuild) then
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

--- Get the maximum number of Tomeshells required in the Filer's Wing accounting for group size
---@return number
function lib:GetMaxTomes()
    -- for the purposes of this check, players with companions count as solo
    local tomeGroupType = self:GetActualGroupType()

    if (tomeGroupType == ENDLESS_DUNGEON_GROUP_TYPE_SOLO) then
        return L.TOMESHELLS.SOLO
    else
        return L.TOMESHELLS.DUO
    end
end

--- determine if the supplied ability id is an avatar verse
--- @param abilityId number the ability id of a verse or vision
--- @return boolean # true if the ability id is an avatar verse
function lib:IsAvatar(abilityId)
    for avatar, info in pairs(L.AVATAR) do
        if (ZO_IsElementInNumericallyIndexedTable(info.abilityIds, abilityId)) then
            return avatar
        end
    end

    return false
end

--- determine if the player is inside a portal to the unknown
--- @return boolean # true if the player is inside a portal to the unknown
--- @return number|nil # the map id of the current portal to the unknown area
--- @return string|nil # the name of the current portal to the unknown area
function lib:IsInUnknown()
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
function lib:IsAuditorActive()
    for pet = 1, MAX_PET_UNIT_TAGS do
        local name = zo_strformat(GetUnitName(string.format("playerpet%s", tostring(pet))))

        if (name and (name ~= "")) then
            if (name == self.auditor) then
                return true
            end
        end
    end

    return false
end

function lib:RegisterForEvent(event, callback)
    assert(L.EVENTS[event], "Invalid event")
    assert(callback ~= nil and type(callback) == "function", "Callback function is mandatory")

    lib.las:RegisterCallback(L.EVENTS[event].name, callback)
end

function lib:UnregisterForEvent(event, callback)
    assert(L.EVENTS[event], "Invalid event")
    assert(callback ~= nil and type(callback) == "function", "Callback function is mandatory")

    lib.las:UnregisterCallback(L.EVENTS[event].name, callback)
end

LibInfiniteArchive = lib:New()
