local config = {}

config.STATES = {
	START = 1,
	RACING = 2,
	END = 3,
}

config.SCREEN = {
	w = 800,
	h = 600,
}

-- Boat defaults
config.BOAT = {
	maxSpeed = 150,
	size = 15,
	turnSpeed = 2.0,
}

-- Wind defaults
config.WIND = {
	speed = 50,
}

-- Race defaults
config.RACE = {
	countdown = 5,
}

return config
