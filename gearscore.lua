--[[

    TacoTip GearScore module by kebabstorm
    for Classic/TBC/WOTLK

    Based on original GearScoreLite by Mirrikat45 & others

    Module is WIP and currently part of TacoTip, but it will be released as a public module on a later date

--]]

local clientVersionString = GetBuildInfo()
local clientBuildMajor = string.byte(clientVersionString, 1)
-- load only on classic/tbc/wotlk
if (clientBuildMajor < 49 or clientBuildMajor > 51 or string.byte(clientVersionString, 2) ~= 46) then
    return
end

assert(LibStub, "TacoTip requires LibStub")
assert(LibStub:GetLibrary("LibClassicInspector", true), "TacoTip requires LibClassicInspector")
assert(LibStub:GetLibrary("LibDetours-1.0", true), "TacoTip requires LibDetours-1.0")

local CI = LibStub("LibClassicInspector")

local GUIDIsPlayer = C_PlayerInfo.GUIDIsPlayer

TT_GS = {}

local BRACKET_SIZE = 1000

if (CI:IsWotlk()) then
    BRACKET_SIZE = 1000
elseif (CI:IsTBC()) then
    BRACKET_SIZE = 400
elseif (CI:IsClassic()) then
    BRACKET_SIZE = 200
end

local MAX_SCORE = BRACKET_SIZE*6-1

local GS_ItemTypes = {
    ["INVTYPE_RELIC"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false},
    ["INVTYPE_TRINKET"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 33, ["Enchantable"] = false },
    ["INVTYPE_2HWEAPON"] = { ["SlotMOD"] = 2.000, ["ItemSlot"] = 16, ["Enchantable"] = true },
    ["INVTYPE_WEAPONMAINHAND"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 16, ["Enchantable"] = true },
    ["INVTYPE_WEAPONOFFHAND"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = true },
    ["INVTYPE_RANGED"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = true },
    ["INVTYPE_THROWN"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false },
    ["INVTYPE_RANGEDRIGHT"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false },
    ["INVTYPE_SHIELD"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = true },
    ["INVTYPE_WEAPON"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 36, ["Enchantable"] = true },
    ["INVTYPE_HOLDABLE"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = false },
    ["INVTYPE_HEAD"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 1, ["Enchantable"] = true },
    ["INVTYPE_NECK"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 2, ["Enchantable"] = false },
    ["INVTYPE_SHOULDER"] = { ["SlotMOD"] = 0.7500, ["ItemSlot"] = 3, ["Enchantable"] = true },
    ["INVTYPE_CHEST"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 5, ["Enchantable"] = true },
    ["INVTYPE_ROBE"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 5, ["Enchantable"] = true },
    ["INVTYPE_WAIST"] = { ["SlotMOD"] = 0.7500, ["ItemSlot"] = 6, ["Enchantable"] = false },
    ["INVTYPE_LEGS"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 7, ["Enchantable"] = true },
    ["INVTYPE_FEET"] = { ["SlotMOD"] = 0.75, ["ItemSlot"] = 8, ["Enchantable"] = true },
    ["INVTYPE_WRIST"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 9, ["Enchantable"] = true },
    ["INVTYPE_HAND"] = { ["SlotMOD"] = 0.7500, ["ItemSlot"] = 10, ["Enchantable"] = true },
    ["INVTYPE_FINGER"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 31, ["Enchantable"] = false },
    ["INVTYPE_CLOAK"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 15, ["Enchantable"] = true },
    ["INVTYPE_BODY"] = { ["SlotMOD"] = 0, ["ItemSlot"] = 4, ["Enchantable"] = false },
}

local GS_Rarity = {
    [0] = {Red = 0.55, Green = 0.55, Blue = 0.55 },
    [1] = {Red = 1.00, Green = 1.00, Blue = 1.00 },
    [2] = {Red = 0.12, Green = 1.00, Blue = 0.00 },
    [3] = {Red = 0.00, Green = 0.50, Blue = 1.00 },
    [4] = {Red = 0.69, Green = 0.28, Blue = 0.97 },
    [5] = {Red = 0.94, Green = 0.09, Blue = 0.00 },
    [6] = {Red = 1.00, Green = 0.00, Blue = 0.00 },
    [7] = {Red = 0.90, Green = 0.80, Blue = 0.50 },
}

local GS_Formula = {
    ["A"] = {
        [4] = { ["A"] = 91.4500, ["B"] = 0.6500 },
        [3] = { ["A"] = 81.3750, ["B"] = 0.8125 },
        [2] = { ["A"] = 73.0000, ["B"] = 1.0000 }
    },
    ["B"] = {
        [4] = { ["A"] = 26.0000, ["B"] = 1.2000 },
        [3] = { ["A"] = 0.7500, ["B"] = 1.8000 },
        [2] = { ["A"] = 8.0000, ["B"] = 2.0000 },
        [1] = { ["A"] = 0.0000, ["B"] = 2.2500 }
    }
}

