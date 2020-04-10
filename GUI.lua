local addonName = "BGHistorian"
local addonTitle = select(2, GetAddOnInfo(addonName))
local BGH = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")
local f, scrollFrame, rows, stats
local lblWinrate, lblDuration

function BGH:CreateGUI()
    f = AceGUI:Create("Frame")
    f:Hide()
    f:EnableResize(false)

    -- f:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    f:SetTitle(addonTitle)
    local frameName = addonName .."_MainFrame"
	_G[frameName] = f
	table.insert(UISpecialFrames, frameName) -- Allow ESC close
    f:SetStatusText("Status Bar")
    f:SetLayout("Flow")

    -- STATS HEADER
    local statsHeader = AceGUI:Create("SimpleGroup")
	statsHeader:SetFullWidth(true)
	statsHeader:SetLayout("Flow")
    f:AddChild(statsHeader)

    -- WINRATE
    local block = AceGUI:Create("SimpleGroup")
    statsHeader:AddChild(block)

	local lbl = AceGUI:Create("Label")
    lbl:SetJustifyH("CENTER")
    lbl:SetText(L["Winrate"])
    lbl:SetFontObject(GameFontHighlight)
    block:AddChild(lbl)

	lblWinrate = AceGUI:Create("InteractiveLabel")
    lblWinrate:SetJustifyH("CENTER")
    lblWinrate:SetFontObject(GameFontHighlightLarge)
    lblWinrate:SetText(string.format("%.2f%%", 0))
	lblWinrate:SetCallback("OnEnter", function() self:ShowTooltip(lblWinrate, {
        string.format("%s %i/%i", L["Winrate"], stats["victories"][0], stats["count"][0]),
        string.format("%s %.2f%%", self:MapName(1), stats["winrate"][1] * 100),
        string.format("%s %.2f%%", self:MapName(2), stats["winrate"][2] * 100),
        string.format("%s %.2f%%", self:MapName(3), stats["winrate"][3] * 100),
    }) end)
	lblWinrate:SetCallback("OnLeave", function() self:HideTooltip() end)
    block:AddChild(lblWinrate)

    -- DURATION
    block = AceGUI:Create("SimpleGroup")
    statsHeader:AddChild(block)

	lbl = AceGUI:Create("Label")
    lbl:SetJustifyH("CENTER")
    lbl:SetText(L["Duration"])
    lbl:SetFontObject(GameFontHighlight)
    block:AddChild(lbl)

	lblDuration = AceGUI:Create("InteractiveLabel")
    lblDuration:SetJustifyH("CENTER")
    lblDuration:SetFontObject(GameFontHighlightLarge)
    lblDuration:SetText(self:HumanDuration(0))
	lblDuration:SetCallback("OnEnter", function() self:ShowTooltip(lblDuration, {
        string.format("%s", L["Duration"]),
        string.format("%s %s", self:MapName(1), self:HumanDuration(stats["averageRunTime"][1])),
        string.format("%s %s", self:MapName(2), self:HumanDuration(stats["averageRunTime"][2])),
        string.format("%s %s", self:MapName(3), self:HumanDuration(stats["averageRunTime"][3])),
    }) end)
	lblDuration:SetCallback("OnLeave", function() self:HideTooltip() end)
    block:AddChild(lblDuration)

    -- TABLE HEADER
    local tableHeader = AceGUI:Create("SimpleGroup")
	tableHeader:SetFullWidth(true)
	tableHeader:SetLayout("Flow")
    f:AddChild(tableHeader)

    local margin = AceGUI:Create("Label")
    margin:SetWidth(4)
    tableHeader:AddChild(margin)

    local btn
	btn = AceGUI:Create("InteractiveLabel")
    btn:SetWidth(145)
    btn:SetText(string.format(" %s ", L["Date"]))
    btn:SetJustifyH("LEFT")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("endTime") end)
    tableHeader:AddChild(btn)

    margin = AceGUI:Create("Label")
    margin:SetWidth(4)
    tableHeader:AddChild(margin)

	btn = AceGUI:Create("InteractiveLabel")
	btn:SetWidth(170)
	btn:SetText(string.format(" %s ", L["Battleground"]))
    btn:SetJustifyH("LEFT")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("mapName") end)
	tableHeader:AddChild(btn)

    margin = AceGUI:Create("Label")
    margin:SetWidth(4)
    tableHeader:AddChild(margin)

	btn = AceGUI:Create("InteractiveLabel")
	btn:SetWidth(94)
	btn:SetText(string.format(" %s ", L["Duration"]))
    btn:SetJustifyH("LEFT")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("runTime") end)
    tableHeader:AddChild(btn)

    margin = AceGUI:Create("Label")
    margin:SetWidth(4)
    tableHeader:AddChild(margin)

	btn = AceGUI:Create("InteractiveLabel")
	btn:SetWidth(40)
	btn:SetText(string.format(" %s ", L["Winner"]))
    btn:SetJustifyH("CENTER")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("battlefieldWinner") end)
    tableHeader:AddChild(btn)

    margin = AceGUI:Create("Label")
    margin:SetWidth(4)
    tableHeader:AddChild(margin)

	btn = AceGUI:Create("InteractiveLabel")
	btn:SetWidth(36)
	btn:SetText(string.format(" %s ", L["KB"]))
    btn:SetJustifyH("RIGHT")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("killingBlows") end)
    tableHeader:AddChild(btn)

    margin = AceGUI:Create("Label")
    margin:SetWidth(4)
    tableHeader:AddChild(margin)
	btn = AceGUI:Create("InteractiveLabel")
	btn:SetWidth(40)
	btn:SetText(string.format(" %s ", L["HK"]))
    btn:SetJustifyH("RIGHT")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("honorableKills") end)
    tableHeader:AddChild(btn)

    margin = AceGUI:Create("Label")
    margin:SetWidth(4)
    tableHeader:AddChild(margin)

	btn = AceGUI:Create("InteractiveLabel")
	btn:SetWidth(40)
	btn:SetText(string.format(" %s ", L["Deaths"]))
    btn:SetJustifyH("RIGHT")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("deaths") end)
    tableHeader:AddChild(btn)

    margin = AceGUI:Create("Label")
    margin:SetWidth(4)
    tableHeader:AddChild(margin)

	btn = AceGUI:Create("InteractiveLabel")
	btn:SetWidth(44)
	btn:SetText(string.format(" %s ", L["Honor"]))
    btn:SetJustifyH("RIGHT")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("honorGained") end)
	tableHeader:AddChild(btn)

    margin = AceGUI:Create("Label")
    margin:SetWidth(4)
    tableHeader:AddChild(margin)

    -- TABLE
    local scrollContainer = AceGUI:Create("SimpleGroup")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetFullHeight(true)
    scrollContainer:SetLayout("Fill")
    f:AddChild(scrollContainer)

	scrollFrame = CreateFrame("ScrollFrame", nil, scrollContainer.frame, "BGHHybridScrollFrame")
	HybridScrollFrame_CreateButtons(scrollFrame, "BGHHybridScrollListItemTemplate")
	scrollFrame.update = function() BGH:UpdateTableView() end
