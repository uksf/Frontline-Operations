/* Converts one campaign value into a form that str writes and parseSimpleArray reads back.
 * A HashMap becomes ["#HM", keys, values], a side becomes ["#SD", name], and an array whose
 * first element is a string starting with "#" becomes ["#AR", elements] so it cannot pass as a tag.
 * A number that 10 decimal places does not read back exactly becomes ["#NB", high, low, exponent].
 * The value is (|high| * 4096 + low), negated when high is negative, * 2^exponent, where that mantissa is an integer
 * of 24 significant bits. The mantissa is split because round and toFixed are not exact for odd
 * integers of 24 bits, while floor and integers below 4096 are.
 * Arguments: 0: Value <HASHMAP, ARRAY, SIDE, NUMBER, STRING, BOOL>
 * Returns: <ANY> - encoded value
 * Throws when the value is nil, a non-finite number, a number that does not read back exactly, or
 * another type.
 */
params ["_value"];
if (isNil "_value") then { throw "Cannot save a nil value" };
if (_value isEqualType 0) exitWith {
    if !(finite _value) then { throw format ["Cannot save non-finite number %1", _value] };
    if (((parseSimpleArray ("[" + (_value toFixed 10) + "]")) select 0) isEqualTo _value) exitWith { _value };
    private _exponent = (floor ((ln abs _value) / (ln 2))) - 23;
    private _mantissa = [_value, -_exponent] call FLO_fnc_saveScaleByPowerOfTwo;
    while { abs _mantissa >= 16777216 } do { _exponent = _exponent + 1; _mantissa = _mantissa / 2 };
    while { abs _mantissa < 8388608 } do { _exponent = _exponent - 1; _mantissa = _mantissa * 2 };
    if (_mantissa != floor _mantissa || {!(([_mantissa, _exponent] call FLO_fnc_saveScaleByPowerOfTwo) isEqualTo _value)}) then {
        throw format ["Cannot save number %1 exactly", _value toFixed 20];
    };
    private _magnitude = abs _mantissa;
    private _high = floor (_magnitude / 4096);
    ["#NB", [_high, -_high] select (_mantissa < 0), _magnitude - (_high * 4096), _exponent]
};
if (_value isEqualTypeAny ["", true]) exitWith { _value };
if (_value isEqualType []) exitWith {
    private _encoded = _value apply { [_x] call FLO_fnc_saveEncodeValue };
    if (_encoded isNotEqualTo [] && {(_encoded select 0) isEqualType ""} && {((_encoded select 0) select [0, 1]) isEqualTo "#"}) then {
        _encoded = ["#AR", _encoded];
    };
    _encoded
};
if (_value isEqualType createHashMap) exitWith {
    private _keys = [];
    private _values = [];
    {
        _keys pushBack ([_x] call FLO_fnc_saveEncodeValue);
        if (isNil "_y") then { throw format ["Cannot save a nil value for key %1", _x] };
        _values pushBack ([_y] call FLO_fnc_saveEncodeValue);
    } forEach _value;
    ["#HM", _keys, _values]
};
if (_value isEqualType sideUnknown) exitWith { ["#SD", str _value] };
throw format ["Cannot save a %1 value", typeName _value];
