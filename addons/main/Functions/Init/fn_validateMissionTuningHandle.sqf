/*
 * Function: FLO_fnc_validateMissionTuningHandle
 * Description:
 *   Validates one side's force composition from flops\settings.sqf against
 *   the setup UI field list. Every UI field is required; unknown fields are
 *   rejected. Throws on the first invalid field.
 *
 * Arguments:
 *   0: Tuning handle <HASHMAP>
 *   1: Side label <STRING> - "BLUFOR" or "OPFOR"
 *
 * Return Value:
 *   HASHMAP - Tuning overrides in the shape the setup UI produces
 */

params [["_handle", createHashMap], ["_sideLabel", "", [""]]];

private _label = format ["%1 force composition", _sideLabel];
if !(_handle isEqualType createHashMap) then {
    throw format ["%1 must be a HASHMAP", _label];
};

private _scalarKeys = [];
private _capKeys = [];
private _countKeys = [];
private _objectiveKeys = createHashMap;
private _objectiveOrder = [];
{
    _x params ["", "_category", "_key"];
    switch (_category) do {
        case "scalar": { _scalarKeys pushBack _key };
        case "cap": { _capKeys pushBack _key };
        case "count": { _countKeys pushBack _key };
        case "objective": {
            if !(_key in _objectiveKeys) then {
                _objectiveKeys set [_key, []];
                _objectiveOrder pushBack _key;
            };
            (_objectiveKeys get _key) pushBack (_x select 3);
        };
    };
} forEach ([_sideLabel] call FLO_fnc_factionGetTuningFieldSpecs);

private _isCount = { _this isEqualType 0 && {_this >= 0} && {_this == floor _this} };

// Converts [[key, count], ...] to a hashmap holding exactly the expected keys.
private _readPairs = {
    params ["_pairs", "_pairLabel", "_expected"];
    if !(_pairs isEqualType []) then {
        throw format ["%1 %2 must be an ARRAY of [name, count] pairs", _label, _pairLabel];
    };
    private _map = createHashMap;
    {
        if !(_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""}) then {
            throw format ["%1 %2 entry %3 must be [name, count]", _label, _pairLabel, _x];
        };
        _x params ["_key", "_value"];
        if !(_key in _expected) then {
            throw format ["%1 %2 has unknown group type %3", _label, _pairLabel, _key];
        };
        if (_key in _map) then {
            throw format ["%1 %2 repeats group type %3", _label, _pairLabel, _key];
        };
        if !(_value call _isCount) then {
            throw format ["%1 %2 %3 must be a non-negative whole number, got %4", _label, _pairLabel, _key, _value];
        };
        _map set [_key, _value];
    } forEach _pairs;
    private _missing = _expected select { !(_x in _map) };
    if (_missing isNotEqualTo []) then {
        throw format ["%1 %2 is missing %3", _label, _pairLabel, _missing];
    };
    _map
};

private _allowedKeys = _scalarKeys + ["objectiveGroupTypeCaps", "groupCounts", "objectiveGroups"];
private _unknown = (keys _handle) select { !(_x in _allowedKeys) };
if (_unknown isNotEqualTo []) then {
    throw format ["%1 has unknown fields %2", _label, _unknown];
};
private _missing = _allowedKeys select { !(_x in _handle) };
if (_missing isNotEqualTo []) then {
    throw format ["%1 is missing fields %2", _label, _missing];
};

private _result = createHashMap;
{
    private _value = _handle get _x;
    if !(_value call _isCount) then {
        throw format ["%1 %2 must be a non-negative whole number, got %3", _label, _x, _value];
    };
    _result set [_x, _value];
} forEach _scalarKeys;

private _caps = [_handle get "objectiveGroupTypeCaps", "objectiveGroupTypeCaps", _capKeys] call _readPairs;
_result set ["objectiveGroupTypeCaps", _capKeys apply { [_x, _caps get _x] }];
private _counts = [_handle get "groupCounts", "groupCounts", _countKeys] call _readPairs;
_result set ["groupCounts", _countKeys apply { [_x, _counts get _x] }];

private _rows = _handle get "objectiveGroups";
if !(_rows isEqualType []) then {
    throw format ["%1 objectiveGroups must be an ARRAY of [objectiveType, groups] rows", _label];
};
private _rowMap = createHashMap;
{
    if !(_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""}) then {
        throw format ["%1 objectiveGroups row %2 must be [objectiveType, groups]", _label, _x];
    };
    _x params ["_objectiveType", "_groups"];
    if !(_objectiveType in _objectiveKeys) then {
        throw format ["%1 objectiveGroups has unknown objective type %2", _label, _objectiveType];
    };
    if (_objectiveType in _rowMap) then {
        throw format ["%1 objectiveGroups repeats objective type %2", _label, _objectiveType];
    };
    _rowMap set [_objectiveType, [_groups, format ["objectiveGroups %1", _objectiveType], _objectiveKeys get _objectiveType] call _readPairs];
} forEach _rows;
private _missingRows = _objectiveOrder select { !(_x in _rowMap) };
if (_missingRows isNotEqualTo []) then {
    throw format ["%1 objectiveGroups is missing objective types %2", _label, _missingRows];
};

// The setup UI omits zero-count groups; match its output.
_result set ["objectiveGroups", _objectiveOrder apply {
    private _objectiveType = _x;
    private _groups = _rowMap get _objectiveType;
    private _present = (_objectiveKeys get _objectiveType) select { (_groups get _x) > 0 };
    [_objectiveType, _present apply { [_x, _groups get _x] }]
}];

_result
