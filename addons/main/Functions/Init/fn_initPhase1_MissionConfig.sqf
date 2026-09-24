/*
 * Phase 1 receives one authoritative native-side campaign configuration.
 * Fresh setup and Continue converge here before any faction state is loaded.
 */

if (!isServer) exitWith { false };

["INIT", 3, "Phase 1 waiting for mission configuration"] call FLO_fnc_log;
FLO_VirtualizationUnitCap = 200;

private _loadedSave = !isNil "FLO_IsLoadedSave" && {FLO_IsLoadedSave};
private _loadError = "";
private _fileConfig = createHashMap;
// The file is read on Continue too: its artillery settings are live balance, not saved state.
try {
    _fileConfig = [] call FLO_fnc_loadMissionConfigFile;
} catch {
    _loadError = _exception;
};

if (_loadError == "") then {
    if (!_loadedSave) then {
        FLO_MissionConfig = _fileConfig;
        publicVariable "FLO_MissionConfig";
        ["INIT", 3, "Phase 1 loaded flops\\settings.sqf"] call FLO_fnc_log;
    } else {
        ["INIT", 3, "Phase 1 using validated current saved mission configuration"] call FLO_fnc_log;
    };
};

if (_loadError != "") exitWith {
    FLO_InitError = _loadError;
    publicVariable "FLO_InitError";
    ["INIT", 1, FLO_InitError] call FLO_fnc_log;
    false
};

if (
    isNil "FLO_MissionConfig"
    || {!(FLO_MissionConfig isEqualType createHashMap)}
    || {(keys FLO_MissionConfig) isEqualTo []}
) exitWith {
    FLO_InitError = "Mission configuration wait ended without setup data";
    publicVariable "FLO_InitError";
    ["INIT", 1, FLO_InitError] call FLO_fnc_log;
    false
};

private _requiredFields = [
    "bluforHandle",
    "opforHandle",
    "civilianHandle",
    "playerSideKey",
    "reputationHandle",
    "westDifficultyHandle",
    "eastDifficultyHandle",
    "westGTNAttackCoverageHandle",
    "eastGTNAttackCoverageHandle",
    "westGTNDefenseCoverageHandle",
    "eastGTNDefenseCoverageHandle",
    "westGTNTempoHandle",
    "eastGTNTempoHandle",
    "westGTNForceGrowthHandle",
    "eastGTNForceGrowthHandle",
    "westGTNGarrisonHandle",
    "eastGTNGarrisonHandle",
    "westFactionTuningHandle",
    "eastFactionTuningHandle",
    "startingResources",
    "objectiveSizeThreshold",
    "virtualizationDistance",
    "virtualizationUnitCap",
    "startingTerritoryWestRatio",
    "startPosition"
];
private _missingFields = _requiredFields select { !(_x in FLO_MissionConfig) };
if (_missingFields isNotEqualTo []) exitWith {
    FLO_InitError = format ["Mission config missing required fields: %1", _missingFields];
    publicVariable "FLO_InitError";
    ["INIT", 1, FLO_InitError] call FLO_fnc_log;
    false
};

