local PATH, channelIn, settings = ...

local options = require(PATH .. ".options")

local appleCake
if type(options.appleCakeLocation) == "string" and love.filesystem.getInfo(options.appleCakeLocation:gsub('%.init$', ''):gsub('%.', '/').."/init.lua", "file") then
  appleCake = require(options.appleCakeLocation)()
  appleCake.setThreadName("MintHive Server")
  appleCake.setThreadSortIndex(50)
  appleCake.setBuffer(true)
end

require("love.math") -- global module, careful usage required
local lt, le, ld, ls = love.thread, require("love.event"), require("love.data"), require("love.system")
local ffi = require("ffi")
local enet = require("enet")
local enum = require(PATH .. ".enum")
local serialize = require(PATH .. ".serialize")

local POST = function(...)
  le.push(options.serverHandlerEvent, ...)
end

love.filesystem.createDirectory(".data")
local file = love.filesystem.openFile(".data/server.dat", "c")
file:setBuffer("none")
if not love.filesystem.getInfo(file:getFilename(), "file") then
  file:open("w")
  file:close()
end

local cleanUp
local getUID
do
  local rand = tonumber(os.getenv("RANDOM")) or 0
  local rngGen = love.math.newRandomGenerator(os.time(), 2^32-79917014+rand)
  local fill = function(byteArray, length) 
    for i = 0, length - 1 do
      byteArray[i] = rngGen:random(0, 0xFF)
    end
  end
  local basicFill = fill

  if ls.getOS() == "Windows" then
    ffi.cdef[[
      // kernel 32
      void* LoadLibraryA(const char* lpLibFileName);
      void* GetProcAddress(void* hModule, const char* lpProcName);
      bool FreeLibrary(void* hModule);
      // Advapi32: SystemFunction036
      bool RtlGenRandom(void* buffer, unsigned long bufferLength);
    ]]
    local kernel32 = ffi.load("kernel32.dll")
    local advapi = kernel32.LoadLibraryA("Advapi32.dll")
    if advapi then
      local RtlGenRandom = ffi.cast("bool (*) (void*, unsigned long)", kernel32.GetProcAddress(advapi, "SystemFunction036"))
      if RtlGenRandom then
        cleanUp = function()
          kernel32.FreeLibrary(advapi)
        end
        fill = function(byteArray, length)
          if not RtlGenRandom(byteArray, length) then
            return basicFill(byteArray, length)
          end
        end
      else
        kernel32.FreeLibrary(advapi)
        POST("log", "Could not find RtlGenRandom Function within winadvapi")
      end
    else
      POST("log", "Could not load winadvapi")
    end
  else
    fill = function(byteArray, length)
      local file = io.open("/dev/urandom", "rb")
      if not file then
        return basicFill(byteArray, length)
      end
      local bytes = file:read(length)
      file:close()
      ffi.copy(byteArray, bytes)
    end
  end

  getUID = function()
    local salt = ld.newByteData(options.saltLength)
    fill(ffi.cast('uint8_t*', salt:getFFIPointer()), salt:getSize())
    local uid = ld.newByteData(options.uidLength)
    fill(ffi.cast('uint8_t*', uid:getFFIPointer()), uid:getSize())
    -- salt uid
    local saltedUID = ld.newByteData(uid:getSize() + salt:getSize())
    ffi.copy(saltedUID:getFFIPointer(), uid:getFFIPointer(), uid:getSize())
    local offset = ld.newDataView(saltedUID, uid:getSize(), salt:getSize()):getFFIPointer()
    ffi.copy(offset, salt:getFFIPointer(), salt:getSize())
    -- hash salted uid
    local hashedUID = ld.hash("data", options.hashFunction, saltedUID)
    -- prepare salted uid and salt to save
    local entry = ld.newByteData(hashedUID:getSize() + salt:getSize())
    ffi.copy(entry:getFFIPointer(), hashedUID:getFFIPointer(), hashedUID:getSize())
    local offset = ld.newDataView(entry, hashedUID:getSize(), salt:getSize()):getFFIPointer()
    ffi.copy(offset, salt:getFFIPointer(), salt:getSize())
    -- save entry
    local success, errmsg = file:open("a")
    if not success then
      POST("error", "Could not open uid file in append mode: "..tostring(errmsg))
      return nil, nil
    end
    file:write(entry)
    file:close()
    return uid, hashedUID
  end
