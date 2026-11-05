/*
 * Function: FLO_fnc_virtualizationResolveIdleHelicopterParkPos
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves a clear ground parking position for an idle helicopter. A free
 *   helipad near the base wins; otherwise the helicopter parks on clear flat
 *   ground at least 15 m from any road. Returns an empty array when no
 *   unreserved position can be found.
 */

params [
    ["_basePos", [0, 0, 0], [[]]],
    ["_vehicleType", "", [""]],
    ["_index", 0, [0]],
    ["_searchRadius", 600, [0]]
];

private _uksf_reservations = missionNamespace getVariable ["uksf_parkReservations", []];
_uksf_reservations = _uksf_reservations select {
    _x params ["_uksf_vehicle", "_uksf_pos", "_uksf_until", "_uksf_group", "_uksf_token"];
    !isNull _uksf_vehicle && {alive _uksf_vehicle} && {serverTime < _uksf_until} && {(_uksf_vehicle distance2D _uksf_pos) > 10}
};
missionNamespace setVariable ["uksf_parkReservations", _uksf_reservations];

private _isFree = {
    params ["_pos"];
    !(surfaceIsWater _pos)
    && {!isOnRoad _pos}
    && {(_pos nearRoads 15) isEqualTo []}
    && {(nearestObjects [_pos, ["AllVehicles"], 25]) isEqualTo []}
    && {(_uksf_reservations findIf {(_x select 1) distance2D _pos < 25}) == -1}
};

private _pads = (nearestObjects [_basePos, ["HeliH"], 300]) select { [getPosATL _x] call _isFree };
if (_pads isNotEqualTo []) exitWith {
    private _padPos = getPosATL (_pads select 0);
    [_padPos select 0, _padPos select 1, 0]
};

private _offsetDistance = if (_index <= 0) then { 0 } else { 24 + (16 * _index) };
private _offsetPos = _basePos getPos [_offsetDistance, (_index * 137) mod 360];
_offsetPos set [2, 0];

private _parkPos = [];
for "_attempt" from 1 to 6 do {
    private _radius = _searchRadius * _attempt / 6;
    private _candidate = [_offsetPos, 0, _radius, 16, 0, 0.35, 0] call BIS_fnc_findSafePos;
    if ((_candidate distance2D _offsetPos) <= _radius && {[_candidate] call _isFree}) exitWith { _parkPos = _candidate };
};

if (_parkPos isEqualTo [] && {_vehicleType != ""}) then {
    _parkPos = _offsetPos findEmptyPosition [0, _searchRadius, _vehicleType];
};

if (_parkPos isNotEqualTo [] && {!([_parkPos] call _isFree)}) then { _parkPos = [] };
if (_parkPos isEqualTo []) then {
    private _uksf_candidate = [_offsetPos, _searchRadius] call FLO_fnc_getSafeLandPos;
    if ([_uksf_candidate] call _isFree) then { _parkPos = _uksf_candidate };
};

if (_parkPos isEqualTo []) exitWith { [] };
_parkPos = [_parkPos select 0, _parkPos select 1, 0];
_parkPos
