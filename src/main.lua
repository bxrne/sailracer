function love.load()
	-- Screen setup
	SCREEN_WIDTH = 1200
	SCREEN_HEIGHT = 800
	love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)
	love.window.setTitle("sailracer")

	-- Camera/viewport
	camera = {
		x = 0,
		y = 0,
		scale = 1.0,
	}

	-- World dimensions (much larger than screen)
	WORLD_WIDTH = 3000
	WORLD_HEIGHT = 2000

	-- Game state
	gameState = "menu" -- menu, countdown, racing, penalty, finished
	countdownTimer = 0
	countdownPhase = 5 -- 5, 4, 3, 2, 1, GO

	-- Boat properties
	boat = {
		x = 500,
		y = WORLD_HEIGHT / 2,
		angle = 0,
		velocity = { x = 0, y = 0 },
		speed = 0,
		rudderAngle = 0,
		sailTrim = 0.5, -- 0 = tight (upwind), 1 = loose (downwind)
		maxSpeed = 200,
		length = 30,
		width = 12,
		inPenalty = false,
		penaltyRotation = 0,
	}

	-- Wind system
	wind = {
		angle = math.rad(90), -- Wind from right
		strength = 80,
		gusts = {},
	}

	-- Current system
	current = {
		angle = math.rad(45),
		strength = 20,
	}

	-- Particle systems for wind and water
	windParticles = {}
	waterParticles = {}
	wakeParticles = {}

	-- Start line
	startLine = {
		x1 = 400,
		y1 = WORLD_HEIGHT / 2 - 150,
		x2 = 400,
		y2 = WORLD_HEIGHT / 2 + 150,
		crossed = false,
	}

	-- Race marks
	marks = {
		{ x = 1200, y = 600, reached = false, order = 1, radius = 30 },
		{ x = 2000, y = 400, reached = false, order = 2, radius = 30 },
		{ x = 2200, y = 1200, reached = false, order = 3, radius = 30 },
		{ x = 1400, y = 1400, reached = false, order = 4, radius = 30 },
	}
	currentMark = 1

	-- Finish line
	finishLine = {
		x1 = 300,
		y1 = WORLD_HEIGHT / 2 - 150,
		x2 = 300,
		y2 = WORLD_HEIGHT / 2 + 150,
	}

	-- Timer
	raceTime = 0
	bestTime = nil

	-- Initialize particle systems
	initializeParticles()
end

function initializeParticles()
	-- Create wind particles throughout the world
	for i = 1, 200 do
		table.insert(windParticles, {
			x = math.random(0, WORLD_WIDTH),
			y = math.random(0, WORLD_HEIGHT),
			speed = math.random(30, 60),
			size = math.random(1, 3),
		})
	end

	-- Create water current particles
	for i = 1, 150 do
		table.insert(waterParticles, {
			x = math.random(0, WORLD_WIDTH),
			y = math.random(0, WORLD_HEIGHT),
			speed = math.random(10, 25),
			size = math.random(2, 4),
			life = math.random(),
		})
	end
end

function love.update(dt)
	if gameState == "countdown" then
		updateCountdown(dt)
	elseif gameState == "racing" or gameState == "penalty" then
		updateRace(dt)
	end

	-- Always update particles
	updateParticles(dt)

	-- Update camera to follow boat
	updateCamera()
end

function updateCountdown(dt)
	countdownTimer = countdownTimer + dt

	if countdownTimer >= 1.0 then
		countdownTimer = 0
		countdownPhase = countdownPhase - 1

		if countdownPhase < 0 then
			gameState = "racing"
			startLine.crossed = false
		end
	end
end

