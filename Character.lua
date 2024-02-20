local character = {}
character.__index = character

character.new = function(self, line, x, y, r, w, h, CollisionW, CollisionH, speed)
	local self = {}

	self.line = 'line' -- the line of the collision rectangle

	--Variables of Player Image
	self.x = x
	self.y = y
	self.w = w
	self.h = h

	self.r = r -- rotation of the player Image

	self.inventory_selected_slot = 0
	self.inventory = {}

	self.arms = {}
	self.legs = {}

	self.attachable = false -- Can be attached to the body. You cannot attach a player to yourself. How horrible would that be?

	--Variables of Collision hitbox / they have different Sizes the collision hitbox and the player hitbox because we might need to scale the character image without interfering with the character hitbox
	self.CollisionW = CollisionW
	self.CollisionH = CollisionH

	self.speed = speed -- Controls Character speed

	-- self.Mainimage = love.graphics.newImage(Mainimage) -- MainImage of Character being idle / wont add to the parameters for the time being since no images.
	self.color = color -- might be useful for later wont add to parameters for the time being.

	return setmetatable(self, character)
end

character.update = function(self, dt)
	self:move(dt)
end

character.move = function(self, dt)
	-- Can't move if you're being held
	if self.held then
		return
	end

	if love.keyboard.isDown('d') then
		self.x = self.x + self.speed * dt
	end
	if love.keyboard.isDown('a') then
		self.x = self.x - self.speed * dt
	end
	if love.keyboard.isDown('w') then
		self.y = self.y - self.speed * dt
	end
	if love.keyboard.isDown('s') then
		self.y = self.y + self.speed * dt
	end
end

character.draw = function(self)
	--I didnt add the love.graphics.draw yet since we have no images for the time being
	love.graphics.rectangle(self.line,self.x,self.y,self.CollisionW,self.CollisionH)
end

character.getInventoryLoad = function(self)
	local inventory_load = 0

	for i, item in ipairs(self.inventory) do
		inventory_load = inventory_load + item.weight
	end

	return inventory_load
end

character.getStrength = function(self)
	return #self.arms - self:getInventoryLoad()
end

character.getWeight = function(self)
	return 1 + #self.arms + #self.legs + self:getInventoryLoad()
end

character.pick = function(self, item)
	-- Cannot hold a held item, no stealing >:(
	if item.held then
		return
	end

	-- No free arm to hold it
	if #self.arms == #self.inventory then
		return
	end
	
	local strength = self:getStrength()

	-- Not enough strength
	if strength < item:getWeight() then
		return
	end

	table.insert(self.inventory, item)
	item.held = true
end

character.attach = function(self, inventory_slot)
	local limb = self.inventory[inventory_slot]

	if not limb.attachable then
		return
	end

	table.remove(self.inventory, inventory_slot)

	if limb.type == "arm" then
		table.insert(self.arms, limb)
	else
		table.insert(self.legs, limb)
	end
end

character.throw = function(self, inventory_slot)
	local item = self.inventory[inventory_slot]
	table.remove(self.inventory, inventory_slot)

	item.held = false
end

return character