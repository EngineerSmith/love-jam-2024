local pixelArt = function(image)
  image:setFilter("nearest", "nearest")
end

return {
-- UI
  { path = "UI/logo.png", name = "ui.logo", onLoad = pixelArt },
-- Images
  { path = "tiles/pressure_plate.png", name = "tile.pressure_plate", onLoad = pixelArt },
-- Audio

-- Fonts
  { path = "fonts/FutilePro.ttf", name = "fonts.futile" },
}