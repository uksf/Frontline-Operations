/* Starts a validated setup request; the map click continues it and then presents its progress. */
disableSerialization;
private _display = uiNamespace getVariable ["FLO_FactionDialog", displayNull];
if (isNull _display) exitWith {
    ["UI", 1, "Cannot start mission - faction dialog is null"] call FLO_fnc_log;
};
private _startBtn = _display displayCtrl 1600;
_startBtn ctrlEnable false;
private _config = [_display] call FLO_fnc_factionDialogReadConfig;
if (count _config == 0) exitWith { _startBtn ctrlEnable true; };
_display closeDisplay 1;
["UI", 3, format ["Mission setup accepted for player side %1", _config get "playerSideKey"]] call FLO_fnc_log;
missionNamespace setVariable ["FLO_missionStartTime", diag_tickTime, true];
hint "Setting up mission...";
[_config] call FLO_fnc_factionDialogSelectStartPosition;
