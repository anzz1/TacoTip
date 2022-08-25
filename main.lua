
local addOnName = ...

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

local CI = LibStub("LibClassicInspector")
local Detours = LibStub("LibDetours-1.0")
local GearScore = TT_GS

local isPawnLoaded = PawnClassicLastUpdatedVersion and PawnClassicLastUpdatedVersion >= 2.0538

local HORDE_ICON = "|TInterface\\TargetingFrame\\UI-PVP-HORDE:16:16:-2:0:64:64:0:38:0:38|t"
local ALLIANCE_ICON = "|TInterface\\TargetingFrame\\UI-PVP-ALLIANCE:16:16:-2:0:64:64:0:38:0:38|t"
local PVP_FLAG_ICON = "|TInterface\\GossipFrame\\BattleMasterGossipIcon:0|t"

local POWERBAR_UPDATE_RATE = 0.2

local NewTicker = C_Timer.NewTicker
local CAfter = C_Timer.After

function TacoTip_GSCallback(guid)
    local _, ttUnit = GameTooltip:GetUnit()
    if (ttUnit and UnitGUID(ttUnit) == guid) then
        GameTooltip:SetUnit(ttUnit)
    end
end

GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    local name, unit = self:GetUnit()
    if (not unit) then 
        return
    end

    if (TacoTipDragButton and TacoTipDragButton:IsShown()) then
        if (not UnitIsUnit(unit, "player")) then
            TacoTipDragButton:ShowExample()
            return
        end
    end

    local guid = UnitGUID(unit)

    local wide_style = (TacoTipConfig.tip_style == 1 or ((TacoTipConfig.tip_style == 2 or TacoTipConfig.tip_style == 4) and IsModifierKeyDown()))
    local mini_style = (not wide_style and (TacoTipConfig.tip_style == 4 or TacoTipConfig.tip_style == 5))

    local text = {}
    local linesToAdd = {}

    local numLines = GameTooltip:NumLines()

    for i=1,numLines do
        text[i] = _G["GameTooltipTextLeft"..i]:GetText()
    end
    if (not text[1] or text[1] == "") then return end
    if (not text[2] or text[2] == "") then return end

    if (TacoTipConfig.show_target and UnitIsConnected(unit) and not UnitIsUnit(unit, "player")) then
        local unitTarget = unit .. "target"
        local targetName = UnitName(unitTarget)

        if (targetName) then
            if (UnitIsUnit(unitTarget, unit)) then
                if (wide_style) then
                    tinsert(linesToAdd, {"Target:", "Self", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b})
                else
                    tinsert(linesToAdd, {"Target: |cFFFFFFFFSelf|r"})
                end
            elseif (UnitIsUnit(unitTarget, "player")) then
                if (wide_style) then
                    tinsert(linesToAdd, {"Target:", "You", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1, 1, 0})
                else
                    tinsert(linesToAdd, {"Target: |cFFFFFF00You|r"})
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
                        tinsert(linesToAdd, {"Target:", string.format("|cFF%02x%02x%02x%s|r (Player)", classc.r*255, classc.g*255, classc.b*255, targetName), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b})
                    else
                        tinsert(linesToAdd, {string.format("Target: |cFF%02x%02x%02x%s|cFFFFFFFF (Player)|r", classc.r*255, classc.g*255, classc.b*255, targetName)})
                    end
                else
                    if (wide_style) then
                        tinsert(linesToAdd, {"Target:", targetName.." (Player)", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b})
                    else
                        tinsert(linesToAdd, {"Target: |cFFFFFFFF"..targetName.." (Player)|r"})
                    end
                end
            elseif (UnitIsUnit(unitTarget, "pet") or UnitIsOtherPlayersPet(unitTarget)) then
                if (wide_style) then
                    tinsert(linesToAdd, {"Target:", targetName.." (Pet)", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b})
                else
                    tinsert(linesToAdd, {"Target: |cFFFFFFFF"..targetName.." (Pet)|r"})
                end
            else
                if (wide_style) then
                    tinsert(linesToAdd, {"Target:", targetName, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b})
                else
                    tinsert(linesToAdd, {"Target: |cFFFFFFFF"..targetName.."|r"})
                end
            end
        else
            local inSameMap = true
            if (IsInGroup() and ((IsInRaid() and UnitInRaid(unit)) or UnitInParty(unit))) then
                if (C_Map.GetBestMapForUnit(unit) ~= C_Map.GetBestMapForUnit("player")) then
                    inSameMap = false
                end
            end
            if (inSameMap) then
                if (wide_style) then
                    tinsert(linesToAdd, {"Target:", "None", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b})
                else
                    tinsert(linesToAdd, {"Target: |cFF808080None|r"})
                end
            end
        end
    end

    if (UnitIsPlayer(unit)) then
        local localizedClass, class = UnitClass(unit)

        if (not TacoTipConfig.show_titles and string.find(text[1], name)) then
            text[1] = name
        end
        if (TacoTipConfig.color_class) then
            if (localizedClass and class) then
                local classc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
                if (classc) then
                    --GameTooltipTextLeft1:SetTextColor(classc.r, classc.g, classc.b)
                    text[1] = string.format("|cFF%02x%02x%02x%s|r", classc.r*255, classc.g*255, classc.b*255, text[1])
                    for i=2,3 do
                        if (text[i]) then
                            text[i] = string.gsub(text[i], localizedClass, string.format("|cFF%02x%02x%02x%s|r", classc.r*255, classc.g*255, classc.b*255, localizedClass), 1)
                        end
                    end
                end
            end
        end
        local guildName, guildRankName = GetGuildInfo(unit);
        if (guildName and guildRankName) then
            if (TacoTipConfig.show_guild_name) then
                if (TacoTipConfig.show_guild_rank) then
                    if (TacoTipConfig.guild_rank_alt_style) then
                        text[2] = string.gsub(text[2], guildName, string.format("|cFF40FB40<%s> (%s)|r", guildName, guildRankName), 1)
                    else
                        text[2] = string.gsub(text[2], guildName, string.format("|cFF40FB40%s of <%s>|r", guildRankName, guildName), 1)
                    end
                else
                    text[2] = string.gsub(text[2], guildName, string.format("|cFF40FB40<%s>|r", guildName), 1)
                end
            else
                text[2] = string.gsub(text[2], guildName, "", 1)
            end
        end
        if (TacoTipConfig.show_team) then
            text[1] = text[1].." "..(UnitFactionGroup(unit) == "Horde" and HORDE_ICON or ALLIANCE_ICON)
        end

        if (not TacoTipConfig.hide_in_combat or not InCombatLockdown()) then
            if (TacoTipConfig.show_talents) then
                local x1, x2, x3 = 0,0,0
                local y1, y2, y3 = 0,0,0
                local spec1 = CI:GetSpecialization(guid, 1)
                if (spec1) then
                    x1, x2, x3 = CI:GetTalentPoints(guid, 1)
                end
                local spec2 = CI:GetSpecialization(guid, 2)
                if (spec2) then
                    y1, y2, y3 = CI:GetTalentPoints(guid, 2)
                end

                local active = CI:GetActiveTalentGroup(guid)

                if (active == 2) then
                    if (spec2) then
                        if (wide_style) then
                            tinsert(linesToAdd, {"Talents:", string.format("%s [%d/%d/%d]", CI:GetSpecializationName(class, spec2), y1, y2, y3), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b})
                        else
                            tinsert(linesToAdd, {string.format("Talents:|cFFFFFFFF %s [%d/%d/%d]|r", CI:GetSpecializationName(class, spec2), y1, y2, y3)})
                        end
                    end
                    if (spec1) then
                        if (wide_style) then
                            tinsert(linesToAdd, {(spec2 and " " or "Talents:"), string.format("%s [%d/%d/%d]", CI:GetSpecializationName(class, spec1), x1, x2, x3), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b})
                        elseif (not spec2) then
                            tinsert(linesToAdd, {string.format("Talents:|cFF808080 %s [%d/%d/%d]|r", CI:GetSpecializationName(class, spec1), x1, x2, x3)})
                        end
                    end
                elseif (active == 1) then
                    if (spec1) then
                        if (wide_style) then
                            tinsert(linesToAdd, {"Talents:", string.format("%s [%d/%d/%d]", CI:GetSpecializationName(class, spec1), x1, x2, x3), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b})
                        else
                            tinsert(linesToAdd, {string.format("Talents:|cFFFFFFFF %s [%d/%d/%d]|r", CI:GetSpecializationName(class, spec1), x1, x2, x3)})
                        end
                    end
                    if (spec2) then
                        if (wide_style) then
                            tinsert(linesToAdd, {(spec1 and " " or "Talents:"), string.format("%s [%d/%d/%d]", CI:GetSpecializationName(class, spec2), y1, y2, y3), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b})
                        elseif (not spec1) then
                            tinsert(linesToAdd, {string.format("Talents:|cFF808080 %s [%d/%d/%d]|r", CI:GetSpecializationName(class, spec2), y1, y2, y3)})
                        end
                    end
                end
            end
            local miniText = ""
            if (TacoTipConfig.show_gs_player) then
                local gearscore, avg_ilvl = GearScore:GetScore(guid, true)
                if (gearscore > 0) then
                    local r, g, b = GearScore:GetQuality(gearscore)
                    if (wide_style) then
                        if (r == b and r == g) then
                            tinsert(linesToAdd, {"|cFFFFFFFFGearScore:|r "..gearscore, "|cFFFFFFFF(iLvl:|r "..avg_ilvl.."|cFFFFFFFF)|r", r, g, b, r, g, b})
                        else
                            tinsert(linesToAdd, {"GearScore: "..gearscore, "(iLvl: "..avg_ilvl..")", r, g, b, r, g, b})
                        end
                    elseif (mini_style) then
                        if (r == b and r == g) then
                            miniText = string.format("GS: |cFF%02x%02x%02x%s|r  L: |cFF%02x%02x%02x%s|r  ", r*255, g*255, b*255, gearscore, r*255, g*255, b*255, avg_ilvl)
                        else
                            miniText = string.format("|cFF%02x%02x%02xGS: %s  L: %s|r  ", r*255, g*255, b*255, gearscore, avg_ilvl)
                        end
                    else
                        if (r == b and r == g) then
                            tinsert(linesToAdd, {"|cFFFFFFFFGearScore:|r "..gearscore, r, g, b})
                        else
                            tinsert(linesToAdd, {"GearScore: "..gearscore, r, g, b})
                        end
                    end
                end
            end
            if (isPawnLoaded and TacoTipConfig.show_pawn_player) then
                local pawnScore, specName, specColor = TT_PAWN:GetScore(guid, not TacoTipConfig.show_gs_player)
                if (pawnScore > 0) then
                    if (wide_style) then
                        tinsert(linesToAdd, {string.format("Pawn: %s%.2f|r", specColor, pawnScore), string.format("%s(%s)|r", specColor, specName), 1, 1, 1, 1, 1, 1})
                    elseif (mini_style) then
                        miniText = miniText .. string.format("P: %s%.1f|r", specColor, pawnScore)
                    else
                        tinsert(linesToAdd, {string.format("Pawn: %s%.2f (%s)|r", specColor, pawnScore, specName), 1, 1, 1})
                    end
                end
            end
            if (miniText ~= "") then
                tinsert(linesToAdd, {miniText, 1, 1, 1})
            end
        end
    end

    if (TacoTipConfig.show_pvp_icon and UnitIsPVP(unit)) then
        text[1] = text[1].." "..PVP_FLAG_ICON
        for i=2,numLines do
            if (text[i]) then
                text[i] = string.gsub(text[i], "PvP", "", 1)
            end
        end
    end

    local n = 0
    for i=1,numLines do
        if (text[i] and text[i] ~= "") then
            n = n+1
            _G["GameTooltipTextLeft"..n]:SetText(text[i])
        end
    end
    if (wide_style) then
        local anchor = "GameTooltipTextLeft"..n
        while (n < numLines) do
            n = n + 1
            _G["GameTooltipTextLeft"..n]:SetText()
            _G["GameTooltipTextRight"..n]:SetText()
            _G["GameTooltipTextLeft"..n]:Hide()
            _G["GameTooltipTextRight"..n]:Hide()
        end
        for _,v in ipairs(linesToAdd) do
            self:AddDoubleLine(unpack(v))
        end
        if (_G["GameTooltipTextLeft"..(n+1)]) then
            _G["GameTooltipTextLeft"..(n+1)]:SetPoint("TOP", _G[anchor], "BOTTOM", 0, -2)
        end
    else
        for _,v in ipairs(linesToAdd) do
            if (n < numLines) then
                n = n+1
                local txt, r, g, b = unpack(v)
                _G["GameTooltipTextLeft"..n]:SetTextColor(r or NORMAL_FONT_COLOR.r, g or NORMAL_FONT_COLOR.g, b or NORMAL_FONT_COLOR.b)
                _G["GameTooltipTextLeft"..n]:SetText(txt)
            else
                self:AddLine(unpack(v))
            end
        end
        while (n < numLines) do
            n = n + 1
            _G["GameTooltipTextLeft"..n]:SetText()
            _G["GameTooltipTextRight"..n]:SetText()
            _G["GameTooltipTextLeft"..n]:Hide()
            _G["GameTooltipTextRight"..n]:Hide()
        end
    end

    if (not TacoTipConfig.show_hp_bar and GameTooltipStatusBar and GameTooltipStatusBar:IsShown()) then
        GameTooltipStatusBar:Hide()
    end

    if (TacoTipConfig.show_power_bar) then
        if (not TacoTipPowerBar) then
            TacoTipPowerBar = CreateFrame("StatusBar", "TacoTipPowerBar", GameTooltip)
            TacoTipPowerBar:SetSize(0, 8)
            TacoTipPowerBar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 2, -9)
            TacoTipPowerBar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -2, -9)
            TacoTipPowerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
            TacoTipPowerBar:SetStatusBarColor(0, 0, 1)
            function TacoTipPowerBar:Update(u)
                if (TacoTipConfig.show_power_bar) then
                    local unit = u or select(2, GameTooltip:GetUnit())
                    if (unit) then
                        local _, power = UnitPowerType(unit)
                        local color = power and PowerBarColor[power] or {}
                        self:SetStatusBarColor(color.r or 0, color.g or 0, color.b or 1);
                        self:SetMinMaxValues(0, UnitPowerMax(unit))
                        self:SetValue(UnitPower(unit))
                    end
                end
            end
            TacoTipPowerBar:SetScript("OnEvent", function(self, event, unit)
                local _, ttUnit = GameTooltip:GetUnit()
                if (unit and ttUnit and UnitIsUnit(unit, ttUnit)) then
                    self:Update(unit)
                end
            end)
            TacoTipPowerBar:RegisterEvent("UNIT_POWER_UPDATE")
            TacoTipPowerBar:RegisterEvent("UNIT_MAXPOWER")
            TacoTipPowerBar:RegisterEvent("UNIT_DISPLAYPOWER")
            TacoTipPowerBar:RegisterEvent("UNIT_POWER_BAR_SHOW")
            TacoTipPowerBar:RegisterEvent("UNIT_POWER_BAR_HIDE")
            TacoTipPowerBar.updateTicker = NewTicker(POWERBAR_UPDATE_RATE, function()
                TacoTipPowerBar:Update()
            end)
        end
        if (UnitPowerMax(unit) > 0) then
            if (TacoTipConfig.show_hp_bar) then
                TacoTipPowerBar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 2, -9)
                TacoTipPowerBar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -2, -9)
            else
                TacoTipPowerBar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 2, -1)
                TacoTipPowerBar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -2, -1)
            end
            TacoTipPowerBar:Update()
            TacoTipPowerBar:Show()
        else
            TacoTipPowerBar:Hide()
        end
    elseif (TacoTipPowerBar) then
        TacoTipPowerBar:Hide()
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
            local gs, r, g, b = GearScore:GetItemScore(itemLink)
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

