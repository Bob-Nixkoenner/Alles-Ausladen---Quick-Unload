// XEH-Init feuert nur fuer NEU erstellte Objekte. Bereits existierende
// (vorgeplatzierte Fahrzeuge, Antistasi-Kisten) werden hier erfasst --
// initial nach 5 s, danach alle 30 s (Antistasi spawnt dynamisch nach).

if (!hasInterface) exitWith {};

private _scan = {
    private _all = [];
    { _all append (allMissionObjects _x) } forEach ["LandVehicle", "Air", "Ship", "ReammoBox_F"];
    { [_x] call BOBU_fnc_addActions } forEach _all;
};

[_scan, [], 5] call CBA_fnc_waitAndExecute;
[_scan, 30, []] call CBA_fnc_addPerFrameHandler;
