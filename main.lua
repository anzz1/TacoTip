
GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    if (not inspector) then return end
    local name, unit = self:GetUnit()
    if (not unit or not UnitIsPlayer(unit)) then 
        return
    end
    
    local text1 = GameTooltipTextLeft1:GetText()
    if(not text1 or text1 == "") then return; end
    local text2 = GameTooltipTextLeft2:GetText()
    if(not text2 or text2 == "") then return; end
    local text3 = GameTooltipTextLeft3:GetText()

    if (not TacoTipConfig.show_titles and string.find(text1, name)) then
        text1 = name
    end
    local localizedClass, class = UnitClass(unit)
    if (TacoTipConfig.color_class and localizedClass and class) then
        local classc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
        --GameTooltipTextLeft1:SetTextColor(classc.r, classc.g, classc.b)
        text1 = string.format("|cFF%02x%02x%02x%s|r", classc.r*255, classc.g*255, classc.b*255, text1)
        text2 = string.gsub(text2, localizedClass, string.format("|cFF%02x%02x%02x%s|r", classc.r*255, classc.g*255, classc.b*255, localizedClass), 1)
        if (text3) then
            text3 = string.gsub(text3, localizedClass, string.format("|cFF%02x%02x%02x%s|r", classc.r*255, classc.g*255, classc.b*255, localizedClass), 1)
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
        local spec = IGetActiveSpecByGUID(guid)
        if (spec and TacoTipConfig.show_talents) then
            local p1, p2, p3 = IGetTotalTalentPointsByGUID(guid)
            self:AddLine(string.format("Talents:|cFFFFFFFF %s [%d/%d/%d]", spec, p1, p2, p3))
        end
    
        --local cacheTimeTalents, cacheTimeInventory = IGetLastCacheTime(guid)
        --if (cacheTimeInventory ~= 0) then
        local gearscore = GearScore_GetScore(unit)
        if (gearscore > 0 and TacoTipConfig.show_gs_player) then
            local r, g, b = GearScore_GetQuality(gearscore)
            self:AddLine("|cFFFFFFFFGearScore:|r "..gearscore, r, g, b)
        end
    end
end)

local function itemToolTipHook(self)
    if (TacoTipConfig.show_item_level) then
        local ilvl = select(4, GetItemInfo(select(2, self:GetItem())))
        if (ilvl and ilvl > 1) then
            self:AddLine("Item Level "..ilvl, 1, 1, 1)
        end
    end
    if (TacoTipConfig.show_gs_items and IsEquippableItem(self:GetItem())) then
        local gs = GearScore_GetItemScore(self:GetItem())
        if (gs and gs > 1) then
            self:AddLine("GearScore: "..gs, 1, 1, 1)
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
	local MyGearScore, MyAverageScore = GearScore_GetScore(UnitName("player"), "player");
	local r, g, b = GearScore_GetQuality(MyGearScore)
	if (TacoTipConfig.show_gs_character) then
		PersonalGearScore:Show()
		PersonalGearScoreText:Show()
	else
		PersonalGearScore:Hide()
		PersonalGearScoreText:Hide()
	end
	if (TacoTipConfig.show_avg_ilvl) then
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
		local r, b, g = GearScore_GetQuality(inspect_gs)
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
    local MyGearScore, MyAverageScore = GearScore_GetScore("player");
    local r, g, b = GearScore_GetQuality(MyGearScore)
    PersonalGearScore:SetText(MyGearScore);
    PersonalGearScore:SetTextColor(r, g, b, 1)
    PersonalAvgItemLvl:SetText(MyAverageScore);
    PersonalAvgItemLvl:SetTextColor(r, g, b, 1)
end

local f = CreateFrame("Frame", nil, UIParent)
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
--f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", onEvent)

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
