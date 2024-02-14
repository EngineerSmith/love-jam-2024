local love = love
local le, lg, ltr, lfs, lw = love.event, love.graphics, love.timer, love.filesystem, love.window

require("errorhandler")

local sceneManager = require("util.sceneManager")
local utf8 = require("util.utf8")
local flux = require("libs.flux")
local lang = require("util.lang")
local logger = require("util.logger")
local settings = require("util.settings")

local localFound, selectLang
if not settings.newSettings then
  localFound = lang.setLocale(settings.client.locale)
end

if settings.newSettings and not localFound then
  selectLang = true
  local locales = love.system.getPreferredLocales()
  logger.info("Preferred locales:", table.concat(locales, ", "))
  for _, locale in ipairs(locales) do
    local lower = locale:lower()
    if lang.setLocale(lower) then
      settings.client.locale = lower
      logger.info("Found locale match from perferred locales:", lower)
      localFound = true
      break
    end
  end
  if not localFound then
    local loadedLocales = lang.getLocales()
    for _, locale in ipairs(locales) do
      locale = locale:lower()
      if #locale > 2 then
        local sublocale = locale:sub(1,2)
        for _, loadedKey in ipairs(loadedLocales) do
          if sublocale == loadedKey or (#loadedKey > 2 and loadedKey:sub(1,2) == sublocale) then
            logger.info("Managed to find partial language locale match:", loadedKey, ", from", locale)
            settings.client.locale = loadedKey
            localFound = lang.setLocale(loadedKey)
            if localFound then
              goto continue
            end
          end
        end
      end
    end
    ::continue::
  end
end
if not localFound then
  lang.setLocale("en")
end

local processEvents = function()
  le.pump()
  for name, a, b, c, d, e, f in le.poll() do
    if name == "quit" then
      if not love.quit or not love.quit() then
        return a or 0
      end
    end
    love.handlers[name](a, b, c, d, e, f)
  end
end

local min, max = math.min, math.max
local clamp = function(target, minimum, maximum)
  return min(max(target, minimum), maximum)
end

-- https://gist.github.com/1bardesign/3ed0fabfdcd2661d3308b4da7fa3076d
local manualGC = function(timeBudget, safetyNetMB)
  local limit, steps = 1000, 0
  local start = ltr.getTime()
  while ltr.getTime() - start < timeBudget and steps < limit do
    collectgarbage("step", 1)
    steps = steps + 1
  end
  if collectgarbage("count") / 1024 > safetyNetMB then
    collectgarbage("collect")
  end
end

love.run = function()
  if love.isServer then
    logger.info("Starting server code")
    sceneManager.changeScene("loadServer")
    logger.info("Creating server gameloop")
    return function()
      local quit = processEvents()
      if quit then
        return quit
      end
        love.update()
        manualGC(1e-3, 128)
      ltr.sleep(1e-5)
    end
  else -- Client
    local _, _, flags = lw.getMode()
    local desktopWidth, desktopHeight = lw.getDesktopDimensions(flags.display)
    if lg.getWidth() >= desktopWidth * 0.95 and lg.getHeight() >= desktopHeight * 0.95 then
      lw.maximize()
    end

    love.keyboard.setKeyRepeat(true)

    local input = require("util.input")

    logger.info("Starting client code")
    sceneManager.changeScene("loadClient")
    logger.info("Creating client gameloop")
    local frameTime, fuzzyTime = 1/60, {1/2,1,2}
    local networkTick = 1/20
    local updateDelta, networkDelta = 0, 0
    ltr.step()
    return function()
      local quit = processEvents()
      if quit then
        return quit
      end

      local dt = ltr.step()
      -- fuzzy timing snapping
      for _, v in ipairs(fuzzyTime) do
        v = frameTime * v
        if math.abs(dt - v) < 0.002 then
          dt = v
        end
      end
      -- dt clamping
      dt = clamp(dt, 0, 2*frameTime)
      updateDelta = updateDelta + dt
      networkDelta = networkDelta + dt
      -- frametimer clamping
      updateDelta = clamp(updateDelta, 0, 8*frameTime)
      
      local ticked = false
      while updateDelta > frameTime do
          updateDelta = updateDelta - frameTime
          input:update()
          flux.update(frameTime)
          love.update(frameTime)
        ticked = true
      end

      if networkDelta > networkTick then
          networkDelta = 0
          love.updatenetwork()
      end

      if ticked then
          love.drawui()
          love.draw()
          lg.present()
      end

      -- clean up
      manualGC(1e-3, 128)
      ltr.sleep(1e-3)
    end
  end
end