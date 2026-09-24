/* Owns the scheduled siege lifecycle shared by FOBs and COPs. */
params [
    ["_base", objNull, [objNull]],
    ["_config", createHashMap, [createHashMap]]
];

if (!isServer) exitWith {};
if (isNull _base) then {
    ["BASE", 1, "Cannot start siege monitor for a null base"] call FLO_fnc_log;
    throw "FLO_fnc_baseMonitorSiege requires a base object";
};
if (isNil { _base getVariable "FLO_BaseSide" }) then {
    ["BASE", 1, format ["Base %1 has no FLO_BaseSide", _base]] call FLO_fnc_log;
    throw "FLO_fnc_baseMonitorSiege requires FLO_BaseSide";
};

private _baseSide = _base getVariable "FLO_BaseSide";
if !(_baseSide in [west, east]) then {
    ["BASE", 1, format ["Base %1 has invalid FLO_BaseSide %2", _base, _baseSide]] call FLO_fnc_log;
    throw "FLO_fnc_baseMonitorSiege received an invalid base side";
};

private _label = _config get "siegeLabel";
private _maxHoldTime = _config get "holdoutTime";
private _areaRadius = _config get "holdoutRadius";
private _markerVariable = _config get "markerVariable";
private _checkInterval = 5;
private _holdoutTime = 0;
private _lost = false;

["BASE", 3, format ["%1 siege monitor started for %2", _label, _baseSide]] call FLO_fnc_log;

while {alive _base && {!_lost}} do {
    private _counts = [_base, _areaRadius, _baseSide] call FLO_fnc_baseCountSiegeForces;
    _counts params ["_friendlyCount", "_enemyCount"];

    if (_enemyCount > _friendlyCount && {_enemyCount > 0}) then {
        if (_holdoutTime == 0) then {
            ["BASE", 3, format ["%1 siege started: side=%2 friendly=%3 enemy=%4", _label, _baseSide, _friendlyCount, _enemyCount]] call FLO_fnc_log;
        };

        _holdoutTime = _holdoutTime + _checkInterval;
        if (_holdoutTime >= _maxHoldTime) then { _lost = true };
    } else {
        if (_holdoutTime > 0) then {
            ["BASE", 3, format ["%1 siege ended after successful defense", _label]] call FLO_fnc_log;
        };
        _holdoutTime = 0;
    };

    if (!_lost) then { sleep _checkInterval };
};

if (_lost) then {
    ["BASE", 2, format ["%1 lost after %2-second siege", _label, _maxHoldTime]] call FLO_fnc_log;

    [_base, _markerVariable] call FLO_fnc_baseCleanupOwnedAssets;

    if (!isNull _base) then { _base setDamage 1 };
};

["BASE", 3, format ["%1 siege monitor ended", _label]] call FLO_fnc_log;
