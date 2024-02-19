local logger = require("util.logger")

return function(isClient, isServer)
  local worldCoordinator = {
    toClient = "worldClient",
    toServer = "worldServer",
  }

  worldCoordinator.formatMap = function(map)
    local plates = { }
    for _, object in pairs(map.objects) do
      -- Assuming all objects want to be tile alligned
      object.x, object.y = map:convertPixelToTile(object.x, object.y)
      if object.name == "plate" then
        table.insert(plates, object)
      end
    end

    local worldInteractables = map:addCustomLayer("worldInteractables")

    worldInteractables.plates = { }
    
    for _, plate in ipairs(plates) do
      table.insert(worldInteractables.plates, {
        x = plate.x,
        y = plate.y,
        pressed = false
      })
    end

    if isClient then
      worldInteractables.draw = function(self)
        for _, plate in ipairs(self.plates) do
          worldCoordinator.drawPlate(plate, map.tilewidth, map.tileheight)
        end
      end
    end

    local success = pcall(map.removeLayer, map, "Interactable")
    if not success  then 
      logger.warn("Could not remove 'Interactable' layer")
    end
  end

  worldCoordinator.update = function(dt)
    if worldCoordinator.map then
      worldCoordinator.box2d:update(dt)
      worldCoordinator.map:update(dt)
    end
  end

  if isServer then
    require("coordinator.world.server")(worldCoordinator)
  end
  if isClient then
    require("coordinator.world.client")(worldCoordinator)
  end

  return worldCoordinator
end