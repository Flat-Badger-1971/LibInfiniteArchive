-- *** FOR INTERNAL USE ONLY ***
local L = LibInfiniteArchiveConstants

--- @class Sharing : ZO_InitializingCallbackObject
local slib = ZO_InitializingCallbackObject:Subclass()

function slib:Initialize()
    local internal

    xpcall(function() error("internal use only") end,
        function(err)
            if (zo_strfind(err, "AddOns/LibInfiniteArchive/core/lib.lua", 1, false)) then
                internal = true
            end
        end)

    assert(internal, "This class is for internal use only")

    EVENT_MANAGER:RegisterForEvent(L.NAME, EVENT_GROUP_UPDATE, function() self.grouped = IsUnitGrouped("player") end)

    self.grouped = IsUnitGrouped("player")

    if (L.LGB) then
        self.handler = L.LGB:RegisterHandler(L.Name)
        self.handler:SetDisplayName(L.Name)
    end

    self.protocols = {}
    self.events = {}

    self:RegisterEvents()
    self:RegisterProtocols()

    self.debug = (GetDisplayName() == "@Flat-Badger") and true
end

function slib:d(message)
    if (self.debug) then
        d(message)
    end
end

function slib:OnData(event, unitTag, ...)
    if (AreUnitsEqual(unitTag, "player")) then return end

    self:d("received data from " .. unitTag .. " " .. ...)
    self:FireCallbacks(event, unitTag, ...)
end

function slib:RegisterEvents()
    if (not L.LGB) then return end

    for event, data in pairs(L.EVENTS) do
        if (not data.fields) then
            self.events[event] = self.handler:DeclareCustomEvent(event, data.name)
        end
    end
end

function slib:RegisterProtocols()
    if (not L.LGB) then return end

    for event, data in pairs(L.EVENTS) do
        if (data.fields) then
            self.protocols[event] = self.handler:DeclareProtocol(event, data.name)

            for _, field in ipairs(data.fields) do
                local fieldName = field.name
                local fieldType = field.type

                if (fieldType == "string") then
                    self.protocols[event]:AddField(L.LGB.CreateStringField(fieldName))
                elseif (fieldType == "number") then
                    self.protocols[event]:AddField(L.LGB.CreateNumericField(fieldName, { minValue = 0, maxValue = 999999 }))
                end
            end

            self.protocols[event]:OnData(function(...) self:OnData(event, ...) end)

            local finalised = self.protocols[event]:Finalize({
                isRelevantInCombat = true,
                replaceQueuedMessages = false
            })

            self:d("finalised:" .. (tostring(finalised) or "nil"))
            assert(finalised, data.name .. " protocol finalisation failed")
        end
    end
end

function slib:FireEvent(event)
    self:d("Firing event " .. L.EVENTS[event].name)

    if (self.grouped) then
        self.events[event]()
    end

    self:FireCallbacks(L.EVENTS[event].name, "player")
end

function slib:SendProtocolMessage(event, ...)
    local eventInfo = L.EVENTS[event]

    self:d("Sending protocol message " .. eventInfo.name)
    self:d(...)

    if (self.grouped) then
        -- self.protocols[event]:Send(...)
    end

    self:FireCallbacks(L.EVENTS[event].name, "player", ...)
end

function slib:Share(event, ...)
    if (L.EVENTS[event].fields) then
        self:d("Sharing event " .. L.EVENTS[event].name)
        self:d(...)
        self:SendProtocolMessage(event, ...)
    else
        self:FireEvent(event)
    end
end

LibInfiniteArchiveSharing = slib
