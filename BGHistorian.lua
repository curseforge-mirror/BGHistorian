local addonName = "BGHistorian"
local addonTitle = select(2, GetAddOnInfo(addonName))
local BGH = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local libDBIcon = LibStub("LibDBIcon-1.0")

function BGH:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(addonName, {
        profile = {
            minimapButton = {
                hide = false,
            },
            maxHistory = 0,
        },
        char = {
            history = {},
        },
    })
    -- BGH:Print("OnInitialize")

    self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
    self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")

	self:DrawMinimapIcon()
    self:RegisterOptionsTable()

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

    local status, mapName = GetBattlefieldStatus(battleFieldIndex)
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
        self.current["stats"]["mapId"] = self:MapId(mapName)
    elseif self.current["battleFieldIndex"] == battleFieldIndex and self.current["status"] == "active" and status == "none" then
        -- self:Print("Leaving battleground")
        self.current["status"] = status
    end
end

-- Wowpedia: Fired whenever new battlefield score data has been recieved, this is usually fired after RequestBattlefieldScoreData is called.
-- This is pretty regular at around 1/sec (maybe linked to Capping ?)
function BGH:UPDATE_BATTLEFIELD_SCORE(eventName)
    -- Faction/team that has won the battlefield. Results are: nil if nobody has won, 0 for Horde and 1 for Alliance in a battleground
    local battlefieldWinner = GetBattlefieldWinner()
    if battlefieldWinner == nil or self.battlegroundEnded then
        return
    end

    self.battlegroundEnded = true
    -- self:Print("Battleground ended")

    self:RecordBattleground()
end

function BGH:RecordBattleground()
	local _, _, _, _, numHorde = GetBattlefieldTeamInfo(0)
    local _, _, _, _, numAlliance = GetBattlefieldTeamInfo(1)

    self.current["stats"]["battlefieldWinner"] = GetBattlefieldWinner()
    self.current["stats"]["runTime"] = GetBattlefieldInstanceRunTime() -- includes prep time
    self.current["stats"]["numHorde"] = numHorde
    self.current["stats"]["numAlliance"] = numAlliance
    self.current["stats"]["endTime"] = time()

    -- BG specific stats
	local numStatColumns = GetNumBattlefieldStats()
    local numScores = GetNumBattlefieldScores()
    local name, killingBlows, honorableKills, deaths, honorGained, faction, rank, race, class, classToken
    local playersStats = {}
    for i=1, numScores do
        name, killingBlows, honorableKills, deaths, honorGained, faction, rank, race, class, classToken = GetBattlefieldScore(i)
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
        -- rankName, rankNumber = GetPVPRankInfo(rank, faction)
        local columnData
        for j=1, numStatColumns do
            columnData = GetBattlefieldStatData(i, j)
            battlefieldScore["statData"][j] = columnData
        end

        table.insert(playersStats, battlefieldScore)
    end

    self.current["stats"]["scores"] = playersStats
    table.insert(self.db.char.history, self.current["stats"])

    if self.db.profile.maxHistory > 0 then
        -- Shift array until we get under threshold
        while (#self.db.char.history > self.db.profile.maxHistory) do
            table.remove(self.db.char.history, 1)
        end
    end
end

function BGH:ResetDatabase()
    self.db:ResetDB()
    self:Print(L["Database reset"])
end

function BGH:DrawMinimapIcon()
	libDBIcon:Register(addonName, LibStub("LibDataBroker-1.1"):NewDataObject(addonName,
	{
		type = "data source",
		text = addonName,
        icon = "interface/icons/inv_misc_book_03",
		OnClick = function(self, button)
			if (button == "RightButton") then
                InterfaceOptionsFrame_OpenToCategory(addonName)
                InterfaceOptionsFrame_OpenToCategory(addonName)
            else
                BGH:Toggle()
            end
		end,
		OnTooltipShow = function(tooltip)
			tooltip:AddLine(string.format("%s |cff777777v%s|r", addonTitle, "@project-version@"))
			tooltip:AddLine(string.format("|cFFCFCFCF%s|r %s", L["Left Click"], L["to open the main window"]))
			tooltip:AddLine(string.format("|cFFCFCFCF%s|r %s", L["Right Click"], L["to open options"]))
			tooltip:AddLine(string.format("|cFFCFCFCF%s|r %s", L["Drag"], L["to move this button"]))
		end
    }), self.db.profile.minimapButton)
end

function BGH:ToggleMinimapButton()
    self.db.profile.minimapButton.hide = not self.db.profile.minimapButton.hide
    if self.db.profile.minimapButton.hide then
        libDBIcon:Hide(addonName)
    else
        libDBIcon:Show(addonName)
    end
end

function BGH:BuildTable(sortColumn)
    -- self:Print("Rebuilding data table")
    local tbl = {}
    local me = UnitName("player")

    for _, row in ipairs(self.db.char.history) do
        local playerScore
        for _, score in ipairs(row["scores"]) do
            if score["name"] == me then
                playerScore = score
                break
            end
        end

        table.insert(tbl, {
            ["endTime"] = row["endTime"],
            ["mapId"] = row["mapId"],
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

function BGH:MapId(mapName)
    if mapName == L["Alterac Valley"] then
        return 1
    elseif mapName == L["Warsong Gulch"] then
        return 2
    elseif mapName == L["Arathi Basin"] then
        return 3
    end

    return nil
end

function BGH:OptimizeDatabase()
    for i, row in ipairs(self.db.char.history) do
        if row["battleFieldIndex"] then
            self.db.char.history[i]["battleFieldIndex"] = nil
        end
        if row["status"] then
            self.db.char.history[i]["status"] = nil
        end
        if not row["mapId"] then
            self.db.char.history[i]["mapId"] = self:MapId(row["mapName"])
        end
    end
end
