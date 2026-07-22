// Gibt true zurueck, wenn das Objekt irgendeine Fracht enthaelt.
params ["_o"];

if (isNull _o) exitWith { false };

!((magazinesAmmoCargo _o) isEqualTo []) ||
{ !((itemCargo _o) isEqualTo []) } ||
{ !((weaponsItemsCargo _o) isEqualTo []) } ||
{ !(((getBackpackCargo _o) # 0) isEqualTo []) }
