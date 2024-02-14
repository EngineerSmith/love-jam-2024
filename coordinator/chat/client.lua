local logger = require("util.logger")
local assets = require("util.assets")
local utf8 = require("utf8")
local suit = require("libs.suit")

local network = require("libs.MintHive").client

return function(coordinator)

  coordinator.timeSinceLastMessage = 0
  coordinator.update = function(dt)
    coordinator.timeSinceLastMessage = coordinator.timeSinceLastMessage + dt
  end

  coordinator.sendChatMessage = function(message)
      if network.isConnected then
        network.send("chatMessage", message)
      end
    end

  coordinator.addChatMessage = function(message)
    coordinator.chat.insert(message)
    coordinator.timeSinceLastMessage = 0
  end

  coordinator.clear = function()
      coordinator.chat.clear()
    end
  
  network.addHandler("chatMessage", coordinator.addChatMessage)

  network.addHandler("disconnect", function(reason, code)
      coordinator.addChatMessage("Disconnected. Reason: "..tostring(reason)..", Code: "..tostring(code))
    end)
end