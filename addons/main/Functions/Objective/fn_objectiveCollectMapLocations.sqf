/* Collects non-excluded map locations used as objective candidates. */
params [["_center", [worldSize / 2, worldSize / 2, 0], [[]]]];

private _locationConfigs = [
    ["NameCityCapital", "civilian", "capital", 100, 1.5],
    ["NameCity", "civilian", "city", 75, 1.3],
    ["NameVillage", "civilian", "village", 50, 1.2],
    ["Airport", "military", "local", 95, 1.5],
    ["Strategic", "military", "local", 85, 1.2]
];
private _locations = [];

{
    _x params ["_locationType", "_category", "_subtype", "_basePriority", "_sizeMultiplier"];
    {
        private _position = locationPosition _x;
        if ([_position] call FLO_fnc_objectivePositionExcluded) then { continue };

        private _locationSize = size _x;
        private _radius = (((_locationSize select 0) max (_locationSize select 1)) * _sizeMultiplier) max 100;
        _locations pushBack [_position, text _x, _locationType, _category, _subtype, _basePriority, _radius];
    } forEach (nearestLocations [_center, [_locationType], worldSize]);
} forEach _locationConfigs;

_locations
