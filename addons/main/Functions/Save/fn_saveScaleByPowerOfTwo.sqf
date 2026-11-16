/* Multiplies a number by 2^power in two half steps, so neither factor overflows a float.
 * The factors come from a table built by repeated doubling and halving, because the ^ operator
 * is not exact for every power. Each step multiplies by an exact power of two, so the result is
 * exact whenever it is representable.
 * Arguments: 0: Number <NUMBER>, 1: Power <NUMBER> - an integer from -254 to 254
 * Returns: <NUMBER>
 */
params ["_number", "_power"];
if (isNil "FLO_SavePowersOfTwo") then {
    private _table = [];
    _table resize 255;
    private _up = 1;
    private _down = 1;
    _table set [127, 1];
    for "_i" from 1 to 127 do {
        _up = _up * 2;
        _down = _down / 2;
        _table set [127 + _i, _up];
        _table set [127 - _i, _down];
    };
    FLO_SavePowersOfTwo = _table;
};
private _half = floor (_power / 2);
_number * (FLO_SavePowersOfTwo select (127 + _half)) * (FLO_SavePowersOfTwo select (127 + _power - _half))
