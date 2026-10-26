/*
 * Function: FLO_fnc_virtualizationAdoptStagedGroup
 * Description:
 *   Hands a complete staged group of the requested kind to activation. A
 *   staged group of that kind that is incomplete, lost a unit, or no longer
 *   matches the composition is discarded. A stage of another kind is left
 *   for its own spawn path.
 *
 * Arguments:
 *   0: Group ID <STRING>
 *   1: Stage kind, "INFANTRY" or "CREW" <STRING>
 *   2: Composition, checked for INFANTRY <ARRAY>
 *
 * Return Value:
 *   The staged group, or grpNull when activation must spawn normally <GROUP>
 */

params ["_groupId", "_kind", ["_comp", []]];

private _stagedGroups = FLO_VirtUpdate get "stagedGroups";
if !(_groupId in _stagedGroups) exitWith { grpNull };

private _stage = _stagedGroups get _groupId;
(_stage get "plan") params ["_stageKind", "_types"];
if (_stageKind != _kind) exitWith { grpNull };

private _group = _stage get "group";
private _units = units _group;
if (
    isNull _group
    || {(_stage get "nextIndex") != count _types}
    || {(_units findIf { !alive _x }) >= 0}
    || {_kind == "INFANTRY" && {(_stage get "comp") isNotEqualTo _comp || {(_units apply { typeOf _x }) isNotEqualTo _comp}}}
) exitWith {
    [_groupId] call FLO_fnc_virtualizationDiscardStagedGroup;
    grpNull
};

_stagedGroups deleteAt _groupId;
_group