local GS_Quality = {
    [BRACKET_SIZE*6] = {
        ["Red"] = { ["A"] = 0.94, ["B"] = BRACKET_SIZE*5, ["C"] = 0.00006, ["D"] = 1 },
        ["Blue"] = { ["A"] = 0.47, ["B"] = BRACKET_SIZE*5, ["C"] = 0.00047, ["D"] = -1 },
        ["Green"] = { ["A"] = 0, ["B"] = 0, ["C"] = 0, ["D"] = 0 },
        ["Description"] = "Legendary"
    },
    [BRACKET_SIZE*5] = {
        ["Red"] = { ["A"] = 0.69, ["B"] = BRACKET_SIZE*4, ["C"] = 0.00025, ["D"] = 1 },
        ["Blue"] = { ["A"] = 0.28, ["B"] = BRACKET_SIZE*4, ["C"] = 0.00019, ["D"] = 1 },
        ["Green"] = { ["A"] = 0.97, ["B"] = BRACKET_SIZE*4, ["C"] = 0.00096, ["D"] = -1 },
        ["Description"] = "Epic"
    },
    [BRACKET_SIZE*4] = {
        ["Red"] = { ["A"] = 0.0, ["B"] = BRACKET_SIZE*3, ["C"] = 0.00069, ["D"] = 1 },
        ["Blue"] = { ["A"] = 0.5, ["B"] = BRACKET_SIZE*3, ["C"] = 0.00022, ["D"] = -1 },
        ["Green"] = { ["A"] = 1, ["B"] = BRACKET_SIZE*3, ["C"] = 0.00003, ["D"] = -1 },
        ["Description"] = "Superior"
    },
    [BRACKET_SIZE*3] = {
        ["Red"] = { ["A"] = 0.12, ["B"] = BRACKET_SIZE*2, ["C"] = 0.00012, ["D"] = -1 },
        ["Blue"] = { ["A"] = 1, ["B"] = BRACKET_SIZE*2, ["C"] = 0.00050, ["D"] = -1 },
        ["Green"] = { ["A"] = 0, ["B"] = BRACKET_SIZE*2, ["C"] = 0.001, ["D"] = 1 },
        ["Description"] = "Uncommon"
    },
    [BRACKET_SIZE*2] = {
        ["Red"] = { ["A"] = 1, ["B"] = BRACKET_SIZE, ["C"] = 0.00088, ["D"] = -1 },
        ["Blue"] = { ["A"] = 1, ["B"] = 000, ["C"] = 0.00000, ["D"] = 0 },
        ["Green"] = { ["A"] = 1, ["B"] = BRACKET_SIZE, ["C"] = 0.001, ["D"] = -1 },
        ["Description"] = "Common"
    },
    [BRACKET_SIZE] = {
        ["Red"] = { ["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1 },
        ["Blue"] = { ["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1 },
        ["Green"] = { ["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1 },
        ["Description"] = "Trash"
    },
}

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

function TT_GS:GetQuality(ItemScore)
    ItemScore = tonumber(ItemScore)
    if (not ItemScore) then
        return 0, 0, 0, "Trash"
    end
    --if (not CI:IsWotlk()) then
        --return 1, 1, 1, "Common"
    --end
    if (ItemScore > MAX_SCORE) then
        ItemScore = MAX_SCORE
    end
    local Red = 0.1
    local Blue = 0.1
    local Green = 0.1
    local GS_QualityDescription = "Legendary"
    for i = 0,6 do
        if ((ItemScore > i * BRACKET_SIZE) and (ItemScore <= ((i + 1) * BRACKET_SIZE))) then
            local Red = GS_Quality[( i + 1 ) * BRACKET_SIZE].Red["A"] + (((ItemScore - GS_Quality[( i + 1 ) * BRACKET_SIZE].Red["B"])*GS_Quality[( i + 1 ) * BRACKET_SIZE].Red["C"])*GS_Quality[( i + 1 ) * BRACKET_SIZE].Red["D"])
            local Blue = GS_Quality[( i + 1 ) * BRACKET_SIZE].Green["A"] + (((ItemScore - GS_Quality[( i + 1 ) * BRACKET_SIZE].Green["B"])*GS_Quality[( i + 1 ) * BRACKET_SIZE].Green["C"])*GS_Quality[( i + 1 ) * BRACKET_SIZE].Green["D"])
            local Green = GS_Quality[( i + 1 ) * BRACKET_SIZE].Blue["A"] + (((ItemScore - GS_Quality[( i + 1 ) * BRACKET_SIZE].Blue["B"])*GS_Quality[( i + 1 ) * BRACKET_SIZE].Blue["C"])*GS_Quality[( i + 1 ) * BRACKET_SIZE].Blue["D"])
            return Red, Green, Blue, GS_Quality[( i + 1 ) * BRACKET_SIZE].Description
        end
    end
    return 0.1, 0.1, 0.1, "Trash"
end


function TT_GS:GetItemScore(ItemLink)
    if not (ItemLink) then
        return 0, 0, 0.1, 0.1, 0.1
    end
    local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(ItemLink)
    if (ItemLink and ItemRarity and ItemLevel and ItemEquipLoc and GS_ItemTypes[ItemEquipLoc]) then
        local Table
        local QualityScale = 1
        local GearScore = 0
        local Scale = 1.8618
        if (ItemRarity == 5) then 
            QualityScale = 1.3
            ItemRarity = 4
        elseif (ItemRarity == 1) then
            QualityScale = 0.005
            ItemRarity = 2
        elseif (ItemRarity == 0) then
            QualityScale = 0.005
            ItemRarity = 2
        elseif (ItemRarity == 7) then
            ItemRarity = 3
            ItemLevel = 187.05
        end
        if (ItemLevel > 120) then
            Table = GS_Formula["A"]
        else
            Table = GS_Formula["B"]
        end
        if ((ItemRarity >= 2) and (ItemRarity <= 4)) then
            local Red, Green, Blue = TT_GS:GetQuality((floor(((ItemLevel - Table[ItemRarity].A) / Table[ItemRarity].B) * 1 * Scale)) * 11.25)
            GearScore = floor(((ItemLevel - Table[ItemRarity].A) / Table[ItemRarity].B) * GS_ItemTypes[ItemEquipLoc].SlotMOD * Scale * QualityScale)
            if (ItemLevel == 187.05) then
                ItemLevel = 0
            end
            if (GearScore < 0) then
                GearScore = 0
                Red, Green, Blue = TT_GS:GetQuality(1)
            end
            return GearScore, ItemLevel, Red, Green, Blue
        end
    end
    return 0, 0, 0.1, 0.1, 0.1
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


function TT_GS:GetScore(unitorguid, useCallback)
    local guid = getPlayerGUID(unitorguid)
    if (guid) then
        if (guid ~= UnitGUID("player")) then
            local _, invTime = CI:GetLastCacheTime(guid)
            if(invTime == 0) then
                return 0,0
            end
        end

        local PlayerClass, PlayerEnglishClass = GetPlayerInfoByGUID(guid)
        local GearScore = 0
        local ItemCount = 0
        local LevelTotal = 0
        local TitanGrip = 1
        local IsReady = true

        local mainHandItem = CI:GetInventoryItemMixin(guid, 16)
        local offHandItem = CI:GetInventoryItemMixin(guid, 17)
        local mainHandLink
        local offHandLink
        
        local cb_table
        
        if (useCallback) then
            cb_table = {["guid"] = guid, ["items"] = {}}
        end

        if (mainHandItem) then
            if (mainHandItem:IsItemDataCached()) then
                mainHandLink = mainHandItem:GetItemLink()
            else
                IsReady = false
                local itemID = mainHandItem:GetItemID()
                if (itemID) then
                    if (useCallback) then
                        table.insert(cb_table.items, itemID)
                        mainHandItem:ContinueOnItemLoad(function()
                            itemcacheCB(cb_table, itemID)
                        end)
                    else
                        C_Item.RequestLoadItemDataByID(itemID)
                    end
                end
            end
        end
        if (offHandItem) then
            if (offHandItem:IsItemDataCached()) then
                offHandLink = offHandItem:GetItemLink()
            else
                IsReady = false
                local itemID = offHandItem:GetItemID()
                if (itemID) then
                    if (useCallback) then
                        table.insert(cb_table.items, itemID)
                        offHandItem:ContinueOnItemLoad(function()
                            itemcacheCB(cb_table, itemID)
                        end)
                    else
                        C_Item.RequestLoadItemDataByID(itemID)
                    end
                end
            end
        end

        if (mainHandLink and offHandLink) then
            local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(mainHandLink)
            if (ItemEquipLoc == "INVTYPE_2HWEAPON") then
                TitanGrip = 0.5
            end
        end

        if (offHandLink) then
            local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(offHandLink)
            if (ItemEquipLoc == "INVTYPE_2HWEAPON") then
                TitanGrip = 0.5
            end
            local TempScore, ItemLevel = TT_GS:GetItemScore(offHandLink)
            if (PlayerEnglishClass == "HUNTER") then
                TempScore = TempScore * 0.3164
            end
            GearScore = GearScore + TempScore * TitanGrip
            ItemCount = ItemCount + 1
            LevelTotal = LevelTotal + ItemLevel
        end

        for i = 1, 18 do
            if ( i ~= 4 ) and ( i ~= 17 ) then
                local item = CI:GetInventoryItemMixin(guid, i)
                if (item) then
                    if (item:IsItemDataCached()) then
                        local TempScore, ItemLevel = TT_GS:GetItemScore(item:GetItemLink())
                        if (PlayerEnglishClass == "HUNTER") then
                            if (i == 16) then
                                TempScore = TempScore * 0.3164
                            elseif (i == 18) then
                                TempScore = TempScore * 5.3224
                            end
                        end
                        if ( i == 16 ) then
                            TempScore = TempScore * TitanGrip
                        end
                        GearScore = GearScore + TempScore
                        ItemCount = ItemCount + 1
                        LevelTotal = LevelTotal + ItemLevel
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
        if (IsReady and GearScore > 0 and ItemCount > 0) then
            return floor(GearScore), floor(LevelTotal/ItemCount)
        end
    end
    return 0,0
end

