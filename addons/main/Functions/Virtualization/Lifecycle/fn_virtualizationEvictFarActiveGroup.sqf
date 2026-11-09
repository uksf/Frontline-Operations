/*
 * Function: FLO_fnc_virtualizationEvictFarActiveGroup
 * Description:
 *   Frees cap space for a group waiting near a player. Deactivates the active
 *   group that is farthest from every player, when it is outside its own
 *   activation range and has no combat, mission, transport, or staging hold.
 *   Runs at most once per FLO_VirtEvictionInterval seconds.
 *
 * Arguments:
 *   0: Group ID of the waiting group <STRING>
 *
 * Return Value:
 *   true when a group was deactivated <BOOLEAN>
 *
 * Example:
 *   ["vgroup_1"] call FLO_fnc_virtualizationEvictFarActiveGroup;
 */

params [["_waitingGroupId", "", [""]]];

if (diag_tickTime < (FLO_VirtUpdate get "nextEvictionAt")) exitWith { false };
FLO_VirtUpdate set ["nextEvictionAt", diag_tickTime + (missionNamespace getVariable ["FLO_VirtEvictionInterval", 2])];

private _activationDist = ["activationDistance"] call FLO_fnc_virtualizationGetConfigValue;
private _stagedGroups = FLO_VirtUpdate get "stagedGroups";
private _combatActivations = FLO_VirtUpdate get "combatActivations";
private _bestId = "";
private _bestData = createHashMap;
private _bestMargin = 0;
{
    private _groupData = _y;
    private _realGroup = _groupData get "realGroup";
    if (
        (_groupData get "isActive")
        && {!isNull leader _realGroup}
        && {!(_groupData get "alwaysActive")}
        && {!(_groupData get "inCombat")}
        && {(_groupData get "missionLock") == ""}
        && {(_groupData get "replacementState") == ""}
        && {(_groupData get "attachedTo") == ""}
        && {(_groupData get "mountedIn") == ""}
        && {(_groupData get "attachedGroups") isEqualTo []}
        && {!(_x in _stagedGroups)}
        && {!(_x in _combatActivations)}
    ) then {
        private _airGroup = (_groupData get "groupType") in ["helicopter", "air", "jet"];
        private _groupActivationDist = [_activationDist, _activationDist * FLO_AirActivationDistanceMultiplier] select _airGroup;
        private _dist = [getPosATL vehicle leader _realGroup, _airGroup, false, true] call FLO_fnc_virtualizationGetNearestCachedPlayerDistance;
        private _margin = _dist - _groupActivationDist;
        if (_margin > 50 && {_margin > _bestMargin}) then {
            _bestId = _x;
            _bestData = _groupData;
            _bestMargin = _margin;
        };
    };
} forEach ([] call FLO_fnc_virtualizationGetGroupMap);

if (_bestId == "") exitWith { false };

private _load = [_bestData, true] call FLO_fnc_virtualizationGetGroupUnitLoad;
["VIRTUALIZATION", 3, format ["Evicting %1 (%2m beyond activation range) for %3", _bestId, round _bestMargin, _waitingGroupId]] call FLO_fnc_log;
if !([_bestId, _bestData] call FLO_fnc_deactivateVirtualGroup) exitWith { false };

private _virtStats = FLO_VirtUpdate get "stats";
FLO_VirtUpdate set ["activeUnitCount", ((FLO_VirtUpdate get "activeUnitCount") - _load) max 0];
_virtStats set ["deactivationsTotal", (_virtStats get "deactivationsTotal") + 1];
_virtStats set ["deactivationsThisBatch", (_virtStats get "deactivationsThisBatch") + 1];
_virtStats set ["activeUnitsLast", FLO_VirtUpdate get "activeUnitCount"];
true
