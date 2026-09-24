// FLO fresh-campaign settings. Every field is required; Phase 1 rejects a missing or out-of-range value.
// "name" fields are display labels only. "value" fields drive behaviour.
createHashMapFromArray [
    // Factions. source: "auto" (factionClass from CfgFactionClasses) | "custom" (Factions\Custom file)
    // | "auto_multi" (add factionClasses list). side is fixed: BLUFOR 1, OPFOR 0, civilian 3.
    ["bluforHandle", createHashMapFromArray [
        ["name", "British Armed Forces"],
        ["source", "auto"],
        ["side", 1],
        ["factionClass", "CUP_B_GB"]
    ]],
    ["opforHandle", createHashMapFromArray [
        ["name", "CSAT"],
        ["source", "auto"],
        ["side", 0],
        ["factionClass", "OPF_F"]
    ]],
    ["civilianHandle", createHashMapFromArray [
        ["name", "Civilians"],
        ["source", "auto"],
        ["side", 3],
        ["factionClass", "CIV_F"]
    ]],
    ["playerSideKey", "WEST"],                                  // "WEST" | "EAST"
    ["reputationHandle", createHashMapFromArray [               // starting civilian standing: 2 hostile | 9 neutral | 16 friendly
        ["name", "Neutral _ Civilians Tolerate Players"],
        ["value", 9]
    ]],

    // AI commanders, one per side.
    // Difficulty (aggression): 0.5 cautious | 1 balanced | 1.5 aggressive
    ["westDifficultyHandle", createHashMapFromArray [["name", "MEDIUM _ Balanced Commander"], ["value", 1]]],
    ["eastDifficultyHandle", createHashMapFromArray [["name", "MEDIUM _ Balanced Commander"], ["value", 1]]],
    // Attack coverage (assault force per objective): 0.5 minimal | 0.75 balanced | 1 layered | 1.25 maximum
    ["westGTNAttackCoverageHandle", createHashMapFromArray [["name", "Balanced Coverage"], ["value", 0.75]]],
    ["eastGTNAttackCoverageHandle", createHashMapFromArray [["name", "Balanced Coverage"], ["value", 0.75]]],
    // Defense coverage (security demand on owned objectives): same values as attack coverage
    ["westGTNDefenseCoverageHandle", createHashMapFromArray [["name", "Balanced Coverage"], ["value", 0.75]]],
    ["eastGTNDefenseCoverageHandle", createHashMapFromArray [["name", "Balanced Coverage"], ["value", 0.75]]],
    // Tempo (seconds between commander updates): 10 | 14 | 20 | 28
    ["westGTNTempoHandle", createHashMapFromArray [["name", "20s"], ["value", 20]]],
    ["eastGTNTempoHandle", createHashMapFromArray [["name", "20s"], ["value", 20]]],
    // Force growth (groups gained per capture): 1 | 2 | 3
    ["westGTNForceGrowthHandle", createHashMapFromArray [["name", "Standard _ 2 Groups Per Capture"], ["value", 2]]],
    ["eastGTNForceGrowthHandle", createHashMapFromArray [["name", "Standard _ 2 Groups Per Capture"], ["value", 2]]],
    // Standing garrison groups per owned objective (whole numbers >= 0): rear = quiet, frontline = next to enemy,
    // priority bonus = important objectives, hot bonus = objectives under pressure.
    // UI presets: Light 1/2/0/1, Standard 1/3/0/1, Heavy 2/3/0/1, Fortified 2/4/0/2.
    ["westGTNGarrisonHandle", createHashMapFromArray [
        ["name", "Standard _ 1 Rear / 3 Front"],
        ["rearBaseGroups", 1],
        ["frontlineBaseGroups", 3],
        ["priorityBonusGroups", 0],
        ["hotBonusGroups", 1]
    ]],
    ["eastGTNGarrisonHandle", createHashMapFromArray [
        ["name", "Standard _ 1 Rear / 3 Front"],
        ["rearBaseGroups", 1],
        ["frontlineBaseGroups", 3],
        ["priorityBonusGroups", 0],
        ["hotBonusGroups", 1]
    ]],

    // Force composition, one per side. All values are whole numbers >= 0.
    // transportReserve*: standby ground / air transport groups.
    // objectiveGroupTypeCaps: side-wide maximum objective garrison groups per type, filled by objective priority (999 = uncapped).
    // groupCounts: units per group of each type.
    // objectiveGroups: garrison groups spawned at each objective type. Every objective type needs all 8 group types.
    ["westFactionTuningHandle", createHashMapFromArray [
        ["transportReserveGroundCount", 20],
        ["transportReserveAirCount", 10],
        ["objectiveGroupTypeCaps", [
            ["infantry", 999], ["motorized", 999], ["mechanized", 999], ["armor", 999], ["helicopter", 10],
            ["jet", 10], ["air", 5], ["artillery", 5], ["mobile_aa", 20], ["static_aa", 3]
        ]],
        ["groupCounts", [
            ["infantry", 10], ["motorized", 1], ["mechanized", 1], ["armor", 1], ["helicopter", 1],
            ["jet", 1], ["air", 1], ["artillery", 3], ["mobile_aa", 1], ["static_aa", 1]
        ]],
        ["objectiveGroups", [
            ["capital", [["infantry", 12], ["motorized", 2], ["mechanized", 1], ["armor", 1], ["air", 1], ["artillery", 1], ["mobile_aa", 1], ["static_aa", 1]]],
            ["city",    [["infantry", 12], ["motorized", 2], ["mechanized", 1], ["armor", 1], ["air", 1], ["artillery", 1], ["mobile_aa", 1], ["static_aa", 1]]],
            ["village", [["infantry", 3], ["motorized", 0], ["mechanized", 0], ["armor", 0], ["air", 0], ["artillery", 0], ["mobile_aa", 0], ["static_aa", 0]]],
            ["local",   [["infantry", 6], ["motorized", 2], ["mechanized", 1], ["armor", 0], ["air", 0], ["artillery", 0], ["mobile_aa", 1], ["static_aa", 0]]],
            ["marine",  [["infantry", 3], ["motorized", 1], ["mechanized", 0], ["armor", 0], ["air", 0], ["artillery", 0], ["mobile_aa", 0], ["static_aa", 0]]],
            ["cluster", [["infantry", 2], ["motorized", 0], ["mechanized", 0], ["armor", 0], ["air", 0], ["artillery", 0], ["mobile_aa", 0], ["static_aa", 0]]]
        ]]
    ]],
    ["eastFactionTuningHandle", createHashMapFromArray [
        ["transportReserveGroundCount", 20],
        ["transportReserveAirCount", 10],
        ["objectiveGroupTypeCaps", [
            ["infantry", 999], ["motorized", 999], ["mechanized", 999], ["armor", 999], ["helicopter", 10],
            ["jet", 10], ["air", 5], ["artillery", 5], ["mobile_aa", 20], ["static_aa", 3]
        ]],
        ["groupCounts", [
            ["infantry", 10], ["motorized", 1], ["mechanized", 1], ["armor", 1], ["helicopter", 1],
            ["jet", 1], ["air", 1], ["artillery", 3], ["mobile_aa", 1], ["static_aa", 1]
        ]],
        ["objectiveGroups", [
            ["capital", [["infantry", 12], ["motorized", 2], ["mechanized", 1], ["armor", 1], ["air", 1], ["artillery", 1], ["mobile_aa", 1], ["static_aa", 1]]],
            ["city",    [["infantry", 12], ["motorized", 2], ["mechanized", 1], ["armor", 1], ["air", 1], ["artillery", 1], ["mobile_aa", 1], ["static_aa", 1]]],
            ["village", [["infantry", 3], ["motorized", 0], ["mechanized", 0], ["armor", 0], ["air", 0], ["artillery", 0], ["mobile_aa", 0], ["static_aa", 0]]],
            ["local",   [["infantry", 6], ["motorized", 2], ["mechanized", 1], ["armor", 0], ["air", 0], ["artillery", 0], ["mobile_aa", 1], ["static_aa", 0]]],
            ["marine",  [["infantry", 3], ["motorized", 1], ["mechanized", 0], ["armor", 0], ["air", 0], ["artillery", 0], ["mobile_aa", 0], ["static_aa", 0]]],
            ["cluster", [["infantry", 2], ["motorized", 0], ["mechanized", 0], ["armor", 0], ["air", 0], ["artillery", 0], ["mobile_aa", 0], ["static_aa", 0]]]
        ]]
    ]],

    // Artillery balance. Read on every start, including Continue.
    ["artilleryHandle", createHashMapFromArray [
        ["sideCooldownSeconds", 300],                           // 60-1800: minimum gap between missions for one side
        ["batteryCooldownSeconds", 600],                        // 60-3600: rearm time before a battery fires again
        ["treasuryCostPerRound", 100],                          // 25-500: side treasury cost per round
        ["localSupplyCostPerRound", 150]                        // 25-500: Local Supplies cost per round
    ]],

    ["startingResources", 5000],                                // whole number >= 0
    ["objectiveSizeThreshold", 8],                              // minimum buildings for a building-cluster objective: 4 | 8 | 12 | 24
    ["virtualizationDistance", 1500],                           // metres from players where AI becomes physical: 1000 | 1500 | 2000 | 2500 | 3000
    ["virtualizationUnitCap", 100],                             // maximum active AI units: 100-400 in steps of 50
    ["startingTerritoryWestRatio", 0.5],                        // BLUFOR share of starting objectives: 0.1-0.9
    ["startPosition", [worldSize / 2, worldSize / 2, 0]]        // [x, y, z] of the starting FOB, inside the terrain
]
