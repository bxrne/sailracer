local config = require("config")
local game = require("game")
local boat = require("boat")
local wind = require("wind")
local marks = require("marks")
local race = require("race")
local particles = require("particles")
local ui = require("ui")

function love.load()
	love.window.setMode(config.SCREEN.w, config.SCREEN.h)
	love.window.setTitle("SailRacer")

	game.load()
	particles.create()
end

function love.update(dt)
	particles.update(dt)

	if game.state == config.STATES.RACING then
		race.update(dt, boat, wind, marks)
		particles.setWindPosition(boat.x, boat.y)
		particles.setWaterPosition(boat.x, boat.y)

		if race.finished then
			game.state = config.STATES.END
		end
	end
end

function love.draw()
	love.graphics.clear(0.1, 0.3, 0.5)

	if game.state == config.STATES.START then
		ui.drawStartScreen(game, particles)
	elseif game.state == config.STATES.RACING then
		ui.drawRacingScreen(boat, race, marks, wind, particles)
	elseif game.state == config.STATES.END then
		ui.drawEndScreen(race, wind)
	end
end

function love.keypressed(key)
	if key == "space" then
		if game.state == config.STATES.START then
			race.start()
			game.state = config.STATES.RACING
		elseif game.state == config.STATES.END then
			game.reset()
			race.reset()
			boat.x = config.SCREEN.w / 2
			boat.y = config.SCREEN.h - 150
			boat.angle = math.pi / 2
			boat.speed = 60
			for i, mark in ipairs(marks) do
				mark.next = (i == 3)
			end
		end
	elseif key == "escape" then
		love.event.quit()
	end
end
