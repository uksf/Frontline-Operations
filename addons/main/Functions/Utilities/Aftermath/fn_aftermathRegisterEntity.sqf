/*
 * Function: FLO_fnc_aftermathRegisterEntity
 * Author: Frontline Operations Development Group
 * Description:
 *   Registers a corpse, wreck, or weapon holder for FLO-owned cleanup.
 *
 * Arguments:
 * 0: Entity <OBJECT>
 * 1: Kind <STRING> - "corpse", "wreck", or "weaponHolder"
 *
 * Return Value:
 * BOOL - True when the entity is tracked
 */

params [
    ["_entity", objNull, [objNull]],
    ["_kind", "", [""]]
];

if (!isServer) exitWith { false };
if (isNull _entity) exitWith { false };
if (_entity getVariable ["FLO_NoAftermathCleanup", false]) exitWith { false };

private _isKindValid = switch (_kind) do {
    case "corpse": { !alive _entity && {_entity isKindOf "CAManBase"} };
    case "wreck": { !alive _entity && {_entity isKindOf "LandVehicle" || {_entity isKindOf "Air"} || {_entity isKindOf "Ship"}} };
    case "weaponHolder": { _entity isKindOf "GroundWeaponHolder" || {_entity isKindOf "WeaponHolder"} || {_entity isKindOf "WeaponHolderSimulated"} };
    default { false };
};

if (!_isKindValid) exitWith { false };

private _state = FLO_AftermathCleanup;
private _trackedEntities = _state get "trackedEntities";
private _entityKey = str _entity;

if (isNil { _trackedEntities get _entityKey }) then {
    _trackedEntities set [_entityKey, [_entity, diag_tickTime, _kind]];
};

true