hooksecurefunc("GameTooltip_SetDefaultAnchor", function(self)
    if (TacoTipConfig.custom_pos) then
        self:SetOwner(TacoTipDragButton,"ANCHOR_NONE")
        self:ClearAllPoints(true)
        self:SetPoint(TacoTipConfig.custom_anchor or "TOPLEFT", TacoTipDragButton, "CENTER")
    elseif (TacoTipConfig.show_hp_bar and TacoTipConfig.show_power_bar) then
        self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -CONTAINER_OFFSET_X-13, CONTAINER_OFFSET_Y+9)
    end
end)

GameTooltipStatusBar:HookScript("OnHide", function(self)
    if (TacoTipPowerBar) then
        TacoTipPowerBar:Hide()
    end
end)

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

local function RefreshCharacterFrame()
    local MyGearScore, MyAverageScore, r, g, b = 0,0,0,0,0
    if (TacoTipConfig.show_gs_character or TacoTipConfig.show_avg_ilvl) then
        MyGearScore, MyAverageScore = GearScore:GetScore("player")
        r, g, b = GearScore:GetQuality(MyGearScore)
    end
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
end

PaperDollFrame:HookScript("OnShow", function()
    RefreshCharacterFrame()
end)

local function RefreshInspectFrame()
    if (not InCombatLockdown() and (TacoTipConfig.show_gs_character or TacoTipConfig.show_avg_ilvl)) then
        local inspect_gs, inspect_avg = GearScore:GetScore(InspectFrame.unit)
        local r, g, b = GearScore:GetQuality(inspect_gs)
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
    local text1 = InspectModelFrame:CreateFontString("InspectGearScore")
    text1:SetFont("Fonts\\FRIZQT__.TTF", 10)
    text1:SetText("0")
    text1:SetPoint("BOTTOMLEFT",InspectPaperDollFrame,"TOPLEFT",72,-359)

    local text2 = InspectModelFrame:CreateFontString("InspectGearScoreText")
    text2:SetFont("Fonts\\FRIZQT__.TTF", 10)
    text2:SetText("GearScore")
    text2:SetPoint("BOTTOMLEFT",InspectPaperDollFrame,"TOPLEFT",72,-372)

    local text3 = InspectModelFrame:CreateFontString("InspectAvgItemLvl")
    text3:SetFont("Fonts\\FRIZQT__.TTF", 10)
    text3:SetText("0")
    text3:SetPoint("BOTTOMLEFT",InspectPaperDollFrame,"TOPLEFT",270,-359)

    local text4 = InspectModelFrame:CreateFontString("InspectAvgItemLvlText")
    text4:SetFont("Fonts\\FRIZQT__.TTF", 10)
    text4:SetText("iLvl")
    text4:SetPoint("BOTTOMLEFT",InspectPaperDollFrame,"TOPLEFT",270,-372)

    InspectPaperDollFrame:HookScript("OnShow", RefreshInspectFrame)
    InspectFrame:HookScript("OnHide", function()
        InspectGearScore:Hide()
        InspectAvgItemLvl:Hide()
    end)
