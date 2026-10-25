/*
 * Function: FLO_fnc_virtualizationClearUnsafeSavedLandRoute
 * Description:
 *   Last resort when a saved LAND route cannot be made terrain-safe. A group
 *   with no commander order and no transport links holds nothing that depends
 *   on its route, so the route is dropped and the group persists idle; it gets
 *   a new patrol after restore. Any other group still rejects the record.
 *   Logs the first leg that fails the water check either way.
 *
 * Return Value:
 *   BOOL - True when the route was cleared; throws otherwise
 */

params [
    ["_savedData", createHashMap, [createHashMap]],
    ["_groupId", "", [""]],
    ["_startPos", [0, 0, 0], [[]], [2, 3]],
    ["_reason", "", [""]]
];

private _waypoints = _savedData get "waypoints";
private _positions = _waypoints apply { +(_x select 0) };
private _index = _savedData get "currentWaypointIndex";
private _isLoop = (_savedData get "autoPatrol")
    || {(_savedData get "patrolConfig") isNotEqualTo []}
    || {(_waypoints findIf { toUpper (_x select 1) == "CYCLE" }) >= 0};
private _legs = [+_startPos] + (_positions select [_index]);
if (_isLoop) then {
    _legs append (_positions select [0, _index]);
    _legs pushBack (+(_legs select 1));
};

private _badLeg = "none found";
for "_i" from 0 to (count _legs - 2) do {
    private _from = _legs select _i;
    private _to = _legs select (_i + 1);
    if (surfaceIsWater _to || {([_from, _to, FLO_PF_WaterValidationStep] call FLO_fnc_pathSegmentWaterProfile) select 0}) exitWith {
        _badLeg = format ["%1 %2 -> %3 (%4 m)", _i, _from, _to, round (_from distance2D _to)];
    };
};

private _detail = format [
    "group=%1 reason=%2 start=%3 index=%4 loop=%5 waypoints=%6 firstWetLeg=%7 order=%8 mode=%9 type=%10 pathSource=%11",
    _groupId, _reason, _startPos, _index, _isLoop, count _waypoints, _badLeg,
    _savedData get "commanderOrder", _savedData get "orderMode", _savedData get "groupType", _savedData get "pathSource"
];

private _routeIsOwned = (_savedData get "commanderOrder") != ""
    || {(_savedData get "attachedTo") != ""}
    || {(_savedData get "attachedGroups") isNotEqualTo []}
    || {(_savedData get "dismountAtWaypoint") != -1};
if (_routeIsOwned) then {
    private _message = format ["Unsafe saved LAND route %1", _detail];
    ["VIRTUALIZATION", 1, _message] call FLO_fnc_log;
    throw _message;
};

_savedData set ["waypoints", []];
_savedData set ["currentWaypointIndex", 0];
_savedData set ["autoPatrol", false];
_savedData set ["patrolConfig", []];
[_savedData, "idle"] call FLO_fnc_virtualizationSetRuntimeState;
[_savedData, _groupId] call FLO_fnc_virtualizationValidateSavedGroup;
["VIRTUALIZATION", 1, format ["Cleared unsafe saved LAND route %1", _detail]] call FLO_fnc_log;

true
