/*
 * Function: FLO_fnc_virtualizationSweepStagedGroups
 * Description:
 *   Discards staged groups whose record is gone or already active, and
 *   staged groups that made no progress within stagingStallSeconds, such as
 *   when the player moved away or the unit cap blocked the activation.
 *
 * Return Value:
 *   None
 */

private _stagedGroups = FLO_VirtUpdate get "stagedGroups";
if (count _stagedGroups == 0) exitWith {};

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _stallBefore = diag_tickTime - (["stagingStallSeconds"] call FLO_fnc_virtualizationGetConfigValue);
{
    private _stage = _stagedGroups get _x;
    if (
        !(_x in _groups)
        || {(_groups get _x) get "isActive"}
        || {(_stage get "progressAt") < _stallBefore}
    ) then {
        [_x] call FLO_fnc_virtualizationDiscardStagedGroup;
    };
} forEach (keys _stagedGroups);
