/*
 * Function: FLO_fnc_civilianRunProtestBehavior
 * Author: Frontline Operations Development Group
 * Description:
 *   Starts bounded protest behavior for one active civilian unit. Runs the
 *   first step now, then one step every 2 seconds until the protest expires.
 *
 * Arguments:
 * 0: Civilian unit <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_unit", objNull, [objNull]]];
if (isNull _unit || {!alive _unit}) exitWith {};

if ([_unit, -1] call FLO_fnc_civilianProtestBehaviorTick) then {
    [{
        params ["_args", "_handle"];
        [_args select 0, _handle] call FLO_fnc_civilianProtestBehaviorTick;
    }, 2, [_unit]] call CBA_fnc_addPerFrameHandler;
};
