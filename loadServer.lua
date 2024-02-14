local logger = require("util.logger")
local mintHive = require("libs.MintHive")
local settings = require("util.settings")
local sceneManager = require("util.sceneManager")
local scene = { }

local network = mintHive.server

scene.load = function()
  scene.unloaded = false

  network.start({
    port = settings.server.port,
    maxPeers = 64,
    inBandwidth = 0,
    outBandwidth = 0,
    pin = 0,
  })
end

scene.unload = function()
  scene.unloaded = true
end

network.addHandler("started", function(port)
  if scene.unloaded then
    return
  end
  logger.info("Started server on", port)
  sceneManager.changeScene("scenes.game")
end)

scene.threaderror = function(thread, errorMessage)
  if not network.threaderror(thread, errorMessage) then
    logger.error("Unknown thread error! Thread:", thread, "Message:", errorMessage)
  end
end

return scene