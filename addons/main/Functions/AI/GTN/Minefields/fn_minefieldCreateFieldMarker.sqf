/*
 * Function: FLO_fnc_minefieldCreateFieldMarker
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates the map marker for one minefield. Only the active player side sees
 *   its own fields; enemy fields get no marker.
 *
 * Arguments:
 * 0: Marker name <STRING>
 * 1: Field side <SIDE>
 * 2: Field center position <ARRAY>
 * 3: Facing direction <SCALAR>
 * 4: Frontage half width <SCALAR>
 * 5: Depth half width <SCALAR>
 *
 * Return Value:
 * STRING - Marker name, or "" when no marker is shown
 */

params ["_markerName", "_side", "_centerPos", "_facingDir", "_frontageHalfWidth", "_depthHalfWidth"];

if (getMarkerColor _markerName != "") then {
    deleteMarker _markerName;
};
if (_side isNotEqualTo FLO_ActivePlayerSide) exitWith { "" };

private _marker = createMarker [_markerName, _centerPos];
_marker setMarkerShapeLocal "RECTANGLE";
_marker setMarkerBrushLocal "SolidBorder";
_marker setMarkerColorLocal (["ColorEAST", "ColorWEST"] select (_side isEqualTo west));
_marker setMarkerAlphaLocal (FLO_MinefieldConfig get "markerAlpha");
_marker setMarkerDirLocal _facingDir;
_marker setMarkerPosLocal _centerPos;
_marker setMarkerSizeLocal [_frontageHalfWidth, _depthHalfWidth];
_marker setMarkerText "Minefield";
_marker
