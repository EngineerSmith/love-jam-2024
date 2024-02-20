local item = {}

item.__index = item

item.new = function()
	local self = {}

	self.line = 'line' -- the line of the collision rectangle

	self.x = 0
	self.y = 0
	self.w = 0
	self.h = 0

	self.r = 0

	self.hitbox_w = 0
	self.hitbox_h = 0

    self.attachable = false -- Can be attached to the main body or not

	--self.sprite =

	return setmetatable(self, item)
end

item.getWeight = function(self)
    return 1
end

return item