
local addOnName = ...
local addOnVersion = GetAddOnMetadata(addOnName, "Version") or "0.0.1"

local clientVersionString = GetBuildInfo()
local clientBuildMajor = string.byte(clientVersionString, 1)
-- load only on classic/tbc/wotlk
if (clientBuildMajor < 49 or clientBuildMajor > 51 or string.byte(clientVersionString, 2) ~= 46) then
    return
end

assert(LibStub, "TacoTip requires LibStub")
assert(LibStub:GetLibrary("LibClassicInspector", true), "TacoTip requires LibClassicInspector")
assert(LibStub:GetLibrary("LibDetours-1.0", true), "TacoTip requires LibDetours-1.0")
--assert(LibStub:GetLibrary("LibClassicGearScore", true), "TacoTip requires LibClassicGearScore")

_G[addOnName] = {}

local isPawnLoaded = PawnClassicLastUpdatedVersion and PawnClassicLastUpdatedVersion >= 2.0538

local Detours = LibStub("LibDetours-1.0")
local CI = LibStub("LibClassicInspector")

local GearScore = TT_GS
local L = TACOTIP_LOCALE
local TT = _G[addOnName]

local HORDE_ICON = "|TInterface\\TargetingFrame\\UI-PVP-HORDE:16:16:-2:0:64:64:0:38:0:38|t"
local ALLIANCE_ICON = "|TInterface\\TargetingFrame\\UI-PVP-ALLIANCE:16:16:-2:0:64:64:0:38:0:38|t"
local PVP_FLAG_ICON = "|TInterface\\GossipFrame\\BattleMasterGossipIcon:0|t"
local ACHIEVEMENT_ICON = "|TInterface\\AchievementFrame\\UI-Achievement-TinyShield:18:18:0:0:20:20:0:12.5:0:12.5|t"

TT.defaults = {
    profile = {
        color_class = true,
        show_titles = true,
        show_guild_name = true,
        show_guild_rank = false,
        show_talents = true,
        show_gs_player = true,
        show_gs_character = true,
        show_gs_items = false,
        show_gs_items_hs = false,
        show_avg_ilvl = true,
        hide_in_combat = false,
        show_item_level = true,
        tip_style = 2,
        show_target = true,
        show_pawn_player = false,
        show_team = false,
        show_pvp_icon = false,
        guild_rank_alt_style = false,
        show_hp_bar = true,
        show_power_bar = false,
        instant_fade = false,
        anchor_position = "1",
        custom_pos = false,
        anchor_mouse = false,
        anchor_mouse_world = true,
        anchor_mouse_spells = false,
        inspect_gs_offset_x = 0,
        inspect_gs_offset_y = 0,
        inspect_ilvl_offset_x = 0,
        inspect_ilvl_offset_y = 0,
        character_gs_offset_x = 0,
        character_gs_offset_y = 0,
        character_ilvl_offset_x = 0,
        character_ilvl_offset_y = 0,
        unlock_info_position = false,
        show_achievement_points = false,
        anchor_mouse_position = "BOTTOMLEFT",
        anchor_mouse_offset_x = 0,
        anchor_mouse_offset_y = 0
    }
}

