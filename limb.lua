local Item = require("item")

local limb = {}

limb.__index = limb

limb.new = function()
	local self = Item.new()

	self.line = 'line' -- the line of the collision rectangle

	self.x = 0
	self.y = 0
	self.w = 0
	self.h = 0

	self.r = 0

	self.hitbox_w = 0
	self.hitbox_h = 0

    self.attachable = true -- Can be attached to the main body

	--self.sprite =

	return setmetatable(self, limb)
end

limb.getWeight = function(self)
    return 0
end

return limb