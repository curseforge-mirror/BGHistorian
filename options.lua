local addonName = "BGHistorian"
local _, addonTitle, addonNotes = GetAddOnInfo(addonName)
local BGH = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceConfig = LibStub("AceConfig-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function BGH:RegisterOptionsTable()
    AceConfig:RegisterOptionsTable(addonName, {
        name = addonName,
        descStyle = "inline",
        handler = BGH,
        type = "group",
        args = {
            General = {
                order = 1,
                type = "group",
                name = L["Options"],
                args = {
                    intro = {
                        order = 0,
                        type = "description",
                        name = addonNotes,
                    },
                    group1 = {
                        order = 10,
                        type = "group",
                        name = L["Database Settings"],
                        inline = true,
                        args = {
                            purge = {
                                order = 19,
                                type = "execute",
                                name = L["Purge database"],
                                desc = L["Delete all collected data"],
                                confirm = true,
                                func = function() self:Reset() end
                            },
                        },
                    },
                    group2 = {
                        order = 20,
                        type = "group",
                        name = L["Minimap Button Settings"],
                        inline = true,
                        args = {
                            minimapButton = {
                                order = 21,
                                type = "toggle",
                                name = L["Show minimap button"],
                                get = function()
                                    return not self.db.profile.minimapButton.hide
                                end,
                                set = 'ToggleMinimapButton',
                            },
                        },
                    },
                }
            },
            Profiles = AceDBOptions:GetOptionsTable(BGH.db),
        }
    }, {"bgh"})
    AceConfigDialog:AddToBlizOptions(addonName, nil, nil, "General")

    AceConfigDialog:AddToBlizOptions(addonName, "Profiles", addonName, "Profiles")
end
