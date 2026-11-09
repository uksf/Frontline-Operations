/*
 * Function: FLO_fnc_virtualizationGetStagedUnitLoad
 * Description:
 *   Counts the full planned unit load of groups that are staging, other than
 *   the one given, so activation cap checks reserve capacity for units that
 *   staging has not created yet.
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
    if (_x != _exceptGroupId) then { _load = _load + ((_y getOrDefault ["load", 0]) max (count units (_y get "group"))) };
} forEach (FLO_VirtUpdate get "stagedGroups");
_load