function updateRace(dt)
	raceTime = raceTime + dt

	if gameState == "penalty" then
		-- Force 360 degree turn
		boat.penaltyRotation = boat.penaltyRotation + 2 * dt
		boat.angle = boat.angle + 2 * dt

		if boat.penaltyRotation >= 2 * math.pi then
			gameState = "racing"
			boat.penaltyRotation = 0
			boat.inPenalty = false
		end
		return
	end

	-- Rudder control (left/right arrows)
	if love.keyboard.isDown("left") then
		boat.rudderAngle = math.max(boat.rudderAngle - 2 * dt, -0.5)
	elseif love.keyboard.isDown("right") then
		boat.rudderAngle = math.min(boat.rudderAngle + 2 * dt, 0.5)
	else
		-- Center rudder gradually
		boat.rudderAngle = boat.rudderAngle * 0.95
	end

	-- Sail trim control (up/down arrows)
	if love.keyboard.isDown("up") then
		boat.sailTrim = math.max(boat.sailTrim - 0.5 * dt, 0)
	elseif love.keyboard.isDown("down") then
		boat.sailTrim = math.min(boat.sailTrim + 0.5 * dt, 1)
	end

	-- Calculate sailing physics
	updateBoatPhysics(dt)

	-- Apply current
	boat.x = boat.x + math.cos(current.angle) * current.strength * dt
	boat.y = boat.y + math.sin(current.angle) * current.strength * dt

	-- Keep in world bounds
	boat.x = math.max(50, math.min(boat.x, WORLD_WIDTH - 50))
	boat.y = math.max(50, math.min(boat.y, WORLD_HEIGHT - 50))

	-- Create wake
	if boat.speed > 30 then
		for i = 1, 2 do
			local offsetAngle = boat.angle + (i == 1 and -0.3 or 0.3)
			table.insert(wakeParticles, {
				x = boat.x - math.cos(boat.angle) * 15 + math.cos(offsetAngle) * 8,
				y = boat.y - math.sin(boat.angle) * 15 + math.sin(offsetAngle) * 8,
				life = 1.5,
				size = 4,
			})
		end
	end

	-- Update wake particles
	for i = #wakeParticles, 1, -1 do
		wakeParticles[i].life = wakeParticles[i].life - dt
		if wakeParticles[i].life <= 0 then
			table.remove(wakeParticles, i)
		end
	end

	-- Check start line crossing
	if not startLine.crossed and countdownPhase < 0 then
		if checkLineCross(startLine.x1, startLine.y1, startLine.x2, startLine.y2) then
			startLine.crossed = true
		end
	end

	-- Check mark collisions
	if currentMark <= #marks then
		local mark = marks[currentMark]
		local dist = distance(boat.x, boat.y, mark.x, mark.y)

		-- Hit mark - penalty!
		if dist < mark.radius + boat.width / 2 and not boat.inPenalty then
			gameState = "penalty"
			boat.inPenalty = true
			boat.penaltyRotation = 0
		end

		-- Rounded mark properly
		if dist < mark.radius + 40 and dist > mark.radius + boat.width then
			mark.reached = true
			currentMark = currentMark + 1
		end
	end

	-- Check finish line
	if currentMark > #marks and startLine.crossed then
		if checkLineCross(finishLine.x1, finishLine.y1, finishLine.x2, finishLine.y2) then
			gameState = "finished"
			if bestTime == nil or raceTime < bestTime then
				bestTime = raceTime
			end
		end
	end
end

function updateBoatPhysics(dt)
	-- Turn based on rudder
	boat.angle = boat.angle + boat.rudderAngle * (boat.speed / 100) * dt

	-- Calculate apparent wind angle
	local windAngle = wind.angle
	local apparentWindAngle = normalizeAngle(windAngle - boat.angle)
	local apparentWindDeg = math.deg(apparentWindAngle)

	-- Calculate optimal sail angle for this point of sail
	local optimalTrim = calculateOptimalTrim(apparentWindDeg)

	-- Calculate efficiency based on sail trim
	local trimError = math.abs(boat.sailTrim - optimalTrim)
	local efficiency = math.max(0, 1 - trimError * 2)

	-- Calculate speed based on point of sail
	local targetSpeed = calculateBoatSpeed(apparentWindDeg) * efficiency * wind.strength

	-- No go zone (within 45 degrees of wind)
	if math.abs(apparentWindDeg) < 45 then
		targetSpeed = targetSpeed * 0.2 -- Very slow in no-go zone
	end

	-- Smooth acceleration
	boat.speed = boat.speed + (targetSpeed - boat.speed) * 2 * dt

	-- Update position
	boat.x = boat.x + math.cos(boat.angle) * boat.speed * dt
	boat.y = boat.y + math.sin(boat.angle) * boat.speed * dt
