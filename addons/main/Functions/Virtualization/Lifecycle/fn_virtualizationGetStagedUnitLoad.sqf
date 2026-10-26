/*
 * Function: FLO_fnc_virtualizationGetStagedUnitLoad
 * Description:
 *   Counts the units that staging has created for groups other than the one
 *   given, so activation cap checks include units that already exist but
 *   are not yet active.
 *
 * Arguments:
 *   0: Group ID to leave out <STRING>
 *
 * Return Value:
 *   Staged unit count <NUMBER>
 */

params [["_exceptGroupId", "", [""]]];

private _load = 0;
{
    if (_x != _exceptGroupId) then { _load = _load + count units (_y get "group") };
} forEach (FLO_VirtUpdate get "stagedGroups");
_load
