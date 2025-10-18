local config = require("config")

local ui = {}

function ui.drawStartScreen(game, particles)
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf("SAILRACER", 0, 80, config.SCREEN.w, "center", 0, 2, 2)

	love.graphics.setColor(0.8, 0.9, 1)
	love.graphics.printf(game.quote, 50, 200, config.SCREEN.w - 100, "center")

	love.graphics.setColor(1, 1, 1)
	love.graphics.printf("RULES:", 50, 280, config.SCREEN.w - 100, "center")
	love.graphics.printf("• A 5-second countdown starts the race", 50, 310, config.SCREEN.w - 100, "center")
	love.graphics.printf("• Navigate: Windward → Leeward → Finish Line", 50, 335, config.SCREEN.w - 100, "center")
	love.graphics.printf("• Use LEFT/RIGHT arrows to steer", 50, 360, config.SCREEN.w - 100, "center")
	love.graphics.printf("• Use Q/E to trim sails for better speed", 50, 385, config.SCREEN.w - 100, "center")
	love.graphics.printf(
		"• Speed varies by wind angle (beam reach is fastest!)",
		50,
		410,
		config.SCREEN.w - 100,
		"center"
	)
	love.graphics.printf(
		"• Early start: +5s penalty | Hit mark: +2s penalty",
		50,
		435,
		config.SCREEN.w - 100,
		"center"
	)

	love.graphics.setColor(1, 1, 0)
	love.graphics.printf("Press SPACE to start!", 0, 480, config.SCREEN.w, "center", 0, 1.5, 1.5)

	particles.setWindPosition(config.SCREEN.w / 2, 0)
	particles.draw()
end

function ui.drawRacingScreen(boat, race, marks, wind, particles)
	-- Water particles
	particles.draw()

	-- Start/Finish line
	love.graphics.setColor(1, 1, 0, 0.6)
	love.graphics.setLineWidth(3)
	love.graphics.line(marks[1].x, marks[1].y, marks[2].x, marks[2].y)
	love.graphics.setLineWidth(1)

	-- Draw marks
	marks.draw()

	-- Draw boat
	boat.draw()

	-- Wind indicator
	wind.drawIndicator()

	-- HUD
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Speed: " .. string.format("%.1f", boat.speed), 10, 10)
	love.graphics.print("Time: " .. string.format("%.1f", race.time), 10, 30)
	love.graphics.print("Penalties: " .. race.penalties .. "s", 10, 50)

	-- Countdown
	if race.active then
		love.graphics.setColor(1, 1, 0)
		local text = race.countdown > 0 and math.ceil(race.countdown) or "GO!"
		love.graphics.printf(text, 0, config.SCREEN.h / 2 - 50, config.SCREEN.w, "center", 0, 3, 3)
	end
end

function ui.drawEndScreen(race, wind)
	local totalTime = race.time + race.penalties
	local avgSpeed = race.speedSamples > 0 and race.totalSpeed / race.speedSamples or 0

	love.graphics.setColor(1, 1, 0)
	love.graphics.printf("RACE FINISHED!", 0, 80, config.SCREEN.w, "center", 0, 2, 2)

	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(
		"Race Time: " .. string.format("%.2f", race.time) .. "s",
		0,
		200,
		config.SCREEN.w,
		"center",
		0,
		1.3,
		1.3
	)
	love.graphics.printf("Penalties: " .. race.penalties .. "s", 0, 240, config.SCREEN.w, "center", 0, 1.3, 1.3)
	love.graphics.printf(
		"Total Time: " .. string.format("%.2f", totalTime) .. "s",
		0,
		280,
		config.SCREEN.w,
		"center",
		0,
		1.5,
		1.5
	)
	love.graphics.printf(
		"Avg Speed: " .. string.format("%.1f", avgSpeed),
		0,
		330,
		config.SCREEN.w,
		"center",
		0,
		1.3,
		1.3
	)
	love.graphics.printf("Mark Hits: " .. race.markHits, 0, 370, config.SCREEN.w, "center", 0, 1.3, 1.3)

	love.graphics.setColor(0.8, 0.9, 1)
	love.graphics.printf(
		"Weather: Wind " .. string.format("%.0f", wind.speed) .. " knots from North",
		0,
		420,
		config.SCREEN.w,
		"center"
	)

	love.graphics.setColor(1, 1, 0)
	love.graphics.printf("Press SPACE to restart", 0, 500, config.SCREEN.w, "center", 0, 1.2, 1.2)
end

return ui
