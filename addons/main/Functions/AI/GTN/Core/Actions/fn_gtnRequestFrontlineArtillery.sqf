/* Requests one paid artillery mission from maintained frontline contact intelligence. */
params ["_cmdr", "_requestedObjective"];

private _metrics = createHashMapFromArray [
    ["assetAvailable", false],
    ["candidateCount", 0],
    ["eligibleCount", 0],
    ["lockedCount", 0],
    ["requestedCount", 0],
    ["selectedObjective", ""],
    ["selectedScore", 0],
    ["authorized", false],
    ["denial", ""]
];
private _deny = {
    params ["_code"];
    _metrics set ["denial", _code];
    ["GTN", 3, format ["Frontline artillery for %1 denied: %2", _requestedObjective, _code]] call FLO_fnc_log;
    _metrics
};
if (isNil "_cmdr") exitWith { _metrics };

private _ws = _cmdr get "_worldState";
if !(_ws call ["_isAssetAvailable", ["artillery"]]) exitWith { ["NO_ASSET"] call _deny };
_metrics set ["assetAvailable", true];
if ((_cmdr get "_frontlineSupportPictureBuiltAt") < 0) exitWith { ["NO_SUPPORT_PICTURE"] call _deny };

private _picture = _cmdr get "_frontlineSupportPicture";
private _ownSide = _cmdr get "_ownSide";
private _enemySide = _cmdr get "_enemySide";
private _objectives = _ws call ["_getObjectives", []];
private _frontline = _cmdr call ["_getAttackFrontlineEnemyObjectives", []];
private _attackCounts = ((_cmdr get "_objectiveAssignmentCache") get "attackCounts");
private _config = _cmdr get "_config";
private _locks = _cmdr get "_frontlineArtilleryLocks";
private _now = diag_tickTime;

private _expiredLocks = [];
{
    if ((_locks get _x) <= _now || {!(_x in _objectives)}) then {
        _expiredLocks pushBack _x;
    };
} forEach (keys _locks);
{ _locks deleteAt _x; } forEach _expiredLocks;

private _bestObjectiveId = "";
private _bestScore = -1e12;
private _skip = "NOT_IN_PICTURE";
{
    private _objectiveId = _x;
    if (_objectiveId != _requestedObjective) then { continue };
    private _contact = _y;
    _skip = "NOT_FRONTLINE";
    if !(_objectiveId in _frontline) then { continue };
    if !(_objectiveId in _objectives) then {
        throw format ["Frontline artillery picture references missing objective %1", _objectiveId];
    };
    _skip = "NOT_ENEMY_OWNED";
    if (((_objectives get _objectiveId) get "owner") isNotEqualTo _enemySide) then { continue };
    _metrics set ["candidateCount", (_metrics get "candidateCount") + 1];
    _skip = format ["OBJECTIVE_LOCKED:%1s", round ((_locks getOrDefault [_objectiveId, _now]) - _now)];
    if (_objectiveId in _locks) then {
        _metrics set ["lockedCount", (_metrics get "lockedCount") + 1];
        continue;
    };
    _skip = "NO_REPORTS";
    if ((_contact get "reportCount") <= 0) then { continue };
    _skip = format ["LOW_CONFIDENCE:%1", (_contact get "confidence") toFixed 2];
    if ((_contact get "confidence") < (_config get "frontlineSupportMinimumConfidence")) then { continue };
    private _activeAttackers = if (_objectiveId in _attackCounts) then {
        _attackCounts get _objectiveId
    } else {
        0
    };
    private _score = (_contact get "score") + (_activeAttackers * 3);
    _metrics set ["eligibleCount", (_metrics get "eligibleCount") + 1];
    if (_score > _bestScore) then {
        _bestObjectiveId = _objectiveId;
        _bestScore = _score;
    };
} forEach _picture;

if (_bestObjectiveId == "") exitWith { [_skip] call _deny };
if (_bestScore < (_config get "frontlineArtilleryMinScore")) exitWith { [format ["LOW_SCORE:%1", round _bestScore]] call _deny };
private _manager = _cmdr get "_artilleryManager";
private _requestStatus = [_manager, _ownSide, _bestObjectiveId] call FLO_fnc_gtnArtilleryCanRequestMission;
if !(_requestStatus select 0) exitWith { [format ["%1:%2s", _requestStatus select 1, _requestStatus select 2]] call _deny };

private _contact = _picture get _bestObjectiveId;
private _fresh = (_contact get "freshReportCount") > 0;
private _accuracy = [
    _config get "frontlineArtilleryStaleAccuracy",
    _config get "frontlineArtilleryFreshAccuracy"
] select _fresh;
private _targetContext = createHashMapFromArray [
    ["targetGroupIds", +(_contact get "targetGroupIds")],
    ["contactState", ["FRONTLINE_STALE", "FRONTLINE_FRESH"] select _fresh],
    ["contactConfidence", _contact get "confidence"],
    ["contactAgeSeconds", _contact get "ageSeconds"],
    ["uncertaintyRadius", _contact get "uncertaintyRadius"]
];
private _authorized = _manager call ["_requestFireMission", [
    _contact get "targetPos",
    _config get "frontlineArtilleryRounds",
    _accuracy,
    _ownSide,
    _bestObjectiveId,
    "FRONTLINE",
    false,
    _targetContext
]];
_metrics set ["requestedCount", 1];
_metrics set ["selectedObjective", _bestObjectiveId];
_metrics set ["selectedScore", _bestScore];
_metrics set ["authorized", _authorized];
_locks set [
    _bestObjectiveId,
    _now + ([
        _config get "frontlineArtilleryRetrySeconds",
        _config get "frontlineArtilleryObjectiveLockSeconds"
    ] select _authorized)
];

if (!_authorized) then {
    [format ["FIRE_MISSION_REFUSED:live=%1 available=%2",
        _manager call ["_isLiveArea", [_contact get "targetPos"]],
        count ([_manager, _ownSide] call FLO_fnc_gtnArtilleryGetAvailableGroups)
    ]] call _deny;
};
if (_authorized) then {
    ["GTN", 3, format [
        "Frontline artillery authorized for %1 from %2 contact reports (score=%3 age=%4s)",
        _bestObjectiveId,
        _contact get "reportCount",
        round _bestScore,
        round (_contact get "ageSeconds")
    ]] call FLO_fnc_log;
};

_metrics
