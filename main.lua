local itemId = 16893; -- Configurable
local maxItemCount = 10; -- Configurable
local EVENT_NAME = "UNIT_INVENTORY_CHANGED";
local DEBUG = true;
local frame = Init();

local function destroyItems()
    local soulstoneCount = GetItemCount(itemId);
    local destroyCount = soulstoneCount - maxItemCount;
    if DEBUG then
        print("Player has %s items", soulstoneCount);
        print("Destroying %s items from bags", destroyCount);
    end
    -- Destroy the difference between current and max counts
    if player:HasItem(itemId) and soulstoneCount > maxItemCount then
        player:RemoveItem(itemId, destroyCount);
    end
end

local function eventHandler(self, event)
    if DEBUG then
        print("Event handler called...");
    end  
    destroyItems();
end

function Init()
    if DEBUG then 
        print("Initialising addon...");
        print("Attempting to create frame and subscribe to event '%s'", EVENT_NAME);
    end
    -- Frame for subscribing to events 
    local newFrame = CreateFrame("FRAME", "AddonFrame");
    newFrame:RegisterEvent("ITEM_LOOTED_HANDLER");
    newFrame:SetScript(EVENT_NAME, eventHandler);
    return newFrame;
end

function Disable()
    if DEBUG then
        print("Disabling addon...");
    end
   frame.UnregisterAllEvents();
end
