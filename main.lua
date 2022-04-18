Name, Realm = UnitName("player");
local itemId = 6265; -- Configurable
local maxItemCount = 10; -- Configurable
-- Rarities range from poor (0) to heirloom (7)
local itemRarities = {0, 1} -- Configurable
local DEBUG = true;
local ADDON_NAME = "Auto Loot Destroy";
local LOOT_EVENT_NAME = "CHAT_MSG_LOOT";
local WAIT_TIME = 0.1;
SLASH_ALD1 = "/ald";
-- To get the current version: /run print((select(4, GetBuildInfo())));
Log = {}; -- Log to SavedVariables
Bag = {};
Bag.__index = Bag;
Bags = {};

function Bag:create(name, bagId, invId, slotCount)
    local bag = {};
    setmetatable(bag, Bag);
    bag.name = name;
    bag.bagId = bagId;
    bag.invId = invId;
    bag.slotCount = slotCount;
    return bag;
end

Inventory = {};
Inventory.__index = Inventory;

function Inventory:create(totalSlots, usedSlots, freeSlots)
    local inventory = {};
    inventory.totalSlots = totalSlots;
    inventory.usedSlots = usedSlots;
    inventory.freeSlots = freeSlots;
    return inventory;
end

function DestroyItems()
    local itemCount = GetItemCount(itemId);
    print("Item count:", itemCount);
    Bags = GetBags();
    local bagCount = #Bags;
    if itemCount <= maxItemCount then
        print("Player has less items than the max count. Stopping deletion.", maxItemCount);
        return
    end
    local destroyCount = itemCount - maxItemCount;
    print("Destroy count:", destroyCount);
    local destroyCounter = destroyCount;
    for bagId = 1,bagCount + 1,1 do
        print("Bag ID:", bagId);
        if Bags[bagId] ~= nil then
            print("Bag slot count:", Bags[bagId].slotCount);
            for slotId = 1,Bags[bagId].slotCount,1 do
                ClearCursor();
                local bagItemId = GetContainerItemID(bagId, slotId);
                if bagItemId ~= nil then
                    print("Bag item ID:", bagItemId);
                    local itemLink = GetContainerItemLink(bagId, slotId);
                    print("Bag item link:", itemLink);
                    if bagItemId == itemId then
                        print("Bag item qualifies for deletion. Bag ID: " ..  bagId .. ". Slot ID: " .. slotId);
                        PickupContainerItem(bagId, slotId);
                        if CursorHasItem() then
                            print("Deleting cursor item");
                            DeleteCursorItem();
                            itemCount = GetItemCount(itemId);
                            destroyCounter = destroyCounter - 1;
                            print("New destroy counter:", destroyCounter);
                            if itemCount <= maxItemCount or destroyCounter <= 0 then
                                print("Item count reached max. " .. maxItemCount .. " Stopping deletion.");
                                return
                            end
                        end
                    end
                end
            end
        end
    end
    -- SavedVariables insert
    -- tinsert(Log,format("%s: %s",date(),logMessage))
end

function GetBags()
    local bags = {};
    for bagId = 1,5,1 do
        local name = GetBagName(bagId);
        if name ~= nil then
            -- Inventory ID: the bag's inventory ID used in functions like PutItemInBag(inventoryId)
            local invId = ContainerIDToInventoryID(bagId);
            local slotCount = GetContainerNumSlots(bagId);
            local bag = Bag:create(name, bagId, invId, slotCount);
            bags[bagId] = bag;
        end
    end
    return bags;
end

function GetInventory(bags)
    local totalSlots = 0;
    local freeSlots = 0;
    for bagId = 1,#Bags,1 do
        totalSlots = totalSlots + bags[bagId].slotCount;
        freeSlots = freeSlots + GetContainerNumFreeSlots(bagId);
    end
    local inventory = Inventory:create(totalSlots, totalSlots - freeSlots, freeSlots);
    return inventory;
end

function GetItemRarity(id)
    local itemName, itemLink, itemRarity = GetItemInfo(id);
    print("Item ID " .. id .. " has rarity " .. itemRarity);
    return itemRarity;
end

function table.contains(table, element)
    for _, e in ipairs(table) do
        if e == element then return true end
    end
    return false
end

function EventHandler(self, event)
    print("Event handler called...");
    print("Event:", event);
    if event and event.arg1 then
        print("Event[1]:", event[5]);
        print("Player name:", Name);
    end
    -- Hardware event for DestroyCursorItem()
    Button:Click();
end

function EventHandlerWait()
    C_Timer.After(WAIT_TIME, EventHandler);
end

local function setSlashCmds()
    SlashCmdList["ALD"] = function(msg)
        print("ALD slash cmd entered");
        print("Msg: " .. msg);
    end
end

local function createOptions()
    -- Container
    local optionsFrame = CreateFrame("Frame", "ALD_OptionsFrame");
    optionsFrame.name = ADDON_NAME;
    InterfaceOptions_AddCategory(optionsFrame);
    local title = optionsFrame:CreateFontString("ARTWORK", nil, "GameFontNormalLarge");
    title:SetPoint("TOP", -8);
    title:SetText(ADDON_NAME);
    -- Item ID edit box
    -- local idEditBox = CreateFrame("EditBox", "ALD_ItemIdEditBox", optionsFrame);
    -- InterfaceOptions_AddCategory(idEditBox);
    -- idEditBox:SetPoint("LEFT", 16, 0);
    -- idEditBox:SetPoint("RIGHT", -32, 0);
    -- idEditBox:SetPoint("TOP", 0, -16);
    -- idEditBox:SetPoint("BOTTOM", 0, 0);
    -- Item name edit box

end

function Init()
    print("Initialising addon...");
    print("Destroy item ID:", itemId);
    setSlashCmds();
    createOptions();
    -- Create frame for subscribing to events
    local coreFrame = CreateFrame("FRAME", "ALD_CoreFrame");
    coreFrame:RegisterEvent(LOOT_EVENT_NAME);
    coreFrame:SetScript("OnEvent", EventHandlerWait);
    return coreFrame;
end

local function clickHandler(self, event)
    print("Click handler called...");
    DestroyItems();
end

function CreateButton()
    local button = CreateFrame("Button");
    button:SetScript("OnClick", clickHandler);
    return button;
end

function Disable()
    if DEBUG then
        print("Disabling addon...");
    end
   CoreFrame.UnregisterAllEvents();
end

-- Entry point
CoreFrame = Init();
Button = CreateButton();
