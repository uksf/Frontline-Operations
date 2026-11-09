/*
 * Function: FLO_fnc_virtualizationCachePlayers
 * Description:
 *   Caches [position, inAir, excluded, lowAir] for each connected player. Players inside
 *   an exclusion area are flagged excluded: they do not activate AI, but still
 *   count for spawn-position clearance. lowAir marks a player in an aircraft that is
 *   landed or hovering: it holds already-active AI and counts for spawn clearance.
 */

private _lowAirMaxHeight = missionNamespace getVariable ["FLO_VirtLowAirMaxHeight", 100];
private _lowAirMaxSpeed = missionNamespace getVariable ["FLO_VirtLowAirMaxSpeed", 60];
private _cached = [];
{
    if (
        (side group _x) in [east, west, independent]
    ) then {
        private _veh = vehicle _x;
        private _inAir = (_veh != _x) && {_veh isKindOf "Air"};
        private _lowAir = _inAir && {((getPos _veh) select 2) < _lowAirMaxHeight} && {(speed _veh) < _lowAirMaxSpeed};
        private _pos = getPosATL _x;
        _cached pushBack [_pos, _inAir, [_pos] call FLO_fnc_objectivePositionExcluded, _lowAir];
    };
} forEach ([] call FLO_fnc_getConnectedHumanPlayers);

FLO_VirtUpdate set ["cachedPlayerPositions", _cached];
FLO_VirtUpdate set ["lastPlayerCacheTime", diag_tickTime];

_cached
