local suit = require("libs.suit").new()
local uiUtil = require("util.ui")

suit.theme = require("ui.theme_Menu") -- todo change

return function(scene)

  local ui = {
    scene = scene,
    fonts = { }
  }
  ui.chat = require("scenes.game.ui.chat")(ui)

  ui.setScale = function(scale)
    suit.scale = scale
    suit.theme.scale = scale

    ui.fonts.subfont = uiUtil.getFont(14, "fonts.futile", scale)
  end

  ui.update = function(dt)
    ui.chat.update(dt)
  end

  ui.drawui = function()
    suit:enterFrame(1)
  end

  ui.draw = function()
    ui.chat.draw(ui.fonts.subfont)
    suit:draw(1)
  end

  ui.keypressed = function(scancode)
    if scancode == "v" and love.keyboard.isScancodeDown('lctrl', 'rctrl') then
      scancode = "paste"
    end
    local handled = ui.chat.keypressed(scancode)
    if handled then return true end
  end

  ui.textinput = function(text)
    local handled = ui.chat.textinput(text)
    if handled then return true end
  end

  return ui

end