TT.options = {
    name = addOnName .. " v" .. addOnVersion,
    type = "group",
    inline = true,
    order = 1,
    args = {
        description = {
            name = L["TEXT_OPT_DESC"],
            type = "description",
            order = 1
        },
        unitTooltips = {
            name = L["Unit Tooltips"],
            type = "group",
            order = 2,
            inline = true,
            args = {
                useClassColors = {
                    name = L["Class Color"],
                    desc  = L["Color class names in tooltips"],
                    type = "toggle",
                    order = 1,
                    get = function()
                        return TT.db.profile.color_class
                    end,
                    set = function(info, value)
                        TT.db.profile.color_class = value
                        TT.exampleTooltip:Refresh()
                    end
                },
                showTitles = {
                    name = L["Title"],
                    desc  = L["Show player's title in tooltips"],
                    type = "toggle",
                    order = 2,
                    get = function()
                        return TT.db.profile.show_titles
                    end,
                    set = function(info, value)
                        TT.db.profile.show_titles = value
                        TT.exampleTooltip:Refresh()
                    end
                },
                showGuildNames = {
                    name = L["Guild Name"],
                    desc  = L["Show guild name in tooltips"],
                    type = "toggle",
                    order = 3,
                    get = function()
                        return TT.db.profile.show_guild_name
                    end,
                    set = function(info, value)
                        TT.db.profile.show_guild_name = value
                        TT.exampleTooltip:Refresh()
                    end
                },
                showGuildRanks = {
                    name = L["Guild Rank"],
                    desc  = L["Show guild rank in tooltips"],
                    type = "toggle",
                    order = 4,
                    get = function()
                        return TT.db.profile.show_guild_rank
                    end,
                    set = function(info, value)
                        TT.db.profile.show_guild_rank = value
                        TT.exampleTooltip:Refresh()
                    end,
                    hidden = function()
                        return not TT.db.profile.show_guild_name
                    end
                },
                guildRankStyle = {
                    name = L["Guild Rank Style"],
                    desc  = L["Show guild rank in tooltips"],
                    type = "select",
                    order = 5,
                    values = function()
                        return {
                            ["one"] = L["RANK_OF_GUILD"],
                            ["two"] = L["GUILD_RANK"]
                        }
                    end,
                    get = function()
                        return TT.db.profile.guild_rank_alt_style
                    end,
                    set = function(info, value)
                        TT.db.profile.guild_rank_alt_style = value
                        TT.exampleTooltip:Refresh()
                    end,
                    hidden = function()
                        return (not TT.db.profile.show_guild_rank) or (not TT.db.profile.show_guild_name)
                    end
                },
                showTalents = {
                    name = L["Talents"],
                    desc  = L["Show talents and specialization in tooltips"],
                    type = "toggle",
                    order = 6,
                    get = function()
                        return TT.db.profile.show_talents
                    end,
                    set = function(info, value)
                        TT.db.profile.show_talents = value
                        TT.exampleTooltip:Refresh()
                    end
                },
                showTarget = {
                    name = L["Target"],
                    desc  = L["Show unit's target in tooltips"],
                    type = "toggle",
                    order = 7,
                    get = function()
                        return TT.db.profile.show_target
                    end,
                    set = function(info, value)
                        TT.db.profile.show_target = value
                        TT.exampleTooltip:Refresh()
                    end
                },
                gearScorePlayer = {
                    name = L["GearScore"],
                    desc  = L["Show player's GearScore in tooltips"],
                    type = "toggle",
                    order = 8,
                    get = function()
                        return TT.db.profile.show_gs_player
                    end,
                    set = function(info, value)
                        TT.db.profile.show_gs_player = value
                        TT.exampleTooltip:Refresh()
                    end
                },
                pawnScorePlayer = {
                    name = function()
                        if isPawnLoaded then
                            return L["PawnScore"]
                        else
                            return L["PawnScore"].." ("..L["requires Pawn"]..")"
                        end
                    end,
                    desc  = L["Show player's GearScore in tooltips"],
                    type = "toggle",
                    order = 9,
                    get = function()
                        return TT.db.profile.show_pawn_player
                    end,
                    set = function(info, value)
                        TT.db.profile.show_pawn_player = value
                        TT.exampleTooltip:Refresh()
                    end,
                    disabled = function()
                        return not isPawnLoaded
                    end
                },
                showTeam = {
                    name = L["Faction Icon"],
                    desc  = L["Show player's faction icon (Horde/Alliance) in tooltips"],
                    type = "toggle",
                    order = 10,
                    get = function()
                        return TT.db.profile.show_team
                    end,
                    set = function(info, value)
                        TT.db.profile.show_team = value
                        TT.exampleTooltip:Refresh()
                    end
                },
                showPVPIcon = {
                    name = L["PVP Icon"],
                    desc  = L["Show player's pvp flag status as icon instead of text"],
                    type = "toggle",
                    order = 11,
                    get = function()
                        return TT.db.profile.show_pvp_icon
                    end,
                    set = function(info, value)
                        TT.db.profile.show_pvp_icon = value
                        TT.exampleTooltip:Refresh()
                    end
                },
                showHealthBar = {
                    name = L["Health Bar"],
                    desc  = L["Show unit's health bar under tooltip"],
                    type = "toggle",
                    order = 12,
                    get = function()
                        return TT.db.profile.show_hp_bar
                    end,
                    set = function(info, value)
                        TT.db.profile.show_hp_bar = value
                        TT.exampleTooltip:Refresh()
                    end
                },
                showPowerBar = {
                    name = L["Power Bar"],
                    desc  = L["Show unit's power bar under tooltip"],
                    type = "toggle",
                    order = 13,
                    get = function()
                        return TT.db.profile.show_power_bar
                    end,
                    set = function(info, value)
                        TT.db.profile.show_power_bar = value
                        TT.exampleTooltip:Refresh()
                    end
                },
                showAchievementPoints = {
                    name = L["Achievement Points"],
                    desc  = L["Show total achievement points in tooltips"],
                    type = "toggle",
                    order = 14,
                    get = function()
                        return TT.db.profile.show_achievement_points
                    end,
                    set = function(info, value)
                        TT.db.profile.show_achievement_points = value
                        TT.exampleTooltip:Refresh()
                    end
                },
                styleChoice = {
                    name = L["Tooltip Style"],
                    type = "select",
                    order = 15,
                    width = "double",
                    values = function()
                        return {
                            [1] = L["Always FULL"],
                            [2] = L["Default COMPACT, hold SHIFT for FULL"],
                            [3] = L["Always COMPACT"],
                            [4] = L["Default MINI, hold SHIFT for FULL"],
                            [5] = L["Always MINI"]
                        }
                    end,
                    get = function()
                        return TT.db.profile.tip_style
                    end,
                    set = function(info, value)
                        TT.db.profile.tip_style = value
                        TT.exampleTooltip:Refresh()
                    end
                },
            }
        },
        characterFrame = {
            name = L["Character Frame"],
            type = "group",
            order = 3,
            inline = true,
            args = {
                gearScoreCharacter = {
                    name = L["GearScore"],
                    desc  = L["Show GearScore in character frame"],
                    type = "toggle",
                    order = 1,
                    get = function()
                        return TT.db.profile.show_gs_character
                    end,
                    set = function(info, value)
                        TT.db.profile.show_gs_character = value
                        if (PaperDollFrame and PaperDollFrame:IsShown()) then
                            TT:RefreshCharacterFrame()
                        end
                        if (InspectFrame and InspectFrame:IsShown()) then
                            TT:RefreshInspectFrame()
                        end
                    end
                },
                averageItemLevel = {
                    name = L["Average iLvl"],
                    desc  = L["Show Average Item Level in character frame"],
                    type = "toggle",
                    order = 2,
                    get = function()
                        return TT.db.profile.show_avg_ilvl
                    end,
                    set = function(info, value)
                        TT.db.profile.show_avg_ilvl = value
                        if (PaperDollFrame and PaperDollFrame:IsShown()) then
                            TT:RefreshCharacterFrame()
                        end
                        if (InspectFrame and InspectFrame:IsShown()) then
                            TT:RefreshInspectFrame()
                        end
                    end
                },
                lockCharacterInfoPosition = {
                    name = L["Lock Position"],
                    desc  = L["Lock GearScore and Average Item Level positions in character frame"],
                    type = "toggle",
                    order = 3,
                    get = function()
                        return not TT.db.profile.unlock_info_position
                    end,
                    set = function(info, value)
                        TT.db.profile.unlock_info_position = not value
                        if (PaperDollFrame and PaperDollFrame:IsShown()) then
                            TT:RefreshCharacterFrame()
                        end
                        if (InspectFrame and InspectFrame:IsShown()) then
                            TT:RefreshInspectFrame()
                        end
                    end
                },
            }
        },
        anchorFrame = {
            name = L["Tooltip Position"],
            type = "group",
            order = 4,
            inline = true,
            args = {
                anchorPosition = {
                    name = "Anchor To",
                    desc  = "",
                    type = "select",
                    order = 1,
                    values = function()
                        return {
                            ["1"] = L["Default"],
                            ["2"] = L["Anchor to Mouse"],
                            ["3"] = L["Custom Tooltip Position"],
                        }
                    end,
                    get = function()
                        return TT.db.profile.anchor_position
                    end,
                    set = function(info, value)
                        TT.db.profile.anchor_position = value

                        -- Anchor to Mouse
                        if value == "2" then
                            TT.db.profile.anchor_mouse = true
                            if (TacoTipDragButton) then
                                TacoTipDragButton:_Disable()
                            end
                            TT.db.profile.custom_pos = nil
                            TT.db.profile.custom_anchor = nil

                        -- Custom Tooltip Position
                        elseif value == "3" then
                            TT.db.profile.anchor_mouse = false
                            TacoTip_CustomPosEnable(false)

                        -- Default
                        else
                            if (TacoTipDragButton) then
                                TacoTipDragButton:_Disable()
                            end
                            TT.db.profile.custom_pos = nil
                            TT.db.profile.custom_anchor = nil
                        end
                    end
                },
                anchorMouseWorld = {
                    name = L["Only in WorldFrame"],
                    desc  = L["Anchor to mouse only in WorldFrame\nSkips raid / party frames"],
                    type = "toggle",
                    order = 2,
                    get = function()
                        return TT.db.profile.anchor_mouse_world
                    end,
                    set = function(info, value)
                        TT.db.profile.anchor_mouse_world = value
                    end,
                    hidden = function()
                        return TT.db.profile.anchor_position ~= "2"
                    end
                },
                moverButton = {
                    name = L["Mover"],
                    type = "execute",
                    order = 3,
                    func = function()
                        TacoTip_CustomPosEnable(true)
                    end,
                    hidden = function()
                        return TT.db.profile.anchor_position ~= "3"
                    end
                },
                anchorMouseSpells = {
                    name = L["Anchor Spells to Mouse"],
                    desc  = L["Anchor spell tooltips to mouse cursor"],
                    type = "toggle",
                    order = 4,
                    get = function()
                        return TT.db.profile.anchor_mouse_spells
                    end,
                    set = function(info, value)
                        TT.db.profile.anchor_mouse_spells = value
                    end
                },
                anchorMousePosition = {
                    name = L["Attachment Point"],
                    desc  = "",
                    type = "select",
                    order = 5,
                    values = function()
                        -- Labels are opposite of the value because it's relative to the tooltip frame instead of the anchor
                        return {
                            ["BOTTOMLEFT"] = L["Top Right"],
                            ["LEFT"] = L["Right"],
                            ["TOPLEFT"] = L["Bottom Right"],
                            ["TOP"] = L["Bottom"],
                            ["TOPRIGHT"] = L["Bottom Left"],
                            ["RIGHT"] = L["Left"],
                            ["BOTTOMRIGHT"] = L["Top Left"],
                            ["BOTTOM"] = L["Top"]
                        }
                    end,
                    get = function()
                        return TT.db.profile.anchor_mouse_position
                    end,
                    set = function(info, value)
                        TT.db.profile.anchor_mouse_position = value
                    end,
                    hidden = function()
                        return TT.db.profile.anchor_position ~= "2"
                    end
                },
                anchorMouseOffsetX = {
                    name = L["X Offset"],
                    desc  = "",
                    type = "range",
                    order = 6,
                    min = -100,
                    max = 100,
                    step = 1,
                    get = function()
                        return TT.db.profile.anchor_mouse_offset_x
                    end,
                    set = function(info, value)
                        TT.db.profile.anchor_mouse_offset_x = value
                    end,
                    hidden = function()
                        return TT.db.profile.anchor_position ~= "2"
                    end
                },
                anchorMouseOffsetY = {
                    name = L["Y Offset"],
                    desc  = "",
                    type = "range",
                    order = 6,
                    min = -100,
                    max = 100,
                    step = 1,
                    get = function()
                        return TT.db.profile.anchor_mouse_offset_y
                    end,
                    set = function(info, value)
                        TT.db.profile.anchor_mouse_offset_y = value
                    end,
                    hidden = function()
                        return TT.db.profile.anchor_position ~= "2"
                    end
                },
            }
        },
        extraFrame = {
            name = L["Extra"],
            type = "group",
            order = 5,
            inline = true,
            args = {
                showItemLevel = {
                    name = L["Show Item Level"],
                    desc  = L["Display item level in the tooltip for certain items."],
                    type = "toggle",
                    order = 1,
                    get = function()
                        return TT.db.profile.show_item_level
                    end,
                    set = function(info, value)
                        TT.db.profile.show_item_level = value
                    end
                },
                gearScoreItems = {
                    name = L["Show Item GearScore"],
                    desc  = L["Show GearScore in item tooltips"],
                    type = "toggle",
                    order = 2,
                    get = function()
                        return TT.db.profile.show_gs_items
                    end,
                    set = function(info, value)
                        TT.db.profile.show_gs_items = value
                    end
                },
                uberTips = {
                    name = L["Enhanced Tooltips"],
                    desc  = L["TEXT_OPT_UBERTIPS"],
                    type = "toggle",
                    order = 3,
                    get = function()
                        return GetCVar("UberTooltips") == "1"
                    end,
                    set = function(info, value)
                        if value == true then
                            SetCVar("UberTooltips", "1")
                        else
                            SetCVar("UberTooltips", "0")
                        end
                    end
                },
                hideInCombat = {
                    name = L["Disable In Combat"],
                    desc  = L["Disable gearscore & talents in combat"],
                    type = "toggle",
                    order = 4,
                    get = function()
                        return TT.db.profile.hide_in_combat
                    end,
                    set = function(info, value)
                        TT.db.profile.hide_in_combat = value
                    end
                },
                chatClassColors = {
                    name = L["Chat Class Colors"],
                    desc  = L["Color names by class in chat windows"],
                    type = "toggle",
                    order = 5,
                    get = function()
                        return GetCVar("chatClassColorOverride") == "1"
                    end,
                    set = function(info, value)
                        if value == true then
                            SetCVar("chatClassColorOverride", "1")
                        else
                            SetCVar("chatClassColorOverride", "0")
                        end
                    end
                },
                instantFade = {
                    name = L["Instant Fade"],
                    desc  = L["Fade out unit tooltips instantly"],
                    type = "toggle",
                    order = 6,
                    get = function()
                        return TT.db.profile.instant_fade
                    end,
                    set = function(info, value)
                        TT.db.profile.instant_fade = value
                        if (value) then
                            TT.frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
                            Detours:DetourHook(TT, GameTooltip, "FadeOut", function(self)
                                self:Hide()
                            end)
                        else
                            TT.frame:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
                            Detours:DetourUnhook(TT, GameTooltip, "FadeOut")
                        end
                    end
                }
            }
        }
    }
}

