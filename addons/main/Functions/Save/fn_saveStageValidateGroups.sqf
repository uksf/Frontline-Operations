/* Save stage: validates one inactive snapshot group per call, outside the capture boundary.
 * Arguments: 0: Save context <HASHMAP>
 * Returns: <BOOL> - true when every snapshot group is checked
 */
params ["_ctx"];
private _ids = _ctx get "groupIds";
private _index = _ctx get "validateIndex";
if (_index >= count _ids) exitWith { true };

private _id = _ids select _index;
private _group = ((_ctx get "campaignState") get "virtualGroups") get _id;
if !(_group get "isActive") then {
    try {
        [_group, _id] call FLO_fnc_virtualizationValidateGroup;
    } catch {
        ["SAVE", 1, format ["Campaign snapshot rejected: %1", _exception]] call FLO_fnc_log;
        throw _exception;
    };
};

_ctx set ["validateIndex", _index + 1];
false
