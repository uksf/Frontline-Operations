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
[_stage get "group", (_stage get "nextIndex") == 0] call FLO_fnc_virtualizationDiscardRealGroupUnits;
