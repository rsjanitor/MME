--[[
Instructions & credits can be found in the github: https://github.com/rsjanitor/MME/tree/main/Scripts/Herblore/herb_cleaner
--]]

--[[Important IDs to update:
potionList - ids(hover over inventory), potionInterfaceID(doaction)
herbloreInterfaceCategoryIDs - DropdownID(doaction), ids (idGrabber.lua)
--]]


--[[
    Libs
 ]]--
local API = require("api")
local UTILS = require("utils")
API.SetDrawLogs(true)
local startTime = os.time()
local startXp = API.GetSkillXP("HERBLORE")
local potionObject = nil
local usableActionBarIngredientName = nil
local bankAttempt = 0
local presetKeyCode = 0x76
local totalPotionCreatedAmount = 0
local bankedIngredients = {}
local dynamicGuiIngredients = {}
local Potion = {}
Potion.__index = Potion
function Potion:new(o,i,n,ing,icid,ddci, pii)
    return setmetatable( {
        id = i,
        name = n,
        ingredients = ing,
        interfaceCategoryID = icid,-- ID of category of stuff like Unfinished potions, clean herb, Barbarian Mixes, etc.
        dropDownCategoryID = ddci, -- each dropdown has its own specific id
        potionInterfaceID = pii -- each of the potion squares that u click to select the potion have their own id

    }, self)
end

function Potion:populateIngredientBankCount()
    local i = 1
    while API.Read_LoopyLoop() and i < #self.ingredients + 1  do
     --   print("Populating: " .. self.ingredients[i].name)
        bankedIngredients[self.ingredients[i].name] = self.ingredients[i]:getBankStackCount() 
        i = i + 1
    end
end


function Potion:checkInventoryForMinimumIngredients()
    local result = true
    
   --[[ for i = 1, #self.ingredients do
        if not self.ingredients[i]:minimumQuantityInInventory() then return false end
    end]]--
    local i = 1
    while API.Read_LoopyLoop() and i < #self.ingredients + 1 do
        if not self.ingredients[i]:minimumQuantityInInventory() then return false end
        i = i + 1
    end
    return true
end

function Potion:getUsableInActionBarIngredient()
    local i = 1
    while API.Read_LoopyLoop() and i < #self.ingredients + 1 do
        if self.ingredients[i].useInActionBar then
            return self.ingredients[i].name
        end
        i = i + 1
    end
    return nil

end



function Potion:print()
    local str = ""
    for i=1, #self.ingredients do
        str = str .. "\n\t"  ..tostring(self.ingredients[i])
    end
    print(string.format("Potion ID: %s, potion name: %s, potion ingredients: [%s]", self.id, self.name, str))
end


local Ingredient = {}
print("starting potionmaker")
Ingredient.__index = Ingredient

function Ingredient:new(o,q,i,n, uiab)
    return setmetatable( {
        id = i,
        quantity = q,
        name = n,
        useInActionBar = uiab

    }, self)
end

function Ingredient:__tostring()
    return string.format("Ingredient id: %s, ingredient quantity: %s, ingredient name: %s", self.id, self.quantity, self.name)
end


function Ingredient:print()
    print(string.format("id: %s, quantity: %s, name: %s", self.id, self.quantity, self.name))
end

function Ingredient:getInventoryCount() 
    return API.InvItemcount_1(self.id)
end

function Ingredient:getBankStackCount() 
    return API.BankGetItemStack1(self.id)
end

function Ingredient:minimumQuantityInInventory() 
    local inventoryQuantity = API.InvItemcount_1(self.id)
    local requiredQuantity = self.quantity
    local result = inventoryQuantity >=  requiredQuantity
    API.logDebug(string.format("Ingredient:minimumQuantityInInventory(): %s - inventory: %s, required: %s, result: %s", self.name,inventoryQuantity,requiredQuantity, tostring(result)))
    return result
end

--[[
   Variables
 ]]--

        --id is the ID of the itemName
    --potionInterfaceID is the ID from doaction and clicking the thing you want to craft.
