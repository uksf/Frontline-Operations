/* Releases one live unit from FLO-owned physical building-garrison state.
   Handlers stay on the machine that assigned the garrison; the AI state is
   restored where the unit is local, which differs after an HC transfer. */
params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith { true };

{
    _x params ["_eventType", "_eventId"];
    _unit removeEventHandler [_eventType, _eventId];
} forEach (_unit getVariable ["FLO_garrisonEventHandlers", []]);

_unit setVariable ["FLO_garrisonEventHandlers", nil];
_unit setVariable ["FLO_garrisonPosition", nil];

if !(local _unit) exitWith {
    [_unit] remoteExecCall ["FLO_fnc_taskReleaseGarrisonUnit", _unit];
    true
};

_unit enableAI "PATH";
_unit setUnitPos "AUTO";

true
