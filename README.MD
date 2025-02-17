### work in progress


## Events

### `EVENT_UNKNOWN_PORTAL_STATE_CHANGED`

The player has entered/left/started/finished a portal to the unknown.

### `EVENT_MYSTERY_VERSE_USED`

A player has used a mystery verse.

### `EVENT_BUFF_SELECTED`

The choice of verse/vision made by the current player.

### `EVENT_UNIT_OR_ITEM_DETECTED`

A quest marker has been seen crossing the center point of the in-game compass.

### `EVENT_MARAUDER_SPAWNED`

A Marauder has spawned.

### `EVENT_MARKER_STATE_CHANGED`

todo:

### `EVENT_TOMESHELL_DESTROYED`

todo:

This document provides an overview of the helper functions available in the `helpers.lua` file of the `LibInfiniteArchive` addon for Elder Scrolls Online.

## Enums

## UNKNOWN_PORTAL_STATE
### `UNKNOWN_PORTAL_STATE_UNKNOWN`
### `UNKNOWN_PORTAL_STATE_EXITED`
### `UNKNOWN_PORTAL_STATE_ENTERED`
### `UNKNOWN_PORTAL_STATE_STARTED`
### `UNKNOWN_PORTAL_STATE_FAILED`
### `UNKNOWN_PORTAL_STATE_SUCCEEDED`
### `UNKNOWN_PORTAL_STATE_ENDED`

## MARKER_STATE
### `MARKER_STATE_CLEARED`
### `MARKER_STATE_USED`

## DETECTED
### `DETECTED_ITEM`
### `DETECTED_UNIT`

## Functions

### `IsAvatar(abilityId)`

Determine if the supplied ability ID is an avatar verse/vision.

- **Parameters:**
    - `abilityId` (number): The ability ID of a verse or vision.
- **Returns:**
    - `boolean`: `true` if the ability ID is an avatar verse/vision.

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

