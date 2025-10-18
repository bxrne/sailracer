local config = require("config")

local wind = {
 	angle = 3 * math.pi / 2,
 	speed = config.WIND.speed,
}

function wind.drawIndicator()
	local x, y = config.SCREEN.w - 60, 40

	love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
	love.graphics.circle("fill", x, y, 25)
	love.graphics.setColor(1, 1, 1)
	love.graphics.circle("line", x, y, 25)

	-- Wind arrow (pointing down)
	love.graphics.push()
	love.graphics.translate(x, y)
	love.graphics.rotate(wind.angle)
	love.graphics.setColor(0.3, 1, 0.3)
	love.graphics.polygon("fill", 0, -15, -5, 5, 5, 5)
	love.graphics.pop()

	love.graphics.setColor(1, 1, 1)
	love.graphics.print("WIND", x - 15, y + 30)
end

return wind
