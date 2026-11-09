/*
 * Function: FLO_fnc_gtnProcessArtilleryRadioQueue
 * Author: Frontline Operations Development Group
 * Description:
 *   Processes the local queued artillery radio missions for one side so the
 *   full mission chatter plays in order without overlapping broadcasts.
 *
 * Arguments:
 *   0: Side <SIDE>
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };

params [
    ["_side", sideUnknown]
];

if !(_side in [east, west]) exitWith { false };
if (isNull player) exitWith { false };
if ((side group player) != _side) exitWith { false };

if (isNil "FLO_GTN_ArtilleryRadioQueues") then {
    FLO_GTN_ArtilleryRadioQueues = createHashMapFromArray [
        ["EAST", []],
        ["WEST", []]
    ];
};
if (isNil "FLO_GTN_ArtilleryRadioActive") then {
    FLO_GTN_ArtilleryRadioActive = createHashMapFromArray [
        ["EAST", false],
        ["WEST", false]
    ];
};

private _sideKey = ["WEST", "EAST"] select (_side isEqualTo east);
if (FLO_GTN_ArtilleryRadioActive get _sideKey) exitWith { false };
if ((FLO_GTN_ArtilleryRadioQueues get _sideKey) isEqualTo []) exitWith { true };

FLO_GTN_ArtilleryRadioActive set [_sideKey, true];

private _playStep = {
    params ["_side", "_sideKey", "_sequence", "_index", "_lastOffset", "_playStep"];

    if (_index >= count _sequence) exitWith {
        private _queue = FLO_GTN_ArtilleryRadioQueues get _sideKey;
        if (_queue isEqualTo []) exitWith {
            FLO_GTN_ArtilleryRadioActive set [_sideKey, false];
        };
        private _nextSequence = (_queue deleteAt 0) select 1;
        [_playStep, [_side, _sideKey, _nextSequence, 0, 0, _playStep], 0.75] call CBA_fnc_waitAndExecute;
    };

    (_sequence select _index) params [
        ["_sender", "HQ", [""]],
        ["_text", "", [""]],
        ["_offset", 0, [0]]
    ];

    [{
        params ["_side", "_sideKey", "_sequence", "_index", "_offset", "_playStep", "_sender", "_text"];
        [_side, _sender, _text] call FLO_fnc_gtnCommanderRadioMessage;
        [_side, _sideKey, _sequence, _index + 1, _offset, _playStep] call _playStep;
    }, [_side, _sideKey, _sequence, _index, _offset, _playStep, _sender, _text], (_offset - _lastOffset) max 0] call CBA_fnc_waitAndExecute;
};

private _firstSequence = ((FLO_GTN_ArtilleryRadioQueues get _sideKey) deleteAt 0) select 1;
[_side, _sideKey, _firstSequence, 0, 0, _playStep] call _playStep;

true
