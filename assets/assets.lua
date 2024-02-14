local pixelArt = function(image)
  image:setFilter("nearest", "nearest")
end

return {
-- UI
  { path = "UI/logo.png", name = "ui.logo", onLoad = pixelArt },
-- Images

-- Audio

-- Fonts
  { path = "fonts/FutilePro.ttf", name = "fonts.futile" },
}