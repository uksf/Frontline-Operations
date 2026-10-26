/*
 * Function: FLO_fnc_virtualizationGetStagingPlan
 * Description:
 *   Lists the units a group can create before it activates. A multi-unit
 *   infantry composition stages its soldiers. A vehicle group stages one
 *   crew unit per driver and non-passenger turret seat of each vehicle whose
 *   config names its crew.
 *
 * Arguments:
 *   0: Group Data <HASHMAP>
 *
 * Return Value:
 *   ["INFANTRY" or "CREW", unit classes], or [] when the group spawns in one call <ARRAY>
 */

params ["_groupData"];

private _comp = _groupData get "comp";
if (_comp isEqualTo [] || {(_groupData get "attachedTo") != ""}) exitWith { [] };

private _archetype = [_groupData get "groupType"] call FLO_fnc_virtualizationGetArchetype;
if ((_comp findIf { !(_x isKindOf "Man") }) < 0) exitWith {
    if (
        count _comp < 2
        || {(_groupData get "supportComp") isNotEqualTo []}
        || {_groupData get "isTransport"}
        || {!(_archetype get "compositionPreemptsSpawn")}
    ) exitWith { [] };
    ["INFANTRY", +_comp]
};

if !((_archetype get "spawnKind") in ["GROUND", "AIR", "ARTILLERY"]) exitWith { [] };
if ((_comp findIf { _x isKindOf "Man" }) >= 0) exitWith { [] };

private _countTurrets = {
    params ["_turretsCfg"];
    private _count = 0;
    {
        if (getNumber (_x >> "isPersonTurret") == 0) then { _count = _count + 1 };
        _count = _count + ([_x >> "Turrets"] call _countTurrets);
    } forEach ("true" configClasses _turretsCfg);
    _count
};

private _crew = [];
{
    private _cfg = configFile >> "CfgVehicles" >> _x;
    private _crewType = getText (_cfg >> "crew");
    if (_crewType != "") then {
        private _seats = (getNumber (_cfg >> "hasDriver") min 1) + ([_cfg >> "Turrets"] call _countTurrets);
        for "_i" from 1 to (_seats max 1) do { _crew pushBack _crewType };
    };
} forEach (_comp + (_groupData get "supportComp"));

if (_crew isEqualTo []) exitWith { [] };
["CREW", _crew]
