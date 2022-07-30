
local addOnName = ...
local addOnVersion = GetAddOnMetadata(addOnName, "Version") or "0.0.1"

local function resetCfg()
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
        show_target = false
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
    
    
    options.exampleTooltip = CreateFrame("GameTooltip", "TacoTipOptExampleTooltip", frame, "GameTooltipTemplate" );
    local function showExampleTooltip()
        options.exampleTooltip:SetOwner(frame, "ANCHOR_NONE")
        options.exampleTooltip:SetPoint("TOPLEFT", description, "TOPLEFT", 340, 0)
        local classc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)["ROGUE"]
        local name_r = TacoTipConfig.color_class and classc.r or 1
        local name_g = TacoTipConfig.color_class and classc.g or 1
        local name_b = TacoTipConfig.color_class and classc.b or 1
        local title = TacoTipConfig.show_titles and " the Kingslayer" or ""
        options.exampleTooltip:AddLine(string.format("|cFF%02x%02x%02xKebabstorm%s|r", name_r*255, name_g*255, name_b*255, title))
        if (TacoTipConfig.show_guild_name) then
            if (TacoTipConfig.show_guild_rank) then
                options.exampleTooltip:AddLine("|cFF40FB40Officer of <Drunken Wrath>|r")
            else
                options.exampleTooltip:AddLine("|cFF40FB40<Drunken Wrath>|r")
            end
        end
        options.exampleTooltip:AddLine(string.format("Level 80 Undead |cFF%02x%02x%02xRogue|r (Player)", name_r*255, name_g*255, name_b*255), 1, 1, 1)
        
        local wide_style = (TacoTipConfig.tip_style == 3 or (TacoTipConfig.tip_style == 2 and IsModifierKeyDown()) and true) or false
        if (TacoTipConfig.show_talents) then
            if (wide_style) then
                options.exampleTooltip:AddDoubleLine("Talents:", "Assassination [51/18/2]", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
                options.exampleTooltip:AddDoubleLine(" ", "Subtlety [14/3/54]", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
            else
                options.exampleTooltip:AddLine("Talents:|cFFFFFFFF Assassination [51/18/2]")
            end
        end
        if (TacoTipConfig.show_gs_player) then
            local gs_r, gs_b, gs_g = GearScore_GetQuality(6054)
            if (wide_style) then
                options.exampleTooltip:AddDoubleLine("GearScore: 6054", "(iLvl: 264)", gs_r, gs_g, gs_b, gs_r, gs_g, gs_b)
            else
                options.exampleTooltip:AddLine("GearScore: 6054", gs_r, gs_g, gs_b)
            end
        end
        if (TacoTipConfig.show_target) then
            options.exampleTooltip:AddLine("Target: None", 1, 1, 1)
        end
        options.exampleTooltip:Show();
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
            showExampleTooltip()
        end)
    options.showGuildNames:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", -2, -32)
    
    options.showGuildRanks = newCheckbox(
        "GuildRanks",
        "Guild Rank",
        "Show guild rank in tooltips",
        function(self, value) 
            TacoTipConfig.show_guild_rank = value
            showExampleTooltip()
        end)
    options.showGuildRanks:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", 140, -32)
    
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
        "Show players GearScore in tooltips",
        function(self, value) 
            TacoTipConfig.show_gs_player = value
            showExampleTooltip()
        end)
    options.gearScorePlayer:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", 140, -60)

    options.showTarget = newCheckbox(
        "ShowTarget",
        "Target",
        "Show unit's target in tooltips",
        function(self, value) 
            TacoTipConfig.show_target = value
            showExampleTooltip()
        end)
    options.showTarget:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", -2, -88)    


    local characterFrameText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    characterFrameText:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -160)
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
    extraText:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -218)
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
    
    options.hideInCombat = newCheckbox(
        "HideInCombat",
        "Hide In Combat",
        "Hide gearscore & talents in combat (low-performance mode)",
        function(self, value) 
            TacoTipConfig.hide_in_combat = value
        end)
    options.hideInCombat:SetPoint("TOPLEFT", extraText, "BOTTOMLEFT", -2, -60)


    local styleText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    styleText:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 360, -132)
    styleText:SetText("Tooltip Style")
    
    local dropdown_values = {
        {"COMPACT", "Always show Compact info"},
        {"HYBRID", "Compact by default, hold SHIFT for Full info"},
        {"FULL", "Always show Full info"}
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
    althint1:SetPoint("TOPLEFT", styleText, "BOTTOMLEFT", -90, -48)
    althint1:SetText("COMPACT")
    local althint2 = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    althint2:SetPoint("TOPLEFT", althint1, "BOTTOMLEFT", 0, 0)
    althint2:SetText("HYBRID")
    local althint3 = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    althint3:SetPoint("TOPLEFT", althint2, "BOTTOMLEFT", 0, 0)
    althint3:SetText("FULL")
    local althint4 = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    althint4:SetPoint("TOPLEFT", styleText, "BOTTOMLEFT", -26, -48)
    althint4:SetText("Show active spec and GearScore")
    local althint5 = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    althint5:SetPoint("TOPLEFT", althint4, "BOTTOMLEFT", 0, 0)
    althint5:SetText("Compact by default, hold SHIFT for Full")
    local althint6 = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    althint6:SetPoint("TOPLEFT", althint5, "BOTTOMLEFT", 0, 0)
    althint6:SetText("Show dual spec, GearScore, average iLvl")
    
    
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
        options.showTarget:SetChecked(TacoTipConfig.show_target)
        options.styleChoice:SetValue(TacoTipConfig.tip_style)
        options.showGuildRanks:SetDisabled(not TacoTipConfig.show_guild_name)
    end
    
    local resetcfg = CreateFrame("Button", "TacoTipOptButtonResetCfg", frame, "UIPanelButtonTemplate")
    resetcfg:SetText("Reset configuration")
    resetcfg:SetWidth(177)
    resetcfg:SetHeight(24)
    resetcfg:SetPoint("TOPLEFT", extraText, "BOTTOMLEFT", 0, -126)
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
SLASH_TACOTIP3 = "/tt";
SLASH_TACOTIP4 = "/gs";
SLASH_TACOTIP5 = "/gearscore";
SlashCmdList["TACOTIP"] = function(msg)
    InterfaceOptionsFrame_OpenToCategory(addOnName)
    InterfaceOptionsFrame_OpenToCategory(addOnName)
end
