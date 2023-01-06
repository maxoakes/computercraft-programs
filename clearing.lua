if not turtle then
  printError("Requires a Turtle")
  return
end
 
-- constants
local Movement = {
  RIGHT = "r",
  LEFT = "l",
  FORWARD = "f",
  UP = "u",
  DOWN = "d"
}

local Facing = {
  FORWARD = "f",
  BACKWARD = "b",
  LEFT = "l",
  RIGHT = "r"
}

local tArgs = { ... }
if #tArgs > 4 or #tArgs < 3 then
  local programName = arg[0] or fs.getName(shell.getRunningProgram())
  print("Usage: " .. programName .. " <right-length> <forward-length> <up-length> (clearing|stairs)")
  return
end

for key,value in ipairs(tArgs) do
  print("Reading " .. key .. ": " .. value)
  if key <= 3 then
    if tonumber(value) < 1 then
      print("Dimensions must be greater than 0: trouble input = " .. value)
      return
    end
  end
end

-- Params
local isVerbose = false
local sizeWide = tonumber(tArgs[1])
local sizeForward = tonumber(tArgs[2])
local sizeUp = tonumber(tArgs[3])
local type = tArgs[4]
if type == nil or type == "clearing" then
  type = "clearing"
elseif type == "stairs" or type == "stairs" then
  type = "stairs"
else
  type = "clearing"
end

-- Rotation, Position
local currX = 0
local currZ = 0
local currY = 0
local currDir = Facing.FORWARD
local currXFacing = 0 -- 1 = facing right; 0 = facing back or forward; -1 = facing left
local currZFacing = 1 -- 1 = facing forward; 0 = facing left or right; -1 = facing backwards

local unloaded = 0
local collected = 0
 
local goTo -- Filled in further down
local refuel -- Filled in further down

-- -- -- -- --
-- Helper functions
-- -- -- -- --
local function verbosePrint(str)
  if isVerbose then
    print("Debug: " .. str)
  end
end

local function isAlternate(num)
  return math.fmod(num, 2) == 0
end

-- -- -- -- --
-- Fueling, loading functions
-- -- -- -- --
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
  local x, y, z, xd, zd = currX, currY, currZ, currXFacing, currZFacing
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
 
  local needed = amount or currX + currZ + currY + 2
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
-- -- -- --
-- Movement functions
-- -- -- --

-- attempt a movement based on an input. if there is a block in the way, it will mine, otherwise, it will move
local function tryMove(movement)
  if turtle.getFuelLevel() <= 2 then
    print("Refueling")
    turtle.refuel(1)
  end
  if movement == "forward" or movement == "f" then
    while turtle.detect() do
      if turtle.dig() then
        -- verbosePrint("dug a block")
      end
    end
    if turtle.forward() then
      if currDir == Facing.FORWARD then
        currZ = currZ + 1
      elseif currDir == Facing.RIGHT then
        currX = currX + 1
      elseif currDir == Facing.BACKWARD then
        currZ = currZ - 1
      elseif currDir == Facing.LEFT then
        currX = currX - 1
      else
        return false
      end
    end
  elseif movement == "up" or movement == "u" then
    while turtle.detectUp() do
      if turtle.digUp() then
        -- verbosePrint("dug a block")
      end
    end
    if turtle.up() then
      currY = currY + 1
    end
  elseif movement == "down" or movement == "d" then
    while turtle.detectDown() do
      if turtle.digDown() then
        -- verbosePrint("dug a block")
      end
    end
    if turtle.down() then
      currY = currY - 1
    end
  else
    print("Not a valid movement")
    return false
  end
  verbosePrint("Moved " .. movement .. " -> Now at (" .. currX .. "," .. currY .. "," .. currZ .. ")")
  return true
end

local function tryRotate(direction)
  if direction == Movement.RIGHT then
    turtle.turnRight()
    if currDir == Facing.FORWARD then
      currDir = Facing.RIGHT
    elseif currDir == Facing.RIGHT then
      currDir = Facing.BACKWARD
    elseif currDir == Facing.BACKWARD then
      currDir = Facing.LEFT
    elseif currDir == Facing.LEFT then
      currDir = Facing.FORWARD
    else
      return false
    end
  elseif Movement.LEFT then
    turtle.turnLeft()
    if currDir == Facing.FORWARD then
      currDir = Facing.LEFT
    elseif currDir == Facing.RIGHT then
      currDir = Facing.FORWARD
    elseif currDir == Facing.BACKWARD then
      currDir = Facing.RIGHT
    elseif currDir == Facing.LEFT then
      currDir = Facing.BACKWARD
    else
      return false
    end
  end
  verbosePrint("Rotated " .. direction .. " -> Now facing " .. currDir)
  return true
end

-- -- -- -- -- --
-- Movement Helper functions
-- -- -- -- -- --

