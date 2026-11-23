/*
 * Function: FLO_fnc_civilianProtestBehaviorTick
 * Author: Frontline Operations Development Group
 * Description:
 *   One 2-second step of protest behavior for one active civilian unit.
 *   When the protest ends, restores the unit and removes its per-frame
 *   handler.
 *
 * Arguments:
 * 0: Civilian unit <OBJECT>
 * 1: Per-frame handler id, or -1 before the handler exists <NUMBER>
 *
 * Return Value:
 * True while the protest continues <BOOL>
 */

params [["_unit", objNull, [objNull]], ["_handle", -1, [0]]];

private _expiresAt = _unit getVariable ["FLO_ProtestExpiresAt", -1];
private _target = _unit getVariable ["FLO_ProtestTarget", objNull];
private _continues = alive _unit
    && {_unit getVariable ["FLO_isProtester", false]}
    && {_expiresAt >= 0}
    && {diag_tickTime < _expiresAt}
    && {!isNull _target}
    && {alive _target};

if (!_continues) exitWith {
    if (_handle >= 0) then { [_handle] call CBA_fnc_removePerFrameHandler };
    _unit setVariable ["FLO_isProtester", false, true];
    _unit setVariable ["FLO_ProtestTarget", objNull, false];
    _unit setVariable ["FLO_ProtestExpiresAt", -1, false];
    _unit setVariable ["FLO_ProtestLastAnimAt", -1, false];
    _unit setVariable ["FLO_ProtestWorkerRunning", false, false];

    // Detention owns movement and animation once it has stopped the protest.
    if (alive _unit && {!captive _unit} && {!(_unit getVariable ["FLO_CivilianDetained", false])}) then {
        _unit switchMove "";
        _unit enableAI "PATH";
        _unit enableAI "MOVE";
        _unit setBehaviour "SAFE";
        _unit setSpeedMode "LIMITED";
        [[_unit]] call FLO_fnc_civilianActions;
    };
    false
};

detach _unit;
_unit enableAI "PATH";
_unit enableAI "MOVE";
_unit setBehaviour "CARELESS";
_unit setSpeedMode "NORMAL";

private _targetPos = getPosATL _target;
private _distance = _unit distance2D _target;

if (_distance > 12) exitWith {
    private _gatherPos = _targetPos getPos [6 + random 10, random 360];
    _gatherPos set [2, 0];
    _unit doMove _gatherPos;
    true
};

doStop _unit;
_unit setDir (_unit getDir _target);

private _lastAnimAt = _unit getVariable ["FLO_ProtestLastAnimAt", -1];
if ((_lastAnimAt + 4) < diag_tickTime) then {
    _unit setVariable ["FLO_ProtestLastAnimAt", diag_tickTime, false];
    _unit playMove (selectRandom ["Acts_Excited_Loop", "Acts_CivilListening_1", "Acts_CivilTalking_1", "Acts_CivilTalking_2", "Acts_Ambient_Aggressive"]);
};

private _lastThrowAt = _unit getVariable ["FLO_ProtestLastThrowAt", -1];
if ((_lastThrowAt + 8) < diag_tickTime && {_distance < 35} && {(random 1) < (FLO_CivilianConfig get "PROTEST_THROW_CHANCE")}) then {
    private _throwDir = _unit getDir _target;
    // Probably don't throw literal house sized rocks at them LOL.
    private _throwable = selectRandom ["GrenadeHand_stone", "GrenadeHand_stone", "Land_BottlePlastic_V1_F", "Land_BottlePlastic_V2_F"];
    private _proj = createVehicle [_throwable, (getPosATL _unit) vectorAdd [0, 0, 1.5], [], 0, "CAN_COLLIDE"];
    if (_proj isKindOf "GrenadeHand_stone") then { _proj setShotParents [_unit, _unit] };
    _proj setVelocity [
        (sin _throwDir) * (7 + random 2),
        (cos _throwDir) * (7 + random 2),
        3 + random 2
    ];
    _unit setVariable ["FLO_ProtestLastThrowAt", diag_tickTime, false];
    _unit playMove "Acts_Ambient_Aggressive";

    [{ if (!isNull _this) then { deleteVehicle _this } }, _proj, 10] call CBA_fnc_waitAndExecute;
};

true
