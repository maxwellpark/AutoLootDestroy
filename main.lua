local itemId = 16893; -- Configurable
local maxItemCount = 10; -- Configurable
local EVENT_NAME = "UNIT_INVENTORY_CHANGED";
local DEBUG = true;
local frame = Init();

Bag = {};
Bag.__index = Bag;

function Bag:create(name, bagId, invId, slotCount)
    local bag = {};
    setmetatable(bag, Bag);
    bag.name = name;
    bag.bagId = bagId;
    bag.invId = invId;
    bag.slotCount = slotCount;
    return bag;
end

-- Entry point
Init();

function DestroyItems()
    local itemCount = GetItemCount(itemId);
    print("Player has %s items with ID %s", itemCount, itemId);
    local bags = GetBags();
    print("Bags: " .. bags);
    local bagCount = #bags;
    print("Bag count: " .. bagCount);
    if itemCount <= maxItemCount then
        print("Player has less items than the max count of %s. Stopping deletion.", maxItemCount);
        return
    end
    local destroyCount = itemCount - maxItemCount;
    print("Destroying %s items from bags", destroyCount);
    for bagId = 0,4,1 do
        for slotId = 0,bags[bagId].slotCount,1 do
            local itemLink = GetContainerItemLink(bagId, slotId);
            print("Bag item link: " .. itemLink);
            local bagItemId = GetContainerItemID(bagId, slotId);
            print("Bag item ID: " .. bagItemId);
            if bagItemId == itemId then
                print("Bag item ID matches ID of item to delete");
                PickupContainerItem(bagId, slotId);
                if CursorHasItem() then
                    print("Deleting cursor item");
                    DeleteCursorItem();
                    itemCount = GetItemCount(itemId);
                    print("Item count = " .. itemCount);
                    if itemCount <= maxItemCount then
                        print("Item count reached %s (max). Stopping deletion.", maxItemCount);
                        return
                    end
                end
            end
        end
    end
end

function GetBags()
    local bags = {};
    for bagId = 0,4,1 do
        local name = GetBagName(bagId);
        -- Inventory ID - the bag's inventory ID used in functions like PutItemInBag(inventoryId)
        local invId = ContainerIDToInventoryID(bagId);
        local slotCount = GetContainerNumSlots(bagId);
        print("Bag no. %s has name '%s', inventory ID %s, and %s slots", bagId, name, invId, slotCount);
        local bag = Bag:create(name, bagId, invId, slotCount);
        bags[bagId] = bag;
    end
    return bags;
end

local function eventHandler(self, event)
    print("Event handler called...");
    DestroyItems();
end

function Init()
    print("Initialising addon...");
    print("Attempting to create frame and subscribe to event '%s'", EVENT_NAME);
    -- Create frame for subscribing to events
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
