
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

--_G[addOnName] = {}

local CI = LibStub("LibClassicInspector")
local Detours = LibStub("LibDetours-1.0")
local GearScore = TT_GS
local L = TACOTIP_LOCALE
local TT = _G[addOnName]

local isPawnLoaded = PawnClassicLastUpdatedVersion and PawnClassicLastUpdatedVersion >= 2.0538

local HORDE_ICON = "|TInterface\\TargetingFrame\\UI-PVP-HORDE:16:16:-2:0:64:64:0:38:0:38|t"
local ALLIANCE_ICON = "|TInterface\\TargetingFrame\\UI-PVP-ALLIANCE:16:16:-2:0:64:64:0:38:0:38|t"
local PVP_FLAG_ICON = "|TInterface\\GossipFrame\\BattleMasterGossipIcon:0|t"
local ACHIEVEMENT_ICON = "|TInterface\\AchievementFrame\\UI-Achievement-TinyShield:18:18:0:0:20:20:0:12.5:0:12.5|t"

local POWERBAR_UPDATE_RATE = 0.2

local NewTicker = C_Timer.NewTicker
local CAfter = C_Timer.After

local playerClass = select(2, UnitClass("player"))

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

    local wide_style = (TT.db.profile.tip_style == 1 or ((TT.db.profile.tip_style == 2 or TT.db.profile.tip_style == 4) and IsModifierKeyDown()))
    local mini_style = (not wide_style and (TT.db.profile.tip_style == 4 or TT.db.profile.tip_style == 5))

    local text = {}
    local linesToAdd = {}

    local numLines = GameTooltip:NumLines()

    for i=1,numLines do
        text[i] = _G["GameTooltipTextLeft"..i]:GetText()
    end
    if (not text[1] or text[1] == "") then return end
    if (not text[2] or text[2] == "") then return end

    if (TT.db.profile.show_target and UnitIsConnected(unit) and not UnitIsUnit(unit, "player")) then
        local unitTarget = unit .. "target"
        local targetName = UnitName(unitTarget)

        if (targetName) then
            if (UnitIsUnit(unitTarget, unit)) then
                if (wide_style) then
                    tinsert(linesToAdd, {L["Target"]..":", L["Self"], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b})
                else
                    tinsert(linesToAdd, {L["Target"]..": |cFFFFFFFF"..L["Self"].."|r"})
                end
            elseif (UnitIsUnit(unitTarget, "player")) then
                if (wide_style) then
                    tinsert(linesToAdd, {L["Target"]..":", L["You"], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1, 1, 0})
                else
                    tinsert(linesToAdd, {L["Target"]..": |cFFFFFF00"..L["You"].."|r"})
                end
            elseif (UnitIsPlayer(unitTarget)) then
                local classc
                if (TT.db.profile.color_class) then
                    local _, targetClass = UnitClass(unitTarget)
                    if (targetClass) then
                        classc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[targetClass]
                    end
                end
                if (classc) then
                    if (wide_style) then
                        tinsert(linesToAdd, {L["Target"]..":", string.format("|cFF%02x%02x%02x%s|r (%s)", classc.r*255, classc.g*255, classc.b*255, targetName, L["Player"]), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b})
                    else
                        tinsert(linesToAdd, {string.format("%s: |cFF%02x%02x%02x%s|cFFFFFFFF (%s)|r", L["Target"], classc.r*255, classc.g*255, classc.b*255, targetName, L["Player"])})
                    end
                else
                    if (wide_style) then
                        tinsert(linesToAdd, {L["Target"]..":", targetName.." ("..L["Player"]..")", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b})
                    else
                        tinsert(linesToAdd, {L["Target"]..": |cFFFFFFFF"..targetName.." ("..L["Player"]..")|r"})
                    end
                end
            elseif (UnitIsUnit(unitTarget, "pet") or UnitIsOtherPlayersPet(unitTarget)) then
                if (wide_style) then
                    tinsert(linesToAdd, {L["Target"]..":", targetName.." ("..L["Pet"]..")", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b})
                else
                    tinsert(linesToAdd, {L["Target"]..": |cFFFFFFFF"..targetName.." ("..L["Pet"]..")|r"})
                end
            else
                if (wide_style) then
                    tinsert(linesToAdd, {L["Target"]..":", targetName, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b})
                else
                    tinsert(linesToAdd, {L["Target"]..": |cFFFFFFFF"..targetName.."|r"})
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
                    tinsert(linesToAdd, {L["Target"]..":", L["None"], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b})
                else
                    tinsert(linesToAdd, {L["Target"]..": |cFF808080"..L["None"].."|r"})
                end
            end
        end
    end

    if (UnitIsPlayer(unit)) then
        local localizedClass, class = UnitClass(unit)

        if (not TT.db.profile.show_titles and string.find(text[1], name)) then
            text[1] = name
        end
        if (TT.db.profile.color_class) then
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
            if (TT.db.profile.show_guild_name) then
                if (TT.db.profile.show_guild_rank) then
                    if (TT.db.profile.guild_rank_alt_style) then
                        text[2] = string.gsub(text[2], guildName, string.format("|cFF40FB40<%s> (%s)|r", guildName, guildRankName), 1)
                    else
                        text[2] = string.gsub(text[2], guildName, string.format("|cFF40FB40"..L["FORMAT_GUILD_RANK_1"].."|r", guildRankName, guildName), 1)
                    end
                else
                    text[2] = string.gsub(text[2], guildName, string.format("|cFF40FB40<%s>|r", guildName), 1)
                end
            else
                text[2] = string.gsub(text[2], guildName, "", 1)
            end
        end
        if (TT.db.profile.show_team) then
            text[1] = text[1].." "..(UnitFactionGroup(unit) == "Horde" and HORDE_ICON or ALLIANCE_ICON)
        end

        if (not TT.db.profile.hide_in_combat or not InCombatLockdown()) then
            if (TT.db.profile.show_talents) then
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
                            tinsert(linesToAdd, {L["Talents"]..":", string.format("%s [%d/%d/%d]", CI:GetSpecializationName(class, spec2, true), y1, y2, y3), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b})
                        else
                            tinsert(linesToAdd, {string.format("%s:|cFFFFFFFF %s [%d/%d/%d]|r", L["Talents"], CI:GetSpecializationName(class, spec2, true), y1, y2, y3)})
                        end
                    end
                    if (spec1) then
                        if (wide_style) then
                            tinsert(linesToAdd, {(spec2 and " " or L["Talents"]..":"), string.format("%s [%d/%d/%d]", CI:GetSpecializationName(class, spec1, true), x1, x2, x3), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b})
                        elseif (not spec2) then
                            tinsert(linesToAdd, {string.format("%s:|cFF808080 %s [%d/%d/%d]|r", L["Talents"], CI:GetSpecializationName(class, spec1, true), x1, x2, x3)})
                        end
                    end
                elseif (active == 1) then
                    if (spec1) then
                        if (wide_style) then
                            tinsert(linesToAdd, {L["Talents"]..":", string.format("%s [%d/%d/%d]", CI:GetSpecializationName(class, spec1, true), x1, x2, x3), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b})
                        else
                            tinsert(linesToAdd, {string.format("%s:|cFFFFFFFF %s [%d/%d/%d]|r", L["Talents"], CI:GetSpecializationName(class, spec1, true), x1, x2, x3)})
                        end
                    end
                    if (spec2) then
                        if (wide_style) then
                            tinsert(linesToAdd, {(spec1 and " " or L["Talents"]..":"), string.format("%s [%d/%d/%d]", CI:GetSpecializationName(class, spec2, true), y1, y2, y3), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b})
                        elseif (not spec1) then
                            tinsert(linesToAdd, {string.format("%s:|cFF808080 %s [%d/%d/%d]|r", L["Talents"], CI:GetSpecializationName(class, spec2, true), y1, y2, y3)})
                        end
                    end
                end
            end
            local miniText = ""
            if (TT.db.profile.show_gs_player) then
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
            if (isPawnLoaded and TT.db.profile.show_pawn_player) then
                local pawnScore, specName, specColor = TT_PAWN:GetScore(guid, not TT.db.profile.show_gs_player)
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
            if (CI:IsWotlk() and TT.db.profile.show_achievement_points) then
                local achi_pts = CI:GetTotalAchievementPoints(guid)
                if (achi_pts) then
                    if (wide_style) then
                        tinsert(linesToAdd, {ACHIEVEMENT_ICON.." "..achi_pts, " ", 1, 1, 1, 1, 1, 1})
                    else
                        tinsert(linesToAdd, {ACHIEVEMENT_ICON.." "..achi_pts, 1, 1, 1})
                    end
                end
            end
        end
    end

    if (TT.db.profile.show_pvp_icon and UnitIsPVP(unit)) then
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

    if (not TT.db.profile.show_hp_bar and GameTooltipStatusBar and GameTooltipStatusBar:IsShown()) then
        GameTooltipStatusBar:Hide()
    end

    if (TT.db.profile.show_power_bar) then
        if (not TacoTipPowerBar) then
            TacoTipPowerBar = CreateFrame("StatusBar", "TacoTipPowerBar", GameTooltip)
            TacoTipPowerBar:SetSize(0, 8)
            TacoTipPowerBar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 2, -9)
            TacoTipPowerBar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -2, -9)
            TacoTipPowerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
            TacoTipPowerBar:SetStatusBarColor(0, 0, 1)
            function TacoTipPowerBar:Update(u)
                if (TT.db.profile.show_power_bar) then
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
            if (TT.db.profile.show_hp_bar) then
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
        if (TT.db.profile.show_item_level) then
            local ilvl = select(4, GetItemInfo(itemLink))
            if (ilvl and ilvl > 1) then
                self:AddLine(L["Item Level"].." "..ilvl, 1, 1, 1)
            end
        end
        if (TT.db.profile.show_gs_items) then
            local gs, _, r, g, b = GearScore:GetItemScore(itemLink)
            if (gs and gs > 1) then
                self:AddLine("GearScore: "..gs, r, g, b)
                if (TT.db.profile.show_gs_items_hs or IsModifierKeyDown() or playerClass == "HUNTER" or
                    (InspectFrame and InspectFrame:IsShown() and InspectFrame.unit and select(2, UnitClass(InspectFrame.unit)) == "HUNTER")) then
                    local hs, _, r, g, b = GearScore:GetItemHunterScore(itemLink)
                    if (gs ~= hs) then
                        self:AddLine("HunterScore: "..hs, r, g, b)
                    end
                end
            end
        end
    end
