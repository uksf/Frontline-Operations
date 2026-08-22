/*
 * Function: FLO_fnc_heartbeatNotifyRestart
 * Author: Frontline Operations Development Group
 * Description:
 *   Records a server restart threshold without player-facing UI.
 *
 * Arguments:
 * 0: Minutes left <NUMBER>
 *
 * Returns: None
 */
params ["_minutesLeft"];

diag_log format ["[FLO_HEARTBEAT] Restart threshold reached with %1 minutes remaining", _minutesLeft];