private _configError = "";
private _playerSideKey = FLO_MissionConfig get "playerSideKey";
try {
    private _handleFields = [
        "bluforHandle", "opforHandle", "civilianHandle", "reputationHandle",
        "westDifficultyHandle", "eastDifficultyHandle",
        "westGTNAttackCoverageHandle", "eastGTNAttackCoverageHandle",
        "westGTNDefenseCoverageHandle", "eastGTNDefenseCoverageHandle",
        "westGTNTempoHandle", "eastGTNTempoHandle",
        "westGTNForceGrowthHandle", "eastGTNForceGrowthHandle",
        "westGTNGarrisonHandle", "eastGTNGarrisonHandle",
        "westFactionTuningHandle", "eastFactionTuningHandle"
    ];
    {
        if !((FLO_MissionConfig get _x) isEqualType createHashMap) then {
            throw format ["Mission config %1 must be a HASHMAP", _x];
        };
    } forEach _handleFields;

    if (([FLO_MissionConfig get "bluforHandle"] call FLO_fnc_factionHandleSide) != 1) then {
        throw "BLUFOR faction handle is not config side 1";
    };
    if (([FLO_MissionConfig get "opforHandle"] call FLO_fnc_factionHandleSide) != 0) then {
        throw "OPFOR faction handle is not config side 0";
    };
    if (([FLO_MissionConfig get "civilianHandle"] call FLO_fnc_factionHandleSide) != 3) then {
        throw "Civilian faction handle is not config side 3";
    };
    if !(_playerSideKey isEqualType "" && {_playerSideKey in ["WEST", "EAST"]}) then {
        throw format ["Unsupported player side key %1", _playerSideKey];
    };

    private _valueSpecs = [
        ["reputationHandle", [2, 9, 16]],
        ["westDifficultyHandle", [0.5, 1, 1.5]],
        ["eastDifficultyHandle", [0.5, 1, 1.5]],
        ["westGTNAttackCoverageHandle", [0.5, 0.75, 1, 1.25]],
        ["eastGTNAttackCoverageHandle", [0.5, 0.75, 1, 1.25]],
        ["westGTNDefenseCoverageHandle", [0.5, 0.75, 1, 1.25]],
        ["eastGTNDefenseCoverageHandle", [0.5, 0.75, 1, 1.25]],
        ["westGTNTempoHandle", [10, 14, 20, 28]],
        ["eastGTNTempoHandle", [10, 14, 20, 28]],
        ["westGTNForceGrowthHandle", [1, 2, 3]],
        ["eastGTNForceGrowthHandle", [1, 2, 3]]
    ];
    {
        _x params ["_field", "_allowedValues"];
        private _value = (FLO_MissionConfig get _field) get "value";
        if !(_value in _allowedValues) then {
            throw format ["Mission config %1 has unsupported value %2", _field, _value];
        };
    } forEach _valueSpecs;

    {
        private _handle = FLO_MissionConfig get _x;
        {
            if !(_x in _handle && {(_handle get _x) isEqualType 0 && {(_handle get _x) >= 0}}) then {
                throw format ["Mission config garrison field %1 is missing or invalid", _x];
            };
        } forEach ["rearBaseGroups", "frontlineBaseGroups", "priorityBonusGroups", "hotBonusGroups"];
    } forEach ["westGTNGarrisonHandle", "eastGTNGarrisonHandle"];

    private _startingResources = FLO_MissionConfig get "startingResources";
    if !(_startingResources isEqualType 0 && {_startingResources >= 0}) then {
        throw format ["Mission config startingResources must be non-negative, got %1", _startingResources];
    };
    private _objectiveSizeThreshold = FLO_MissionConfig get "objectiveSizeThreshold";
    if !(_objectiveSizeThreshold in [4, 8, 12, 24]) then {
        throw format ["Mission config objectiveSizeThreshold must be one of 4, 8, 12, or 24, got %1", _objectiveSizeThreshold];
    };
    private _virtualizationDistance = FLO_MissionConfig get "virtualizationDistance";
    if !(_virtualizationDistance in [1000, 1500, 2000, 2500, 3000]) then {
        throw format ["Mission config virtualizationDistance is unsupported: %1", _virtualizationDistance];
    };
    private _virtualizationUnitCap = FLO_MissionConfig get "virtualizationUnitCap";
    if !(_virtualizationUnitCap in [100, 150, 200, 250, 300, 350, 400]) then {
        throw format ["Mission config virtualizationUnitCap is unsupported: %1", _virtualizationUnitCap];
    };
    private _territoryRatio = FLO_MissionConfig get "startingTerritoryWestRatio";
    if !(_territoryRatio isEqualType 0 && {_territoryRatio >= 0.1 && {_territoryRatio <= 0.9}}) then {
        throw format ["Mission config startingTerritoryWestRatio must be between 0.1 and 0.9, got %1", _territoryRatio];
    };
    private _startPosition = FLO_MissionConfig get "startPosition";
    if !(_startPosition isEqualType [] && {(count _startPosition) >= 2} && {{_x isEqualType 0} count _startPosition == count _startPosition}) then {
        throw format ["Mission config startPosition is invalid: %1", _startPosition];
    };
    if ((_startPosition select 0) < 0 || {(_startPosition select 0) > worldSize || {(_startPosition select 1) < 0 || {(_startPosition select 1) > worldSize}}}) then {
        throw format ["Mission config startPosition is outside the terrain: %1", _startPosition];
    };

    // Saved campaigns keep the composition they started with.
    if (!_loadedSave) then {
        {
            _x params ["_field", "_sideLabel"];
            FLO_MissionConfig set [_field, [FLO_MissionConfig get _field, _sideLabel] call FLO_fnc_validateMissionTuningHandle];
        } forEach [["westFactionTuningHandle", "BLUFOR"], ["eastFactionTuningHandle", "OPFOR"]];
        publicVariable "FLO_MissionConfig";
    };

    [_fileConfig] call FLO_fnc_applyArtillerySettings;
} catch {
    _configError = _exception;
};
if (_configError != "") exitWith {
    FLO_InitError = format ["Mission faction configuration rejected: %1", _configError];
    publicVariable "FLO_InitError";
    ["INIT", 1, FLO_InitError] call FLO_fnc_log;
    false
};

