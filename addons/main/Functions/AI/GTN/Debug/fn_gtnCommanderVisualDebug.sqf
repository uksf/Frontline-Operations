/*
 * Function: FLO_fnc_gtnCommanderVisualDebug
 * Author: Frontline Operations Development Group
 * Description:
 *   Server-side visual debug for dual GTN commanders. Once the resource
 *   manager and force registry exist, redraws the commander debug markers at
 *   the given interval until FLO_GTN_CommanderDebugRunning is false, then
 *   clears them.
 *
 * Arguments:
 *   0: Update interval (seconds) <NUMBER> - Default 5
 *
 * Return Value:
 *   BOOL - true when debug drawing is started or already running
 *
 * Example:
 *   [5] call FLO_fnc_gtnCommanderVisualDebug;
 */

if (!isServer) exitWith { false };

params [["_interval", 5, [0]]];
if (_interval < 1) then { _interval = 1 };

if (!isNil "FLO_GTN_CommanderDebugRunning" && {FLO_GTN_CommanderDebugRunning}) exitWith { true };
FLO_GTN_CommanderDebugRunning = true;

if (isNil "FLO_GTN_CommanderDebugEnabled") then { FLO_GTN_CommanderDebugEnabled = true; };
if (isNil "FLO_GTN_CommanderDebugMarkers") then { FLO_GTN_CommanderDebugMarkers = createHashMap; };

[
    { !isNil "FLO_GTN_ResourceManager" && {!isNil "FLO_VirtualForceRegistry"} },
    {
        [] call FLO_fnc_gtnCommanderVisualDebugTick;
        [{
            if (!FLO_GTN_CommanderDebugRunning) exitWith {
                [_this select 1] call CBA_fnc_removePerFrameHandler;
                [] call FLO_fnc_gtnCommanderDebugClearAll;
            };
            [] call FLO_fnc_gtnCommanderVisualDebugTick;
        }, _this] call CBA_fnc_addPerFrameHandler;
    },
    _interval
] call CBA_fnc_waitUntilAndExecute;

["GTN_DEBUG", 2, format ["Commander visual debug started (%1s interval)", _interval]] call FLO_fnc_log;

true
