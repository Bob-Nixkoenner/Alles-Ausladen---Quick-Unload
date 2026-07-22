// Modernes CBA-Settings-System (CfgSettings in der Config ist veraltet!).
// Erscheint unter Optionen -> Spiel -> Addon-Optionen -> "Alles Ausladen".

[
    "BOBU_driverLock", "CHECKBOX",
    ["Fahrersitz sperren", "Aktionen nicht verfuegbar, wenn der Spieler selbst am Steuer sitzt."],
    "Alles Ausladen",
    true, 1
] call CBA_settings_fnc_init;

[
    "BOBU_lootRadius", "SLIDER",
    ["Loot-Radius (m)", "Suchradius fuer 'Fracht aus der Naehe hierher umladen'."],
    "Alles Ausladen",
    [5, 50, 10, 0], 1
] call CBA_settings_fnc_init;

[
    "BOBU_showHint", "CHECKBOX",
    ["Itemzahl-Hint anzeigen", "Zeigt nach dem Looten, wie viele Gegenstaende bewegt wurden."],
    "Alles Ausladen",
    true, 0
] call CBA_settings_fnc_init;

[
    "BOBU_showUnload", "CHECKBOX",
    ["Aktion: Ausladen (Boden)", "Blendet 'Alles ausladen' im Scrollmenue ein oder aus."],
    "Alles Ausladen",
    true, 0
] call CBA_settings_fnc_init;

[
    "BOBU_showPull", "CHECKBOX",
    ["Aktion: Fracht ziehen", "Blendet 'Fracht aus der Naehe' im Scrollmenue ein oder aus."],
    "Alles Ausladen",
    true, 0
] call CBA_settings_fnc_init;

[
    "BOBU_showList", "CHECKBOX",
    ["Aktion: Was ist drin?", "Blendet die Frachtuebersicht im Scrollmenue ein oder aus."],
    "Alles Ausladen",
    true, 0
] call CBA_settings_fnc_init;
