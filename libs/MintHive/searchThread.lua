local PATH, channelIn = ...

local options = require(PATH .. ".options")

local appleCake
if type(options.appleCakeLocation) == "string" and love.filesystem.getInfo(options.appleCakeLocation:gsub('%.init$', ''):gsub('%.', '/').."/init.lua", "file") then
  appleCake = require(options.appleCakeLocation)()
  appleCake.setThreadName("MintHive Server")
  appleCake.setThreadSortIndex(50)
  appleCake.setBuffer(true)
end

local socket = require("socket")
local serialize = require(PATH .. "serialize")

local POST = function(...)
  le.push(options.serverHandlerEvent, ...)
end

-- thread loop

local udp = socket.udp()
udp:setTimeout(1/100)
local success, errmsg = udp:setsockname("*", 19991)
if not success then
  POST("socknameError", errmsg)
end
local success = udp:setOption("broadcast", true)
if not success then
  POST("broadcastError")
  return
end

while true do
  -- broadcast
  udp:sendto("search", "255.255.255.255", options.searchListenPort)
  -- listen
  local limit = 0
  local data, ip = udp:receivefrom()
  while data and limit < 50 do
    local success, decoded = pcall(serialize.decodeIndexed, data)
    if not success then
      POST("log", "Could not decode incoming data from: "..tostring(ip))
      goto continue
    end
    local port, data = unpack(decoded)
    POST("found", port, data)
    ::continue::
    -- next
    data, ip = udp:receivefrom()
    limit = limit + 1
  end
  -- handle thread commands
  local command, limit = channelIn:demand(1/100), 0
  while command and limit < 50 do
    if command == "quit" then
      udp:shutdown()
      return
    end
    command = channelIn:pop()
    limit = limit + 1
  end
  love.time.sleep(1/10)
end