end

local function onEvent(self, event, ...)
    if (event == "PLAYER_EQUIPMENT_CHANGED") then
        if (PaperDollFrame:IsShown()) then
            RefreshCharacterFrame()
        end
    elseif (event == "MODIFIER_STATE_CHANGED") then
        local _, unit = GameTooltip:GetUnit()
        if (unit and UnitIsPlayer(unit)) then
            GameTooltip:SetUnit(unit)
        end
    elseif (event == "UNIT_TARGET") then
        local unit = ...
        if (unit) then
            local _, ttUnit = GameTooltip:GetUnit()
            if (ttUnit and UnitIsUnit(unit, ttUnit)) then
                GameTooltip:SetUnit(unit)
            end
        end
    elseif (event == "ADDON_LOADED") then
        local addon = ...
        if (addon == addOnName) then
            self:UnregisterEvent("ADDON_LOADED")
            if (TacoTipConfig.custom_pos) then
                TacoTip_CustomPosEnable(false)
            end
            if (TacoTipConfig.instant_fade) then
                self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
                Detours:DetourHook(_G[addOnName], GameTooltip, "FadeOut", function(self)
                    self:Hide()
                end)
            end
        end
    elseif (event == "UPDATE_MOUSEOVER_UNIT") then
        if (GameTooltip:GetUnit()) then
            CAfter(0, function()
                if (not UnitExists("mouseover")) then
                    GameTooltip:Hide()
                end
            end)
        end
    else -- INVENTORY_READY / TALENTS_READY
        local guid = ...
        if (guid) then
            local _, ttUnit = GameTooltip:GetUnit()
            if (ttUnit and UnitGUID(ttUnit) == guid) then
                GameTooltip:SetUnit(ttUnit)
            end
            if (event == "INVENTORY_READY") then
                if (not inspect_init) then
                    if (InspectFrame and InspectModelFrame and InspectPaperDollFrame) then
                        InitInspectFrame()
                    end
                elseif (InspectFrame and InspectFrame:IsShown()) then
                    RefreshInspectFrame()
                end
            end
        end
    end
