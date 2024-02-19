local mintHive = require("libs.MintHive")
local network = mintHive.server

local sti = require("libs.sti")

return function(coordinator)

  network.addHandler("login", function(client)
    network.send(client, "loadMap", coordinator.mapLocation)
  end)

  coordinator.setWorld = function(mapLocation)
    coordinator.mapLocation = mapLocation
    coordinator.map = sti(mapLocation, { "box2d" })
    coordinator.box2d = love.physics.newWorld(0, 0, true)
    coordinator.map:box2d_init(coordinator.box2d)
    if not mintHive.isSingleplayer then
      network.sendAll("loadMap", mapLocation)
    end
    coordinator.formatMap(coordinator.map)
  end

  coordinator.load = function()
    coordinator.setWorld("assets/tiles/lobby.lua")
  end

end