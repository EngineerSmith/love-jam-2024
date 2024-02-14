local assets = require("util.assets")

local lg = love.graphics

local ui = { }

ui.getFont = function(size, name, scale)
  local fontSize = math.floor(size * (scale or 1))
  local fontName = name.."."..fontSize
  if not assets[fontName] then
    assets[fontName] = lg.newFont(assets[name], fontSize)
    assets[fontName]:setFilter("nearest", "nearest")
  end
  return assets[fontName], fontSize
end

ui.getWrapColored = function(font, text, limit)
  local width, wrappedText = font:getWrap(text, limit)
  local wrappedTextColored, textIndex = { }, 1
  local currentColoredText, color = text[textIndex+1], text[textIndex]
  for i, line in ipairs(wrappedText) do -- for each line
    wrappedTextColored[i] = { }
    while currentColoredText ~= nil do
      -- if line fits within the current color string
      if #line <= #currentColoredText then
        table.insert(wrappedTextColored[i], color)
        table.insert(wrappedTextColored[i], line)
        currentColoredText = currentColoredText:sub(#line+1)
        if currentColoredText == "" then
          textIndex = textIndex + 2
          if textIndex > #text then
            goto exit
          end
          currentColoredText, color = text[textIndex+1], text[textIndex]
        end
        break
      else -- if line is greater than current color string
        local before = line:sub(1, #currentColoredText)
        table.insert(wrappedTextColored[i], color)
        table.insert(wrappedTextColored[i], before)

        line = line:sub(#currentColoredText+1)
        textIndex = textIndex + 2
        if textIndex > #text then
          goto exit
        end
        currentColoredText, color = text[textIndex+1], text[textIndex]
      end
    end
  end
  ::exit::
  return width, wrappedTextColored
end

return ui