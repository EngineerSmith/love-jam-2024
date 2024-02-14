local lily = require("libs.lily")
local file = require("util.file")

local insert = table.insert

local extensions = {
    png  = "newImage",
    jpg  = "newImage",
    jpeg = "newImage",
    bmp  = "newImage",
    mp3  = "newSource",
    ogg  = "newSource",
    wav  = "newSource",
    txt  = "read",
    ttf  = "newFont",
    otf  = "newFont",
    fnt  = "newFont",
  }

return function()
  local assets = require("assets.assets") or error("Unable to require assets file")
  local outAssets = require("util.assets")

  local lilyTable = { }
  for _, asset in ipairs(assets) do
    local ext = file.getFileExtension(asset.path)
    local fn = ext and extensions[ext:lower()] or error("Could not find load functions for "..tostring(ext).." extension from file "..tostring(asset.path))
    if fn == "newFont" then
      outAssets[asset.name] = "assets/"..asset.path
    else
      insert(lilyTable, {
          fn, "assets/"..asset.path,
          (fn == "newSource" and "static" or nil),
        })
    end
  end

  local multiLily = lily.loadMulti(lilyTable)
  multiLily:onComplete(function(_, lilies)
      for index, lilyAsset in ipairs(lilies) do
        local import = assets[index]
        outAssets[import.name] = lilyAsset[1]
        if import.onLoad then
          local a = import.onLoad(lilyAsset[1], unpack(import, 1))
          if a then
            outAssets[import.name] = a
            if type(a) == "table" then
              insert(outAssets.updateTable, a)
            end
          end
        end
      end
    end)
  return multiLily
end