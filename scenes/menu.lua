local lg = love.graphics

local mintHive = require("libs.MintHive")
local settings = require("util.settings")
local logger = require("util.logger")
local cursor = require("util.cursor")
local lang = require("util.lang")
local flux = require("libs.flux")
local suit = require("libs.suit").new()
local ui = require("util.ui")
local utf8 = require("utf8")

suit.theme = require("ui.theme_Menu")

local scene = { }

scene.load = function()
  scene.menu = "main"

  scene.menuButtons = { 
    alpha = 0,
    y = 150
  }
  flux.to(scene.menuButtons, 1, { alpha =  1 }):ease("linear")
  flux.to(scene.menuButtons, 3, { y     = 70 }):ease("backout")

  scene.serverInputBox = {
    text = settings.client.lastServerAddress or "",
    shake = 0,
  }

  scene.pinInputBox = {
    text = settings.client.lastServerPin or "",
    shake = 0,
    masked = true,
  }

  scene.usernameInputBox = {
    text = settings.client.lastUsername or "",
    shake = 0,
  }
end

scene.unload = function()
  cursor.switch(nil)
end

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
end

scene.changeMenu = function(menuType)
  scene.menu = menuType
  scene.menuButtons.alpha = 0
  flux.to(scene.menuButtons, 0.2, { alpha = 1 }):ease("linear")
end

