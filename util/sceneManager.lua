local sceneManager = {
  currentScene = nil,
  nilFunc = function() end,
  sceneHandlers = {
    -- GAME LOOP
    "load",
    "unload",
    "update",
    "updatenetwork",
    "drawui",
    "draw",
    "quit",
    -- WINDOW
    "focus",
    "resize",
    "visable",
    "displayrotated",
    "filedropped",
    "directorydropped",
    -- TOUCH INPUT
    "touchpressed",
    "touchmoved",
    "touchreleased",
    -- MOUSE INPUT
    "mousepressed",
    "mousemoved",
    "mousereleased",
    "mousefocus",
    "wheelmoved",
    -- KEY INPUT,
    "keypressed",
    "keyreleased",
    "textinput",
    "textedited",
    -- JOYSTICK/GAMEPAD INPUT
    "joystickhat",
    "joystickaxis",
    "joystickpressed",
    "joystickreleased",
    "joystickadded",
    "joystickremoved",
    "gamepadpressed",
    "gamepadreleased",
    "gamepadaxis",
    -- ERROR
    "threaderror",
    "lowmemory",
  },
}

local love = love

sceneManager.changeScene = function(sceneRequire, ...)
  local scene = require(sceneRequire)
  if sceneManager.currentScene then
    love.unload()
  end
  for _, v in ipairs(sceneManager.sceneHandlers) do
    love[v] = scene[v] or sceneManager.nilFunc
  end
  if love["quit"] ~= sceneManager.nilFunc then
    love["quit"] = sceneManager.quit
  end
  sceneManager.currentScene = scene
  collectgarbage("collect")
  collectgarbage("collect")
  if love.graphics then
    love.resize(love.graphics.getDimensions())
  end
  love.load(...)
end

sceneManager.quit = function()
  local quit = sceneManager.currentScene.quit()
  return quit
end

return sceneManager