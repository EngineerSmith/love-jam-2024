-- Customize MintHive's behaviour
-- This file is ran in both main thread and child threads. So Ensure you use thread safe code

return {
  -- logging and error handling (Only called from the main thread)
  log = function(...)
    print("MintHive: ".. table.concat({...}, ", "))
  end,
  error = function(msg)
    error("MintHive: "..tostring(msg))
  end,
  -- This is a basic implementation of username validation, so you can customize to fit your specific needs.
  -- And you can call upon this function within your own text input box for validation
  validateUsername = function(username)
    -- Verifies that the username conforms to the length required
    if #username < 3 or #username > 32 then
      return false
    end

    -- Verifies that the username contains only alphanumeric characters, underscores, or hyphens.
    if not string.match(username, "^[a-zA-Z0-9_-]+$") then
      return false
    end

    -- Verifies that the username doesn't contain reserved keywords
    local reservedKeywords = { "server", "admin", "moderator" }
    for _, keyword in ipairs(reservedKeywords) do
      if username:find(keyword, 1, true) then
        return false
      end
    end

    return true
  end,
  -- external library locations
  appleCakeLocation = "libs.appleCake", -- not required to use MintHive, just adds profiling for MH

--[[ 
  Only change these if you know what you're doing
]]--

  serverHandlerEvent = "MintHiveServer",
  clientHandlerEvent = "MintHiveClient",
  searchHandlerEvent = "MintHiveSearch",

  -- port the client/server uses for searching the network
  searchListenPort = 19991,

  compressionFunction = "lz4", -- https://love2d.org/wiki/CompressedDataFormat

    -- Changing the following values after having generated uids
    -- Will cause previously generated UIDs to become invalid
  hashFunction = "sha512", -- https://love2d.org/wiki/HashFunction
  uidLength = 64,
  saltLength = 64,
}