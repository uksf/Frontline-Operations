/*
 * Function: FLO_fnc_virtualizationTakeStagedUnit
 * Description:
 *   Moves a staged crew unit of the requested class from the crew holder of
 *   the activation in progress into the group, shown and simulated at the
 *   position. Creates a new unit when the holder has none of that class.
 *
 * Arguments:
 *   0: Real group <GROUP>
 *   1: Unit class <STRING>
 *   2: Position <ARRAY>
 *
 * Return Value:
 *   The unit, or objNull when the engine refused it <OBJECT>
 */

params ["_realGroup", "_unitType", "_position"];

private _holder = FLO_VirtUpdate getOrDefault ["crewHolder", grpNull];
private _spares = (units _holder) select { alive _x && {typeOf _x == _unitType} };
if (_spares isEqualTo []) exitWith { _realGroup createUnit [_unitType, _position, [], 0, "NONE"] };

private _unit = _spares select 0;
[_unit] joinSilent _realGroup;
_unit setPosATL _position;
_unit enableSimulationGlobal true;
_unit hideObjectGlobal false;
_unit
