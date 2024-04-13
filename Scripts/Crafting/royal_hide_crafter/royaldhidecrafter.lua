--[[
Instructions & credits can be found in the github: https://github.com/rsjanitor/MME/Scripts/Crafting/royal_hide_crafter
--]]


--[[
    Libs
 ]]--
local API = require("api")
local UTILS = require("utils")


--[[
   Variables
 ]]--
local scriptVersion = "1.0"
local leatherName = "Royal dragon leather"
local craftItemName = "Royal dragonhide body"
local ingredientIDs = {
   ["Royal dragon leather"] = 24374,
   ["Thread"] = 1734
}
local craftItemIDs = {
    ["Royal dragonhide body"] = {id = 24382, interface = 17, guiName = "Royal Dhide Body"}
}

local keepRunning = true
local bankAttempt = 0
local presetKeyCode = 0x78
local startTime = os.time()
local startXp = API.GetSkillXP("CRAFTING")
local totalCraftedItemCount = 0
local bankedLeatherAmount = 0

print("Starting r_dhide_body")
API.SetDrawLogs(true)

--[[
    GUI Stuff
 ]]--

--[[Lifted original code from
Author: Higgins
Script: Lumbridge Castle Flax Spinner
--]]
-- Format a number with commas as thousands separator
local function formatNumberWithCommas(amount)
    local formatted = tostring(amount)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then
            break
        end
    end
    return formatted
end

--[[Lifted original code from
Author: Higgins
From Script: Lumbridge Castle Flax Spinner
--]]
-- Format script elapsed time to [hh:mm:ss]
local function formatElapsedTime(startTime)
    local currentTime = os.time()
    local elapsedTime = currentTime - startTime
    local hours = math.floor(elapsedTime / 3600)
    local minutes = math.floor((elapsedTime % 3600) / 60)
    local seconds = elapsedTime % 60
    return string.format("[%02d:%02d:%02d]", hours, minutes, seconds)
end

--[[Lifted original code from
Author: Higgins
From Script: Lumbridge Castle Flax Spinner
--]]
-- Rounds a number to the nearest integer or to a specified number of decimal places.
local function round(val, decimal)
    if decimal then
        return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
    else
        return math.floor(val + 0.5)
    end
end

--[[Lifted original code from
Author: Higgins
From Script: Lumbridge Castle Flax Spinner
--]]
local function setupGUI()
    IG = API.CreateIG_answer()
    IG.box_start = FFPOINT.new(15, 40, 0)
    IG.box_name = "CRAFT"
    IG.colour = ImColor.new(255, 255, 255);
    IG.string_value = "Crafting XP : 0 (0)"

    IG2 = API.CreateIG_answer()
    IG2.box_start = FFPOINT.new(15, 55, 0)
    IG2.box_name = "STRING"
    IG2.colour = ImColor.new(255, 255, 255);
    IG2.string_value = string.format("  %s : 0 (0)", craftItemIDs[craftItemName]["guiName"])

    IG3 = API.CreateIG_answer()
    IG3.box_start = FFPOINT.new(0, 5, 0)
    IG3.box_name = "TITLE"
    IG3.colour = ImColor.new(0, 255, 0);
    IG3.string_value = string.format("- Royal Dragon Leather Crafter v%s -", scriptVersion)

    IG4 = API.CreateIG_answer()
    IG4.box_start = FFPOINT.new(70, 21, 0)
    IG4.box_name = "TIME"
    IG4.colour = ImColor.new(255, 255, 255);
    IG4.string_value = "[00:00:00]"

    IG5 = API.CreateIG_answer()
    IG5.box_start = FFPOINT.new(15, 70, 0)
    IG5.box_name = "bankedLeatherAmount"
    IG5.colour = ImColor.new(255, 255, 255);
    IG5.string_value = string.format("Banked %s : %s",leatherName,bankedLeatherAmount )

    IG_Back = API.CreateIG_answer();
    IG_Back.box_name = "back";
    IG_Back.box_start = FFPOINT.new(0, 0, 0)
    IG_Back.box_size = FFPOINT.new(275, 90, 0)
    IG_Back.colour = ImColor.new(15, 13, 18, 255)
    IG_Back.string_value = ""

    --Pulled this from Dead's Digger script.
    IG_Terminate = API.CreateIG_answer()
    IG_Terminate.box_name = "Stop Script"
    IG_Terminate.box_start = FFPOINT.new(150, 10, 0)
    IG_Terminate.box_size = FFPOINT.new(100, 30, 0)
    IG_Terminate.tooltip_text = "Exit the script"
end

