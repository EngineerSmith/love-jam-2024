local args = require("util.args")
local logger = require("util.logger")
local loader = require("util.lilyloader")
local ui = require("util.ui")
local args = require("util.args")
  
local flux = require("libs.flux")

local lg = love.graphics
local floor, rad = math.floor, math.rad

local logo = lg.newImage("assets/UI/logo.png")
logo:setFilter("nearest")

local assets = require("util.assets")

local bgColor = { .1, .1, .1, 1 }

local scene = {
  logo = {
    x = 0, y = 0, r = 0
  },
}
scene.load = function() end

local splash
if not args["--speed"] then
  love.window.maximize()
  splash = require("libs.splash").new({background = bgColor})
  splash.onDone = function()
    splash.finished = true
  end
else
  splash = {
    finished = true
  }
end

scene.lily = loader()
logger.info("Loading", scene.lily:getCount(), "assets")

lg.setFont(ui.getFont(18, "fonts.futile", 1))

local percentage = 0
local logoFadeTimer = 0
local nextScenetimer = 0
if args["--speed"] then
  logoFadeTimer = 1
  nextScenetimer = 60
end

scene.update = function(dt)
  if not splash.finished then
    splash:update(dt)
  else
    percentage = scene.lily:getLoadedCount() / scene.lily:getCount()
    if scene.lily:isComplete() then
      logoFadeTimer = logoFadeTimer + dt
      nextScenetimer = nextScenetimer + dt
      if nextScenetimer >= 2 then
        logger.info("Finished loading, moving to menu")
        if args["--speed"] then
          love.window.focus()
        else
          love.window.requestAttention(true)
        end
        require("util.sceneManager").changeScene("scenes.menu")
      end
    end
  end
end

local w, h = lg.getDimensions()
w, h = floor(w/2), floor(h/2)

scene.resize = function(w_, h_)
  w, h = floor(w_/2), floor(h_/2)  
end

local barW, barH = 400, 20
local lineWidth = 2
local lineWidth2, lineWidth4 = lineWidth*2, lineWidth*4
local scale = 12

scene.draw = function()
  lg.clear(bgColor)
  if not splash.finished then
    lg.push("all")
      splash:draw()
    lg.pop()
  else
    lg.push()
      lg.translate(w, h)
      lg.push("all")
        lg.setColor(1,1,1, logoFadeTimer)
        lg.draw(logo, scene.logo.x,scene.logo.y, scene.logo.r, scale,scale, logo:getWidth()/2, logo:getHeight()/2)

        lg.translate(0, logo:getHeight()*(scale))
        lg.translate(-floor(barW/2), -floor(barH/2))
        lg.setStencilMode("draw", 1)
        lg.rectangle("fill", lineWidth, lineWidth, barW-lineWidth2, barH-lineWidth2)
        lg.setStencilMode("test", 0)
        lg.setColor(.9,.9,.9, logoFadeTimer)
        lg.rectangle("fill", 0,0, barW, barH)
        lg.setStencilMode("off")
        lg.rectangle("fill", lineWidth2, lineWidth2, (barW-lineWidth4)*percentage, barH-lineWidth4)
      lg.pop()
      local str = scene.lily:getLoadedCount().." / "..scene.lily:getCount()
      lg.print(str, -lg.getFont():getWidth(str)/2, lg.getFont():getHeight()+logo:getHeight()*scale/1.5)
    lg.pop()
  end
end

return scene