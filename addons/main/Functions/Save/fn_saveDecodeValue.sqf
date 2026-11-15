/* Reverses FLO_fnc_saveEncodeValue on a value read by parseSimpleArray.
 * Arguments: 0: Encoded value <ANY>
 * Returns: <ANY> - decoded value
 * Throws when a HashMap has unequal key and value counts or duplicate keys.
 */
params ["_value"];
if !(_value isEqualType []) exitWith { _value };
private _tag = if (count _value in [2, 3] && {(_value select 0) isEqualType ""}) then { _value select 0 } else { "" };
if (_tag isEqualTo "#HM" && {count _value == 3}) exitWith {
    _value params ["", "_encodedKeys", "_encodedValues"];
    if !(_encodedKeys isEqualType [] && {_encodedValues isEqualType []} && {count _encodedKeys == count _encodedValues}) then {
        throw "Saved map has unequal key and value lists";
    };
    private _map = (_encodedKeys apply { [_x] call FLO_fnc_saveDecodeValue }) createHashMapFromArray (_encodedValues apply { [_x] call FLO_fnc_saveDecodeValue });
    if (count _map != count _encodedKeys) then { throw "Saved map has duplicate keys" };
    _map
};
if (_tag isEqualTo "#NB" && {count _value == 2} && {(_value select 1) isEqualType ""}) exitWith {
    parseNumber (_value select 1)
};
if (_tag isEqualTo "#SD" && {count _value == 2}) exitWith {
    switch (_value select 1) do {
        case "WEST": { west };
        case "EAST": { east };
        case "GUER": { independent };
        case "CIV": { civilian };
        case "UNKNOWN": { sideUnknown };
        case "LOGIC": { sideLogic };
        case "EMPTY": { sideEmpty };
        case "ENEMY": { sideEnemy };
        case "FRIENDLY": { sideFriendly };
        case "AMBIENT LIFE": { sideAmbientLife };
        default { throw format ["Saved side %1 is unknown", _value select 1] };
    }
};
if (_tag isEqualTo "#AR" && {count _value == 2}) exitWith {
    (_value select 1) apply { [_x] call FLO_fnc_saveDecodeValue }
};
_value apply { [_x] call FLO_fnc_saveDecodeValue }
