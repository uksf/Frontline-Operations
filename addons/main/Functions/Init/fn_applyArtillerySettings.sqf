/*
 * Function: FLO_fnc_applyArtillerySettings
 * Description:
 *   Validates the mission-owned artilleryHandle and publishes the artillery
 *   cost and cooldown values. Throws on a missing or invalid field.
 *
 * Arguments:
 *   0: Mission configuration file contents <HASHMAP>
 *
 * Return Value:
 *   None
 */

params [["_fileConfig", createHashMap, [createHashMap]]];

private _handle = _fileConfig getOrDefault ["artilleryHandle", 0];
if !(_handle isEqualType createHashMap) then {
    throw "Mission config artilleryHandle must be a HASHMAP";
};

// Field, published variable, minimum, maximum.
private _specs = [
    ["sideCooldownSeconds", "FLO_ArtillerySideCooldownSeconds", 60, 1800],
    ["batteryCooldownSeconds", "FLO_ArtilleryBatteryCooldownSeconds", 60, 3600],
    ["treasuryCostPerRound", "FLO_ArtilleryTreasuryCostPerRound", 25, 500],
    ["localSupplyCostPerRound", "FLO_ArtilleryLocalSupplyCostPerRound", 25, 500]
];

private _unknown = (keys _handle) select { !(_x in (_specs apply { _x select 0 })) };
if (_unknown isNotEqualTo []) then {
    throw format ["Mission config artilleryHandle has unknown fields %1", _unknown];
};

{
    _x params ["_field", "", "_min", "_max"];
    private _value = _handle getOrDefault [_field, -1];
    if !(_value isEqualType 0 && {_value >= _min && {_value <= _max}}) then {
        throw format ["Mission config artilleryHandle %1 must be a number from %2 to %3, got %4", _field, _min, _max, _value];
    };
} forEach _specs;

{
    _x params ["_field", "_variable"];
    missionNamespace setVariable [_variable, _handle get _field, true];
} forEach _specs;

["INIT", 3, format ["Applied mission artillery settings: %1", _handle]] call FLO_fnc_log;
