/* Converts one campaign value into a form that str writes and parseSimpleArray reads back.
 * A HashMap becomes ["#HM", keys, values], a side becomes ["#SD", name], and an array whose
 * first element is a string starting with "#" becomes ["#AR", elements] so it cannot pass as a tag.
 * Arguments: 0: Value <HASHMAP, ARRAY, SIDE, NUMBER, STRING, BOOL>
 * Returns: <ANY> - encoded value
 * Throws when the value is nil, a non-finite number, or another type.
 */
params ["_value"];
if (isNil "_value") then { throw "Cannot save a nil value" };
if (_value isEqualType 0) exitWith {
    if !(finite _value) then { throw format ["Cannot save non-finite number %1", _value] };
    _value
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
        _values pushBack ([_y] call FLO_fnc_saveEncodeValue);
    } forEach _value;
    ["#HM", _keys, _values]
};
if (_value isEqualType sideUnknown) exitWith { ["#SD", str _value] };
throw format ["Cannot save a %1 value", typeName _value];
