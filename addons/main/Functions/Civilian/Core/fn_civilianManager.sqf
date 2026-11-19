/*
 * Function: FLO_fnc_civilianManager
 * Author: Frontline Operations Development Group
 * Description:
 *   Server-owned civilian manager for local mood, ambient state, and
 *   reputation-driven civilian policy.
 *
 * Return Value:
 * HASHMAP OBJECT - Civilian manager
 */

if (!isServer) exitWith { createHashMap };

if (!isNil "FLO_CivilianManager") exitWith {
    FLO_CivilianManager
};

private _civilianClass = [
    ["#type", "CivilianManager"],
    ["CONFIG", FLO_CivilianConfig],
    ["_objectiveContexts", createHashMap],
    ["_objectiveContextSignatures", createHashMap],
    ["_objectivePoiCaches", createHashMap],
    ["_poiBuilds", 0],
    ["_poiBuildMs", 0],
    ["_objectiveMemories", createHashMap],
    ["_lastUpdate", -1],
    ["_loopPfhId", -1],
    ["_lastCombatEventAt", -1],
    ["_routineCursor", 0],
    ["_gossipCursor", 0],
    ["_missionState", createHashMapFromArray [
        ["active", false],
        ["id", ""],
        ["type", ""],
        ["objectiveId", ""],
        ["briefing", ""],
        ["requestedByUid", ""],
        ["requestedByName", ""],
        ["startedAt", -1],
        ["taskId", ""],
        ["source", objNull],
        ["position", []],
        ["offer", createHashMap]
    ]],
    ["_activeProtests", createHashMap],
    ["_objectiveProtestCooldowns", createHashMap],
    ["_detentionRecords", createHashMap],

    ["getReputation", {
        FLO_ReputationHandle get "value"
    }],

    ["getObjectiveContext", {
        params [
            ["_objectiveId", "", [""]],
            ["_civilianRole", "resident", [""]],
            ["_reportingSide", FLO_ActivePlayerSide, [east]]
        ];

        if !(_reportingSide in [east, west]) then {
            _reportingSide = west;
        };

        private _contexts = _self get "_objectiveContexts";
        private _cacheKey = format ["%1|%2|%3", _objectiveId, _civilianRole, _reportingSide];
        if (_cacheKey in _contexts) exitWith {
            _contexts get _cacheKey
        };

        private _context = [_objectiveId, _civilianRole, _reportingSide] call FLO_fnc_civilianResolveObjectiveContext;
        _contexts set [_cacheKey, _context];
        _context
    }],

    ["getDisposition", {
        params [
            ["_objectiveId", "", [""]],
            ["_civilianRole", "resident", [""]],
            ["_reportingSide", FLO_ActivePlayerSide, [east]]
        ];
        (_self call ["getObjectiveContext", [_objectiveId, _civilianRole, _reportingSide]]) get "disposition"
    }],

    ["getObjectivePoiCache", {
        params [["_objectiveId", "", [""]]];

        private _poiCaches = _self get "_objectivePoiCaches";
        if (_objectiveId in _poiCaches) exitWith {
            _poiCaches get _objectiveId
        };

        private _buildStart = diag_tickTime;
        private _poiCache = [_objectiveId] call FLO_fnc_civilianBuildObjectivePoiCache;
        _poiCaches set [_objectiveId, _poiCache];
        _self set ["_poiBuilds", (_self get "_poiBuilds") + 1];
        _self set ["_poiBuildMs", (_self get "_poiBuildMs") + (diag_tickTime - _buildStart) * 1000];
        _poiCache
    }],

    ["getObjectiveMemories", {
        params [["_objectiveId", "", [""]], ["_nowTick", diag_tickTime, [0]]];

        private _ledger = _self get "_objectiveMemories";
        if !(_objectiveId in _ledger) exitWith { [] };

        private _activeMemories = [];
        {
            if ((_x get "expiresAt") > _nowTick) then {
                _activeMemories pushBack _x;
            };
        } forEach (_ledger get _objectiveId);

        _ledger set [_objectiveId, _activeMemories];
        _activeMemories
    }],

    ["recordObjectiveMemory", {
        params [["_memory", createHashMap, [createHashMap]], ["_nowTick", diag_tickTime, [0]]];
        [_self get "_objectiveMemories", _memory, _nowTick] call FLO_fnc_civilianMergeObjectiveMemory;
        true
    }],

    ["ingestCombatEvents", {
        private _ledger = _self get "_objectiveMemories";
        private _lastProcessedAt = _self get "_lastCombatEventAt";
        private _result = [_ledger, _lastProcessedAt, diag_tickTime] call FLO_fnc_civilianIngestCombatEvents;
        _result params ["_latestProcessedAt", "_addedCount"];
        _self set ["_lastCombatEventAt", _latestProcessedAt];
        _addedCount
    }],

    ["propagateObjectiveGossip", {
        private _ledger = _self get "_objectiveMemories";
        private _cursor = _self get "_gossipCursor";
        private _result = [_ledger, _cursor, diag_tickTime] call FLO_fnc_civilianPropagateObjectiveGossip;
        _result params ["_addedCount", "_nextCursor"];
        _self set ["_gossipCursor", _nextCursor];
        _addedCount
    }],

    ["shouldFlee", {
        params [["_position", [0, 0, 0], [[]], [3]]];

        private _objectiveId = [_position] call FLO_fnc_civilianResolveObjective;
        if (_objectiveId == "") exitWith { false };

        private _reportingSide = FLO_ActivePlayerSide;
        if !(_reportingSide in [east, west]) then {
            _reportingSide = west;
        };

        private _context = _self call ["getObjectiveContext", [_objectiveId, "resident", _reportingSide]];
        if ((_context get "disposition") == "FRIENDLY") exitWith { false };

        private _cfg = _self get "CONFIG";
        private _radius = _cfg get "FLEE_RADIUS";
        private _nearbyPlayers = ([] call FLO_fnc_getConnectedHumanPlayers) select {
            _position distance2D (getPosATL _x) <= _radius
        };
        if (_nearbyPlayers isEqualTo []) exitWith { false };

        private _objective = FLO_Objectives get _objectiveId;
        (_objective get "contested") || {(_context get "disposition") in ["WARY", "HOSTILE"]}
    }],

    ["retaskCivilianGroup", {
        params [["_groupId", "", [""]], ["_groupData", createHashMap, [createHashMap]]];

        private _objectiveId = _groupData get "civilianObjective";
        if (_objectiveId == "") exitWith { false };
        private _realGroup = _groupData get "realGroup";
        if (!isNull _realGroup && {((units _realGroup) findIf { alive _x && {captive _x} }) isNotEqualTo -1}) exitWith { false };
        if ((_groupData get "civilianRoutineState") == "protest" && {(diag_tickTime < (_groupData get "civilianRoutineUntil"))}) exitWith { false };

        private _reportingSide = FLO_ActivePlayerSide;
        if !(_reportingSide in [east, west]) then {
            _reportingSide = west;
        };

        private _context = _self call ["getObjectiveContext", [_objectiveId, _groupData get "civilianRole", _reportingSide]];
        private _poiCache = _self call ["getObjectivePoiCache", [_objectiveId]];
        private _plan = [_groupData, _context, _poiCache, diag_tickTime] call FLO_fnc_civilianPlanRoutine;
        if ((keys _plan) isEqualTo []) exitWith { false };

        [_groupId, _plan] call FLO_fnc_civilianApplyRoutinePlan
    }],

    ["updateCivilianRoutines", {
        [_self] call FLO_fnc_civilianUpdateRoutines
    }],

    ["updateProtests", {
        [_self] call FLO_fnc_civilianUpdateProtests
    }],

    ["update", {
        if (isNil "FLO_Objectives") exitWith { false };

        private _updateStart = diag_tickTime;
        private _phaseStart = _updateStart;
        private _contextRefresh = [_self] call FLO_fnc_civilianRefreshObjectiveContexts;
        private _contextMs = (diag_tickTime - _phaseStart) * 1000;

        _self set ["_lastUpdate", diag_tickTime];

        _phaseStart = diag_tickTime;
        private _memoryIngested = _self call ["ingestCombatEvents", []];
        private _memoryMs = (diag_tickTime - _phaseStart) * 1000;
        _phaseStart = diag_tickTime;
        private _gossipAdded = _self call ["propagateObjectiveGossip", []];
        private _gossipMs = (diag_tickTime - _phaseStart) * 1000;
        _phaseStart = diag_tickTime;
        private _retaskedCount = _self call ["updateCivilianRoutines", []];
        private _routineMs = (diag_tickTime - _phaseStart) * 1000;
        _phaseStart = diag_tickTime;
        private _protestResult = _self call ["updateProtests", []];
        private _protestMs = (diag_tickTime - _phaseStart) * 1000;
        _protestResult params ["_activeProtestCount", "_startedProtests"];
        private _totalMs = (diag_tickTime - _updateStart) * 1000;

        if (_totalMs >= 5 || {FLO_Debug_Level >= 5}) then {
            diag_log format [
                "[FLO][PERF] Civilian manager total=%1ms contexts=%2 rebuilt=%3 changedObjectives=%4 | build=%5 memory=%6 gossip=%7 routines=%8 protests=%9 retasked=%10 | poiBuilds=%11 poiBuildMs=%12",
                _totalMs,
                _contextRefresh get "totalContexts",
                _contextRefresh get "rebuiltContexts",
                _contextRefresh get "changedObjectives",
                _contextMs,
                _memoryMs,
                _gossipMs,
                _routineMs,
                _protestMs,
                _retaskedCount,
                _self get "_poiBuilds",
                _self get "_poiBuildMs"
            ];
        };
        _self set ["_poiBuilds", 0];
        _self set ["_poiBuildMs", 0];

        ["CIVILIAN", 4, format [
            "Civilian manager refreshed %1/%2 objective contexts across %3 changed objectives at rep %4 | memories=%5 gossip=%6 retasked=%7 protests=%8 started=%9",
            _contextRefresh get "rebuiltContexts",
            _contextRefresh get "totalContexts",
            _contextRefresh get "changedObjectives",
            _self call ["getReputation", []],
            _memoryIngested,
            _gossipAdded,
            _retaskedCount,
            _activeProtestCount,
            _startedProtests
        ]] call FLO_fnc_log;

        true
    }],

    ["start", {
        if ((_self get "_loopPfhId") >= 0) exitWith { true };

        private _interval = ((_self get "CONFIG") get "UPDATE_INTERVAL") max 5;
        private _pfhId = [{
            params ["_args", "_pfhId"];
            _args params ["_manager"];

            if (isNil "FLO_CivilianManager") exitWith {
                [_pfhId] call CBA_fnc_removePerFrameHandler;
            };

            _manager call ["update", []];
        }, _interval, [_self]] call CBA_fnc_addPerFrameHandler;

        _self set ["_loopPfhId", _pfhId];
        true
    }],

    ["init", {
        [_self] call FLO_fnc_civilianWarmPoiCaches;
        ["CIVILIAN", 3, "Civilian manager initialized; warming objective POI caches before the worker starts"] call FLO_fnc_log;
        true
    }]
];

FLO_CivilianManager = createHashMapObject [_civilianClass];
FLO_CivilianManager call ["init", []];

FLO_CivilianManager
