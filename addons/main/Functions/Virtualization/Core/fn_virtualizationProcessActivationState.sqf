/*
 * Function: FLO_fnc_virtualizationProcessActivationState
 */

params ["_groupId", "_groupData", "_activationDist", "_nearestDist", "_forceVirtual", "_missionLock", "_replacementState", "_inCombat", "_virtStats"];

private _isActive = _groupData get "isActive";
private _activationDeferred = _groupData get "activationDeferred";
private _activationUnitCap = ["activationUnitCap"] call FLO_fnc_virtualizationGetConfigValue;
private _activationResumeCap = ["activationResumeCap"] call FLO_fnc_virtualizationGetConfigValue;
private _activationRetryCooldown = ["activationRetryCooldown"] call FLO_fnc_virtualizationGetConfigValue;
private _activeUnitCount = FLO_VirtUpdate get "activeUnitCount";
if (_activationDeferred && {_nearestDist > (_activationDist + 10)}) then {
    _groupData set ["activationDeferred", false];
    _groupData set ["activationDeferredAt", -1];
    _activationDeferred = false;
    (FLO_VirtUpdate get "deferredQueue") deleteAt _groupId;
    (FLO_VirtUpdate get "lateSpawnClearance") deleteAt _groupId;
};

if (!_forceVirtual && {_nearestDist <= _activationDist} && {!_isActive}) exitWith {
    private _activationRetryAt = _groupData get "activationRetryAt";
    if (_activationRetryAt > diag_tickTime) exitWith {
        _virtStats set ["activationBlocksTotal", (_virtStats get "activationBlocksTotal") + 1];
        _virtStats set ["activationBlocksThisBatch", (_virtStats get "activationBlocksThisBatch") + 1];
        _virtStats set ["activeUnitsLast", FLO_VirtUpdate get "activeUnitCount"];
        true
    };

    // The combat overlay cannot bypass a live handoff rejected by the cap.
    // Explicit strategic missions retain their existing activation exception.
    private _bypassBudget = _missionLock != "" || {_replacementState != ""};
    private _activationLoad = [_groupData, true] call FLO_fnc_virtualizationGetGroupUnitLoad;
    private _projectedUnitCount = _activeUnitCount + _activationLoad + ([_groupId] call FLO_fnc_virtualizationGetStagedUnitLoad);
    private _blockActivation = false;
    private _nearerDeferredLoad = 0;

    if (!_bypassBudget && {!(_groupId in (FLO_VirtUpdate get "stagedGroups"))}) then {
        _nearerDeferredLoad = [_groupId, _nearestDist] call FLO_fnc_virtualizationGetNearerDeferredLoad;
        _blockActivation = (_projectedUnitCount + _nearerDeferredLoad) > _activationUnitCap;
        if (_activationDeferred && {_nearerDeferredLoad > 0} && {_activeUnitCount >= _activationResumeCap}) then {
            _blockActivation = true;
        };
    };

    if (!_blockActivation && {!([_groupId] call FLO_fnc_virtualizationClaimActivationSlot)}) exitWith {
        _virtStats set ["activationFrameSkipsTotal", (_virtStats get "activationFrameSkipsTotal") + 1];
        true
    };

    private _holdLateSpawn = false;
    if (!_blockActivation && {!(_groupId in (FLO_VirtUpdate get "stagedGroups"))}) then {
        private _deferredAt = _groupData get "activationDeferredAt";
        private _waited = [0, round (diag_tickTime - _deferredAt)] select (_activationDeferred && {_deferredAt >= 0});
        if (_waited >= (missionNamespace getVariable ["FLO_VirtLateSpawnWait", 60])) then {
            _holdLateSpawn = !([_groupId, _groupData] call FLO_fnc_virtualizationCheckLateSpawn);
            _nearestDist = [_groupData get "position"] call FLO_fnc_virtualizationGetNearestCachedPlayerDistance;
        };
        if (!_holdLateSpawn) then {
            ["VIRTUALIZATION", 3, format["Activating %1 (dist: %2m, waited: %3s)", _groupId, round _nearestDist, _waited]] call FLO_fnc_log;
        };
    };

    if (_holdLateSpawn) exitWith {
        (FLO_VirtUpdate get "deferredQueue") deleteAt _groupId;
        _groupData set ["activationRetryAt", diag_tickTime + _activationRetryCooldown];
        true
    };

    if (!_blockActivation && {[_groupId, _groupData] call FLO_fnc_virtualizationStageActivation}) exitWith {
        (FLO_VirtUpdate get "deferredQueue") deleteAt _groupId;
        true
    };

    if (_blockActivation) then {
        (FLO_VirtUpdate get "deferredQueue") set [_groupId, [_nearestDist, _activationLoad, diag_tickTime]];
        if (_nearerDeferredLoad == 0 && {_nearestDist <= (missionNamespace getVariable ["FLO_VirtEvictionDistance", 800])}) then {
            [_groupId] call FLO_fnc_virtualizationEvictFarActiveGroup;
        };
        if (!_activationDeferred) then {
            _groupData set ["activationDeferredAt", diag_tickTime];
        };
        _groupData set ["activationDeferred", true];
        _virtStats set ["activationBlocksTotal", (_virtStats get "activationBlocksTotal") + 1];
        _virtStats set ["activationBlocksThisBatch", (_virtStats get "activationBlocksThisBatch") + 1];
        _virtStats set ["deferredGroupsLast", (_virtStats get "deferredGroupsLast") + ([1, 0] select (_activationDeferred))];
        _virtStats set ["activeUnitsLast", _activeUnitCount];
    } else {
        if ([_groupId, _bypassBudget || {_groupId in (FLO_VirtUpdate get "stagedGroups")}] call FLO_fnc_virtualizationTryActivateGroup) then {
            (FLO_VirtUpdate get "deferredQueue") deleteAt _groupId;
            _groupData set ["activationDeferred", false];
            _groupData set ["activationDeferredAt", -1];
            _groupData set ["activationRetryAt", -1];
            _virtStats set ["activationsTotal", (_virtStats get "activationsTotal") + 1];
            _virtStats set ["activationsThisBatch", (_virtStats get "activationsThisBatch") + 1];
            _virtStats set ["activeUnitsLast", FLO_VirtUpdate get "activeUnitCount"];
            _virtStats set ["deferredGroupsLast", ((_virtStats get "deferredGroupsLast") - ([0, 1] select (_activationDeferred))) max 0];
        } else {
            private _routeRetryAt = _groupData get "landRouteRetryAt";
            private _retryAt = (diag_tickTime + _activationRetryCooldown) max _routeRetryAt;
            _groupData set ["activationRetryAt", _retryAt];
            _virtStats set ["activationBlocksTotal", (_virtStats get "activationBlocksTotal") + 1];
            _virtStats set ["activationBlocksThisBatch", (_virtStats get "activationBlocksThisBatch") + 1];
            _virtStats set ["activeUnitsLast", FLO_VirtUpdate get "activeUnitCount"];
        };
    };

    true
};

