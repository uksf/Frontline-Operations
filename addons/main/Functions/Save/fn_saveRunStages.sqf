/* Runs one campaign save as ordered stages inside one PFH.
 * Each stage call does one bounded unit of work and returns true when the stage is complete.
 * The PFH calls stages until the frame budget is used, so one atomic unit may exceed it.
 * A stage that stops with a script error leaves inStage set; the next frame fails the save.
 *
 * Arguments:
 *   0: Save context <HASHMAP> - built by FLO_fnc_MissionSave
 * Returns: <NUMBER> - PFH handle
 */
params ["_ctx"];

[{
    params ["_ctx", "_pfh"];
    private _stages = _ctx get "stages";
    private _perf = _ctx get "perf";

    if (_ctx get "inStage") exitWith {
        [_pfh] call CBA_fnc_removePerFrameHandler;
        private _name = (_stages select (_ctx get "index")) select 0;
        [false, format ["Save stage %1 stopped with a script error", _name]] call FLO_fnc_saveFinish;
    };

    private _frameStart = diag_tickTime;
    private _failure = "";
    private _complete = false;
    while {!_complete && {_failure == ""} && {diag_tickTime - _frameStart < (_ctx get "frameBudget")}} do {
        private _index = _ctx get "index";
        (_stages select _index) params ["_name", "_step"];
        private _stepStart = diag_tickTime;
        private _stageDone = false;
        _ctx set ["inStage", true];
        try { _stageDone = [_ctx] call _step } catch { _failure = format ["%1", _exception] };
        _ctx set ["inStage", false];
        if (_failure == "" && {isNil "_stageDone" || {!(_stageDone isEqualType true)}}) then {
            _failure = format ["Save stage %1 returned no Boolean result", _name];
        };

        private _stepMs = (diag_tickTime - _stepStart) * 1000;
        private _stagePerf = _perf getOrDefault [_name, [0, 0, 0]];
        _perf set [_name, [(_stagePerf select 0) + _stepMs, (_stagePerf select 1) + 1, (_stagePerf select 2) max _stepMs]];

        if (_failure == "" && {_stageDone}) then {
            _ctx set ["index", _index + 1];
            _complete = _index + 1 >= count _stages;
        };
    };

    private _frameMs = (diag_tickTime - _frameStart) * 1000;
    _ctx set ["frames", (_ctx get "frames") + 1];
    _ctx set ["maxFrameMs", (_ctx get "maxFrameMs") max _frameMs];

    if (!_complete && {_failure == ""}) exitWith {};

    [_pfh] call CBA_fnc_removePerFrameHandler;
    ["SAVE", 3, format [
        "[PERF] Save stages frames=%1 maxFrameMs=%2 stages=%3",
        _ctx get "frames",
        _ctx get "maxFrameMs",
        _stages apply { private _p = _perf getOrDefault [_x select 0, [0, 0, 0]]; [_x select 0, _p select 0, _p select 1, _p select 2] }
    ]] call FLO_fnc_log;

    if (_failure != "") exitWith { [false, _failure] call FLO_fnc_saveFinish };
    private _saved = _ctx getOrDefault ["saved", false];
    [_saved, ["Campaign validation or disk write rejected; see preceding SAVE error", ""] select _saved] call FLO_fnc_saveFinish;
}, 0, _ctx] call CBA_fnc_addPerFrameHandler
