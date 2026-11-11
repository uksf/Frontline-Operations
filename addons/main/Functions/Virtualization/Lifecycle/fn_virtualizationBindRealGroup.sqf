/*
 * Function: FLO_fnc_virtualizationBindRealGroup
 * Description: Tracks physical group membership and notifications until teardown.
 * Arguments: 0: Virtual group ID <STRING>, 1: Physical group <GROUP>
 * Return Value: BOOL
 */
params ["_groupId", "_realGroup"];

if (isNil "FLO_VirtualizationUnitLossHandlers") then {
    FLO_VirtualizationUnitLossHandlers = [
        addMissionEventHandler ["EntityKilled", {
            params ["_entity"];
            [_entity] call FLO_fnc_virtualizationTrackUnitLoss;
        }],
        addMissionEventHandler ["EntityDeleted", {
            params ["_entity"];
            [_entity] call FLO_fnc_virtualizationTrackUnitLoss;
        }]
    ];
};

private _oldEntry = _realGroup getVariable ["FLO_virtualEntry", []];
if (_oldEntry isNotEqualTo []) then {
    (_oldEntry select 3) set [0, false];
    {
        private _unitEntry = _x getVariable "FLO_virtualEntry";
        if (!isNil "_unitEntry" && {_unitEntry isEqualRef _oldEntry}) then {
            _x setVariable ["FLO_virtualEntry", nil];
        };
    } forEach units _realGroup;
};
{
    _x params ["_event", "_variable"];
    private _oldHandler = _realGroup getVariable [_variable, -1];
    if (_oldHandler >= 0) then { _realGroup removeEventHandler [_event, _oldHandler] };
    _realGroup setVariable [_variable, nil];
} forEach [
    ["Empty", "FLO_virtualEmptyHandler"],
    ["UnitJoined", "FLO_virtualJoinedHandler"],
    ["UnitLeft", "FLO_virtualLeftHandler"]
];
_realGroup setVariable ["FLO_virtualEntry", nil];
_realGroup setVariable ["FLO_virtualGroupId", _groupId];
if (_groupId == "") exitWith { true };

private _groupData = [_groupId] call FLO_fnc_virtualizationRequireGroup;
private _entry = [_groupId, [0], _groupData, [true]];
{
    if (alive _x) then {
        [_x] call FLO_fnc_virtualizationTrackUnitLoss;
        _x setVariable ["FLO_virtualEntry", _entry];
        (_entry select 1) set [0, ((_entry select 1) select 0) + 1];
    };
} forEach units _realGroup;
_realGroup setVariable ["FLO_virtualEntry", _entry];

private _empty = _realGroup addEventHandler ["Empty", {
    params ["_group"];
    private _entry = _group getVariable "FLO_virtualEntry";
    if (isNil "_entry" || {!((_entry select 3) select 0)}) exitWith {};
    (_entry select 3) set [0, false];
    [_entry select 2] call FLO_fnc_virtualizationClearRealGroup;
}];
_realGroup setVariable ["FLO_virtualEmptyHandler", _empty];
private _joined = _realGroup addEventHandler ["UnitJoined", {
    params ["_group", "_unit"];
    private _entry = _group getVariable "FLO_virtualEntry";
    if (isNil "_entry" || {!alive _unit}) exitWith {};
    [_unit] call FLO_fnc_virtualizationTrackUnitLoss;
    _unit setVariable ["FLO_virtualEntry", _entry];
    (_entry select 1) set [0, ((_entry select 1) select 0) + 1];
}];
_realGroup setVariable ["FLO_virtualJoinedHandler", _joined];
private _left = _realGroup addEventHandler ["UnitLeft", {
    params ["_group", "_unit"];
    [_unit, _group getVariable ["FLO_virtualEntry", []]] call FLO_fnc_virtualizationTrackUnitLoss;
}];
_realGroup setVariable ["FLO_virtualLeftHandler", _left];
true
