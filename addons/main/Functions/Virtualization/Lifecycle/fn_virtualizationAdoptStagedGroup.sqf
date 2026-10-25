/*
 * Function: FLO_fnc_virtualizationAdoptStagedGroup
 * Description:
 *   Hands a complete staged group to activation. A staged group that is
 *   incomplete, lost a unit, or no longer matches the composition is discarded.
 *
 * Arguments:
 *   0: Group ID <STRING>
 *   1: Composition <ARRAY>
 *
 * Return Value:
 *   The staged group, or grpNull when activation must spawn normally <GROUP>
 */

params ["_groupId", "_comp"];

private _stagedGroups = FLO_VirtUpdate get "stagedGroups";
if !(_groupId in _stagedGroups) exitWith { grpNull };

private _stage = _stagedGroups get _groupId;

private _group = _stage get "group";
private _units = units _group;
if (
    isNull _group
    || {(_stage get "comp") isNotEqualTo _comp}
    || {(_stage get "nextIndex") != count _comp}
    || {(_units findIf { !alive _x }) >= 0}
    || {(_units apply { typeOf _x }) isNotEqualTo _comp}
) exitWith {
    [_groupId] call FLO_fnc_virtualizationDiscardStagedGroup;
    grpNull
};

_stagedGroups deleteAt _groupId;
_group
