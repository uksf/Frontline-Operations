/*
 * Function: FLO_fnc_gtnBuildCommanderIntelPicture
 * Author: Frontline Operations Development Group
 * Description:
 *   Normalizes the maintained GTN world-state intel picture into simple marker
 *   records for the player-facing commander common operating picture.
 *
 * Arguments:
 *   0: GTN world state <HASHMAPOBJECT>
 *
 * Return Value:
 *   HASHMAP - Normalized commander picture
 */

params [["_worldState", nil]];

if (isNil "_worldState") exitWith {
    createHashMapFromArray [
        ["enemyGroups", []],
        ["enemyConcentrations", []],
        ["friendlyGroups", []],
        ["supportMarkers", []]
    ]
};

private _enemyGroupMarkers = [];
private _enemyConcentrationMarkers = [];

private _supportMarkers = [_worldState] call FLO_fnc_gtnBuildFriendlySupportMarkers;

createHashMapFromArray [
    ["enemyGroups", _enemyGroupMarkers],
    ["enemyConcentrations", _enemyConcentrationMarkers],
    ["friendlyGroups", [_worldState] call FLO_fnc_gtnBuildFriendlyCommanderGroupMarkers],
    ["supportMarkers", _supportMarkers]
]
