/*
 * Function: FLO_fnc_gtnAirMissionTimerTick
 * Description:
 *   One 5-second step of a live air mission: travel to the target area, then
 *   hold on station for the mission duration, checking every 10 seconds.
 *   Removes its per-frame handler when the mission ends, the aircraft dies,
 *   or the mission returns to virtual.
 *
 * Arguments:
 *   0: Timer state <HASHMAP>
 *   1: Per-frame handler id <NUMBER>
 */

params ["_state", "_handle"];

private _a = _state get "aircraft";
private _gid = _state get "gid";
private _missionType = _state get "missionType";
private _targetPos = _state get "targetPos";
private _targetSide = _state get "targetSide";
private _phase = _state get "phase";

private _finish = {
    [_handle] call CBA_fnc_removePerFrameHandler;
    if (!isNil "_gid" && {_gid != ""}) then {
        (call FLO_fnc_gtnAirAssetManager) call ["_releaseAirAsset", [_gid]];
    };
};
private _alertIfDetected = {
    if (!(_state get "alertSent") && {_targetSide in [east, west]} && {[_a, _targetPos, _targetSide] call FLO_fnc_gtnCanSideDetectAirThreat}) then {
        [_targetPos, _missionType, _targetSide] call FLO_fnc_gtnAlertIncomingAircraft;
        _state set ["alertSent", true];
    };
};
private _revirtualized = {
    params ["_remainingMissionSeconds"];
    private _presenceResult = [_a, _gid, _missionType, _targetPos, _remainingMissionSeconds, _state get "noPlayerSince"] call FLO_fnc_gtnAirTryRevirtualizeLiveMission;
    _presenceResult params ["_transitioned", "_nextNoPlayerSince"];
    _state set ["noPlayerSince", _nextNoPlayerSince];
    if (_transitioned) then { [_handle] call CBA_fnc_removePerFrameHandler };
    _transitioned
};

if (_phase == "travel") exitWith {
    if (!alive _a) exitWith {
        ["GTN ATO", 3, format["Aircraft %1 destroyed en route", _gid]] call FLO_fnc_log;
        call _finish;
    };
    private _maxTravelTime = _state get "maxTravelTime";
    private _elapsed = time - (_state get "travelStart");
    if ([((_maxTravelTime - _elapsed) max 0) + (_state get "duration")] call _revirtualized) exitWith {};
    call _alertIfDetected;
    if (((getPos _a) distance2D _targetPos) >= (_state get "arrivalRadius") && {_elapsed <= _maxTravelTime}) exitWith {};

    call _alertIfDetected;
    private _duration = _state get "duration";
    private _requestSide = _state get "requestSide";
    ["GTN ATO", 3, format["Aircraft %1 on station, mission timer started: %2s", _gid, _duration]] call FLO_fnc_log;
    if (_state get "hasPlayerSupportMeta") then {
        [_requestSide, "HQ", format ["%1 on station over %2.", toUpper _missionType, _state get "targetLabel"]] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
    };
    private _commander = [_requestSide] call FLO_fnc_gtnGetCommanderBySide;
    [_targetPos, 1500, crew _a, _commander get "_worldState"] call FLO_fnc_gtnRevealIntelToUnits;
    _state set ["phase", "station"];
    _state set ["missionEnd", time + _duration];
    _state set ["nextCheckAt", time + 10];
};

if (time < (_state get "nextCheckAt") && {alive _a}) exitWith {};
_state set ["nextCheckAt", time + 10];
private _missionEnd = _state get "missionEnd";
if (alive _a && {[(_missionEnd - time) max 0] call _revirtualized}) exitWith {};
if (alive _a && {time < _missionEnd}) exitWith {};

private _reason = if (!alive _a) then { "aircraft destroyed" } else { format["mission complete (%1s on station)", _state get "duration"] };
["GTN ATO", 3, format["Mission ended for %1: %2", _gid, _reason]] call FLO_fnc_log;
call _finish;
