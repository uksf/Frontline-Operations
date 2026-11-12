/* Save stage: pre-save cleanup, installation markers, mission configuration, and map markers.
 * Arguments: 0: Save context <HASHMAP>
 * Returns: <BOOL> - true when the stage is complete
 */
params ["_ctx"];
private _data = _ctx get "data";
_data set ["time", call FLO_fnc_operationalDate];

{ deleteVehicle _x } forEach (allMissionObjects "Sign_Sphere10cm_F");
{ deleteMarker _x } forEach (allMapMarkers select { markerType _x == "b_unknown" && markerColor _x == "Color6_FD_F" });

_ctx set ["installationMarkers", allMapMarkers select { markerType _x == "b_installation" }];
_ctx set ["saveRadius", 300];

try {
    private _cfg = createHashMap;
    _cfg set ["bluforHandle", FLO_BluforHandle];
    _cfg set ["opforHandle", FLO_OpforHandle];
    _cfg set ["civilianHandle", FLO_CivilianHandle];
    _cfg set ["playerSideKey", [FLO_ActivePlayerSide] call FLO_fnc_sideKey];
    _cfg set ["startingResources", FLO_MissionConfig get "startingResources"];
    _cfg set ["reputationHandle", FLO_ReputationHandle];
    _cfg set ["westDifficultyHandle", FLO_WestDifficultyHandle];
    _cfg set ["eastDifficultyHandle", FLO_EastDifficultyHandle];
    _cfg set ["westGTNAttackCoverageHandle", FLO_WestGTN_AttackCoverageHandle];
    _cfg set ["eastGTNAttackCoverageHandle", FLO_EastGTN_AttackCoverageHandle];
    _cfg set ["westGTNDefenseCoverageHandle", FLO_WestGTN_DefenseCoverageHandle];
    _cfg set ["eastGTNDefenseCoverageHandle", FLO_EastGTN_DefenseCoverageHandle];
    _cfg set ["westGTNTempoHandle", FLO_WestGTN_TempoHandle];
    _cfg set ["eastGTNTempoHandle", FLO_EastGTN_TempoHandle];
    _cfg set ["westGTNForceGrowthHandle", FLO_WestGTN_ForceGrowthHandle];
    _cfg set ["eastGTNForceGrowthHandle", FLO_EastGTN_ForceGrowthHandle];
    _cfg set ["westGTNGarrisonHandle", FLO_WestGTN_GarrisonHandle];
    _cfg set ["eastGTNGarrisonHandle", FLO_EastGTN_GarrisonHandle];
    _cfg set ["westFactionTuningHandle", FLO_WestFactionTuningHandle];
    _cfg set ["eastFactionTuningHandle", FLO_EastFactionTuningHandle];
    _cfg set ["objectiveSizeThreshold", FLO_ObjectiveSizeThreshold];
    _cfg set ["virtualizationDistance", FLO_VirtualizationDistance];
    _cfg set ["virtualizationUnitCap", FLO_VirtualizationUnitCap];
    _cfg set ["startingTerritoryWestRatio", FLO_StartingTerritoryWestRatio];
    _cfg set ["startPosition", FLO_MissionConfig get "startPosition"];
    _data set ["config", _cfg];
    ["SAVE", 3, format ["Config: %1 items", count keys _cfg]] call FLO_fnc_log;
} catch { throw format ["[SAVE] Config failed: %1", _exception]; };

try {
    private _markerHash = createHashMap;
    private _exclude = createHashMapFromArray [["b_unknown", true], ["Empty", true], ["mil_dot", true], ["hd_start", true]];
    private _combatMarkerPrefix = "FLO_GTN_COMBAT_";
    private _minefieldMarkerPrefix = "FLO_MINEFIELD_";
    private _markers = allMapMarkers select {
        !(_exclude getOrDefault [markerType _x, false])
        && {markerAlpha _x > 0.01}
        && {_x find _combatMarkerPrefix != 0}
        && {_x find _minefieldMarkerPrefix != 0}
    };
    {
        _markerHash set [_x, createHashMapFromArray [
            ["alpha", markerAlpha _x], ["brush", markerBrush _x], ["color", getMarkerColor _x],
            ["dir", markerDir _x], ["pos", getMarkerPos _x], ["shape", markerShape _x],
            ["size", getMarkerSize _x], ["text", markerText _x], ["type", markerType _x]
        ]];
    } forEach _markers;
    _data set ["markers", _markerHash];
    ["SAVE", 3, format ["Markers: %1", count _markers]] call FLO_fnc_log;
} catch { throw format ["[SAVE] Markers failed: %1", _exception]; };

true
