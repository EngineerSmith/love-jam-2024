local PATH = (...):gsub('%.[^%.]+$', '')
local FILEPATH = PATH:gsub('%.', '/')

local lt, le = love.thread, love.event

local serialize = require(PATH .. ".serialize")
local options = require(PATH .. ".options")
local enum = require(PATH .. ".enum")

local client = {
  isConnected = false,
  -- private
  _handlers = { },
  _thread = lt.newThread(FILEPATH.."/clientThread.lua"),
  _isSingleplayer = false,
}

for _, type in ipairs(enum.packetType) do
  client._handlers[type] = { }
end

client.connect = function(address, serverID, defaultPort, username, serverPin)
  love.handlers[options.clientHandlerEvent] = client._handler

  client._channelIn = lt.newChannel()
  client._channelIn:push({
    "login",
    username,
  })
  client._thread:start(PATH, client._channelIn, address, serverID, defaultPort, serverPin)
  client.address = address
end

client.isRunning = function()
  return client._thread:isRunning()
end

client.setSingleplayerMode = function(isSingleplayer)
  if client.isRunning() then
    options.log("Tried to change singleplayer mode while already running")
    return false
  end
  client._isSingleplayer = isSingleplayer
  return true
end

client.addHandler = function(type, callback)
  if not client._handlers[type] then
    client._handlers[type] = { }
  end
  table.insert(client._handlers[type], callback)
end

client.send = function(type, ...)
  if client._isSingleplayer then
    le.push(options.serverHandlerEvent, type, ...)
    return
  end
  client._channelIn:push({
    "send",
    serialize.encode(type, ...),
  })
end

client.sendChannel = function(channel, type, ...)
  if client._isSingleplayer then
    le.push(options.serverHandlerEvent, type, ...)
    return
  end
  client._channelIn:push({
    "channel",
    channel,
    serialize.encode(type, ...),
  })
end

client.disconnect = function(reason)
  if client.isRunning() then
    client._channelIn:push({
      "disconnect",
      reason or enum.disconnect.normal
    })
  end
end

-- if you want to disconnect, use client.disconnect
-- this function is for when you need to rejoin the thread when the program is closing
client.quit = function()
  if client.isRunning() then
    client.nonwaitingQuit()
    client._thread:wait()
  end
  client._channelIn = nil
  client.isConnected = false
end

client.nonwaitingQuit = function()
  if not client.isRunning() then
    return
  end
  client._channelIn:performAtmoic(function()
    client._channelIn:clear()
    client._channelIn:push("quit")
  end)
end

client.threaderror = function(thread, errorMessage)
  if thread == client._thread then
    options.error("Error on MintHive client thread: " .. errorMessage)
    return true
  end
  return false
end

-- private

client._handler = function(packetType, encoded, ...)
  if client._isSingleplayer then
    for _, callback in ipairs(client._handlers[packetType]) do
      callback(encoded, ...)
    end
    return
  end

  if packetType == "error" then
    client.threaderror(client._thread, encoded)
    return
  elseif packetType == "log" then
    options.log("Thread", encoded, ...)
    return
  end

  if packetType == "ping" then
    client.ping = encoded
    return
  end

  local success, decoded
  if encoded then
    success, decoded = pcall(serialize.decodeIndexed, encoded:getString())
    if not success then
      options.log("Could not decode incoming data")
      return
    end
  end

  if packetType == enum.packetType.receive then
    local type_ = decoded[1]
    if not type_ or type(client._handlers[type_]) ~= "table" then
      options.log("There were no handlers for received type: "..tostring(type_))
      return
    end
    for _, callback in ipairs(client._handlers[type_]) do
      callback(unpack(decoded, 2))
    end
  elseif packetType == enum.packetType.disconnect then
    options.log("Disconnected! Reason: ", decoded[1], "code", decoded[2])
    client.isConnected = false
    for _, callback in ipairs(client._handlers[enum.packetType.disconnect]) do
      callback(decoded[1], decoded[2])
    end
  elseif packetType == enum.packetType.login then
    client.isConnected = true
    options.log("Connection has been successful")
    for _, callback in ipairs(client._handlers[enum.packetType.login]) do
      callback()
    end
  end
end

return client