function fuelLevel()
    if turtle.getFuelLevel() < 1000 then
        turtle.select(1)
        turtle.refuel(8)
        print("Refueled")
    else
        print("Enough Fuel")
    end
    end
    
    function mine()
    while turtle.detect() do
        turtle.dig()
        sleep(0.5)
    end
    turtle.forward()
    while turtle.detectUp() do
        turtle.digUp()
        sleep(0.5)
    end
    turtle.digDown()
end 

function checkFull()
    if turtle.getItemCount(16) > 0 then
        turtle.back()
        turtle.down()
        turtle.digDown()
        turtle.select(3)
        turtle.placeDown()
        for i = 4,16 do
        turtle.select(i)
        turtle.dropDown()
        end
        turtle.select(2)
        turtle.up()
        turtle.forward()
    end
end
        
print("Place fuel in slot 1, torches in slot 2, and chests in slot 3!")
    print("How wide will the tunnel be?")
    local x = read()
            turtle.select(2)
    turtle.placeDown()
    while true do

for i = 1,9 do
        turtle.select(2)
        fuelLevel()
        checkFull()
        mine()
        turtle.turnLeft()
        for i = 1,((x/2)-0.5) do
        mine()
        end
        turtle.turnLeft()
        turtle.turnLeft()
        for i = 1,(x-1) do
        mine()
        end
        turtle.turnLeft()
        turtle.turnLeft()
        for i = 1,((x/2)-0.5) do
        turtle.forward()
        end
        turtle.turnRight()
    end
    turtle.select(2)
    turtle.placeDown()
    end