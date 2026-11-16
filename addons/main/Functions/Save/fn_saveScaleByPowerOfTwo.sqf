/* Multiplies a number by 2^power in two half steps, so neither factor overflows a float.
 * Each step multiplies by a power of two, so the result is exact whenever it is representable.
 * Arguments: 0: Number <NUMBER>, 1: Power <NUMBER> - an integer
 * Returns: <NUMBER>
 */
params ["_number", "_power"];
private _half = floor (_power / 2);
_number * (2 ^ _half) * (2 ^ (_power - _half))
