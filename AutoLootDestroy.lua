local playerName = UnitName("player")
local ITEM_ID = 6265
local DEBUG = true -- Toggle with /ald debug
local ADDON_NAME = "Auto Loot Destroy"
local TOC_FILE_NAME = "AutoLootDestroy"
local WAIT_TIME = 0.1
SLASH_ALD1 = "/ald"
-- Core addon state tables
Colours = {}
CoreFrame = {}
DestroyItemButton = {}
PlayerBags = {}
PlayerInventory = {}
-- SavedVariables: ALD_Settings
Settings = {}
Settings.__index = Settings

function Settings:create(maxCount)
    local settings = {}
    setmetatable(settings, Settings)
    settings.maxItemCount = maxCount
    return settings
end

Bag = {}
Bag.__index = Bag

function Bag:create(name, bagId, invId, slotCount)
    local bag = {}
    setmetatable(bag, Bag)
    bag.name = name
    bag.bagId = bagId
    bag.invId = invId
    bag.slotCount = slotCount
    return bag
end

function GetBags()
    local bags = {}
    for bagId = 0, 4, 1 do
        local name = GetBagName(bagId)
        -- ALD_Print(format("Bag ID: %s. Bag name: %s", bagId, tostring(name)), true)
        if name ~= nil then
            local invId = nil
            local slotCount = nil
            if bagId == 0 then
                -- Default backpack has no Inventory ID, only a Container ID, and 16 slots
                slotCount = 16
            else
                -- Inventory ID: the bag's inventory ID used in functions like PutItemInBag(inventoryId)
                invId = ContainerIDToInventoryID(bagId)
                slotCount = GetContainerNumSlots(bagId)
                -- ALD_Print(format("Found bag with inv ID '%s', name '%s', and slot count '%s'", invId, name, slotCount), true)
            end
            local bag = Bag:create(name, bagId, invId, slotCount)
            bags[bagId] = bag
        end
    end
    return bags
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