// Separate boundaries prevent repeated spawn/delete as a player moves along the edge.
private _deactivationDist = _activationDist * (["deactivationDistanceMultiplier"] call FLO_fnc_virtualizationGetConfigValue);
if (_nearestDist > _deactivationDist && {_isActive} && {
    private _leader = leader (_groupData get "realGroup");
    private _holdPos = [getPosATL vehicle _leader, _groupData get "position"] select (isNull _leader);
    ([_holdPos, (_groupData get "groupType") in ["helicopter", "air", "jet"], false, true] call FLO_fnc_virtualizationGetNearestCachedPlayerDistance) > _deactivationDist
}) then {
    private _alwaysActive = _groupData get "alwaysActive";
    private _physicalContact = false;
    if (_inCombat) then {
        private _leader = leader (_groupData get "realGroup");
        if (!isNull _leader && {alive _leader}) then {
            private _enemy = _leader findNearestEnemy _leader;
            _physicalContact = !isNull _enemy && {alive _enemy} && {_leader distance2D _enemy <= _activationDist};
        };
    };
    private _missionHoldActive = _missionLock != "" && {_replacementState == ""};
    if (_missionHoldActive && {_missionLock == "TRANSPORT"} && {[_groupData] call FLO_fnc_virtualizationIsTransportCarrier}) then {
        _missionHoldActive = [_groupData] call FLO_fnc_transportCarrierBlocksDeactivation;
    };

    if (_missionHoldActive || {_alwaysActive} || {_physicalContact}) then {
        _virtStats set ["missionHoldSkipsTotal", (_virtStats get "missionHoldSkipsTotal") + 1];
        _virtStats set ["missionHoldSkipsThisBatch", (_virtStats get "missionHoldSkipsThisBatch") + 1];
    } else {
        private _deactivationLoad = [_groupData, true] call FLO_fnc_virtualizationGetGroupUnitLoad;
        ["VIRTUALIZATION", 3, format["Deactivating %1 (dist: %2m)", _groupId, round _nearestDist]] call FLO_fnc_log;
        if ([_groupId, _groupData] call FLO_fnc_deactivateVirtualGroup) then {
            FLO_VirtUpdate set ["activeUnitCount", ((_activeUnitCount - _deactivationLoad) max 0)];
            _virtStats set ["deactivationsTotal", (_virtStats get "deactivationsTotal") + 1];
            _virtStats set ["deactivationsThisBatch", (_virtStats get "deactivationsThisBatch") + 1];
            _virtStats set ["activeUnitsLast", FLO_VirtUpdate get "activeUnitCount"];
        };
    };
};

true
