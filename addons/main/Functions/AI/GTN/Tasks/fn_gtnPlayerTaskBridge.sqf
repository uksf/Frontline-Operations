/*
 * Function: FLO_fnc_gtnPlayerTaskBridge
 * Author: Frontline Operations Development Group
 * Description:
 *   Once the mission is ready and commanders exist, updates the player
 *   capture task every 15 seconds until FLO_GTN_PlayerTaskBridgeRunning is
 *   false.
 *
 * Arguments: None
 *
 * Return Value:
 *   BOOL - true when the bridge is started or already running
 *
 * Example:
 *   [] call FLO_fnc_gtnPlayerTaskBridge;
 */

if (!isServer) exitWith { false };
if (!isNil "FLO_GTN_PlayerTaskBridgeRunning" && {FLO_GTN_PlayerTaskBridgeRunning}) exitWith { true };

FLO_GTN_PlayerTaskBridgeRunning = true;
FLO_GTN_PlayerTasks = createHashMap;

[
    { FLO_MissionReady && {keys (call FLO_fnc_gtnGetCommandersBySide) isNotEqualTo []} },
    {
        [] call FLO_fnc_gtnPlayerTaskBridgeTick;
        [{
            if (!FLO_GTN_PlayerTaskBridgeRunning) exitWith { [_this select 1] call CBA_fnc_removePerFrameHandler; };
            [] call FLO_fnc_gtnPlayerTaskBridgeTick;
        }, 15] call CBA_fnc_addPerFrameHandler;
    }
] call CBA_fnc_waitUntilAndExecute;

["GTN_TASKS", 3, "Direct attack task bridge started (15s interval)"] call FLO_fnc_log;
true
