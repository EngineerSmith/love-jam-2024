local PATH = (...):gsub('%.[^%.]+$', '')
local FILEPATH = PATH:gsub('%.', '/')

local lt, ld, le = love.thread, love.data, love.event

local serialize = require(PATH .. ".serialize")
local options = require(PATH .. ".options")
local enum = require(PATH .. ".enum")

local server = {
  channel = enum.channel,
  disconnectReason = enum.disconnect,
  singleplayerClient = {
    username = "usr",
    uid = "0",
  },
  -- private
  _handlers = {
    started = { }
  },
  _thread = lt.newThread(FILEPATH .. "/serverThread.lua"),
  _isSingleplayer = false,
}

for _, enum in pairs(enum.packetType) do
  server._handlers[enum] = { }
end

server.start = function(settings)
  love.handlers[options.serverHandlerEvent] = server._handler
  server._clients = { }
  server._clientCount = 0

  server._channelIn = lt.newChannel()
  server._thread:start(PATH, server._channelIn, settings)
end

server.isRunning = function()
  return server._thread:isRunning()
end

server.setSingleplayerMode = function(isSingleplayer)
  if server.isRunning() then
    options.log("Tried to change singleplayer mode while already running")
    return false
  end
  server._isSingleplayer = isSingleplayer
  return true
end

server.getConnectedAmount = function()
  return server.isRunning() and server._clientCount or nil
end

server.addHandler = function(type, callback)
  if not server._handlers[type] then
    server._handlers[type] = { }
  end
  table.insert(server._handlers[type], callback)
end

server.send = function(client, type_, ...)
  if server._isSingleplayer then
    le.push(options.clientHandlerEvent, type_, ...)
    return
  end
  server._channelIn:push({
    type(client) == "table" and client.sessionID or client,
    serialize.encode(type_, ...),
  })
end

server.sendAll = function(type, ...)
  server.send("all", type, ...)
end

server.sendChannel = function(channel, client, type_, ...)
  if server._isSingleplayer then
    le.push(options.clientHandlerEvent, type_, ...)
    return
  end
  server._channelIn:push({
    "channel",
    channel,
    type(client) == "table" and client.sessionID or client,
    serialize.encode(type_, ...),
  })
end

server.sendChannelAll = function(channel, type, ...)
  server.sendChannel(channel, "all", type, ...)
end

server.disconnectClient = function(client, reason)
  if not server.isRunning() then
    return nil
  end
  server._channelIn:push({
    client.id,
    enum.packetType.disconnect,
    reason or enum.disconnect.normal
  })
end

server.quit = function()
  if server.isRunning() then
    server.nonwaitingQuit()
    server._thread:wait()
  end
  server._clientCount = nil
  server._channelIn = nil
end

server.nonwaitingQuit = function()
  if not server.isRunning() then
    return
  end
  server._channelIn:performAtmoic(function()
    server._channelIn:clear()
    server._channelIn:push("quit")
  end)
end

server.threaderror = function(thread, errorMessage)
  if thread == server._thread then
    options.error("Error on MintHive server thread: " .. errorMessage)
    return true
  end
  return false
end

-- private functions

server._getClient = function(sessionID)
  if not server.isRunning() then
    return nil
  end
  
  local client = server._clients[sessionID]
  if not client then
    client = {
      sessionID = sessionID
    }
    server._clients[sessionID] = client
    server._clientCount = server._clientCount + 1
  end
  return client
end

server._removeClient = function(sessionID)
  if server.isRunning() and server._clients[sessionID] then
    server._clients[sessionID] = nil
    server._clientCount = server._clientCount - 1
  end
end

server._handler = function(packetType, ...)
  if server._isSingleplayer then
    for _, callback in ipairs(server._handlers[packetType]) do
      callback(server.singleplayerClient, ...)
    end
    return
  end

  if packetType == "error" then
    server.threaderror(server._thread, ...)
    return
  elseif packetType == "log" then
    options.log(...)
    return
  elseif packetType == "started" then
    for _, callback in ipairs(server._handlers[packetType]) do
      callback(...)
    end
    return
  end

  local sessionID, encoded = ...
  local decoded = nil
  if encoded then
    local success
    success, decoded = pcall(serialize.decodeIndexed, encoded:getString())
    encoded = nil
    if not success then
      options.log("Could not decode incoming data")
      return
    end
  end
  local client = server._getClient(sessionID)

  if packetType == enum.packetType.receive then
    local type_ = decoded[1]
    if not type_ or type(server._handlers[type_]) ~= "table" then
      options.log("There were no handlers for received type: "..tostring(type_))
      return
    end
    for _, callback in ipairs(server._handlers[type_]) do
      callback(client, unpack(decoded, 2))
    end
  else
    if packetType == enum.packetType.disconnect then
      server._removeClient(sessionID)
    elseif packetType == enum.packetType.login then
      client.username = decoded[1]
      client.uid = decoded[2]
    end
    for _, callback in ipairs(server._handlers[packetType]) do
      callback(client)
    end
  end
end

return server