/*
 * Function: FLO_fnc_logisticsShipmentsNear
 * Author: Frontline Operations Development Group
 * Description:
 *   Drops deleted, destroyed, and delivered crates from the shipment
 *   registry, then returns the undelivered shipments within a 3D radius of
 *   the ground under a position, nearest first. The height of the position
 *   is ignored because node and objective positions do not store a reliable
 *   ground height. A crate loaded into ACE cargo (held 100 m below its
 *   vehicle) stays out of range.
 *
 * Arguments:
 *   0: Centre position; only its map coordinates are used <ARRAY>
 *   1: Radius in metres <NUMBER>
 *
 * Return Value:
 *   Undelivered shipment crates, nearest first <ARRAY>
 *
 * Example:
 *   [getPosATL _node, 20] call FLO_fnc_logisticsShipmentsNear;
 */

params [["_position", [0, 0, 0], [[]], [2, 3]], ["_radius", 0, [0]]];

if (isNil "FLO_LogisticsShipments") exitWith { [] };

FLO_LogisticsShipments = FLO_LogisticsShipments select {
    alive _x && {!(_x getVariable ["FLO_LogisticsDelivered", false])}
};

private _centre = AGLToASL [_position select 0, _position select 1, 0];
private _near = [];
{
    private _distance = (getPosASL _x) vectorDistance _centre;
    if (_distance <= _radius) then { _near pushBack [_distance, _x]; };
} forEach FLO_LogisticsShipments;
_near sort true;
_near apply { _x select 1 }
