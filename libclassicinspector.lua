-- TODO: for wotlk, 2 talent groups !
-- TODO: save honor data too ?

-- cache_players.talents.group.tab.index
-- cache_players.inventory.slot

local user_cache_first
local user_cache_last
local user_cache_len = 0
local user_cache_this = {["guid"] = 0}

local nextInspectTime = 0
local inspectQueue = {}
inspector = true

INSPECTOR_MAX_CACHE = 150
INSPECTOR_INSPECT_DELAY = 2
INSPECTOR_MAX_QUEUE = 20
INSPECTOR_REFRESH_DELAY = 10

-- TODO: localization
local spec_table = {
    ["WARRIOR"] = {"Arms", "Fury", "Protection"},
    ["PALADIN"] = {"Holy", "Protection", "Retribution"},
    ["HUNTER"] = {"Beast Mastery", "Marksmanship", "Survival"},
    ["ROGUE"] = {"Assassination", "Combat", "Subtlety"},
    ["PRIEST"] = {"Discipline", "Holy", "Shadow"},
    ["DEATHKNIGHT"] = {"Blood", "Frost", "Unholy"},
    ["SHAMAN"] = {"Elemental", "Enhancement", "Restoration"},
    ["MAGE"] = {"Arcane", "Fire", "Frost"},
    ["WARLOCK"] = {"Affliction", "Demonology", "Destruction"},
    ["DRUID"] = {"Balance", "Feral Combat", "Restoration"}
}

local function getCacheUser(guid)
    if (guid == user_cache_this.guid) then
        return user_cache_this
    elseif (user_cache_first) then
        local node = user_cache_first
        repeat
            if (guid == node.guid) then
                user_cache_this = node
                return node
            end
            node = node.next
        until (node == nil)
    end
    return nil
end

local function addCacheUser(guid, inventory, talents)
    local user = {["guid"] = guid}
    if(inventory) then
        user.inventory = inventory
    else
        user.inventory = {["time"] = 0}
    end
    if(talents) then
        user.talents = talents
    else
        user.talents = {[1] = {[1] = {}, [2] = {}, [3] = {}}, [2] = {[1] = {}, [2] = {}, [3] = {}}, ["time"] = 0}
    end

    if (not user_cache_first) then
        user_cache_first = user
        user_cache_last = user
        user_cache_len = 1
    else
        user_cache_last.next = user
        user_cache_last = user
        if (user_cache_len >= INSPECTOR_MAX_CACHE) then
            if (IsInGroup() and IsGUIDInGroup(user_cache_first.guid)) then
                local node = user_cache_first
                while (IsGUIDInGroup(node.next)) do
                    node = node.next
                end
                local next = node.next
                node.next = next.next
                --print("removed user:",next.guid," cache_len:",user_cache_len)
                next = nil
            else
                local next = user_cache_first.next
                user_cache_first = nil
                user_cache_first = next 
                --print("removed user:",next.guid," cache_len:",user_cache_len)
            end
        else
            user_cache_len = user_cache_len + 1
        end
    end
    --print("added user:",guid," cache_len:",user_cache_len)
end

local function inventoryReadyCallback(guid)
    local _, unit = GameTooltip:GetUnit()
    if (unit and UnitGUID(unit) == guid) then
        GameTooltip:SetUnit(unit)
    end
end

local function talentsReadyCallback(guid)
    local _, unit = GameTooltip:GetUnit()
    if (unit and UnitGUID(unit) == guid) then
        GameTooltip:SetUnit(unit)
    end
end

local function cacheUserInventory(unit)
    local inventory = {["time"] = time()}
    for i=1,18 do
        if(GetInventoryItemTexture(unit, i)) then
            inventory[i] = GetInventoryItemLink(unit, i)
        end
    end
    local guid = UnitGUID(unit)
    local user = getCacheUser(guid)
    if(user) then
        user.inventory = inventory
        --print("refresh inventory user:",guid," cache_len:",user_cache_len)
    else
        addCacheUser(guid, inventory, nil)
    end
    --if (not InspectFrame or not InspectFrame:IsShown()) then
        --ClearInspectPlayer()
    --end
    -- fire INVENTORY_READY(unit, guid, inventory) callback
    inventoryReadyCallback(guid)
end

local function cacheUserTalents(unit)
    local talents = {[1] = {[1] = {}, [2] = {}, [3] = {}}, [2] = {[1] = {}, [2] = {}, [3] = {}}, ["time"] = time()}
    for i = 1, 3 do  -- GetNumTalentTabs
        for j = 1, GetNumTalents(i) do
            talents[1][i][j] = select(5, GetTalentInfo(i, j, true))
        end
    end
    local guid = UnitGUID(unit)
    local user = getCacheUser(guid)
    if(user) then
        user.talents = talents
        --print("refresh talents user:",guid," cache_len:",user_cache_len)
    else
        addCacheUser(guid, nil, talents)
    end
    -- fire TALENTS_READY(unit, guid, talents) callback
    talentsReadyCallback(guid)