end

GameTooltip:HookScript("OnTooltipSetItem", itemToolTipHook)
ShoppingTooltip1:HookScript("OnTooltipSetItem", itemToolTipHook)
ShoppingTooltip2:HookScript("OnTooltipSetItem", itemToolTipHook)
ItemRefTooltip:HookScript("OnTooltipSetItem", itemToolTipHook)

local function CreateMouseAnchor()
    TacoTipMouseAnchor = CreateFrame("Frame", nil, UIParent)
    TacoTipMouseAnchor:EnableMouse(false)
    TacoTipMouseAnchor:SetMovable(true)
    TacoTipMouseAnchor:SetUserPlaced(false)
    TacoTipMouseAnchor:SetClampedToScreen(true)
    TacoTipMouseAnchor:SetSize(1,1)
    TacoTipMouseAnchor:SetPoint("CENTER",UIParent,"BOTTOMLEFT",0,0)
    TacoTipMouseAnchor:SetScript("OnUpdate", function(self)
        GameTooltip:SetScale(TT.db.profile.scale)
        local cx, cy = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        TacoTipMouseAnchor:SetPoint("CENTER",UIParent,"BOTTOMLEFT",cx/scale,cy/scale)
    end)
end

hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
    if (TT.db.profile.anchor_mouse_spells) then
        local parentparent = parent and parent:GetParent()
        if (parent.action or parent.spellId or (parentparent and parentparent.action) or (parentparent and parentparent.spellId)) then
            if (parentparent == MultiBarBottomRight or parentparent == MultiBarRight or parentparent == MultiBarLeft) then
                tooltip:SetOwner(parent, "ANCHOR_LEFT")
            else
                tooltip:SetOwner(parent, "ANCHOR_RIGHT")
            end
            return
        end
    end
    if (TT.db.profile.anchor_mouse) then
        if (not TT.db.profile.anchor_mouse_world or GetMouseFocus() == WorldFrame) then
            if (not TacoTipMouseAnchor) then
                CreateMouseAnchor()
                CreateMouseAnchor = nil
            end
            tooltip:SetOwner(TacoTipMouseAnchor,"ANCHOR_NONE")
            tooltip:ClearAllPoints(true)
            tooltip:SetPoint("BOTTOMLEFT", TacoTipMouseAnchor, "CENTER", 10, 10)
        end
    else
        if (TT.db.profile.custom_pos) then
            tooltip:SetOwner(TacoTipDragButton,"ANCHOR_NONE")
            tooltip:ClearAllPoints(true)
            tooltip:SetPoint(TT.db.profile.custom_anchor or "TOPLEFT", TacoTipDragButton, "CENTER")
        elseif (TT.db.profile.show_hp_bar and TT.db.profile.show_power_bar) then
            tooltip:SetPoint("BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -CONTAINER_OFFSET_X-13, CONTAINER_OFFSET_Y+9)
        end
    end
end)

