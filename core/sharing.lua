-- *** FOR INTERNAL USE ONLY ***
local L = LibInfiniteArchiveConstants

--- @class LibInfiniteArchiveSharing:ZO_InitializingCallbackObject
local slib = ZO_InitializingCallbackObject:Subclass()

--- @protected
function slib:Initialize()
    local internal

    xpcall(function() error("internal use only") end,
        function(err)
            if (zo_strfind(err, "AddOns/LibInfiniteArchive/core/lib.lua", 1, false)) then
                internal = true
            end
        end)

    assert(internal, "This class is for internal use only")

    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_GROUP_UPDATE, function() self.grouped = IsUnitGrouped("player") end)

    self.grouped = IsUnitGrouped("player")

    if (L.LGB) then
        self.handler = L.LGB:RegisterHandler(L.Name)
        self.handler:SetDisplayName(L.Name)
    end

    self.protocols = {}
    self.events = {}

    self:RegisterProtocols()

    self.debug = (GetDisplayName() == "@Flat-Badger") and L.DEBUG
end

--- @protected
function slib:d(message)
    if (self.debug) then
        d("LIAs: " .. tostring(message))
    end
end

--- @protected
function slib:OnData(event, unitTag, data)
    if (AreUnitsEqual(unitTag, "player")) then return end

    self:d("received data from " .. unitTag)
    self:Fire(event, unitTag, data)
end

--- @protected
function slib:RegisterProtocols()
    if (not L.LGB) then return end

    local valueFields = {
        L.LGB.CreateNumericField("event", { minValue = 0, maxValue = 512, defaultValue = 0 }),
        L.LGB.CreateNumericField("abilityId", { minValue = 0, maxValue = 1048576, defaultValue = 0 }),
        L.LGB.CreateNumericField("destroyed", { minValue = 0, maxValue = 64, defaultValue = 0 }),
        L.LGB.CreateNumericField("remaining", { minValue = 0, maxValue = 64, defaultValue = 0 }),
        L.LGB.CreateNumericField("mapId", { minValue = 0, maxValue = 16384, defaultValue = 0 }),
        L.LGB.CreateNumericField("state", { minValue = 0, maxValue = 32, defaultValue = 0 }),
        L.LGB.CreateStringField("name", { maxLength = 128, defaultValue = "" }),
        L.LGB.CreateStringField("unitName", { maxLength = 128, defaultValue = "" }),
        L.LGB.CreateStringField("itemInfo", { maxLength = 128, defaultValue = "" }),
        L.LGB.CreateStringField("mapName", { maxLength = 255, defaultValue = "" })
    }

    self.eventProtocol = self.handler:DeclareProtocol(L.PROTOCOL_ID_EVENTS, L.Name)
    self.eventProtocol:AddField(L.LGB.CreateTableField("event", valueFields))
    self.eventProtocol:OnData(function(unitTag, data) self:OnData(data.event, unitTag, data) end)

    local finalised = self.eventProtocol:Finalize({
        isRelevantInCombat = true,
        replaceQueuedMessages = false
    })

    self:d("finalised:" .. (tostring(finalised) or "nil"))
    assert(finalised, "Protocol finalisation failed")
end

--- @protected
function slib:Fire(event, unitTag, data)
    local eventName = L.EVENTS[event]

    unitTag = unitTag or "player"

    if (event == L.EVENT_BUFF_SELECTED) then
        self:FireCallbacks(eventName, unitTag, data.abilityId, data.name, data.unitName)
    elseif (event == L.EVENT_MARAUDER_SPAWNED) then
        self:FireCallbacks(eventName, data.name)
    elseif (event == L.EVENT_MYSTERY_VERSE_USED) then
        self:FireCallbacks(eventName, unitTag, data.abilityId, data.name)
    elseif (event == L.EVENT_SWEETROLL_CONSUMED) then
        self:FireCallbacks(eventName, data.unitname)
    elseif (event == L.EVENT_TOMESHELL_DESTROYED) then
        self:FireCallbacks(eventName, unitTag, data.destroyed, data.remaining)
    elseif (event == L.EVENT_ITEM_DETECTED) then
        self:FireCallbacks(eventName, data.itemInfo)
    elseif (event == L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED) then
        self:FireCallbacks(eventName, data.mapId, data.mapName, data.state)
    end
end

--- @protected
function slib:SendProtocolMessage(event, data)
    local eventName = L.EVENTS[event]

    data.event = event

    self:d("Sending protocol message " .. eventName)

    if (self.grouped) then
        self:d("Sending to group")
        self.eventProtocol:Send({ event = data })
    end

    self:Fire(event, nil, data)
end

local function formatProtocolData(data)
    local protocolData = {
        abilityId = data.abilityId,
        destroyed = data.destroyed,
        event = 0,
        remaining = data.remaining,
        mapId = data.mapId,
        state = data.state,
        name = data.name,
        unitName = data.unitName,
        itemInfo = data.itemInfo,
        mapName = data.mapName
    }

    return protocolData
end

--- @protected
function slib:Share(event, data)
    self:d("Sharing event " .. L.EVENTS[event])
    self:SendProtocolMessage(event, formatProtocolData(data))
end

LibInfiniteArchiveSharing = slib
