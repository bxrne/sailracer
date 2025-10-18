local config = require("config")

local marks = {
	{ name = "START", x = config.SCREEN.w / 2 - 50, y = config.SCREEN.h / 2, radius = 8, color = { 1, 0.8, 0 } },
	{ name = "FINISH", x = config.SCREEN.w / 2 + 50, y = config.SCREEN.h / 2, radius = 8, color = { 1, 0.8, 0 } },
	{ name = "WINDWARD", x = config.SCREEN.w / 2, y = 100, radius = 10, color = { 1, 0.3, 0.3 }, next = true },
	{ name = "LEEWARD", x = config.SCREEN.w / 2, y = config.SCREEN.h - 100, radius = 10, color = { 0.3, 1, 0.3 } },
}

function marks.draw()
	for _, mark in ipairs(marks) do
		-- Highlight next mark
		if mark.next then
			love.graphics.setColor(1, 1, 0, 0.3)
			love.graphics.circle("fill", mark.x, mark.y, mark.radius + 8)
		end

		love.graphics.setColor(mark.color)
		love.graphics.circle("fill", mark.x, mark.y, mark.radius)
		love.graphics.setColor(0, 0, 0)
		love.graphics.circle("line", mark.x, mark.y, mark.radius)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(mark.name, mark.x - 20, mark.y - mark.radius - 15)
	end
end

function marks.checkCollisions(boat, race)
	local nextMark = marks[race.nextMark]
	local dx = boat.x - nextMark.x
	local dy = boat.y - nextMark.y
	local dist = math.sqrt(dx * dx + dy * dy)

	-- Hit next mark
	if dist < nextMark.radius + boat.size then
		nextMark.next = false

		if race.nextMark == 3 then -- Windward
			race.nextMark = 4 -- Go to leeward
			marks[4].next = true
		elseif race.nextMark == 4 then -- Leeward
			race.nextMark = 0 -- Go to finish
		end
	end

	-- Check mark hits (for penalties)
	for i, mark in ipairs(marks) do
		dx = boat.x - mark.x
		dy = boat.y - mark.y
		dist = math.sqrt(dx * dx + dy * dy)
		if dist < mark.radius + boat.size and i ~= race.nextMark then
			race.markHits = race.markHits + 1
			race.penalties = race.penalties + 2
		end
	end
end

function marks.crossedStartLine(boat)
	local lineY = marks[1].y
	return math.abs(boat.y - lineY) < 5 and boat.x > marks[1].x and boat.x < marks[2].x
end

return marks
