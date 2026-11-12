/* Save stage: validates the campaign root and writes it to the mission profile.
 * Arguments: 0: Save context <HASHMAP>
 * Returns: <BOOL> - true when the stage is complete; the write outcome is in "saved"
 */
params ["_ctx"];
private _data = _ctx get "data";
[_data] call FLO_fnc_saveValidateCampaignRoot;
_ctx set ["saved", [_data] call FLO_fnc_saveCommitCampaignData];
true
