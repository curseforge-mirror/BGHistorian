local BGH = LibStub("AceAddon-3.0"):NewAddon("BGHistorian", "AceConsole-3.0", "AceEvent-3.0", "AceSerializer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BGHistorian", true)

local debugData = nil
function BGH:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BGHistorian", {
        profile = {
            minimapButton = {
                hide = false,
            },
        },
        char = {
            history = {},
        },
    })
    -- BGH:Print("OnInitialize")

    self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
    self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")

    self:RegisterChatCommand("bgh", "ChatCommandHandler")

	self:DrawMinimapIcon();

    self.battlegroundEnded = false
    self.sortColumn = "endTime"
    self.sortOrder = true
    self.current = {
        status = "none",
        battleFieldIndex = nil,
        stats = {},
    }
end

-- Wowpedia: Fired whenever joining a queue, leaving a queue, battlefield to join is changed, when you can join a battlefield, or if somebody wins the battleground.
-- Fired at enter BG | reload in BG | on game over | leave BG | queue BG | regularly while in queue | queue pops
function BGH:UPDATE_BATTLEFIELD_STATUS(eventName, battleFieldIndex)
    -- self:Print("UPDATE_BATTLEFIELD_STATUS", battleFieldIndex)

    local status, mapName = GetBattlefieldStatus(battleFieldIndex);
    -- status = ["queued", "confirm", "active", "none" = leave] -- active is also triggered on game over
    -- mapName = ["Alterac Valley"]
    -- instanceID = 0 queued & confirm & none / >0 active
    -- self:Print("GetBattlefieldStatus", status, mapName, instanceID, asGroup)

    if self.current["status"] == "none" and status == "active" then
        -- self:Print("Entering battleground")
        self.battlegroundEnded = false
        self.current["status"] = status
        self.current["battleFieldIndex"] = battleFieldIndex
        self.current["stats"]["startTime"] = time()
        self.current["stats"]["mapName"] = mapName
    elseif self.current["battleFieldIndex"] == battleFieldIndex and self.current["status"] == "active" and status == "none" then
        -- self:Print("Leaving battleground")
        self.current["status"] = status
    end
end

-- Wowpedia: Fired whenever new battlefield score data has been recieved, this is usually fired after RequestBattlefieldScoreData is called.
-- This is pretty regular at around 1/sec (maybe linked to Capping ?)
function BGH:UPDATE_BATTLEFIELD_SCORE(eventName)
    -- self:Print("UPDATE_BATTLEFIELD_SCORE")

    -- Faction/team that has won the battlefield. Results are: nil if nobody has won, 0 for Horde and 1 for Alliance in a battleground
    local battlefieldWinner = GetBattlefieldWinner();
    if battlefieldWinner == nil or self.battlegroundEnded then
        return
    end

    self.battlegroundEnded = true
    -- self:Print("Battleground ended")

	local _, _, _, _, numHorde = GetBattlefieldTeamInfo(0);
    local _, _, _, _, numAlliance = GetBattlefieldTeamInfo(1);
    local runTime = GetBattlefieldInstanceRunTime(); -- includes prep time
    -- self:Print(runTime, numHorde, numAlliance)

    self.current["stats"]["battlefieldWinner"] = battlefieldWinner
    self.current["stats"]["runTime"] = runTime
    self.current["stats"]["numHorde"] = numHorde
    self.current["stats"]["numAlliance"] = numAlliance
    self.current["stats"]["endTime"] = time()

    -- BG specific stats
	local numStatColumns = GetNumBattlefieldStats();
    local numScores = GetNumBattlefieldScores();
    local name, killingBlows, honorableKills, deaths, honorGained, faction, rank, race, class, classToken;
    local playersStats = {}
    for i=1, numScores do
        name, killingBlows, honorableKills, deaths, honorGained, faction, rank, race, class, classToken = GetBattlefieldScore(i);
        -- self:Print("GetBattlefieldScore", name, killingBlows, honorableKills, deaths, honorGained, faction, rank, race, class, classToken)
        local battlefieldScore = {
            ["name"] = name,
            ["killingBlows"] = killingBlows,
            ["honorableKills"] = honorableKills,
            ["deaths"] = deaths,
            ["honorGained"] = honorGained,
            ["faction"] = faction,
            ["rank"] = rank,
            ["race"] = race,
            ["class"] = class,
            ["classToken"] = classToken,
            ["statData"] = {},
        }
        -- rankName, rankNumber = GetPVPRankInfo(rank, faction);
        local columnData
        for j=1, numStatColumns do
            columnData = GetBattlefieldStatData(i, j);
            battlefieldScore["statData"][j] = columnData
            -- self:Print("GetBattlefieldStatData", columnData)
        end

        table.insert(playersStats, battlefieldScore)
    end

    self.current["stats"]["scores"] = playersStats
    table.insert(self.db.char.history, self.current["stats"])
end

function BGH:Reset()
    self.db:ResetDB()
    self:Print(L["Database reset"])
end

function BGH:ChatCommandHandler(input)
    if input == "reset" then
        self:Reset()
    else
        self:Toggle()
    end
end

function BGH:DrawMinimapIcon()
	LibStub("LibDBIcon-1.0"):Register("BGHistorian", LibStub("LibDataBroker-1.1"):NewDataObject("BGHistorian",
	{
		type = "data source",
		text = "BGHistorian",
        icon = "interface/icons/inv_misc_book_03",
		OnClick = function(self, button)
            BGH:Toggle()
		end,
		OnTooltipShow = function(tooltip)
			tooltip:AddLine("BGHistorian");
		end
	}), self.db.profile.minimapButton);
end

function BGH:BuildTable(sortColumn)
    -- self:Print("Rebuilding data table")
    local tbl = {}
    local me = UnitName("player")

    for _, row in ipairs(debugData or self.db.char.history) do
        local playerScore
        for _, score in ipairs(row["scores"]) do
            if score["name"] == me then
                playerScore = score
                break
            end
        end

        table.insert(tbl, {
            ["endTime"] = row["endTime"],
            ["mapName"] = row["mapName"],
            ["runTime"] = row["runTime"],
            ["battlefieldWinner"] = row["battlefieldWinner"],
            ["killingBlows"] = playerScore["killingBlows"],
            ["honorableKills"] = playerScore["honorableKills"],
            ["deaths"] = playerScore["deaths"],
            ["honorGained"] = playerScore["honorGained"],
        })
    end

    if sortColumn then
        if self.sortColumn == sortColumn then
            self.sortOrder = not self.sortOrder
        else
            self.sortColumn = sortColumn
            self.sortOrder = true
        end
    end

    table.sort(tbl, function(a, b)
        if self.sortOrder then
            return a[self.sortColumn] > b[self.sortColumn]
        else
            return b[self.sortColumn] > a[self.sortColumn]
        end
    end)

    return tbl
end
