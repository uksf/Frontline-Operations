/* Reverses FLO_fnc_saveEncodeValue on a value read by parseSimpleArray.
 * Arguments: 0: Encoded value <ANY>
 * Returns: <ANY> - decoded value
 */
params ["_value"];
if !(_value isEqualType []) exitWith { _value };
private _tag = if (count _value in [2, 3] && {(_value select 0) isEqualType ""}) then { _value select 0 } else { "" };
if (_tag isEqualTo "#HM" && {count _value == 3}) exitWith {
    ((_value select 1) apply { [_x] call FLO_fnc_saveDecodeValue }) createHashMapFromArray ((_value select 2) apply { [_x] call FLO_fnc_saveDecodeValue })
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