end

local function hasCacheUser(guid)
    local user = getCacheUser(guid)
    if (user) then
        return user.inventory.time ~= 0
    end
    return false
end

local function getCacheUser2(guid)
    local user = getCacheUser(guid)
    if (user) then
        local t = time()-INSPECTOR_REFRESH_DELAY
        if (user.talents.time < t or user.inventory.time < t) then
            DoInspectByGUID(guid)
        end
    else
        DoInspectByGUID(guid)
    end
    return user
end

function GUIDToUnitToken(guid)
    if(not guid or not C_PlayerInfo.GUIDIsPlayer(guid)) then
        return nil
    end
    if(UnitGUID("player") == guid) then
        return "player"
    end
    if(UnitGUID("target") == guid) then
        return "target"
    end
    if(UnitGUID("focus") == guid) then
        return "focus"
    end
    if(UnitGUID("mouseover") == guid) then
        return "mouseover"
    end
    if(IsInGroup() and IsGUIDInGroup(guid)) then
        if(IsInRaid()) then
            for i=1,40 do
                if(UnitGUID("raid"..i) == guid) then
                    return "raid"..i
                end
            end
        else
            for i=1,4 do
                if(UnitGUID("party"..i) == guid) then
                    return "party"..i
                end
            end
        end
    end
    if(GetCVar("nameplateShowFriends") == '1' or GetCVar("nameplateShowEnemies") == '1') then
        local nameplatesArray = C_NamePlate.GetNamePlates()
        for i, nameplate in ipairs(nameplatesArray) do
            if (UnitGUID(nameplate.namePlateUnitToken) == guid) then
                return nameplate.namePlateUnitToken
            end
        end
    end
    if(UnitGUID("targettarget") == guid) then
        return "targettarget"
    end
    if(UnitGUID("mouseovertarget") == guid) then
        return "mouseovertarget"
    end
    return nil
end

-- func IGetTalentsByGUID(guid) return table or nil
-- func IGetInventoryItemIDByGUID(guid, slot) return id or nil, -1 (not cached) / seconds from cache
-- func IGetInventoryItemLinkByGUID(guid, slot) return link or nil, -1 (not cached) / seconds from cache
-- func IGetInventoryItemsByGUID(guid) return table or nil

-- func IGetTalentInfoByGUID(guid, tab, index) return info or nil, -1 (not cached) / seconds from cache
-- (WOTLK) func IGetTalentInfo(guid, tab, index, group) return info or nil, -1 (not cached) / seconds from cache
-- (WOTLK) func IGetActiveTalentGroup(unitId/guid) return info or nil, -1 (not cached) / seconds from cache

-- func GetTalentTabInfoByGUID(guid, index)

-- func GetTalentPointsByGUID(guid, tab, index) return points_spent or nil
-- (WOTLK) func GetTalentPoints(unit, tab, index, group) return points_spent or nil

-- (WOTLK) func GetActiveTalentGroup(unit) return 1/2 or nil

-- func DoInspectByGUID(guid, [forcerefresh]) return success, queued
-- func DoInspect(unit, [forcerefresh]) return success, queued



-- callback TALENTS_READY (guid)
-- callback INVENTORY_READY (guid)

function IGetInventoryItemLinkByGUID(guid, slot)
    if (not guid or not slot) then
        return nil
    end
    if (guid == UnitGUID("player")) then
        return GetInventoryItemLink("player", slot)
    end
    local user = getCacheUser2(guid)
    if (user and user.inventory.time ~= 0) then
        return user.inventory[slot]
    end
    return nil
end

function IGetTalentTabInfoByGUID(guid, index)
    if (not guid or not index or index < 1 or index > 3) then
        return nil
    end
    if (guid == UnitGUID("player")) then
        return GetTalentTabInfo(index, false)
    end
    local user = getCacheUser2(guid)
    if (user) then
        local pointsSpent = 0
        for _, v in ipairs(user.talents[1][index]) do
            pointsSpent = pointsSpent + v
        end
        return "Fire", nil, pointsSpent, "fileName"
    end
    return nil
end

function IGetTotalTalentPointsByGUID(guid)
    local talents = {0, 0, 0}
    if (guid == UnitGUID("player")) then
        for i = 1, 3 do  -- GetNumTalentTabs
            for j = 1, GetNumTalents(i) do
                talents[i] = talents[i] + select(5, GetTalentInfo(i, j, false))
            end
        end
        return unpack(talents)
    end
    local user = getCacheUser2(guid)
    if (user) then
        for i = 1, 3 do  -- GetNumTalentTabs
            for _, v in ipairs(user.talents[1][i]) do
                talents[i] = talents[i] + v
            end
        end
        return unpack(talents)
    end
    return nil
end


