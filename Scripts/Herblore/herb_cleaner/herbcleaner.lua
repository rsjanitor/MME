--[[
Instructions & credits can be found in the github: https://github.com/rsjanitor/MME/tree/main/Scripts/herblore/herb_cleaner
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
local herbToClean = "Grimy avantoe"
local cleanHerbName = "Clean avantoe"
-- The Key is the grimy herb name
-- The Value is the ID of the grimy herb
local ingredientIDs = {
   ["Grimy avantoe"] = 211,
   ["Grimy irit"] = 209
}
--The Key is the clean herb name
--The Value is the:
--    ID - ID of the clean herb
--    interface - ID of the herblore interface that corresponds to the clean herb
--    guiName - The name you want to display on the GUI
local cleanHerbIDs = {
    ["Clean avantoe"] = {id = 261, interface = 57, guiName = "Clean avantoe"},
    ["Clean irit"] = {id = 259, interface = 49, guiName = "Clean irit"}
}

local keepRunning = true
local bankAttempt = 0
local presetKeyCode = 0x77
local startTime = os.time()
local startXp = API.GetSkillXP("HERBLORE")
local totalCleanedItemAmount = 0
local bankedLeatherAmount = 0

print("Starting herbcleaner")
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
    IG.box_name = "HERBXP"
    IG.colour = ImColor.new(255, 255, 255);
    IG.string_value = "Herblore  XP : 0 (0)"

    IG2 = API.CreateIG_answer()
    IG2.box_start = FFPOINT.new(15, 55, 0)
    IG2.box_name = "STRING"
    IG2.colour = ImColor.new(255, 255, 255);
    IG2.string_value = string.format("  %s : 0 (0)", cleanHerbIDs[cleanHerbName]["guiName"])

    IG3 = API.CreateIG_answer()
    IG3.box_start = FFPOINT.new(70, 5, 0)
    IG3.box_name = "TITLE"
    IG3.colour = ImColor.new(0, 255, 0);
    IG3.string_value = string.format("- Herb Cleaner v%s -", scriptVersion)

    IG4 = API.CreateIG_answer()
    IG4.box_start = FFPOINT.new(70, 21, 0)
    IG4.box_name = "TIME"
    IG4.colour = ImColor.new(255, 255, 255);
    IG4.string_value = "[00:00:00]"

    IG5 = API.CreateIG_answer()
    IG5.box_start = FFPOINT.new(15, 70, 0)
    IG5.box_name = "bankedLeatherAmount"
    IG5.colour = ImColor.new(255, 255, 255);
    IG5.string_value = string.format("Banked %s : %s",herbToClean,bankedLeatherAmount )

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
    local currentXp = API.GetSkillXP("HERBLORE")
    local elapsedMinutes = (os.time() - startTime) / 60
    local diffXp = math.abs(currentXp - startXp);
    local xpPH = round((diffXp * 60) / elapsedMinutes);
    local cleanedPH = round((totalCleanedItemAmount * 60) / elapsedMinutes);
    local time = formatElapsedTime(startTime)
    IG.string_value = string.format("HERBLORE XP : %s (%s)", formatNumberWithCommas(diffXp),formatNumberWithCommas(xpPH))
    IG2.string_value = string.format(" %s : %s (%s)", cleanHerbIDs[cleanHerbName]["guiName"],formatNumberWithCommas(totalCleanedItemAmount),formatNumberWithCommas(cleanedPH))
    IG4.string_value = time
    IG5.string_value = string.format("Banked %s : %s",herbToClean,bankedLeatherAmount )
    if final then
        print(string.format("Finished at %s. Runtime: %s \nHerblore XP: %s, \n%s : %s",os.date("%H:%M:%S"),time,formatNumberWithCommas(diffXp), cleanHerbIDs[cleanHerbName]["guiName"],formatNumberWithCommas(totalCleanedItemAmount)))
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
    Cleaning stuff starts here
]]--


local function barCheck() 
    local herb = API.GetABs_name1(herbToClean)
    if herb == nil then
        API.logError("Could not find " .. herb .. " on the action bar.")
        return false
    end
    return true
end



local function meetsMinimumCounts()
    local grimyHerbCount = API.InvItemcount_1(ingredientIDs[herbToClean])
    if (grimyHerbCount == nil or grimyHerbCount < 1) then
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

    local cleanedCount = API.InvItemcount_1(cleanHerbIDs[cleanHerbName]["id"])
    API.logDebug(string.format("Cleaned %d, adding to existing %d", cleanedCount,totalCleanedItemAmount))
    totalCleanedItemAmount = totalCleanedItemAmount + (cleanedCount == nill and 0 or cleanedCount)
    API.logDebug("Opening bank booth")
    --open bank booth
    API.DoAction_Object_string1(0x5, 80, { "Bank booth" }, 50, false)
    UTILS.randomSleep(1000)
    if API.BankOpen2() then
        bankedLeatherAmount = API.BankGetItemStack1(ingredientIDs[herbToClean])
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

local function openHerbloreInterface() 
    if not meetsMinimumCounts() then return false end
    local counter = 0
    while API.Read_LoopyLoop() and counter < 5 do
        API.DoAction_Ability(herbToClean, 1, API.OFF_ACT_GeneralInterface_route)
        UTILS.randomSleep(1000)
        if API.VB_FindPSett(2874, 1, 0).state == 40 then return true end
        counter = counter + 1
    end
    API.logError("Failed to open herblore interface")
    terminate()
    return false
end

local function selectHerb() 
    local counter = 0
    while API.Read_LoopyLoop() and counter < 3 do
        --If the herb is already selected, we can skip this
        if API.VB_FindPSett(1170, -1, 0).state == cleanHerbIDs[cleanHerbName]["id"] then return true end
        --if the herb is not selected, select it.
        API.DoAction_Interface(0xffffffff,0xffffffff,1,1371,22,cleanHerbIDs[cleanHerbName]["interface"],API.OFF_ACT_GeneralInterface_route);
        UTILS.randomSleep(500)
        counter = counter + 1
    end
    API.logError("Failed to select herb in cleaning menu.")
    terminate()
    return false
end

local function clean()
    --click the herb to open herblore menu
    API.DoAction_Ability(herbToClean, 1, API.OFF_ACT_GeneralInterface_route)
    --open the herblore interface and select the item
    if (openHerbloreInterface() and selectHerb()) then
        API.logDebug("Time to clean")
        API.RandomSleep2(600, 800, 1200)
        --press space to begin cleaning
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
        clean()
    end

    ::skip::
    printProgressReport(false)
    API.RandomSleep2(200, 400, 600);

end

print("Exiting herbcleaner")