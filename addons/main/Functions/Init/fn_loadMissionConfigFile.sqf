/*
 * Function: FLO_fnc_loadMissionConfigFile
 * Description:
 *   Loads the complete fresh-campaign configuration from the mission folder.
 *
 * Return Value:
 *   HASHMAP - Mission configuration
 */

private _path = "flops\settings.sqf";
private _source = preprocessFileLineNumbers _path;
if (_source == "") then {
    throw format ["Mission configuration file is missing or empty: %1", _path];
};

private _config = createHashMap;
try {
    _config = call compile _source;
} catch {
    throw format ["Mission configuration file %1 failed to execute: %2", _path, _exception];
};

if !(_config isEqualType createHashMap) then {
    throw format ["Mission configuration file %1 returned %2 instead of HASHMAP", _path, typeName _config];
};

_config
