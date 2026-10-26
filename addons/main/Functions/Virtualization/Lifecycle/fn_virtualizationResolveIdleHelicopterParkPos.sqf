/*
 * Function: FLO_fnc_virtualizationResolveIdleHelicopterParkPos
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves a clear ground parking position for an idle helicopter. A free
 *   helipad near the base wins; otherwise the helicopter parks on clear flat
 *   ground at least 15 m from any road.
 */

params [
    ["_basePos", [0, 0, 0], [[]]],
    ["_vehicleType", "", [""]],
    ["_index", 0, [0]],
    ["_searchRadius", 600, [0]]
];

private _isFree = {
    params ["_pos"];
    !(surfaceIsWater _pos)
    && {!isOnRoad _pos}
    && {(_pos nearRoads 15) isEqualTo []}
    && {(nearestObjects [_pos, ["AllVehicles"], 10]) isEqualTo []}
};

private _pads = (nearestObjects [_basePos, ["HeliH"], 300]) select { [getPosATL _x] call _isFree };
if (_pads isNotEqualTo []) exitWith {
    private _padPos = getPosATL (_pads select (_index min (count _pads - 1)));
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

if (_parkPos isEqualTo [] || { surfaceIsWater _parkPos }) then {
    _parkPos = [_offsetPos, _searchRadius] call FLO_fnc_getSafeLandPos;
};

_parkPos = [_parkPos select 0, _parkPos select 1, 0];
_parkPos
