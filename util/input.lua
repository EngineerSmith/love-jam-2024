local baton = require("libs.baton")

local logger = require("util.logger")
local settings = require("util.settings")

local joystick = love.joystick.getJoysticks()[1]

if joystick and settings.newSettings then
  local type = joystick:getGamepadType()
  if type:find("xbox") then
    settings.client.gamepadType = "xbox"
  elseif type:find("ps") then
    settings.client.gamepadType = "playstation"
  elseif type:find("switch") then
    settings.client.gamepadType = "switch"
  else
    settings.client.gamepadType = "general"
  end
  logger.info("Found joystick:", type, ", interal type:", settings.client.gamepadType)
end

if joystick then
  joystick:setPlayerIndex(1)
end

local input = baton.new({
    controls = settings.client.input,
    pairs = {
      move = { "left", "right", "up", "down" },
    },
    joystick = joystick,
    deadzone = settings.client.deadzone,
  })

return input