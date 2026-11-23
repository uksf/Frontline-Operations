/*
 * Function: FLO_fnc_initDeployPlayerFail
 * Description:
 *   Marks initial player deployment as failed, logs the reason, and tells the
 *   player.
 *
 * Arguments:
 * 0: Log message <STRING>
 * 1: Player hint <STRING>
 *
 * Return Value:
 * None
 */

params ["_logMessage", "_hint"];

FLO_ClientDeploymentFailed = true;
["INIT_CLIENT", 1, _logMessage] call FLO_fnc_log;
titleText ["", "BLACK IN", 1, true, true];
hint _hint;
