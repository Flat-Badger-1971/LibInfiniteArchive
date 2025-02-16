local L = LibInfiniteArchive
local lgb = L.s:New(L.Name)
local Bosses = {}

function L.OnCombatStateChanged(_, inCombat)
    L.InCombat = inCombat
end

local lastMapId

--- SHARE: The player has entered a portal to the unknown
function L.OnPlayerActivated()
    local mapId = GetCurrentMapId()
    local unknownportal

    if (lastMapId ~= mapId) then
        lastMapId = mapId

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
            lgb:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                { id = mapId, name = unknownportal.name, state = L.UNKNOWN_PORTAL_STATE_ENTERED })
        end
    end

    L.GetActualGroupType()
end

function L.OnQuestCounterChanged(_, journalIndex)
    if (IsInstanceEndlessDungeon()) then
        local indices = L.GetArchiveQuestIndices(true)

        if (ZO_IsElementInNumericallyIndexedTable(indices, journalIndex)) then
            L.FoundQuestItem = false
        end
    end
end

local function resetValues()
    ZO_ClearNumericallyIndexedTable(L.Bosses)

    L.FoundQuestItem = false
end

-- minimise false zone change detections
local lastStun = 0

function L.OnStunned(_, stunned)
    if (stunned and not IsUnitInCombat("player")) then
        local now = GetTimeStamp()

        if ((now - lastStun) > 2) then
            zo_callLater(
                function()
                    if (not L.ShowingBuffs) then
                        resetValues()
                    end
                end,
                1000
            )

            lastStun = now
        end
    end
end

local function getMaxTomes()
    -- for the purposes of this check, players with companions count as solo
    local tomeGroupType = L.GetActualGroupType()

    if (tomeGroupType == ENDLESS_DUNGEON_GROUP_TYPE_SOLO) then
        return L.TOMESHELLS.SOLO
    else
        return L.TOMESHELLS.DUO
    end
end

local tomeName = zo_strlower(GetString(LIBINFINITEARCHIVE_TOMESHELL))
local tomesFound = 0
local tomesTotal = 0

local function tomeCheck(...)
    local result = select(2, ...)
    local sourceName, _, targetName = select(7, ...)

    if (result == ACTION_RESULT_DIED or result == ACTION_RESULT_DIED_XP) then
        targetName = zo_strlower(zo_strformat(targetName))
        sourceName = zo_strlower(zo_strformat(sourceName))

        if (zo_strfind(targetName, tomeName, 1, true) or zo_strfind(sourceName, tomeName, 1, true)) then
            tomesFound = tomesFound + 1
            tomesTotal = tomesTotal + 1

            local tomesLeft = L.MaxTomes - tomesTotal

            tomesLeft = (tomesLeft < 0) and 0 or tomesLeft

            L.Share(L.EVENT_TOMESHELL_DESTROYED, tomesFound, tomesLeft)
        end
    end
end

local function startTomeCheck()
    L.MaxTomes = getMaxTomes()

    EVENT_MANAGER:RegisterForEvent(L.Name .. "_Tome", EVENT_COMBAT_EVENT, tomeCheck)
end

local function stopTomeCheck()
    EVENT_MANAGER:UnregisterForEvent(L.Name .. "_Tome", _G.EVENT_COMBAT_EVENT)
end

--- SHARE: The player has triggered the start/end of the Filer's wing challenge
function L.OnHotBarChange(_, changed, shouldUpdate, category)
    if (GetCurrentMapId() == L.MAPS.FILERS_WING.id) then
        if ((category == HOTBAR_CATEGORY_TEMPORARY) and shouldUpdate and changed) then
            lgb:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                { id = L.MAPS.FILERS_WING.id, name = L.MAPS.FILERS_WING.name, state = L.UNKNOWN_PORTAL_STATE_STARTED })
            startTomeCheck()
        end

        if ((category == HOTBAR_CATEGORY_PRIMARY) and changed and not shouldUpdate) then
            lgb:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                { id = L.MAPS.FILERS_WING.id, name = L.MAPS.FILERS_WING.name, state = L.UNKNOWN_PORTAL_STATE_ENDED })
            stopTomeCheck()
        end
    end
end

-- callbacks
function L.OnSingleSlotUpdate(_, _, previousSlotData)
    if (previousSlotData) then
        local icon = previousSlotData.iconFile

        for _, iconname in pairs(L.MYSTERY) do
            if (icon:find(iconname)) then
                L.MysteryVerse = true
                return
            end
        end

        L.MysteryVerse = false
    end
