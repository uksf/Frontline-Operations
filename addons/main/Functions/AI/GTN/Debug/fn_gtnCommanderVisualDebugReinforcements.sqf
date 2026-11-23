/*
 * Function: FLO_fnc_gtnCommanderVisualDebugReinforcements
 * Author: Frontline Operations Development Group
 * Description:
 *   Draws one commander's reinforcement debug markers: friendly objectives
 *   under player pressure, the last logistics target, reinforcing and AA
 *   deploying groups, and their inbound objectives. Adds each drawn marker
 *   ID to the active ID list.
 *
 * Arguments:
 *   0: Commander side key <STRING>
 *   1: Commander side <SIDE>
 *   2: Enemy side <SIDE>
 *   3: Marker colour of the commander side <STRING>
 *   4: Friendly objectives <HASHMAP>
 *   5: Virtual group map <HASHMAP>
 *   6: Active marker IDs, extended in place <ARRAY>
 *
 * Return Value: None
 *
 * Example:
 *   [_cmdSideKey, _ownSide, _enemySide, _ownColor, _friendlyObjectives, _allGroups, _activeIds] call FLO_fnc_gtnCommanderVisualDebugReinforcements;
 */

params ["_cmdSideKey", "_ownSide", "_enemySide", "_ownColor", "_friendlyObjectives", "_allGroups", "_activeIds"];

private _detectRange = 2000;
private _logNetwork = nil;
if (!isNil "FLO_Logistics_Networks" && {FLO_Logistics_Networks isEqualType createHashMap}) then {
    _logNetwork = FLO_Logistics_Networks getOrDefault [_cmdSideKey, nil];
};
if (!isNil "_logNetwork") then {
    _detectRange = _logNetwork get "BLUFOR_DETECT_RANGE";
};

private _reinforcementPointRows = [];
{
    private _objId = _x;
    private _objData = _friendlyObjectives get _objId;
    private _objPos = _objData get "position";
    private _enemyPressure = {
        side _x == _enemySide && {_x distance2D _objPos < _detectRange}
    } count ([] call FLO_fnc_getConnectedHumanPlayers);
    if (_enemyPressure > 0) then {
        _reinforcementPointRows pushBack [_objId, _enemyPressure, _objData get "priority", _objPos];
    };
} forEach (keys _friendlyObjectives);
private _reinforcementRanked = _reinforcementPointRows apply { [((_x select 1) * 100 + (_x select 2)), _x] };
_reinforcementRanked sort false;
_reinforcementPointRows = _reinforcementRanked apply { _x select 1 };

private _maxReinfPointDebug = (count _reinforcementPointRows) min 8;
for "_i" from 0 to (_maxReinfPointDebug - 1) do {
    private _row = _reinforcementPointRows select _i;
    _row params ["_objId", "_enemyPressure", "_priority", "_objPos"];

    private _reinfPointMarkerId = format ["FLO_GTN_DBG_%1_REINF_PT_%2", _cmdSideKey, _objId];
    _activeIds pushBack _reinfPointMarkerId;
    private _reinfPointText = format [
        "%1 REINF PT %2 | pressure:%3 prio:%4",
        _cmdSideKey,
        _objId,
        _enemyPressure,
        _priority
    ];
    [_reinfPointMarkerId, _objPos, "mil_marker", _ownColor, _reinfPointText, [0.65, 0.65], 0.75] call FLO_fnc_gtnCommanderDebugUpsertMarker;
};

if (!isNil "_logNetwork") then {
    private _lastReinfTarget = _logNetwork get "_lastReinforcementTarget";
    if (_lastReinfTarget != "" && {_lastReinfTarget in FLO_Objectives}) then {
        private _lastTargetPos = (FLO_Objectives get _lastReinfTarget) get "position";
        private _lastMarkerId = format ["FLO_GTN_DBG_%1_REINF_LAST", _cmdSideKey];
        _activeIds pushBack _lastMarkerId;
        [_lastMarkerId, _lastTargetPos, "mil_objective", _ownColor, format ["%1 LOGI LAST %2", _cmdSideKey, _lastReinfTarget], [0.8, 0.8], 0.9] call FLO_fnc_gtnCommanderDebugUpsertMarker;
    };
};

private _reinforcingObjectiveCounts = createHashMap;
{
    private _groupId = _x;
    private _gData = _allGroups get _groupId;
    if (isNil "_gData") then { continue };
    if ((_gData get "side") != _ownSide) then { continue };

    private _isReinforcing = (_gData get "replacementState") == "REINFORCE";
    private _isAAMoving = (_gData get "replacementState") == "AA_DEPLOY";
    if !(_isReinforcing || _isAAMoving) then { continue };

    private _groupPos = _gData get "position";
    private _groupType = _gData get "groupType";
    private _groupUnits = _gData get "unitCount";
    private _targetObjective = if (_isAAMoving) then {
        (_gData get "aaDeployTargetObjective")
    } else {
        _gData get "homeObjective"
    };

    private _reinfGroupMarkerId = format ["FLO_GTN_DBG_%1_REINF_GROUP_%2", _cmdSideKey, _groupId];
    _activeIds pushBack _reinfGroupMarkerId;
    private _reinfGroupText = format [
        "%1 REINF %2 u%3 %4 -> %5",
        _cmdSideKey,
        _groupId,
        _groupUnits,
        _groupType,
        [_targetObjective, "free"] select (_targetObjective == "")
    ];
    [_reinfGroupMarkerId, _groupPos, ["mil_arrow", "mil_warning"] select (_isAAMoving), _ownColor, _reinfGroupText, [0.55, 0.55], 0.95] call FLO_fnc_gtnCommanderDebugUpsertMarker;

    if (_targetObjective != "" && {_targetObjective in FLO_Objectives}) then {
        _reinforcingObjectiveCounts set [_targetObjective, (_reinforcingObjectiveCounts getOrDefault [_targetObjective, 0]) + 1];
    } else {
        if (_isAAMoving) then {
            private _targetPos = (_gData get "aaDeployTargetPos");
            if (count _targetPos >= 2) then {
                private _aaTargetMarkerId = format ["FLO_GTN_DBG_%1_REINF_AA_TGT_%2", _cmdSideKey, _groupId];
                _activeIds pushBack _aaTargetMarkerId;
                [_aaTargetMarkerId, _targetPos, "mil_dot", _ownColor, format ["%1 AA DEPLOY", _cmdSideKey], [0.5, 0.5], 0.8] call FLO_fnc_gtnCommanderDebugUpsertMarker;
            };
        };
    };
} forEach (keys _allGroups);

{
    private _objId = _x;
    private _count = _reinforcingObjectiveCounts get _objId;
    private _objPos = (FLO_Objectives get _objId) get "position";
    private _reinfTargetMarkerId = format ["FLO_GTN_DBG_%1_REINF_TGT_%2", _cmdSideKey, _objId];
    _activeIds pushBack _reinfTargetMarkerId;
    [_reinfTargetMarkerId, _objPos, "mil_dot", _ownColor, format ["%1 REINF INBOUND %2 x%3", _cmdSideKey, _objId, _count], [0.6, 0.6], 0.8] call FLO_fnc_gtnCommanderDebugUpsertMarker;
} forEach (keys _reinforcingObjectiveCounts);
