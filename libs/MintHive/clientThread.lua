local PATH, channelIn, address, serverID, defaultPort, serverPin = ...

local options = require(PATH .. ".options")

local appleCake
if type(options.appleCakeLocation) == "string" and love.filesystem.getInfo(options.appleCakeLocation:gsub('%.init$', ''):gsub('%.', '/').."/init.lua", "file") then
  appleCake = require(options.appleCakeLocation)()
  appleCake.setThreadName("MintHive Client")
  appleCake.setThreadSortIndex(50)
  appleCake.setBuffer(true)
end

local lt, le, ld = love.thread, require("love.event"), require("love.data")
local enet = require("enet")
local enum = require(PATH .. ".enum")
local serialize = require(PATH .. ".serialize")

local POST = function(...)
  le.push(options.clientHandlerEvent, ...)
end

love.filesystem.createDirectory(".data")
local fileServerID = (tostring(serverID) or "0"):gsub(":", ".")
local file = love.filesystem.openFile((".data/client.%s.dat"):format(fileServerID), "c")
file:setBuffer("none")
if not love.filesystem.getInfo(file:getFilename(), "file") then
  local success, errormessage = file:open("w")
  if not success then
    POST("log", errormessage)
  end
  file:close()
end

local getUid = function()
  local success, errmsg = file:open("r")
  if not success then
    POST("error", "Could not open uid file in read mode: "..tostring(errmsg))
    return nil
  end
  local uid = file:read("data", options.uidLength)
  file:close()
  return uid
end

local saveUid = function(uid)
  if not uid then return end

  local success, errmsg = file:open("w")
  if not success then
    POST("error", "Could not open uid file in write mode: "..tostring(errmsg))
    return
  end
  file:write(uid)
  file:close()
end

-- thread loop

local host = enet.host_create(nil, 1, enum.channelCount, 0, 0)
if not address:find(":") then
  address = address .. ":" .. defaultPort
end
local server = host:connect(address, enum.channelCount, serverPin)
local loggedIn = false

local success = host:service(1000)

if not success or success.type ~= "connect" or success.peer ~= server then
  if success and success.peer ~= server then
    success.peer:disconnect_now(enum.disconnect.badconnect)
  end
  POST(enum.packetType.disconnect, serialize.encode("badconnect", enum.disconnect.badconnect))
  return host and host:destroy()
end

local inProfile, outProfile
while true do
  -- RECEIVE
  inProfile = appleCake and appleCake.profile("in", { cycles = 0 }, inProfile) or nil
  local event, limit = host:service(50), 0
  while event and limit < 50 do
    if inProfile then inProfile.args.cycles = inProfile.args.cycles + 1 end
    if event.type == "receive" then
      local success, data = pcall(ld.decompress, "data", options.compressionFunction, event.data)
      if not success then
        POST("log", "Incoming data ignored! Could not decompress:", tostring(data))
      else
        if loggedIn then
          POST(enum.packetType.receive, data)
        else
          local success, decoded = pcall(serialize.decodeIndexed, data:getString())
          if not success then
            POST("log", "Could not decode incoming encoded data confirming login. Disconnecting.")
            POST(enum.packetType.disconnect, serialize.encode("badserver", enum.disconnect.badserver))
            channelIn:performAtomic(function()
              channelIn:clear()
              channelIn:push("quit")
            end)
            break
          end
          if decoded[1] == enum.packetType.login then
            saveUid(decoded[2])
            decoded[2] = nil
            loggedIn = true
            POST(enum.packetType.login)
          else
            POST("log", "Didn't recieved confirming login packetType. Data ignored! Type: "..tostring(decoded[1]))
          end
        end
      end
    elseif event.type == "connect" then
      if event.peer ~= server then
        event.peer:disconnect_now(enum.disconnect.badconnect)
        POST("log", "Unknown connection handshake from "..tostring(event.peer))
      end
    elseif event.type == "disconnect" then
      local reason = enum.convert(event.data, "disconnect")
      POST(enum.packetType.disconnect, serialize.encode(reason, event.data))
      channelIn:performAtomic(function()
          channelIn:clear()
          channelIn:push("quit")
      end)
      break
    end
    event = host:check_events()
    limit = limit + 1
  end
  if inProfile then inProfile:stop() end

  -- SEND
  outProfile = appleCake and appleCake.profile("out", { cycles = 0 }, outProfile) or nil
  local command, limit = channelIn:demand(1/100), 0
  while command and limit < 20 do
    if outProfile then outProfile.args.cycles = outProfile.args.cycles + 1 end
    if command == "quit" then
      local state = server:state()
      if state ~= "disconnected" and state ~= "disconnecting" then
        server:disconnect_now(enum.disconnect.normal)
      end
      host:flush()
      host:destroy()
      if appleCake then
        outProfile:stop()
        appleCake.flush()
      end
      return
    end

    local target = command[1]
    local data = command[2]

    local channel = enum.channel.default
    local flags = "reliable"
    if target == "channel" then
      channel = command[2]
      if channel == enum.channel.unreliable then
        flags = "unreliable"
      elseif channel == enum.channel.unsequenced then
        flags = "unsequenced"
      end
      data = command[3]
    end

    if target == "login" then
      -- data is username in login command
      data = serialize.encode(data, getUid())
      target = "send"
    end

    if target == "send" then
      -- compress data
      local compressData
      if data then
        local success
        success, compressData = pcall(ld.compress, "data", options.compressionFunction, data)
        if not success then
          POST("log", "Could not compress outgoing data")
          goto continue
        end
        if appleCake and appleCake.isActive then
          appleCake.mark("Compressed", "p", { size = data:getSize(), compressedSize = compressData:getSize() })
        end
      end
      server:send(compressData:getPointer(), compressData:getSize(), channel, flags)
    elseif target == "disconnect" then
      server:disconnect(tonumber(command[2]) or enum.disconnect.normal)
    end
    ::continue::
    command = channelIn:pop()
    limit = limit + 1
  end
  if outProfile then outProfile:stop() end
  -- PING
  POST("ping", server:round_trip_time())
  -- AC
  if appleCake then appleCake.flush() end
end