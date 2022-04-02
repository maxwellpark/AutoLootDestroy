local soulstoneId = 16893;
local maxSoulstones = 10; -- Configurable
local frame = Init();

local function destroyItems()
    local soulstoneCount = GetItemCount(soulstoneId);
    local destroyCount = soulstoneCount - maxSoulstones;

    if player:HasItem(soulstoneId) and soulstoneCount > maxSoulstones then
        player:RemoveItem(soulstoneId, destroyCount);
    end
end

local function eventHandler(self, event)
    print("Destroying items");
    destroyItems();
end

function Init()
    local newFrame = CreateFrame("FRAME", "AddonFrame");
    newFrame:RegisterEvent("ITEM_LOOTED_HANDLER");
    newFrame:SetScript("UNIT_INVENTORY_CHANGED", eventHandler);
    return newFrame;
end

function Disable()
   frame.UnregisterAllEvents();
end
