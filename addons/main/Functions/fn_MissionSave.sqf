/*
 * Function: FLO_fnc_MissionSave
 * Author: Frontline Operations Development Group
 * Description:
 *   Starts one campaign save transaction. FLO_fnc_saveRunStages runs the save as
 *   bounded stages in one PFH and reports the outcome through FLO_fnc_saveFinish.
 *   Saves time, markers, vehicles, objects, crates, minefields, structures, base
 *   deployment, side resources, logistics, virtual groups, objectives, AI commander
 *   state, IDS Logistics entities, and mission configuration.
 *
 * Arguments:
 *   0: Queued save sequence <NUMBER> - Default -1 for a direct local caller
 * Returns: <BOOL> - True if the save transaction started
 *
 * Example:
 *   [] call FLO_fnc_MissionSave;
 */

params [["_queuedSequence", -1, [0]]];
if (!isServer) exitWith { false };
if (remoteExecutedOwner > 2) exitWith {
    ["SAVE", 2, "Rejected direct remote save; clients must use the authenticated save request"] call FLO_fnc_log;
    false
};
if (!FLO_MissionReady) exitWith {
    ["SAVE", 2, "Rejected campaign save before mission readiness"] call FLO_fnc_log;
    false
};
private _acquiredSave = false;
isNil {
    private _queued = (FLO_SaveStatus get "phase") == "QUEUED";
    private _ownsQueue = _queued && {_queuedSequence == FLO_SaveSequence};
    if (!FLO_MissionSaveInProgress && {(!_queued && {_queuedSequence == -1}) || {_ownsQueue}}) then {
        if (!_ownsQueue) then { FLO_SaveSequence = FLO_SaveSequence + 1 };
        FLO_MissionSaveInProgress = true;
        FLO_SaveStatus set ["phase", "SAVING"];
        FLO_SaveStatus set ["lastAttemptAt", diag_tickTime];
        _acquiredSave = true;
    };
};
if (!_acquiredSave) exitWith {
    ["SAVE", 2, "Rejected concurrent mission save request"] call FLO_fnc_log;
    false
};

["SAVE", 3, "Starting mission save..."] call FLO_fnc_log;
FLO_SaveWorker = [createHashMapFromArray [
    ["data", createHashMap],
    ["index", 0],
    ["inStage", false],
    ["frameBudget", 0.003],
    ["frames", 0],
    ["maxFrameMs", 0],
    ["perf", createHashMap],
    ["stages", [
        ["prepare", FLO_fnc_saveStagePrepare],
        ["capture", FLO_fnc_saveStageCapture],
        ["validateGroups", FLO_fnc_saveStageValidateGroups],
        ["objects", FLO_fnc_saveStageObjects],
        ["minefields", FLO_fnc_saveStageMinefields],
        ["serializeGroups", FLO_fnc_saveStageSerializeGroups],
        ["ids", FLO_fnc_saveStageIds],
        ["encode", FLO_fnc_saveStageEncode],
        ["commit", FLO_fnc_saveStageCommit]
    ]]
]] call FLO_fnc_saveRunStages;
true
