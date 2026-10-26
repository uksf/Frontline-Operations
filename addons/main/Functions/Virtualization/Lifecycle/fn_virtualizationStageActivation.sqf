/*
 * Function: FLO_fnc_virtualizationStageActivation
 * Description:
 *   Creates the units of a due group across frames, within a per-frame time
 *   budget, before the group activates. Staged units are hidden and frozen.
 *   An infantry composition stages its soldiers, which
 *   FLO_fnc_virtualizationSpawnFromComposition reveals on adoption. A vehicle
 *   group stages crew in a holding group, which
 *   FLO_fnc_virtualizationTakeStagedUnit seats when the vehicles spawn. The
 *   record stays virtual while staging, so saves and outcome syncs never see
 *   a partial group.
 *
 * Arguments:
 *   0: Group ID <STRING>
 *   1: Group Data <HASHMAP>
 *
 * Return Value:
 *   true when this call created staged units and activation must wait <BOOLEAN>
 */

params ["_groupId", "_groupData"];

private _stagedGroups = FLO_VirtUpdate get "stagedGroups";
private _plan = [_groupData] call FLO_fnc_virtualizationGetStagingPlan;
if (_groupId in _stagedGroups && {((_stagedGroups get _groupId) get "plan") isNotEqualTo _plan}) then {
    [_groupId] call FLO_fnc_virtualizationDiscardStagedGroup;
};
if (_plan isEqualTo []) exitWith { false };
_plan params ["_kind", "_types"];
if !(_groupId in _stagedGroups) then {
    private _group = [_groupData get "side", _groupId, _groupData get "groupType"] call FLO_fnc_virtualizationCreateRealGroup;
    if (isNull _group) exitWith {};
    _stagedGroups set [_groupId, createHashMapFromArray [
        ["group", _group],
        ["plan", +_plan],
        ["comp", +(_groupData get "comp")],
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
while { (_stage get "nextIndex") < count _types && {!_staged || {diag_tickTime < _budgetEnd}} } do {
    private _type = _types select (_stage get "nextIndex");
    private _unit = if (_kind == "INFANTRY") then {
        [_group, _type, _stage get "position", _groupData get "side", _groupData get "groupType"] call FLO_fnc_activateSavedVirtualGroup
    } else {
        _group createUnit [_type, _stage get "position", [], 0, "NONE"]
    };
    if (isNull _unit) exitWith {
        [_groupId] call FLO_fnc_virtualizationDiscardStagedGroup;
        _staged = false;
    };
    _unit enableSimulationGlobal false;
    _unit hideObjectGlobal true;
    _stage set ["nextIndex", (_stage get "nextIndex") + 1];
    _stage set ["progressAt", diag_tickTime];
    _stats set ["stagedUnitsTotal", (_stats get "stagedUnitsTotal") + 1];
    _staged = true;
};

_staged
