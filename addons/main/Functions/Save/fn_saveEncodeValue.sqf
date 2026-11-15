/* Converts one campaign value into a form that str writes and parseSimpleArray reads back.
 * A HashMap becomes ["#HM", keys, values], a side becomes ["#SD", name], and an array whose
 * first element is a string starting with "#" becomes ["#AR", elements] so it cannot pass as a tag.
 * A number that 10 decimal places does not read back exactly becomes ["#NB", 20-decimal text].
 * Arguments: 0: Value <HASHMAP, ARRAY, SIDE, NUMBER, STRING, BOOL>, 1: Value is a HashMap key <BOOL>
 * Returns: <ANY> - encoded value
 * Throws when the value is nil, a non-finite number, a number that cannot be written within one
 * float rounding step (or exactly, for a HashMap key), or another type.
 */
params ["_value", ["_isKey", false]];
if (isNil "_value") then { throw "Cannot save a nil value" };
if (_value isEqualType 0) exitWith {
    if !(finite _value) then { throw format ["Cannot save non-finite number %1", _value] };
    if (((parseSimpleArray ("[" + (_value toFixed 10) + "]")) select 0) isEqualTo _value) exitWith { _value };
    private _wideText = _value toFixed 20;
    private _wide = parseNumber _wideText;
    private _exact = _wide isEqualTo _value;
    if (_isKey && {!_exact}) then { throw format ["Cannot save number key %1 exactly", _wideText] };
    if (!_exact && {abs (_wide - _value) > (abs _value) * 2.4e-7}) then {
        throw format ["Cannot save number %1 without loss", _wideText];
    };
    ["#NB", _wideText]
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
        _keys pushBack ([_x, true] call FLO_fnc_saveEncodeValue);
        if (isNil "_y") then { throw format ["Cannot save a nil value for key %1", _x] };
        _values pushBack ([_y] call FLO_fnc_saveEncodeValue);
    } forEach _value;
    ["#HM", _keys, _values]
};
if (_value isEqualType sideUnknown) exitWith { ["#SD", str _value] };
throw format ["Cannot save a %1 value", typeName _value];