end

function calculateOptimalTrim(apparentWindDeg)
	local absAngle = math.abs(apparentWindDeg)

	if absAngle < 45 then
		return 0.1 -- Very tight
	elseif absAngle < 90 then
		return 0.3 -- Close hauled
	elseif absAngle < 135 then
		return 0.6 -- Beam reach
	else
		return 0.9 -- Broad reach / run
	end
end

function calculateBoatSpeed(apparentWindDeg)
	local absAngle = math.abs(apparentWindDeg)

	if absAngle < 45 then
		return 0.3 -- Upwind, slow
	elseif absAngle < 90 then
		return 1.0 -- Close hauled, good speed
	elseif absAngle < 135 then
		return 1.2 -- Beam reach, fastest
	else
		return 0.8 -- Downwind, moderate
	end
end

function updateParticles(dt)
	-- Update wind particles
	for _, p in ipairs(windParticles) do
		p.x = p.x + math.cos(wind.angle) * p.speed * dt
		p.y = p.y + math.sin(wind.angle) * p.speed * dt

		-- Wrap around world
		if p.x > WORLD_WIDTH then
			p.x = 0
		end
		if p.x < 0 then
			p.x = WORLD_WIDTH
		end
		if p.y > WORLD_HEIGHT then
			p.y = 0
		end
		if p.y < 0 then
			p.y = WORLD_HEIGHT
		end
	end

	-- Update water current particles
	for _, p in ipairs(waterParticles) do
		p.x = p.x + math.cos(current.angle) * p.speed * dt
		p.y = p.y + math.sin(current.angle) * p.speed * dt
		p.life = p.life + dt * 0.5
		if p.life > 1 then
			p.life = 0
		end

		-- Wrap around
		if p.x > WORLD_WIDTH then
			p.x = 0
		end
		if p.x < 0 then
			p.x = WORLD_WIDTH
		end
		if p.y > WORLD_HEIGHT then
			p.y = 0
		end
		if p.y < 0 then
			p.y = WORLD_HEIGHT
		end
	end
end

function updateCamera()
	-- Camera follows boat smoothly
	local targetX = boat.x - SCREEN_WIDTH / 2
	local targetY = boat.y - SCREEN_HEIGHT / 2

	camera.x = camera.x + (targetX - camera.x) * 0.1
	camera.y = camera.y + (targetY - camera.y) * 0.1

	-- Clamp camera to world bounds
	camera.x = math.max(0, math.min(camera.x, WORLD_WIDTH - SCREEN_WIDTH))
	camera.y = math.max(0, math.min(camera.y, WORLD_HEIGHT - SCREEN_HEIGHT))
end

function love.draw()
	if gameState == "menu" then
		drawMenu()
		return
	end

	-- Apply camera transform
	love.graphics.push()
	love.graphics.translate(-camera.x, -camera.y)

	-- Draw water background with gradient
	drawWater()

	-- Draw current particles
	love.graphics.setColor(0.3, 0.5, 0.7, 0.3)
	for _, p in ipairs(waterParticles) do
		local alpha = 0.3 * (1 - p.life)
		love.graphics.setColor(0.4, 0.6, 0.8, alpha)
		love.graphics.circle("fill", p.x, p.y, p.size)
	end

	-- Draw wind particles
	love.graphics.setColor(0.9, 0.9, 0.9, 0.4)
	for _, p in ipairs(windParticles) do
		love.graphics.line(p.x, p.y, p.x - math.cos(wind.angle) * 10, p.y - math.sin(wind.angle) * 10)
	end

	-- Draw start line
	drawLine(startLine.x1, startLine.y1, startLine.x2, startLine.y2, { 0, 1, 0 }, "START")

	-- Draw finish line
	drawLine(finishLine.x1, finishLine.y1, finishLine.x2, finishLine.y2, { 1, 0, 0 }, "FINISH")

	-- Draw marks
	for i, mark in ipairs(marks) do
		drawMark(mark, i == currentMark)
	end

	-- Draw wake
	for _, p in ipairs(wakeParticles) do
		local alpha = p.life / 1.5
		love.graphics.setColor(1, 1, 1, alpha * 0.6)
		love.graphics.circle("fill", p.x, p.y, p.size * alpha)
	end

	-- Draw boat
	drawBoat()

	love.graphics.pop()

	-- Draw HUD (not affected by camera)
	drawHUD()

	-- Draw countdown
	if gameState == "countdown" then
		drawCountdown()
	elseif gameState == "penalty" then
		drawPenalty()
	elseif gameState == "finished" then
		drawFinished()
	end