GameTooltipStatusBar:HookScript("OnHide", function(self)
    if (TacoTipPowerBar) then
        TacoTipPowerBar:Hide()
    end
end)

local function CreateMover(parent, topkek, bottomright, callbackFunc)
    local mover = CreateFrame("Button", nil, parent)
    mover:SetFrameStrata("TOOLTIP")
    mover:SetFrameLevel(999)
    mover:EnableMouse(true)
    mover:SetMovable(true)
    mover:SetUserPlaced(false)
    mover:SetClampedToScreen(true)
    mover:SetPoint("TOPLEFT",topkek,"TOPLEFT")
    mover:SetPoint("BOTTOMRIGHT",bottomright,"BOTTOMRIGHT")
    mover:RegisterForDrag("LeftButton")
    mover:SetScript("OnDragStart", function(self)
        self:StartMoving()
        self:SetScript("OnUpdate", function(self)
            local cx, cy = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            local fx, fy = parent:GetRect()
            callbackFunc(cx/scale-fx, cy/scale-fy)
        end)
    end)
    mover:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetScript("OnUpdate", nil)
        mover:ClearAllPoints()
        mover:SetPoint("TOPLEFT",topkek,"TOPLEFT")
        mover:SetPoint("BOTTOMRIGHT",bottomright,"BOTTOMRIGHT")
    end)
    return mover
