-- *** FOR INTERNAL USE ONLY ***

local L = LibInfiniteArchive
L.s = ZO_InitializingCallbackObject:Subclass()

--- @class Sharing : ZO_InitializingCallbackObject
local s = L.s

function s:Initialize(name)
    assert(name == L.Name, "This class is only for internal use by LibInfiniteArchive")

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

function s:d(message)
    if (self.debug) then
        d(message)
    end
end

function s:OnData(event, unitTag, data)
    if (AreUnitsEqual(unitTag, "player")) then return end

    self:FireCallbacks(event, unitTag, data)
end

function s:RegisterEvents()
    if (not L.LGB) then return end
    
    for event, data in pairs(L.EVENTS) do
        if (not data.fields) then
            self.events[event] = self.handler:DeclareCustomEvent(event, data.name)
        end
    end
end

function s:RegisterProtocols()
    if (not L.LGB) then return end

    for event, data in pairs(L.EVENTS) do
        if (data.fields) then
            self.protocols[event] = self.handler:DeclareProtocol(event, data.name)

            for field in 1, #data.fields do
                local fieldName = field.name
                local fieldType = field.type

                if (fieldType == "string") then
                    self.protocols[event]:AddField(L.LGB.CreateStringField(fieldName))
                elseif (fieldType == "number") then
                    self.protocols[event]:AddField(L.LGB.CreateNumericField(fieldName,
                        { minValue = 0, maxValue = 999999 }))
                end
            end

            self.protocols[event]:OnData(function(...) self:OnData(event, ...) end)

            local finalised = self.protocols[event]:Finalize({
                isRelevantInCombat = true,
                replaceQueuedMessages = false,
            })

            self:d("finalised:" .. (tostring(finalised) or "nil"))
            assert(finalised, data.name .. " protocol finalisation failed")
        end
    end
end

function s:FireEvent(event)
    self:d("Firing event " .. L.EVENTS[event].name)

    if (self.grouped) then
        self.events[event]()
    end

    self:FireCallbacks(event)
end

function s:SendProtocolMessage(event, ...)
    local eventInfo = L.EVENTS[event]

    self:d("Sending protocol message " .. eventInfo.name)
    self:d(...)

    if (self.grouped) then
        self.protocols[event]:Send(...)
    end

    self:FireCallbacks(event, ...)
end

function s:Share(event, ...)
    self:d("Sharing event " .. L.EVENTS[event].name)

    if (L.EVENTS[event].fields) then
        if (event == L.EVENT_BUFF_SELECTED or event == L.EVENT_TOMESHELL_DESTROYED) then
            self:SendProtocolMessage(event, ..., zo_strformat(GetUnitName("player")))
        else
            self:SendProtocolMessage(event, ...)
        end
        self:SendProtocolMessage(event, ...)
    else
        self:FireEvent(event)
    end
end

function s:RegisterForEvent(event, callback)
    local eventName = L.EVENT_IDS[event]

    assert(type(callback) == "function", "Callback must be a function")
    assert(eventName, "Event not recognised")

    self:RegisterCallback(eventName, callback, event)
end

function s:UnregisterForEvent(event, callback)
    local eventName = L.EVENT_IDS[event]

    assert(type(callback) == "function", "Callback must be a function")
    assert(eventName, "Event not recognised")

    self:UnregisterCallback(eventName, callback, event)
end
