local config = require("config")

local QUOTES = {
	"A smooth sea never made a skilled sailor!",
	"The pessimist complains about the wind; the optimist expects it to change; the sailor adjusts the sails.",
	"Wind and water are not just elements, they're your dance partners.",
	"Port tack has right of way... unless you're racing!",
	"There's no such thing as bad weather, only inappropriate clothing.",
	"The cure for anything is salt water: sweat, tears, or the sea.",
	"Red sky at night, sailor's delight. Red sky at morning, sailors take warning!",
}

local game = {
	state = config.STATES.START,
	quote = "",
}

function game.load()
	game.quote = QUOTES[math.random(#QUOTES)]
end

function game.reset()
	game.state = config.STATES.START
	game.quote = QUOTES[math.random(#QUOTES)]
end

return game
