/*
 * Function: FLO_fnc_civilianUpdateProtests
 * Author: Frontline Operations Development Group
 * Description:
 *   Ends expired or invalid civilian protests and starts new protests against
 *   connected players standing in hostile or contested-wary objectives.
 *   Unscheduled calls index active civilian groups by objective once per call.
 *   Scheduled calls scan the live group map for each player, because the map can
 *   change while the call is suspended.
 *
 * Arguments:
 * 0: Civilian manager <HASHMAP>
 *
 * Return Value:
 * ARRAY [activeProtestCount, startedCount]
 */

params ["_manager"];

private _nowTick = diag_tickTime;
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _activeProtests = _manager get "_activeProtests";
private _cooldowns = _manager get "_objectiveProtestCooldowns";
private _endedObjectives = [];

{
    private _objectiveId = _x;
    private _record = _y;
    private _target = _record get "target";
    private _groupIds = _record get "groupIds";
    private _shouldEnd = false;

    if ((_record get "expiresAt") <= _nowTick || {isNull _target} || {!alive _target}) then {
        _shouldEnd = true;
    } else {
        private _targetSide = side group _target;
        if !(_targetSide in [east, west]) then {
            _targetSide = FLO_ActivePlayerSide;
        };

        private _context = _manager call ["getObjectiveContext", [_objectiveId, "resident", _targetSide]];
        private _objective = FLO_Objectives get _objectiveId;
        private _qualifies = ((_context get "disposition") == "HOSTILE") || {
            (_context get "disposition") == "WARY" && {(_objective get "contested")}
        };

        if (!_qualifies || {([getPosATL _target] call FLO_fnc_civilianResolveObjective) != _objectiveId}) then {
            _shouldEnd = true;
        };
    };

    if (_shouldEnd) then {
        {
            if !(_x in _groups) then { continue };
            private _groupData = _groups get _x;
            private _changes = createHashMapFromArray [["protestRestoreAlwaysActive", false]];
            if ((_groupData get "civilianRoutineState") == "protest") then {
                _changes set ["civilianRoutineUntil", _nowTick - 1];
            };
            private _realGroup = _groupData get "realGroup";
            private _hasDetainedUnits = false;
            if (!isNull _realGroup) then {
                {
                    if (alive _x && {captive _x}) then {
                        _hasDetainedUnits = true;
                    };
                    _x setVariable ["FLO_ProtestExpiresAt", _nowTick - 1, false];
                } forEach (units _realGroup);
            };
            if (!_hasDetainedUnits) then {
                _changes set ["alwaysActive", _groupData get "protestRestoreAlwaysActive"];
            };
            [_x, _changes] call FLO_fnc_virtualizationPatchGroup;
            if (!_hasDetainedUnits) then {
                _manager call ["retaskCivilianGroup", [_x, _groupData]];
            };
        } forEach _groupIds;
        _endedObjectives pushBack _objectiveId;
    };
} forEach _activeProtests;

{
    _activeProtests deleteAt _x;
} forEach _endedObjectives;

private _started = 0;
private _civilianGroupsByObjective = nil;
private _useObjectiveIndex = !canSuspend;
{
    private _player = _x;
    private _playerSide = side group _player;
    if !(_playerSide in [east, west]) then { continue };

    private _objectiveId = [getPosATL _player] call FLO_fnc_civilianResolveObjective;
    if (_objectiveId == "" || {!(_objectiveId in FLO_Objectives)}) then { continue };
    if (_objectiveId in _activeProtests) then { continue };
    if ((_cooldowns getOrDefault [_objectiveId, -1]) > _nowTick) then { continue };

    private _context = _manager call ["getObjectiveContext", [_objectiveId, "resident", _playerSide]];
    private _objective = FLO_Objectives get _objectiveId;
    private _qualifies = ((_context get "disposition") == "HOSTILE") || {
        (_context get "disposition") == "WARY" && {(_objective get "contested")}
    };
    if (!_qualifies) then { continue };

    if (_useObjectiveIndex && {isNil "_civilianGroupsByObjective"}) then {
        _civilianGroupsByObjective = createHashMap;
        {
            if ((_y get "side") != civilian || {!(_y get "isActive")}) then { continue };
            private _civilianObjective = _y getOrDefault ["civilianObjective", ""];
            private _objectiveGroups = _civilianGroupsByObjective getOrDefault [_civilianObjective, [], true];
            _objectiveGroups pushBack _x;
        } forEach _groups;
    };
    private _selectArgs = [_objectiveId, _player, FLO_CivilianConfig get "PROTEST_MAX_GROUPS"];
    if (_useObjectiveIndex) then { _selectArgs pushBack (_civilianGroupsByObjective getOrDefault [_objectiveId, []]) };
    private _selectedGroups = _selectArgs call FLO_fnc_civilianSelectObjectiveProtesters;
    if ((count _selectedGroups) < (FLO_CivilianConfig get "PROTEST_MIN_GROUPS")) then { continue };

    private _expiresAt = _nowTick + (FLO_CivilianConfig get "PROTEST_DURATION_SECONDS");
    private _protesters = [_player, _selectedGroups, _objectiveId, _expiresAt] call FLO_fnc_civilianProtest;
    if (_protesters isEqualTo []) then { continue };

    _activeProtests set [_objectiveId, createHashMapFromArray [
        ["target", _player],
        ["groupIds", _selectedGroups],
        ["expiresAt", _expiresAt]
    ]];
    _cooldowns set [_objectiveId, _expiresAt + (FLO_CivilianConfig get "PROTEST_COOLDOWN_SECONDS")];
    _started = _started + 1;
} forEach ([] call FLO_fnc_getConnectedHumanPlayers);

[count (keys _activeProtests), _started]
