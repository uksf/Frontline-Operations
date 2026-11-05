/*
 * Function: FLO_fnc_virtualizationDiscardRealGroupUnits
 * Description:
 *   Deletes a physical group's units and leaves group removal to the engine.
 *   Groups are created with deleteGroupWhenEmpty, which removes them once the
 *   deferred unit deletions land. The engine never removes a group that never
 *   held units, so the caller passes true to delete such an empty group.
 *   A group that held units is never deleted here.
 *
 * Arguments:
 *   0: Group <GROUP>
 *   1: Group never held units <BOOL> (default false)
 * Return Value:
 *   None
 */

params [["_group", grpNull, [grpNull]], ["_uksf_neverPopulated", false, [false]]];

if (isNull _group) exitWith {};
if ((units _group) isEqualTo []) exitWith {
    if (_uksf_neverPopulated && {local _group}) then { deleteGroup _group };
};
{ deleteVehicle _x } forEach units _group;
