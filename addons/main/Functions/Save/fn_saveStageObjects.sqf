/* Save stage: static objects around installations, one installation marker per call.
 * Arguments: 0: Save context <HASHMAP>
 * Returns: <BOOL> - true when every installation marker is captured
 */
params ["_ctx"];
private _data = _ctx get "data";

if !("objects" in _data) then {
    _data set ["objects", createHashMap];
    _ctx set ["objectIds", createHashMap];
    _ctx set ["objectMarkerIndex", 0];
    _ctx set ["skippedWeaponHolders", 0];
    _ctx set ["excludedObjectTypes", createHashMapFromArray [
        ["Box_NATO_WpsSpecial_F", true], ["Box_NATO_AmmoOrd_F", true],
        ["Box_NATO_Ammo_F", true], ["Box_NATO_Wps_F", true], ["VirtualReammoBox_small_F", true],
        [FLO_FactionFobTerminalType, true], [FLO_FactionCopTerminalType, true],
        ["Land_TripodScreen_01_large_sand_F", true],
        ["Land_Cargo20_military_green_F", true],
        ["Land_Cargo10_military_green_F", true]
    ]];
};

private _objHash = _data get "objects";
private _markers = _ctx get "installationMarkers";
private _index = _ctx get "objectMarkerIndex";
if (_index >= count _markers) exitWith {
    ["SAVE", 3, format ["Objects: %1; excluded weapon-holder candidates: %2", count _objHash, _ctx get "skippedWeaponHolders"]] call FLO_fnc_log;
    true
};

try {
    private _savedObjIds = _ctx get "objectIds";
    private _excluded = _ctx get "excludedObjectTypes";
    private _nearObjs = (getMarkerPos (_markers select _index)) nearEntities [["Static", "Thing", "ReammoBox_F"], _ctx get "saveRadius"];
    {
        private _obj = _x;
        private _objType = typeOf _obj;

        if ([_objType] call FLO_fnc_saveIsWeaponHolderClass) then {
            _ctx set ["skippedWeaponHolders", (_ctx get "skippedWeaponHolders") + 1];
            continue;
        };

        if (alive _obj &&
            { !(_excluded getOrDefault [_objType, false]) } &&
            { !(_obj getVariable ["FLO_save_crate", false]) } &&
            { !(_obj getVariable ["FLO_temp_object", false]) } &&
            { !(_obj getVariable ["IDS_Logistics_isPlacedEntity", false]) }) then {

            private _existingId = _obj getVariable ["FLO_SaveID", ""];
            if (_existingId == "" || !(_savedObjIds getOrDefault [_existingId, false])) then {
                private _id = if (_existingId != "") then { _existingId } else { [] call FLO_fnc_createUUID };
                _obj setVariable ["FLO_SaveID", _id, true];
                _savedObjIds set [_id, true];
                private _hadAICrew = ({ alive _x && {!isPlayer _x} } count (crew _obj)) > 0;
                _objHash set [_id, createHashMapFromArray [
                    ["type", _objType], ["posASL", getPosASL _obj],
                    ["vectorDirAndUp", [vectorDir _obj, vectorUp _obj]],
                    ["damage", damage _obj], ["hadAICrew", _hadAICrew]
                ]];
            };
        };
    } forEach _nearObjs;
} catch { throw format ["[SAVE] Objects failed: %1", _exception]; };

_ctx set ["objectMarkerIndex", _index + 1];
false
