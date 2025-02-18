# LibInfiniteArchive
This library contains utility functions and custom events shared between group members whilst inside the Infinite Archive

## Usage

```lua
local lia = LibInfiniteArchive

lia.RegisterForEvent("myAddonName", lia.EVENT_MARAUDER_DETECTED, function(...) myCallbackFunction(...) end)

local avatarVerse = lia.IsAvatar(202134)
```
## Events

- `EVENT_UNKNOWN_PORTAL_STATE_CHANGED`
    - **Description:**
        - The player has entered/left/started/finished a portal to the unknown.
    - **Arguments:**
        - `eventid` - number
        - `mapId` - number
        - `mapName` - string
        - `state` - [UNKNOWN_PORTAL_STATE](#unknownportalstate)

- `EVENT_MYSTERY_VERSE_USED`
    - **Description:**
        - A player has used a mystery verse.
    - **Arguments:**
        - `eventId` - number
        - `abilityId` - number
        - `name` - string

- `EVENT_BUFF_SELECTED`
    - **Description:**
        - A verse/vision has been selected.
    - **Arguments:**
        - `eventId` - number
        - `abilityId` - number
        - `name` - string
        - `unitName` - string

- `EVENT_UNIT_OR_ITEM_DETECTED`
    - **Description:**
        - A quest marker or unit type (currenly only [Gw the Pilferer](https://en.uesp.net/wiki/Online:Gw_the_Pilferer)) has been detected
    - **Arguments:**
        - `eventId` - number
        - `type` - [DETECTED](#detected)
        - `extraInfo` - string|nil

- `EVENT_MARAUDER_SPAWNED`
    - **Description:**
        - A Marauder has spawned.
    - **Arguments:**
        - `eventId` - number
        - `name` - string

- `EVENT_TOMESHELL_DESTROYED`
    -   **Description:**
        - A tomeshell has been destroyed in the Filer's Wing
    - **Arguments:**
        - `eventId` - number
        - `destroyed` - number
        - `remaining` - number
        - `unitName` - string

## Enums

## UNKNOWN_PORTAL_STATE
```
UNKNOWN_PORTAL_STATE_UNKNOWN
UNKNOWN_PORTAL_STATE_EXITED
UNKNOWN_PORTAL_STATE_ENTERED
UNKNOWN_PORTAL_STATE_STARTED
UNKNOWN_PORTAL_STATE_FAILED
UNKNOWN_PORTAL_STATE_SUCCEEDED
UNKNOWN_PORTAL_STATE_ENDED
```

## DETECTED
```
DETECTED_ITEM
DETECTED_UNIT
```

## Functions

### `IsAvatar(abilityId)`

Determine if the supplied ability ID is an avatar verse.

- **Parameters:**
    - `abilityId` (number): The ability ID of a verse or vision.
- **Returns:**
    - `boolean`: `true` if the ability ID is an avatar verse.

### `IsInsideArchive()`

Determine if the player is inside the infinite archive, but not in the index/lobby area.

- **Returns:**
    - `boolean`: `true` if the player is inside an infinite archive stage.

### `GetActualGroupType()`

Get the current group size, accounting for offline players.

- **Returns:**
    - `integer|nil`: Actual/active group size.

### `GetArchiveQuestIndices(rebuild)`

Get the quest journal indices of any infinite archive quests that require you to collect items.

- **Parameters:**
    - `rebuild` (boolean): Force a rebuild of the quest indices data.
- **Returns:**
    - `table`: A table of quest journal indices.

### `IsInUnknown()`

Determine if the player is inside a portal to the unknown.

- **Returns:**
    - `boolean`: `true` if the player is inside a portal to the unknown.
    - `number|nil`: The map ID of the current portal to the unknown area.
    - `string|nil`: The name of the current portal to the unknown area.

### `IsAuditorActive()`

Determine if the Loyal Auditor is currently active.

- **Returns:**
    - `boolean`: `true` if the Loyal Auditor is active.

