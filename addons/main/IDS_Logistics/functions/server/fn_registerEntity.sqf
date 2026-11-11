/*
 * Function: IDS_Logistics_fnc_registerEntity
 * Author: Frontline Operations Development Group
 * Description: Registers a structure and removes deleted structures from tracking.
 * Parameters: 0: Entity <OBJECT>
 * Return value: Nothing
 * Example: [_entity] call IDS_Logistics_fnc_registerEntity
 */
params ["_entity"];
if (isNil "IDS_Logistics_EntityDeletedEH") then {
    IDS_Logistics_EntityDeletedEH = addMissionEventHandler ["EntityDeleted", {
        params ["_entity"];
        IDS_Logistics_PlacedEntities = IDS_Logistics_PlacedEntities - [_entity];
        IDS_Logistics_ManipulatedEntities = IDS_Logistics_ManipulatedEntities - [_entity];
    }];
};
IDS_Logistics_PlacedEntities pushBackUnique _entity;
if (isNil { _entity getVariable "IDS_Logistics_KilledEH" }) then {
    private _handler = _entity addEventHandler ["Killed", {
        params ["_unit"];
        [_unit] call IDS_Logistics_fnc_onEntityKilled;
    }];
    _entity setVariable ["IDS_Logistics_KilledEH", _handler];
};
