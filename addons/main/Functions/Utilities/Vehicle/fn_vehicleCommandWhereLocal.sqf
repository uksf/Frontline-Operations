/*
 * Function: FLO_fnc_vehicleCommandWhereLocal
 * Author: Frontline Operations Development Group
 * Description:
 *   Runs a local-argument unit or vehicle command on the machine where each
 *   object is local. The server runs its own objects inline and sends the rest
 *   to their owners, such as a headless client. Remote calls are accepted only
 *   from the server.
 *
 * Arguments:
 *   0: Objects <ARRAY> - Units or vehicles
 *   1: Command <STRING> - FLY_IN_HEIGHT, DISABLE_MOVE or PARK
 *   2: Argument <ANY> - Optional, depends on the command
 *
 * Return Value:
 *   NUMBER - Count of objects handled on this machine
 *
 * Example:
 *   [[_helicopter], "FLY_IN_HEIGHT", 60] call FLO_fnc_vehicleCommandWhereLocal;
 */

params [["_objects", [], [[]]], ["_command", "", [""]], ["_argument", 0]];

if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith { 0 };

private _localObjects = [];
private _remoteByOwner = createHashMap;
{
    if (isNull _x) then { continue };
    if (local _x) then { _localObjects pushBack _x; continue };
    if (isServer) then {
        (_remoteByOwner getOrDefaultCall [owner _x, { [] }, true]) pushBack _x;
    };
} forEach _objects;

{
    [_y, _command, _argument] remoteExec ["FLO_fnc_vehicleCommandWhereLocal", _x];
} forEach _remoteByOwner;

private _uksf_handled = 0;
{
    private _object = _x;
    private _uksf_applied = true;
    switch (_command) do {
        case "FLY_IN_HEIGHT": {
            _object flyInHeight _argument;
        };
        case "DISABLE_MOVE": {
            _object disableAI "PATH";
            _object disableAI "MOVE";
        };
        case "PARK": {
            _argument params ["_parkPos", "_parkDir", "_uksf_group", "_uksf_token", "_uksf_waypoints", "_uksf_engineOn", "_uksf_until"];
            private _uksf_currentWaypoints = [count waypoints _uksf_group, currentWaypoint _uksf_group];
            if (serverTime >= _uksf_until || {isNull _uksf_group} || {(_uksf_group getVariable ["uksf_parkToken", -1]) != _uksf_token} || {_uksf_currentWaypoints isNotEqualTo _uksf_waypoints} || {((getPosATL _object) select 2) > 15} || {(vectorMagnitude (velocity _object)) > 2} || {isEngineOn _object != _uksf_engineOn}) then {
                _uksf_applied = false;
            } else {
                _object setPosATL _parkPos;
                _object setDir _parkDir;
                _object setVectorUp [0, 0, 1];
                _object setVelocity [0, 0, 0];
                _object engineOn false;
            };
        };
        default {
            throw format ["FLO_fnc_vehicleCommandWhereLocal: unknown command %1", _command];
        };
    };
    if (_uksf_applied) then { _uksf_handled = _uksf_handled + 1 };
} forEach _localObjects;

_uksf_handled
