/*
 * Function: FLO_fnc_virtualizationProcessCombatActivations
 * Description:
 *   Activates groups that the virtual combat resolver handed to the engine,
 *   at the FLO_ActivationInterval cadence, staging units within the frame
 *   budget. Each entry holds the time the resolver last confirmed it. An
 *   entry the resolver has not confirmed within one tick and a margin, or
 *   whose group left player range or boarded a carrier, leaves the queue and
 *   discards any units staged for it.
 *   A group is prepared for combat once it is physical, then leaves the queue.
 *
 * Return Value:
 *   None
 */

private _queue = FLO_VirtUpdate get "combatActivations";
if (count _queue == 0) exitWith {};
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _confirmedAfter = diag_tickTime - 30;
private _liveAreaRadius = ["activationDistance"] call FLO_fnc_virtualizationGetConfigValue;
{
    private _groupId = _x;
    private _groupData = _groups getOrDefault [_groupId, createHashMap];
    if (
        _y < _confirmedAfter
        || {_groupData isEqualTo createHashMap}
        || {!(_groupData get "isActive") && {
            (_groupData get "attachedTo") != ""
            || {!([_groupData get "position", _liveAreaRadius] call FLO_fnc_gtnCombatIsLiveArea)}
        }}
    ) then {
        _queue deleteAt _groupId;
        [_groupId] call FLO_fnc_virtualizationDiscardStagedGroup;
        continue;
    };
    if (_groupData get "isActive") then {
        _queue deleteAt _groupId;
        [_groupData] call FLO_fnc_gtnCombatPrepareRealGroupForCombat;
        continue;
    };
    if !([_groupId] call FLO_fnc_virtualizationClaimActivationSlot) exitWith {};
    if ([_groupId, _groupData] call FLO_fnc_virtualizationStageActivation) exitWith {};
    _queue deleteAt _groupId;
    if ([_groupId] call FLO_fnc_virtualizationTryActivateGroup) then {
        [_groupData] call FLO_fnc_gtnCombatPrepareRealGroupForCombat;
    };
} forEach +_queue;
