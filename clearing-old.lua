if not turtle then
    printError("Requires a Turtle")
    return
end
 
local tArgs = { ... }
if #tArgs ~= 3 then
    local programName = arg[0] or fs.getName(shell.getRunningProgram())
    print("Usage: " .. programName .. " <right-length> <forward-length> <up-length>")
    return
end

for key,value in ipairs(tArgs) do
    print("Reading " .. key .. ": " .. value)
    if tonumber(value) < 1 then
        print("Dimensions must be greater than 0: trouble input = " .. value)
        return
    end
end

local sizeWide = tonumber(tArgs[1])
local sizeForward = tonumber(tArgs[2])
local sizeUp = tonumber(tArgs[3])
print("Will begin mining a cube of size (width:" ..  sizeWide .. ", forward:" .. sizeForward .. ", tall:" .. sizeUp .. ")")

local unloaded = 0
local collected = 0
 
local xPos, zPos, yPos = 0, 0, 0
local xDir, zDir = 0, 1
 
local goTo -- Filled in further down
local refuel -- Filled in further down
 
local function unload(_bKeepOneFuelStack)
    print("Unloading items...")
    for n = 1, 16 do
        local nCount = turtle.getItemCount(n)
        if nCount > 0 then
            turtle.select(n)
            local bDrop = true
            if _bKeepOneFuelStack and turtle.refuel(0) then
                bDrop = false
                _bKeepOneFuelStack = false
            end
            if bDrop then
                turtle.drop()
                unloaded = unloaded + nCount
            end
        end
    end
    collected = 0
    turtle.select(1)
end
 
local function returnSupplies()
    local x, y, z, xd, zd = xPos, yPos, zPos, xDir, zDir
    print("Returning to origin...")
    goTo(0, 0, 0, 0, -1)
 
    local fuelNeeded = 2 * (x + y + z) + 1
    if not refuel(fuelNeeded) then
        unload(true)
        print("Waiting for fuel")
        while not refuel(fuelNeeded) do
            os.pullEvent("turtle_inventory")
        end
    else
        unload(true)
    end
 
    print("Resuming clearing...")
    goTo(x, y, z, xd, zd)
end
 
local function collect()
    local bFull = true
    local nTotalItems = 0
    for n = 1, 16 do
        local nCount = turtle.getItemCount(n)
        if nCount == 0 then
            bFull = false
        end
        nTotalItems = nTotalItems + nCount
    end
 
    if nTotalItems > collected then
        collected = nTotalItems
        if math.fmod(collected + unloaded, 50) == 0 then
            print("Mined " .. collected + unloaded .. " items.")
        end
    end
 
    if bFull then
        print("No empty slots left.")
        return false
    end
    return true
end
 
function refuel(amount)
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" then
        return true
    end
 
    local needed = amount or xPos + zPos + yPos + 2
    if turtle.getFuelLevel() < needed then
        for n = 1, 16 do
            if turtle.getItemCount(n) > 0 then
                turtle.select(n)
                if turtle.refuel(1) then
                    while turtle.getItemCount(n) > 0 and turtle.getFuelLevel() < needed do
                        turtle.refuel(1)
                    end
                    if turtle.getFuelLevel() >= needed then
                        turtle.select(1)
                        return true
                    end
                end
            end
        end
        turtle.select(1)
        return false
    end
 
    return true
end
 
local function tryForwards()
    if not refuel() then
        print("Not enough Fuel")
        returnSupplies()
    end
 
    while not turtle.forward() do
        if turtle.detect() then
            if turtle.dig() then
                if not collect() then
                    returnSupplies()
                end
            else
                return false
            end
        elseif turtle.attack() then
            if not collect() then
                returnSupplies()
            end
        else
            sleep(0.5)
        end
    end
 
    xPos = xPos + xDir
    zPos = zPos + zDir
    return true
end
 
