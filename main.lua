
GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    if (not inspector) then return end
    local name, unit = self:GetUnit()
    if (not unit) then 
        return
    end

    local wide_style = (TacoTipConfig.tip_style == 3 or (TacoTipConfig.tip_style == 2 and IsModifierKeyDown()) and true) or false

    if (TacoTipConfig.show_target and UnitIsConnected(unit) and not UnitIsUnit(unit, "player")) then
        local unitTarget = unit .. "target"
        local targetName = UnitName(unitTarget)
        if (targetName) then
            if (UnitIsUnit(unitTarget, unit)) then
                if (wide_style) then
                    self:AddDoubleLine("Target:", "Self", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
                else
                    self:AddLine("Target: |cFFFFFFFFSelf|r")
                end
            elseif (UnitIsUnit(unitTarget, "player")) then
                if (wide_style) then
                    self:AddDoubleLine("Target:", "You", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1, 1, 0)
                else
                    self:AddLine("Target: |cFFFFFF00You|r")
                end
            elseif (UnitIsPlayer(unitTarget)) then
                local classc
                if (TacoTipConfig.color_class) then
                    local _, targetClass = UnitClass(unitTarget)
                    if (targetClass) then
                        classc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[targetClass]
                    end
                end
                if (classc) then
                    if (wide_style) then
                        self:AddDoubleLine("Target:", string.format("|cFF%02x%02x%02x%s|r (Player)", classc.r*255, classc.g*255, classc.b*255, targetName), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
                    else
                        self:AddLine(string.format("Target: |cFF%02x%02x%02x%s|cFFFFFFFF (Player)|r", classc.r*255, classc.g*255, classc.b*255, targetName))
                    end
                else
                    if (wide_style) then
                        self:AddDoubleLine("Target:", targetName.." (Player)", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
                    else
                        self:AddLine("Target: |cFFFFFFFF"..targetName.." (Player)|r")
                    end
                end
            elseif (UnitIsUnit(unitTarget, "pet") or UnitIsOtherPlayersPet(unitTarget)) then
                if (wide_style) then
                    self:AddDoubleLine("Target:", targetName.." (Pet)", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
                else
                    self:AddLine("Target: |cFFFFFFFF"..targetName.." (Pet)|r")
                end
            else
                if (wide_style) then
                    self:AddDoubleLine("Target:", targetName, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
                else
                    self:AddLine("Target: |cFFFFFFFF"..targetName.."|r")
                end
            end
        elseif (wide_style) then
            self:AddDoubleLine("Target:", "None", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
        else
            self:AddLine("Target: |cFF808080None|r")
        end
    end

    if (UnitIsPlayer(unit)) then
        local text1 = GameTooltipTextLeft1:GetText()
        if(not text1 or text1 == "") then return; end
        local text2 = GameTooltipTextLeft2:GetText()
        if(not text2 or text2 == "") then return; end
        local text3 = GameTooltipTextLeft3:GetText()

        if (not TacoTipConfig.show_titles and string.find(text1, name)) then
            text1 = name
        end
        if (TacoTipConfig.color_class) then
            local localizedClass, class = UnitClass(unit)
            if (localizedClass and class) then
                local classc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
                if (classc) then
                    --GameTooltipTextLeft1:SetTextColor(classc.r, classc.g, classc.b)
                    text1 = string.format("|cFF%02x%02x%02x%s|r", classc.r*255, classc.g*255, classc.b*255, text1)
                    text2 = string.gsub(text2, localizedClass, string.format("|cFF%02x%02x%02x%s|r", classc.r*255, classc.g*255, classc.b*255, localizedClass), 1)
                    if (text3) then
                        text3 = string.gsub(text3, localizedClass, string.format("|cFF%02x%02x%02x%s|r", classc.r*255, classc.g*255, classc.b*255, localizedClass), 1)
                    end
                end
            end
        end
        local guildName, guildRankName = GetGuildInfo(unit);
        if (guildName and guildRankName) then
            if (TacoTipConfig.show_guild_name) then
                if (TacoTipConfig.show_guild_rank) then 
                    text2 = string.gsub(text2, guildName, string.format("|cFF40FB40%s of <%s>|r", guildRankName, guildName), 1)
                else
                    text2 = string.gsub(text2, guildName, string.format("|cFF40FB40<%s>|r", guildName), 1)
                end
            else
                if (string.find(text2, guildName)) then
                    text2 = ""
                end
            end
        end

        GameTooltipTextLeft1:SetText(text1)
        GameTooltipTextLeft2:SetText(text2)
        if (text3) then
            GameTooltipTextLeft3:SetText(text3)
        end

        if (not TacoTipConfig.hide_in_combat or not InCombatLockdown()) then
            local guid = UnitGUID(unit)

            if (TacoTipConfig.show_talents) then
                local x1, x2, x3 = 0,0,0
                local y1, y2, y3 = 0,0,0
                local spec1 = IGetMostPointsSpecByGUID(guid, 1)
                if (spec1) then
                    x1, x2, x3 = IGetTotalTalentPointsByGUID(guid, 1)
                end
                local spec2 = IGetMostPointsSpecByGUID(guid, 2)
                if (spec2) then
                    y1, y2, y3 = IGetTotalTalentPointsByGUID(guid, 2)
                end

                local active = IGetActiveTalentGroupByGUID(guid)

                if (active == 2) then
                    if (spec2) then
                        if (wide_style) then
                            self:AddDoubleLine("Talents:", string.format("%s [%d/%d/%d]", spec2, y1, y2, y3), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
                        else
                            self:AddLine(string.format("Talents:|cFFFFFFFF %s [%d/%d/%d]|r", spec2, y1, y2, y3))
                        end
                    end
                    if (spec1) then
                        if (wide_style) then
                            self:AddDoubleLine((spec2 and " " or "Talents:"), string.format("%s [%d/%d/%d]", spec1, x1, x2, x3), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
                        elseif (not spec2) then
                            self:AddLine(string.format("Talents:|cFF808080 %s [%d/%d/%d]|r", spec1, x1, x2, x3))
                        end
                    end
                else
                    if (spec1) then
                        if (wide_style) then
                            self:AddDoubleLine("Talents:", string.format("%s [%d/%d/%d]", spec1, x1, x2, x3), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
                        else
                            self:AddLine(string.format("Talents:|cFFFFFFFF %s [%d/%d/%d]|r", spec1, x1, x2, x3))
                        end
                    end
                    if (spec2) then
                        if (wide_style) then
                            self:AddDoubleLine((spec1 and " " or "Talents:"), string.format("%s [%d/%d/%d]", spec2, y1, y2, y3), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
                        elseif (not spec1) then
                            self:AddLine(string.format("Talents:|cFF808080 %s [%d/%d/%d]|r", spec2, y1, y2, y3))
                        end
                    end
                end
            end
    
            if (TacoTipConfig.show_gs_player) then
                local gearscore, avg_ilvl = GearScore_GetScore(unit)
                if (gearscore > 0) then
                    local r, g, b = GearScore_GetQuality(gearscore)
                    if (wide_style) then
                        if (r == b and r == g) then
                            self:AddDoubleLine("|cFFFFFFFFGearScore:|r "..gearscore, "|cFFFFFFFF(iLvl:|r "..avg_ilvl.."|cFFFFFFFF)|r", r, g, b, r, g, b)
                        else
                            self:AddDoubleLine("GearScore: "..gearscore, "(iLvl: "..avg_ilvl..")", r, g, b, r, g, b)
                        end
                    else
                        if (r == b and r == g) then
                            self:AddLine("|cFFFFFFFFGearScore:|r "..gearscore, r, g, b)
                        else
                            self:AddLine("GearScore: "..gearscore, r, g, b)
                        end
                    end
                end
            end
        end
    end
end)

local function itemToolTipHook(self)
    local _, itemLink = self:GetItem()
    if (itemLink and IsEquippableItem(itemLink)) then
        if (TacoTipConfig.show_item_level) then
            local ilvl = select(4, GetItemInfo(itemLink))
            if (ilvl and ilvl > 1) then
                self:AddLine("Item Level "..ilvl, 1, 1, 1)
            end
        end
        if (TacoTipConfig.show_gs_items) then
            local gs, _, _, r, g, b = GearScore_GetItemScore(itemLink)
            if (gs and gs > 1) then
                self:AddLine("GearScore: "..gs, r, g, b)
            end
        end
    end
end

GameTooltip:HookScript("OnTooltipSetItem", itemToolTipHook)
ShoppingTooltip1:HookScript("OnTooltipSetItem", itemToolTipHook)
ShoppingTooltip2:HookScript("OnTooltipSetItem", itemToolTipHook)
ItemRefTooltip:HookScript("OnTooltipSetItem", itemToolTipHook)

PaperDollFrame:CreateFontString("PersonalGearScore")
PersonalGearScore:SetFont("Fonts\\FRIZQT__.TTF", 10)
PersonalGearScore:SetText("0")
PersonalGearScore:SetPoint("BOTTOMLEFT",PaperDollFrame,"TOPLEFT",72,-253)
PersonalGearScore:Show()
PaperDollFrame:CreateFontString("PersonalGearScoreText")
PersonalGearScoreText:SetFont("Fonts\\FRIZQT__.TTF", 10)
PersonalGearScoreText:SetText("GearScore")
PersonalGearScoreText:SetPoint("BOTTOMLEFT",PaperDollFrame,"TOPLEFT",72,-265)
PersonalGearScoreText:Show()

PaperDollFrame:CreateFontString("PersonalAvgItemLvl")
PersonalAvgItemLvl:SetFont("Fonts\\FRIZQT__.TTF", 10)
PersonalAvgItemLvl:SetText("0")
PersonalAvgItemLvl:SetPoint("BOTTOMLEFT",PaperDollFrame,"TOPLEFT",270,-253)
PersonalAvgItemLvl:Show()
PaperDollFrame:CreateFontString("PersonalAvgItemLvlText")
PersonalAvgItemLvlText:SetFont("Fonts\\FRIZQT__.TTF", 10)
PersonalAvgItemLvlText:SetText("iLvl")
PersonalAvgItemLvlText:SetPoint("BOTTOMLEFT",PaperDollFrame,"TOPLEFT",270,-265)
PersonalAvgItemLvlText:Show()

PaperDollFrame:HookScript("OnShow", function(self)
    local MyGearScore, MyAverageScore = GearScore_GetScore("player");
    local r, g, b = GearScore_GetQuality(MyGearScore)
    if (TacoTipConfig.show_gs_character) then
        PersonalGearScore:SetText(MyGearScore);
        PersonalGearScore:SetTextColor(r, g, b, 1)
        PersonalGearScore:Show()
        PersonalGearScoreText:Show()
    else
        PersonalGearScore:Hide()
        PersonalGearScoreText:Hide()
    end
    if (TacoTipConfig.show_avg_ilvl) then
        PersonalAvgItemLvl:SetText(MyAverageScore);
        PersonalAvgItemLvl:SetTextColor(r, g, b, 1)
        PersonalAvgItemLvl:Show()
        PersonalAvgItemLvlText:Show()
    else
        PersonalAvgItemLvl:Hide()
        PersonalAvgItemLvlText:Hide()
    end
end)

local function RefreshInspectFrame()
    if (InCombatLockdown()) then
        InspectGearScore:Hide()
        InspectGearScoreText:Hide()
        InspectAvgItemLvl:Hide()
        InspectAvgItemLvlText:Hide()
    elseif (TacoTipConfig.show_gs_character or TacoTipConfig.show_avg_ilvl) then
        local inspect_gs, inspect_avg = GearScore_GetScore(InspectFrame.unit);
        local r, g, b = GearScore_GetQuality(inspect_gs)
        if (TacoTipConfig.show_gs_character) then
            InspectGearScore:SetText(inspect_gs);
            InspectGearScore:SetTextColor(r, g, b, 1)
            InspectGearScore:Show()
            InspectGearScoreText:Show()
        else
            InspectGearScore:Hide()
            InspectGearScoreText:Hide()
        end
        if (TacoTipConfig.show_avg_ilvl) then
            InspectAvgItemLvl:SetText(inspect_avg);
            InspectAvgItemLvl:SetTextColor(r, g, b, 1)
            InspectAvgItemLvl:Show()
            InspectAvgItemLvlText:Show()
        else
            InspectAvgItemLvl:Hide()
            InspectAvgItemLvlText:Hide()
        end
    else
        InspectGearScore:Hide()
        InspectGearScoreText:Hide()
        InspectAvgItemLvl:Hide()
        InspectAvgItemLvlText:Hide()
    end
end

local inspect_init = false
local function InitInspectFrame()
    inspect_init = true
    local text1 = InspectModelFrame:CreateFontString("InspectGearScore");
    text1:SetFont("Fonts\\FRIZQT__.TTF", 10);
    text1:SetText("0");
    text1:SetPoint("BOTTOMLEFT",InspectPaperDollFrame,"TOPLEFT",72,-359);

    local text2 = InspectModelFrame:CreateFontString("InspectGearScoreText");
    text2:SetFont("Fonts\\FRIZQT__.TTF", 10);
    text2:SetText("GearScore");
    text2:SetPoint("BOTTOMLEFT",InspectPaperDollFrame,"TOPLEFT",72,-372);
    
    local text3 = InspectModelFrame:CreateFontString("InspectAvgItemLvl");
    text3:SetFont("Fonts\\FRIZQT__.TTF", 10);
    text3:SetText("0");
    text3:SetPoint("BOTTOMLEFT",InspectPaperDollFrame,"TOPLEFT",270,-359);

    local text4 = InspectModelFrame:CreateFontString("InspectAvgItemLvlText");
    text4:SetFont("Fonts\\FRIZQT__.TTF", 10);
    text4:SetText("iLvl");
    text4:SetPoint("BOTTOMLEFT",InspectPaperDollFrame,"TOPLEFT",270,-372);

    InspectPaperDollFrame:HookScript("OnShow", RefreshInspectFrame);
end

local function onEvent(self, event, ...)
    if (event == "PLAYER_EQUIPMENT_CHANGED") then
        local MyGearScore, MyAverageScore = GearScore_GetScore("player");
        local r, g, b = GearScore_GetQuality(MyGearScore)
        PersonalGearScore:SetText(MyGearScore);
        PersonalGearScore:SetTextColor(r, g, b, 1)
        PersonalAvgItemLvl:SetText(MyAverageScore);
        PersonalAvgItemLvl:SetTextColor(r, g, b, 1)
    else -- MODIFIER_STATE_CHANGED
        local _, unit = GameTooltip:GetUnit()
        if (unit and UnitIsPlayer(unit)) then
            GameTooltip:SetUnit(unit)
        end
    end
end

do
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    f:RegisterEvent("MODIFIER_STATE_CHANGED")
    f:SetScript("OnEvent", onEvent)
end

-- TODO: use something better than a timed func
C_Timer.NewTicker(1, function()
    if (not inspector or InCombatLockdown() or not UnitExists("player") or not UnitIsConnected("player") or UnitIsDeadOrGhost("player")) then
        return
    end
    if (not inspect_init) then
        if (InspectModelFrame and InspectPaperDollFrame) then
            InitInspectFrame()
        end
    elseif (InspectFrame and InspectFrame:IsShown()) then
       RefreshInspectFrame()
    end
end)
