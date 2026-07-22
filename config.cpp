class CfgPatches {
    class bob_unload {
        name = "Alles Ausladen (QoL)";
        author = "Bob";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.00;
        requiredAddons[] = {"cba_main"};
    };
};

// CBA XEH: haengt die Aktionen automatisch an alle Fahrzeuge und Kisten
class Extended_Init_EventHandlers {
    class LandVehicle {
        class bob_unload { init = "_this call BOBU_fnc_addActions"; };
    };
    class Air {
        class bob_unload { init = "_this call BOBU_fnc_addActions"; };
    };
    class Ship {
        class bob_unload { init = "_this call BOBU_fnc_addActions"; };
    };
    class ReammoBox_F {
        class bob_unload { init = "_this call BOBU_fnc_addActions"; };
    };
};

class CfgFunctions {
    class BOBU {
        class main {
            file = "\bob_unload\functions";
            class initEvents { preInit = 1; };
            class initSettings { preInit = 1; };
            class canUse {};
            class postInit { postInit = 1; };
            class addActions {};
            class hasCargo {};
            class grabCargo {};
            class putCargo {};
            class unloadGround {};
            class pullNearest {};
            class listCargo {};
        };
    };
};
