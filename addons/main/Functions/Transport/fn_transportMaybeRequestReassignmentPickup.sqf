/*
 * Function: FLO_fnc_transportMaybeRequestReassignmentPickup
 * Author: Frontline Operations Development Group
 * Description:
 *   Allows foot infantry groups to request a pickup when a new commander order
 *   sends them on a long foot movement.
 *
 * Arguments:
 *   0: Infantry Group ID <STRING>
 *   1: Group Data <HASHMAP>
 *   2: Destination Position <ARRAY>
 *   3: Order Tag <STRING>
 *   4: Attempt <NUMBER> - Optional, retries made while the group moves off a
 *      headless client
 *
 * Return Value:
 *   BOOL - True when transport was assigned
 */

params [
    ["_groupId", "", [""]],
    ["_groupData", createHashMap, [createHashMap]],
    ["_targetPos", [], [[]]],
    ["_orderTag", "", [""]],
    ["_attempt", 0, [0]]
];

if (_groupId == "") exitWith { false };
if (!(_targetPos isEqualType []) || {count _targetPos < 2}) exitWith { false };
if ((_groupData get "groupType") != "infantry") exitWith { false };
if ((_groupData get "attachedTo") != "" || {(_groupData get "mountedIn") != ""}) exitWith { false };

private _distance = (_groupData get "position") distance2D _targetPos;
if (_distance < FLO_Transport_ReassignmentPickupMinDistance) exitWith { false };

private _realGroup = _groupData get "realGroup";
if ((_groupData get "isActive") && {!isNull _realGroup} && {!([[_realGroup]] call FLO_fnc_transportKeepOnServer)}) exitWith {
    if (_attempt >= 5) exitWith { false };
    [{
        params ["_groupId", "_targetPos", "_orderTag", "_attempt"];
        private _groupData = [_groupId] call FLO_fnc_virtualizationFindGroup;
        if (isNil "_groupData") exitWith {};
        if ((_groupData get "commanderOrder") != _orderTag || {(_groupData get "orderTargetPos") isNotEqualTo _targetPos}) exitWith {};
        [_groupId, _groupData, _targetPos, _orderTag, _attempt + 1] call FLO_fnc_transportMaybeRequestReassignmentPickup;
    }, [_groupId, _targetPos, _orderTag, _attempt], 3] call CBA_fnc_waitAndExecute;
    false
};

private _requestSpec = createHashMapFromArray [
    ["orderTag", _orderTag]
];
private _transportId = [_groupId, _targetPos, _requestSpec] call FLO_fnc_transportRequest;
if (_transportId == "") exitWith { false };

["TRANSPORT", 3, format [
    "Assigned reassignment pickup for %1 via %2 (%3, %4m)",
    _groupId,
    _transportId,
    _orderTag,
    round _distance
]] call FLO_fnc_log;

true
