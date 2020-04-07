local BGH = LibStub("AceAddon-3.0"):NewAddon("BGHistorian", "AceConsole-3.0", "AceEvent-3.0", "AceSerializer-3.0")

local debugData = nil
function BGH:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BGHistorian", {
        profile = {
            minimapButton = {hide = false},
        },
        char = {
            history = {}
        },
    })
    -- BGH:Print("OnInitialize")

    self:RegisterEvent("BATTLEFIELD_QUEUE_TIMEOUT")
    self:RegisterEvent("BATTLEFIELDS_CLOSED")
    self:RegisterEvent("BATTLEFIELDS_SHOW")
    self:RegisterEvent("BATTLEGROUND_OBJECTIVES_UPDATE")
    self:RegisterEvent("BATTLEGROUND_POINTS_UPDATE")
    self:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
    -- self:RegisterEvent("UPDATE_ACTIVE_BATTLEFIELD")
    self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
    self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")

    self:RegisterChatCommand("bgh", "ChatCommandHandler")

	self:DrawMinimapIcon();

    self.battlegroundEnded = false
    self.sortColumn = "endTime"
    self.sortOrder = true
    self.current = {
        status = "none",
    }
end

-- Wowpedia: Fired when a War Game request times out without a response.
-- This seems to be unused in classic
function BGH:BATTLEFIELD_QUEUE_TIMEOUT(eventName)
    self:Print("BATTLEFIELD_QUEUE_TIMEOUT")
end

-- Wowpedia: Fired when the battlegrounds signup window is closed.
function BGH:BATTLEFIELDS_CLOSED(eventName)
    self:Print("BATTLEFIELDS_CLOSED")
end

-- Wowpedia: Fired when the battlegrounds signup window is opened.
-- "I would like to go to the battleground."
function BGH:BATTLEFIELDS_SHOW(eventName, isArena, battleMasterListID)
    self:Print("BATTLEFIELDS_SHOW", isArena, battleMasterListID)

	local localizedName, canEnter, isHoliday, isRandom, battleGroundID, mapDescription, BGMapID, maxPlayers, gameType, iconTexture, shortDescription, longDescription = GetBattlegroundInfo();
    -- This function returns info relative to latest BATTLEFIELDS_SHOW
    -- Sadly, canEnter, isHoliday & isRandom are always false
    self:Print("GetBattlegroundInfo", localizedName, canEnter, isHoliday, isRandom, battleGroundID, BGMapID, maxPlayers, gameType)
end

function BGH:BATTLEGROUND_OBJECTIVES_UPDATE(eventName)
    self:Print("BATTLEGROUND_OBJECTIVES_UPDATE")
end

function BGH:BATTLEGROUND_POINTS_UPDATE(eventName)
    self:Print("BATTLEGROUND_POINTS_UPDATE")
end

-- Enter battleground | reload while in BG
function BGH:PLAYER_ENTERING_BATTLEGROUND(eventName)
    self:Print("PLAYER_ENTERING_BATTLEGROUND")
end

-- Fired at enter BG | reload in BG | on game over | leave BG
function BGH:UPDATE_ACTIVE_BATTLEFIELD(eventName)
    self:Print("UPDATE_ACTIVE_BATTLEFIELD")
    -- This is triggered after UPDATE_BATTLEFIELD_STATUS
    -- UI uses this to update Party & Raid frames
    -- This is probably useless for us
end

-- Wowpedia: Fired whenever joining a queue, leaving a queue, battlefield to join is changed, when you can join a battlefield, or if somebody wins the battleground.
-- Fired at enter BG | reload in BG | on game over | leave BG | queue BG | regularly while in queue | queue pops
function BGH:UPDATE_BATTLEFIELD_STATUS(eventName, battleFieldIndex)
    self:Print("UPDATE_BATTLEFIELD_STATUS", battleFieldIndex)

    local status, mapName, instanceID, _, _, _, _, _, _, asGroup = GetBattlefieldStatus(battleFieldIndex);
    -- status = ["queued", "confirm", "active", "none" = leave] -- active is also triggered on game over
    -- mapName = ["Alterac Valley"]
    -- instanceID = 0 queued & confirm & none / >0 active
    self:Print("GetBattlefieldStatus", status, mapName, instanceID, asGroup)

    if self.current["status"] == "none" and status == "active" then
        self.battlegroundEnded = false
        self:Print("Entering battleground")
        self.current["battleFieldIndex"] = battleFieldIndex
        self.current["startTime"] = time()
        self.current["mapName"] = mapName
        self.current["status"] = status
    end

    if self.current["battleFieldIndex"] == battleFieldIndex and self.current["status"] == "active" and status == "none" then
        self:Print("Leaving battleground")
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
    self:Print("Battleground ended")

	local _, _, _, _, numHorde = GetBattlefieldTeamInfo(0);
    local _, _, _, _, numAlliance = GetBattlefieldTeamInfo(1);
    local runTime = GetBattlefieldInstanceRunTime(); -- includes prep time
    -- self:Print(runTime, numHorde, numAlliance)

    self.current["battlefieldWinner"] = battlefieldWinner
    self.current["runTime"] = runTime
    self.current["numHorde"] = numHorde
    self.current["numAlliance"] = numAlliance
    self.current["endTime"] = time()

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

    self.current["scores"] = playersStats
    table.insert(self.db.char.history, self.current)
end

function BGH:Reset()
    self.db:ResetDB()
    self:Print("Database reset")
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
        -- icon = "Interface\\Icons\\Inv_Misc_Bomb_04",
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