end

--- SHARE: A player has used a mystery verse
function L.OnBuffStackCountChanged(_, abilityId)
    zo_callLater(
        function()
            if (L.MysteryVerse) then
                lgb:Share(L.EVENT_MYSTERY_VERSE_USED, { id = abilityId, name = GetAbilityName(abilityId, "player") })
                L.MysteryVerse = false
            end
        end,
        1000
    )
end

-- hooks

--- SHARE: The choice of verse/vision made by the current player
function L.OnChoiceCommitted()
    if (L.SelectedBuff) then
        local name = GetAbilityName(L.SelectedBuff, "player")

        lgb:Share(L.EVENT_BUFF_SELECTED, L.SelectedBuff, name)
    end
end

--- SHARE: A quest marker has seen crossing the centre point of the in-game compass
function L.OnCompassUpdate()
    if (L.IsInsideArchive() and L.InCombat) then
        if (L.FoundQuestItem == false) then
            local numPins = COMPASS.container:GetNumCenterOveredPins()

            if (numPins > 0) then
                for pin = 1, numPins do
                    local pinType = COMPASS.container:GetCenterOveredPinType(pin)

                    if (pinType == MAP_PIN_TYPE_QUEST_INTERACT) then
                        L.FoundQuestItem = true
                        lgb:Share(L.EVENT_UNIT_OR_ITEM_DETECTED, L.DETECTED_ITEM, "QuestItem")
                    end
                end
            end
        end
    end
end

--- SHARE: The player has triggered the start/end of the Echoing Den challenge
local function checkMessage(messageParams)
    if (not L.DenStarted) then
        L.OnPlayerActivated()
    end

    -- Herd the Ghost Lights
    if (L.IsInEchoingDen) then
        local message = zo_strlower(zo_strformat(messageParams:GetMainText()))
        local secondaryMessage = zo_strlower(zo_strformat(messageParams:GetSecondaryText() or ""))
        local start = zo_strlower(zo_strformat(_G[L.lia .. "HERD"]))
        local fail = zo_strlower(zo_strformat(_G[L.lia .. "HERD_FAIL"]))
        local success = zo_strlower(zo_strformat(_G[L.lia .. "HERD_SUCCESS"]))

        if (zo_strfind(message, start, 1, true)) then
            lgb:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                { id = L.MAPS.ECHOING_DEN.id, name = L.MAPS.ECHOING_DEN.name, state = L.UNKNOWN_PORTAL_STATE_STARTED })
        elseif (zo_strfind(message, fail, 1, true)) or (zo_strfind(secondaryMessage, fail, 1, true)) then
            lgb:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                { id = L.MAPS.ECHOING_DEN.id, name = L.MAPS.ECHOING_DEN.name, state = L.UNKNOWN_PORTAL_STATE_FAILED })
            lgb:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                { id = L.MAPS.ECHOING_DEN.id, name = L.MAPS.ECHOING_DEN.name, state = L.UNKNOWN_PORTAL_STATE_ENDED })
        elseif (zo_strfind(message, success, 1, true)) or zo_strfind(secondaryMessage, success, 1, true) then
            lgb:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                { id = L.MAPS.ECHOING_DEN.id, name = L.MAPS.ECHOING_DEN.name, state = L.UNKNOWN_PORTAL_STATE_SUCCEEDED })
            lgb:Share(L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED,
                { id = L.MAPS.ECHOING_DEN.id, name = L.MAPS.ECHOING_DEN.name, state = L.UNKNOWN_PORTAL_STATE_ENDED })
        end
    end
end

function L.OnMessage(_, messageParams)
    if ((not messageParams) or (not IsInstanceEndlessDungeon())) then
        return
    end

    checkMessage(messageParams)
end

local function bossHandled(unitTag, name)
    if (Bosses[unitTag] == name) then
        return true
    end

    Bosses[unitTag] = name

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

--- SHARE: A Marauder has spawned
function L.OnNewBoss(_, unitTag)
    if (not IsInstanceEndlessDungeon() or ((unitTag or "") == "")) then
        return
    end

    local bossName = GetUnitName(unitTag)

    if (bossHandled(unitTag, bossName)) then
        return
    end

    if (isMarauder(bossName)) then
        lgb:Share(L.EVENT_MARAUDER_SPAWNED, bossName)
    end
end

function L.OnHiding()
    zo_callLater(
        function()
            L.ShowingBuffs = false
        end,
        1500
    )
end