end

function TT:InitCharacterFrame()
    CharacterModelFrame:CreateFontString("PersonalGearScore")
    PersonalGearScore:SetFont(L["CHARACTER_FRAME_GS_VALUE_FONT"], L["CHARACTER_FRAME_GS_VALUE_FONT_SIZE"])
    PersonalGearScore:SetText("0")
    PersonalGearScore.RefreshPosition = function()
        PersonalGearScore:SetPoint("BOTTOMLEFT",PaperDollFrame,"BOTTOMLEFT",L["CHARACTER_FRAME_GS_VALUE_XPOS"] + (TT.db.profile.character_gs_offset_x or 0),L["CHARACTER_FRAME_GS_VALUE_YPOS"] + (TT.db.profile.character_gs_offset_y or 0))
    end
    PersonalGearScore:RefreshPosition()

    CharacterModelFrame:CreateFontString("PersonalGearScoreText")
    PersonalGearScoreText:SetFont(L["CHARACTER_FRAME_GS_TITLE_FONT"], L["CHARACTER_FRAME_GS_TITLE_FONT_SIZE"])
    PersonalGearScoreText:SetText("GearScore")
    PersonalGearScoreText.RefreshPosition = function()
        PersonalGearScoreText:SetPoint("BOTTOMLEFT",PaperDollFrame,"BOTTOMLEFT",L["CHARACTER_FRAME_GS_TITLE_XPOS"] + (TT.db.profile.character_gs_offset_x or 0),L["CHARACTER_FRAME_GS_TITLE_YPOS"] + (TT.db.profile.character_gs_offset_y or 0))
    end
    PersonalGearScoreText:RefreshPosition()

    CharacterModelFrame:CreateFontString("PersonalAvgItemLvl")
    PersonalAvgItemLvl:SetFont(L["CHARACTER_FRAME_ILVL_VALUE_FONT"], L["CHARACTER_FRAME_ILVL_VALUE_FONT_SIZE"])
    PersonalAvgItemLvl:SetText("0")
    PersonalAvgItemLvl.RefreshPosition = function()
        PersonalAvgItemLvl:SetPoint("BOTTOMLEFT",PaperDollFrame,"BOTTOMLEFT",L["CHARACTER_FRAME_ILVL_VALUE_XPOS"] + (TT.db.profile.character_ilvl_offset_x or 0),L["CHARACTER_FRAME_ILVL_VALUE_YPOS"] + (TT.db.profile.character_ilvl_offset_y or 0))
    end
    PersonalAvgItemLvl:RefreshPosition()

    CharacterModelFrame:CreateFontString("PersonalAvgItemLvlText")
    PersonalAvgItemLvlText:SetFont(L["CHARACTER_FRAME_ILVL_TITLE_FONT"], L["CHARACTER_FRAME_ILVL_TITLE_FONT_SIZE"])
    PersonalAvgItemLvlText:SetText("iLvl")
    PersonalAvgItemLvlText.RefreshPosition = function()
        PersonalAvgItemLvlText:SetPoint("BOTTOMLEFT",PaperDollFrame,"BOTTOMLEFT",L["CHARACTER_FRAME_ILVL_TITLE_XPOS"] + (TT.db.profile.character_ilvl_offset_x or 0),L["CHARACTER_FRAME_ILVL_TITLE_YPOS"] + (TT.db.profile.character_ilvl_offset_y or 0))
    end
    PersonalAvgItemLvlText:RefreshPosition()

    PaperDollFrame:HookScript("OnShow", TT.RefreshCharacterFrame)
