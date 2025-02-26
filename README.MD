# LibInfiniteArchive
LibInfiniteArchive is intended for addon authors **only** - it is not a standalone addon.

This library contains utility functions and custom events shared between group members whilst inside the Infinite Archive from update 45 and onwards.

## Usage

```lua
local lia = LibInfiniteArchive

lia.RegisterForEvent("myAddonName", lia.EVENT_MARAUDER_DETECTED, function(...) myCallbackFunction(...) end)

local avatarVerse = lia.IsAvatar(202134)
```
## Events

- `EVENT_BUFF_SELECTED`
    - **Description:**
        - A verse/vision has been selected.
    - **Arguments:**
        - `eventId` - number
        - `abilityId` - number
        - `name` - string
        - `unitName` - string

- `EVENT_MARAUDER_SPAWNED`
    - **Description:**
        - A Marauder has spawned.
    - **Arguments:**
        - `eventId` - number
        - `name` - string

- `EVENT_MYSTERY_VERSE_USED`
    - **Description:**
        - A player has used a mystery verse.
    - **Arguments:**
        - `eventId` - number
        - `abilityId` - number
        - `name` - string

- `EVENT_SWEETROLL_CONSUMED`
    - **Description:**
        - A player has consumed a sweetroll in Haefal's Butchery
    - **Arguments:**
        - `eventId` - number
        - `unitName` - string

- `EVENT_TOMESHELL_DESTROYED`
    - **Description:**
        - A tomeshell has been destroyed in the Filer's Wing
    - **Arguments:**
        - `eventId` - number
        - `destroyed` - number
        - `remaining` - number
        - `unitName` - string

- `EVENT_ITEM_DETECTED`
    - **Description:**
        - A quest marker has been detected
    - **Arguments:**
        - `eventId` - number
        - `itemInfo` - string

- `EVENT_UNKNOWN_PORTAL_STATE_CHANGED`
    - **Description:**
        - The player has entered/left/started/finished a portal to the unknown.
    - **Arguments:**
        - `eventid` - number
        - `mapId` - number
        - `mapName` - string
        - `state` - [UNKNOWN_PORTAL_STATE](#unknown_portal_state)

## Enums

## UNKNOWN_PORTAL_STATE
```
UNKNOWN_PORTAL_STATE_ENDED
UNKNOWN_PORTAL_STATE_ENTERED
UNKNOWN_PORTAL_STATE_EXITED
UNKNOWN_PORTAL_STATE_FAILED
UNKNOWN_PORTAL_STATE_STARTED
UNKNOWN_PORTAL_STATE_SUCCEEDED
UNKNOWN_PORTAL_STATE_UNKNOWN
```

## Functions

### `GetArchiveQuestIndices(rebuild)`

Get the quest journal indices of any infinite archive quests that require you to collect items.

- **Parameters:**
    - `rebuild` (boolean): Force a rebuild of the quest indices data.
- **Returns:**
    - `table`: A table of quest journal indices.

### `GetEffectiveGroupType()`

Get the effective group size, accounting for offline players and companions. Allows for correct determination of unknown portal targets.

- **Returns:**
    - `integer|nil`: Effective group size.

### `IsAuditorActive()`

Determine if the Loyal Auditor is currently active.

- **Returns:**
    - `boolean`: `true` if the Loyal Auditor is active.

### `IsAvatar(abilityId)`

Determine if the supplied ability id is an avatar verse.

- **Parameters:**
    - `abilityId` (number): The ability id of a verse or vision.
- **Returns:**
    - `boolean`: `true` if the ability id is an avatar verse.

### `IsInsideArchive()`

Determine if the player is inside the infinite archive, but not in the index/lobby area.

- **Returns:**
    - `boolean`: `true` if the player is inside an infinite archive stage.


### `IsInUnknown()`

Determine if the player is inside a portal to the unknown.

- **Returns:**
    - `boolean`: `true` if the player is inside a portal to the unknown.
    - `number|nil`: The map id of the current portal to the unknown area.
    - `string|nil`: The name of the current portal to the unknown area.
