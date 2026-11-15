/* Save stage: validates the campaign root and encodes it as save text.
 * The first call validates and lists the work; each later call encodes one root value, or one
 * entry of a root HashMap, so a large map such as virtualGroups spreads across frames.
 * The last call joins the parts into one text in the FLO_fnc_saveEncodeValue format.
 * Arguments: 0: Save context <HASHMAP>
 * Returns: <BOOL> - true when "payloadText" is ready
 */
params ["_ctx"];
private _data = _ctx get "data";

if !("encodeItems" in _ctx) exitWith {
    [_data] call FLO_fnc_saveValidateCampaignRoot;
    private _items = [];
    {
        private _rootKey = _x;
        if (_y isEqualType createHashMap) then {
            { _items pushBack [_rootKey, _x] } forEach _y;
        } else {
            _items pushBack [_rootKey];
        };
    } forEach _data;
    _ctx set ["encodeItems", _items];
    _ctx set ["encodeIndex", 0];
    _ctx set ["encodedParts", createHashMap];
    false
};

private _items = _ctx get "encodeItems";
private _index = _ctx get "encodeIndex";
private _parts = _ctx get "encodedParts";

if (_index < count _items) exitWith {
    (_items select _index) params ["_rootKey", "_entryKey"];
    private _rootValue = _data get _rootKey;
    try {
        if (isNil "_entryKey") then {
            _parts set [_rootKey, [_rootValue] call FLO_fnc_saveEncodeText];
        } else {
            if !(_rootKey in _parts) then { _parts set [_rootKey, [[], []]] };
            (_parts get _rootKey) params ["_keyTexts", "_valueTexts"];
            _keyTexts pushBack ([_entryKey] call FLO_fnc_saveEncodeText);
            _valueTexts pushBack ([_rootValue get _entryKey] call FLO_fnc_saveEncodeText);
        };
    } catch { throw format ["[SAVE] Encoding %1 failed: %2", _rootKey, _exception] };
    _ctx set ["encodeIndex", _index + 1];
    false
};

private _rootKeyTexts = [];
private _rootValueTexts = [];
{
    _rootKeyTexts pushBack ([_x] call FLO_fnc_saveEncodeText);
    if (_y isEqualType createHashMap) then {
        (_parts getOrDefault [_x, [[], []]]) params ["_keyTexts", "_valueTexts"];
        _rootValueTexts pushBack ("[""#HM"",[" + (_keyTexts joinString ",") + "],[" + (_valueTexts joinString ",") + "]]");
    } else {
        _rootValueTexts pushBack (_parts get _x);
    };
} forEach _data;
_ctx set ["payloadText", "[""#HM"",[" + (_rootKeyTexts joinString ",") + "],[" + (_rootValueTexts joinString ",") + "]]"];
["SAVE", 3, format ["Encoded campaign: %1 characters", count (_ctx get "payloadText")]] call FLO_fnc_log;
true