end

local isExistingUID
do
  local hashSize = ld.hash("data", options.hashFunction, ""):getSize()
  if hashSize % 4 ~= 0 then
    -- this error should only happen, if love introduces new hash functions that aren't divisible by 4. Currently all functions are.
    POST("error", "Expected the bytes of the resulting hash size to be divisible by 4. Size: "..tostring(hashSize))
    return
  end

  isExistingUID = function(uid)
    local result, hashedUID = false, nil

    local success, errmsg = file:open("r")
    if not success then
      POST("error", "Could not open uid file in read mode: "..tostring(errmsg))
      return nil, nil
    end
    local saltedUID = ld.newByteData(uid:getSize() + options.saltLength)
    ffi.copy(saltedUID:getFFIPointer(), uid:getFFIPointer(), uid:getSize())
    local saltedUID_offset = ld.newDataView(saltedUID, uid:getSize(), options.saltLength):getFFIPointer()
    uid = nil
    while not file:isEOF() do
      -- read
      local readHash, readSize = file:read("data", hashSize)
      if not readHash or readSize ~= hashSize then break end
      local salt, readSize = file:read("data", options.saltLength)
      if not salt or readSize ~= options.saltLength then break end
      -- calculate hashed uid, with salt
      ffi.copy(saltedUID_offset, salt:getFFIPointer(), salt:getSize())
      hashedUID = ld.hash("data", options.hashFunction, saltedUID)
      -- compare - hash size expected to be divisible by 4
      local storedHash_ptr = ffi.cast('uint32_t*', readHash:getFFIPointer())
      local calculatedHash_ptr = ffi.cast('uint32_t*', hashedUID:getFFIPointer())

      result = true
      for i = 0, hashSize/4 - 1 do
        if storedHash_ptr[i] ~= calculatedHash_ptr[i] then
          result = false
          break
        end
      end
      if result then break end
    end
    file:close()
    return result, hashedUID 
  end
end

local clients = { }
local getClient = function(sessionID, makeNew)
  if makeNew == nil then 
    makeNew = true
  end
  local client = clients[sessionID] or (makeNew and { } or nil)
  clients[sessionID] = client
  return client
end

local removeClient = function(sessionID)
  clients[sessionID] = nil
end

local validLogin = function(client, encoded)
  local decoded = serialize.decodeIndexed(encoded:getString())
  if type(decoded) ~= "table" or decoded == nil then
    POST("log", "Invalid decoded")
    return false
  end
  -- USERNAME
  client.username = decoded[1]
  if type(client.username) ~= "string"   or
     #client.username == 0               or
     client.username == "server"         or
    (options.validateUsername and not options.validateUsername(client.username))
  then
    POST("log", "Invalid username")
    return false
  end
  -- UID: Most expensive, so it is last in validation
  local uid
  if decoded[2] then -- existing user
    local decodedUID = decoded[2]
    if type(decodedUID) ~= "userdata" or not decodedUID:typeOf("Data") or decodedUID:getSize() ~= options.uidLength then
      POST("log", "Invalid decodedUID")
      return false
    end
    local success
    success, client.uid = isExistingUID(decodedUID)
    decodedUID, decoded[2] = nil, nil
    if not success then
      POST("log", "Did not find given uid")
      return false
    end
  else -- new user
    uid, client.uid = getUID()
  end
  --
  client.loggedIn = true
  return true, uid
end

-- thread loop

local host = enet.host_create(
  "*:"..tostring(settings.port),
  settings.maxPeers,
  enum.channelCount,
  settings.inBandwidth,
  settings.outBandwidth
)

if not host then
  return POST("error", "Could not start server on port: "..tostring(settings.port))
end
POST("log", "Server started on port: "..tostring(settings.port))
POST("started", settings.port)

