/*
 * Function: FLO_fnc_addonPostInit
 * Author: Frontline Operations Development Group
 * Description:
 *   Addon-owned mission bootstrap. This replaces the removed loose mission
 *   initServer/initPlayerLocal scripts so FLO can run from any thin mission
 *   shell that loads the addon.
 */

if !(missionNamespace getVariable ["FLO_MissionEnabled", false]) exitWith {
    diag_log "[FLO_INIT] Disabled for this mission";
};

[] call FLO_fnc_playerSideAdapterInit;

if (isServer) then {
    if !(missionNamespace getVariable ["MissionLoadedLitterally", false]) then {
        if !(call FLO_fnc_MissionLoad) then {
            throw "FLO_fnc_MissionLoad failed during enabled addon startup";
        };
    };

    uksf_mission_artillerySupport = false;
    publicVariable "uksf_mission_artillerySupport";
    ["INIT", 3, "Disabled autonomous UKSF artillery requests; FLO owns authorization"] call FLO_fnc_log;

    ["uksf_mission_fireMissionCompleted", {
        _this call FLO_fnc_gtnArtilleryHandleUKSFCompletion;
    }] call CBA_fnc_addEventHandler;

    [] spawn {
        if (missionNamespace getVariable ["FLO_AddonServerBootstrapStarted", false]) exitWith {
            diag_log "[FLO_INIT] Addon server bootstrap already started";
        };
        missionNamespace setVariable ["FLO_AddonServerBootstrapStarted", true, true];

        uiNamespace setVariable ["FLO_GTN_ResourceManagerLive", nil];
        uiNamespace setVariable ["FLO_GTN_CommandersBySideLive", createHashMap];
        FLO_GTN_ResourceManager = call FLO_fnc_gtnResourceManagerProxy;

        private _globalVars = createHashMapFromArray [
            ["FLO_StartingLocationComplete", 0],
            ["FLO_Objectives_Debug", false],
            ["StartingLocationDone", false],
            ["F_Init", false],
            ["InitializationOG", false],
            ["FLO_MissionReady", false],
            ["FLO_SideResources", createHashMap],
            ["FLO_SideResourceState", createHashMap],
            ["FLO_ActivePlayerSide", sideUnknown],
            ["FLO_MissionSides", [east, west]],
            ["FLO_FactionCatalog", createHashMap],
            ["FLO_GTN_CommandersBySide", createHashMap],
            ["FLO_GTN_CommandersBySideState", createHashMap],
            ["FLO_CampaignBases", []],
            ["FLO_CampaignSnapshotRequestAt", createHashMap],
            ["FLO_GTN_EnablePlayerTaskBridge", true],
            ["FLO_GTN_CommanderDebugEnabled", false],
            ["FLO_GTN_CommanderDebugRunning", false],
            ["FLO_GTN_CommanderDebugMarkers", createHashMap],
            ["FLO_GTN_CombatDebugEnabled", true]
        ];

        {
            missionNamespace setVariable [_x, _y, true];
        } forEach _globalVars;

        FLO_GTN_IntelPickupRevealState = createHashMapFromArray [
            ["WEST", createHashMap],
            ["EAST", createHashMap]
        ];
        FLO_GTN_StrategicIntelBySide = createHashMapFromArray [
            ["WEST", createHashMap],
            ["EAST", createHashMap]
        ];
        FLO_Logistics_Networks = createHashMap;

        FLO_GTN_CombatEvents = [];
        FLO_GTN_CombatLastByObjective = createHashMap;
        Centerposition = [worldSize / 2, worldSize / 2, 0];

        [] spawn FLO_fnc_heartbeat;

        waitUntil {
            sleep 0.1;
            !isNil "MissionLoadedLitterally" && {MissionLoadedLitterally}
        };

        sleep 1;
        diag_log "[FLO_INIT] Addon bootstrap starting Phase Manager";

        private _success = [] call FLO_fnc_initPhaseManager;
        if (_success) then {
            diag_log "[FLO_INIT] Phase Manager completed successfully";
        } else {
            diag_log format ["[FLO_INIT] Phase Manager FAILED: %1", FLO_InitError];
        };
    };
};

if (hasInterface) then {
    [] spawn {
        if (missionNamespace getVariable ["FLO_AddonClientBootstrapStarted", false]) exitWith {
            diag_log "[FLO_INIT_CLIENT] Addon client bootstrap already started";
        };
        missionNamespace setVariable ["FLO_AddonClientBootstrapStarted", true, false];

        waitUntil {
            sleep 0.1;
            !isNull player && {player == player}
        };

        StartingLocationDone = false;
        FLO_ClientFinalizeDone = false;
        FLO_ClientUiReady = false;

        [] call FLO_fnc_initMissionConfigEvents;
        [] spawn {
            waitUntil {
                sleep 1;
                !isNull player
                && {player == player}
                && {
                    (missionNamespace getVariable ["FLO_MissionReady", false])
                    || {(missionNamespace getVariable ["FLO_InitPhase", 0]) == -1}
                }
            };

            if ((missionNamespace getVariable ["FLO_InitPhase", 0]) == -1) exitWith {
                private _error = missionNamespace getVariable ["FLO_InitError", "Unknown initialization error"];
                ["INIT_CLIENT", 1, format ["Mission initialization failed: %1", _error]] call FLO_fnc_log;
                hint format ["Mission initialization failed:\n%1\n\nCheck the server RPT for details.", _error];
            };

            if (!FLO_ClientFinalizeDone) then {
                ["INIT_CLIENT", 3, "Mission-ready watchdog firing local client finalize"] call FLO_fnc_log;
                ["FLO_INIT_COMPLETE", []] call FLO_fnc_initClientFinalize;
            };
        };

        private _loadTimeout = diag_tickTime + 300;
        waitUntil {
            sleep 0.1;
            (!isNil "MissionLoadedLitterally" && {MissionLoadedLitterally}) || {diag_tickTime > _loadTimeout}
        };

        if (diag_tickTime > _loadTimeout) then {
            ["INIT_CLIENT", 1, "Mission loading timeout reached"] call FLO_fnc_log;
        };

        StartingLocationDone = true;
        ["INIT_CLIENT", 3, "Mission setup is supplied by flops\\settings.sqf"] call FLO_fnc_log;
    };
};
