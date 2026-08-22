/*
 * Function: FLO_fnc_adjustAggression
 * Adjusts the authoritative EAST difficulty handle.
 * Parameters:
 *   0: Amount to adjust (NUMBER, positive or negative)
 *   1: Type (STRING, 'increase' or 'decrease')
 * Example:
 *   [0.75, 'increase'] call FLO_fnc_adjustAggression;
 */
params [
    ["_amount", 0, [0]],
    ["_type", "increase", [""]]
];

private _AGGRSCORE = FLO_EastDifficultyHandle get "value";
private _newScore = _AGGRSCORE + _amount;
_newScore = _newScore max 0 min 34;
FLO_EastDifficultyHandle set ["value", _newScore];
publicVariable "FLO_EastDifficultyHandle";