-- assuming in the lowest rear block position
local function mineForwardVerticalSlice(length, tall)
  local currHeight = 1
  local currDepth = 1
  -- if the height that is being cleared is more than just one vertical layer
  for z = 1, length do
    if (tall > 1) then
      -- mine one column and move forward
      for y = 2, tall do
        if isAlternate(currDepth) then
          if tryMove(Movement.DOWN) then
            currHeight = currHeight - 1
          end
        else
          if tryMove(Movement.UP) then
            currHeight = currHeight + 1
          end
        end
      end
    end
    -- no matter what, even if there is only one layer being mined, move forward (after the column is mined)
    if currDepth < length then
      if tryMove(Movement.FORWARD) then
        currDepth = currDepth + 1
      end
    end
  end
end
 
local function strafe(facing, distance)
  if facing == Facing.RIGHT then
    tryRotate(Movement.RIGHT)
    for i = 1, distance do
      tryMove(Movement.FORWARD)
    end
    tryRotate(Movement.LEFT)
  elseif facing == Facing.LEFT then
    tryRotate(Movement.LEFT)
    for i = 1, distance do
      tryMove(Movement.FORWARD)
    end
    tryRotate(Movement.RIGHT)
  elseif facing == Facing.BACKWARD then
    tryRotate(Movement.RIGHT)
    tryRotate(Movement.RIGHT)
    for i = 1, distance do
      tryMove(Movement.FORWARD)
    end
    tryRotate(Movement.RIGHT)
    tryRotate(Movement.RIGHT)
  elseif facing == Facing.FORWARD then
    for i = 1, distance do
      tryMove(Movement.FORWARD)
    end
  else
    return
  end
end

-- set direction regardless of what it is at currently
local function setDir(facing)
  while currDir ~= facing do
    tryRotate(Facing.RIGHT)
  end
end

-- Stair climb
local function traverseTo(x, z, y, d)
  print("Starting traversal to (" .. x .. ", " .. y .. ", " .. z .. ")")
  local destructive = false
  if d then
    destructive = true
  end

  if not destructive then
    while currX ~= x or currZ ~= z or currY ~= y do
      if currX ~= x then
        if (currX - x) > 0 then 
          setDir(Facing.LEFT)
          while not turtle.detect() and currX ~= x do
            tryMove(Movement.FORWARD)
          end
        else
          setDir(Facing.RIGHT)
          while not turtle.detect() and currX ~= x do
            tryMove(Movement.FORWARD)
          end
        end
        if currZ ~= z then
          if (currZ - z) > 0 then 
            setDir(Facing.BACKWARD)
            while not turtle.detect() and currZ ~= z do
              tryMove(Movement.FORWARD)
            end
          else
            setDir(Facing.FORWARD)
            while not turtle.detect() and currZ ~= z do
              tryMove(Movement.FORWARD)
            end
          end
        end
        if currY ~= y then
          if (currY - y) > 0 then 
            while not turtle.detectUp() and currY ~= y do
              tryMove(Movement.UP)
            end
          else
            while not turtle.detectDown() and currY ~= y do
              tryMove(Movement.DOWN)
            end
          end
        end
      end
    end
  end
end
-- -- -- --
-- Main functions
-- -- -- -- 

local function clearing()
  -- inital rotate to mine frontmost slice
  tryRotate(Movement.RIGHT)

  for x = 1, sizeForward do
    -- mine that slice
    mineForwardVerticalSlice(sizeWide, sizeUp)

    -- move the turtle to the lowest Y level of the clearing area
    while currY > 0 do
      tryMove(Movement.DOWN)
    end

    -- strafe to the next slice base
    if isAlternate(currZ) then
      tryRotate(Facing.LEFT)
      tryMove(Movement.FORWARD)
      tryRotate(Facing.LEFT)
    else
      tryRotate(Facing.RIGHT)
      tryMove(Movement.FORWARD)
      tryRotate(Facing.RIGHT)
    end
  end
end

local function stairs()
  -- inital rotate to mine frontmost slice
  tryRotate(Movement.RIGHT)

  for x = 1, sizeForward do
    -- mine that slice
    mineForwardVerticalSlice(sizeWide, sizeUp)

    -- move the turtle to the lowest Y level of the clearing area
    while currY > 0 do
      tryMove(Movement.DOWN)
    end

    -- strafe to the next slice base
    if isAlternate(currZ) then
      tryRotate(Facing.LEFT)
      tryMove(Movement.FORWARD)
      tryRotate(Facing.LEFT)
      tryMove(Movement.DOWN)
    else
      tryRotate(Facing.RIGHT)
      tryMove(Movement.FORWARD)
      tryRotate(Facing.RIGHT)
      tryMove(Movement.DOWN)
    end
  end
  traverseTo(0, 0, 0, false)
end

-- main procedure
print("Excavating...")

-- select fuel slot
turtle.select(1)
turtle.refuel(1)
print("Turtle has fuel: " .. turtle.getFuelLevel() .. ". Will do: " .. type .. " with dimensions (wide: ".. sizeWide .. ", forward: " .. sizeForward .. ", tall: " .. sizeUp)

if type == "clearing" then
  clearing()
elseif type == "stairs" then
  stairs()
end
print("Done!")