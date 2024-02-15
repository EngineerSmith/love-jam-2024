local PATH = (...):gsub('%.[^%.]+$', '')

local ld = love.data

local ffi = require("ffi")
local buffer = require("string.buffer")

local options = require(PATH .. ".options")

local bufferOpts = {
  dict = {
    "type",
    "userdata"
  }
}

table.sort(bufferOpts.dict, function(a, b) return a < b end)

local buffer_encode = buffer.new(bufferOpts)
local buffer_decode = buffer.new(bufferOpts)

local supportedTypesTable = {
  boolean  = true,
  number   = true,
  string   = true,
  table    = true,
  userdata = true, -- Love data objects only
}

local isSupported
isSupported = function(var, _isRecursive)
  local varType = type(var)
  if not supportedTypesTable[varType] then
    return false, varType
  end
  if varType == "table" then
    for key, value in pairs(var) do
      local supported, errorType = isSupported(key, true)
      if supported == false then
        return false, errorType
      end
      local supported, errorType = isSupported(value, true)
      if supported == false then
        return false, errorType
      end
    end
  elseif varType == "userdata" then
    if _isRecursive then return false, varType end
    if type(var.typeOf) == "function" then
      return var:typeOf("Data"), varType
    end
    -- fallback
    return false, "non-love userdata"
  end
  return true, varType
end

local serialize
serialize = {
  encode = function(...)
      local data = { ... }
      for i, var in ipairs(data) do
        local supported, errorType = isSupported(var)
        if not supported then
          if errorType == "userdata" then
            errorType = "userdata within a table"
          end
          options.error("Tried to encode unsupported type: "..errorType.." in varargs index "..i)
          return
        end
        if type(var) == "userdata" then
          if type(var.typeOf) == "function" and var:typeOf("Data") then
            if var:getSize() == 0 then
              data[i] = nil
            else
              data[i] = {
                type = "userdata",
                userdata = var:getString(),
              }
            end
          end
        end
      end
      local buffer_ptr, buffer_len = buffer_encode:reset():encode(data):ref()
      local encoded = ld.newByteData(buffer_len)
      ffi.copy(encoded:getFFIPointer(), buffer_ptr, buffer_len)
      return encoded
    end,
  decode = function(data)
      return unpack(serialize.decodeIndexed(data))
    end,
  decodeIndexed = function(data)
      local decoded = buffer_decode:set(data):decode()
      for i, var in ipairs(decoded) do
        if type(var) == "table" and var.type == "userdata" and type(var.userdata) == "string" then
          decoded[i] = ld.newByteData(var.userdata)
        end
      end
      return decoded
    end,
}

return serialize