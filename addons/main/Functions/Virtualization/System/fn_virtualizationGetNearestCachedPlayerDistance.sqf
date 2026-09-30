/*
 * Function: FLO_fnc_virtualizationGetNearestCachedPlayerDistance
 * Description:
 *   Distance to the nearest cached player. Players in an exclusion area are
 *   skipped unless _includeExcluded is set, which spawn-clearance checks use.
 */

params ["_pos", ["_includeAirPlayers", false, [true]], ["_includeExcluded", false, [true]]];

private _cachedPlayers = FLO_VirtUpdate get "cachedPlayerPositions";
private _nearest = 999999;

{
    _x params ["_playerPos", "_inAir", ["_excluded", false]];
    if ((!_inAir || {_includeAirPlayers}) && {!_excluded || {_includeExcluded}}) then {
        private _dist = _pos distance2D _playerPos;
        if (_dist < _nearest) then {
            _nearest = _dist;
        };
    };
} forEach _cachedPlayers;

_nearest
