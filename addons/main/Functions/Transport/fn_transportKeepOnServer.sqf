/*
 * Function: FLO_fnc_transportKeepOnServer
 * Author: Frontline Operations Development Group
 * Description:
 *   Holds groups on the server, where the transport code runs its
 *   local-argument commands such as moveInCargo, unassignVehicle and land.
 *   A group that a headless client owns is moved back to the server, and the
 *   call returns false until every unit is local and FLO_Transport_LocalitySettle
 *   seconds have passed. Units change locality after their group, and a unit
 *   seated before its locality settles is pushed out of the vehicle.
 *   The hold lasts for the rest of the group's active life. A group that moves
 *   to a headless client after it leaves a carrier boards that carrier again
 *   there, and then never deactivates. FLO_fnc_virtualizationProcessActiveState
 *   also holds carriers with a transport role from their first active tick.
 *
 * Arguments:
 *   0: Real Groups <ARRAY>
 *
 * Return Value:
 *   BOOL - True when every group is local to the server
 *
 * Example:
 *   [[_passengerGroup, _carrierGroup]] call FLO_fnc_transportKeepOnServer;
 */

params [["_groups", [], [[]]]];

private _allLocal = true;
{
    if (isNull _x) then { continue };
    _x setVariable ["acex_headless_blacklist", true];
    if !(local _x) then {
        ["TRANSPORT", 3, format ["Moving transport group %1 from owner %2 to the server", _x, groupOwner _x]] call FLO_fnc_log;
        _x setGroupOwner 2;
        _x setVariable ["FLO_transportArrivedAt", -1];
        _allLocal = false;
        continue;
    };
    if ((units _x) findIf { !local _x } >= 0) then {
        _allLocal = false;
        continue;
    };
    private _arrivedAt = _x getVariable ["FLO_transportArrivedAt", 0];
    if (_arrivedAt < 0) then {
        _x setVariable ["FLO_transportArrivedAt", time];
        _allLocal = false;
        continue;
    };
    if (time < _arrivedAt + FLO_Transport_LocalitySettle) then {
        _allLocal = false;
    };
} forEach _groups;

_allLocal
