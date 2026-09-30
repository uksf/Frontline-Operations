/*
 * Function: FLO_fnc_virtualizationCachePlayers
 * Description:
 *   Caches [position, inAir, excluded] for each connected player. Players inside
 *   an exclusion area are flagged excluded: they do not activate AI, but still
 *   count for spawn-position clearance.
 */

private _cached = [];
{
    if (
        (side group _x) in [east, west, independent]
    ) then {
        private _veh = vehicle _x;
        private _inAir = (_veh != _x) && {_veh isKindOf "Air"};
        private _pos = getPosATL _x;
        _cached pushBack [_pos, _inAir, [_pos] call FLO_fnc_objectivePositionExcluded];
    };
} forEach ([] call FLO_fnc_getConnectedHumanPlayers);

FLO_VirtUpdate set ["cachedPlayerPositions", _cached];
FLO_VirtUpdate set ["lastPlayerCacheTime", diag_tickTime];

_cached
