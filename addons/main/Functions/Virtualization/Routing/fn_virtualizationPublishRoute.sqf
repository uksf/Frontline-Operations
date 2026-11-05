/* Publish an already validated route and optional commander fields together. */
params ["_groupId", "_groupData", "_candidate", ["_additionalFields", [], [[]]]];

private _uksf_realGroup = _groupData get "realGroup";
if (!isNull _uksf_realGroup) then {
    _uksf_realGroup setVariable ["uksf_parkToken", (_uksf_realGroup getVariable ["uksf_parkToken", 0]) + 1, true];
};

private _physicalRouteAllowed = true;
if (_candidate get "isActive") then {
    _physicalRouteAllowed = [_groupId, _candidate] call FLO_fnc_virtualizationApplyRealRoute;
};
if (!_physicalRouteAllowed) exitWith { false };

private _oldPosition = _groupData get "position";
private _newPosition = _candidate get "position";
if (!(_candidate get "isActive") && {_newPosition isNotEqualTo _oldPosition}) then {
    if !([_groupId, _groupData, _newPosition] call FLO_fnc_virtualizationUpdateOwnedGroupPosition) then {
        throw format ["Route publication for %1 could not commit its recovered start %2", _groupId, _newPosition];
    };
    ["VIRTUALIZATION", 2, format ["Recovered stranded LAND group=%1 reason=START_IN_WATER distance=%2", _groupId, round (_oldPosition distance2D _newPosition)]] call FLO_fnc_log;
};

private _committedFields = call FLO_fnc_virtualizationGetRouteOwnedFields;
_committedFields append _additionalFields;
_committedFields append ["idleHelicopterParked", "nextProcessAt", "state", "landRouteStartBlocked", "landRouteRetryAt"];
{
    _groupData set [_x, [_candidate get _x] call FLO_fnc_virtualizationCloneValue];
} forEach _committedFields;
[_groupData, _groupId] call FLO_fnc_virtualizationValidateGroup;
call FLO_fnc_virtualizationTouchRegistry;
private _changedFields = ["waypoints", "state"];
_changedFields append _additionalFields;
if (_candidate get "autoPatrol") then {
    _changedFields append ["autoPatrol", "patrolConfig"];
};
[
    "FLO_Virtualization_GroupPatched",
    [_groupId, _changedFields]
] call CBA_fnc_localEvent;

["VIRTUALIZATION", 5, format ["Updated waypoints for virtual group %1", _groupId]] call FLO_fnc_log;
true
