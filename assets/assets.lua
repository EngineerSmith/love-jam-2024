local pixelArt = function(image)
  image:setFilter("nearest", "nearest")
end

return {
-- UI
  { path = "UI/logo.png", name = "ui.logo", onLoad = pixelArt },
-- Images
  { path = "tiles/walls.png", name = "tile.walls", onLoad = pixelArt },
  { path = "tiles/walls_small.png", name = "tile.walls.small", onLoad = pixelArt },
-- Audio

-- Fonts
  { path = "fonts/FutilePro.ttf", name = "fonts.futile" },
}