FLO_BluforHandle = FLO_MissionConfig get "bluforHandle";
FLO_OpforHandle = FLO_MissionConfig get "opforHandle";
FLO_CivilianHandle = FLO_MissionConfig get "civilianHandle";
FLO_ActivePlayerSide = [_playerSideKey] call FLO_fnc_campaignSideFromKey;
publicVariable "FLO_ActivePlayerSide";

private _adaptedPlayerCount = 0;
{
    if ([_x] call FLO_fnc_playerSideAdapterApply) then {
        _adaptedPlayerCount = _adaptedPlayerCount + 1;
    };
} forEach ([] call FLO_fnc_getConnectedHumanPlayers);

FLO_ReputationHandle = FLO_MissionConfig get "reputationHandle";
FLO_WestDifficultyHandle = FLO_MissionConfig get "westDifficultyHandle";
FLO_EastDifficultyHandle = FLO_MissionConfig get "eastDifficultyHandle";
FLO_WestGTN_AttackCoverageHandle = FLO_MissionConfig get "westGTNAttackCoverageHandle";
FLO_EastGTN_AttackCoverageHandle = FLO_MissionConfig get "eastGTNAttackCoverageHandle";
FLO_WestGTN_DefenseCoverageHandle = FLO_MissionConfig get "westGTNDefenseCoverageHandle";
FLO_EastGTN_DefenseCoverageHandle = FLO_MissionConfig get "eastGTNDefenseCoverageHandle";
FLO_WestGTN_TempoHandle = FLO_MissionConfig get "westGTNTempoHandle";
FLO_EastGTN_TempoHandle = FLO_MissionConfig get "eastGTNTempoHandle";
FLO_WestGTN_ForceGrowthHandle = FLO_MissionConfig get "westGTNForceGrowthHandle";
FLO_EastGTN_ForceGrowthHandle = FLO_MissionConfig get "eastGTNForceGrowthHandle";
FLO_WestGTN_GarrisonHandle = FLO_MissionConfig get "westGTNGarrisonHandle";
FLO_EastGTN_GarrisonHandle = FLO_MissionConfig get "eastGTNGarrisonHandle";

FLO_WestFactionTuningHandle = FLO_MissionConfig get "westFactionTuningHandle";
FLO_EastFactionTuningHandle = FLO_MissionConfig get "eastFactionTuningHandle";

FLO_ObjectiveSizeThreshold = FLO_MissionConfig get "objectiveSizeThreshold";
FLO_VirtualizationDistance = FLO_MissionConfig get "virtualizationDistance";
FLO_VirtualizationUnitCap = FLO_MissionConfig get "virtualizationUnitCap";
FLO_StartingTerritoryWestRatio = FLO_MissionConfig get "startingTerritoryWestRatio";

StartingLocationDone = true;
publicVariable "StartingLocationDone";

["INIT", 3, format [
    "Phase 1 committed native factions: BLUFOR=%1 OPFOR=%2 CIVILIAN=%3 playerSide=%4",
    FLO_BluforHandle get "name",
    FLO_OpforHandle get "name",
    FLO_CivilianHandle get "name",
    _playerSideKey
]] call FLO_fnc_log;

if (_adaptedPlayerCount > 0) then {
    ["INIT", 3, format [
        "Adapted %1 connected human slot(s) to campaign side %2",
        _adaptedPlayerCount,
        _playerSideKey
    ]] call FLO_fnc_log;
};

true