scene.drawui = function()
  suit:enterFrame(1)
  local font = love.graphics.getFont()
  local fontHeight = font:getHeight()

  local buttonWidth = 150 * scene.scale
  local buttonHeight = (fontHeight + 20) / scene.scale

  local windowSize = settings._default.client.windowSize
  local windowWidth = lg.getWidth()
  suit.layout:reset(math.floor(windowWidth/2) -(buttonWidth/2), math.floor(windowSize.height/1.25) + scene.menuButtons.y, 0, 20)
  suit.layout:up(buttonWidth, buttonHeight)

  if scene.menu == "main" then
    local b = suit:Button(lang.getText("menu.exit"), { noScaleX = true, alpha = scene.menuButtons.alpha }, suit.layout:up())
    if b.hit then
      love.event.quit()
    end
    cursor.switchIf(b.hovered, "hand")
    cursor.switchIf(b.left, nil)
    local b = suit:Button(lang.getText("menu.multiplayer"), { noScaleX = true, alpha = scene.menuButtons.alpha }, suit.layout:up())
    if b.hit then
      mintHive.setMultiplayer()
      scene.changeMenu("multiplayer")
    end
    cursor.switchIf(b.hovered, "hand")
    cursor.switchIf(b.left, nil)
    local b = suit:Button(lang.getText("menu.singleplayer"), { noScaleX = true, alpha = scene.menuButtons.alpha }, suit.layout:up())
    if b.hit then
      mintHive.setSingleplayer()
      scene.changeMenu("singleplayer")
    end
    cursor.switchIf(b.hovered, "hand")
    cursor.switchIf(b.left, nil)
  else
    local b = suit:Button(lang.getText("menu.back"), { noScaleX = true, alpha = scene.menuButtons.alpha }, suit.layout:up())
    if b.hit then
      scene.changeMenu("main")
    end
    cursor.switchIf(b.hovered, "hand")
    cursor.switchIf(b.left, nil)

    if scene.menu == "singleplayer" then
      mintHive.startSingleplayer()
      require("util.sceneManager").changeScene("scenes.game", "singleplayer")
    elseif scene.menu == "multiplayer" then

      local isValidUsername = mintHive.validateUsername(scene.usernameInputBox.text)
      local isValidAddress = utf8.len(scene.serverInputBox.text) > 0
      local isValidPin = utf8.len(scene.pinInputBox.text) == 0 or (string.match(scene.pinInputBox.text, "^[0-9]+$") and tostring(tonumber(scene.pinInputBox)) == scene.pinInputBox)

      local b = suit:Button(lang.getText("menu.join"), { noScaleX = true, alpha = scene.menuButtons.alpha }, suit.layout:up())
      if b.hit then
        local isValid = true
        if not isValidAddress then
          flux.to(scene.serverInputBox,
                     0.1, { shake =  10 }):ease("linear")
              :after(0.2, { shake = -20 }):ease("linear")
              :after(0.2, { shake =  20 }):ease("linear")
              :after(0.1, { shake =   0 }):ease("linear")
          isValid = false
        end
        if not isValidUsername then
          flux.to(scene.usernameInputBox,
                     0.1, { shake = -10 }):ease("linear")
              :after(0.2, { shake =  20 }):ease("linear")
              :after(0.2, { shake = -20 }):ease("linear")
              :after(0.1, { shake =   0 }):ease("linear")
          isValid = false
        end
        if not isValidPin then
          flux.to(scene.pinInputBox,
                     0.1, { shake =  10 }):ease("linear")
              :after(0.2, { shake = -20 }):ease("linear")
              :after(0.2, { shake =  20 }):ease("linear")
              :after(0.1, { shake =   0 }):ease("linear")
          isValid = false
        end

        if isValid then
          local address, pin, username = scene.serverInputBox.text, scene.pinInputBox.text, scene.usernameInputBox.text
          require("util.sceneManager").changeScene("scenes.connect", address, tonumber(pin), username)

          settings.client.lastServerAddress = address
          settings.client.lastServerPin = pin
          settings.client.lastUsername = username
          settings.encode()
          return
        end
      end
      cursor.switchIf(b.hovered, "hand")
      cursor.switchIf(b.left, nil)

      suit.layout:translate(-(buttonWidth/2), -20)
      suit.layout:padding(0, 0)

      local isValidPinColor = not isValidPin and { 220/255, 50/255, 90/255 } or nil

      suit.layout:translate(scene.pinInputBox.shake * scene.scale, 0)
      local i = suit:Input(scene.pinInputBox, { noScaleX = true, color = { normal = { fg = isValidPinColor } } }, suit.layout:up(buttonWidth * 2, buttonHeight))
      suit.layout:translate(-scene.pinInputBox.shake * scene.scale, 0)

      local _ = cursor.switchIf(i.hovered, "ibeam") or cursor.switchIf(i.hovered, "hand")
      cursor.switchIf(i.left, nil)

      suit:Label(lang.getText("menu.serverPinInput"), { noScaleX = true, noBox = true }, suit.layout:up())

      suit.layout:translate(scene.serverInputBox.shake * scene.scale, 0)
      local i = suit:Input(scene.serverInputBox, { noScaleX = true }, suit.layout:up(buttonWidth * 2, buttonHeight))
      suit.layout:translate(-scene.serverInputBox.shake * scene.scale, 0)

      local _ = cursor.switchIf(i.hovered, "ibeam") or cursor.switchIf(i.hovered, "hand")
      cursor.switchIf(i.left, nil)

      suit:Label(lang.getText("menu.serverInput"), { noScaleX = true, noBox = true }, suit.layout:up())

      local isValidUsernameColor = not isValidUsername and { 220/255, 50/255, 90/255 } or nil

      suit.layout:translate(scene.usernameInputBox.shake * scene.scale, 0)
      local i = suit:Input(scene.usernameInputBox, { noScaleX = true, color = { normal = { fg = isValidUsernameColor } } }, suit.layout:up(buttonWidth * 2, buttonHeight))
      suit.layout:translate(-scene.usernameInputBox.shake * scene.scale, 0)

      local _ = cursor.switchIf(i.hovered, "ibeam") or cursor.switchIf(i.hovered, "hand")
      cursor.switchIf(i.left, nil)

      suit:Label(lang.getText("menu.usernameInput"), { noScaleX = true, noBox = true }, suit.layout:up())
    end
  end
end

scene.draw = function()
  lg.clear(25/255, 5/255, 50/255)
  suit:draw(1)
end

scene.wheelmoved = function(...)
  suit:updateWheel(...)
end

scene.textedited = function(...)
  suit:textedited(...)
end

scene.textinput = function(...)
  suit:textinput(...)
end

scene.keypressed = function(...)
  suit:keypressed(...)
end

return scene