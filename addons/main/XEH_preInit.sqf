call compile preprocessFileLineNumbers "\z\flo\addons\main\Functions\Init\fn_registerSettings.sqf";

if (missionNamespace getVariable ["FLO_MissionEnabled", false]) then {
    FLO_ObjectiveExclusionAreas = [];
};
