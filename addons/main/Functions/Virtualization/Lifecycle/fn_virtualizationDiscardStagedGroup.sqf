/*
 * Function: FLO_fnc_virtualizationDiscardStagedGroup
 * Description:
 *   Removes a staging entry and deletes the units it created.
 *
 * Arguments:
 *   0: Group ID <STRING>
 *
 * Return Value:
 *   None
 */

params ["_groupId"];

private _stage = (FLO_VirtUpdate get "stagedGroups") deleteAt _groupId;
if (isNil "_stage") exitWith {};
private _stats = FLO_VirtUpdate get "stats";
_stats set ["stagedGroupsDiscardedTotal", (_stats get "stagedGroupsDiscardedTotal") + 1];
private _uksf_neverPopulated = (_stage get "nextIndex") == 0 && {(_stage get "uksf_createdFrame") == diag_frameNo};
[_stage get "group", _uksf_neverPopulated] call FLO_fnc_virtualizationDiscardRealGroupUnits;
