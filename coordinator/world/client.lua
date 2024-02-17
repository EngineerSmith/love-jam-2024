local lg = love.graphics

local logger = require("util.logger")
local assets = require("util.assets")
local suit = require("libs.suit")
local sti = require("libs.sti")

local network = require("libs.MintHive.client")

local quad_plate_unpressed = lg.newQuad(0, 0, 16, 16, 32, 16)
local quad_plate_pressed = lg.newQuad(16, 0, 16, 16, 32, 16)

return function(coordinator)

  network.addHandler("loadMap",  function(map)
    coordinator.map = sti(map)
    coordinator.formatMap(coordinator.map)
  end)

  coordinator.update = function(dt)
    if coordinator.map then
      coordinator.map:update(dt)
    end
  end

  coordinator.drawPlate = function(plate, scaleX, scaleY)
    local quad = plate.pressed and quad_plate_pressed or quad_plate_unpressed
    lg.draw(assets["tile.pressure_plate"], quad, plate.x * scaleX, plate.y * scaleY)
  end

  coordinator.draw = function()
    if coordinator.map then
      coordinator.map:draw()
    end
  end

end