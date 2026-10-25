/*
 * Function: FLO_fnc_virtualizationClaimActivationSlot
 * Description:
 *   Claims this frame's activation slot for a group. A new group may start
 *   only FLO_ActivationInterval seconds after the previous one started. A
 *   group that is already staging its units continues on any free frame.
 *
 * Arguments:
 *   0: Group ID <STRING>
 *
 * Return Value:
 *   true when the group may do activation work in this frame <BOOLEAN>
 */

params ["_groupId"];

if ((FLO_VirtUpdate get "lastActivationFrame") == diag_frameNo) exitWith { false };

private _isStaging = _groupId in (FLO_VirtUpdate get "stagedGroups");
if (!_isStaging && {diag_tickTime < (FLO_VirtUpdate get "nextActivationAt")}) exitWith { false };

if (!_isStaging) then {
    FLO_VirtUpdate set ["nextActivationAt", diag_tickTime + (missionNamespace getVariable ["FLO_ActivationInterval", 0.5])];
};
FLO_VirtUpdate set ["lastActivationFrame", diag_frameNo];
true
