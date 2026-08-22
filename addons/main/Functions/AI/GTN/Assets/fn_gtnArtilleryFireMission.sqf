/*
    Function: FLO_fnc_gtnArtilleryFireMission

    Description:
    Prepares a live FLO artillery group and delegates physical firing to the
    UKSF walking-fire request API. FLO cleanup resumes from the completion
    event.

    Arguments:
    0: Group ID <STRING>
    1: Group Data <HASHMAP>
    2: Real Group <GROUP>
    3: Target Position <ARRAY>
    4: Number of rounds <NUMBER>
    5: Accuracy/dispersion in meters <NUMBER>
    6: Fire plan <HASHMAP>
    7: Artillery Manager reference <HASHMAP>

    Example:
    [_gid, _gdata, _realGroup, _targetPos, 6, 100, _firePlan, _mgr] spawn FLO_fnc_gtnArtilleryFireMission;
*/

params ["_gid", "_gdata", "_realGroup", "_targetPos", "_rounds", "_accuracy", ["_firePlan", createHashMap], "_mgr"];

if ((keys _firePlan) isEqualTo []) then {
    _firePlan = [_realGroup, _targetPos, _rounds, _accuracy] call FLO_fnc_gtnBuildArtilleryFirePlan;
};

private _vehiclePlans = [];
if ((keys _firePlan) isNotEqualTo []) then {
    _vehiclePlans = _firePlan get "vehiclePlans";
};

if (_vehiclePlans isEqualTo []) exitWith {
    ["GTN Artillery", 1, format["Artillery %1 - no valid vehicles found in group of %2 units", _gid, count units _realGroup]] call FLO_fnc_log;
    [_gdata] call FLO_fnc_virtualizationClearMissionLock;
    private _missionRecord = (_mgr get "missions") get _gid;
    (_mgr get "missions") deleteAt _gid;
    if (!isNil "_missionRecord") then {
        ["FLO_GTN_ArtilleryMissionStateChanged", [_missionRecord get "side", _missionRecord get "missionId", "COMPLETED"]] call CBA_fnc_localEvent;
    };
};

["GTN Artillery", 3, format["Artillery %1 - found %2 valid guns", _gid, count _vehiclePlans]] call FLO_fnc_log;

private _missionRecord = (_mgr get "missions") get _gid;
if (isNil "_missionRecord") exitWith {
    ["GTN Artillery", 1, format ["Artillery %1 has no registered mission", _gid]] call FLO_fnc_log;
    [_gdata] call FLO_fnc_virtualizationClearMissionLock;
};

// === PHASE 2: Clear patrol and waypoints ===
if !([_gid, [], true, "GTN_ARTILLERY_FIRE"] call FLO_fnc_updateVirtualGroupWaypoints) exitWith {
    [
        _missionRecord get "missionId",
        objNull,
        false,
        0,
        "Battery route clear was rejected",
        [_gid]
    ] call FLO_fnc_gtnArtilleryHandleUKSFCompletion;
};

// Clear the FLO_patrolConfig variable from real group
_realGroup setVariable ["FLO_patrolConfig", nil, true];

// Clear existing waypoints
[_realGroup] call CBA_fnc_clearWaypoints;

// Stop movement
{ doStop _x; } forEach units _realGroup;

["GTN Artillery", 3, format["Artillery %1 - cleared patrol/waypoints", _gid]] call FLO_fnc_log;

private _artillery = (_vehiclePlans select 0) get "vehicle";
private _gunner = gunner _artillery;
private _missionId = _missionRecord get "missionId";
private _plannedRounds = _missionRecord get "plannedRounds";

if (isNull _artillery || {isNull _gunner}) exitWith {
    [_missionId, _artillery, false, 0, "Selected battery has no live gun", [_gid]] call FLO_fnc_gtnArtilleryHandleUKSFCompletion;
};

["GTN Artillery", 3, format [
    "Artillery %1 delegated mission %2 (%3 rounds) to UKSF walking fire",
    _gid,
    _missionId,
    _plannedRounds
]] call FLO_fnc_log;

[
    "uksf_mission_requestFireMission",
    [_artillery, _artillery, _targetPos, _missionId, _plannedRounds, [_gid]],
    _gunner
] call CBA_fnc_targetEvent;
