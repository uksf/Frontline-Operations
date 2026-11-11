/*
 * Function: FLO_fnc_virtualizationBindRealGroup
 * Description: Tracks physical group membership and notifications until teardown.
 * Arguments: 0: Virtual group ID <STRING>, 1: Physical group <GROUP>
 * Return Value: BOOL
 */
params ["_groupId", "_realGroup"];

if (isNil "FLO_VirtualizationUnitIndex") then {
    FLO_VirtualizationUnitIndex = createHashMap;
    addMissionEventHandler ["EntityDeleted", {
        params ["_entity"];
        [_entity] call FLO_fnc_virtualizationTrackUnitLoss;
    }];
};

private _oldMembers = _realGroup getVariable ["FLO_virtualMembers", createHashMap];
private _oldEntry = _realGroup getVariable ["FLO_virtualEntry", []];
{
    private _indexedEntry = FLO_VirtualizationUnitIndex get _x;
    if (!isNil "_indexedEntry" && {_indexedEntry isEqualRef _oldEntry}) then {
        FLO_VirtualizationUnitIndex deleteAt _x;
    };
} forEach keys _oldMembers;
{
    _x params ["_event", "_variable"];
    private _oldHandler = _realGroup getVariable [_variable, -1];
    if (_oldHandler >= 0) then { _realGroup removeEventHandler [_event, _oldHandler] };
    _realGroup setVariable [_variable, nil];
} forEach [
    ["Empty", "FLO_virtualEmptyHandler"],
    ["UnitKilled", "FLO_virtualKilledHandler"],
    ["UnitJoined", "FLO_virtualJoinedHandler"],
    ["UnitLeft", "FLO_virtualLeftHandler"]
];
_realGroup setVariable ["FLO_virtualMembers", nil];
_realGroup setVariable ["FLO_virtualEntry", nil];
_realGroup setVariable ["FLO_virtualGroupId", _groupId];
if (_groupId == "") exitWith { true };

private _members = createHashMap;
private _groupData = [_groupId] call FLO_fnc_virtualizationRequireGroup;
private _entry = [_groupId, _members, _groupData];
{
    if (alive _x) then {
        [_x] call FLO_fnc_virtualizationTrackUnitLoss;
        _members set [_x, true];
        FLO_VirtualizationUnitIndex set [_x, _entry];
    };
} forEach units _realGroup;
_realGroup setVariable ["FLO_virtualMembers", _members];
_realGroup setVariable ["FLO_virtualEntry", _entry];

private _empty = _realGroup addEventHandler ["Empty", {
    params ["_group"];
    private _entry = _group getVariable "FLO_virtualEntry";
    if (!isNil "_entry") then {
        [_entry select 2] call FLO_fnc_virtualizationClearRealGroup;
    };
}];
_realGroup setVariable ["FLO_virtualEmptyHandler", _empty];
private _killed = _realGroup addEventHandler ["UnitKilled", {
    params ["_group", "_unit"];
    [_unit, _group getVariable ["FLO_virtualEntry", []]] call FLO_fnc_virtualizationTrackUnitLoss;
}];
_realGroup setVariable ["FLO_virtualKilledHandler", _killed];
private _joined = _realGroup addEventHandler ["UnitJoined", {
    params ["_group", "_unit"];
    private _entry = _group getVariable "FLO_virtualEntry";
    [_unit] call FLO_fnc_virtualizationTrackUnitLoss;
    (_entry select 1) set [_unit, true];
    FLO_VirtualizationUnitIndex set [_unit, _entry];
}];
_realGroup setVariable ["FLO_virtualJoinedHandler", _joined];
private _left = _realGroup addEventHandler ["UnitLeft", {
    params ["_group", "_unit"];
    [_unit, _group getVariable ["FLO_virtualEntry", []]] call FLO_fnc_virtualizationTrackUnitLoss;
}];
_realGroup setVariable ["FLO_virtualLeftHandler", _left];
true
