local lg = love.graphics

local mintHive = require("libs.MintHive")
local settings = require("util.settings")
local logger = require("util.logger")
local ui = require("util.ui")

local scene = { 
  cameraScale = 2
}

scene.load = function()
  scene.unloaded = false
  logger.info("Loading game scene")

  scene.ui = require("scenes.game.ui")(scene)
  scene.world = require("scenes.game.world")(scene)

  scene.world.load()
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
  -- Camera
  local x, y = 0, 0 -- character position
  scene.camera = require("libs.stalker-x")(x, y, tw*scene.scale, th*scene.scale, scene.scale*scene.cameraScale)
  --scene.camera.draw_deadzone = true
  --scene.camera:setFollowLerp(0.1)
  --scene.camera:setFollowStyle("LOCKON")
end

scene.update = function(dt)
  if mintHive.isClient() then
    scene.ui.update(dt)
    scene.world.update(dt)
    scene.camera:update(dt)
  end
end

scene.drawui = function()
  scene.ui.drawui()
end

scene.draw = function()
  lg.clear(0,0,0)
  scene.camera:attach()
  lg.push()
    scene.world.draw()
  lg.pop()
  scene.camera:detach()
  scene.camera:draw()
  scene.ui.draw()
end

scene.keypressed = function(_, scancode)
  -- DEBUG
  local camera = scene.camera
  if scancode == "left" then
    camera.x = camera.x - 10
  elseif scancode == "right" then
    camera.x = camera.x + 10
  elseif scancode == "up" then
    camera.y = camera.y - 10
  elseif scancode == "down" then
    camera.y = camera.y + 10
  end
  -- DEBUG
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