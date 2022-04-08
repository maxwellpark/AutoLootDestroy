local itemId = 16893; -- Configurable
local maxItemCount = 10; -- Configurable
-- Rarities range from poor (0) to heirloom (7)
local itemRarities = {0, 1} -- Configurable
local EVENT_NAME = "UNIT_INVENTORY_CHANGED";
local DEBUG = true;
local frame = Init();
SLASH_ALD1 = "/ald";

-- To get the current version:
-- /run print((select(4, GetBuildInfo())));

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
            print("Bag item ID matches: " .. bagItemId == itemId);
            local rarity = GetItemRarity(bagItemId);
            print("Item rarity: " .. rarity);
            local destroyRarity = table.contains(itemRarities, rarity);
            print("Rarity matches: " .. destroyRarity);
            if bagItemId == itemId then
                print("Bag item qualifies for deletion. Picking up item to cursor.");
                PickupContainerItem(bagId, slotId);
                if CursorHasItem() then
                    print("Deleting cursor item");
                    DeleteCursorItem();
                    itemCount = GetItemCount(itemId);
                    print("New item count: " .. itemCount);
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

function GetItemRarity(id)
    local sName, sLink, iRarity, iLevel, iMinLevel, sType, sSubType, iStackCount = GetItemInfo(id);
    print("Item with item ID %s and name '%s' has rarity '%s'", itemId, sName, iRarity);
    return iRarity;
end

-- Type.method
function table.contains(table, element)
    for _, e in ipairs(table) do
        if e == element then return true end
    end
    return false
end

local function eventHandler(self, event)
    print("Event handler called...");
    DestroyItems();
end

local function setSlashCmds()
    SlashCmdList["ALD"] = function(msg)
        print("ALD slash cmd entered");
        print("Msg: " .. msg);
    end
end

function Init()
    print("Initialising addon...");
    setSlashCmds();
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
