params [
    ["_side", sideUnknown, [west]],
    ["_message", "", [""]],
    ["_type", "info", [""]]
];

if !(_side in [west, east]) then { throw format ["Invalid development notification side %1", _side]; };
if (_message == "") then { throw "Development notification message cannot be empty"; };

["DEVELOPMENT", 3, format ["Suppressed %1 broadcast for %2: %3", _type, _side, _message]] call FLO_fnc_log;

true
