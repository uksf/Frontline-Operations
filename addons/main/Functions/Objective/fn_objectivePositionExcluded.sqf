/* Returns true when a position is inside any registered exclusion module. */
params [["_position", [0, 0, 0], [[]]]];

private _excluded = false;
{
    _x params ["_logic", "_area"];
    if (isNull _logic || {_area isEqualTo []}) then { continue };

    _area params ["_radiusX", "_radiusY", "_angle", "_isRectangle"];
    if (_position inArea [_logic, _radiusX, _radiusY, _angle, _isRectangle]) exitWith {
        _excluded = true;
    };
} forEach FLO_ObjectiveExclusionAreas;

_excluded
