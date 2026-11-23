/* Setup progress shown once per second until the mission is ready, fails, or 10 minutes pass. initClientFinalize owns player and respawn setup. */
hint "Initializing mission systems...";

[{
    params ["_startTime", "_handle"];

    if (!isNil "FLO_InitPhase") then {
        private _phaseName = switch (FLO_InitPhase) do {
            case 1: { "Loading factions..." };
            case 2: { "Configuring factions..." };
            case 3: { "Indexing objectives..." };
            case 4: { "Setting up campaign forces..." };
            case 5: { "Starting mission systems..." };
            case 99: { "Complete!" };
            case -1: { "ERROR - Check server log" };
            default { "Initializing..." };
        };
        hintSilent format ["Mission Setup: %1\nPhase %2", _phaseName, FLO_InitPhase];
    };

    private _ready = !isNil "FLO_MissionReady" && {FLO_MissionReady};
    private _failed = !isNil "FLO_InitPhase" && {FLO_InitPhase == -1};
    if (!_ready && {!_failed} && {diag_tickTime - _startTime <= 600}) exitWith {};
    [_handle] call CBA_fnc_removePerFrameHandler;

    if (_ready) then {
        ["UI", 3, "Mission initialization complete - ready to play"] call FLO_fnc_log;
        titleText ["Deploying...", "BLACK FADED", 0.1, true, true];
        hintSilent "Mission ready. Deploying...";
    } else {
        private _errorMsg = if (!isNil "FLO_InitError") then { FLO_InitError } else { "Unknown error" };
        ["UI", 1, format["Mission initialization FAILED: %1", _errorMsg]] call FLO_fnc_log;
        hint format ["Mission initialization failed:\n%1\n\nCheck server RPT for details.", _errorMsg];
    };

    ["UI", 3, "Faction dialog setup complete"] call FLO_fnc_log;
}, 1, diag_tickTime] call CBA_fnc_addPerFrameHandler;