local function tryDown()
    if not refuel() then
        print("Not enough Fuel")
        returnSupplies()
    end
 
    while not turtle.down() do
        if turtle.detectDown() then
            if turtle.digDown() then
                if not collect() then
                    returnSupplies()
                end
            else
                return false
            end
        elseif turtle.attackDown() then
            if not collect() then
                returnSupplies()
            end
        else
            sleep(0.5)
        end
    end
 
    yPos = yPos - 1
    if math.fmod(yPos, 3) == 0 then
        print("At " .. yPos .. " meters.")
    end
 
    return true
end

local function tryUp()
    if not refuel() then
        print("Not enough Fuel")
        returnSupplies()
    end
 
    while not turtle.up() do
        if turtle.detectUp() then
            if turtle.digUp() then
                if not collect() then
                    returnSupplies()
                end
            else
                return false
            end
        elseif turtle.attackUp() then
            if not collect() then
                returnSupplies()
            end
        else
            sleep(0.5)
        end
    end
 
    yPos = yPos + 1
    if math.fmod(yPos, 3) == 0 then
        print("At " .. yPos .. " meters.")
    end
 
    return true
end
 
local function turnLeft()
    turtle.turnLeft()
    xDir, zDir = -zDir, xDir
end
 
local function turnRight()
    turtle.turnRight()
    xDir, zDir = zDir, -xDir
end
 
function goTo(x, y, z, xd, zd)
    --move to correct height
    while yPos > y do
        if turtle.down() then
            yPos = yPos - 1
        elseif turtle.digDown() or turtle.attackDown() then
            collect()
        else
            sleep(0.5)
        end
    end

    while yPos < y do
        if turtle.up() then
            yPos = yPos + 1
        elseif turtle.digUp() or turtle.attackUp() then
            collect()
        else
            sleep(0.5)
        end
    end
 
    if xPos > x then
        while xDir ~= -1 do
            turnLeft()
        end
        while xPos > x do
            if turtle.forward() then
                xPos = xPos - 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    elseif xPos < x then
        while xDir ~= 1 do
            turnLeft()
        end
        while xPos < x do
            if turtle.forward() then
                xPos = xPos + 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    end
 
    if zPos > z then
        while zDir ~= -1 do
            turnLeft()
        end
        while zPos > z do
            if turtle.forward() then
                zPos = zPos - 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    elseif zPos < z then
        while zDir ~= 1 do
            turnLeft()
        end
        while zPos < z do
            if turtle.forward() then
                zPos = zPos + 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    end
 
    -- while yPos < y do
    --     if turtle.down() then
    --         yPos = yPos + 1
    --     elseif turtle.digDown() or turtle.attackDown() then
    --         collect()
    --     else
    --         sleep(0.5)
    --     end
    -- end
 
    while zDir ~= zd or xDir ~= xd do
        turnLeft()
    end
end
 
if not refuel() then
    print("Out of Fuel")
    return
end
 
print("Excavating...")
 
turtle.select(1)
 
local alternate = 0
local done = false
while not done do
    for n = 1, sizeWide do
        for _ = 1, sizeForward - 1 do
            if not tryForwards() then
                done = true
                break
            end
        end
        if done then
            break
        end
        if n < sizeForward then
            if math.fmod(n + alternate, 2) == 0 then
                turnLeft()
                if not tryForwards() then
                    done = true
                    break
                end
                turnLeft()
            else
                turnRight()
                if not tryForwards() then
                    done = true
                    break
                end
                turnRight()
            end
        end
    end
    if done then
        break
    end
 
    if sizeUp > 1 then
        if math.fmod(sizeUp, 2) == 0 then
            turnRight()
        else
            if alternate == 0 then
                turnLeft()
            else
                turnRight()
            end
            alternate = 1 - alternate
        end
    end
 
    if not tryUp() or yPos > sizeUp then
        done = true
        break
    end
end
 
print("Returning to origin...")
 
-- Return to where we started
goTo(0, 0, 0, 0, -1)
unload(false)
goTo(0, 0, 0, 0, 1)
 
print("Mined " .. collected + unloaded .. " items total.")