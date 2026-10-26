/*
 * Function: FLO_fnc_isRouteWater
 * Description:
 *   Reports whether a land route must avoid a position. surfaceIsWater
 *   follows the waves, so terrain within a few centimetres of sea level reads
 *   as water for part of each wave cycle and a route that was dry when built
 *   reads wet when saved. Terrain depth is stable, so building and saving
 *   always agree.
 *
 * Arguments:
 *   0: Position <ARRAY>
 *
 * Return Value:
 *   true when the terrain lies more than 0.3 m below sea level <BOOLEAN>
 */

params ["_pos"];

getTerrainHeightASL _pos < -0.3