local scriptVersion = "1.1"
local keepRunning = true
local clickIngredient = true
local potionList = {
        --id is the ID of the itemName
    --potionInterfaceID is the ID from doaction and clicking the thing you want to craft.
    ["Snapdragon potion (unf)"] = {
        ["ingredients"] = {
            ["Vial of water"] = {
                ["quantity"] = 1,
                ["id"] = 227,
                ["useInActionBar"] = true
            }, 
            ["Clean snapdragon"] = {
                ["quantity"] = 1,
                ["id"] = 3000,
                ["useInActionBar"] = false
            }

         },
        ["id"]  = 3004,
        ["interfaceCategory"] = "Unfinished Potions",
        ["potionInterfaceID"] = 69
    },
    ["Super restore (3)"] = {
        ["ingredients"] = {
            ["Snapdragon potion (unf)"] = {
                ["quantity"] = 1,
                ["id"] = 3004,
                ["useInActionBar"] = true
            },
            ["Red spiders' eggs"] = {
                ["quantity"] = 1,
                ["id"] = 223,
                ["useInActionBar"] = false
            }
        },
        ["id"] = 3026,
        ["interfaceCategory"] = "Potions",
        ["potionInterfaceID"] = 149
    },
    ["Attack potion (3)"] = {
        ["ingredients"] = {
            ["Guam potion (unf)"] = {
                ["quantity"] = 1,
                ["id"] = 91,
                ["useInActionBar"] = true
            },
            ["Eye of newt"] = {
                ["quantity"] = 1,
                ["id"] = 221,
                ["useInActionBar"] = false
            }

        },
        ["id"] = 121,
        ["interfaceCategory"] = "Potions",
        ["potionInterfaceID"] = 1
    },
    ["Super defence (3)"] = {
        ["ingredients"] = {
            ["Cadantine potion (unf)"] = {
                ["quantity"] = 1,
                ["id"] = 107,
                ["useInActionBar"] = true
            },
            ["White berries"] = {
                ["quantity"] = 1,
                ["id"] = 239,
                ["useInActionBar"] = false
            }

        },
        ["id"] = 163,
        ["interfaceCategory"] = "Potions",
        ["potionInterfaceID"] = 173
    },
    ["Extreme defence (3)"] = {
        ["ingredients"] = {
            ["Super defence (3)"] = {
                ["quantity"] = 1,
                ["id"] = 163,
                ["useInActionBar"] = false
            },
            ["Clean lantadyme"] = {
                ["quantity"] = 1,
                ["id"] = 2481,
                ["useInActionBar"] = false
            }

        },
        ["id"] = 15317,
        ["interfaceCategory"] = "Potions",
        ["potionInterfaceID"] = 301
    },
    ["Super magic potion (3)"] = {
        ["ingredients"] = {
            ["Potato cactus"] = {
                ["quantity"] = 1,
                ["id"] = 3138,
                ["useInActionBar"] = false
            },
            ["Lantadyme potion (unf)"] = {
                ["quantity"] = 1,
                ["id"] = 2483,
                ["useInActionBar"] = true
            }

        },
        ["id"] = 3042,
        ["interfaceCategory"] = "Potions",
        ["potionInterfaceID"] = 217
    },
    ["Extreme magic (3)"] = {
        ["ingredients"] = {
            ["Super magic potion (3)"] = {
                ["quantity"] = 1,
                ["id"] = 3042,
                ["useInActionBar"] = false
            },
            ["Ground mud runes"] = {
                ["quantity"] = 1,
                ["id"] = 9594,
                ["useInActionBar"] = false
            }

        },
        ["id"] = 15321,
        ["interfaceCategory"] = "Potions",
        ["potionInterfaceID"] = 309
    },
    ["Super attack (3)"] = {
        ["ingredients"] = {
            ["Irit potion (unf)"] = {
                ["quantity"] = 1,
                ["id"] = 101,
                ["useInActionBar"] = true
            },
            ["Eye of newt"] = {
                ["quantity"] = 1,
                ["id"] = 221,
                ["useInActionBar"] = false
            }

        },
        ["id"] = 145,
        ["interfaceCategory"] = "Potions",
        ["potionInterfaceID"] = 89
    },
    ["Extreme attack (3)"] = {
        ["ingredients"] = {
            ["Super attack (3)"] = {
                ["quantity"] = 1,
                ["id"] = 145,
                ["useInActionBar"] = false
            },
            ["Clean avantoe"] = {
                ["quantity"] = 1,
                ["id"] = 261,
                ["useInActionBar"] = false
            }

        },
        ["id"] = 15309,
        ["interfaceCategory"] = "Potions",
        ["potionInterfaceID"] = 289
    },
    ["Super ranging potion (3)"] = {
        ["ingredients"] = {
            ["Dwarf weed potion (unf)"] = {
                ["quantity"] = 1,
                ["id"] = 109,
                ["useInActionBar"] = true
            },
            ["Wine of Zamorak"] = {
                ["quantity"] = 1,
                ["id"] = 245,
                ["useInActionBar"] = false
            }

        },
        ["id"] = 169,
        ["interfaceCategory"] = "Potions",
        ["potionInterfaceID"] = 193
    },
    ["Extreme ranging (3)"] = {
        ["ingredients"] = {
            ["Super ranging potion (3)"] = {
                ["quantity"] = 1,
                ["id"] = 169,
                ["useInActionBar"] = false
            },
            ["Grenewall spikes"] = {
                ["quantity"] = 1,
                ["id"] = 12539,
                ["useInActionBar"] = false
            }

        },
        ["id"] = 15325,
        ["interfaceCategory"] = "Potions",
        ["potionInterfaceID"] = 317
    },
    ["Super necromancy (3)"] = {
        ["ingredients"] = {
            ["Spirit weed potion (unf)"] = {
                ["quantity"] = 1,
                ["id"] = 12181,
                ["useInActionBar"] = true
            },
            ["Congealed blood"] = {
                ["quantity"] = 1,
                ["id"] = 37227,
                ["useInActionBar"] = false
            }

        },
        ["id"] = 55318,
        ["interfaceCategory"] = "Potions",
        ["potionInterfaceID"] = 245
    },
    ["Extreme necromancy (3)"] = {
        ["ingredients"] = {
            ["Super necromancy (3)"] = {
                ["quantity"] = 1,
                ["id"] = 55318,
                ["useInActionBar"] = false
            },
            ["Ground miasma rune"] = {
                ["quantity"] = 1,
                ["id"] = 55697,
                ["useInActionBar"] = false
            }

        },
        ["id"] = 55326,
        ["interfaceCategory"] = "Potions",
        ["potionInterfaceID"] = 321
    }
    
}
local herbloreInterfaceCategoryIDs = {
    --DropdownID is grabbed from doaction, second to last arg.
    --id is grabbed from offset 6404
    ["Clean Herbs"] = {id = 6841, dropDownId = 1},
    ["Unfinished Potions"] = {id = 6842, dropDownId = 3},
    ["Potions"] = {id = 6843, dropDownId = 5},
    ["Barbarian Mixes"] = {id = 6844, dropDownId = 7},
    ["Clean Juju Herbs"] = {id = 6845, dropDownId = 9},
    ["Unfinished Juju Potions"] = {id = 6846, dropDownId = 11},
    ["Juju Potions"] = {id = 6847, dropDownId = 13},
    ["Combination Potions"] = {id = 9470, dropDownId = 15},
    ["Powerburst Potions"] = {id = 15759, dropDownId = 17},
    ["Bombs"] = {id = 15760, dropDownId = 19},
    ["Primal extract potions"] = {id = 15761, dropDownId = 21}
 }

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
    IG2.string_value = string.format("  %s : 0 (0)", potionObject.name)

    IG3 = API.CreateIG_answer()
    IG3.box_start = FFPOINT.new(70, 5, 0)
    IG3.box_name = "TITLE"
    IG3.colour = ImColor.new(0, 255, 0);
    IG3.string_value = string.format("- Potion Maker v%s -", scriptVersion)

    IG4 = API.CreateIG_answer()
    IG4.box_start = FFPOINT.new(70, 21, 0)
    IG4.box_name = "TIME"
    IG4.colour = ImColor.new(255, 255, 255);
    IG4.string_value = "[00:00:00]"

    IG_Back = API.CreateIG_answer();
    IG_Back.box_name = "back";
    IG_Back.box_start = FFPOINT.new(0, 0, 0)
    IG_Back.box_size = FFPOINT.new(300, 80  + (#potionObject.ingredients * 20), 0)
    IG_Back.colour = ImColor.new(15, 13, 18, 255)
    IG_Back.string_value = ""

    for i = 1, #potionObject.ingredients do
        local name = potionObject.ingredients[i].name
        dynamicGuiIngredients[name] =  API.CreateIG_answer();
        local ig = dynamicGuiIngredients[name]
        ig.box_start = FFPOINT.new(15, 60 + (13 * i ), 0)
        ig.box_name = name
        ig.colour = ImColor.new(255, 255, 255);
        ig.string_value = string.format("Banked %s : %s",name, "0" )
      end

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
    for i, v in pairs( bankedIngredients ) do
        local ig =  dynamicGuiIngredients[i]
        ig.string_value = string.format("Banked %s : %s",i, v)
      end
    
    local currentXp = API.GetSkillXP("HERBLORE")
    local elapsedMinutes = (os.time() - startTime) / 60
    local diffXp = math.abs(currentXp - startXp);
    local xpPH = round((diffXp * 60) / elapsedMinutes);
    local cleanedPH = round((totalPotionCreatedAmount * 60) / elapsedMinutes);
    local time = formatElapsedTime(startTime)
    IG.string_value = string.format("HERBLORE XP : %s (%s)", formatNumberWithCommas(diffXp),formatNumberWithCommas(xpPH))
    IG2.string_value = string.format(" %s : %s (%s)", potionObject.name,formatNumberWithCommas(totalPotionCreatedAmount),formatNumberWithCommas(cleanedPH))
    IG4.string_value = time
    --IG5.string_value = string.format("Banked %s : %s","TODOBANKNAMED","TODOBANKEDQUANTITY" )
    if final then
        print(string.format("Finished at %s. Runtime: %s \nHerblore XP: %s, \n%s : %s",os.date("%H:%M:%S"),time,formatNumberWithCommas(diffXp), potionObject.name,formatNumberWithCommas(totalPotionCreatedAmount)))
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
    --API.DrawTextAt(IG5)
    for i = 1, #potionObject.ingredients do
        local ig = dynamicGuiIngredients[potionObject.ingredients[i].name]
        API.DrawTextAt(ig)
      end
    API.DrawBox(IG_Terminate)
end



local function populateIngredientObjects(potionName) 
    local ingredients = potionList[potionName]["ingredients"]
    local ingredientObjects = {}
    for key,value in pairs(ingredients) do
        ingredientObjects[#ingredientObjects + 1] = Ingredient:new(nil,value["quantity"],value["id"],key, value["useInActionBar"])
    end
    return ingredientObjects

end


local function isCorrectHerbloreInterfaceCategory(potCategoryID)
    return API.VB_FindPSett(6404, -1, 0).state == potCategoryID
end

local function populatePotionObject(targetPotion)
    --[[
    id = i,
    name = n,
    ingredients = ing,
    interfaceCategoryID = icid,-- ID of category of stuff like Unfinished potions, clean herb, Barbarian Mixes, etc.
    dropDownCategoryID = ddci, -- each dropdown has its own specific id
    potionInterfaceID = pii -- each of the potion squares that u click to select the potion have their own id
    --]]
    local id = potionList[targetPotion]["id"]
    local potCategory = potionList[targetPotion]["interfaceCategory"]
    local interfaceCategoryID = herbloreInterfaceCategoryIDs[potCategory]["id"]
    local dropDownCategoryID = herbloreInterfaceCategoryIDs[potCategory]["dropDownId"]
    local potioninterfaceID =  potionList[targetPotion]["potionInterfaceID"]
    
    potionObject = Potion:new(nil, id,targetPotion,populateIngredientObjects(targetPotion),interfaceCategoryID, dropDownCategoryID, potioninterfaceID)

end

local function checkInterfaceDropdown(dropdownId)
    API.logDebug("Inside checkInterfaceDropdown")
    local counter = 0
    while API.Read_LoopyLoop() and  not isCorrectHerbloreInterfaceCategory(potionObject.interfaceCategoryID) do
        if counter > 4 then
            API.logError("Could not select the correct Herblore dropdown category")
            return false
        end
        --open dropdown
        API.DoAction_Interface(0x2e,0xffffffff,1,1371,28,-1,API.OFF_ACT_GeneralInterface_route);
        API.RandomSleep2(600, 800, 1200)
        --click on the category
        API.DoAction_Interface(0xffffffff,0xffffffff,1,1477,893,dropdownId,API.OFF_ACT_GeneralInterface_route);
        API.RandomSleep2(600, 800, 1200)
        counter = counter + 1

    end

    return true
end

local function checkInterfacePotionSelected(targetPotionId,potionInterfaceId) 
    API.logDebug("Inside checkInterfacePotionSelected")
    local counter = 0
    while API.Read_LoopyLoop() and counter < 3 do
        --If the potion is already selected, we can skip this
        if API.VB_FindPSett(1170, -1, 0).state == targetPotionId then return true end
        --if the potion is not selected, select it.
        API.DoAction_Interface(0xffffffff,0xffffffff,1,1371,22,potionInterfaceId,API.OFF_ACT_GeneralInterface_route);
        UTILS.randomSleep(890)
        counter = counter + 1
    end
    API.logError("Failed to select the potion in the interface.")
    terminate()
    return false
end

local function  isInterfaceOpen() 
    return API.VB_FindPSett(2874, 1, 0).state == 1310738 or API.VB_FindPSett(2874, 1, 0).state == 40 
end

local function openHerbloreInterface() 
    API.logDebug("Inside openHerbloreInterface")
    local counter = 0
    while API.Read_LoopyLoop() and counter < 3 do
        --Checks if inteface is up
        if API.VB_FindPSett(2874, 1, 0).state == 1310738 or API.VB_FindPSett(2874, 1, 0).state == 40  then return true end
        --Clicks portable well
        API.DoAction_Object_string1(0x29, API.OFF_ACT_GeneralObject_route0, { "Portable well" }, 60, true);
        UTILS.randomSleep(1000)
        counter = counter + 1
    end
    API.logError("Failed to open herblore interface")
    terminate()
    return false
end

local function barCheck(itemName) 
    if API.GetABs_name1(itemName).id <= 0 then
        API.logError("Could not find " .. itemName .. " on the action bar.")
        terminate()
        return false
    end
    return true
end

local function bank()
    if potionObject:checkInventoryForMinimumIngredients() then
        bankAttempt = 0
        printProgressReport(false)
        return true
    end
    
    if bankAttempt > 2 then
        API.logError("Failed to bank.")
        terminate()
        return false
    end

    local potionMadeCount = API.InvItemcount_1(potionObject.id)
    API.logDebug(string.format("Cleaned %d, adding to existing %d", potionMadeCount,totalPotionCreatedAmount))
    totalPotionCreatedAmount = totalPotionCreatedAmount + (potionMadeCount == nil and 0 or potionMadeCount)
    API.logDebug("Opening bank booth")
    --open bank booth
    API.DoAction_Object_string1(0x5, 80, { "Bank booth", "Bank chest" }, 50, false)
    UTILS.randomSleep(1000)
    if API.BankOpen2() then
        potionObject:populateIngredientBankCount()
        UTILS.randomSleep(800)
        API.logDebug("Bank is open")
    --Press preset key
        API.KeyboardPress2(presetKeyCode,60, 100)
        UTILS.randomSleep(600)
    end

    if potionObject:checkInventoryForMinimumIngredients() then
        bankAttempt = 0
        printProgressReport(false)
        return true
    else
        bankAttempt = bankAttempt + 1
        return false
    end
end

local function getKeysList(table)
    local keys = {}
    for k, v in pairs(table) do
        keys[#keys+1] = k
    end
    return keys
end
populatePotionObject(API.ScriptDialogWindow2("Potion",getKeysList(potionList), "Select", "Close").Name)
usableActionBarIngredientName = potionObject:getUsableInActionBarIngredient()
setupGUI()

--[[
   Copped the jump/anim check from Higgin's Lumbridge Castle Flax Spinner
]]--

while API.Read_LoopyLoop() and keepRunning do
    drawGUI()
    if not keepRunning then 
        break 
    end
    API.DoRandomEvents()
    if  API.CheckAnim(10) or API.isProcessing() or API.ReadPlayerMovin2() then
        API.RandomSleep2(600, 800, 950);
        goto skip
    end
    API.logDebug("passed checkanim")
    if bank() then
        if clickIngredient and not (usableActionBarIngredientName == nil ) and barCheck(usableActionBarIngredientName) then 
            API.logDebug("------------------Inside click ingredient condition")
            API.DoAction_Ability(usableActionBarIngredientName, 1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(600, 800, 1200)
            if isInterfaceOpen() and checkInterfacePotionSelected(potionObject.id,potionObject.potionInterfaceID) then
                API.logDebug("Time to make potion")
                API.RandomSleep2(600, 800, 1200)
                --press space to begin cleaning
                API.KeyboardPress2(0x20, 60, 100)
                API.RandomSleep2(600, 800, 1200)
            end
        else
            API.logDebug("****************************outside click ingredient condition")
            if openHerbloreInterface() and checkInterfaceDropdown(potionObject.dropDownCategoryID) and checkInterfacePotionSelected(potionObject.id,potionObject.potionInterfaceID) then
                API.RandomSleep2(600, 800, 1200)
                API.KeyboardPress2(0x20, 60, 100)
                API.RandomSleep2(600, 800, 1200)
            end
        end
    end

    ::skip::
    printProgressReport(false)
    API.RandomSleep2(200, 400, 600);

end

print("Exiting herbcleaner")