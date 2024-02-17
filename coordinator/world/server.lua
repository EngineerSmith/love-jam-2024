local mintHive = require("libs.MintHive")
local network = mintHive.server

local sti = require("libs.sti")

return function(coordinator)

  network.addHandler("login", function(client)
    network.send(client, "loadMap", coordinator.mapLocation)
  end)

  coordinator.setWorld = function(mapLocation)
    coordinator.mapLocation = mapLocation
    coordinator.map = sti(mapLocation)
    if not mintHive.isSingleplayer then
      network.sendAll("loadMap", mapLocation)
    end
    coordinator.formatMap(coordinator.map)
  end

  coordinator.load = function()
    coordinator.setWorld("assets/tiles/lobby.lua")
  end

end