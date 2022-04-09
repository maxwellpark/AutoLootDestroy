local itemId = 6265; -- Configurable
local maxItemCount = 10; -- Configurable
-- Rarities range from poor (0) to heirloom (7)
local itemRarities = {0, 1} -- Configurable
local EVENT_NAME = "UNIT_INVENTORY_CHANGED";
local DEBUG = true;
local ADDON_NAME = "Auto Loot Destroy";
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

function DestroyItems()
    print("Item ID:", itemId);
    local itemCount = GetItemCount(itemId);
    print("Item count:", itemCount);
    local bags = GetBags();
    print("Bags:", bags);
    local bagCount = #bags;
    print("Bag count:", bagCount);
    if itemCount <= maxItemCount then
        print("Player has less items than the max count. Stopping deletion.", maxItemCount);
        return
    end
    local destroyCount = itemCount - maxItemCount;
    print("Destroy count:", destroyCount);
    for bagId = 1,4,1 do
        for slotId = 1,bags[bagId].slotCount,1 do
            local itemLink = GetContainerItemLink(bagId, slotId);
            print("Bag item link:", itemLink);
            local bagItemId = GetContainerItemID(bagId, slotId);
            print("Bag item ID:", bagItemId);
            print("Bag item ID matches:", bagItemId == itemId);
            -- local rarity = GetItemRarity(bagItemId);
            -- print("Item rarity:", rarity);
            -- local destroyRarity = table.contains(itemRarities, rarity);
            -- print("Rarity matches:", destroyRarity);
            if bagItemId == itemId then
                print("Bag item qualifies for deletion. Picking up item to cursor.");
                PickupContainerItem(bagId, slotId);
                if CursorHasItem() then
                    print("Deleting cursor item");
                    DeleteCursorItem();
                    itemCount = GetItemCount(itemId);
                    print("New item count:", itemCount);
                    if itemCount <= maxItemCount then
                        print("Item count reached max. Stopping deletion.");
                        print("Max count:", maxItemCount);
                        return
                    end
                end
            end
        end
    end
end

function GetBags()
    local bags = {};
    for bagId = 1,4,1 do
        local name = GetBagName(bagId);
        -- Inventory ID - the bag's inventory ID used in functions like PutItemInBag(inventoryId)
        local invId = ContainerIDToInventoryID(bagId);
        local slotCount = GetContainerNumSlots(bagId);
        print("Bag:", bagId, name, invId, slotCount);
        local bag = Bag:create(name, bagId, invId, slotCount);
        bags[bagId] = bag;
    end
    return bags;
end

function GetItemRarity(id)
    local itemName, itemLink, itemRarity = GetItemInfo(id);
    print("Item ID " .. id .. " has rarity " .. itemRarity);
    return itemRarity;
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

local function createOptions()
    local panel = CreateFrame("Frame");
    panel.name = ADDON_NAME;
    InterfaceOptions_AddCategory(panel);
    local title = panel:CreateFontString("ARTWORK", nil, "GameFontNormalLarge");
    title:SetPoint("TOP");
    title:SetText(ADDON_NAME);
end

function Init()
    print("Initialising addon...");
    setSlashCmds();
    createOptions();
    print("Attempting to create frame and subscribe to event", EVENT_NAME);
    -- Create frame for subscribing to events
    local newFrame = CreateFrame("FRAME", "AddonFrame");
    newFrame:RegisterEvent(EVENT_NAME);
    newFrame:SetScript("OnEvent", eventHandler);
    return newFrame;
end

-- Entry point
local frame = Init();

function Disable()
    if DEBUG then
        print("Disabling addon...");
    end
   frame.UnregisterAllEvents();
end
