/* Captures commander minefields and a detached copy of minefield objective cooldowns.
 * Called inside the capture stage so minefields and resources come from the same frame.
 * Arguments: 0: Save context <HASHMAP>
 * Returns: <BOOL> - true when the stage is complete
 */
params ["_ctx"];
private _data = _ctx get "data";

try {
    private _minefieldArray = [];
    if (!isNil "FLO_Minefields" && {FLO_Minefields isEqualType createHashMap}) then {
        {
            private _serialized = [_y] call FLO_fnc_minefieldSerializeField;
            if ((keys _serialized) isNotEqualTo []) then {
                [_serialized, count _minefieldArray] call FLO_fnc_minefieldValidateSavedField;
                _minefieldArray pushBack _serialized;
            };
        } forEach FLO_Minefields;
    };
    _data set ["minefields", _minefieldArray];

    if !(FLO_MinefieldObjectiveCooldowns isEqualType createHashMap) then {
        throw format [
            "Minefield objective cooldowns have invalid type %1",
            typeName FLO_MinefieldObjectiveCooldowns
        ];
    };
    _data set ["minefieldObjectiveCooldowns", +FLO_MinefieldObjectiveCooldowns];
    ["SAVE", 3, format ["Commander minefields: %1", count _minefieldArray]] call FLO_fnc_log;
} catch { throw format ["[SAVE] Commander minefields failed: %1", _exception]; };

true