end

do
    local f = CreateFrame("Frame")
    f:SetScript("OnEvent", onEvent)
    f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    f:RegisterEvent("MODIFIER_STATE_CHANGED")
    f:RegisterEvent("UNIT_TARGET")
    f:RegisterEvent("ADDON_LOADED")
    CI.RegisterCallback(addOnName, "INVENTORY_READY", function(...) onEvent(f, ...) end)
    CI.RegisterCallback(addOnName, "TALENTS_READY", function(...) onEvent(f, ...) end)
    _G[addOnName].frame = f
end

function TacoTip_CustomPosEnable(show)
    if (not TacoTipDragButton) then
        TacoTipDragButton = CreateFrame("Button", nil, UIParent)
        TacoTipDragButton:SetFrameStrata("TOOLTIP")
        TacoTipDragButton:SetFrameLevel(999)
        TacoTipDragButton:EnableMouse(true)
        TacoTipDragButton:SetMovable(true)
        TacoTipDragButton:SetUserPlaced(false)
        TacoTipDragButton:SetClampedToScreen(true)
        TacoTipDragButton:SetSize(32,32)
        TacoTipDragButton:SetNormalTexture("Interface\\MINIMAP\\TempleofKotmogu_ball_green")
        local pos = TacoTipConfig.custom_pos or {"TOPLEFT","TOPLEFT",0,0}
        TacoTipDragButton:SetPoint(pos[1],UIParent,pos[2],pos[3],pos[4])
        TacoTipDragButton:RegisterForDrag("LeftButton")
        TacoTipDragButton:RegisterForClicks("MiddleButtonUp", "RightButtonUp")
        TacoTipDragButton:SetScript("OnDragStart", TacoTipDragButton.StartMoving)
        TacoTipDragButton:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local from, _, to, x, y = self:GetPoint()
            TacoTipConfig.custom_pos = {from, to, x, y}
        end)
        TacoTipDragButton:SetScript("OnClick", function(self, button, down)
            if (button == "MiddleButton") then
                if (TacoTipConfig.custom_anchor == "TOPRIGHT") then
                    TacoTipConfig.custom_anchor = "BOTTOMRIGHT"
                elseif (TacoTipConfig.custom_anchor == "BOTTOMRIGHT") then
                    TacoTipConfig.custom_anchor = "BOTTOMLEFT"
                elseif (TacoTipConfig.custom_anchor == "BOTTOMLEFT") then
                    TacoTipConfig.custom_anchor = "CENTER"
                elseif (TacoTipConfig.custom_anchor == "CENTER") then
                    TacoTipConfig.custom_anchor = "TOPLEFT"
                else
                    TacoTipConfig.custom_anchor = "TOPRIGHT"
                end
                TacoTipDragButton:ShowExample()
            elseif (button == "RightButton") then
                StaticPopupDialogs["_TacoTipDragButtonConfirm_"] = {["whileDead"]=1,["hideOnEscape"]=1,["timeout"]=0,["exclusive"]=1,["enterClicksFirstButton"]=1,["text"]="\nDo you want to save custom tooltip position or reset back to default?\n\n",
                ["button1"]=SAVE,["button2"]=CANCEL,["button3"]=RESET,["OnAccept"]=function() TacoTipDragButton:_Save() end,["OnAlt"]=function() TacoTipDragButton:_Disable() end}
                StaticPopup_Show("_TacoTipDragButtonConfirm_")
            end
        end)
        TacoTipDragButton:SetScript("OnShow", function(self)
            if (self.ticker) then
                self.ticker:Cancel()
            end
            self.ticker = NewTicker(1, function()
                TacoTipDragButton:ShowExample()
            end)
            Detours:ScriptHook(_G[addOnName], GameTooltip, "OnShow", function(self)
                if (TacoTipDragButton:IsShown()) then
                    local name, unit = self:GetUnit()
                    if (not unit or not UnitIsUnit(unit, "player")) then
                        TacoTipDragButton:ShowExample()
                    end
                end
            end)
            Detours:ScriptHook(_G[addOnName], GameTooltip, "OnHide", function(self)
                if (TacoTipDragButton:IsShown()) then
                    TacoTipDragButton:ShowExample()
                end
            end)
            TacoTipDragButton:ShowExample()
            print("|cff59f0dcTacoTip:|r Mover is shown. Drag the yellow dot to move the tooltip. Middle-Click to change anchor. Right-Click to save.")
        end)
        TacoTipDragButton:SetScript("OnHide", function(self)
            if (self.ticker) then
                self.ticker:Cancel()
            end
            Detours:ScriptUnhook(_G[addOnName], GameTooltip, "OnShow")
            Detours:ScriptUnhook(_G[addOnName], GameTooltip, "OnHide")
        end)
        function TacoTipDragButton:ShowExample()
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
            GameTooltip:SetUnit("player")
            GameTooltip:AddDoubleLine("Left-Click", "Drag to Move", 1, 1, 1)
            GameTooltip:AddDoubleLine("Middle-Click", "Change Anchor", 1, 1, 1)
            GameTooltip:AddDoubleLine("Right-Click", "Save Position", 1, 1, 1)
            GameTooltip:Show()
        end
        function TacoTipDragButton:_Enable()
            if (not TacoTipConfig.custom_pos) then
                local from, _, to, x, y = TacoTipDragButton:GetPoint()
                TacoTipConfig.custom_pos = {from, to, x, y}
                print("|cff59f0dcTacoTip:|r Custom tooltip position enabled.")
            end
            if (TacoTipOptCheckBoxCustomPosition) then
                TacoTipOptCheckBoxCustomPosition:SetChecked(true)
            end
            if (TacoTipOptButtonMover) then
                TacoTipOptButtonMover:SetEnabled(true)
            end
        end
        function TacoTipDragButton:_Save()
            TacoTipDragButton:Hide()
            print("|cff59f0dcTacoTip:|r Custom tooltip position saved. Mover hidden. Type '/tacotip custom' to show mover again.")
        end
        function TacoTipDragButton:_Disable()
            TacoTipDragButton:Hide()
            GameTooltip:Hide()
            GameTooltip:ClearAllPoints()
            if (TacoTipConfig.custom_pos) then
                print("|cff59f0dcTacoTip:|r Custom tooltip position disabled. Tooltip position back to default.")
            end
            if (TacoTipOptCheckBoxCustomPosition) then
                TacoTipOptCheckBoxCustomPosition:SetChecked(false)
            end
            if (TacoTipOptButtonMover) then
                TacoTipOptButtonMover:SetEnabled(false)
            end
            TacoTipConfig.custom_pos = nil
            TacoTipConfig.custom_anchor = nil
        end
        TacoTipDragButton:Hide()
    end
    TacoTipDragButton:_Enable()
    if (show) then
        TacoTipDragButton:Show()
    else
        TacoTipDragButton:Hide()
    end
end
