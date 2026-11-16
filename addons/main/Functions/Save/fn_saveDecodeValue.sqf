/* Reverses FLO_fnc_saveEncodeValue on a value read by parseSimpleArray.
 * The encoder escapes every plain array whose first element starts with "#", so any such array
 * read here must be a well-formed tag.
 * Arguments: 0: Encoded value <ANY>
 * Returns: <ANY> - decoded value
 * Throws on an unknown or malformed tag, a HashMap with unequal key and value counts or duplicate
 * keys, or a number token that is not an integer mantissa with an integer exponent.
 */
params ["_value"];
if !(_value isEqualType []) exitWith { _value };
private _isTagged = _value isNotEqualTo [] && {(_value select 0) isEqualType ""} && {((_value select 0) select [0, 1]) isEqualTo "#"};
if (!_isTagged) exitWith { _value apply { [_x] call FLO_fnc_saveDecodeValue } };

private _tag = _value select 0;
private _malformed = { throw format ["Saved value has a malformed %1 tag: %2", _tag, _value select [0, 4]] };
switch (_tag) do {
    case "#HM": {
        if !(count _value == 3 && {(_value select 1) isEqualType []} && {(_value select 2) isEqualType []}) then _malformed;
        _value params ["", "_encodedKeys", "_encodedValues"];
        if (count _encodedKeys != count _encodedValues) then { throw "Saved map has unequal key and value lists" };
        private _map = (_encodedKeys apply { [_x] call FLO_fnc_saveDecodeValue }) createHashMapFromArray (_encodedValues apply { [_x] call FLO_fnc_saveDecodeValue });
        if (count _map != count _encodedKeys) then { throw "Saved map has duplicate keys" };
        _map
    };
    case "#NB": {
        if !(count _value == 3 && {(_value select 1) isEqualType ""} && {(_value select 2) isEqualType 0}) then _malformed;
        _value params ["", "_mantissaText", "_exponent"];
        private _digits = if ((_mantissaText select [0, 1]) isEqualTo "-") then { _mantissaText select [1] } else { _mantissaText };
        private _validMantissa = (count _digits) in [7, 8]
            && {((toArray _digits) findIf { _x < 48 || {_x > 57} }) == -1}
            && {(_digits select [0, 1]) isNotEqualTo "0"};
        if !(_validMantissa && {finite _exponent} && {_exponent == round _exponent} && {abs _exponent <= 200}) then _malformed;
        [parseNumber _mantissaText, _exponent] call FLO_fnc_saveScaleByPowerOfTwo
    };
    case "#SD": {
        if !(count _value == 2 && {(_value select 1) isEqualType ""}) then _malformed;
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
    case "#AR": {
        if !(count _value == 2 && {(_value select 1) isEqualType []}) then _malformed;
        (_value select 1) apply { [_x] call FLO_fnc_saveDecodeValue }
    };
    default { throw format ["Saved value has unknown tag %1", _tag] };
}
