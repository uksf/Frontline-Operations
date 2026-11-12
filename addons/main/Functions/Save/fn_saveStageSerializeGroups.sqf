/* Save stage: serializes one snapshot group per call, then validates the transport graph.
 * Arguments: 0: Save context <HASHMAP>
 * Returns: <BOOL> - true when every group is serialized and the graph is valid
 */
params ["_ctx"];
private _ids = _ctx get "groupIds";
private _index = _ctx get "serializeIndex";
private _serialized = _ctx get "serializedGroups";

if (_index >= count _ids) exitWith {
    try {
        [_serialized] call FLO_fnc_virtualizationValidateTransportGraph;
    } catch { throw format ["[SAVE] Virtual Groups failed: %1", _exception]; };
    (_ctx get "data") set ["virtualGroups", _serialized];
    ["SAVE", 3, format ["Virtual Groups: %1", count _serialized]] call FLO_fnc_log;
    true
};

private _campaignState = _ctx get "campaignState";
private _id = _ids select _index;
try {
    _serialized set [_id, [(_campaignState get "virtualGroups") get _id, _campaignState get "capturedAtTick"] call FLO_fnc_virtualizationSerializeGroup];
} catch { throw format ["[SAVE] Virtual Groups failed: %1", _exception]; };

_ctx set ["serializeIndex", _index + 1];
false
