/*
 * Function: FLO_fnc_registerSettings
 * Author: Frontline Operations Development Group
 * Description:
 *   Registers addon-level CBA settings that replace removed mission lobby
 *   parameters.
 */

if (missionNamespace getVariable ["FLO_SettingsRegistered", false]) exitWith {
    diag_log "[FLO_SETTINGS] CBA settings already registered";
};

private _settingsFn = if (!isNil "cba_settings_fnc_init") then {
    cba_settings_fnc_init
} else {
    if (!isNil "CBA_fnc_addSetting") then {
        CBA_fnc_addSetting
    } else {
        nil
    }
};

if (isNil "_settingsFn") exitWith {
    diag_log "[FLO_SETTINGS] CBA settings API is unavailable; required CBA settings were not registered";
};

private _enabled = [
    "FLO_Enabled",
    "CHECKBOX",
    ["Enable Frontline Operations", "Starts FLO campaign systems only when this setting is true in the mission-root cba_settings.sqf. Server and user presets cannot opt in."],
    ["FLO", "Campaign"],
    false,
    1,
    {},
    true
];

_enabled call _settingsFn;

private _missionEnabled = false;
private _hasMissionSettingsFile = getMissionConfigValue ["cba_settings_hasSettingsFile", false] in [true, 1];
if (_hasMissionSettingsFile && {!isNil "cba_settings_missionConfig"}) then {
    private _missionSetting = cba_settings_missionConfig getVariable ["FLO_Enabled", []];
    private _missionValue = _missionSetting param [0, false];
    _missionEnabled = _missionValue isEqualTo true || {_missionValue isEqualTo 1};
};
missionNamespace setVariable ["FLO_MissionEnabled", _missionEnabled];

if (!_missionEnabled) exitWith {
    missionNamespace setVariable ["FLO_SettingsRegistered", true];
    diag_log "[FLO_SETTINGS] FLO is disabled because this mission did not opt in";
};

private _campaignLaunchMode = [
    "FLO_CampaignLaunchMode",
    "LIST",
    ["Campaign launch mode", "Continue loads valid saved progress when available and opens setup when no save exists. Reset deletes saved progress and opens setup."],
    ["FLO", "Campaign"],
    [[1, 2], ["Continue saved progress", "Reset saved progress"], 0],
    1
];

_campaignLaunchMode call _settingsFn;

FLO_AutosavePFH = -1;
FLO_MissionSaveInProgress = false;
FLO_SaveWorker = scriptNull;
FLO_SaveSequence = 0;
FLO_SaveRequester = -1;
FLO_SaveStatus = createHashMapFromArray [
    ["phase", "NOT_SAVED"], ["lastAttemptAt", -1], ["lastSuccessAt", -1],
    ["duration", 0], ["failures", 0]
];

private _autosaveInterval = [
    "FLO_AutosaveIntervalMinutes",
    "LIST",
    ["Automatic save interval", "How often the server saves campaign progress after initialization. Disabled leaves saving manual."],
    ["FLO", "Campaign"],
    [[0, 5, 10, 15, 30, 60], ["Disabled", "Every 5 minutes", "Every 10 minutes", "Every 15 minutes", "Every 30 minutes", "Every 60 minutes"], 1],
    1,
    {
        if (isServer && {!isNil "FLO_MissionReady"} && {FLO_MissionReady}) then {
            call FLO_fnc_saveConfigureAutosave;
        };
    }
];

_autosaveInterval call _settingsFn;

private _debugLevel = [
    "FLO_Debug_Level",
    "LIST",
    ["RPT logging level", "Information is the production default. Debug and Trace add investigation detail and can materially increase RPT volume."],
    ["FLO", "Diagnostics"],
    [[1, 2, 3, 4, 5], ["Errors", "Warnings", "Information", "Debug", "Trace"], 2],
    1
];

_debugLevel call _settingsFn;

private _airActivationMultiplier = [
    "FLO_AirActivationDistanceMultiplier",
    "SLIDER",
    ["Aircraft activation distance multiplier", "Aircraft physically spawn at the normal virtualization distance multiplied by this value."],
    ["FLO", "Virtualization"],
    [1, 4, 2, 1],
    1
];

_airActivationMultiplier call _settingsFn;

private _activationInterval = [
    "FLO_ActivationInterval",
    "SLIDER",
    ["Group activation interval", "Seconds between the start of one virtual group's physical spawn and the next. Spreads spawn work when many groups enter activation range at once. 0 allows one group per frame."],
    ["FLO", "Virtualization"],
    [0, 5, 0.25, 2],
    1
];

_activationInterval call _settingsFn;

missionNamespace setVariable ["FLO_SettingsRegistered", true];
diag_log "[FLO_SETTINGS] Registered CBA settings";
