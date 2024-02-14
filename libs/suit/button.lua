-- This file is part of SUIT, copyright (c) 2016 Matthias Richter

local BASE = (...):match('(.-)[^%.]+$')

return function(core, text, ...)
	local opt, x,y,w,h = core.getOptionsAndSize(...)

	w = w or opt.font and opt.font:getWidth(text) + 10 or love.graphics.getFont():getWidth(text) + 10
	h = h or opt.font and opt.font:getHeight() + 10 or love.graphics.getFont():getHeight() + 10
	
  if not opt.noScaleX then
    x, w = x * core.scale, w * core.scale
  end
  if not opt.noScaleY then
    y, h  = y * core.scale, h * core.scale
  end

	if not opt.x then
		opt.x, opt.y, opt.w, opt.h = 0, 0, 0, 0
	end

	opt.id = opt.id or text


	opt.state = core:registerHitbox(opt.id, x,y,w,h)

	local hit = core:mouseReleasedOn(opt.id)
	local hovered = not opt.disable and core:isHovered(opt.id)
	local entered = not opt.disable and core:isHovered(opt.id) and not core:wasHovered(opt.id)
	local left = not opt.disable and not core:isHovered(opt.id) and core:wasHovered(opt.id)

	opt.hit, opt.hovered, opt.entered, opt.left = hit, hovered, entered, left

	opt.rect = { x, y, w, h}
	core:registerDraw(opt.draw or core.theme.Button, text, opt, x,y,w,h)

	return {
		id = opt.id,
		hit = hit,
		hovered = hovered,
		entered = entered,
		left = left,
		disabled_hovered = opt.disable and core:isHovered(opt.id),
		x = x, y = y,
		w = w, h = h,
	}
end
