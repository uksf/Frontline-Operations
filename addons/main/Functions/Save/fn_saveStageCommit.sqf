/* Save stage: writes the encoded campaign text to the mission profile.
 * Arguments: 0: Save context <HASHMAP>
 * Returns: <BOOL> - true when the stage is complete; the write outcome is in "saved"
 */
params ["_ctx"];
_ctx set ["saved", [_ctx get "payloadText"] call FLO_fnc_saveCommitCampaignData];
true
