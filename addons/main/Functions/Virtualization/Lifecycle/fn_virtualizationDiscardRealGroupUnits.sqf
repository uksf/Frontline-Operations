/*
 * Function: FLO_fnc_virtualizationDiscardRealGroupUnits
 * Description:
 *   Deletes a physical group's units and leaves group removal to the engine.
 *   Groups are created with deleteGroupWhenEmpty, which removes them once the
 *   deferred unit deletions land. An empty group is deleted here, because
 *   the engine never auto-deletes a group that never held units. Call it
 *   only on a group the caller created in the same frame.
 *
 * Arguments:
 *   0: Group <GROUP>
 * Return Value:
 *   None
 */

params [["_group", grpNull, [grpNull]]];

if (isNull _group) exitWith {};
if ((units _group) isEqualTo []) exitWith {
    if (local _group) then { deleteGroup _group };
};
{ deleteVehicle _x } forEach units _group;
