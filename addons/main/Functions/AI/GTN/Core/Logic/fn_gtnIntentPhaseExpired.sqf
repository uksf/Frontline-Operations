/*
 * Function: FLO_fnc_gtnIntentPhaseExpired
 * Description:
 *   Decides whether an intent's current phase has run out of time. A phase
 *   expires after 1800 seconds (3600 for SECURE). A movement phase (ASSEMBLE
 *   or ARRIVE) gets more time while its force still closes on the target:
 *   it expires only when the summed group distance has not dropped by 100 m
 *   for 300 seconds, or after 5400 seconds in total.
 *
 * Arguments:
 * 0: Intent <HASHMAP>
 * 1: Virtual group map <HASHMAP>
 *
 * Return Value:
 * True when the phase has expired <BOOL>
 */

params ["_intent", "_groups"];

private _phase = _intent get "phase";
private _elapsed = diag_tickTime - (_intent get "phaseStartedAt");
private _limit = [1800, 3600] select (_phase == "SECURE");
if !(_phase in ["ASSEMBLE", "ARRIVE"]) exitWith { _elapsed > _limit };

private _target = [_intent get "targetPos", _intent get "stagePos"] select (_phase == "ASSEMBLE");
private _distance = 0;
{
    private _group = _groups get _x;
    private _groupTarget = _target;
    if ((_intent get "kind") == "GARRISON" && {(_group getOrDefault ["garrisonPosition", []]) isNotEqualTo []}) then {
        _groupTarget = _group get "garrisonPosition";
    };
    _distance = _distance + ((_group get "position") distance2D _groupTarget);
} forEach ((_intent get "groupIds") select { _x in _groups });

private _progress = _intent getOrDefault ["phaseProgress", []];
if ((_progress param [0, ""]) != _phase) then {
    _progress = [_phase, _distance, diag_tickTime];
    _intent set ["phaseProgress", _progress];
};
if (_distance < ((_progress select 1) - 100)) then {
    _progress set [1, _distance];
    _progress set [2, diag_tickTime];
};

_elapsed > _limit && {_elapsed > 5400 || {(diag_tickTime - (_progress select 2)) > 300}}
