
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

local isPawnLoaded = PawnClassicLastUpdatedVersion and PawnClassicLastUpdatedVersion >= 2.0538

local Detours = LibStub("LibDetours-1.0")
local GearScore = TT_GS

local HORDE_ICON = "|TInterface\\TargetingFrame\\UI-PVP-HORDE:16:16:-2:0:64:64:0:38:0:38|t"
local ALLIANCE_ICON = "|TInterface\\TargetingFrame\\UI-PVP-ALLIANCE:16:16:-2:0:64:64:0:38:0:38|t"
local PVP_FLAG_ICON = "|TInterface\\GossipFrame\\BattleMasterGossipIcon:0|t"

local function resetCfg()
    if (TacoTipDragButton) then
        TacoTipDragButton:_Disable()
    end
    if (TacoTipConfig and TacoTipConfig.instant_fade) then
        _G[addOnName].frame:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
        Detours:DetourUnhook(_G[addOnName], GameTooltip, "FadeOut")
    end
    TacoTipConfig = {
        color_class = true,
        show_titles = true,
        show_guild_name = true,
        show_guild_rank = false,
        show_talents = true,
        show_gs_player = true,
        show_gs_character = true,
        show_gs_items = false,
        show_avg_ilvl = true,
        hide_in_combat = false,
        show_item_level = true,
        tip_style = 2,
        show_target = false,
        show_pawn_player = false,
        show_team = false,
        show_pvp_icon = false,
        guild_rank_alt_style = false,
        show_hp_bar = true,
        show_power_bar = false,
        instant_fade = false
        --custom_pos = nil,
        --custom_anchor = nil,
    }
    --SetCVar("showItemLevel", "1")
end

if not TacoTipConfig then
    resetCfg()
end

-- main frame
local frame = CreateFrame("Frame","TacoTipOptions")
frame.name = addOnName
InterfaceOptions_AddCategory(frame)
frame:Hide()

