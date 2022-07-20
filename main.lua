
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
	if (text3) then GameTooltipTextLeft3:SetText(text3); end
    
    local guid = UnitGUID(unit)
    local spec = IGetActiveSpecByGUID(guid)
    if (spec) then
        local p1, p2, p3 = IGetTotalTalentPointsByGUID(guid)
        self:AddLine(string.format("Talents:|cFFFFFFFF %s [%d/%d/%d]", spec, p1, p2, p3))
    end

    --local cacheTimeTalents, cacheTimeInventory = IGetLastCacheTime(guid)
    --if (cacheTimeInventory ~= 0) then
    local gearscore = GearScore_GetScore(unit)
    if (gearscore > 0) then
        local r, g, b = GearScore_GetQuality(gearscore)
        self:AddLine("|cFFFFFFFFGearScore:|r "..gearscore, r, g, b)
    end
end)

local function itemToolTipHook(self)
    local ilvl = select(4, GetItemInfo(select(2, self:GetItem())))
    if (ilvl and ilvl > 1) then
        self:AddLine("Item Level "..ilvl, 1, 1, 1)
    end
end

GameTooltip:HookScript("OnTooltipSetItem", itemToolTipHook)
ShoppingTooltip1:HookScript("OnTooltipSetItem", itemToolTipHook)
ShoppingTooltip2:HookScript("OnTooltipSetItem", itemToolTipHook)
ItemRefTooltip:HookScript("OnTooltipSetItem", itemToolTipHook)
