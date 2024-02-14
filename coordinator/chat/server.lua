local logger = require("util.logger")
local utf8 = require("utf8")

local network = require("libs.MintHive.server")

return function(coordinator)
  coordinator.sendChatMessage = function(message)
      network.sendAll("chatMessage", message)
    end

  coordinator.sendTargetedChatMessage = function(client, message)
      network:send(client, "chatMessage", message)
    end

  coordinator.recieveChatMessage = function(client, message)
      local len = utf8.len(message)
      if len == 0 then
        return
      end
      if len > 100 then
        message = utf8.sub(message, 1, 100)
      end
      coordinator.sendChatMessage({
        coordinator.color.username, client.username, coordinator.color.white, ": "..message
      })
    end

  network.addHandler("chatMessage", coordinator.recieveChatMessage)

end