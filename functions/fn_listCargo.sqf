// "Was ist drin?" -- zaehlt die Fracht und postet sie fuer ALLE in den Chat.
// Cargo-Daten sind netzwerksynchron -> kann direkt auf dem Client laufen.
params ["_target"];

private _counts = createHashMap;

{ _counts set [_x # 0, (_counts getOrDefault [_x # 0, 0]) + 1] } forEach (magazinesAmmoCargo _target);
{ _counts set [_x # 0, (_counts getOrDefault [_x # 0, 0]) + 1] } forEach (weaponsItemsCargo  _target);
{ _counts set [_x,     (_counts getOrDefault [_x, 0])     + 1] } forEach (itemCargo          _target);
(getBackpackCargo _target) params [["_bt", []], ["_bc", []]];
{ _counts set [_x, (_counts getOrDefault [_x, 0]) + (_bc # _forEachIndex)] } forEach _bt;

private _vehName = getText (configOf _target >> "displayName");
if (_vehName isEqualTo "") then { _vehName = typeOf _target };

if (count _counts == 0) exitWith {
    ["BOBU_chat", [format ["[%1 | %2] Leer.", name player, _vehName]]] call CBA_fnc_globalEvent;
};

// Nach Anzahl absteigend sortieren, Top 5 + Rest als "Sonstiges"
private _arr = [];
{ _arr pushBack [_y, _x] } forEach _counts;
_arr sort false;

private _topN = 5 min count _arr;
private _top  = _arr select [0, _topN];
private _rest = 0;
if (count _arr > _topN) then {
    { _rest = _rest + (_x # 0) } forEach (_arr select [_topN, count _arr - _topN]);
};

private _names = _top apply {
    _x params ["_n", "_c"];
    private _dn = getText (configFile >> "CfgMagazines" >> _c >> "displayName");
    if (_dn isEqualTo "") then { _dn = getText (configFile >> "CfgWeapons"  >> _c >> "displayName") };
    if (_dn isEqualTo "") then { _dn = getText (configFile >> "CfgVehicles" >> _c >> "displayName") };
    if (_dn isEqualTo "") then { _dn = _c };
    format ["%1x %2", _n, _dn]
};

private _txt = _names joinString ", ";
if (_rest > 0) then { _txt = _txt + format [" + %1 Sonstiges", _rest] };

["BOBU_chat", [format ["[%1 | %2] %3", name player, _vehName, _txt]]] call CBA_fnc_globalEvent;
