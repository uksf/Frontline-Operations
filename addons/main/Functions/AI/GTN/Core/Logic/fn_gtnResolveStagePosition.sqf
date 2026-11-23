/*
 * Function: FLO_fnc_gtnResolveStagePosition
 * Description:
 *   Chooses where a CAPTURE force assembles. While the active AI count is at
 *   or above the activation resume cap, a group that enters activation range
 *   is deferred and stops moving, so a stage near players can never fill.
 *   In that state the stage moves back from the target until it is
 *   250 m outside activation range of every ground player, on dry land and
 *   within 2000 m of the stage objective. Otherwise, or when no such point
 *   exists, the stage objective position is kept.
 *
 * Arguments:
 * 0: Stage objective position <ARRAY>
 * 1: Attack target position <ARRAY>
 *
 * Return Value:
 * Stage position <ARRAY>
 */

params ["_stagePos", "_targetPos"];

if ((FLO_VirtUpdate get "activeUnitCount") < (["activationResumeCap"] call FLO_fnc_virtualizationGetConfigValue)) exitWith { +_stagePos };

private _clearance = (["activationDistance"] call FLO_fnc_virtualizationGetConfigValue) + 250;
if (([_stagePos] call FLO_fnc_virtualizationGetNearestCachedPlayerDistance) >= _clearance) exitWith { +_stagePos };

private _away = _targetPos getDir _stagePos;
private _resolved = [];
for "_step" from 200 to 2000 step 200 do {
    {
        private _candidate = _stagePos getPos [_step, _away + _x];
        _candidate set [2, 0];
        if (!([_candidate] call FLO_fnc_isRouteWater) && {([_candidate] call FLO_fnc_virtualizationGetNearestCachedPlayerDistance) >= _clearance}) exitWith {
            _resolved = _candidate;
        };
    } forEach [0, 30, -30, 60, -60];
    if (_resolved isNotEqualTo []) exitWith {};
};

if (_resolved isEqualTo []) exitWith { +_stagePos };
["GTN", 3, format ["Staging CAPTURE force %1m back from %2 to stay outside player activation range", round (_resolved distance2D _stagePos), _stagePos]] call FLO_fnc_log;
_resolved
