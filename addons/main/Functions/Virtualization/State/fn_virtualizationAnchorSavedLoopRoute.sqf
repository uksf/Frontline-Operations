/*
 * Function: FLO_fnc_virtualizationAnchorSavedLoopRoute
 * Description:
 *   Recovers a saved patrol loop whose continuation from the group position
 *   crosses water. The group moves onto the nearest loop waypoint, within
 *   500 m, from which the whole loop is terrain-safe, and resumes the loop
 *   there. Routes that are not loops are left unchanged.
 *
 * Arguments:
 *   0: Saved group data <HASHMAP>
 *   1: Group ID <STRING>
 *
 * Return Value:
 *   BOOL - True when the saved record was anchored onto its loop
 */

params [
    ["_savedData", createHashMap, [createHashMap]],
    ["_groupId", "", [""]]
];

private _waypoints = _savedData get "waypoints";
private _autoPatrol = _savedData get "autoPatrol";
private _patrolConfig = _savedData get "patrolConfig";
private _hasCycle = (_waypoints findIf { toUpper (_x select 1) == "CYCLE" }) >= 0;
if !(_autoPatrol || {_patrolConfig isNotEqualTo []} || {_hasCycle}) exitWith { false };

private _position = _savedData get "position";
private _candidates = [];
{
    if (toUpper (_x select 1) != "CYCLE") then {
        private _distance = (_x select 0) distance2D _position;
        if (_distance <= 500) then { _candidates pushBack [_distance, _forEachIndex] };
    };
} forEach _waypoints;
_candidates sort true;

private _anchorIndex = -1;
{
    private _index = _x select 1;
    private _anchorPos = +((_waypoints select _index) select 0);
    if (([_groupId, _anchorPos, _waypoints, _index, _autoPatrol, _patrolConfig] call FLO_fnc_virtualizationValidateLandRoute) select 0) exitWith {
        _anchorIndex = _index;
    };
} forEach _candidates;
if (_anchorIndex < 0) exitWith { false };

private _anchorPos = +((_waypoints select _anchorIndex) select 0);
_savedData set ["position", [_anchorPos select 0, _anchorPos select 1, 0]];
_savedData set ["currentWaypointIndex", _anchorIndex];
["VIRTUALIZATION", 2, format [
    "Anchored saved patrol loop group=%1 from=%2 to waypoint %3 at %4 (%5 m)",
    _groupId,
    _position,
    _anchorIndex,
    _anchorPos,
    round (_position distance2D _anchorPos)
]] call FLO_fnc_log;
true
