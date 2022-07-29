-- func GetItemGearScore(itemID or itemLink) return score, r, g, b or nil
-- func GetUnitGearScore(unit) return score or nil
-- func GetUnitGearScoreByGUID(guid) return score or nil
-- func GetUnitAverageItemLevel(unit) return avg_ilvl or nil
-- func GetUnitAverageItemLevelByGUID(guid) return avg_ilvl or nil

-- if getunitgearscore nil doinspect unit

local isRetail = WOW_PROJECT_ID == (WOW_PROJECT_MAINLINE or 1)
local isClassic = WOW_PROJECT_ID == (WOW_PROJECT_CLASSIC or 2)
local isBCC = WOW_PROJECT_ID == (WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5)
local isWrath = false

GS_ItemTypes = {
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
    
    --Lol Shirt
    ["INVTYPE_BODY"] = { ["SlotMOD"] = 0, ["ItemSlot"] = 4, ["Enchantable"] = false },
}

GS_Rarity = {
    [0] = {Red = 0.55, Green = 0.55, Blue = 0.55 },
    [1] = {Red = 1.00, Green = 1.00, Blue = 1.00 },
    [2] = {Red = 0.12, Green = 1.00, Blue = 0.00 },
    [3] = {Red = 0.00, Green = 0.50, Blue = 1.00 },
    [4] = {Red = 0.69, Green = 0.28, Blue = 0.97 },
    [5] = {Red = 0.94, Green = 0.09, Blue = 0.00 },
    [6] = {Red = 1.00, Green = 0.00, Blue = 0.00 },
    [7] = {Red = 0.90, Green = 0.80, Blue = 0.50 },
}