end

function BGH:RefreshLayout()
	local buttons = HybridScrollFrame_GetButtons(scrollFrame)
    local offset = HybridScrollFrame_GetOffset(scrollFrame)

    f:SetStatusText(string.format(L["Recorded %i battlegrounds"], #rows))
    lblWinrate:SetText(string.format("%.2f%%", stats["winrate"][0] * 100))
    lblDuration:SetText(self:HumanDuration(stats["averageRunTime"][0]))

	for buttonIndex = 1, #buttons do
		local button = buttons[buttonIndex]
        local itemIndex = buttonIndex + offset
        local row = rows[itemIndex]

        if (itemIndex <= #rows) then
            button:SetID(itemIndex)
            button.Icon:SetTexture(self:MapIconId(row["mapId"]))
            button.EndTime:SetText(date(L["%F %T"], row["endTime"]))
            button.MapName:SetText(row["mapName"])
            button.RunTime:SetText(self:HumanDuration(row["runTime"]))
            button.BattlefieldWinner:SetTexture(132485 + row["battlefieldWinner"])
            button.KillingBlows:SetText(row["killingBlows"])
            button.HonorableKills:SetText(row["honorableKills"])
            button.Deaths:SetText(row["deaths"])
            button.HonorGained:SetText(row["honorGained"])

            button:SetWidth(scrollFrame.scrollChild:GetWidth())
			button:Show()
		else
			button:Hide()
		end
	end

	local buttonHeight = scrollFrame.buttonHeight
	local totalHeight = #rows * buttonHeight
	local shownHeight = #buttons * buttonHeight

	HybridScrollFrame_Update(scrollFrame, totalHeight, shownHeight)
end

function BGH:Show()
    if not f then
        self:CreateGUI()
    end

    rows = BGH:BuildTable()
    stats = BGH:CalcStats()

    f:Show()
    self:RefreshLayout()
end

function BGH:Hide()
    f:Hide()
end

function BGH:Toggle()
    if f and f:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function BGH:Sort(column)
    scrollFrame:SetVerticalScroll(0)
    rows = BGH:BuildTable(column)
    self:RefreshLayout()
end

function BGH:HumanDuration(miliseconds)
    local seconds = math.floor(miliseconds / 1000)
    if seconds < 60 then
        return string.format(L["%is"], seconds)
    end
    local minutes = math.floor(seconds / 60)
    if minutes < 60 then
        return string.format(L["%im %is"], minutes, (seconds - minutes * 60))
    end
    local hours = math.floor(minutes / 60)
    return string.format(L["%ih %im"], hours, (minutes - hours * 60))
end

function BGH:MapIconId(mapId)
    if not mapId then
        return 136628
    end

    if mapId == 1 then -- Alterac Valley
        return 133308
    elseif mapId == 2 then -- Warsong Gulch
        return 134420
    elseif mapId == 3 then -- Arathi Basin
        return 133282
    end
end

function BGH:ShowTooltip(owner, lines)
    AceGUI.tooltip:SetOwner(owner.frame, "ANCHOR_BOTTOMLEFT")
    AceGUI.tooltip:ClearLines()
    for i, line in ipairs(lines) do
        if i == 1 then
            AceGUI.tooltip:AddLine(line)
        else
            AceGUI.tooltip:AddLine(line, 1, 1, 1)
        end
    end
    AceGUI.tooltip:Show()
end

function BGH:HideTooltip()
    AceGUI.tooltip:Hide()
end
