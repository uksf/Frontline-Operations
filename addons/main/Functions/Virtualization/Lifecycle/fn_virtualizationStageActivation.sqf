/*
 * Function: FLO_fnc_virtualizationStageActivation
 * Description:
 *   Creates the units of a due infantry composition across frames, within a
 *   per-frame time budget, before the group activates. The record stays
 *   virtual while staging, so saves and outcome syncs never see a partial
 *   group. FLO_fnc_virtualizationSpawnFromComposition adopts the complete
 *   staged group during the normal activation.
 *
 * Arguments:
 *   0: Group ID <STRING>
 *   1: Group Data <HASHMAP>
 *
 * Return Value:
 *   true when this call created staged units and activation must wait <BOOLEAN>
 */

params ["_groupId", "_groupData"];

private _comp = _groupData get "comp";
if (
    count _comp < 2
    || {(_groupData get "supportComp") isNotEqualTo []}
    || {(_groupData get "attachedTo") != ""}
    || {_groupData get "isTransport"}
    || {!(([_groupData get "groupType"] call FLO_fnc_virtualizationGetArchetype) get "compositionPreemptsSpawn")}
    || {(_comp findIf { !(_x isKindOf "Man") }) >= 0}
) exitWith { false };

private _stagedGroups = FLO_VirtUpdate get "stagedGroups";
if (_groupId in _stagedGroups && {((_stagedGroups get _groupId) get "comp") isNotEqualTo _comp}) then {
    [_groupId] call FLO_fnc_virtualizationDiscardStagedGroup;
};
if !(_groupId in _stagedGroups) then {
    private _group = [_groupData get "side", _groupId, _groupData get "groupType"] call FLO_fnc_virtualizationCreateRealGroup;
    if (isNull _group) exitWith {};
    _stagedGroups set [_groupId, createHashMapFromArray [
        ["group", _group],
        ["comp", +_comp],
        ["nextIndex", 0],
        ["position", [_groupData get "position"] call FLO_fnc_getSafeUnvirtualizePos],
        ["progressAt", diag_tickTime]
    ]];
};
if !(_groupId in _stagedGroups) exitWith { false };

private _stage = _stagedGroups get _groupId;

private _group = _stage get "group";
private _stats = FLO_VirtUpdate get "stats";
private _budgetEnd = diag_tickTime + ((["stagingFrameBudgetMs"] call FLO_fnc_virtualizationGetConfigValue) / 1000);
private _staged = false;
while { (_stage get "nextIndex") < count _comp && {!_staged || {diag_tickTime < _budgetEnd}} } do {
    private _unit = [_group, _comp select (_stage get "nextIndex"), _stage get "position", _groupData get "side", _groupData get "groupType"] call FLO_fnc_activateSavedVirtualGroup;
    if (isNull _unit) exitWith {
        [_groupId] call FLO_fnc_virtualizationDiscardStagedGroup;
        _staged = false;
    };
    _stage set ["nextIndex", (_stage get "nextIndex") + 1];
    _stage set ["progressAt", diag_tickTime];
    _stats set ["stagedUnitsTotal", (_stats get "stagedUnitsTotal") + 1];
    _staged = true;
};

_staged
