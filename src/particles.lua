local particles = { wind = nil, water = nil }

function particles.create()
	-- Create particle texture
	local imgData = love.image.newImageData(2, 2)
	for x = 0, 1 do
		for y = 0, 1 do
			imgData:setPixel(x, y, 1, 1, 1, 1)
		end
	end
	local img = love.graphics.newImage(imgData)

	-- Wind particles
	particles.wind = love.graphics.newParticleSystem(img, 100)
	particles.wind:setParticleLifetime(2, 4)
	particles.wind:setEmissionRate(20)
	particles.wind:setLinearAcceleration(0, 20, 0, 40) -- Downward
	particles.wind:setColors(1, 1, 1, 0.3, 1, 1, 1, 0)
	particles.wind:setSpeed(30, 60)
	particles.wind:setSpread(0.2)
	particles.wind:setDirection(3 * math.pi / 2) -- Downward

	-- Water particles
	particles.water = love.graphics.newParticleSystem(img, 150)
	particles.water:setParticleLifetime(1, 2)
	particles.water:setEmissionRate(50)
	particles.water:setColors(0.3, 0.5, 0.8, 0.4, 0.3, 0.5, 0.8, 0)
	particles.water:setSpeed(10, 30)
	particles.water:setSpread(math.pi * 2)
end

function particles.update(dt)
	particles.wind:update(dt)
	particles.water:update(dt)
end

function particles.draw()
	love.graphics.draw(particles.water)
	love.graphics.draw(particles.wind)
end

function particles.setWindPosition(x, y)
	particles.wind:setPosition(x, y - 30)
end

function particles.setWaterPosition(x, y)
	particles.water:setPosition(x, y + 10)
end

return particles
