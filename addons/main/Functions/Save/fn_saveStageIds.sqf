/* Save stage: IDS Logistics placed entities.
 * Arguments: 0: Save context <HASHMAP>
 * Returns: <BOOL> - true when the stage is complete
 */
params ["_ctx"];

try {
    if !(IDS_Logistics_PlacedEntities isEqualType []) then {
        throw format [
            "IDS Logistics registry has invalid type %1",
            typeName IDS_Logistics_PlacedEntities
        ];
    };
    private _idsEntities = [];
    {
        if (!isNull _x && alive _x) then {
            _idsEntities pushBack createHashMapFromArray [
                ["class", typeOf _x],
                ["posASL", getPosASL _x],
                ["direction", getDir _x],
                ["vectorUp", vectorUp _x],
                ["damage", damage _x]
            ];
        };
    } forEach IDS_Logistics_PlacedEntities;
    (_ctx get "data") set ["idsLogisticsEntities", _idsEntities];
    ["SAVE", 3, format ["IDS Logistics: %1 placed entities", count _idsEntities]] call FLO_fnc_log;
} catch { throw format ["[SAVE] IDS Logistics failed: %1", _exception]; };

true