--[[Lifted original code from
Author: Higgins
From Script: Lumbridge Castle Flax Spinner
--]]
local function printProgressReport(final)
    local currentXp = API.GetSkillXP("CRAFTING")
    local elapsedMinutes = (os.time() - startTime) / 60
    local diffXp = math.abs(currentXp - startXp);
    local xpPH = round((diffXp * 60) / elapsedMinutes);
    local craftedPH = round((totalCraftedItemCount * 60) / elapsedMinutes);
    local time = formatElapsedTime(startTime)
    IG.string_value = string.format("Crafting XP : %s (%s)", formatNumberWithCommas(diffXp),formatNumberWithCommas(xpPH))
    IG2.string_value = string.format(" %s : %s (%s)", craftItemIDs[craftItemName]["guiName"],formatNumberWithCommas(totalCraftedItemCount),formatNumberWithCommas(craftedPH))
    IG4.string_value = time
    IG5.string_value = string.format("Banked %s : %s",leatherName,bankedLeatherAmount )
    if final then
        print(string.format("Finished at %s. Runtime: %s \nCrafting XP: %s, \n%s : %s",os.date("%H:%M:%S"),time,formatNumberWithCommas(diffXp), craftItemIDs[craftItemName]["guiName"],formatNumberWithCommas(totalCraftedItemCount)))
    end
end


local function terminate()
    API.logDebug("terminate() was called.")
    keepRunning = false
    API.Write_LoopyLoop(false)
    printProgressReport(true)
end

--[[Lifted original code from
Author: Higgins
From Script: Lumbridge Castle Flax Spinner
--]]
function drawGUI()
    if IG_Terminate.return_click then
        terminate()
    end
    API.DrawSquareFilled(IG_Back)
    API.DrawTextAt(IG)
    API.DrawTextAt(IG2)
    API.DrawTextAt(IG3)
    API.DrawTextAt(IG4)
    API.DrawTextAt(IG5)
    API.DrawBox(IG_Terminate)
end

--[[
    Crafting stuff starts here
]]--


local function barCheck() 
    local leather = API.GetABs_name1(leatherName)
    if leather == nil then
        API.logError("Could not find " .. leather .. " on the action bar.")
        return false
    end
    return true
end



local function meetsMinimumCounts()
    local leatherCount = API.InvItemcount_1(ingredientIDs[leatherName])
    local threadCount = API.InvStackSize(ingredientIDs["Thread"])
    if (leatherCount == nil or leatherCount < 3) or (threadCount == nil or threadCount < 1) then
        API.logError("Failed to meet the minimum crafting requirements. Must have at least 1 thread and 3 leathers.")
        return false
    end
    return true
    
end

local function bank()
    if bankAttempt > 2 then
        API.logError("Failed to bank.")
        terminate()
        return false
    end

    local craftedCount = API.InvItemcount_1(craftItemIDs[craftItemName]["id"])
    API.logDebug(string.format("Crafted %d, adding to existing %d", craftedCount,totalCraftedItemCount))
    totalCraftedItemCount = totalCraftedItemCount + (craftedCount == nill and 0 or craftedCount)
    API.logDebug("Opening bank booth")
    --open bank booth
    API.DoAction_Object_string1(0x5, 80, { "Bank booth" }, 50, false)
    UTILS.randomSleep(1000)
    if API.BankOpen2() then
        bankedLeatherAmount = API.BankGetItemStack1(ingredientIDs[leatherName])
        API.logDebug("Bank is open")
    --Press preset key
        API.KeyboardPress2(presetKeyCode,60, 100)
        UTILS.randomSleep(600)
    end

    if meetsMinimumCounts() then
        bankAttempt = 0
        printProgressReport(false)
        return true
    else
        bankAttempt = bankAttempt + 1
        return false
    end


end

local function openCraftingInterface() 
    if not meetsMinimumCounts() then return false end
    local counter = 0
    while API.Read_LoopyLoop() and counter < 5 do
        API.DoAction_Ability(leatherName, 1, API.OFF_ACT_GeneralInterface_route)
        UTILS.randomSleep(1000)
        if API.VB_FindPSett(2874, 1, 0).state == 40 then return true end
        counter = counter + 1
    end
    API.logError("Failed to open crafting interface")
    terminate()
    return false
end

local function selectLeatherArmour() 
    local counter = 0
    while API.Read_LoopyLoop() and counter < 3 do
        API.DoAction_Interface(0xffffffff,0xffffffff,1,1371,22,craftItemIDs[craftItemName]["interface"],3808);
        UTILS.randomSleep(500)
        if API.VB_FindPSett(1170, -1, 0).state == craftItemIDs[craftItemName]["id"] then return true end
        counter = counter + 1
    end
    API.logError("Failed to select armour.")
    terminate()
    return false
end

local function craft()
    --click the leather to open crafting menu
    API.DoAction_Ability(leatherName, 1, API.OFF_ACT_GeneralInterface_route)
    --open the crafting interface and select the item
    if (openCraftingInterface() and selectLeatherArmour()) then
        API.logDebug("Time to craft")
        --space to begin crafting
        API.KeyboardPress2(0x20, 60, 100)
        API.RandomSleep2(600, 800, 1200)

    end
end

setupGUI()

--[[
   Copped the jump/anim check from Higgin's Lumbridge Castle Flax Spinner
]]--
while API.Read_LoopyLoop() do
    drawGUI()
    if not keepRunning then 
        break 
    end
    API.DoRandomEvents()
    if API.CheckAnim(10) or API.isProcessing() or API.ReadPlayerMovin2() then
        API.RandomSleep2(600, 200, 200);
        goto skip
    end
    API.logDebug("passed checkanim")
    barCheck()
    if bank() then
        craft()
    end

    ::skip::
    printProgressReport(false)
    API.RandomSleep2(200, 400, 600);

end

print("Exiting r_dhide_body")