end

function TT:RefreshCharacterFrame()
    if (TT.InitCharacterFrame) then
        TT:InitCharacterFrame()
        TT.InitCharacterFrame = nil
    end
    local MyGearScore, MyAverageScore, r, g, b = 0,0,0,0,0
    if (TT.db.profile.show_gs_character or TT.db.profile.show_avg_ilvl) then
        MyGearScore, MyAverageScore = GearScore:GetScore("player")
        r, g, b = GearScore:GetQuality(MyGearScore)
    end
    if (TT.db.profile.show_gs_character) then
        PersonalGearScore:SetText(MyGearScore);
        PersonalGearScore:SetTextColor(r, g, b, 1)
        PersonalGearScore:Show()
        PersonalGearScoreText:Show()
        if (TT.db.profile.unlock_info_position) then
            if (not PersonalGearScoreText.mover) then
                PersonalGearScoreText.mover = CreateMover(PaperDollFrame, PersonalGearScore, PersonalGearScoreText, function(ofx, ofy)
                    TT.db.profile.character_gs_offset_x = ofx-L["CHARACTER_FRAME_GS_TITLE_XPOS"]
                    TT.db.profile.character_gs_offset_y = ofy-L["CHARACTER_FRAME_GS_TITLE_YPOS"]
                    PersonalGearScore:RefreshPosition()
                    PersonalGearScoreText:RefreshPosition()
                end)
            end
            PersonalGearScoreText.mover:Show()
        elseif (PersonalGearScoreText.mover) then
            PersonalGearScoreText.mover:Hide()
        end
    else
        PersonalGearScore:Hide()
        PersonalGearScoreText:Hide()
        if (PersonalGearScoreText.mover) then
            PersonalGearScoreText.mover:Hide()
        end
    end
    if (TT.db.profile.show_avg_ilvl) then
        PersonalAvgItemLvl:SetText(MyAverageScore);
        PersonalAvgItemLvl:SetTextColor(r, g, b, 1)
        PersonalAvgItemLvl:Show()
        PersonalAvgItemLvlText:Show()
        if (TT.db.profile.unlock_info_position) then
            if (not PersonalAvgItemLvlText.mover) then
                PersonalAvgItemLvlText.mover = CreateMover(PaperDollFrame, PersonalAvgItemLvl, PersonalAvgItemLvlText, function(ofx, ofy)
                    TT.db.profile.character_ilvl_offset_x = ofx-L["CHARACTER_FRAME_ILVL_TITLE_XPOS"]
                    TT.db.profile.character_ilvl_offset_y = ofy-L["CHARACTER_FRAME_ILVL_TITLE_YPOS"]
                    PersonalAvgItemLvl:RefreshPosition()
                    PersonalAvgItemLvlText:RefreshPosition()
                end)
            end
            PersonalAvgItemLvlText.mover:Show()
        elseif (PersonalAvgItemLvlText.mover) then
            PersonalAvgItemLvlText.mover:Hide()
        end
    else
        PersonalAvgItemLvl:Hide()
        PersonalAvgItemLvlText:Hide()
        if (PersonalAvgItemLvlText.mover) then
            PersonalAvgItemLvlText.mover:Hide()
        end
    end
end


