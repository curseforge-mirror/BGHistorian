local BGH = LibStub("AceAddon-3.0"):GetAddon("BGHistorian")
local AceGUI = LibStub("AceGUI-3.0")
local f, scrollFrame, rows

function BGH:CreateGUI()
    f = AceGUI:Create("Frame")
    f:Hide()

    -- f:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    f:SetTitle("BGHistorian")
    f:SetStatusText("Status Bar")
    f:SetLayout("Flow")

    local tableHeader = AceGUI:Create("SimpleGroup")
	tableHeader:SetFullWidth(true)
	tableHeader:SetLayout("Flow")
    f:AddChild(tableHeader)

    local btn;
	btn = AceGUI:Create("InteractiveLabel")
    btn:SetWidth(150)
    btn:SetText(" Date")
    btn:SetJustifyH("LEFT")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("endTime") end)
    tableHeader:AddChild(btn)

	btn = AceGUI:Create("InteractiveLabel")
	btn:SetWidth(174)
	btn:SetText(" Battleground")
    btn:SetJustifyH("LEFT")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("mapName") end)
	tableHeader:AddChild(btn)

	btn = AceGUI:Create("InteractiveLabel")
	btn:SetWidth(100)
	btn:SetText(" Duration")
    btn:SetJustifyH("LEFT")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("runTime") end)
    tableHeader:AddChild(btn)

	btn = AceGUI:Create("InteractiveLabel")
	btn:SetWidth(40)
	btn:SetText("Winner")
    btn:SetJustifyH("CENTER")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("battlefieldWinner") end)
    tableHeader:AddChild(btn)

	btn = AceGUI:Create("InteractiveLabel")
	btn:SetWidth(32)
	btn:SetText("KB ")
    btn:SetJustifyH("RIGHT")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("killingBlows") end)
    tableHeader:AddChild(btn)

	btn = AceGUI:Create("InteractiveLabel")
	btn:SetWidth(40)
	btn:SetText("HK ")
    btn:SetJustifyH("RIGHT")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("honorableKills") end)
    tableHeader:AddChild(btn)

	btn = AceGUI:Create("InteractiveLabel")
	btn:SetWidth(40)
	btn:SetText("Deaths ")
    btn:SetJustifyH("RIGHT")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("deaths") end)
    tableHeader:AddChild(btn)

	btn = AceGUI:Create("InteractiveLabel")
	btn:SetWidth(44)
	btn:SetText("Honor ")
    btn:SetJustifyH("RIGHT")
	btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	btn:SetCallback("OnClick", function() BGH:Sort("honorGained") end)
	tableHeader:AddChild(btn)

    local scrollContainer = AceGUI:Create("SimpleGroup")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetFullHeight(true)
    scrollContainer:SetLayout("Fill")
    f:AddChild(scrollContainer)

	scrollFrame = CreateFrame("ScrollFrame", nil, scrollContainer.frame, "BGHHybridScrollFrame")
	HybridScrollFrame_CreateButtons(scrollFrame, "BGHHybridScrollListItemTemplate");
	scrollFrame.update = function() BGH:UpdateTableView() end
end

function BGH:RefreshLayout()
	local buttons = HybridScrollFrame_GetButtons(scrollFrame);
    local offset = HybridScrollFrame_GetOffset(scrollFrame);

    f:SetStatusText(string.format("Recorded %i battlegrounds", #rows))
    -- self:Printf("Buttons : %i | Offset : %i | Rows : %i", #buttons, offset, #rows)

	for buttonIndex = 1, #buttons do
		local button = buttons[buttonIndex];
        local itemIndex = buttonIndex + offset;
        local row = rows[itemIndex]

        if (itemIndex <= #rows) then
            button:SetID(itemIndex);
            -- button.Icon:SetTexture(133308);
            button.Icon:SetTexture(136628);
            button.EndTime:SetText(date("%F %T", row["endTime"]));
            button.MapName:SetText(row["mapName"]);
            button.RunTime:SetText(HumanDuration(row["runTime"]));
            -- button.BattlefieldWinner:SetTexture(130705 - row["battlefieldWinner"]);
            button.BattlefieldWinner:SetTexture(132485 + row["battlefieldWinner"]);
            button.KillingBlows:SetText(row["killingBlows"]);
            button.HonorableKills:SetText(row["honorableKills"]);
            button.Deaths:SetText(row["deaths"]);
            button.HonorGained:SetText(row["honorGained"]);

            button:SetWidth(scrollFrame.scrollChild:GetWidth());
			button:Show();
		else
			button:Hide();
		end
	end

	local buttonHeight = scrollFrame.buttonHeight;
	local totalHeight = #rows * buttonHeight;
	local shownHeight = #buttons * buttonHeight;

    -- self:Printf("HybridScrollFrame_Update %i %i %i", buttonHeight, totalHeight, shownHeight)
	HybridScrollFrame_Update(scrollFrame, totalHeight, shownHeight);
end

function BGH:Show()
    if not f then
        self:CreateGUI()
    end

    rows = BGH:BuildTable()
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
    scrollFrame:SetVerticalScroll(0);
    rows = BGH:BuildTable(column)
    self:RefreshLayout();
end

function HumanDuration(miliseconds)
    local seconds = math.floor(miliseconds / 1000)
    if seconds < 60 then
        return seconds.."s"
    end
    local minutes = math.floor(seconds / 60)
    if minutes < 60 then
        return minutes.."m "..(seconds - minutes * 60).."s"
    end
    local hours = math.floor(minutes / 60)
    return hours.."h "..(minutes - hours * 60).."m"
end