function IGetActiveSpecByGUID(guid)
    local most = 0
    local spec = nil
    local _, englishClass = GetPlayerInfoByGUID(guid)
    if (guid == UnitGUID("player")) then
        for i = 1, 3 do  -- GetNumTalentTabs
            local points = 0
            for j = 1, GetNumTalents(i) do
                points = points + select(5, GetTalentInfo(i, j, false))
            end
            if (points > most) then
                most = points
                spec = spec_table[englishClass][i]
            end
        end
        return spec
    end
    local user = getCacheUser2(guid)
    if (user) then
        for i = 1, 3 do  -- GetNumTalentTabs
            local points = 0
            for _, v in ipairs(user.talents[1][i]) do
                points = points + v
            end
            if (points > most) then
                most = points
                spec = spec_table[englishClass][i]
            end
        end
        return spec
    end
    return nil
end

function IsInspectInventoryReady(unit)
    if(not unit or not UnitIsPlayer(unit)) then
        return false
    end
    local ret = false
    for i=1,18 do
        if(GetInventoryItemTexture(unit, i)) then
            if(not GetInventoryItemLink(unit, i)) then
                return false
            end
            ret = true
        end
    end
    return ret
end

function IGetLastCacheTime(guid)
    local user = getCacheUser2(guid)
    if (user) then
        return user.talents.time, user.inventory.time
    end
    return 0, 0
end

function ICanInspect(unit)
    return unit and (not InCombatLockdown()) and UnitExists(unit) and UnitIsPlayer(unit) and UnitIsConnected(unit) and (not UnitIsDeadOrGhost(unit)) and (not UnitIsUnit(unit, "player")) and CheckInteractDistance(unit, 1) and (not InspectFrame or not InspectFrame:IsShown()) and CanInspect(unit, false)
end

local oNotifyInspect = NotifyInspect
function NotifyInspect(unit)
	nextInspectTime = time()+INSPECTOR_INSPECT_DELAY
	--print("inspecting user:",UnitGUID(unit),UnitName(unit))
	oNotifyInspect(unit)
end

local function tryInspect(unit)
    if (ICanInspect(unit)) then
        local guid = UnitGUID(unit)
        local user = getCacheUser(guid)
        if (user) then
            local t = time()-INSPECTOR_REFRESH_DELAY
            if (user.talents.time < t or user.inventory.time < t) then
                NotifyInspect(unit)
                return true
            end
        else
            NotifyInspect(unit)
            return true
        end
    end
    return false
end

C_Timer.NewTicker(1, function()
    if (not inspector or InCombatLockdown() or not UnitExists("player") or not UnitIsConnected("player") or UnitIsDeadOrGhost("player")) then return end
    if (time() >= nextInspectTime) then
        if (UnitExists("target") and tryInspect("target")) then
            return
        elseif (#inspectQueue > 0) then
            for i=#inspectQueue,1,-1 do
                local unit = GUIDToUnitToken(inspectQueue[i])
                table.remove(inspectQueue, i)
                if (tryInspect(unit)) then
                    return
                end
            end
            --print("queue size:",#inspectQueue)
        end
    end
end)

function DoInspect(unit)
    if (ICanInspect(unit)) then
        if (time() >= nextInspectTime) then
            NotifyInspect(unit)
            return 0
        else
            local c = #inspectQueue
            local guid = UnitGUID(unit)
            if (c > 0) then
                for i=1,c do
                    if (inspectQueue[i] == guid) then
                        return i
                    end
                end
                if (c >= INSPECTOR_MAX_QUEUE) then
                    table.remove(inspectQueue, 1)
                    c = c-1
                end
            end
            table.insert(inspectQueue, guid)
            return c+1
        end
    end
    return -1
end

function DoInspectByGUID(guid)
    local unit = GUIDToUnitToken(guid)
    if (unit) then
        return DoInspect(unit)
    end
    return -1
end

local function onEvent(self, event, ...)
    if (event == "UNIT_INVENTORY_CHANGED") then
        local unit = ...
        if (unit and unit ~= "player") then
            local ready = IsInspectInventoryReady(unit)
            print(event, ..., ready)
            if(ready and not UnitIsUnit(unit, "player")) then
                cacheUserInventory(unit)
            end
        end
    else -- INSPECT_READY
        local guid = ...
        if (not inspector or not guid) then 
            return
        end
        local unit = GUIDToUnitToken(guid)
        if(not unit or UnitIsUnit(unit, "player")) then
            return
        end
        cacheUserTalents(unit)
        if(IsInspectInventoryReady(unit)) then
            --print(GetInventoryItemLink(unit, 1))
            cacheUserInventory(unit)
        else
            local timer = nil
            timer = C_Timer.NewTicker(0.5, function()
                local unit2 = GUIDToUnitToken(guid)
                if (IsInspectInventoryReady(unit2)) then
                    cacheUserInventory(unit2)
                    timer:Cancel()
                end
            end, 20)
        end
    end
end

local f = CreateFrame("Frame", nil, UIParent)
f:RegisterEvent("INSPECT_READY")
f:RegisterEvent("UNIT_INVENTORY_CHANGED")
f:SetScript("OnEvent", onEvent)