end

function drawWater()
	-- Gradient water effect
	for y = 0, WORLD_HEIGHT, 50 do
		local shade = 0.15 + 0.1 * (y / WORLD_HEIGHT)
		love.graphics.setColor(0.1, 0.2 + shade, 0.4 + shade)
		love.graphics.rectangle("fill", 0, y, WORLD_WIDTH, 50)
	end
end

function drawLine(x1, y1, x2, y2, color, label)
	love.graphics.setColor(color)
	love.graphics.setLineWidth(5)

	-- Draw line with flags
	love.graphics.line(x1, y1, x2, y2)

	-- Draw flags at ends
	for i, x, y in ipairs({ { x1, y1 }, { x2, y2 } }) do
		-- Flag pole
		love.graphics.setColor(0.6, 0.4, 0.2)
		love.graphics.rectangle("fill", x[1] - 2, x[2] - 40, 4, 40)

		-- Flag
		love.graphics.setColor(color)
		love.graphics.polygon("fill", x[1], x[2] - 40, x[1] + 20, x[2] - 30, x[1], x[2] - 20)
	end

	-- Label
	love.graphics.setColor(1, 1, 1)
	local midX, midY = (x1 + x2) / 2, (y1 + y2) / 2
	love.graphics.print(label, midX - 20, midY - 30)
end

function drawMark(mark, isNext)
	if mark.reached then
		love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
	elseif isNext then
		love.graphics.setColor(1, 1, 0)
	else
		love.graphics.setColor(1, 0.5, 0)
	end

	-- Buoy
	love.graphics.circle("fill", mark.x, mark.y, mark.radius)

	-- Stripes
	love.graphics.setColor(1, 1, 1)
	love.graphics.circle("line", mark.x, mark.y, mark.radius)
	love.graphics.circle("line", mark.x, mark.y, mark.radius * 0.7)

	-- Number
	love.graphics.setColor(0, 0, 0)
	love.graphics.print(tostring(mark.order), mark.x - 5, mark.y - 8)
end

function drawBoat()
	love.graphics.push()
	love.graphics.translate(boat.x, boat.y)
	love.graphics.rotate(boat.angle)

	-- Hull
	love.graphics.setColor(0.9, 0.9, 0.95)
	love.graphics.polygon(
		"fill",
		-boat.length / 2,
		-boat.width / 2,
		boat.length / 2,
		0,
		-boat.length / 2,
		boat.width / 2
	)

	-- Hull outline
	love.graphics.setColor(0.3, 0.3, 0.4)
	love.graphics.setLineWidth(2)
	love.graphics.polygon(
		"line",
		-boat.length / 2,
		-boat.width / 2,
		boat.length / 2,
		0,
		-boat.length / 2,
		boat.width / 2
	)

	-- Mast
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.setLineWidth(3)
	love.graphics.line(0, 0, 0, -50)

	-- Main sail (line from mast showing sail angle)
	local sailAngle = (boat.sailTrim - 0.5) * math.pi * 0.6
	local sailLength = 40
	love.graphics.setColor(1, 1, 1)
	love.graphics.setLineWidth(4)
	love.graphics.line(0, -45, math.sin(sailAngle) * sailLength, -45 + math.cos(sailAngle) * sailLength)

	-- Jib (smaller forward sail)
	local jibLength = 25
	love.graphics.line(10, -30, 10 + math.sin(sailAngle * 0.8) * jibLength, -30 + math.cos(sailAngle * 0.8) * jibLength)

	-- Rudder indicator
	love.graphics.setColor(0.5, 0.3, 0.2)
	love.graphics.push()
	love.graphics.translate(-boat.length / 2 + 5, 0)
	love.graphics.rotate(boat.rudderAngle)
	love.graphics.rectangle("fill", -2, -8, 4, 16)
	love.graphics.pop()

	love.graphics.pop()
