local lg = love.graphics

local mintHive = require("libs.MintHive")
local settings = require("util.settings")
local logger = require("util.logger")
local lang = require("util.lang")
local uiUtil = require("util.ui")
local utf8 = require("utf8")

return function(ui)
  local chat = {
    opened = false,
    protoText = "",
    cursor = 0,
  }

  local chatCoordinator = require("coordinator.chat")(mintHive.isClient(), mintHive.isServer())

  mintHive.server.addHandler("login", function(client)
    if ui.scene.unloaded then return end
    logger.info(client.username, "has joined!")
    chatCoordinator.serverSendChatMessage({
      chatCoordinator.color.username, client.username, chatCoordinator.color.notification, lang.getText("chat.notification.join")
    })
  end)

  mintHive.server.addHandler("disconnect", function(client)
    if ui.scene.unloaded then return end
    logger.info(client.username, "has left")
    chatCoordinator.serverSendChatMessage({
      chatCoordinator.color.username, client.username, chatCoordinator.color.notification, lang.getText("chat.notification.left")
    })
  end)

  chat.update = chatCoordinator.update

  local chatBackground = { .3, .3, .3, .7 }
  local chatInputBackground = { .2, .2, .7 }
  local chatTextColor = { 1, 1, 1, 1}

  local formatMessages = function(font, width)
    local messages = { }
    for i, message in ipairs(chatCoordinator.chat) do
      local _, text = uiUtil.getWrapColored(font, message, width)
      for _, line in ipairs(text) do
        table.insert(messages, 1, line)
      end
    end
    return messages
  end

  chat.draw = function(font)
    lg.push("all")
    lg.setFont(font)
    local width = lg.getWidth()*0.4 -- 40%
    local height = font:getHeight()
    local padding = 8

    if chat.opened then
      lg.setColor(chatBackground)
      local backgroundHeight = lg.getHeight() - height * (chatCoordinator.chatLimit + 1)
      lg.rectangle("fill", -padding, backgroundHeight, width + padding, height * chatCoordinator.chatLimit)
      lg.setColor(chatInputBackground)
      lg.rectangle("fill", 0, lg.getHeight() - height, width, height)
      lg.setColor(chatTextColor)
      local x, y = padding, lg.getHeight() - height
      lg.print("> "..chat.protoText, x, y)
      -- cursor
      if love.timer.getTime() % 1 > .5 then
        x = x + font:getWidth("> ")
        local cursorPos = 0
        if chat.cursor > 1 then
          local s = chat.protoText:sub(1, utf8.offset(chat.protoText, chat.cursor)-1)
          cursorPos = font:getWidth(s)
        end
        lg.line(x + cursorPos, y, x + cursorPos, y + height)
      end

      local messages = formatMessages(font, width)

      for i = 1, chatCoordinator.chatLimit do
        if not messages[i] then break end
        lg.print(messages[i], padding, lg.getHeight() - height*(i+1))
      end
    elseif #chatCoordinator.chat ~= 0 and chatCoordinator.timeSinceLastMessage < 6 then
      local alpha = chatBackground[4] * 1 -(chatCoordinator.timeSinceLastMessage - 5)
      lg.setColor(chatBackground[1], chatBackground[2], chatBackground[3], alpha)
      lg.rectangle("fill", -padding, lg.getHeight()*4, width+padding, height*4+padding, padding)
      local messages = formatMessages(font, width)
      lg.setColor(chatTextColor)
      for i = 1, 3 do
        if not messages[i] then break end
        lg.print(messages[i], padding, lg.getHeight() - height*(i+1))
      end
    end
    lg.pop()
  end

  local split = function(str, position)
    local offset = utf8.offset(str, position) or 0
    return str:sub(1, offset-1), str:sub(offset)
  end

  chat.textinput = function(text)
    if chat.opened then
      local a, b = split(chat.protoText, chat.cursor)
      local t  = table.concat({a, text, b})
      if chat.opened and utf8.len(t) <= 100 then
        chat.protoText = t
        chat.cursor = chat.cursor + utf8.len(text)
        return true
      end
    end
  end

  chat.keypressed = function(scancode)
    if not chat.opened then
      for _, chatButton in ipairs(settings.client.input.openChat) do
        local chatScancode = chatButton:match("^sc:(.+)$")
        if chatScancode == scancode then
          chat.protoText = ""
          chat.cursor = 1
          chat.opened = true
          return true
        end
      end
    else -- opened chat

      -- text editing
      if scancode == "backspace" then
        local a, b = split(chat.protoText, chat.cursor)
        chat.protoText = table.concat({split(a, utf8.len(a)), b})
        chat.cursor = math.max(1, chat.cursor - 1)
        return true
      elseif scancode == "delete" then
        local a, b = split(chat.protoText, chat.cursor)
        local _, b = split(b, 2)
        chat.protoText = table.concat({a, b})
        if utf8.len(chat.protoText) == 0 then
          chat.cursor = 1
        end
        return true
      elseif scancode == "paste" then
        local a, b = split(chat.protoText, chat.cursor)
        local clipboard = love.system.getClipboardText()
        chat.protoText = table.concat({a, clipboard, b})
        chat.cursor = chat.cursor + utf8.len(clipboard)
        return true
      end

      -- cursor movement
      if scancode == "left" then
        chat.cursor = math.max(0, chat.cursor - 1)
        return true
      elseif scancode == "right" then
        chat.cursor = math.min(utf8.len(chat.protoText) + 1, chat.cursor + 1)
        return true
      elseif scancode == "home" then
        chat.cursor = 1
        return true
      elseif scancode == "end" then
        chat.cursor = utf8.len(chat.protoText) + 1
        return true
      end

      -- close chat
      if scancode == "tab" or scancode == "escape" then
        chat.opened = false
        return true
      elseif scancode == "return" then
        chatCoordinator.sendChatMessage(chat.protoText)
        chat.opened = false
        return true
      end

    end
  end

  return chat
end