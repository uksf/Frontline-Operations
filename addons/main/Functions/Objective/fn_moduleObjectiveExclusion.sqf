/*
 * Function: FLO_fnc_moduleObjectiveExclusion
 * Description:
 *   Registers one Eden objective-exclusion area before fresh indexing.
 */

(_this select 1) params ["_logic"];

if !(missionNamespace getVariable ["FLO_MissionEnabled", false]) exitWith {};
if (!isServer || {!local _logic}) exitWith {};

private _area = _logic getVariable ["objectarea", []];
if (_area isEqualTo []) exitWith {
    ["OBJECTIVES", 2, format ["Ignored objective exclusion module without an area at %1", getPosATL _logic]] call FLO_fnc_log;
};

FLO_ObjectiveExclusionAreas pushBack [_logic, _area];
["OBJECTIVES", 3, format ["Registered objective exclusion area at %1 with shape %2", getPosATL _logic, _area]] call FLO_fnc_log;
