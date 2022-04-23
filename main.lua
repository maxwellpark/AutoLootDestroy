local playerName = UnitName("player")
local itemId = 6265 -- Configurable
local maxItemCount = 10 -- Configurable
-- Rarities range from poor (0) to heirloom (7)
local itemRarities = { 0, 1 } -- Configurable
local DEBUG = true
local ADDON_NAME = "Auto Loot Destroy"
local LOOT_EVENT_NAME = "CHAT_MSG_LOOT"
local WAIT_TIME = 0.1
local EMPTY_OR_WHITESPACE_REGEX = "/^\\s+$/"
SLASH_ALD1 = "/ald"

-- To get the current version: /run print((select(4, GetBuildInfo())));
Log = {} -- Log to SavedVariables
Bag = {}
Bag.__index = Bag
Bags = {}

function Bag:create(name, bagId, invId, slotCount)
    local bag = {}
    setmetatable(bag, Bag)
    bag.name = name
    bag.bagId = bagId
    bag.invId = invId
    bag.slotCount = slotCount
    return bag
end

Inventory = {}
Inventory.__index = Inventory

function Inventory:create(totalSlots, usedSlots, freeSlots)
    local inventory = {}
    inventory.totalSlots = totalSlots
    inventory.usedSlots = usedSlots
    inventory.freeSlots = freeSlots
    return inventory
end

function DestroyItems()
    local itemCount = GetItemCount(itemId)
    ALD_Print("Current item count: " .. itemCount, true)
    Bags = GetBags()
    local bagCount = #Bags
    if itemCount <= maxItemCount then
        ALD_Print("Player has less items than the max count. Stopping deletion. " .. maxItemCount, true)
        return
    end
    local destroyCount = itemCount - maxItemCount
    ALD_Print("Destroy count: " .. destroyCount, true)
    local destroyCounter = destroyCount
    for bagId = 0, bagCount, 1 do
        ALD_Print("Bag ID: " .. bagId, true)
        if Bags[bagId] ~= nil then
            ALD_Print("Bag slot count: " .. Bags[bagId].slotCount, true)
            for slotId = 1, Bags[bagId].slotCount, 1 do
                ClearCursor()
                local bagItemId = GetContainerItemID(bagId, slotId)
                if bagItemId ~= nil then
                    if bagItemId == itemId then
                        ALD_Print("Bag item qualifies for deletion. Bag ID: " .. bagId .. ". Slot ID: " .. slotId, true)
                        ALD_Print("Picking up container item", true)
                        PickupContainerItem(bagId, slotId)
                        if CursorHasItem() then
                            ALD_Print("Deleting cursor item", true)
                            DeleteCursorItem()
                            itemCount = GetItemCount(itemId)
                            destroyCounter = destroyCounter - 1
                            ALD_Print("New destroy counter: " .. destroyCounter, true)
                            if itemCount <= maxItemCount or destroyCounter <= 0 then
                                ALD_Print("Item count reached max. " .. maxItemCount .. " Stopping deletion.", true)
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
    local bags = {}
    for bagId = 0, 4, 1 do
        local name = GetBagName(bagId)
        if name ~= nil then
            local invId = nil
            local slotCount = nil
            if bagId == 0 then
                -- Default backpack has no Inventory ID, only a Container ID
                slotCount = 16
            else
                -- Inventory ID: the bag's inventory ID used in functions like PutItemInBag(inventoryId)
                invId = ContainerIDToInventoryID(bagId)
                slotCount = GetContainerNumSlots(bagId)
                ALD_Print(format("Found bag with inv ID %s, name '%s'", invId, name), true)
            end
            local bag = Bag:create(name, bagId, invId, slotCount)
            bags[bagId] = bag
        end
    end
    return bags
end

function GetInventory(bags)
    local totalSlots = 0
    local freeSlots = 0
    for bagId = 1, #Bags, 1 do
        totalSlots = totalSlots + bags[bagId].slotCount
        freeSlots = freeSlots + GetContainerNumFreeSlots(bagId)
    end
    local inventory = Inventory:create(totalSlots, totalSlots - freeSlots, freeSlots)
    return inventory
end

function GetItemRarity(id)
    local itemName, itemLink, itemRarity = GetItemInfo(id)
    ALD_Print("Item ID " .. id .. " has rarity " .. itemRarity, true)
    return itemRarity
end

function table.contains(table, element)
    for _, e in ipairs(table) do
        if e == element then
            return true
        end
    end
    return false
end

function EventHandler()
    ALD_Print("Event handler called...", true)
    -- Hardware event for DestroyCursorItem()
    DestroyItemButton:Click()
end

function EventHandlerWait(self, event, arg1, arg2, arg3, arg4, arg5)
    ALD_Print("Event: " .. event, true)
    ALD_Print(format("Event args: 1. %s, 2. %s, 3. %s, 4. %s, 5. %s", arg1, arg2, arg3, arg4, arg5), true)
    if arg5 ~= playerName then
        return
    end
    C_Timer.After(WAIT_TIME, EventHandler)
end

