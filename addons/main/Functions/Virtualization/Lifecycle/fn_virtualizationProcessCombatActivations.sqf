/*
 * Function: FLO_fnc_virtualizationProcessCombatActivations
 * Description:
 *   Activates groups that the virtual combat resolver handed to the engine,
 *   at the FLO_ActivationInterval cadence, staging infantry units within the
 *   frame budget.
 *   A group is prepared for combat once it is physical, then leaves the queue.
 *
 * Return Value:
 *   None
 */

private _queue = FLO_VirtUpdate get "combatActivations";
if (count _queue == 0) exitWith {};

private _groups = call FLO_fnc_virtualizationGetGroupMap;
{
    private _groupId = _x;
    if !(_groupId in _groups) then {
        _queue deleteAt _groupId;
        continue;
    };
    private _groupData = _groups get _groupId;
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
} forEach (keys _queue);
