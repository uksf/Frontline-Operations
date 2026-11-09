/*
 * Function: FLO_fnc_virtualizationPullBackLateSpawn
 * Description:
 *   Keeps a land group that waited for activation capacity from appearing
 *   next to players. A group closer than FLO_VirtLateSpawnClearance metres to
 *   a ground player is moved to a point at least that far plus a margin,
 *   searched backwards along the route it already travelled, then directly
 *   away from the nearest player. The group keeps its current waypoint and
 *   walks back in. A group with no remaining route has nowhere to walk back
 *   to, so it stays where it is. While the group activates, ground vehicle
 *   placement keeps the same player clearance.
 *
 * Arguments:
 *   0: Group ID <STRING>
 *   1: Group Data <HASHMAP>
 *
 * Return Value:
 *   true when the group may spawn now, false when no clear point exists
 *   and activation must wait <BOOLEAN>
 *
 * Example:
 *   ["vgroup_1", _groupData] call FLO_fnc_virtualizationPullBackLateSpawn;
 */

params [["_groupId", "", [""]], ["_groupData", createHashMap, [createHashMap]]];

private _spawnKind = ([_groupData get "groupType"] call FLO_fnc_virtualizationGetArchetype) get "spawnKind";
if !(_spawnKind in ["INFANTRY", "GROUND"]) exitWith { true };

private _waypoints = _groupData get "waypoints";
private _currentIndex = _groupData get "currentWaypointIndex";
if (_currentIndex >= count _waypoints) exitWith { true };

private _clearance = missionNamespace getVariable ["FLO_VirtLateSpawnClearance", 400];
(FLO_VirtUpdate get "lateSpawnClearance") set [_groupId, _clearance];
private _position = _groupData get "position";
private _distanceToPlayers = { [_this, false, true, true] call FLO_fnc_virtualizationGetNearestCachedPlayerDistance };
if ((_position call _distanceToPlayers) >= _clearance) exitWith { true };

private _targetClearance = _clearance + 50;
private _clearOf = { !(surfaceIsWater _this) && {(_this call _distanceToPlayers) >= _targetClearance} };
private _target = [];
private _trail = [_position];
for "_i" from (_currentIndex - 1) to 0 step -1 do {
    _trail pushBack ((_waypoints select _i) select 0);
};
private _walked = 0;
for "_i" from 0 to (count _trail - 2) do {
    private _from = _trail select _i;
    private _to = _trail select (_i + 1);
    private _length = _from distance2D _to;
    private _dir = _from getDir _to;
    for "_step" from 50 to _length step 50 do {
        private _probe = _from getPos [_step, _dir];
        if (_probe call _clearOf) exitWith { _target = _probe; };
    };
    _walked = _walked + _length;
    if (_target isNotEqualTo [] || {_walked > 3000}) exitWith {};
};

if (_target isEqualTo []) then {
    private _nearest = [];
    private _nearestDist = 1e9;
    {
        _x params ["_playerPos", "_inAir", "_excluded", ["_lowAir", false]];
        if ((!_inAir || {_lowAir}) && {(_position distance2D _playerPos) < _nearestDist}) then {
            _nearest = _playerPos;
            _nearestDist = _position distance2D _playerPos;
        };
    } forEach (FLO_VirtUpdate get "cachedPlayerPositions");
    if (_nearest isEqualTo []) exitWith {};
    private _away = _nearest getDir _position;
    {
        private _probe = _nearest getPos [_targetClearance + 50, _away + _x];
        if (_probe call _clearOf) exitWith { _target = _probe; };
    } forEach [0, 30, -30, 60, -60, 90, -90, 120, -120, 150, -150, 180];
};

if (_target isEqualTo []) exitWith {
    ["VIRTUALIZATION", 3, format ["Holding late spawn %1: no clear point %2m from players", _groupId, _targetClearance]] call FLO_fnc_log;
    false
};
_target = [_target select 0, _target select 1, 0];
if !([_groupId, _groupData, _target] call FLO_fnc_virtualizationUpdateOwnedGroupPosition) exitWith { false };
["VIRTUALIZATION", 3, format ["Pulled back late spawn %1 by %2m to %3", _groupId, round (_position distance2D _target), _target]] call FLO_fnc_log;
true