GS_Formula = {
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

GS_Quality = {
    [6000] = {
        ["Red"] = { ["A"] = 0.94, ["B"] = 5000, ["C"] = 0.00006, ["D"] = 1 },
        ["Blue"] = { ["A"] = 0.47, ["B"] = 5000, ["C"] = 0.00047, ["D"] = -1 },
        ["Green"] = { ["A"] = 0, ["B"] = 0, ["C"] = 0, ["D"] = 0 },
        ["Description"] = "Legendary"
    },
    [5000] = {
        ["Red"] = { ["A"] = 0.69, ["B"] = 4000, ["C"] = 0.00025, ["D"] = 1 },
        ["Blue"] = { ["A"] = 0.28, ["B"] = 4000, ["C"] = 0.00019, ["D"] = 1 },
        ["Green"] = { ["A"] = 0.97, ["B"] = 4000, ["C"] = 0.00096, ["D"] = -1 },
        ["Description"] = "Epic"
    },
    [4000] = {
        ["Red"] = { ["A"] = 0.0, ["B"] = 3000, ["C"] = 0.00069, ["D"] = 1 },
        ["Blue"] = { ["A"] = 0.5, ["B"] = 3000, ["C"] = 0.00022, ["D"] = -1 },
        ["Green"] = { ["A"] = 1, ["B"] = 3000, ["C"] = 0.00003, ["D"] = -1 },
        ["Description"] = "Superior"
    },
    [3000] = {
        ["Red"] = { ["A"] = 0.12, ["B"] = 2000, ["C"] = 0.00012, ["D"] = -1 },
        ["Blue"] = { ["A"] = 1, ["B"] = 2000, ["C"] = 0.00050, ["D"] = -1 },
        ["Green"] = { ["A"] = 0, ["B"] = 2000, ["C"] = 0.001, ["D"] = 1 },
        ["Description"] = "Uncommon"
    },
    [2000] = {
        ["Red"] = { ["A"] = 1, ["B"] = 1000, ["C"] = 0.00088, ["D"] = -1 },
        ["Blue"] = { ["A"] = 1, ["B"] = 000, ["C"] = 0.00000, ["D"] = 0 },
        ["Green"] = { ["A"] = 1, ["B"] = 1000, ["C"] = 0.001, ["D"] = -1 },
        ["Description"] = "Common"
    },
    [1000] = {
        ["Red"] = { ["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1 },
        ["Blue"] = { ["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1 },
        ["Green"] = { ["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1 },
        ["Description"] = "Trash"
    },
}

function GearScore_GetQuality(ItemScore)
    if (not ItemScore) then
        return 0, 0, 0, "Trash"
    end
    if (not isWrath) then
        return 1, 1, 1, "Common"
    end
    if (ItemScore > 5999) then
        ItemScore = 5999
    end
    local Red = 0.1
    local Blue = 0.1
    local Green = 0.1
    local GS_QualityDescription = "Legendary"
    for i = 0,6 do
        if ( ItemScore > i * 1000 ) and ( ItemScore <= ( ( i + 1 ) * 1000 ) ) then
            local Red = GS_Quality[( i + 1 ) * 1000].Red["A"] + (((ItemScore - GS_Quality[( i + 1 ) * 1000].Red["B"])*GS_Quality[( i + 1 ) * 1000].Red["C"])*GS_Quality[( i + 1 ) * 1000].Red["D"])
            local Blue = GS_Quality[( i + 1 ) * 1000].Green["A"] + (((ItemScore - GS_Quality[( i + 1 ) * 1000].Green["B"])*GS_Quality[( i + 1 ) * 1000].Green["C"])*GS_Quality[( i + 1 ) * 1000].Green["D"])
            local Green = GS_Quality[( i + 1 ) * 1000].Blue["A"] + (((ItemScore - GS_Quality[( i + 1 ) * 1000].Blue["B"])*GS_Quality[( i + 1 ) * 1000].Blue["C"])*GS_Quality[( i + 1 ) * 1000].Blue["D"])
            --if not ( Red ) or not ( Blue ) or not ( Green ) then return 0.1, 0.1, 0.1, nil; end
            return Red, Green, Blue, GS_Quality[( i + 1 ) * 1000].Description
        end
    end
    return 0.1, 0.1, 0.1
end

function GearScore_GetEnchantInfo(ItemLink, ItemEquipLoc)
    local found, _, ItemSubString = string.find(ItemLink, "^|c%x+|H(.+)|h%[.*%]");
    local ItemSubStringTable = {}

    for v in string.gmatch(ItemSubString, "[^:]+") do tinsert(ItemSubStringTable, v); end
    ItemSubString = ItemSubStringTable[2]..":"..ItemSubStringTable[3], ItemSubStringTable[2]
    local StringStart, StringEnd = string.find(ItemSubString, ":") 
    ItemSubString = string.sub(ItemSubString, StringStart + 1)
    if ( ItemSubString == "0" ) and ( GS_ItemTypes[ItemEquipLoc]["Enchantable"] )then
        --table.insert(MissingEnchantTable, ItemEquipLoc)
        local percent = ( floor((-2 * ( GS_ItemTypes[ItemEquipLoc]["SlotMOD"] )) * 100) / 100 );
        return(1 + (percent/100));
    else
        return 1;
    end
end

function GearScore_GetItemScore(ItemLink)
    local QualityScale = 1; local PVPScale = 1; local PVPScore = 0; local GearScore = 0
    if not ( ItemLink ) then return 0, 0; end
    local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(ItemLink); local Table = {}; local Scale = 1.8618
     if ( ItemRarity == 5 ) then QualityScale = 1.3; ItemRarity = 4;
    elseif ( ItemRarity == 1 ) then QualityScale = 0.005;  ItemRarity = 2
    elseif ( ItemRarity == 0 ) then QualityScale = 0.005;  ItemRarity = 2 end
    if ( ItemRarity == 7 ) then ItemRarity = 3; ItemLevel = 187.05; end
    if ( GS_ItemTypes[ItemEquipLoc] ) then
        if ( ItemLevel > 120 ) then Table = GS_Formula["A"]; else Table = GS_Formula["B"]; end
        if ( ItemRarity >= 2 ) and ( ItemRarity <= 4 )then
            local Red, Green, Blue = GearScore_GetQuality((floor(((ItemLevel - Table[ItemRarity].A) / Table[ItemRarity].B) * 1 * Scale)) * 11.25 )
            GearScore = floor(((ItemLevel - Table[ItemRarity].A) / Table[ItemRarity].B) * GS_ItemTypes[ItemEquipLoc].SlotMOD * Scale * QualityScale)
            if ( ItemLevel == 187.05 ) then ItemLevel = 0; end
            if ( GearScore < 0 ) then GearScore = 0;   Red, Green, Blue = GearScore_GetQuality(1); end
            if ( PVPScale == 0.75 ) then PVPScore = 1; GearScore = GearScore * 1; 
            else PVPScore = GearScore * 0; end
            local percent = (GearScore_GetEnchantInfo(ItemLink, ItemEquipLoc) or 1)
            GearScore = floor(GearScore * percent )
            PVPScore = floor(PVPScore)
            return GearScore, ItemLevel, GS_ItemTypes[ItemEquipLoc].ItemSlot, Red, Green, Blue, PVPScore, ItemEquipLoc, percent ;
        end
      end
      return -1, ItemLevel, 50, 1, 1, 1, PVPScore, ItemEquipLoc, 1
end

function GearScore_GetScore(Target)
    if ( Target and UnitIsPlayer(Target) ) then
        local guid = UnitGUID(Target)
        
        if (not UnitIsUnit(Target, "player")) then
            local _, invTime = IGetLastCacheTime(guid)
            if(invTime == 0) then
                return 0,0
            end
        end
        
        local PlayerClass, PlayerEnglishClass = UnitClass(Target);
        local GearScore = 0; local PVPScore = 0; local ItemCount = 0; local LevelTotal = 0; local TitanGrip = 1; local TempEquip = {}; local TempPVPScore = 0; local TempScore = 0

        if ( IGetInventoryItemLinkByGUID(guid, 16) ) and ( IGetInventoryItemLinkByGUID(guid, 17) ) then
            local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(IGetInventoryItemLinkByGUID(guid, 16))
            if ( ItemEquipLoc == "INVTYPE_2HWEAPON" ) then TitanGrip = 0.5; end
        end

        if ( IGetInventoryItemLinkByGUID(guid, 17) ) then
            local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(IGetInventoryItemLinkByGUID(guid, 17))
            if ( ItemEquipLoc == "INVTYPE_2HWEAPON" ) then TitanGrip = 0.5; end
            TempScore, ItemLevel = GearScore_GetItemScore(IGetInventoryItemLinkByGUID(guid, 17));
            if ( PlayerEnglishClass == "HUNTER" ) then TempScore = TempScore * 0.3164; end
            GearScore = GearScore + TempScore * TitanGrip;    ItemCount = ItemCount + 1; LevelTotal = LevelTotal + ItemLevel
        end
        
        for i = 1, 18 do
            if ( i ~= 4 ) and ( i ~= 17 ) then
                ItemLink = IGetInventoryItemLinkByGUID(guid, i)
                --GS_ItemLinkTable = {}
                if ( ItemLink ) then
                    local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(ItemLink)
                    TempScore = GearScore_GetItemScore(ItemLink);
                    if ( i == 16 ) and ( PlayerEnglishClass == "HUNTER" ) then TempScore = TempScore * 0.3164; end
                    if ( i == 18 ) and ( PlayerEnglishClass == "HUNTER" ) then TempScore = TempScore * 5.3224; end
                    if ( i == 16 ) then TempScore = TempScore * TitanGrip; end
                    GearScore = GearScore + TempScore;    ItemCount = ItemCount + 1; LevelTotal = LevelTotal + ItemLevel
                end
            end;
        end
        if ( GearScore <= 0 ) and ( not UnitIsUnit(Target, "player") ) then
            GearScore = 0;
            return 0,0;
        elseif ( UnitIsUnit(Target, "player") ) and ( GearScore <= 0 ) then
            GearScore = 0;
        end
        if ( ItemCount == 0 ) then LevelTotal = 0; end           
        return floor(GearScore), floor(LevelTotal/ItemCount)
    end
end
