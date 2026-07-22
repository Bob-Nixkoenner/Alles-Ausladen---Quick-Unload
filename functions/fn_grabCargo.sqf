// Laeuft dort, wo _src lokal ist (via CBA_fnc_targetEvent):
// liest die komplette Fracht aus, leert die Quelle und schickt die Daten
// per Event dorthin, wo _dst lokal ist.
params ["_src", "_dst", ["_initiator", objNull]];

private _mags  = [];
private _weps  = [];
private _items = [];

// Inhalte von Containern IN der Fracht (Rucksaecke, Westen, Uniformen)
// NUR wenn kein lebender Spieler/KI den Container traegt -- keine Pluenderung!
{
    _x params ["", "_cobj"];
    private _owner = attachedTo _cobj;
    if (!isNull _owner && { alive _owner } && { _owner isKindOf "CAManBase" }) then {
        // getragen von lebender Einheit -> ignorieren
    } else {
        _mags  append (magazinesAmmoCargo _cobj);
        _weps  append (weaponsItemsCargo  _cobj);
        _items append (itemCargo          _cobj);
    };
} forEach (everyContainer _src);

_mags  append (magazinesAmmoCargo _src);   // [[Klasse, Munition], ...] -> Fuellstand bleibt!
_weps  append (weaponsItemsCargo  _src);   // Waffen inkl. Anbauteile
_items append (itemCargo          _src);
private _packs = getBackpackCargo _src;    // [[Typen], [Anzahl]]

// Itemzaehler fuer die Chat-Meldung
private _count = (count _mags) + (count _weps) + (count _items) + (count (_packs # 0));

clearWeaponCargoGlobal   _src;
clearMagazineCargoGlobal _src;
clearItemCargoGlobal     _src;
clearBackpackCargoGlobal _src;

// Easteregg: jede 10. Loot-Aktion (serverweit) faellt eine ClubCola raus
if (_count > 0) then {
    private _n = (missionNamespace getVariable ["BOBU_lootOps", 0]) + 1;
    missionNamespace setVariable ["BOBU_lootOps", _n];
    if (_n % 10 == 0) then {
        private _can = createVehicle [
            "Land_Can_V3_F",
            (getPosATL _src) vectorAdd [0, 0, 1.5], [], 0, "CAN_COLLIDE"
        ];
        _can setVelocity [(random 4) - 2, (random 4) - 2, 3];
        ["BOBU_chat", ["[Alles Ausladen] Pssht! Eine ClubCola faellt aus der Fracht."]] call CBA_fnc_globalEvent;
    };
};

["BOBU_put", [_dst, _mags, _weps, _items, _packs, _count, _initiator], _dst] call CBA_fnc_targetEvent;
