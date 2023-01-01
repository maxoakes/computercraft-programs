if not turtle then
  printError("Requires a Turtle")
  return
end
 
-- constants
local Direction = {
  RIGHT = "r",
  LEFT = "l",
  FORWARD = "f",
  UP = "u",
  DOWN = "d"
}

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

-- attempt a movement based on an input. if there is a block in the way, it will mine, otherwise, it will move
local function tryMove(movement)
  if turtle.getFuelLevel() then
    print("Refueling")
    turtle.refuel(2)
  end
  if movement == "forward" or movement == "f" then
    if turtle.detect() then
      if turtle.dig() then
        print("dug a block")
      end
    else
      if turtle.forward() then
        print("there is no block")
      end
    end
  elseif movement == "up" or movement == "u" then
    if turtle.detectUp() then
      if turtle.digUp() then
        print("dug a block")
      end
    else
      if turtle.up() then
        print("there is no block")
      end
    end
  elseif movement == "down" or movement == "d" then
    if turtle.detectDown() then
      if turtle.digDown() then
        print("dug a block")
      end
    else
      if turtle.down() then
        print("there is no block")
      end
    end
  else
    print("Not a valid movement")
    return false
  end
  return true
end

local function tryRotate(direction)
  if direction == "right" or direction == "r" then
    turtle.turnRight()
  elseif direction == "left" or direction == "l" then
    turtle.turnLeft()
  end
  return true
end

-- helper function to determine if a number (ideally a single coord position) will use some alternative action. returns boolean
local function isAlternate(num)
  return math.fmod(num, 2) == 0
end

-- assuming in the lowest rear block position
local function mineVerticalSlice(length, tall)
  local currHeight = 1
  local currDepth = 1
  -- if the height that is being cleared is more than just one vertical layer
  for z = 1, length do
    if (tall > 1) then
      -- mine one column and move forward
      for y = 2, tall do
        if isAlternate(currDepth) then
          if tryMove(Direction.DOWN) then
            currHeight = currHeight - 1
          end
        else
          if tryMove(Direction.UP) then
            currHeight = currHeight + 1
          end
        end
      end
    end
    -- no matter what, even if there is only one layer being mined, move forward (after the column is mined)
    if tryMove(Direction.FORWARD) then
      currDepth = currDepth + 1
    end
  end
end
 
print("Excavating...")

-- select fuel slot
turtle.select(1)
turtle.refuel(1)
print("Turtle has fuel: " .. turtle.getFuelLevel() .. ". Will mine wide: " .. sizeWide .. ", forward: " .. sizeForward .. ", tall: " .. sizeUp)
mineVerticalSlice(sizeForward, sizeUp)

-- start the turtle from the lower left of the cube that will be cleared (interior)
-- from 1 to sizeForward,
-- mine a column Y high, y+
-- move forward 1, mine a column Y high, y-
-- if current y is not 0, move to y=0
-- rotate right, move forward 1, rotate right
print("Done!")