function GetInventory()
    if PlayerBags == nil then
        PlayerBags = GetBags()
    end
    local totalSlots = 0
    local freeSlots = 0
    ALD_Print("Getting inventory data. Bag count: " .. tostring(#PlayerBags), true)
    for bagId = 0, #PlayerBags, 1 do
        totalSlots = totalSlots + PlayerBags[bagId].slotCount
        freeSlots = freeSlots + GetContainerNumFreeSlots(bagId)
    end
    local inventory = Inventory:create(totalSlots, totalSlots - freeSlots, freeSlots)
    return inventory
end

local function printInfo()
    ALD_Print(format("Item ID = %s. Max Item Count = %s.", ITEM_ID, ALD_Settings.maxItemCount))
end

function DestroyItems()
    local itemCount = GetItemCount(ITEM_ID)
    ALD_Print("Current item count: " .. itemCount, true)
    PlayerBags = GetBags()
    local bagCount = #PlayerBags
    if itemCount <= ALD_Settings.maxItemCount then
        ALD_Print(format("Player has less items than the max count of %s. Stopping deletion.", ALD_Settings.maxItemCount), true)
        return
    end
    local destroyCount = itemCount - ALD_Settings.maxItemCount
    ALD_Print("Destroy count: " .. destroyCount, true)
    local destroyCounter = destroyCount
    for bagId = 0, bagCount, 1 do
        ALD_Print("Checking Bag with ID: " .. bagId, true)
        if PlayerBags[bagId] ~= nil then
            ALD_Print("Bag slot count: " .. PlayerBags[bagId].slotCount, true)
            for slotId = 1, PlayerBags[bagId].slotCount, 1 do
                ClearCursor()
                local bagItemId = GetContainerItemID(bagId, slotId)
                if bagItemId ~= nil then
                    if bagItemId == ITEM_ID then
                        ALD_Print("Bag item qualifies for deletion. Bag ID: " .. bagId .. ". Slot ID: " .. slotId, true)
                        ALD_Print("Picking up container item", true)
                        PickupContainerItem(bagId, slotId)
                        if CursorHasItem() then
                            ALD_Print("Deleting cursor item", true)
                            DeleteCursorItem()
                            itemCount = GetItemCount(ITEM_ID)
                            destroyCounter = destroyCounter - 1
                            ALD_Print("New destroy counter: " .. destroyCounter, true)
                            if itemCount <= ALD_Settings.maxItemCount or destroyCounter <= 0 then
                                ALD_Print("Item count reached max. " .. ALD_Settings.maxItemCount .. " Stopping deletion.", true)
                                return
                            end
                        end
                    end
                end
            end
        end
    end
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

function LootEventHandler()
    ALD_Print("Loot event handler called...", true)
    -- Hardware event for DestroyCursorItem()
    DestroyItemButton:Click()
end

function EventHandlerWait(self, event, arg1, arg2, arg3, arg4, arg5)
    ALD_Print("Event fired: " .. event, true)
    ALD_Print(format("Event args: 1. %s, 2. %s, 3. %s, 4. %s, 5. %s", tostring(arg1), tostring(arg2), tostring(arg3), tostring(arg4), tostring(arg5)), true)
    if event == "CHAT_MSG_LOOT" then
        if arg5 ~= playerName then
            return
        end
        C_Timer.After(WAIT_TIME, LootEventHandler)
        -- Initialise once SavedVariables loaded
    elseif event == "ADDON_LOADED" then
        if arg1 == TOC_FILE_NAME then
            ALD_Print("--- " .. TOC_FILE_NAME .. "loaded. ---", true)
            Init()
        end
    end
end

local function round(number)
    if (number - (number % 0.1)) - (number - (number % 1)) < 0.5 then
        number = number - (number % 1)
    else
        number = (number - (number % 1)) + 1
    end
    return number
end

local function setMaxItemCount(countStr)
    local countNum = tonumber(countStr)
    if countNum ~= nil and countNum > 0 then
        local rounded = round(countNum)
        -- Prevent floating point value
        if rounded ~= countNum then
            ALD_Print(format("Input has been rounded to the nearest integer: %s -> %s.", countNum, rounded))
            countNum = rounded
        end
        ALD_Settings.maxItemCount = countNum
    else
        ALD_Print("Invalid max item count input: " .. countStr .. ". Please use a valid positive integer.")
    end
    printInfo()
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
            printInfo()
            -- Set max item count
        elseif arg1 == "SETMAX" then
            if args[2] ~= nil then
                setMaxItemCount(args[2])
            end
            -- Manual trigger destroy
        elseif arg1 == "DESTROY" then
            ALD_Print("Destroying items...", false)
            DestroyItemButton:Click()
            -- List commands
        elseif arg1 == "HELP" then
            ALD_Print(format("Type |%s/ald info |%sto get the current settings.", Colours["greenHex"], Colours["blueHex"]))
            ALD_Print(format("Type |%s/ald setmax [max item count] |%sto set the max no. of items. Or you can use the Interface Options.",
                Colours["greenHex"], Colours["blueHex"]))
            ALD_Print(format("Type |%s/ald destroy |%sto trigger a destroy manually.", Colours["greenHex"], Colours["blueHex"]))
        elseif arg1 == "DEBUG" then
            DEBUG = not DEBUG
        end
    end
end

local function createInterfaceOptions()
    -- Container
    local optionsFrame = CreateFrame("Frame", "ALD_OptionsFrame")
    optionsFrame.name = ADDON_NAME
    InterfaceOptions_AddCategory(optionsFrame)
    local title = optionsFrame:CreateFontString("ALD_TitleFontString", nil, "GameFontNormalLarge")
    title:SetTextScale(1.5)
    title:SetPoint("TOP", 12, -12)
    title:SetText(format("|%s%s", Colours["purpleHex"], ADDON_NAME))
    -- Item count edit box
    local maxCountEditBox = CreateFrame("EditBox", nil, optionsFrame, "InputBoxTemplate")
    maxCountEditBox:SetAutoFocus(false)
    maxCountEditBox:SetFrameStrata("DIALOG")
    maxCountEditBox:SetSize(48, 16)
    maxCountEditBox:SetPoint("TOPLEFT", 152, -64)
    -- Label for edit box
    local maxCountLabel = optionsFrame:CreateFontString("ALD_IdEditBoxLabelFontString", nil, "GameFontNormal")
    maxCountLabel:SetTextScale(1.25)
    maxCountLabel:SetText("Max Item Count:")
    maxCountLabel:SetPoint("TOPLEFT", 16, -64)
    maxCountLabel:SetTextColor(Colours["purpleRgb"][1], Colours["purpleRgb"][2], Colours["purpleRgb"][3], 1)
    -- Total bag slots text
    local totalSlotsText = optionsFrame:CreateFontString("ALD_TotalSlotsText", nil, "GameFontNormal")
    totalSlotsText:SetTextScale(1.25)
    totalSlotsText:SetText(format("Total Bag Slots: %s", tostring(Inventory.totalSlots)))
    totalSlotsText:SetPoint("TOPLEFT", 256, -64)
    totalSlotsText:SetTextColor(Colours["purpleRgb"][1], Colours["purpleRgb"][2], Colours["purpleRgb"][3], 1)
    -- Set max item count when exiting options
    InterfaceOptionsFrame:HookScript("OnHide", function()
        local editBoxText = maxCountEditBox:GetText()
        ALD_Print("Edit box input text on hide: " .. editBoxText .. " Edit box text == nil " .. tostring(editBoxText == nil), true)
        setMaxItemCount(editBoxText)
    end)
    -- Populate edit box with current settings when opening options
    InterfaceOptionsFrame:HookScript("OnShow", function()
        PlayerBags = GetBags()
        PlayerInventory = GetInventory(PlayerBags)
        totalSlotsText:SetText("Total Bag Slots: " .. tostring(PlayerInventory.totalSlots))
        maxCountEditBox:SetText(tostring(ALD_Settings.maxItemCount))
    end)
end

local function setAltArrowKeyModes()
    for i = 1, NUM_CHAT_WINDOWS do
        _G["ChatFrame" .. i .. "EditBox"]:SetAltArrowKeyMode(false)
    end
end

local function clickHandler(self, event)
    ALD_Print("Click handler called...", true)
    DestroyItems()
end

function CreateCoreFrame()
    -- Create frame for subscribing to events
    local coreFrame = CreateFrame("FRAME", "ALD_CoreFrame")
    coreFrame:RegisterEvent("CHAT_MSG_LOOT")
    coreFrame:RegisterEvent("ADDON_LOADED")
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
    -- Hex codes and rgb for printing coloured text
    colours["redHex"] = "cFFFF2400"
    colours["greenHex"] = "cFF138808"
    colours["blueHex"] = "cFF6CA0DC"
    colours["purpleHex"] = "cFFBF40BF"
    colours["purpleRgb"] = { 0.75, 0.25, 0.75, 1 }
    colours["whiteHex"] = "cFFFFFFFF"
    return colours
end

function ALD_Print(msg, debug)
    if debug and not DEBUG then
        return
    end
    print(format("|%sAuto Loot Destroy|%s: |%s" .. tostring(msg),
        Colours["purpleHex"], Colours["whiteHex"], Colours["blueHex"]))
end

function Init()
    -- Create settings if first time using addon
    if ALD_Settings == nil then
        ALD_Print("Thanks for installing " .. ADDON_NAME .. ".")
        if PlayerInventory == nil or PlayerInventory.totalSlots == nil then
            PlayerInventory = GetInventory()
        end
        -- No items will be destroyed unless configuration is setup
        ALD_Settings = Settings:create(PlayerInventory.totalSlots)
    end
    ALD_Print(format("Type |%s/ald help |%sto list the slash commands for this addon.",
        Colours["greenHex"], Colours["blueHex"]), false)
    setSlashCmds()
    createInterfaceOptions()
    setAltArrowKeyModes()
end

-- Entry point
CoreFrame = CreateCoreFrame()
DestroyItemButton = CreateButton()
Colours = GetColours()
PlayerBags = GetBags()
