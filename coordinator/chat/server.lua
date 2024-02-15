local logger = require("util.logger")
local utf8 = require("utf8")

local network = require("libs.MintHive.server")

return function(coordinator)
  coordinator.serverSendChatMessage = function(message)
      network.sendAll(coordinator.toClient, message)
    end

  coordinator.serverSendTargetedChatMessage = function(client, message)
      network:send(client, coordinator.toClient, message)
    end

  coordinator.recieveChatMessage = function(client, message)
    local len = utf8.len(message)
    if len == 0 then
      return
    end
    if len > 100 then
      message = utf8.sub(message, 1, 100)
    end
    logger.info("Chat:", client.username, ":", message)
    coordinator.serverSendChatMessage({
      coordinator.color.username, client.username, coordinator.color.white, ": "..message
    })
  end

  network.addHandler(coordinator.toServer, coordinator.recieveChatMessage)

end