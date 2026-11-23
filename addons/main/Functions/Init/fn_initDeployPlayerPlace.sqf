/*
 * Function: FLO_fnc_initDeployPlayerPlace
 * Description:
 *   Validates the server activation acknowledgement, places the local player,
 *   and calls the deployed callback once the activation state reaches the
 *   client.
 *
 * Arguments:
 * 0: Activation acknowledgement [start position, server tick] <ARRAY>
 * 1: Code to call after the player is deployed <CODE>
 *
 * Return Value:
 * None
 */

params ["_activation", ["_onDeployed", {}, [{}]]];

if !(_activation isEqualType [] && {count _activation == 2}) exitWith {
    [format ["Player activation acknowledgement is malformed: %1", _activation], "FLO received an invalid deployment acknowledgement. Check the server and client RPT."] call FLO_fnc_initDeployPlayerFail;
};

_activation params ["_startPosition", "_serverTick"];
if !(
    _startPosition isEqualType []
    && {count _startPosition == 3}
    && {_serverTick isEqualType 0}
) exitWith {
    [format ["Player activation data is malformed: %1", _activation], "FLO received malformed deployment data. Check the server and client RPT."] call FLO_fnc_initDeployPlayerFail;
};

player allowDamage true;
if !(player setVehiclePosition [_startPosition, [], 15, "NONE"]) exitWith {
    [format ["No safe initial player position near %1", _startPosition], "FLO could not find a safe deployment position. Move the campaign start or reconnect after clearing the area."] call FLO_fnc_initDeployPlayerFail;
};

[
    { simulationEnabled player && {!isObjectHidden player} && {isDamageAllowed player} },
    {
        params ["_serverTick", "_onDeployed"];
        FLO_InitPlayerDeploymentDone = true;
        ["INIT_CLIENT", 3, format ["Player deployed at %1 (server tick %2)", getPosATL player, _serverTick]] call FLO_fnc_log;
        call _onDeployed;
    },
    [_serverTick, _onDeployed],
    5,
    {
        [format [
            "Player activation did not propagate: simulation=%1 hidden=%2 damage=%3",
            simulationEnabled player,
            isObjectHidden player,
            isDamageAllowed player
        ], "FLO player activation did not complete. Reconnect and check the server and client RPT."] call FLO_fnc_initDeployPlayerFail;
    }
] call CBA_fnc_waitUntilAndExecute;
