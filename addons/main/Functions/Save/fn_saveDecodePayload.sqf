/* Reads campaign save text written by FLO_fnc_saveStageEncode back into the campaign HashMap.
 * Arguments: 0: Save text <STRING>
 * Returns: <HASHMAP>
 * Throws when the text does not hold an encoded HashMap.
 */
params ["_text"];
private _parsed = parseSimpleArray _text;
if !(count _parsed == 3 && {(_parsed select 0) isEqualTo "#HM"}) then {
    throw format ["Saved campaign text could not be read (%1 characters)", count _text];
};
[_parsed] call FLO_fnc_saveDecodeValue
