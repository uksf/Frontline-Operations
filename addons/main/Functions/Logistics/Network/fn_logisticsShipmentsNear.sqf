/*
 * Function: FLO_fnc_logisticsShipmentsNear
 * Author: Frontline Operations Development Group
 * Description:
 *   Drops deleted, destroyed, and delivered crates from the shipment
 *   registry, then returns the undelivered shipments within a radius of a
 *   position, nearest first.
 *
 * Arguments:
 *   0: Centre position <ARRAY>
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

private _near = [];
{
    private _distance = _x distance2D _position;
    if (_distance <= _radius) then { _near pushBack [_distance, _x]; };
} forEach FLO_LogisticsShipments;
_near sort true;
_near apply { _x select 1 }
