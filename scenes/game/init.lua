local lg = love.graphics

local mintHive = require("libs.MintHive")
local settings = require("util.settings")
local logger = require("util.logger")
local ui = require("util.ui")

local scene = { }

scene.load = function()
  scene.unloaded = false
  logger.info("Loading game scene")

  scene.ui = require("scenes.game.ui")(scene)
end

scene.unload = function()
  scene.unloaded = true
  logger.info("Unloading game scene")
end

mintHive.client.addHandler("disconnect", function(reason)
  if scene.unloaded then return end
  logger.info("Disconnected!")
  require("util.sceneManager").changeScene("scenes.menu")
end)

scene.resize = function(w, h)
  -- Update settings
  settings.client.windowSize = {
    width = w, height = h
  }
  settings.encode()

  -- Scale scene
  local wsize = settings._default.client.windowSize
  local tw, th = wsize.width, wsize.height
  local sw, sh = w / tw, h / th
  scene.scale = sw < sh and sw or sh

  -- scale Text
  local font, fontSize = ui.getFont(18, "fonts.futile", scene.scale)
  logger.info("Scaled default font size to", fontSize, "from", 18)
  lg.setFont(font)

  -- scale UI
  scene.ui.setScale(scene.scale)
end

scene.update = function(dt)
  if mintHive.isClient() then
    scene.ui.update(dt)
  end
end

scene.drawui = function()
  scene.ui.drawui()
end

scene.draw = function()
  lg.clear(0,0,0)
  scene.ui.draw()
end

scene.keypressed = function(_, scancode)
  local handled = scene.ui.keypressed(scancode)
  if handled then return end
end

scene.textinput = function(text)
  local handled = scene.ui.textinput(text)
  if handled then return end
end

scene.threaderror = function(thread, errorMessage)
  if mintHive.client.threaderror(thread, errorMessage) then
    return
  end
  if mintHive.server.threaderror(thread, errorMessage) then
    return
  end
  logger.error("Unknown thread error! Thread:", thread, "Message:", errorMessage)
end

return scene