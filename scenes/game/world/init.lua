local mintHive = require("libs.MintHive")

return function (scene)
  local world = { }
  world.worldcoordinator = require("coordinator.world")(mintHive.isClient(), mintHive.isServer())

  world.load = function()
    if world.worldcoordinator.load then
      world.worldcoordinator.load()
    end
  end

  world.update = function(dt)
    if mintHive.isClient() then
      world.worldcoordinator.update(dt)
    end
  end

  world.draw = function()
    world.worldcoordinator.draw()
  end

  return world
end