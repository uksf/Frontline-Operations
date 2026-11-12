/* One identifiable save transaction for automatic and authenticated manual requests. */
params [["_requesterOwner", -1, [0]]];
if (!isServer || {remoteExecutedOwner > 2}) exitWith { false };
private _accepted = false;
isNil {
    if (FLO_MissionReady && {!FLO_MissionSaveInProgress}
        && {!((FLO_SaveStatus get "phase") in ["QUEUED", "SAVING"])}) then {
        FLO_SaveRequester = _requesterOwner;
        FLO_SaveSequence = FLO_SaveSequence + 1;
        FLO_SaveStatus set ["phase", "QUEUED"];
        FLO_SaveStatus set ["lastAttemptAt", diag_tickTime];
        _accepted = true;
        if !([FLO_SaveSequence] call FLO_fnc_MissionSave) then {
            [false, "Save transaction did not start"] call FLO_fnc_saveFinish;
        };
    };
};
_accepted
