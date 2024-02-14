local lg = love.graphics

local mintHive = require("libs.MintHive")
local settings = require("util.settings")
local logger = require("util.logger")
local cursor = require("util.cursor")
local lang = require("util.lang")
local suit = require("libs.suit").new()
local ui = require("util.ui")

suit.theme = require("ui.theme_Menu")

local scene = { }

scene.load = function(address, pin, username)
  scene.unloaded = false
  scene.state = "connecting"
  scene.disconnectReason = "normal"

  mintHive.client.connect(address, address, settings._default.server.port, username, pin)

  scene.dots = {
    num = 0,
    numLimit = 3,
    timer = 0,
    steps = 0.6,
  }
end

scene.unload = function()
  scene.unloaded = true
  cursor.switch(nil)
end

mintHive.client.addHandler("login", function(...)
  if not scene.unloaded then
    require("util.sceneManager").changeScene("scenes.game")
  end
end)

mintHive.client.addHandler("disconnect", function(reason)
  if not scene.unloaded then
    scene.state = "disconnected"
    scene.disconnectReason = reason
  end
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
  
  -- scale UI
    suit.scale = scene.scale
    suit.theme.scale = scene.scale
  
    -- scale Text
    local font, fontSize = ui.getFont(18, "fonts.futile", scene.scale)
    logger.info("Scaled default font size to", fontSize, "from", 18)
    lg.setFont(font)

    scene.subfont = ui.getFont(14, "fonts.futile", scene.scale)
  end

scene.update = function(dt)
  if scene.state == "connecting" then
    scene.dots.timer = scene.dots.timer + dt
    while scene.dots.timer > scene.dots.steps do
      scene.dots.num = scene.dots.num + 1
      if scene.dots.num > scene.dots.numLimit then
        scene.dots.num = 0
      end
      scene.dots.timer = scene.dots.timer - scene.dots.steps
    end
  end
end

scene.drawui = function()
  suit:enterFrame(1)
  local font = love.graphics.getFont()
  local fontHeight = font:getHeight()

  local buttonWidth = 150 * scene.scale
  local buttonHeight = (fontHeight + 20) / scene.scale

  local windowSize = settings._default.client.windowSize
  local windowWidth = lg.getWidth()
  suit.layout:reset(math.floor(windowWidth/2 - buttonWidth/2), math.floor(windowSize.height/2) + buttonHeight)
  suit.layout:up(buttonWidth, buttonHeight)

  if scene.state == "connecting" then
    suit.layout:translate(-25 * scene.scale, 0)
    suit:Label(lang.getText("menu.connectingMessage"), { noScaleX = true, noBox = true }, suit.layout:up(200*scene.scale, buttonHeight))
    suit:Label(string.rep(".", scene.dots.num), { noScaleX = true, noBox = true }, suit.layout:down())
  elseif scene.state == "disconnected" then
    suit.layout:translate(-100 * scene.scale, 0)
    suit:Label(lang.getText("menu.disconnected"), { noScaleX = true, noBox = true }, suit.layout:up(350*scene.scale, buttonHeight))
    suit:Label(lang.getText("disconnected."..scene.disconnectReason), { noScaleX = true, noBox = true, font = scene.subfont }, suit.layout:down())
    suit.layout:translate(100 * scene.scale, 20)
    local b = suit:Button(lang.getText("menu.back"), { noScaleX = true }, suit.layout:down(buttonWidth, buttonHeight))
    if b.hit then
      require("util.sceneManager").changeScene("scenes.menu")
      return
    end
    cursor.switchIf(b.hovered, "hand")
    cursor.switchIf(b.left, nil)
  end
end

scene.draw = function()
  lg.clear(25/255, 5/255, 50/255)
  suit:draw(1)
end

scene.threaderror = function(thread, errorMessage)
  if not mintHive.client.threaderror(thread, errorMessage) then
    logger.error("Unknown thread error! Thread:", thread, "Message:", errorMessage)
  end
end

return scene