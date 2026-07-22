// Laeuft dort, wo _dst lokal ist (bei Kisten: meist der SERVER -> kein Interface!).
// Der Hint wird deshalb per Event an den ausloesenden Spieler zurueckgeschickt.
params ["_dst", ["_mags", []], ["_weps", []], ["_items", []], ["_packs", [[], []]], ["_count", 0], ["_initiator", objNull]];

{ _dst addMagazineAmmoCargo [_x # 0, 1, _x # 1] } forEach _mags;
{ _dst addWeaponWithAttachmentsCargoGlobal [_x, 1] } forEach _weps;
{ _dst addItemCargoGlobal [_x, 1] } forEach _items;

_packs params [["_ptypes", []], ["_pcounts", []]];
{ _dst addBackpackCargoGlobal [_x, _pcounts # _forEachIndex] } forEach _ptypes;

if (!isNull _initiator) then {
    ["BOBU_hintDone", [_count], _initiator] call CBA_fnc_targetEvent;
};
