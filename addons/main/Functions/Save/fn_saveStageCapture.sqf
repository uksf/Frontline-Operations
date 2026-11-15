/* Save stage: the coherent campaign snapshot, including commander minefields. The capture itself is one atomic unit.
 * Arguments: 0: Save context <HASHMAP>
 * Returns: <BOOL> - true when the stage is complete
 */
params ["_ctx"];
private _data = _ctx get "data";
private _campaignState = [_ctx get "installationMarkers", _ctx get "saveRadius"] call FLO_fnc_saveCaptureCampaignState;
_ctx set ["campaignState", _campaignState];
_ctx set ["groupIds", keys (_campaignState get "virtualGroups")];
_ctx set ["validateIndex", 0];
_ctx set ["serializeIndex", 0];
_ctx set ["serializedGroups", createHashMap];
[_ctx] call FLO_fnc_saveStageMinefields;

{
    _data set [_x, _campaignState get _x];
} forEach ["vehicles", "crates", "fobs", "ops", "baseDeploymentState", "sideResources", "logisticsNetworkBySide", "objectives", "aiCommanders"];

["SAVE", 3, "Base deployment state saved"] call FLO_fnc_log;
["SAVE", 3, format ["Side resources saved for %1 sides", count keys (_data get "sideResources")]] call FLO_fnc_log;
["SAVE", 3, format ["Logistics: saved %1 side contexts", count keys (_data get "logisticsNetworkBySide")]] call FLO_fnc_log;
["SAVE", 3, "Objectives and dual GTN state saved"] call FLO_fnc_log;
true
