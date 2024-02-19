local console, identity = false, "love-jam-2024"

if console and love._os == "Windows" then
  love._openConsole()
end

local lfs = love.filesystem
lfs.setIdentity(identity, true)
love.setDeprecationOutput(true)

local args = require("util.args")
local logger = require("util.logger")

if jit then
  jit.on()
end

local settings = require("util.settings")
local json = require("util.json")
local lang = require("util.lang")
local file = require("util.file")

local saveDir = lfs.getSaveDirectory()
local saveDirLang = { }
for _, f in ipairs(lfs.getDirectoryItems("assets/languages")) do
  f = "assets/languages/" .. f
  if lfs.getRealDirectory(f) == saveDir then
    table.insert(saveDirLang, f)
  else
    local success, json = json.decode(f)
    if not success then
      return error("Could not decode language json "..tostring(f)..", error: "..tostring(json))
    end
    local fileName = file.getFileName(f)
    lang.importLocale(fileName, json)
  end
end

-- Second loop allows for savedir languages to override asset based ones
for _, f in ipairs(saveDirLang) do
  if file.getFileExtension(f) == "json" then
    local success, json = json.decode(f)
    if not success then
      return error("Could not decode language json "..tostring(f)..", error: "..tostring(json))
    end
    local fileName = file.getFileName(f)
    lang.importLocale(fileName, json) 
  end
end

local baseConf = function(t)
  t.console = console
  t.version = "12.0"
  t.identity = identity
  t.appendidentity = true
  t.accelerometerjoystick = false

  t.modules.touch   = false
  t.modules.video   = false
end

if args["--server"] then
  logger.info("Configuring server")
  love.isServer = true
  love.isClient = false
  love.conf = function(t)
    baseConf(t)

    t.window = nil

    t.modules.data    = true
    t.modules.event   = true
    t.modules.math    = true
    t.modules.physics = true
    t.modules.system  = true
    t.modules.thread  = true
    t.modules.timer   = true

    t.modules.audio    = false
    t.modules.font     = false
    t.modules.graphics = false
    t.modules.image    = false
    t.modules.joystick = false
    t.modules.keyboard = false
    t.modules.mouse    = false
    t.modules.window   = false

  end

else
  logger.info("Configuring client")
  love.isServer = false
  love.isClient = true
  love.conf = function(t)
    baseConf(t)

    t.window.title = "Love Jam 2024"
    t.window.icon  = nil
    t.window.width = settings.client.windowSize.width
    t.window.height = settings.client.windowSize.height
    t.window.fullscreen = settings.client.windowFullscreen
    t.window.resizable = true
    t.window.minwidth = settings._default.client.windowSize.width
    t.window.minheight = settings._default.client.windowSize.height
    t.window.displayindex = 1
    t.window.depth = true
    t.window.mssa = 16

    t.modules.audio    = true
    t.modules.data     = true
    t.modules.event    = true
    t.modules.font     = true
    t.modules.graphics = true
    t.modules.image    = true
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.math     = true
    t.modules.mouse    = true
    t.modules.physics  = true
    t.modules.system   = true
    t.modules.thread   = true
    t.modules.timer    = true
    t.modules.window   = true
  end
end