local function setSlashCmds()
    SlashCmdList["ALD"] = function(input)
        ALD_Print("ALD slash cmd entered. Input: " .. input, true)
        local args = {}
        for arg in input:gmatch("%S+") do
            if arg:upper() ~= "ALD" then
                table.insert(args, arg)
            end
        end
        ALD_Print("Cmd args: " .. table.concat(args, " "), true)
        if args[1] == nil then
            InterfaceOptionsFrame_Show()
            InterfaceOptionsFrame_OpenToCategory(ADDON_NAME)
            return
        end
        local arg1 = args[1]:upper()
        -- Get info
        if arg1 == "INFO" then
            ALD_Print(format("Item ID = %s. Max Item Count = %s", itemId, maxItemCount), false)
            -- Set max item count
        elseif arg1 == "SETMAX" then
            if args[2] ~= nil then
                local num = tonumber(args[2])
                if num ~= nil then
                    maxItemCount = num
                else
                    ALD_Print("Invalid max item count input: " .. args[2] .. ". Please use a valid integer", false)
                end
            end
        elseif arg1 == "HELP" then
            ALD_Print("Type '/ald info' to get the current settings")
            ALD_Print("Type '/ald setmax [max item count]' to set the max no. of items")
        end
    end
end

local function createInterfaceOptions()
    -- Container
    local optionsFrame = CreateFrame("Frame", "ALD_OptionsFrame")
    optionsFrame.name = ADDON_NAME
    InterfaceOptions_AddCategory(optionsFrame)
    local title = optionsFrame:CreateFontString("TitleFontString", nil, "GameFontNormalLarge")
    title:SetPoint("TOP", 12, -12)
    title:SetText(ADDON_NAME)
    -- Item count edit box
    local maxCountEditBox = CreateFrame("EditBox", nil, optionsFrame, "InputBoxTemplate")
    maxCountEditBox:SetAutoFocus(false)
    maxCountEditBox:SetFrameStrata("DIALOG")
    maxCountEditBox:SetSize(100, 15)
    local maxCountLabel = optionsFrame:CreateFontString("IdEditBoxLabelFontString", nil, "GameFontNormalLarge")
    maxCountLabel:SetText("Max Item Count:")
    maxCountLabel:SetPoint("TOPLEFT", 16, -32)
    maxCountEditBox:SetPoint("TOPLEFT", 16, -64)
    -- Set max item count on exiting options
    InterfaceOptionsFrame:HookScript("OnHide", function()
        local editBoxNum = maxCountEditBox:GetNumber()
        ALD_Print("Edit box input num on hide: " .. editBoxNum, true)
        local editBoxText = maxCountEditBox:GetText()
        ALD_Print("Edit box input text on hide: " .. editBoxText, true)
        local matchBlank = editBoxText:gmatch(EMPTY_OR_WHITESPACE_REGEX)
        if editBoxText == nil then
            return
        end
        ALD_Print("Changing max item count", true)
        maxItemCount = editBoxNum
        ALD_Print("Max item count: " .. maxItemCount, false)
    end)
end

local function setAltArrowKeyModes()
    for i = 1, NUM_CHAT_WINDOWS do
        _G["ChatFrame" .. i .. "EditBox"]:SetAltArrowKeyMode(false)
    end
end

function Init()
    ALD_Print("Type '/ald help' to list the slash commands for this addon", false)
    setSlashCmds()
    createInterfaceOptions()
    setAltArrowKeyModes()
end

local function clickHandler(self, event)
    ALD_Print("Click handler called...", true)
    DestroyItems()
end

function CreateCoreFrame()
    -- Create frame for subscribing to events
    local coreFrame = CreateFrame("FRAME", "ALD_CoreFrame")
    coreFrame:RegisterEvent(LOOT_EVENT_NAME)
    coreFrame:SetScript("OnEvent", EventHandlerWait)
    return coreFrame
end

function CreateButton()
    local button = CreateFrame("Button")
    button:SetScript("OnClick", clickHandler)
    return button
end

function Disable()
    ALD_Print("Disabling addon...", true)
    CoreFrame.UnregisterAllEvents()
end

function GetColours()
    local colours = {}
    colours["red"] = "cFFFF0000"
    colours["green"] = "cFF00FF00"
    colours["blue"] = "cFF0000FF"
    colours["purple"] = "cFFBF40BF"
    colours["white"] = "cFFFFFFFF"
    return colours
end

function ALD_Print(msg, debug)
    if debug and not DEBUG then
        return
    end
    -- print("|cFFFF0000Auto |cFF00FF00Loot |cFF0000FFDestroy|cFFFFFFFF: |cFF6a0dad" .. msg)
    print(format("|%sAuto |%sLoot |%sDestroy|%s: |%s" .. msg,
        Colours["red"], Colours["green"], Colours["blue"], Colours["white"], Colours["purple"]))
end

-- Entry point
Colours = GetColours()
CoreFrame = CreateCoreFrame()
DestroyItemButton = CreateButton()
Init()

-- EditBox:GetAltArrowKeyMode
