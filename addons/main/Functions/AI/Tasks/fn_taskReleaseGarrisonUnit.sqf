/* Releases one garrison assignment by token, clearing local handlers and restoring AI on the current owner. */
params [["_unit", objNull, [objNull]], ["_token", "", [""]]];

if (isNull _unit) exitWith { true };
if (_token == "") then { _token = _unit getVariable ["FLO_garrisonToken", ""] };
if (_token == "" || {_token != (_unit getVariable ["FLO_garrisonToken", ""])}) exitWith { true };

{
    _x params ["_eventType", "_eventId"];
    _unit removeEventHandler [_eventType, _eventId];
} forEach (_unit getVariable ["FLO_garrisonEventHandlers", []]);

_unit setVariable ["FLO_garrisonEventHandlers", nil];
_unit setVariable ["FLO_garrisonPosition", nil];

if !(local _unit) exitWith {
    [_unit, _token] remoteExecCall ["FLO_fnc_taskReleaseGarrisonUnit", _unit];
    true
};

_unit setVariable ["FLO_garrisonToken", nil, true];
_unit enableAI "PATH";
_unit setUnitPos "AUTO";

true
