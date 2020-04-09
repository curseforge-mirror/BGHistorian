local addonName = "BGHistorian"
local _, addonTitle, addonNotes = GetAddOnInfo(addonName)
local BGH = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function BGH:RegisterOptionsTable()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, {
        name = addonName,
        descStyle = "inline",
        handler = BGH,
        type = "group",
        args = {
            general = {
                order = 1,
                type = "group",
                name = L["Options"],
                args = {
                    intro = {
                        order = 0,
                        type = "description",
                        name = addonNotes,
                    },
                    group2 = {
                        order = 20,
                        type = "group",
                        name = L["Minimap Button Settings"],
                        inline = true,
                        args = {
                            minimapButton = {
                                order = 22,
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
            profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(BGH.db)
        }
    }, {"bgh"})

    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName)
end
