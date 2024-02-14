return function(isClient, isServer)
  local chatCoordinator = {
    chatLimit = 10,
    chat = { },
    color = {
      notification = { 120/255, 255/255,  30/255 },
      username =     {  80/255, 160/255, 255/255 },
      white =        { 255/255, 255/255, 255/255 },
    }
  }

  chatCoordinator.chat.insert = function(message)
    if #chatCoordinator.chat == chatCoordinator.chatLimit then
      table.remove(chatCoordinator.chat, 1)
    end
    table.insert(chatCoordinator.chat, message)
  end

  chatCoordinator.chat.clear = function()
    for i=1, 10 do
      chatCoordinator.chat[i] = nil
    end
  end

  if isServer then
    require("coordinator.chat.server")(chatCoordinator)
  end
  if isClient then
    require("coordinator.chat.client")(chatCoordinator)
  end

  return chatCoordinator
end