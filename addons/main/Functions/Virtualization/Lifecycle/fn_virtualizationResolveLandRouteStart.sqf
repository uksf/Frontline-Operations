/*
 * Function: FLO_fnc_virtualizationResolveLandRouteStart
 * Description:
 *   Returns the position a captured LAND route starts from. A group standing
 *   in water starts from the nearest shore within 500 m, so wading units do
 *   not make the route invalid. With no shore in reach, the position is
 *   returned unchanged.
 *
 * Arguments:
 *   0: Group position <ARRAY>
 *
 * Return Value:
 *   Route start position <ARRAY>
 */

params ["_position"];

if !([_position] call FLO_fnc_isRouteWater) exitWith { _position };
private _shore = [_position, 500] call FLO_fnc_getSafeLandPos;
if (([_shore] call FLO_fnc_isRouteWater) || {(_shore distance2D _position) > 500}) exitWith { _position };
[_shore select 0, _shore select 1, 0]