end

function drawHUD()
	local padding = 10

	-- Semi-transparent background
	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle("fill", padding, padding, 300, 180)

	love.graphics.setColor(1, 1, 1)
	local y = padding + 10
	love.graphics.print(string.format("Time: %.1f s", raceTime), padding + 10, y)
	y = y + 25
	love.graphics.print(string.format("Speed: %.0f kts", boat.speed / 10), padding + 10, y)
	y = y + 25
	love.graphics.print(string.format("Mark: %d / %d", currentMark, #marks), padding + 10, y)
	y = y + 25

	-- Sail trim indicator
	love.graphics.print("Sail Trim:", padding + 10, y)
	love.graphics.rectangle("line", padding + 100, y, 100, 15)
	love.graphics.setColor(0, 1, 0)
	love.graphics.rectangle("fill", padding + 100, y, boat.sailTrim * 100, 15)
	love.graphics.setColor(1, 1, 1)
	y = y + 25

	-- Rudder indicator
	love.graphics.print("Rudder:", padding + 10, y)
	love.graphics.rectangle("line", padding + 100, y, 100, 15)
	love.graphics.setColor(1, 0.5, 0)
	local rudderPos = (boat.rudderAngle + 0.5) * 100
	love.graphics.rectangle("fill", padding + 100 + rudderPos - 2, y, 4, 15)
	love.graphics.setColor(1, 1, 1)
	y = y + 25

	-- Wind direction indicator
	love.graphics.print("Wind →", padding + 10, y)
	love.graphics.push()
	love.graphics.translate(padding + 250, y + 10)
	love.graphics.rotate(wind.angle - boat.angle)
	love.graphics.line(-15, 0, 15, 0)
	love.graphics.polygon("fill", 15, 0, 10, -4, 10, 4)
	love.graphics.pop()
end

function drawMenu()
	love.graphics.clear(0.2, 0.4, 0.6)
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf("SAILING RACE SIMULATOR", 0, 150, SCREEN_WIDTH, "center")
	love.graphics.printf("Navigate around all marks in order", 0, 220, SCREEN_WIDTH, "center")
	love.graphics.printf("Controls:", 0, 280, SCREEN_WIDTH, "center")
	love.graphics.printf("← → : Steer rudder", 0, 310, SCREEN_WIDTH, "center")
	love.graphics.printf("↑ ↓ : Adjust sail trim", 0, 340, SCREEN_WIDTH, "center")
	love.graphics.printf("Hit a mark? 360° penalty!", 0, 390, SCREEN_WIDTH, "center")
	love.graphics.printf("Press SPACE to start", 0, 450, SCREEN_WIDTH, "center")

	if bestTime then
		love.graphics.setColor(1, 1, 0)
		love.graphics.printf(string.format("Best Time: %.1f s", bestTime), 0, 520, SCREEN_WIDTH, "center")
	end
end

function drawCountdown()
	love.graphics.setColor(0, 0, 0, 0.5)
	love.graphics.rectangle("fill", SCREEN_WIDTH / 2 - 150, SCREEN_HEIGHT / 2 - 100, 300, 200)

	love.graphics.setColor(1, 1, 1)
	local text = countdownPhase > 0 and tostring(countdownPhase) or "GO!"
	local fontSize = countdownPhase == 0 and 80 or 120
	love.graphics.setNewFont(fontSize)
	love.graphics.printf(text, 0, SCREEN_HEIGHT / 2 - 40, SCREEN_WIDTH, "center")
	love.graphics.setNewFont(14)
end

function drawPenalty()
	love.graphics.setColor(1, 0, 0, 0.7)
	love.graphics.rectangle("fill", SCREEN_WIDTH / 2 - 150, 50, 300, 80)
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf("PENALTY - 360° TURN!", 0, 70, SCREEN_WIDTH, "center")
	local remaining = math.ceil((2 * math.pi - boat.penaltyRotation) / math.pi * 180)
	love.graphics.printf(string.format("%d° remaining", remaining), 0, 95, SCREEN_WIDTH, "center")
end

function drawFinished()
	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", SCREEN_WIDTH / 2 - 200, SCREEN_HEIGHT / 2 - 150, 400, 300)

	love.graphics.setColor(1, 1, 1)
	love.graphics.printf("RACE COMPLETE!", 0, SCREEN_HEIGHT / 2 - 100, SCREEN_WIDTH, "center")
	love.graphics.printf(
		string.format("Time: %.1f seconds", raceTime),
		0,
		SCREEN_HEIGHT / 2 - 50,
		SCREEN_WIDTH,
		"center"
	)

	if bestTime == raceTime then
		love.graphics.setColor(1, 1, 0)
		love.graphics.printf("NEW BEST TIME!", 0, SCREEN_HEIGHT / 2, SCREEN_WIDTH, "center")
	end

	love.graphics.setColor(1, 1, 1)
	love.graphics.printf("Press SPACE to race again", 0, SCREEN_HEIGHT / 2 + 70, SCREEN_WIDTH, "center")
	love.graphics.printf("Press ESC for menu", 0, SCREEN_HEIGHT / 2 + 100, SCREEN_WIDTH, "center")
end

function normalizeAngle(angle)
	while angle > math.pi do
		angle = angle - 2 * math.pi
	end
	while angle < -math.pi do
		angle = angle + 2 * math.pi
	end
	return angle
end

function distance(x1, y1, x2, y2)
	return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function checkLineCross(x1, y1, x2, y2)
	-- Check if boat crosses the line (simplified)
	local boatDist = distanceToLine(boat.x, boat.y, x1, y1, x2, y2)
	return boatDist < 20 and boat.x > math.min(x1, x2) - 50 and boat.x < math.max(x1, x2) + 50
end

function distanceToLine(px, py, x1, y1, x2, y2)
	local A = px - x1
	local B = py - y1
	local C = x2 - x1
	local D = y2 - y1

	local dot = A * C + B * D
	local lenSq = C * C + D * D
	local param = dot / lenSq

	local xx, yy

	if param < 0 or (x1 == x2 and y1 == y2) then
		xx = x1
		yy = y1
	elseif param > 1 then
		xx = x2
		yy = y2
	else
		xx = x1 + param * C
		yy = y1 + param * D
	end

	return distance(px, py, xx, yy)
end

function love.keypressed(key)
	if key == "space" then
		if gameState == "menu" then
			startRace()
		elseif gameState == "finished" then
			startRace()
		end
	elseif key == "escape" then
		if gameState == "finished" or gameState == "racing" or gameState == "penalty" then
			gameState = "menu"
		else
			love.event.quit()
		end
	end
end

function startRace()
	gameState = "countdown"
	countdownPhase = 5
	countdownTimer = 0
	boat.x = 500
	boat.y = WORLD_HEIGHT / 2
	boat.angle = 0
	boat.velocity = { x = 0, y = 0 }
	boat.speed = 0
	boat.rudderAngle = 0
	boat.sailTrim = 0.5
	boat.inPenalty = false
	boat.penaltyRotation = 0
	currentMark = 1
	raceTime = 0
	wakeParticles = {}
	startLine.crossed = false

	for _, mark in ipairs(marks) do
		mark.reached = false
	end

	-- Randomize wind slightly
	wind.angle = math.rad(math.random(60, 120))
end
