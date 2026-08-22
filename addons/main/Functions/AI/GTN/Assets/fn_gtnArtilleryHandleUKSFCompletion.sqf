/* Handles completion of a live UKSF walking-fire request. */
params [
    ["_requestId", "", [""]],
    ["_artillery", objNull, [objNull]],
    ["_success", false, [false]],
    ["_roundsFired", 0, [0]],
    ["_reason", "", [""]],
    ["_context", [], [[]]]
];

if (!isServer || {isNil "FLO_GTNArtilleryManager"}) exitWith {};

private _manager = FLO_GTNArtilleryManager;
private _missions = _manager get "missions";
private _groupId = _context param [0, "", [""]];

if (_groupId == "" || {!(_groupId in _missions)}) then {
    {
        private _mission = _missions get _x;
        if ((_mission get "missionId") == _requestId) exitWith {
            _groupId = _x;
        };
    } forEach (keys _missions);
};

if (_groupId == "" || {!(_groupId in _missions)}) exitWith {
    ["GTN Artillery", 2, format ["Ignored unknown UKSF artillery completion %1", _requestId]] call FLO_fnc_log;
};

private _missionRecord = _missions get _groupId;
if ((_missionRecord get "missionId") != _requestId) exitWith {
    ["GTN Artillery", 1, format ["UKSF artillery completion %1 did not match battery %2", _requestId, _groupId]] call FLO_fnc_log;
};

_missionRecord set ["roundsFired", _roundsFired];
_missionRecord set ["fireSucceeded", _success];
_missionRecord set ["fireFailureReason", _reason];

["GTN Artillery", [3, 2] select !_success, format [
    "UKSF walking-fire mission %1 completed for %2: success=%3 rounds=%4 reason=%5",
    _requestId,
    _groupId,
    _success,
    _roundsFired,
    _reason
]] call FLO_fnc_log;

_manager call ["_cleanupMission", [_groupId, _artillery]];
