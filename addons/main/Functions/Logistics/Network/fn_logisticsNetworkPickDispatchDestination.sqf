/* Check delivery reachability in sector-priority order. Lower ranked sectors do
 * not need a route search once the best serviceable sector has been found.
 */
params ["_net", "_candidates", "_type", "_throughput", "_blocked", "_inbound", "_deliveryInbound", "_recent", "_batch", "_rejections", "_perf"];
private _sources = [_net] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _enemyKey = ["opforCount", "bluforCount"] select ((_net get "_managedSide") isEqualTo east);
if ((keys _sources) findIf {
    !(_x in _blocked) && {((_sources get _x) get "throughput") >= _throughput} && {((FLO_Objectives get _x) get _enemyKey) == 0}
} < 0) exitWith { ["", ""] };
private _trailsKey = _type in ["infantry"];
private _routeBlockedUntil = _net get "_routeBlockedUntil";
private _isRouteBlocked = { (_routeBlockedUntil getOrDefault [format ["%1|%2", _this, _trailsKey], 0]) > diag_tickTime };
private _deliveryInboundForPick = +_deliveryInbound;
private _routeBlockedCount = 0;
{
    (_x splitString "|") params ["_objectiveId", "_trails"];
    if (_trails == str _trailsKey && {_objectiveId call _isRouteBlocked}) then {
        _deliveryInboundForPick set [_objectiveId, _net get "REINFORCEMENT_DELIVERY_INBOUND_CAP"];
        _routeBlockedCount = _routeBlockedCount + 1;
    };
} forEach keys _routeBlockedUntil;
private _remaining = +_candidates;
private _result = ["", ""];
while {_remaining isNotEqualTo []} do {
    private _started = diag_tickTime;
    private _requested = [_net, _remaining, _type, _inbound, _recent, _batch, _rejections] call FLO_fnc_logisticsNetworkPickBestTarget;
    _perf set ["dispatchTargetPickMs", (_perf get "dispatchTargetPickMs") + (diag_tickTime - _started) * 1000];
    if (_requested == "") exitWith {};
    _remaining = _remaining - [_requested];
    _started = diag_tickTime;
    private _delivery = "";
    if (_type == "static_aa") then {
        if ((_deliveryInboundForPick getOrDefault [_requested, 0]) < (_net get "REINFORCEMENT_DELIVERY_INBOUND_CAP") && {([_net, _requested, _blocked, _throughput] call FLO_fnc_logisticsNetworkFindSupplySourceObjective) != ""}) then { _delivery = _requested; };
    } else {
        _delivery = [_net, _requested, _throughput, _blocked, _deliveryInboundForPick] call FLO_fnc_logisticsNetworkPickDeliveryObjective;
    };
    _perf set ["dispatchDeliveryPickMs", (_perf get "dispatchDeliveryPickMs") + (diag_tickTime - _started) * 1000];
    if (_delivery == "" && {_routeBlockedCount > 0}) then {
        _rejections set ["NO_ROUTE", (_rejections getOrDefault ["NO_ROUTE", 0]) + 1];
    };
    if (_delivery != "") exitWith { _result = [_requested, _delivery]; };
};
_result
