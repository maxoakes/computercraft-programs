-- --
-- Created by Max (Scouter)
-- Last updated June 21, 2018
--
-- For OpenComputer/ExtremeReactor Combo
-- Verson 1.0.0b
-- Reactor automation
-- --
 
--Init stuff
local component = require("component")
local reactor = component.br_reactor
local gpu = component.gpu
local term = require("term")
gpu.setResolution(50,16)
gpu.setForeground(0xff00ff)
gpu.setBackground(0xffffff)
 
--Reactor stuff
local w, h = gpu.getResolution()
local time = -1
local reactorString = "Default"
local chargeTime = 11000
local energy = -1
local produced = -1
local fuelConsumed = -1
local reactorCode = -1
-- 0 is empty, waiting to recharge
-- 1 is recharging
-- 2 is full/discharging
 
local initStatus = reactor.getActive()
if (initStatus == true) then
  reactorCode = 1
else
  reactorCode = 2
end
 
while true do
   
  --time
  time = (os.time()*(1000/60/60) - 6000) % 24000
   
  -- Reactor Status
  energy = reactor.getEnergyStored()
  produced = reactor.getEnergyProducedLastTick()
  fuelConsumed = reactor.getFuelConsumedLastTick()
 
  -- String Status
  if (reactorCode == 0) then
    reactorString = "Waiting to Resume"
    gpu.setForeground(0x0000ff)
  elseif (reactorCode == 1) then
    reactorString = "Online (Charging)"
    gpu.setForeground(0x00ff00)
  elseif (reactorCode == 2) then
    reactorString = "Offline (Discharging)"
    gpu.setForeground(0xff0000)
  end
 
  if (energy >= 9500000) and (reactorCode == 1) then
    reactorCode = 2
    reactor.setActive(false)
  end
 
  if (energy == 0) then
    if (time < chargeTime) and (reactorCode == 2) then
      reactorCode = 0
    end
    if (time > chargeTime) and (reactorCode == 0) then
      reactorCode = 1
      reactor.setActive(true)
    end
  end
 
  --Pretty Display
  local pos = math.floor(h/2)-3
  local indent = math.floor((w-36)/2)
   
  term.clear()
 
  term.setCursor(indent+9,pos)
  term.write("Southern  Cliff")
 
  pos = pos + 2
  term.setCursor(indent,pos)
  term.write("Reactor Status: " .. reactorString)
 
  pos = pos + 1
  term.setCursor(indent,pos)
  term.write("Reactor Buffer: " .. energy .. " RF")
 
  pos = pos + 1
  term.setCursor(indent,pos)
  term.write("Energy Produced: " .. math.floor(produced) .. " RF/t")
 
  pos = pos + 1
  term.setCursor(indent,pos)
  term.write("Efficiency: " .. string.format("%." .. (4 or 0) .. "f", (fuelConsumed*20/1000)*6) .. " Ingots/sec")
 
  os.sleep(0.2)
end