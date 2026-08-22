/**
 * Function: FLO_fnc_notification
 * 
 * Description:
 * Records objective rewards without a player-facing campaign banner.
 *
 * Parameters:
 * _this select 0: NUMBER - The reward points amount
 * _this select 1: STRING - The objective name/description
 *
 * Returns:
 * NOTHING
 *
 * Example:
 * [100, "ENEMY OUTPOST"] call FLO_fnc_notification;
 */

// Check parameters
params [
    ["_reward", 0, [0]],
    ["_objectiveStr", "STR_FLO_OBJECTIVE", [""]]
];

["REWARDS", 3, format ["Objective reward secured: objective=%1 reward=%2", _objectiveStr, _reward]] call FLO_fnc_log;
