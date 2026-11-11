/*
 * Function: FLO_fnc_virtualizationTrackUnitLoss
 * Description: Clears a tracked group's handle when its final tracked unit is lost.
 * Arguments: 0: Unit <OBJECT>, 1: Expected entry <ARRAY> (optional)
 * Return Value: None
 */

params ["_unit", ["_expected", []]];
private _entry = _unit getVariable "FLO_virtualEntry";
if (isNil "_entry") exitWith {};
if (_expected isNotEqualTo [] && {!(_entry isEqualRef _expected)}) exitWith {};
_unit setVariable ["FLO_virtualEntry", nil];
_entry params ["", "_remaining", "_groupData", "_live"];
if !(_live select 0) exitWith {};
_remaining set [0, (_remaining select 0) - 1];
if ((_remaining select 0) > 0) exitWith {};
_live set [0, false];
[_groupData] call FLO_fnc_virtualizationClearRealGroup;
