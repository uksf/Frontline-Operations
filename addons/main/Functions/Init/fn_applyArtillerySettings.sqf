/*
 * Function: FLO_fnc_applyArtillerySettings
 * Description:
 *   Publishes the artillery cost and cooldown values from the mission-owned
 *   artilleryHandle. A missing field keeps the upstream CBA setting default.
 *
 * Arguments:
 *   0: Mission configuration file contents <HASHMAP>
 *
 * Return Value:
 *   None
 */

params [["_fileConfig", createHashMap, [createHashMap]]];

private _handle = _fileConfig getOrDefault ["artilleryHandle", createHashMap];

{
    _x params ["_field", "_variable", "_default"];
    missionNamespace setVariable [_variable, _handle getOrDefault [_field, _default], true];
} forEach [
    ["sideCooldownSeconds", "FLO_ArtillerySideCooldownSeconds", 300],
    ["batteryCooldownSeconds", "FLO_ArtilleryBatteryCooldownSeconds", 600],
    ["treasuryCostPerRound", "FLO_ArtilleryTreasuryCostPerRound", 100],
    ["localSupplyCostPerRound", "FLO_ArtilleryLocalSupplyCostPerRound", 150]
];

["INIT", 3, format ["Applied mission artillery settings: %1", _handle]] call FLO_fnc_log;
