/*
 * Function: FLO_fnc_logisticsShipmentsNear
 * Author: Frontline Operations Development Group
 * Description:
 *   Drops deleted, destroyed, and delivered crates from the shipment
 *   registry, then returns the undelivered shipments within a 3D radius of a
 *   delivery centre, nearest first. Crates loaded into ACE vehicle cargo are
 *   never returned. The centre is the anchor object's position when an anchor
 *   is given, otherwise the ground under the position, because node and
 *   objective positions do not store a reliable height.
 *
 * Arguments:
 *   0: Centre position; only its map coordinates are used <ARRAY>
 *   1: Radius in metres <NUMBER>
 *   2: Anchor object that sets the centre, such as a base (optional, default: objNull) <OBJECT>
 *
 * Return Value:
 *   Undelivered shipment crates, nearest first <ARRAY>
 *
 * Example:
 *   [_node get "position", 20, _base] call FLO_fnc_logisticsShipmentsNear;
 */

params [["_position", [0, 0, 0], [[]], [2, 3]], ["_radius", 0, [0]], ["_anchor", objNull, [objNull]]];

if (isNil "FLO_LogisticsShipments") exitWith { [] };

FLO_LogisticsShipments = FLO_LogisticsShipments select {
    alive _x && {!(_x getVariable ["FLO_LogisticsDelivered", false])}
};

private _centre = if (isNull _anchor) then {
    AGLToASL [_position select 0, _position select 1, 0]
} else {
    getPosASL _anchor
};
private _near = [];
{
    private _holder = attachedTo _x;
    if (!isNull _holder && {_x in (_holder getVariable ["ace_cargo_loaded", []])}) then { continue };
    private _distance = (getPosASL _x) vectorDistance _centre;
    if (_distance <= _radius) then { _near pushBack [_distance, _x]; };
} forEach FLO_LogisticsShipments;
_near sort true;
_near apply { _x select 1 }
