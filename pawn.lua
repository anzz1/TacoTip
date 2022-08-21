--[[

    TacoTip Pawn Score module by kebabstorm
    for Classic/TBC/WOTLK
    
    Requires: Pawn 2.5.38+

--]]

local clientVersionString = GetBuildInfo()
local clientBuildMajor = string.byte(clientVersionString, 1)
-- load only on classic/tbc/wotlk
if (clientBuildMajor < 49 or clientBuildMajor > 51 or string.byte(clientVersionString, 2) ~= 46) then
    return
end

local isPawnLoaded = PawnClassicLastUpdatedVersion and PawnClassicLastUpdatedVersion >= 2.0538

if (not isPawnLoaded) then
    return
end

assert(LibStub, "TacoTip requires LibStub")
assert(LibStub:GetLibrary("LibClassicInspector", true), "TacoTip requires LibClassicInspector")

local CI = LibStub("LibClassicInspector")

local GUIDIsPlayer = C_PlayerInfo.GUIDIsPlayer

TT_PAWN = {}

local function getPlayerGUID(arg)
    if (arg) then
        if (GUIDIsPlayer(arg)) then
            return arg
        elseif (UnitIsPlayer(arg)) then
            return UnitGUID(arg)
        end
    end
    return nil
end

function TT_PAWN:GetItemScore(itemLink, class, specIndex)
    if (itemLink and class and specIndex) then
        local item = PawnGetItemData(itemLink)
        if (item) then
            return tonumber(select(2,PawnGetSingleValueFromItem(item,"\"Classic\":"..class..specIndex))) or 0
        end
    end
    return 0
end

local function itemcacheCB(tbl, id)
    for i=1,#tbl.items do
        if (id == tbl.items[i]) then
            table.remove(tbl.items, i)
        end
    end
    if (#tbl.items == 0) then
        TacoTip_GSCallback(tbl.guid)
    end
end


function TT_PAWN:GetScore(unitorguid, useCallback)
    local guid = getPlayerGUID(unitorguid)
    if (guid) then
        if (guid ~= UnitGUID("player")) then
            local _, invTime = CI:GetLastCacheTime(guid)
            if(invTime == 0) then
                return 0, "", "|cffffffff"
            end
        end

        local spec = CI:GetSpecialization(guid)
        local _, class = GetPlayerInfoByGUID(guid)
        local pawnScore = 0
        local IsReady = true

        if (spec and class) then
            local scaleName = "\"Classic\":"..class..spec
            local cb_table
            
            if (useCallback) then
                cb_table = {["guid"] = guid, ["items"] = {}}
            end
    
            for i = 1, 18 do
                if (i ~= 4) then
                    local item = CI:GetInventoryItemMixin(guid, i)
                    if (item) then
                        if (item:IsItemDataCached()) then
                            local tempScore = TT_PAWN:GetItemScore(item:GetItemLink(),class,spec)
                            pawnScore = pawnScore + tempScore
                        else
                            IsReady = false
                            local itemID = item:GetItemID()
                            if (itemID) then
                                if (useCallback) then
                                    table.insert(cb_table.items, itemID)
                                    item:ContinueOnItemLoad(function()
                                        itemcacheCB(cb_table, itemID)
                                    end)
                                else
                                    C_Item.RequestLoadItemDataByID(itemID)
                                end
                            end
                        end
                    end
                end
            end
            if (not IsReady) then
                pawnScore = 0
            end
            return pawnScore, CI:GetSpecializationName(class, spec), PawnGetScaleColor(scaleName, true) or "|cffffffff"
        end
    end
    return 0, "", "|cffffffff"
end
