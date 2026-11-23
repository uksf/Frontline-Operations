/*
 * Function: FLO_fnc_initDeployPlayer
 * Description:
 *   Requests server activation for the local player, then places the player at
 *   campaign start once the server acknowledges. Runs without suspension.
 *
 * Arguments:
 * 0: Code to call after the player is deployed <CODE>
 *
 * Return Value:
 * None
 */

params [["_onDeployed", {}, [{}]]];

if (!hasInterface) exitWith {};
if (isNull player || {player != player} || {!local player}) exitWith {
    throw "Initial player deployment requires a valid local player"
};

titleText ["", "BLACK FADED", 0.1, true, true];
FLO_ClientDeploymentFailed = false;
player setVariable ["FLO_InitPlayerActivation", nil, false];
[player] remoteExecCall ["FLO_fnc_initActivatePlayer", 2];

[
    { (player getVariable ["FLO_InitPlayerActivation", []]) isNotEqualTo [] },
    {
        [player getVariable ["FLO_InitPlayerActivation", []], _this] call FLO_fnc_initDeployPlayerPlace;
    },
    _onDeployed,
    20,
    {
        ["Player activation timed out after 20 seconds", "FLO could not activate your player. Reconnect and check the server RPT for [FLO][INIT] errors."] call FLO_fnc_initDeployPlayerFail;
    }
] call CBA_fnc_waitUntilAndExecute;
