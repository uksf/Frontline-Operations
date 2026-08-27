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
    ["westFactionTuningHandle", createHashMap],
    ["eastFactionTuningHandle", createHashMap],
    ["startingResources", 5000],
    ["objectiveSizeThreshold", 8],
    ["virtualizationDistance", 1500],
    ["virtualizationUnitCap", 100],
    ["startingTerritoryWestRatio", 0.5],
    ["startPosition", [worldSize / 2, worldSize / 2, 0]]
]
