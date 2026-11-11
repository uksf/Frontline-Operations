/*
 * Function: FLO_fnc_virtualizationDeleteRealGroupAssets
 */

params [
    ["_groupData", createHashMap, [createHashMap]],
    ["_realGroup", grpNull, [grpNull]],
    ["_retainDeadEntities", false, [false]]
];

if !([_groupData, _realGroup, false] call FLO_fnc_virtualizationCanDeactivateGroup) then {
    ["VIRTUALIZATION", 1, format ["Refusing entity deletion for %1: player or foreign occupant", _groupData get "id"]] call FLO_fnc_log;
    throw "Virtualization entity deletion crossed group ownership";
};

private _deleteEmptyGroup = !isNull _realGroup && {(units _realGroup) isEqualTo []} && {local _realGroup};
private _vehiclesToDelete = +(_groupData get "realVehicles");
if (!isNull _realGroup) then {
    ["", _realGroup] call FLO_fnc_virtualizationBindRealGroup;
    _vehiclesToDelete append (assignedVehicles _realGroup);
};
if ((_groupData get "realGroup") isEqualTo _realGroup) then {
    [_groupData] call FLO_fnc_virtualizationClearRealGroup;
};
_vehiclesToDelete = _vehiclesToDelete arrayIntersect _vehiclesToDelete;
private _entitiesToDelete = [];
{
    private _veh = vehicle _x;
    if (_veh == _x) then {
        _veh = assignedVehicle _x;
    };

    if (!isNull _veh) then {
        _vehiclesToDelete pushBackUnique _veh;
    };
} forEach units _realGroup;

{
    private _veh = _x;
    if (isNull _veh) then { continue };
    if (_retainDeadEntities && {!alive _veh}) then {
        [_veh, "wreck"] call FLO_fnc_aftermathRegisterEntity;
        continue;
    };

    {
        if (_retainDeadEntities && {!alive _x}) then {
            moveOut _x;
            [_x, "corpse"] call FLO_fnc_aftermathRegisterEntity;
            continue;
        };
        _x hideObjectGlobal true;
        _entitiesToDelete pushBackUnique _x;
    } forEach (crew _veh);

    _veh hideObjectGlobal true;
    _entitiesToDelete pushBackUnique _veh;
} forEach _vehiclesToDelete;

{
    if (isNull _x) then { continue };
    if (_retainDeadEntities && {!alive _x}) then {
        [_x, "corpse"] call FLO_fnc_aftermathRegisterEntity;
        continue;
    };
    _x hideObjectGlobal true;
    _entitiesToDelete pushBackUnique _x;
} forEach units _realGroup;

deleteVehicle _entitiesToDelete;

if (_deleteEmptyGroup) then { deleteGroup _realGroup };

true
