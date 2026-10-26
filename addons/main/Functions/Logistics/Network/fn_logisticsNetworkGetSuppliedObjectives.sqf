/*
 * Function: FLO_fnc_logisticsNetworkGetSuppliedObjectives
 * Description:
 *   Returns every routed objective for which
 *   FLO_fnc_logisticsNetworkFindSupplySourceObjective would find a source,
 *   using one search back from the qualifying sources instead of one search
 *   per objective.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Required throughput <NUMBER>
 *
 * Return Value:
 *   HASHMAP - Supplied objective IDs mapped to true
 */

params ["_network", ["_requiredThroughput", 0, [0]]];
[_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _routeInfo = _network get "_supplyRouteInfo";
private _sources = _network get "_activeSupplyNodes";
private _side = _network get "_managedSide";
private _enemyKey = ["opforCount", "bluforCount"] select (_side isEqualTo east);

private _isTraversable = {
    params ["_id"];
    if !(_id in _routeInfo) exitWith { false };
    private _objective = FLO_Objectives get _id;
    (_objective get "owner") == _side && {(_objective get _enemyKey) == 0}
};

private _incoming = createHashMap;
{
    private _from = _x;
    if !(_from in _routeInfo) then { continue };
    {
        if (([_x] call _isTraversable)) then {
            (_incoming getOrDefault [_x, [], true]) pushBack _from;
        };
    } forEach ((FLO_Objectives get _from) get "linkedObjectives");
} forEach (keys _routeInfo);

private _supplied = createHashMap;
private _queue = [];
{
    if !(_x in _routeInfo) then { continue };
    if (((FLO_Objectives get _x) get _enemyKey) != 0) then { continue };
    if ((_y get "throughput") < _requiredThroughput) then { continue };
    _supplied set [_x, true];
    if ([_x] call _isTraversable) then { _queue pushBack _x };
} forEach _sources;

while {_queue isNotEqualTo []} do {
    private _id = _queue deleteAt 0;
    {
        if (_x in _supplied) then { continue };
        _supplied set [_x, true];
        if ([_x] call _isTraversable) then { _queue pushBack _x };
    } forEach (_incoming getOrDefault [_id, []]);
};

_supplied
