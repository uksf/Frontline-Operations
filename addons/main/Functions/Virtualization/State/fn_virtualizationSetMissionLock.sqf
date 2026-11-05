/*
 * Function: FLO_fnc_virtualizationSetMissionLock
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies the canonical subsystem mission lock to a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Mission owner <STRING>
 * 2: Mission type <STRING>
 *
 * Return Value:
 * BOOL - True when the lock was applied
 */

params ["_groupData", "_owner", ["_type", ""]];

private _uksf_realGroup = _groupData get "realGroup";
if (!isNull _uksf_realGroup) then {
    _uksf_realGroup setVariable ["uksf_parkToken", (_uksf_realGroup getVariable ["uksf_parkToken", 0]) + 1, true];
};

_groupData set ["missionLock", _owner];
_groupData set ["missionType", _type];

true