function TT:InitInspectFrame()
    InspectModelFrame:CreateFontString("InspectGearScore")
    InspectGearScore:SetFont(L["INSPECT_FRAME_GS_VALUE_FONT"], L["INSPECT_FRAME_GS_VALUE_FONT_SIZE"])
    InspectGearScore:SetText("0")
    InspectGearScore.RefreshPosition = function()
        InspectGearScore:SetPoint("BOTTOMLEFT",InspectPaperDollFrame,"BOTTOMLEFT",L["INSPECT_FRAME_GS_VALUE_XPOS"] + (TT.db.profile.inspect_gs_offset_x or 0),L["INSPECT_FRAME_GS_VALUE_YPOS"] + (TT.db.profile.inspect_gs_offset_y or 0))
    end
    InspectGearScore:RefreshPosition()

    InspectModelFrame:CreateFontString("InspectGearScoreText")
    InspectGearScoreText:SetFont(L["INSPECT_FRAME_GS_TITLE_FONT"], L["INSPECT_FRAME_GS_TITLE_FONT_SIZE"])
    InspectGearScoreText:SetText("GearScore")
    InspectGearScoreText.RefreshPosition = function()
        InspectGearScoreText:SetPoint("BOTTOMLEFT",InspectPaperDollFrame,"BOTTOMLEFT",L["INSPECT_FRAME_GS_TITLE_XPOS"] + (TT.db.profile.inspect_gs_offset_x or 0),L["INSPECT_FRAME_GS_TITLE_YPOS"] + (TT.db.profile.inspect_gs_offset_y or 0))
    end
    InspectGearScoreText:RefreshPosition()

    InspectModelFrame:CreateFontString("InspectAvgItemLvl")
    InspectAvgItemLvl:SetFont(L["INSPECT_FRAME_ILVL_VALUE_FONT"], L["INSPECT_FRAME_ILVL_VALUE_FONT_SIZE"])
    InspectAvgItemLvl:SetText("0")
    InspectAvgItemLvl.RefreshPosition = function()
        InspectAvgItemLvl:SetPoint("BOTTOMLEFT",InspectPaperDollFrame,"BOTTOMLEFT",L["INSPECT_FRAME_ILVL_VALUE_XPOS"] + (TT.db.profile.inspect_ilvl_offset_x or 0),L["INSPECT_FRAME_ILVL_VALUE_YPOS"] + (TT.db.profile.inspect_ilvl_offset_y or 0))
    end
    InspectAvgItemLvl:RefreshPosition()

    InspectModelFrame:CreateFontString("InspectAvgItemLvlText")
    InspectAvgItemLvlText:SetFont(L["INSPECT_FRAME_ILVL_TITLE_FONT"], L["INSPECT_FRAME_ILVL_TITLE_FONT_SIZE"])
    InspectAvgItemLvlText:SetText("iLvl")
    InspectAvgItemLvlText.RefreshPosition = function()
        InspectAvgItemLvlText:SetPoint("BOTTOMLEFT",InspectPaperDollFrame,"BOTTOMLEFT",L["INSPECT_FRAME_ILVL_TITLE_XPOS"] + (TT.db.profile.inspect_ilvl_offset_x or 0),L["INSPECT_FRAME_ILVL_TITLE_YPOS"] + (TT.db.profile.inspect_ilvl_offset_y or 0))
    end
    InspectAvgItemLvlText:RefreshPosition()

    InspectPaperDollFrame:HookScript("OnShow", TT.RefreshInspectFrame)
    InspectFrame:HookScript("OnHide", function()
        InspectGearScore:Hide()
        InspectAvgItemLvl:Hide()
    end)
end

function TT:RefreshInspectFrame()
    if (InCombatLockdown()) then
        return
    end
    if (TT.InitInspectFrame) then
        if (not InspectModelFrame or not InspectPaperDollFrame) then
            return
        end
        TT:InitInspectFrame()
        TT.InitInspectFrame = nil
    end
    local inspect_gs, inspect_avg, r, g, b = 0,0,0,0,0
    if (TT.db.profile.show_gs_character or TT.db.profile.show_avg_ilvl) then
        inspect_gs, inspect_avg = GearScore:GetScore(InspectFrame.unit)
        r, g, b = GearScore:GetQuality(inspect_gs)
    end
    if (TT.db.profile.show_gs_character) then
        InspectGearScore:SetText(inspect_gs);
        InspectGearScore:SetTextColor(r, g, b, 1)
        InspectGearScore:Show()
        InspectGearScoreText:Show()
        if (TT.db.profile.unlock_info_position) then
            if (not InspectGearScoreText.mover) then
                InspectGearScoreText.mover = CreateMover(InspectPaperDollFrame, InspectGearScore, InspectGearScoreText, function(ofx, ofy)
                    TT.db.profile.inspect_gs_offset_x = ofx-L["INSPECT_FRAME_GS_TITLE_XPOS"]
                    TT.db.profile.inspect_gs_offset_y = ofy-L["INSPECT_FRAME_GS_TITLE_YPOS"]
                    InspectGearScore:RefreshPosition()
                    InspectGearScoreText:RefreshPosition()
                end)
            end
            InspectGearScoreText.mover:Show()
        elseif (InspectGearScoreText.mover) then
            InspectGearScoreText.mover:Hide()
        end
    else
        InspectGearScore:Hide()
        InspectGearScoreText:Hide()
        if (InspectGearScoreText.mover) then
            InspectGearScoreText.mover:Hide()
        end
    end
    if (TT.db.profile.show_avg_ilvl) then
        InspectAvgItemLvl:SetText(inspect_avg);
        InspectAvgItemLvl:SetTextColor(r, g, b, 1)
        InspectAvgItemLvl:Show()
        InspectAvgItemLvlText:Show()
        if (TT.db.profile.unlock_info_position) then
            if (not InspectAvgItemLvlText.mover) then
                InspectAvgItemLvlText.mover = CreateMover(InspectPaperDollFrame, InspectAvgItemLvl, InspectAvgItemLvlText, function(ofx, ofy)
                    TT.db.profile.inspect_ilvl_offset_x = ofx-L["INSPECT_FRAME_ILVL_TITLE_XPOS"]
                    TT.db.profile.inspect_ilvl_offset_y = ofy-L["INSPECT_FRAME_ILVL_TITLE_YPOS"]
                    InspectAvgItemLvl:RefreshPosition()
                    InspectAvgItemLvlText:RefreshPosition()
                end)
            end
            InspectAvgItemLvlText.mover:Show()
        elseif (InspectAvgItemLvlText.mover) then
            InspectAvgItemLvlText.mover:Hide()
        end
    else
        InspectAvgItemLvl:Hide()
        InspectAvgItemLvlText:Hide()
        if (InspectAvgItemLvlText.mover) then
            InspectAvgItemLvlText.mover:Hide()
        end
    end
