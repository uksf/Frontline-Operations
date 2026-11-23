/* Map selection of the starting FOB; the click sends the setup request to the server and starts the progress display. */
params ["_config"];

titleText ["", "BLACK IN", 1, true, true];

FLO_StartingLocationComplete = 0;
publicVariable "FLO_StartingLocationComplete";
private _startLocationPrompt = "<t size='1.35' color='#ff3b3b' font='PuristaBold'>SELECT STARTING FOB LOCATION</t><br/><t size='0.9' color='#ffffff'>Left-click the map to place your starting FOB and begin the campaign.</t>";
hint "Select your starting FOB location on the map.";
[_startLocationPrompt, 0, 0.18, 9999, 0, 0, 9010] spawn BIS_fnc_dynamicText;
openMap [true, true];

FLO_mapClickDFD = addMissionEventHandler ["MapSingleClick", {
    params ["_control", "_pos", "_alt", "_shift"];
    _thisArgs params ["_config"];

    removeMissionEventHandler ["MapSingleClick", FLO_mapClickDFD];

    player setPos _pos;
    ["", 0, 0.18, 0.1, 0, 0, 9010] spawn BIS_fnc_dynamicText;
    hintSilent "LOADING...";
    FLO_StartingLocationComplete = 1;
    publicVariable "FLO_StartingLocationComplete";
    missionNamespace setVariable ["FLO_StartPosition", _pos, true];
    titleText ["Initializing Frontline Operations...", "BLACK FADED", 0.1, true, true];

    [{
        params ["_config", "_pos"];
        openMap [true, false];
        openMap [false, false];
        _config set ["startPosition", _pos];
        FLO_MissionConfig = _config;
        publicVariable "FLO_MissionConfig";
        ["UI", 3, "Mission config sent to server - Phase Manager will handle initialization"] call FLO_fnc_log;
        call FLO_fnc_factionDialogWaitForMission;
    }, [_config, _pos]] call CBA_fnc_execNextFrame;
}, [_config]];
