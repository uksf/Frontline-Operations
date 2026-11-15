/* Encodes one campaign value as save text with 10 decimal places, enough for float32 values.
 * Arguments: 0: Value <ANY> - see FLO_fnc_saveEncodeValue
 * Returns: <STRING>
 */
params ["_value"];
private _encoded = [_value] call FLO_fnc_saveEncodeValue;
toFixed 10;
private _text = str _encoded;
toFixed -1;
_text
