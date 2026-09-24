createHashMapFromArray [
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
    ["playerSideKey", "WEST"],
    ["reputationHandle", createHashMapFromArray [
        ["name", "Neutral _ Civilians Tolerate Players"],
        ["value", 9]
    ]],
    ["westDifficultyHandle", createHashMapFromArray [["name", "MEDIUM _ Balanced Commander"], ["value", 1]]],
    ["eastDifficultyHandle", createHashMapFromArray [["name", "MEDIUM _ Balanced Commander"], ["value", 1]]],
    ["westGTNAttackCoverageHandle", createHashMapFromArray [["name", "Balanced Coverage"], ["value", 0.75]]],
    ["eastGTNAttackCoverageHandle", createHashMapFromArray [["name", "Balanced Coverage"], ["value", 0.75]]],
    ["westGTNDefenseCoverageHandle", createHashMapFromArray [["name", "Balanced Coverage"], ["value", 0.75]]],
    ["eastGTNDefenseCoverageHandle", createHashMapFromArray [["name", "Balanced Coverage"], ["value", 0.75]]],
    ["westGTNTempoHandle", createHashMapFromArray [["name", "20s"], ["value", 20]]],
    ["eastGTNTempoHandle", createHashMapFromArray [["name", "20s"], ["value", 20]]],
    ["westGTNForceGrowthHandle", createHashMapFromArray [["name", "Standard _ 2 Groups Per Capture"], ["value", 2]]],
    ["eastGTNForceGrowthHandle", createHashMapFromArray [["name", "Standard _ 2 Groups Per Capture"], ["value", 2]]],
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
    // Force composition tab. Every value is required; 999 means uncapped.
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
        ["sideCooldownSeconds", 300],
        ["batteryCooldownSeconds", 600],
        ["treasuryCostPerRound", 100],
        ["localSupplyCostPerRound", 150]
    ]],
    ["startingResources", 5000],
    ["objectiveSizeThreshold", 8],
    ["virtualizationDistance", 1500],
    ["virtualizationUnitCap", 100],
    ["startingTerritoryWestRatio", 0.5],
    ["startPosition", [worldSize / 2, worldSize / 2, 0]]
]