frame:SetScript("OnShow", function(frame)
    local options = {}
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(addOnName .. " v" .. addOnVersion)

    local description = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    description:SetText("Better player tooltips - class colors, talents/specialization,\n                     gearscore, guild ranks")

    local function newCheckbox(name, label, description, onClick)
        local check = CreateFrame("CheckButton", "TacoTipOptCheckBox" .. name, frame, "InterfaceOptionsCheckButtonTemplate")
        check:SetScript("OnClick", function(self)
            local tick = self:GetChecked()
            onClick(self, tick and true or false)
        end)
        check.SetDisabled = function(self, disable)
            if disable then
                self:Disable()
                _G[self:GetName() .. 'Text']:SetFontObject('GameFontDisable')
            else
                self:Enable()
                _G[self:GetName() .. 'Text']:SetFontObject('GameFontHighlight')
            end
        end
        check.label = _G[check:GetName() .. "Text"]
        check.label:SetText(label)
        if (description) then
            check.tooltipText = label
            check.tooltipRequirement = description
        end
        return check
    end

    local function newDropDown(name, values, callback)
        local dropDown = CreateFrame("Frame", "TacoTipOptDropDown" .. name, frame, "UIDropDownMenuTemplate")
        UIDropDownMenu_Initialize(dropDown, function(frame, level, menuList)
            local info = UIDropDownMenu_CreateInfo()
            info.func = function(self)
                    UIDropDownMenu_SetSelectedValue(frame, self.value)
                    callback(self.value)
            end
            for i,selection in ipairs(values) do
                local text, desc = unpack(selection)
                info.text, info.checked, info.value = text, false, i
                if(desc) then
                    info.tooltipTitle = text
                    info.tooltipText = desc
                    info.tooltipOnButton = 1
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        dropDown.SetValue = function(self, value)
            self.selectedValue = value
            UIDropDownMenu_SetText(self, values[value][1])
        end
        return dropDown
    end

    local function newRadioButton(name, label, description, onClick)
        local check = CreateFrame("CheckButton", "TacoTipOptRadioButton" .. name, frame, "InterfaceOptionsCheckButtonTemplate, UIRadioButtonTemplate")
        check:SetScript("OnClick", function(self)
            if(not self:GetChecked()) then
                self:SetChecked(true)
            end
            onClick(self, true)
        end)
        check.SetDisabled = function(self, disable)
            if disable then
                self:Disable()
                _G[self:GetName() .. 'Text']:SetFontObject('GameFontDisable')
            else
                self:Enable()
                _G[self:GetName() .. 'Text']:SetFontObject('GameFontHighlight')
            end
        end
        check.label = _G[check:GetName() .. "Text"]
        check.label:SetText(label)
        if (description) then
            check.tooltipText = label
            check.tooltipRequirement = description
        end
        return check
    end


    options.exampleTooltip = CreateFrame("GameTooltip", "TacoTipOptExampleTooltip", frame, "GameTooltipTemplate")
    options.exampleTooltipHealthBar = CreateFrame("StatusBar", "TacoTipOptExampleTooltipStatusBar", options.exampleTooltip)
    options.exampleTooltipHealthBar:SetSize(0, 8)
    options.exampleTooltipHealthBar:SetPoint("TOPLEFT", options.exampleTooltip, "BOTTOMLEFT", 2, -1)
    options.exampleTooltipHealthBar:SetPoint("TOPRIGHT", options.exampleTooltip, "BOTTOMRIGHT", -2, -1)
    options.exampleTooltipHealthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
    options.exampleTooltipHealthBar:SetStatusBarColor(0, 1, 0)
    options.exampleTooltipPowerBar = CreateFrame("StatusBar", "TacoTipOptExampleTooltipPowerBar", options.exampleTooltip)
    options.exampleTooltipPowerBar:SetSize(0, 8)
    options.exampleTooltipPowerBar:SetPoint("TOPLEFT", options.exampleTooltip, "BOTTOMLEFT", 2, -9)
    options.exampleTooltipPowerBar:SetPoint("TOPRIGHT", options.exampleTooltip, "BOTTOMRIGHT", -2, -9)
    options.exampleTooltipPowerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
    options.exampleTooltipPowerBar:SetStatusBarColor(1, 1, 0)
    local function showExampleTooltip()
        options.exampleTooltip:SetOwner(frame, "ANCHOR_NONE")
        options.exampleTooltip:SetPoint("TOPLEFT", description, "TOPLEFT", 340, 0)
        local classc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)["ROGUE"]
        local name_r = TacoTipConfig.color_class and classc and classc.r or 0
        local name_g = TacoTipConfig.color_class and classc and classc.g or 0.6
        local name_b = TacoTipConfig.color_class and classc and classc.b or 0.1
        local title = TacoTipConfig.show_titles and " the Kingslayer" or ""
        options.exampleTooltip:AddLine(string.format("|cFF%02x%02x%02xKebabstorm%s %s%s|r", name_r*255, name_g*255, name_b*255, title, (TacoTipConfig.show_team and (HORDE_ICON.." ") or ""), (TacoTipConfig.show_pvp_icon and PVP_FLAG_ICON or "")))
        if (TacoTipConfig.show_guild_name) then
            if (TacoTipConfig.show_guild_rank) then
                if (TacoTipConfig.guild_rank_alt_style) then
                    options.exampleTooltip:AddLine("|cFF40FB40<Drunken Wrath> (Officer)|r")
                else
                    options.exampleTooltip:AddLine("|cFF40FB40Officer of <Drunken Wrath>|r")
                end
            else
                options.exampleTooltip:AddLine("|cFF40FB40<Drunken Wrath>|r")
            end
        end
        if (TacoTipConfig.color_class) then
            options.exampleTooltip:AddLine(string.format("Level 80 Undead |cFF%02x%02x%02xRogue|r (Player)", name_r*255, name_g*255, name_b*255), 1, 1, 1)
        else
            options.exampleTooltip:AddLine("Level 80 Undead Rogue (Player)", 1, 1, 1)
        end

        if (not TacoTipConfig.show_pvp_icon) then
            options.exampleTooltip:AddLine("PvP", 1, 1, 1)
        end

        local wide_style = (TacoTipConfig.tip_style == 1 or ((TacoTipConfig.tip_style == 2 or TacoTipConfig.tip_style == 4) and IsModifierKeyDown()))
        local mini_style = (not wide_style and (TacoTipConfig.tip_style == 4 or TacoTipConfig.tip_style == 5))

        if (TacoTipConfig.show_target) then
            if (wide_style) then
                options.exampleTooltip:AddDoubleLine("Target:", "None", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
            else
                options.exampleTooltip:AddLine("Target: |cFF808080None|r")
            end
        end
        if (TacoTipConfig.show_talents) then
            if (wide_style) then
                options.exampleTooltip:AddDoubleLine("Talents:", "Assassination [51/18/2]", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
                options.exampleTooltip:AddDoubleLine(" ", "Subtlety [14/3/54]", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
            else
                options.exampleTooltip:AddLine("Talents:|cFFFFFFFF Assassination [51/18/2]")
            end
        end
        local miniText = ""
        if (TacoTipConfig.show_gs_player) then
            local gs_r, gs_b, gs_g = GearScore:GetQuality(6054)
            if (wide_style) then
                options.exampleTooltip:AddDoubleLine("GearScore: 6054", "(iLvl: 264)", gs_r, gs_g, gs_b, gs_r, gs_g, gs_b)
            elseif (mini_style) then
                miniText = string.format("|cFF%02x%02x%02xGS: 6054  L: 264|r  ", gs_r*255, gs_g*255, gs_b*255)
            else
                options.exampleTooltip:AddLine("GearScore: 6054", gs_r, gs_g, gs_b)
            end
        end
        if (isPawnLoaded and TacoTipConfig.show_pawn_player) then
            local specColor = PawnGetScaleColor("\"Classic\":ROGUE1", true) or "|cffffffff"
            if (wide_style) then
                options.exampleTooltip:AddDoubleLine(string.format("Pawn: %s1234.56|r", specColor), string.format("%s(Assassination)|r", specColor), 1, 1, 1, 1, 1, 1)
            elseif (mini_style) then
                miniText = miniText .. string.format("P: %s1234.5|r", specColor)
            else
                options.exampleTooltip:AddLine(string.format("Pawn: %s1234.56 (Assassination)|r", specColor), 1, 1, 1)
            end
        end
        if (miniText ~= "") then
            options.exampleTooltip:AddLine(miniText, 1, 1, 1)
        end
        options.exampleTooltip:Show()
        if (TacoTipConfig.show_hp_bar) then
            options.exampleTooltipHealthBar:Show()
            options.exampleTooltipPowerBar:SetPoint("TOPLEFT", options.exampleTooltip, "BOTTOMLEFT", 2, -9)
            options.exampleTooltipPowerBar:SetPoint("TOPRIGHT", options.exampleTooltip, "BOTTOMRIGHT", -2, -9)
        else
            options.exampleTooltipHealthBar:Hide()
            options.exampleTooltipPowerBar:SetPoint("TOPLEFT", options.exampleTooltip, "BOTTOMLEFT", 2, -1)
            options.exampleTooltipPowerBar:SetPoint("TOPRIGHT", options.exampleTooltip, "BOTTOMRIGHT", -2, -1)
        end
        if (TacoTipConfig.show_power_bar) then
            options.exampleTooltipPowerBar:Show()
        else
            options.exampleTooltipPowerBar:Hide()
        end
    end
    options.exampleTooltip:SetScript("OnEvent", function() showExampleTooltip() end)


    local generalText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    generalText:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -18)
    generalText:SetText("Tooltips")

    options.useClassColors = newCheckbox(
        "ClassColors",
        "Class Color",
        "Color class names in tooltips",
        function(self, value) 
            TacoTipConfig.color_class = value
            showExampleTooltip()
        end)
    options.useClassColors:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", -2, -4)

    options.showTitles = newCheckbox(
        "ShowTitles",
        "Title",
        "Show player's title in tooltips",
        function(self, value) 
            TacoTipConfig.show_titles = value
            showExampleTooltip()
        end)
    options.showTitles:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", 140, -4)

    options.showGuildNames = newCheckbox(
        "GuildNames",
        "Guild Name",
        "Show guild name in tooltips",
        function(self, value) 
            TacoTipConfig.show_guild_name = value
            options.showGuildRanks:SetDisabled(not value)
            if (value) then
                options.guildRankStyle1:SetDisabled(not TacoTipConfig.show_guild_rank)
                options.guildRankStyle2:SetDisabled(not TacoTipConfig.show_guild_rank)
            else
                options.guildRankStyle1:SetDisabled(true)
                options.guildRankStyle2:SetDisabled(true)
            end
            showExampleTooltip()
        end)
    options.showGuildNames:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", -2, -32)

    options.showGuildRanks = newCheckbox(
        "GuildRanks",
        "Guild Rank",
        "Show guild rank in tooltips",
        function(self, value) 
            TacoTipConfig.show_guild_rank = value
            options.guildRankStyle1:SetDisabled(not value)
            options.guildRankStyle2:SetDisabled(not value)
            showExampleTooltip()
        end)
    options.showGuildRanks:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", 140, -32)
    options.showGuildRanks:SetHitRectInsets(0, -80, 0, 0)

    options.guildRankStyle1 = newRadioButton(
        "GuildRankStyle1",
        "Style 1",
        "Rank of <Guild>",
        function(self, value)
            options.guildRankStyle2:SetChecked(false)
            TacoTipConfig.guild_rank_alt_style = false
            showExampleTooltip()
        end)
    options.guildRankStyle1.label:SetText("1")
    options.guildRankStyle1:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", 248, -36)
    options.guildRankStyle1:SetHitRectInsets(0, -16, 0, 0)

    options.guildRankStyle2 = newRadioButton(
        "GuildRankStyle2",
        "Style 2",
        "<Guild> (Rank)",
        function(self, value)
            options.guildRankStyle1:SetChecked(false)
            TacoTipConfig.guild_rank_alt_style = true
            showExampleTooltip()
        end)
    options.guildRankStyle2.label:SetText("2")
    options.guildRankStyle2:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", 280, -36)
    options.guildRankStyle2:SetHitRectInsets(0, -16, 0, 0)

    local rankstylehint = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    rankstylehint:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", 264, -23)
    rankstylehint:SetText("Style")

    options.showTalents = newCheckbox(
        "Talents",
        "Talents",
        "Show talents and specialization in tooltips",
        function(self, value) 
            TacoTipConfig.show_talents = value
            showExampleTooltip()
        end)
    options.showTalents:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", -2, -60)

    options.gearScorePlayer = newCheckbox(
        "GearScorePlayer",
        "GearScore",
        "Show player's GearScore in tooltips",
        function(self, value) 
            TacoTipConfig.show_gs_player = value
            showExampleTooltip()
        end)
    options.gearScorePlayer:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", 140, -60)

    options.pawnScorePlayer = newCheckbox(
        "PawnScorePlayer",
        "PawnScore",
        "Show player's PawnScore in tooltips (may affect performance)",
        function(self, value) 
            TacoTipConfig.show_pawn_player = value
            showExampleTooltip()
        end)
    options.pawnScorePlayer:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", 140, -88)

    options.showTarget = newCheckbox(
        "ShowTarget",
        "Target",
        "Show unit's target in tooltips",
        function(self, value) 
            TacoTipConfig.show_target = value
            showExampleTooltip()
        end)
    options.showTarget:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", -2, -88)

    options.showTeam = newCheckbox(
        "ShowTeam",
        "Faction Icon",
        "Show player's faction icon (Horde/Alliance) in tooltips",
        function(self, value) 
            TacoTipConfig.show_team = value
            showExampleTooltip()
        end)
    options.showTeam:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", -2, -116)   

    options.showPVPIcon = newCheckbox(
        "ShowPVPIcon",
        "PVP Icon",
        "Show player's pvp flag status as icon instead of text",
        function(self, value) 
            TacoTipConfig.show_pvp_icon = value
            showExampleTooltip()
        end)
    options.showPVPIcon:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", 140, -116)

    options.showHealthBar = newCheckbox(
        "ShowHealthBar",
        "Health Bar",
        "Show unit's health bar under tooltip",
        function(self, value) 
            TacoTipConfig.show_hp_bar = value
            showExampleTooltip()
        end)
    options.showHealthBar:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", -2, -144)

    options.showPowerBar = newCheckbox(
        "ShowPowerBar",
        "Power Bar",
        "Show unit's power bar under tooltip",
        function(self, value) 
            TacoTipConfig.show_power_bar = value
            showExampleTooltip()
        end)
    options.showPowerBar:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", 140, -144)


    local characterFrameText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    characterFrameText:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -216)
    characterFrameText:SetText("Character Frame")

    options.gearScoreCharacter = newCheckbox(
        "GearScoreCharacter",
        "GearScore",
        "Show GearScore in character frame",
        function(self, value) 
            TacoTipConfig.show_gs_character = value
        end)
    options.gearScoreCharacter:SetPoint("TOPLEFT", characterFrameText, "BOTTOMLEFT", -2, -4)

    options.averageItemLevel = newCheckbox(
        "AverageItemLevel",
        "Average iLvl",
        "Show Average Item Level in character frame",
        function(self, value) 
            TacoTipConfig.show_avg_ilvl = value
        end)
    options.averageItemLevel:SetPoint("TOPLEFT", characterFrameText, "BOTTOMLEFT", 140, -4)


    local extraText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    extraText:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -274)
    extraText:SetText("Extra")

    options.showItemLevel = newCheckbox(
        "ShowItemLevel",
        "Show Item Level",
        "Display item level in the tooltip for certain items.",
        function(self, value) 
            TacoTipConfig.show_item_level = value
        end)
    options.showItemLevel:SetPoint("TOPLEFT", extraText, "BOTTOMLEFT", -2, -4)  

    options.gearScoreItems = newCheckbox(
        "GearScoreItems",
        "Show Item GearScore",
        "Show GearScore in item tooltips",
        function(self, value) 
            TacoTipConfig.show_gs_items = value
        end)
    options.gearScoreItems:SetPoint("TOPLEFT", extraText, "BOTTOMLEFT", -2, -32)

    options.uberTips = newCheckbox(
        "UberTips",
        "Enhanced Tooltips",
        "Show enhanced tooltips for spells (\"UberTooltips\")",
        function(self, value) 
            SetCVar("UberTooltips", value and "1" or "0")
        end)
    options.uberTips:SetPoint("TOPLEFT", extraText, "BOTTOMLEFT", -2, -60)

    options.hideInCombat = newCheckbox(
        "HideInCombat",
        "Hide In Combat",
        "Hide gearscore & talents in combat",
        function(self, value) 
            TacoTipConfig.hide_in_combat = value
        end)
    options.hideInCombat:SetPoint("TOPLEFT", extraText, "BOTTOMLEFT", -2, -88)

    options.customPosition = newCheckbox(
        "CustomPosition",
        "Custom Tooltip Position",
        "Set a custom position for game tooltips",
        function(self, value)
            if (value) then
                options.moverBtn:SetEnabled(true)
                TacoTip_CustomPosEnable(false)
            else
                options.moverBtn:SetEnabled(false)
                if (TacoTipDragButton) then
                    TacoTipDragButton:_Disable()
                end
                TacoTipConfig.custom_pos = nil
                TacoTipConfig.custom_anchor = nil
            end
        end)
    options.customPosition:SetPoint("TOPLEFT", extraText, "BOTTOMLEFT", -2, -116)

    options.moverBtn = CreateFrame("Button", "TacoTipOptButtonMover", frame, "UIPanelButtonTemplate")
    options.moverBtn:SetText("Mover")
    options.moverBtn:SetWidth(80)
    options.moverBtn:SetHeight(20)
    options.moverBtn:SetPoint("TOPLEFT", extraText, "BOTTOMLEFT", 188, -117)
    options.moverBtn:SetScript("OnClick", function()
        TacoTip_CustomPosEnable(true)
    end)

    options.instantFade = newCheckbox(
        "InstantFade",
        "Instant Fade",
        "Fade out unit tooltips instantly",
        function(self, value) 
            TacoTipConfig.instant_fade = value
            if (value) then
                _G[addOnName].frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
                Detours:DetourHook(_G[addOnName], GameTooltip, "FadeOut", function(self)
                    self:Hide()
                end)
            else
                _G[addOnName].frame:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
                Detours:DetourUnhook(_G[addOnName], GameTooltip, "FadeOut")
            end
        end)
    options.instantFade:SetPoint("TOPLEFT", extraText, "BOTTOMLEFT", -2, -144)

    local styleText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    styleText:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 341, -154)
    styleText:SetText("Tooltip Style")

    local dropdown_values = {
        {"FULL", "Always FULL"},
        {"COMPACT/FULL", "Default COMPACT, hold SHIFT for FULL"},
        {"COMPACT", "Always COMPACT"},
        {"MINI/FULL", "Default MINI, hold SHIFT for FULL"},
        {"MINI", "Always MINI"}
    }
    options.styleChoice = newDropDown(
        "StyleChoice",
        dropdown_values,
        function(value)
            TacoTipConfig.tip_style = value
            showExampleTooltip()
        end)
    options.styleChoice:SetPoint("TOPLEFT", styleText, "BOTTOMLEFT", -20, -4)
    options.styleChoice:SetValue(TacoTipConfig.tip_style)

    local althint1 = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    althint1:SetPoint("TOPLEFT", styleText, "BOTTOMLEFT", -61, -48)
    althint1:SetText("FULL")
    local althint2 = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    althint2:SetPoint("TOPLEFT", althint1, "BOTTOMLEFT", 0, 0)
    althint2:SetText("COMPACT")
    local althint3 = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    althint3:SetPoint("TOPLEFT", althint2, "BOTTOMLEFT", 0, 0)
    althint3:SetText("MINI")
    local althint4 = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    althint4:SetPoint("TOPLEFT", styleText, "BOTTOMLEFT", 3, -48)
    althint4:SetText("Wide, Dual Spec, GearScore, Average iLvl")
    local althint5 = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    althint5:SetPoint("TOPLEFT", althint4, "BOTTOMLEFT", 0, 0)
    althint5:SetText("Narrow, Active Spec, GearScore")
    local althint6 = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    althint6:SetPoint("TOPLEFT", althint5, "BOTTOMLEFT", 0, 0)
    althint6:SetText("Narrow, Active Spec, GearScore, Average iLvl")


    local function getConfig()
        options.useClassColors:SetChecked(TacoTipConfig.color_class)
        options.showTitles:SetChecked(TacoTipConfig.show_titles)
        options.showGuildNames:SetChecked(TacoTipConfig.show_guild_name)
        options.showGuildRanks:SetChecked(TacoTipConfig.show_guild_rank)
        options.showTalents:SetChecked(TacoTipConfig.show_talents)
        options.gearScorePlayer:SetChecked(TacoTipConfig.show_gs_player)
        options.gearScoreCharacter:SetChecked(TacoTipConfig.show_gs_character)
        options.gearScoreItems:SetChecked(TacoTipConfig.show_gs_items)
        options.averageItemLevel:SetChecked(TacoTipConfig.show_avg_ilvl)
        options.showItemLevel:SetChecked(TacoTipConfig.show_item_level)
        options.hideInCombat:SetChecked(TacoTipConfig.hide_in_combat)
        options.uberTips:SetChecked(GetCVar("UberTooltips") == "1")
        options.showTarget:SetChecked(TacoTipConfig.show_target)
        options.styleChoice:SetValue(TacoTipConfig.tip_style)
        options.showGuildRanks:SetDisabled(not TacoTipConfig.show_guild_name)
        options.customPosition:SetChecked(TacoTipConfig.custom_pos and true or false)
        options.moverBtn:SetEnabled(TacoTipConfig.custom_pos and true or false)
        options.pawnScorePlayer:SetDisabled(not isPawnLoaded)
        options.pawnScorePlayer:SetChecked(TacoTipConfig.show_pawn_player)
        options.pawnScorePlayer.label:SetText(isPawnLoaded and "PawnScore" or "PawnScore (requires Pawn)")
        options.showTeam:SetChecked(TacoTipConfig.show_team)
        options.showPVPIcon:SetChecked(TacoTipConfig.show_pvp_icon)
        options.guildRankStyle1:SetChecked(not TacoTipConfig.guild_rank_alt_style)
        options.guildRankStyle2:SetChecked(TacoTipConfig.guild_rank_alt_style)
        options.guildRankStyle1:SetDisabled(not TacoTipConfig.show_guild_rank)
        options.guildRankStyle2:SetDisabled(not TacoTipConfig.show_guild_rank)
        options.showHealthBar:SetChecked(TacoTipConfig.show_hp_bar)
        options.showPowerBar:SetChecked(TacoTipConfig.show_power_bar)
        options.instantFade:SetChecked(TacoTipConfig.instant_fade)
    end

    local resetcfg = CreateFrame("Button", "TacoTipOptButtonResetCfg", frame, "UIPanelButtonTemplate")
    resetcfg:SetText("Reset configuration")
    resetcfg:SetWidth(177)
    resetcfg:SetHeight(24)
    resetcfg:SetPoint("TOPLEFT", extraText, "BOTTOMLEFT", 0, -180)
    resetcfg:SetScript("OnClick", function()
        resetCfg()
        getConfig()
        showExampleTooltip()
    end)

    getConfig()
    options.exampleTooltip:RegisterEvent("MODIFIER_STATE_CHANGED")
    showExampleTooltip()

    frame:SetScript("OnShow", function()
        getConfig()
        options.exampleTooltip:RegisterEvent("MODIFIER_STATE_CHANGED")
        showExampleTooltip()
    end)
    frame:SetScript("OnHide", function()
        options.exampleTooltip:UnregisterEvent("MODIFIER_STATE_CHANGED")
    end)
end)

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
        if (not TacoTipConfig.custom_pos) then
            print("|cff59f0dcTacoTip:|r Custom tooltip position is disabled.")
        end
        if (TacoTipDragButton) then
            TacoTipDragButton:_Disable()
        end
        TacoTipConfig.custom_pos = nil
        TacoTipConfig.custom_anchor = nil
    elseif (cmd == "reset") then
        resetCfg()
        if (frame:IsShown()) then
            getConfig()
            showExampleTooltip()
        end
        print("|cff59f0dcTacoTip:|r Configuration has been reset to default.")
    else
        InterfaceOptionsFrame_OpenToCategory(addOnName)
        InterfaceOptionsFrame_OpenToCategory(addOnName)
    end
end
