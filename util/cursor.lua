local lm = love.mouse

local isCursorSupported = lm.isCursorSupported()

local cursors = { }
if isCursorSupported then
  cursors["sizewe"] = lm.getSystemCursor("sizewe")
  cursors["sizens"] = lm.getSystemCursor("sizens")
  cursors["sizenesw"] = lm.getSystemCursor("sizenesw")
  cursors["sizenwse"] = lm.getSystemCursor("sizenwse")
  cursors["sizeall"] = lm.getSystemCursor("sizeall")
  cursors["ibeam"] = lm.getSystemCursor("ibeam")
  cursors["hand"] = lm.getSystemCursor("hand")
end

local cursor = { }

cursor.switch = function(cursorType)
  if isCursorSupported then
    local c = type(cursorType) == "string" and cursors[cursorType] or cursorType
    if c ~= cursor.current then
      cursor.current = c
      lm.setCursor(c)
    end
    return true
  end
  return false
end

cursor.switchIf = function(bool, type)
  if bool then
    return cursor.switch(type)
  end
  return false
end

return cursor 