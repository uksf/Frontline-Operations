/*
 * Function: FLO_fnc_virtualizationGetNearerDeferredLoad
 * Description:
 *   Sums the unit load of cap-deferred groups that are nearer to a player than
 *   the given distance. That load is reserved for them, so a farther group
 *   cannot take the capacity first. Entries not refreshed within
 *   FLO_VirtDeferredQueueTTL seconds are dropped.
 *
 * Arguments:
 *   0: Group ID to leave out <STRING>
 *   1: Nearest player distance of that group <NUMBER>
 *
 * Return Value:
 *   Reserved unit load <NUMBER>
 *
 * Example:
 *   ["vgroup_1", 600] call FLO_fnc_virtualizationGetNearerDeferredLoad;
 */

params [["_groupId", "", [""]], ["_nearestDist", 0, [0]]];

private _queue = FLO_VirtUpdate get "deferredQueue";
private _staleBefore = diag_tickTime - (missionNamespace getVariable ["FLO_VirtDeferredQueueTTL", 5]);
private _stale = [];
private _load = 0;
{
    _y params ["_dist", "_groupLoad", "_seenAt"];
    if (_seenAt < _staleBefore) then {
        _stale pushBack _x;
    } else {
        if (_x != _groupId && {_dist < _nearestDist}) then {
            _load = _load + _groupLoad;
        };
    };
} forEach _queue;
{ _queue deleteAt _x } forEach _stale;

_load