-- Example Tooltip Class
TT.exampleTooltip = {}

-- Create the Example Tooltip
function TT.exampleTooltip:Create()
    if not self.tooltip then
        self.tooltip = CreateFrame("GameTooltip", "TacoTipOptExampleTooltip", TT.optionsFrame, "GameTooltipTemplate")
        self.tooltipHealthBar = CreateFrame("StatusBar", "TacoTipOptExampleTooltipStatusBar", self.tooltip)
        self.tooltipHealthBar:SetSize(0, 8)
        self.tooltipHealthBar:SetPoint("TOPLEFT", self.tooltip, "BOTTOMLEFT", 2, -1)
        self.tooltipHealthBar:SetPoint("TOPRIGHT", self.tooltip, "BOTTOMRIGHT", -2, -1)
        self.tooltipHealthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
        self.tooltipHealthBar:SetStatusBarColor(0, 1, 0)
        self.tooltipPowerBar = CreateFrame("StatusBar", "TacoTipOptExampleTooltipPowerBar", self.tooltip)
        self.tooltipPowerBar:SetSize(0, 8)
        self.tooltipPowerBar:SetPoint("TOPLEFT", self.tooltip, "BOTTOMLEFT", 2, -9)
        self.tooltipPowerBar:SetPoint("TOPRIGHT", self.tooltip, "BOTTOMRIGHT", -2, -9)
        self.tooltipPowerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
        self.tooltipPowerBar:SetStatusBarColor(1, 1, 0)
    end
