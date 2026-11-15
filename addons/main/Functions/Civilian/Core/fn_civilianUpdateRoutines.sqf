/*
 * Function: FLO_fnc_civilianUpdateRoutines
 * Author: Frontline Operations Development Group
 * Description:
 *   Retasks every active civilian group and a rotating batch of inactive civilian groups.
 *
 * Arguments:
 * 0: Civilian manager <HASHMAP>
 *
 * Return Value:
 * NUMBER - Retasked group count
 */

params ["_manager"];

if (isNil "FLO_VirtualForceRegistry") exitWith { 0 };

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _activeCivilianIds = [];
private _inactiveCivilianIds = [];

{
    private _groupId = _x;
    private _groupData = _y;

    if ((_groupData get "side") != civilian) then { continue };
    if !((_groupData get "groupType") in ["civilian", "civ_pedestrian", "civ_building", "civilianVehicle", "civ_car"]) then { continue };

    if (_groupData get "isActive") then {
        _activeCivilianIds pushBack _groupId;
    } else {
        _inactiveCivilianIds pushBack _groupId;
    };
} forEach _groups;

private _retasked = 0;
{
    if (_manager call ["retaskCivilianGroup", [_x, _groups get _x]]) then {
        _retasked = _retasked + 1;
    };
} forEach _activeCivilianIds;

private _inactiveCount = count _inactiveCivilianIds;
if (_inactiveCount > 0) then {
    private _cursor = _manager get "_routineCursor";
    private _batchSize = ((_manager get "CONFIG") get "ROUTINE_BATCH_SIZE") max 1;
    private _iterations = _batchSize min _inactiveCount;

    for "_i" from 0 to (_iterations - 1) do {
        private _idx = (_cursor + _i) mod _inactiveCount;
        private _groupId = _inactiveCivilianIds select _idx;
        if (_manager call ["retaskCivilianGroup", [_groupId, _groups get _groupId]]) then {
            _retasked = _retasked + 1;
        };
    };

    _manager set ["_routineCursor", (_cursor + _iterations) mod _inactiveCount];
} else {
    _manager set ["_routineCursor", 0];
};

_retasked
