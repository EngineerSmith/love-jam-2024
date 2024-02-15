local PATH = (...):gsub('%.init$', '')

local options = require(PATH .. ".options")

local mintHive = {
  client = require(PATH .. ".client"),
  server = require(PATH .. ".server"),
  isSingleplayer = false,
  validateUsername = options.validateUsername
}

mintHive.isClient = function()
  return mintHive.isSingleplayer or mintHive.client.isRunning()
end

mintHive.isServer = function()
  return mintHive.isSingleplayer or mintHive.server.isRunning()
end

mintHive.setSingleplayer = function()
  return mintHive._setMode(true)
end

mintHive.setMultiplayer = function()
  return mintHive._setMode(false)
end

mintHive._setMode = function(isSingleplayer)
  if not mintHive.client.setSingleplayerMode(isSingleplayer) or
     not mintHive.server.setSingleplayerMode(isSingleplayer) then
    return false
  end
  mintHive.isSingleplayer = isSingleplayer
  return true
end

mintHive.startSingleplayer = function()
  if not mintHive.isSingleplayer then
    local success = mintHive.setSingleplayer()
    if not success then
      options.error("Cannot start singleplayer. Check if a game is not already in progress!")
      return false
    end
  end
  love.handlers[options.clientHandlerEvent] = mintHive.client._handler
  love.handlers[options.serverHandlerEvent] = mintHive.server._handler
  mintHive.client.isConnected = true
  return true
end

mintHive.search = function()
  
end

mintHive.stopSearch = function()
  
end

return mintHive