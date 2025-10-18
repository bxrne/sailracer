local config = require("config")

local race = {
	countdown = config.RACE.countdown,
	active = false,
	started = false,
	finished = false,
	startTime = 0,
	time = 0,
	penalties = 0,
	nextMark = 3,
	markHits = 0,
	totalSpeed = 0,
	speedSamples = 0,
}

function race.update(dt, boat, wind, marks)
	-- Countdown
	if race.active then
		race.countdown = race.countdown - dt
		if race.countdown <= 0 then
			race.active = false
			race.started = true
			race.startTime = love.timer.getTime()
		end
	end

	-- Check early start
	if race.active and marks.crossedStartLine(boat) then
		race.penalties = race.penalties + 5
		race.active = false
		race.started = true
		race.startTime = love.timer.getTime()
	end

	-- Race logic
	if race.started and not race.finished then
		boat.update(dt, wind)
		marks.checkCollisions(boat, race)
		race.time = love.timer.getTime() - race.startTime

		-- Check finish line (only after passing leeward)
		if race.nextMark == 0 and marks.crossedStartLine(boat) and boat.y > config.SCREEN.h / 2 then
			race.finished = true
		end
	end

	-- Track average speed
	race.totalSpeed = race.totalSpeed + boat.speed
	race.speedSamples = race.speedSamples + 1
end

function race.start()
	race.active = true
	race.countdown = config.RACE.countdown
end

function race.reset()
	race.countdown = config.RACE.countdown
	race.active = false
	race.started = false
	race.finished = false
	race.startTime = 0
	race.time = 0
	race.penalties = 0
	race.nextMark = 3
	race.markHits = 0
	race.totalSpeed = 0
	race.speedSamples = 0
end

return race
