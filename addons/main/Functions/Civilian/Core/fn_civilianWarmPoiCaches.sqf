/*
 * Function: FLO_fnc_civilianWarmPoiCaches
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the POI cache of every objective that a civilian group lives at,
 *   one objective per frame, then runs the first manager update and starts
 *   the manager worker. The first routine pass then plans from warm caches
 *   instead of building every objective's cache in a single frame.
 *
 * Arguments:
 *   0: Civilian manager <HASHMAP>
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [FLO_CivilianManager] call FLO_fnc_civilianWarmPoiCaches;
 */

params ["_manager"];

private _objectiveIds = createHashMap;
if (!isNil "FLO_VirtualForceRegistry") then {
    {
        if ((_y get "side") != civilian) then { continue };
        private _objectiveId = _y getOrDefault ["civilianObjective", ""];
        if (_objectiveId != "") then {
            _objectiveIds set [_objectiveId, true];
        };
    } forEach (call FLO_fnc_virtualizationGetGroupMap);
};

private _warmStart = diag_tickTime;
[{
    params ["_args", "_pfhId"];
    _args params ["_manager", "_pending", "_warmStart"];

    if (isNil "FLO_CivilianManager") exitWith {
        [_pfhId] call CBA_fnc_removePerFrameHandler;
    };

    if (_pending isEqualTo []) exitWith {
        [_pfhId] call CBA_fnc_removePerFrameHandler;
        ["CIVILIAN", 3, format [
            "Warmed %1 objective POI caches in %2 s",
            count (_manager get "_objectivePoiCaches"),
            (diag_tickTime - _warmStart) toFixed 1
        ]] call FLO_fnc_log;
        _manager call ["update", []];
        _manager call ["start", []];
    };

    _manager call ["getObjectivePoiCache", [_pending deleteAt 0]];
}, 0, [_manager, keys _objectiveIds, _warmStart]] call CBA_fnc_addPerFrameHandler;
