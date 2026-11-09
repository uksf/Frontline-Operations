/*
 * Function: FLO_fnc_virtualizationCheckLateSpawn
 * Description:
 *   The one late-spawn rule that every activation path applies. A land
 *   group that waited FLO_VirtLateSpawnWait seconds for activation capacity
 *   must not appear next to players: it is pulled back, or held when no
 *   clear point exists. A staged group is checked again before its units
 *   are revealed, and its stage is discarded when a player has come inside
 *   the clearance while it staged.
 *
 * Arguments:
 *   0: Group ID <STRING>
 *   1: Group Data <HASHMAP>
 *
 * Return Value:
 *   true when the group may spawn or reveal now <BOOLEAN>
 *
 * Example:
 *   ["vgroup_1", _groupData] call FLO_fnc_virtualizationCheckLateSpawn;
 */

params [["_groupId", "", [""]], ["_groupData", createHashMap, [createHashMap]]];

private _stage = (FLO_VirtUpdate get "stagedGroups") getOrDefault [_groupId, createHashMap];
if (_stage isNotEqualTo createHashMap) exitWith {
    private _clearance = (FLO_VirtUpdate get "lateSpawnClearance") getOrDefault [_groupId, 0];
    if (_clearance <= 0 || {([_stage get "position", false, true, true] call FLO_fnc_virtualizationGetNearestCachedPlayerDistance) >= _clearance}) exitWith { true };
    ["VIRTUALIZATION", 3, format ["Discarding late stage %1: a player came inside %2m while it staged", _groupId, _clearance]] call FLO_fnc_log;
    [_groupId] call FLO_fnc_virtualizationDiscardStagedGroup;
    false
};

private _deferredAt = _groupData get "activationDeferredAt";
if (
    !(_groupData get "activationDeferred")
    || {_deferredAt < 0}
    || {(diag_tickTime - _deferredAt) < (missionNamespace getVariable ["FLO_VirtLateSpawnWait", 60])}
) exitWith { true };

[_groupId, _groupData] call FLO_fnc_virtualizationPullBackLateSpawn
