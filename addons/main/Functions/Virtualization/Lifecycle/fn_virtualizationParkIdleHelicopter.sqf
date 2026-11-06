/*
 * Function: FLO_fnc_virtualizationParkIdleHelicopter
 * Author: Frontline Operations Development Group
 * Description:
 *   Parks active idle helicopters on the ground with engines off so nearby
 *   reserve or inactive air assets do not hover in place.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Group Data <HASHMAP>
 * 2: Real Group <GROUP>
 *
 * Return Value:
 * BOOL - True when the group is eligible for idle helicopter parking
 */

params [
    ["_groupId", "", [""]],
    ["_groupData", createHashMap, [createHashMap]],
    ["_realGroup", grpNull, [grpNull]]
];

if (!isServer) exitWith { false };
if (_groupId == "") exitWith { false };

if (isNull _realGroup) then {
    _realGroup = _groupData get "realGroup";
};
if (isNull _realGroup) exitWith { false };

private _groupType = _groupData get "groupType";
private _vehicleType = _groupData get "vehicleType";
if (_groupType != "helicopter" && { _vehicleType == "" || { !(_vehicleType isKindOf "Helicopter") } }) exitWith { false };

private _helicopters = ([_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles) select {
    !isNull _x && { alive _x } && { _x isKindOf "Helicopter" }
};
if (_helicopters isEqualTo []) exitWith { false };

if ((_groupData get "missionLock") != "") exitWith { false };
if ((_groupData get "replacementState") != "") exitWith { false };
if ((_groupData get "attachedTo") != "") exitWith { false };
if ((_groupData get "mountedIn") != "") exitWith { false };
if (([_groupData] call FLO_fnc_virtualizationGetTransportPassengers) isNotEqualTo []) exitWith { false };

private _isReserveTransport = _groupData get "transportRole";
private _state = _groupData get "state";
private _executionState = _groupData get "executionState";
private _waypoints = _groupData get "waypoints";
private _position = _groupData get "position";
private _alreadyParked = _groupData get "idleHelicopterParked";
private _basePos = if (_isReserveTransport) then {
    +(_groupData get "spawnPosition")
} else {
    +_position
};
private _clearRoute = false;
private _canPark = false;

if !([_basePos] call FLO_fnc_virtualizationIsValidPosition) then {
    _basePos = getPosATL (_helicopters select 0);
};
_basePos set [2, 0];

if (_waypoints isEqualTo []) then {
    _canPark = (_state == "idle") || { _isReserveTransport && { _executionState == "" } };
} else {
    if (_isReserveTransport && { _executionState == "RTB" }) then {
        private _targetWp = _waypoints select -1;
        private _targetPos = +(_targetWp select 0);
        private _completionRadius = (_targetWp param [6, 75]) max 75;
        private _atReserve = (_position distance2D _targetPos) <= _completionRadius || {
            (_position distance2D _basePos) <= _completionRadius
        };

        if (_atReserve) then {
            _basePos = _targetPos;
            _basePos set [2, 0];
            _clearRoute = true;
            _canPark = true;
        };
    };
};

if (!_canPark) exitWith { false };
if (_alreadyParked && {!_clearRoute}) exitWith { true };

if (_clearRoute) then {
    _groupData set ["pathSource", ""];
    [_groupData] call FLO_fnc_virtualizationClearExecutionState;
    _groupData set ["waypoints", []];
    _groupData set ["currentWaypointIndex", 0];
    _groupData set ["virtualMoveCarryMeters", 0];
};

[_realGroup] call CBA_fnc_clearWaypoints;

private _needsParking = (_helicopters findIf {
    !(isTouchingGround _x) ||
    { ((getPosATL _x) select 2) > 1.5 } ||
    { (vectorMagnitude (velocity _x)) > 1 } ||
    { isEngineOn _x }
}) != -1;

[_groupData, "idle"] call FLO_fnc_virtualizationSetRuntimeState;
[_groupId, getPosATL (_helicopters select 0)] call FLO_fnc_virtualizationUpdateGroupPosition;
private _parksRemotely = (_helicopters findIf { !local _x }) != -1;
if (!_needsParking) then {
    _groupData set ["idleHelicopterParked", true];
};

if (!_needsParking) exitWith { true };
private _uksf_operation = _realGroup getVariable ["uksf_parkOperation", [-1, 0]];
_uksf_operation params ["_uksf_previousToken", "_uksf_previousUntil"];
private _uksf_currentToken = _realGroup getVariable ["uksf_parkToken", 0];
if (_uksf_previousToken == _uksf_currentToken && {serverTime < _uksf_previousUntil}) exitWith { true };

private _uksf_reservations = missionNamespace getVariable ["uksf_parkReservations", []];
_uksf_reservations = _uksf_reservations select {
    !((_x select 3) isEqualTo _realGroup && {(_x select 4) == _uksf_previousToken})
};
missionNamespace setVariable ["uksf_parkReservations", _uksf_reservations];

private _uksf_token = _uksf_currentToken + 1;
private _uksf_until = serverTime + 15;
_realGroup setVariable ["uksf_parkOperation", [_uksf_token, _uksf_until]];
_realGroup setVariable ["uksf_parkToken", _uksf_token, true];
private _uksf_waypoints = [count waypoints _realGroup, currentWaypoint _realGroup];
private _uksf_parked = 0;
{
    private _parkPos = [_basePos, typeOf _x, _forEachIndex, 600] call FLO_fnc_virtualizationResolveIdleHelicopterParkPos;
    if (_parkPos isNotEqualTo []) then {
        private _uksf_reservations = missionNamespace getVariable ["uksf_parkReservations", []];
        _uksf_reservations pushBack [_x, _parkPos, _uksf_until, _realGroup, _uksf_token];
        missionNamespace setVariable ["uksf_parkReservations", _uksf_reservations];
        _uksf_parked = _uksf_parked + ([[_x], "PARK", [_parkPos, getDir _x, _realGroup, _uksf_token, _uksf_waypoints, _uksf_until]] call FLO_fnc_vehicleCommandWhereLocal);
    };
} forEach _helicopters;

if (!_parksRemotely && {_uksf_parked == count _helicopters}) then {
    _groupData set ["idleHelicopterParked", true];
    [_groupData, [_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles] call FLO_fnc_virtualizationSetRealVehicles;
    [_groupId, getPosATL (_helicopters select 0)] call FLO_fnc_virtualizationUpdateGroupPosition;
};

true
