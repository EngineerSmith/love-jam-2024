local PATH = (...):gsub('%.[^%.]+$', '')
local FILEPATH = PATH:gsub('%.', '/')

local lt = love.thread

local options = require(PATH .. ".options")

local search = {
  -- private
  _thread = lt.newThread(FILEPATH .. "/searchThread.lua")
}
-- start/stop searching
  -- ownership of search thread

-- search thread handlers
  -- log error messages
  -- dispatch callbacks

  return search