local inProfile, outProfile
while true do
  -- RECEIVE
  inProfile = appleCake and appleCake.isActive and appleCake.profile("in", { cycles = 0 }, inProfile) or nil
  local event, limit = host:service(20), 0
  while event and limit < 50 do
    if inProfile then inProfile.args.cycles = inProfile.args.cycles + 1 end

    local sessionID = ld.hash("string", "sha256", tostring(event.peer)) -- peer:connect_id() doesn't work if user disconnects unexpectedly
    local client = getClient(sessionID)

    if event.type == "receive" then
      local success, encoded = pcall(ld.decompress, "data", options.compressionFunction, event.data)
      if not success then
        if client.loggedIn then
          POST("log", "Could not decompress incoming data from "..client.username)
        else
          removeClient(sessionID)
          client.peer:disconnect_now(enum.disconnect.badlogin)
        end
        goto continue
      end
      if client.loggedIn then
        POST(enum.packetType.receive, sessionID, encoded)
      else
        local success, uid = validLogin(client, encoded)
        if not success then
          removeClient(sessionID)
          client.peer:disconnect_now(enum.disconnect.badlogin)
          goto continue
        end
        POST(enum.packetType.login, sessionID, serialize.encode(client.username, client.uid))
        channelIn:push({ -- tell client it is accepted, and their uid if they're a new user
          sessionID,
          serialize.encode(enum.packetType.login, uid)
        })
      end
    elseif event.type == "disconnect" then
      removeClient(sessionID)
      if client.loggedIn then
        POST(enum.packetType.disconnect, sessionID)
      end
    elseif event.type == "connect" then
      client.peer = event.peer
      if event.data ~= settings.pin then
        POST("log", "Review", event.data, settings.pin)
        removeClient(sessionID)
        client.peer:disconnect_now(enum.disconnect.badlogin)
        goto continue
      end
      client.sessionID = sessionID
      client.loggedIn = false
    end
    ::continue::
    event = host:check_events()
    limit = limit + 1
  end
  if inProfile then inProfile:stop() end

  -- SEND
  outProfile = appleCake and appleCake.isActive and appleCake.profile("out", { cycles = 0}, outProfile) or nil
  local command, limit = channelIn:demand(1/100), 0
  while command and limit < 50 do
    if outProfile then outProfile.args.cycles = outProfile.args.cycles + 1 end
    if command == "quit" then
      host:destroy()
      if appleCake then
        outProfile:stop()
        appleCake.flush()
      end

      if type(cleanUp) == "function" then
        cleanUp()
      end

      return
    end
    if type(command) ~= "table" then
      POST("log", "Retrieved command to send was not of type table! It was "..type(command))
    else
      -- abstract target, channel and data from incoming
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
        target = command[3]
        data = command[4]
      end
      -- compress data
      local compressData
      if data and data ~= enum.packetType.disconnect then
        local success
        success, compressData = pcall(ld.compress, "data", options.compressionFunction, data)
        if not success then
          if target == "all" then
            POST("log", "Could not compress outgoing data to all")
          else
            local client = getClient(target, false)
            POST("log", "Could not compress outgoing data to "..tostring(target)..(client and client.username and " known as "..client.username or ""))
          end
          goto continue
        end
        if appleCake and appleCake.isActive then
          appleCake.mark("Compressed", "p", { size = data:getSize(), compressedSize = compressData:getSize() })
        end
      end
      -- send to target
      if target == "all" then
        for _, client in pairs(clients) do
          if client.loggedIn then
            client.peer:send(compressData:getPointer(), compressData:getSize(), channel, flags)
          end
        end
      else
        local client = getClient(target, false)
        if not client then
          POST("log", "Network target is not valid "..tostring(target))
          goto continue
        end
        if command[2] == enum.packetType.disconnect then
          local reason = tonumber(command[3]) or enum.disconnect.normal
          client.peer:disconnect(reason)
          goto continue
        end
        
        client.peer:send(compressData:getPointer(), compressData:getSize(), channel, flags)
      end
      ::continue::
    end
    command = channelIn:pop()
    limit = limit + 1
  end
  if outProfile then outProfile:stop() end
  -- AC
  if appleCake and appleCake.isActive then
    appleCake.flush()
  end
end