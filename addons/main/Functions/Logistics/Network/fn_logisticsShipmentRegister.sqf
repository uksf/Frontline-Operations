/*
 * Function: FLO_fnc_logisticsShipmentRegister
 * Author: Frontline Operations Development Group
 * Description:
 *   Adds a supply shipment crate to the server shipment registry, which the
 *   delivery checks read instead of searching the map around every node and
 *   development objective.
 *
 * Arguments:
 *   0: Shipment crate <OBJECT>
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [_shipment] call FLO_fnc_logisticsShipmentRegister;
 */

params [["_shipment", objNull, [objNull]]];

if (!isServer || {isNull _shipment}) exitWith {};
if (isNil "FLO_LogisticsShipments") then { FLO_LogisticsShipments = []; };
FLO_LogisticsShipments pushBackUnique _shipment;
