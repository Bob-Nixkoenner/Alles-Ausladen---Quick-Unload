// Laeuft dort, wo _src lokal ist.
params ["_src", ["_initiator", objNull]];

private _bb  = boundingBoxReal _src;
private _off = ((_bb # 1) # 1) + 1.5;
private _pos = _src modelToWorld [0, _off, 0];

private _holder = createVehicle ["GroundWeaponHolder", _pos, [], 0.5, "CAN_COLLIDE"];
[_src, _holder, _initiator] call BOBU_fnc_grabCargo;
