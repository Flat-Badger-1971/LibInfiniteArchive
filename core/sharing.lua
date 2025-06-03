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

local function tprint(tbl, indent)
    if not indent then indent = 0 end
    local toprint = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint .. k .. "= "
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\r\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\r\n"
        elseif (type(v) == "table") then
            toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent - 2) .. "}"
    return toprint
end

--- @protected
function slib:OnData(event, unitTag, data)
    if (AreUnitsEqual(unitTag, "player")) then return end

    self:d("received data from " .. unitTag)
    self:d(tprint(data))
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
    local edata = data
    local eventNum = event

    if (type(event) == "table") then
        edata = event
        eventNum = edata.event
    end

    local eventName = L.EVENTS[eventNum]

    unitTag = unitTag or "player"

    if (eventNum == L.EVENT_BUFF_SELECTED) then
        self:FireCallbacks(eventName, unitTag, edata.abilityId, edata.name, edata.unitName)
    elseif (eventNum == L.EVENT_MARAUDER_SPAWNED) then
        self:FireCallbacks(eventName, edata.name)
    elseif (eventNum == L.EVENT_MYSTERY_VERSE_USED) then
        self:FireCallbacks(eventName, unitTag, edata.abilityId, edata.name)
    elseif (eventNum == L.EVENT_SWEETROLL_CONSUMED) then
        self:FireCallbacks(eventName, edata.unitname)
    elseif (eventNum == L.EVENT_TOMESHELL_DESTROYED) then
        self:FireCallbacks(eventName, unitTag, edata.destroyed, edata.remaining)
    elseif (eventNum == L.EVENT_ITEM_DETECTED) then
        self:FireCallbacks(eventName, edata.itemInfo)
    elseif (eventNum == L.EVENT_UNKNOWN_PORTAL_STATE_CHANGED) then
        self:FireCallbacks(eventName, edata.mapId, edata.state, edata.mapName)
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
