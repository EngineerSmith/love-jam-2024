local lfs = love.filesystem
local args = require("util.args")

local _print = print -- print is set at EOF

local logger = {
  internallog = {
    ["WARN"] = {},
    ["ERROR"] = {},
    ["FATAL"] = {},
  },
  sinks = {},
  levels = require("util.loggerLevels")
}

logger.addSink = function(sink)
  table.insert(logger.sinks, sink)
  return #logger.sinks
end

logger.removeSink = function(sinkID)
  table.remove(logger.sinks, sinkID)
end

logger.addSink(function(level, logMessage)
    if logger.internallog[level] then
      table.insert(logger.internallog[level], logMessage)
    end
  end)

local windowsSinkAdded = false
if jit.os == "Windows" then
  local f = io.popen("ver", "r")
  local result = f:read("*a")
  f:close()
  local version = tonumber(string.match(result or "", "Version (%d+%.%d+)%..+"))
  if not version or version < 10 then
    windowsSinkAdded = true
    _print()
    logger.addSink(function(_, logMessage)
      _print(logMessage)
      end)
  else
    os.execute("@echo off") -- without an os.execute, windows 10 console doesn't want to colour text with ansi escape colours
  end
else
  _print()
end

if not windowsSinkAdded then
  local colors = {
    ["INFO"] = "\27[32m",
    ["WARN"] = "\27[33m",
    ["ERROR"] = "\27[31m",
    ["FATAL"] = "\27[35m",
    ["UNKNOWN"] = "\27[36m",
    ["white"] = "\27[0m",
  }
  logger.addSink(function(level, _, time, message)
      _print(("%s%s %s%s %s"):format(colors[level] or colors["UNKNOWN"], level, time, colors["white"], message))
    end)
end


local getFormattedTime = function()
  return os.date("[%d/%m/%y %H:%M:%S]")
end

logger.file = nil
if args["-log"] then
  local file = "log.txt"
  if type(args["-log"]) == "table" then
    file = args["-log"][1]
  end
  
  if not lfs.getInfo(file, "file") then
    local _, errormsg = lfs.openFile(file, 'c')
    if errormsg then
      logger.runSinks("ERROR", "ERROR "..getFormattedTime().." Could not make log file: file name: "..file..", error: "..errormsg)
      goto skip
    end
  end
  
  local success, errormsg = lfs.append(file, "INFO "..getFormattedTime().." New logging session.\n")
  
  if not success then
    logger.runSinks("ERROR", "ERROR "..getFormattedTime().." Could not append log: file name: "..file..", error: "..errormsg)
    goto skip
  end
  
  logger.addSink(function(_, logMessage)
      lfs.append(file, logMessage.."\n")
    end)
  
  logger.file = file
  ::skip::
end

logger.runSinks = function(level, logMessage, time, message)
  for _, sink in ipairs(logger.sinks) do
    sink(level, logMessage, time, message)
  end
end

logger.log = function(level, ...)
  if not level or logger.levels[level] == nil then
    level = "UNKNOWN"
  end
  local message, n = "", select("#", ...)
  if n > 1 then
    local t = {}
    for i=1, n do
      t[i] = tostring(select(i, ...))
    end
    message = table.concat(t, " ")
  elseif n == 1 then
    message = tostring(select(1, ...))
  end
  local time = getFormattedTime()
  local logMessage = ("%s %s %s"):format(level, time, message)
  logger.runSinks(level, logMessage, time, message)
end

logger.unknown = function(...)
  logger.log("UNKNOWN", ...)
end

logger.info = function(...)
  logger.log("INFO", ...)
end

logger.warn = function(...)
  logger.log("WARN", ...)
end

logger.error = function(...)
  logger.log("ERROR", ...)
end

logger.fatal = function(name, ...)
  if name == nil then
    logger.log("FATAL", ...)
  elseif not love.window then
    logger.log("FATAL", name, ...)
  else
    logger.log("FATAL", name, ":", ...)
    logger.info("Showing errorbox:", name)
    love.window.showMessageBox("Error occurred: "..name, table.concat({...}, " "), "error", true)
    love.event.quit()
  end
end

print = logger.unknown

return logger