end

-- Refresh the Example Tooltip content
function TT.exampleTooltip:Refresh()
    self.tooltip:ClearLines()

    local classc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)["ROGUE"]
    local name_r = TT.db.profile.color_class and classc and classc.r or 0
    local name_g = TT.db.profile.color_class and classc and classc.g or 0.6
    local name_b = TT.db.profile.color_class and classc and classc.b or 0.1
    local title = TT.db.profile.show_titles and L[" the Kingslayer"] or ""

    self.tooltip:AddLine(string.format("|cFF%02x%02x%02xKebabstorm%s %s%s|r", name_r*255, name_g*255, name_b*255, title, (TT.db.profile.show_team and (HORDE_ICON.." ") or ""), (TT.db.profile.show_pvp_icon and PVP_FLAG_ICON or "")))

    if (TT.db.profile.show_guild_name) then
        if (TT.db.profile.show_guild_rank) then
            if (TT.db.profile.guild_rank_alt_style) then
                self.tooltip:AddLine("|cFF40FB40<Drunken Wrath> (Officer)|r")
            else
                self.tooltip:AddLine(string.format("|cFF40FB40"..L["FORMAT_GUILD_RANK_1"].."|r", "Officer", "Drunken Wrath"))
            end
        else
            self.tooltip:AddLine("|cFF40FB40<Drunken Wrath>|r")
        end
    end

    if (TT.db.profile.color_class) then
        self.tooltip:AddLine(string.format("%s 80 %s |cFF%02x%02x%02x%s|r (%s)", L["Level"], L["Undead"], name_r*255, name_g*255, name_b*255, LOCALIZED_CLASS_NAMES_MALE["ROGUE"], L["Player"]), 1, 1, 1)
    else
        self.tooltip:AddLine(string.format("%s 80 %s %s (%s)", L["Level"], L["Undead"], LOCALIZED_CLASS_NAMES_MALE["ROGUE"], L["Player"]), 1, 1, 1)
    end

    if (not TT.db.profile.show_pvp_icon) then
        self.tooltip:AddLine("PvP", 1, 1, 1)
    end

    local wide_style = (TT.db.profile.tip_style == 1 or ((TT.db.profile.tip_style == 2 or TT.db.profile.tip_style == 4) and IsModifierKeyDown()))
    local mini_style = (not wide_style and (TT.db.profile.tip_style == 4 or TT.db.profile.tip_style == 5))

    if (TT.db.profile.show_target) then
        if (wide_style) then
            self.tooltip:AddDoubleLine(L["Target"]..":", L["None"], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
        else
            self.tooltip:AddLine(L["Target"]..": |cFF808080"..L["None"].."|r")
        end
    end

    if (TT.db.profile.show_talents) then
        if (wide_style) then
            self.tooltip:AddDoubleLine(L["Talents"]..":", CI:GetSpecializationName("ROGUE", 1, true).." [51/18/2]", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
            self.tooltip:AddDoubleLine(" ", CI:GetSpecializationName("ROGUE", 3, true).." [14/3/54]", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
        else
            self.tooltip:AddLine(L["Talents"]..":|cFFFFFFFF "..CI:GetSpecializationName("ROGUE", 1, true).." [51/18/2]")
        end
    end

    local miniText = ""
    if (TT.db.profile.show_gs_player) then
        local gs_r, gs_b, gs_g = GearScore:GetQuality(6054)
        if (wide_style) then
            self.tooltip:AddDoubleLine("GearScore: 6054", "(iLvl: 264)", gs_r, gs_g, gs_b, gs_r, gs_g, gs_b)
        elseif (mini_style) then
            miniText = string.format("|cFF%02x%02x%02xGS: 6054  L: 264|r  ", gs_r*255, gs_g*255, gs_b*255)
        else
            self.tooltip:AddLine("GearScore: 6054", gs_r, gs_g, gs_b)
        end
    end

    if (isPawnLoaded and TT.db.profile.show_pawn_player) then
        local specColor = PawnGetScaleColor("\"Classic\":ROGUE1", true) or "|cffffffff"
        if (wide_style) then
            self.tooltip:AddDoubleLine(string.format("Pawn: %s1234.56|r", specColor), string.format("%s(%s)|r", specColor, CI:GetSpecializationName("ROGUE", 1, true)), 1, 1, 1, 1, 1, 1)
        elseif (mini_style) then
            miniText = miniText .. string.format("P: %s1234.5|r", specColor)
        else
            self.tooltip:AddLine(string.format("Pawn: %s1234.56 (%s)|r", specColor, CI:GetSpecializationName("ROGUE", 1, true)), 1, 1, 1)
        end
    end

    if (CI:IsWotlk() and TT.db.profile.show_achievement_points) then
        self.tooltip:AddLine(ACHIEVEMENT_ICON.." ".."|cFFFFFFFF1337|r ")
    end

    if (miniText ~= "") then
        self.tooltip:AddLine(miniText, 1, 1, 1)
    end

    self.tooltip:Show()

    if (TT.db.profile.show_hp_bar) then
        self.tooltipHealthBar:Show()
        self.tooltipPowerBar:SetPoint("TOPLEFT", self.tooltip, "BOTTOMLEFT", 2, -9)
        self.tooltipPowerBar:SetPoint("TOPRIGHT", self.tooltip, "BOTTOMRIGHT", -2, -9)
    else
        self.tooltipHealthBar:Hide()
        self.tooltipPowerBar:SetPoint("TOPLEFT", self.tooltip, "BOTTOMLEFT", 2, -1)
        self.tooltipPowerBar:SetPoint("TOPRIGHT", self.tooltip, "BOTTOMRIGHT", -2, -1)
    end

    if (TT.db.profile.show_power_bar) then
        self.tooltipPowerBar:Show()
    else
        self.tooltipPowerBar:Hide()
    end
end

-- Show the Example Tooltip
function TT.exampleTooltip:Show()
    if not self.tooltip then
        self:Create()
    end

    self.tooltip:SetScale(1)
    self.tooltip:SetOwner(TT.optionsFrame, "ANCHOR_NONE")
    self.tooltip:SetPoint("TOPLEFT", TT.optionsFrame, "TOPRIGHT", 29, 0)

    self:Refresh()
end

-- Hide the Example Tooltip
function TT.exampleTooltip:Hide()
    self.tooltip:Hide()
end

SLASH_TACOTIP1 = "/tacotip";
SLASH_TACOTIP2 = "/tooltip";
SLASH_TACOTIP3 = "/tip";
SLASH_TACOTIP4 = "/tt";
SLASH_TACOTIP5 = "/gs";
SLASH_TACOTIP6 = "/gearscore";
SlashCmdList["TACOTIP"] = function(msg)
    local cmd = strlower(msg)
    if (cmd == "custom") then
        TacoTip_CustomPosEnable(true)
    elseif (cmd == "default") then
        if (not TT.db.profile.custom_pos) then
            print("|cff59f0dcTacoTip:|r "..L["Custom tooltip position disabled."])
        end
        if (TacoTipDragButton) then
            TacoTipDragButton:_Disable()
        end
        TT.db.profile.custom_pos = nil
        TT.db.profile.custom_anchor = nil
    elseif (cmd == "reset") then
        resetCfg()
        if (frame:IsShown()) then
            frame:Refresh()
        end
        print("|cff59f0dcTacoTip:|r "..L["Configuration has been reset to default."])
    elseif (cmd == "save") then
        if (TacoTipDragButton and TacoTipDragButton:IsShown()) then
            TacoTipDragButton:_Save()
        end
    elseif (strfind(cmd, "anchor")) then
        if (strfind(cmd, "topleft")) then
            TT.db.profile.custom_anchor = "TOPLEFT"
            print("|cff59f0dcTacoTip:|r "..L["Custom position anchor set"]..": 'TOPLEFT'")
        elseif (strfind(cmd, "topright")) then
            TT.db.profile.custom_anchor = "TOPRIGHT"
            print("|cff59f0dcTacoTip:|r "..L["Custom position anchor set"]..": 'TOPRIGHT'")
        elseif (strfind(cmd, "bottomleft")) then
            TT.db.profile.custom_anchor = "BOTTOMLEFT"
            print("|cff59f0dcTacoTip:|r "..L["Custom position anchor set"]..": 'BOTTOMLEFT'")
        elseif (strfind(cmd, "bottomright")) then
            TT.db.profile.custom_anchor = "BOTTOMRIGHT"
            print("|cff59f0dcTacoTip:|r "..L["Custom position anchor set"]..": 'BOTTOMRIGHT'")
        elseif (strfind(cmd, "center")) then
            TT.db.profile.custom_anchor = "CENTER"
            print("|cff59f0dcTacoTip:|r "..L["Custom position anchor set"]..": 'CENTER'")
        else
            print("|cff59f0dcTacoTip:|r "..L["TEXT_HELP_ANCHOR"])
        end
    else
        InterfaceOptionsFrame_OpenToCategory(addOnName)
        InterfaceOptionsFrame_OpenToCategory(addOnName)
    end
end
