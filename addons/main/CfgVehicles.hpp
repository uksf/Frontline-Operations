class CfgFactionClasses {
    class FLO_Modules {
        displayName = "Frontline Operations";
        priority = 2;
        side = 7;
    };
};

class CfgVehicles {
    class Logic;
    class Module_F : Logic {
        class AttributesBase;
        class ModuleDescription;
    };

    class FLO_ModuleObjectiveExclusion : Module_F {
        scope = 2;
        scopeCurator = 0;
        is3DEN = 1;
        displayName = "Exclusion Area";
        icon = "A3\Modules_F\Data\portraitsector_ca.paa";
        portrait = "A3\Modules_F\Data\portraitsector_ca.paa";
        category = "FLO_Modules";
        function = "FLO_fnc_moduleObjectiveExclusion";
        functionPriority = 25;
        isGlobal = 0;
        isDisposable = 0;
        canSetArea = 1;
        canSetAreaHeight = 0;
        canSetAreaShape = 1;

        class AttributeValues {
            size3[] = {500, 500, -1};
            isRectangle = 0;
        };

        class AttributesBase : AttributesBase {
            class ModuleDescription : ModuleDescription {};
        };
        class ModuleDescription : ModuleDescription {};
    };
};