end

local function onEvent(self, event, ...)
    if (event == "PLAYER_EQUIPMENT_CHANGED") then
        if (PaperDollFrame and PaperDollFrame:IsShown()) then
            TT:RefreshCharacterFrame()
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

            local AceConfig = LibStub("AceConfig-3.0")
            local AceConfigDialog = LibStub("AceConfigDialog-3.0")

            -- Create AceAddon configuration database
            TT.db = LibStub("AceDB-3.0"):New("TacoTipDB", TT.defaults, true)
            AceConfig:RegisterOptionsTable(addOnName.."_options", TT.options)
            TT.optionsFrame = AceConfigDialog:AddToBlizOptions(addOnName.."_options", addOnName)

            local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(TT.db)
            AceConfig:RegisterOptionsTable(addOnName.."_profiles", profiles)
            AceConfigDialog:AddToBlizOptions(addOnName.."_profiles", "Profiles", addOnName)

            -- Create and Show the Example Tooltip in the Addon Options Window
            TT.optionsFrame:HookScript("OnShow", function(frame)
                TT.exampleTooltip:Show()
            end)

            if (TT.db.profile.custom_pos) then
                TacoTip_CustomPosEnable(false)
            end
            if (TT.db.profile.instant_fade) then
                self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
                Detours:DetourHook(TT, GameTooltip, "FadeOut", function(self)
                    self:Hide()
                end)
            end
            if (CharacterModelFrame and PaperDollFrame) then
                TT:RefreshCharacterFrame()
            end
            CAfter(3, function()
                print("|cff59f0dcTacoTip v"..addOnVersion.." "..L["TEXT_HELP_WELCOME"])

                if (TT.db.profile.conf_version ~= addOnVersion) then
                    print("|cff59f0dcTacoTip:|r "..L["TEXT_HELP_FIRST_LOGIN"])
                    TT.db.profile.conf_version = addOnVersion
                end
            end)
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
        if (TT.InitInspectFrame and InspectModelFrame and InspectPaperDollFrame) then
            TT:InitInspectFrame()
            TT.InitInspectFrame = nil
        end
        local guid = ...
        if (guid) then
            local _, ttUnit = GameTooltip:GetUnit()
            if (ttUnit and UnitGUID(ttUnit) == guid) then
                GameTooltip:SetUnit(ttUnit)
            end
            if (event == "INVENTORY_READY") then
                if (InspectFrame and InspectFrame:IsShown()) then
                    TT:RefreshInspectFrame()
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
    TT.frame = f
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
        local pos = TT.db.profile.custom_pos or {"TOPLEFT","TOPLEFT",0,0}
        TacoTipDragButton:SetPoint(pos[1],UIParent,pos[2],pos[3],pos[4])
        TacoTipDragButton:RegisterForDrag("LeftButton")
        TacoTipDragButton:RegisterForClicks("MiddleButtonUp", "RightButtonUp")
        TacoTipDragButton:SetScript("OnDragStart", TacoTipDragButton.StartMoving)
        TacoTipDragButton:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local from, _, to, x, y = self:GetPoint()
            TT.db.profile.custom_pos = {from, to, x, y}
        end)
        TacoTipDragButton:SetScript("OnClick", function(self, button, down)
            if (button == "MiddleButton") then
                if (TT.db.profile.custom_anchor == "TOPRIGHT") then
                    TT.db.profile.custom_anchor = "BOTTOMRIGHT"
                elseif (TT.db.profile.custom_anchor == "BOTTOMRIGHT") then
                    TT.db.profile.custom_anchor = "BOTTOMLEFT"
                elseif (TT.db.profile.custom_anchor == "BOTTOMLEFT") then
                    TT.db.profile.custom_anchor = "CENTER"
                elseif (TT.db.profile.custom_anchor == "CENTER") then
                    TT.db.profile.custom_anchor = "TOPLEFT"
                else
                    TT.db.profile.custom_anchor = "TOPRIGHT"
                end
                TacoTipDragButton:ShowExample()
            elseif (button == "RightButton") then
                StaticPopupDialogs["_TacoTipDragButtonConfirm_"] = {["whileDead"]=1,["hideOnEscape"]=1,["timeout"]=0,["exclusive"]=1,["enterClicksFirstButton"]=1,["text"]=L["TEXT_DLG_CUSTOM_POS_CONFIRM"],
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
            Detours:ScriptHook(TT, GameTooltip, "OnShow", function(self)
                if (TacoTipDragButton:IsShown()) then
                    local name, unit = self:GetUnit()
                    if (not unit or not UnitIsUnit(unit, "player")) then
                        TacoTipDragButton:ShowExample()
                    end
                end
            end)
            Detours:ScriptHook(TT, GameTooltip, "OnHide", function(self)
                if (TacoTipDragButton:IsShown()) then
                    TacoTipDragButton:ShowExample()
                end
            end)
            TacoTipDragButton:ShowExample()
            print("|cff59f0dcTacoTip:|r "..L["TEXT_HELP_MOVER_SHOWN"])
        end)
        TacoTipDragButton:SetScript("OnHide", function(self)
            if (self.ticker) then
                self.ticker:Cancel()
            end
            Detours:ScriptUnhook(TT, GameTooltip, "OnShow")
            Detours:ScriptUnhook(TT, GameTooltip, "OnHide")
        end)
        function TacoTipDragButton:ShowExample()
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
            GameTooltip:SetUnit("player")
            GameTooltip:AddDoubleLine(L["Left-Click"], L["Drag to Move"], 1, 1, 1)
            GameTooltip:AddDoubleLine(L["Middle-Click"], L["Change Anchor"], 1, 1, 1)
            GameTooltip:AddDoubleLine(L["Right-Click"], L["Save Position"], 1, 1, 1)
            GameTooltip:Show()
        end
        function TacoTipDragButton:_Enable()
            if (not TT.db.profile.custom_pos) then
                local from, _, to, x, y = TacoTipDragButton:GetPoint()
                TT.db.profile.custom_pos = {from, to, x, y}
                print("|cff59f0dcTacoTip:|r "..L["Custom tooltip position enabled."])
            end
            if (TacoTipOptCheckBoxCustomPosition) then
                TacoTipOptCheckBoxCustomPosition:SetChecked(true)
            end
            if (TacoTipOptButtonMover) then
                TacoTipOptButtonMover:SetEnabled(true)
            end
            if (TacoTipOptCheckBoxAnchorMouse) then
                TacoTipOptCheckBoxAnchorMouse:SetChecked(false)
                TacoTipOptCheckBoxAnchorMouse:SetDisabled(true)
            end
            if (TacoTipOptCheckBoxAnchorMouseWorld) then
                TacoTipOptCheckBoxAnchorMouseWorld:SetDisabled(true)
            end
            TT.db.profile.anchor_mouse = false
        end
        function TacoTipDragButton:_Save()
            TacoTipDragButton:Hide()
            print("|cff59f0dcTacoTip:|r "..L["TEXT_HELP_MOVER_SAVED"])
        end
        function TacoTipDragButton:_Disable()
            TacoTipDragButton:Hide()
            GameTooltip:Hide()
            GameTooltip:ClearAllPoints()
            if (TT.db.profile.custom_pos) then
                print("|cff59f0dcTacoTip:|r "..L["Custom tooltip position disabled."])
            end
            if (TacoTipOptCheckBoxCustomPosition) then
                TacoTipOptCheckBoxCustomPosition:SetChecked(false)
            end
            if (TacoTipOptButtonMover) then
                TacoTipOptButtonMover:SetEnabled(false)
            end
            if (TacoTipOptCheckBoxAnchorMouse) then
                TacoTipOptCheckBoxAnchorMouse:SetDisabled(false)
            end
            TT.db.profile.custom_pos = nil
            TT.db.profile.custom_anchor = nil
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
