/*
 * Function: FLO_fnc_virtualizationTrackUnitLoss
 * Description: Clears a tracked group's handle when its final indexed unit is lost.
 * Arguments: 0: Unit <OBJECT>, 1: Expected entry <ARRAY> (optional)
 * Return Value: None
 */

params ["_unit", ["_expected", []]];
private _entry = FLO_VirtualizationUnitIndex get _unit;
if (isNil "_entry") exitWith {};
if (_expected isNotEqualTo [] && {!(_entry isEqualRef _expected)}) exitWith {};
FLO_VirtualizationUnitIndex deleteAt _unit;
_entry params ["", "_members", "_groupData"];
_members deleteAt _unit;
if (count _members > 0) exitWith {};
[_groupData] call FLO_fnc_virtualizationClearRealGroup;
