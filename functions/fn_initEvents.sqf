// Registriert CBA-Events. CBA_fnc_targetEvent fuehrt den Code auf der Maschine
// aus, auf der das Zielobjekt lokal ist -- unabhaengig von CfgRemoteExec.

["BOBU_unload", { _this call BOBU_fnc_unloadGround }] call CBA_fnc_addEventHandler;
["BOBU_grab",   { _this call BOBU_fnc_grabCargo   }] call CBA_fnc_addEventHandler;
["BOBU_put",    { _this call BOBU_fnc_putCargo    }] call CBA_fnc_addEventHandler;

// Kommt vom Server zurueck zum ausloesenden Spieler
["BOBU_hintDone", {
    params [["_count", 0]];
    if (!hasInterface) exitWith {};
    if !(missionNamespace getVariable ["BOBU_showHint", true]) exitWith {};
    if (_count > 0) then {
        systemChat format ["[Alles Ausladen] %1 Gegenstaende gelootet.", _count];
    } else {
        systemChat "[Alles Ausladen] Nichts zu looten.";
    };
}] call CBA_fnc_addEventHandler;

// Globaler Chat -- laeuft auf ALLEN Clients (fuer "Was ist drin?" und Easteregg)
["BOBU_chat", {
    params [["_txt", ""]];
    if (hasInterface) then { systemChat _txt };
}] call CBA_fnc_addEventHandler;
