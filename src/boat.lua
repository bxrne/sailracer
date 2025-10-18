local config = require("config")

local boat = {
	x = config.SCREEN.w / 2,
	y = config.SCREEN.h - 150,
	angle = 0,
	speed = 60,
	maxSpeed = config.BOAT.maxSpeed,
	size = config.BOAT.size,
	turnSpeed = config.BOAT.turnSpeed,
	sailAngle = 0,
	centreboardDeployed = true,
	centreboardFactor = 50,
}

function boat.update(dt, wind)
	-- Steering
	if love.keyboard.isDown("left") then
		boat.angle = boat.angle - boat.turnSpeed * dt
	end
	if love.keyboard.isDown("right") then
		boat.angle = boat.angle + boat.turnSpeed * dt
	end

	if love.keyboard.isDown("up") then
		boat.sailAngle = math.max(boat.sailAngle - boat.turnSpeed * dt, -math.pi / 2)
	end
	if love.keyboard.isDown("down") then
		boat.sailAngle = math.min(boat.sailAngle + boat.turnSpeed * dt, math.pi / 2)
	end

	-- Calculate speed based on wind angle (adjusted for sail trim)
	local angleToWind = boat.normalizeAngle(wind.angle - boat.angle + boat.sailAngle)
	local speedFactor = boat.getSpeedFactor(angleToWind)
	local targetSpeed = boat.maxSpeed * speedFactor

	-- Smooth speed changes
	local accel = boat.speed < targetSpeed and 80 or -60
	boat.speed = math.max(0, math.min(boat.speed + accel * dt, targetSpeed))

	-- Calculate leeway for lateral resistance
	local relativeWind = boat.normalizeAngle(wind.angle - boat.angle)
	local lateralForce = math.sin(relativeWind) * wind.speed
	local leeway = lateralForce / (boat.speed + 1) / (boat.centreboardDeployed and boat.centreboardFactor or 1)
	local moveAngle = boat.angle - leeway

	-- Move boat with leeway
	boat.x = boat.x + math.cos(moveAngle) * boat.speed * dt
	boat.y = boat.y + math.sin(moveAngle) * boat.speed * dt

	-- Screen boundaries
	boat.x = math.max(20, math.min(config.SCREEN.w - 20, boat.x))
	boat.y = math.max(20, math.min(config.SCREEN.h - 20, boat.y))
end

function boat.getSpeedFactor(angleToWind)
	local deg = math.deg(angleToWind)
	if deg < 45 then
		return 0.1 -- In irons
	elseif deg < 90 then
		return 0.6 + (deg - 45) / 45 * 0.3 -- Close hauled
	elseif deg < 135 then
		return 0.9 + (1 - math.abs(deg - 90) / 45) * 0.1 -- Beam reach (fastest)
	elseif deg < 160 then
		return 0.8 - (deg - 135) / 25 * 0.2 -- Broad reach
	else
		return 0.5 -- Running
	end
end

function boat.normalizeAngle(angle)
	while angle > math.pi do
		angle = angle - 2 * math.pi
	end
	while angle < -math.pi do
		angle = angle + 2 * math.pi
	end
	return angle
end

function boat.draw()
	love.graphics.push()
	love.graphics.translate(boat.x, boat.y)
	love.graphics.rotate(boat.angle)

	-- Hull (centered at (0,0))
	local hullPoints = {
		0,
		-boat.size * 4 / 3, -- Bow
		-boat.size / 2,
		boat.size * 2 / 3, -- Port stern
		boat.size / 2,
		boat.size * 2 / 3, -- Starboard stern
	}
	love.graphics.setColor(0.2, 0.6, 1)
	love.graphics.polygon("fill", hullPoints)
	love.graphics.setColor(0, 0, 0)
	love.graphics.polygon("line", hullPoints)

	-- Mast and Sail (centered, rotated by sailAngle)
	love.graphics.push()
	love.graphics.rotate(boat.sailAngle)
	love.graphics.setColor(1, 1, 1)
	love.graphics.setLineWidth(3)
	love.graphics.line(0, -boat.size * 0.5, 0, boat.size * 0.8) -- Sail along mast
	love.graphics.pop()

	-- Tiller at stern
	love.graphics.setColor(0.6, 0.4, 0.2)
	love.graphics.setLineWidth(2)
	love.graphics.line(-boat.size / 4, boat.size * 2 / 3, boat.size / 4, boat.size * 2 / 3)

	love.graphics.setLineWidth(1)
	love.graphics.pop()
end

return boat
