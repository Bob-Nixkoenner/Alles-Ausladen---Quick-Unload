// Wird per XEH-Init und postInit-Scan fuer Fahrzeuge/Kisten aufgerufen.
params ["_obj"];

if (!hasInterface) exitWith {};
if (_obj getVariable ["BOBU_done", false]) exitWith {};
_obj setVariable ["BOBU_done", true];

_obj addAction [
    "<t color='#FFB000'>&#187; Alles ausladen (auf den Boden)</t>",
    {
        params ["_target"];
        // player mitgeben, damit der Hint spaeter an DIESEN Client zurueckkommt
        ["BOBU_unload", [_target, player], _target] call CBA_fnc_targetEvent;
    },
    nil, 1.2, true, true, "",
    "(missionNamespace getVariable ['BOBU_showUnload', true]) && {call BOBU_fnc_canUse} && {[_target] call BOBU_fnc_hasCargo}",
    7
];

_obj addAction [
    "<t color='#FFB000'>&#171; Fracht aus der Naehe hierher umladen</t>",
    {
        params ["_target"];
        [_target] call BOBU_fnc_pullNearest;
    },
    nil, 1.1, true, true, "",
    "(missionNamespace getVariable ['BOBU_showPull', true]) && {call BOBU_fnc_canUse} && {alive _target}",
    7
];

_obj addAction [
    "<t color='#B0D0FF'>? Was ist drin?</t>",
    {
        params ["_target"];
        [_target] call BOBU_fnc_listCargo;
    },
    nil, 1.0, true, true, "",
    "(missionNamespace getVariable ['BOBU_showList', true]) && {alive _target}",
    7
];
