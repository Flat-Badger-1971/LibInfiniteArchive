LibInfiniteArchive = {
    Bosses = {},
    InCombat = false,
    Name = "LibInfiniteArchive",
    LGB = LibGroupBroadcast
}

local L = LibInfiniteArchive
local selector_short = "ZO_EndDunBuffSelector_%s"
local selector = "ZO_EndlessDungeonBuffSelector_%s"
local selectorObject = "ENDLESS_DUNGEON_BUFF_SELECTOR_%s"

local function setupHooks()
    -- hooks
    SecurePostHook(_G[L.SELECTOR], "OnHiding", L.OnHiding)
    SecurePostHook(_G[L.SELECTOR], "CommitChoice", L.OnChoiceCommitted)
    SecurePostHook(_G[L.SELECTOR], "OnShowing", function() L.ShowingBuffs = true end)
    SecurePostHook(COMPASS, "OnUpdate", L.OnCompassUpdate)
    SecurePostHook(CENTER_SCREEN_ANNOUNCE, "AddMessageWithParams", L.OnMessage)
    SecurePostHook(_G[L.SELECTOR], "SelectBuff",
        function(_, buffControl) L.SelectedBuff = GetEndlessDungeonBuffSelectorBucketTypeChoice(buffControl.bucketType) end)
    ZO_PreHook(BOSS_BAR, "AddBoss", L.OnNewBoss)
end

local function setupEvents()
    -- events
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_PLAYER_ACTIVATED, L.OnPlayerActivated)
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_QUEST_CONDITION_COUNTER_CHANGED, L.OnQuestCounterChanged)
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_PLAYER_STUNNED_STATE_CHANGED, L.OnStunned)
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED, L.OnHotBarChange)
    EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_PLAYER_COMBAT_STATE, L.OnCombatStateChanged)

    -- callbacks
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", L.OnSingleSlotUpdate)
    ENDLESS_DUNGEON_MANAGER:RegisterCallback("BuffStackCountChanged", L.OnBuffStackCountChanged)
end

local function initialise(_, addonName)
    if (addonName ~= L.Name) then return end

    EVENT_MANAGER:UnregisterForEvent(L.Name, EVENT_ADD_ON_LOADED)

    if (IsInGamepadPreferredMode()) then
        L.SELECTOR_SHORT = string.format(selector_short, "Gamepad")
        L.SELECTOR = string.format(selector, "Gamepad")
        L.SELECTOR_OBJECT = string.format(selectorObject, "GAMEPAD")
    else
        L.SELECTOR_SHORT = string.format(selector_short, "Keyboard")
        L.SELECTOR = string.format(selector, "Keyboard")
        L.SELECTOR_OBJECT = string.format(selectorObject, "KEYBOARD")
    end

    setupHooks()
    setupEvents()
end

EVENT_MANAGER:RegisterForEvent(L.Name, EVENT_ADD_ON_LOADED, initialise)
