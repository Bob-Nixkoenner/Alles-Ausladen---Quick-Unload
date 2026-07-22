// Laeuft auf dem Client des Spielers: sucht die naechste Frachtquelle (10 m)
// und zieht deren komplette Fracht in _dst. Auch Bodenhaufen (WeaponHolder)
// werden mit aufgesaugt.
params ["_dst"];

private _radius = if (isNil "BOBU_lootRadius") then { 10 } else { BOBU_lootRadius };
private _cands = (nearestObjects [_dst, ["LandVehicle", "Air", "Ship", "ReammoBox_F", "WeaponHolder"], _radius]) - [_dst];
_cands = _cands select { alive _x && { [_x] call BOBU_fnc_hasCargo } };

if (_cands isEqualTo []) exitWith {
    hint "Nichts mit Fracht im Umkreis von 10 m gefunden.";
};

private _src  = _cands # 0;   // nearestObjects ist nach Distanz sortiert
private _name = getText (configOf _src >> "displayName");
if (_name isEqualTo "") then { _name = typeOf _src };

["BOBU_grab", [_src, _dst, player], _src] call CBA_fnc_targetEvent;
hint format ["Uebernehme Fracht aus: %1", _name];
