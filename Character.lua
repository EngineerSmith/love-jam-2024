local character = {}
character.__index = character

character.new = function(self,line,x,y,r,w,h,CollisionW,CollisionH,speed)
	local self = {}

	self.line = 'line' -- the line of the collision rectangle

	--Variables of Player Image
	self.x = x
	self.y = y
	self.w = w
	self.h = h

	self.r = r -- rotation of the player Image

	--Variables of Collision hitbox / they have different Sizes the collision hitbox and the player hitbox because we might need to scale the character image without interfering with the character hitbox
	self.CollisionW = CollisionW
	self.CollisionH = CollisionH

	self.speed = speed -- Controls Character speed

	-- self.Mainimage = love.graphics.newImage(Mainimage) -- MainImage of Character being idle / wont add to the parameters for the time being since no images.
	self.color = color -- might be useful for later wont add to parameters for the time being.

	return setmetatable(self, character)
end

character.update = function(self,dt)
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


return character