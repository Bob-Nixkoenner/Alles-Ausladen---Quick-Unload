// Darf der Spieler die Aktionen gerade benutzen?
// WICHTIG: Zu Fuss ist man in Arma sein EIGENER driver -> zuerst pruefen!
if (isNull player || {!alive player}) exitWith { false };
if (vehicle player == player) exitWith { true };   // zu Fuss -> immer ok
if !(missionNamespace getVariable ["BOBU_driverLock", true]) exitWith { true };
driver vehicle player != player                    // im Fahrzeug: nur wenn NICHT am Steuer
