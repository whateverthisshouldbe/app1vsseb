-- The playthrough tutorial. The client watches what you do and moves you
-- through these steps; the server saves progress and pays the reward.

local Tutorial = {}

Tutorial.RewardMult = 2
Tutorial.RewardDuration = 15 * 60 -- seconds of x2 money
Tutorial.ShopTarget = "click" -- the pen the tutorial has you buy

Tutorial.Steps = {
	{ id = "talk", title = "Find a customer", text = "Walk up to a visitor and press E to pitch them.", target = "customer" },
	{ id = "line", title = "Say something", text = "Pick a line: press 1, 2 or 3 (or tap it).", target = "pitchOptions" },
	{ id = "tonality", title = "Nail the tonality", text = "Stop the needle inside the GREEN zone. SPACE or click!", target = "pitchTonality" },
	{ id = "meters", title = "Build certainty", text = "Fill up PEN, YOU and FIRM. Lines they LIKE work best. Pick another line.", target = "pitchMeters" },
	{ id = "close", title = "Close the deal", text = "Hit CLOSE (C). Fuller bars = better odds and a bigger sale.", target = "pitchClose" },
	{ id = "deal", title = "Cash or recruit?", text = "Take the money [1], or recruit them as a broker who earns for you [2].", target = "deal" },
	{ id = "shop", title = "Upgrade your pen", text = "Open the SHOP and buy the Clicky Pen. Better pens = bigger sales. (The firm spotted you the cash.)", target = "shop" },
	{ id = "firm", title = "Your firm", text = "Open FIRM. Up to 8 brokers work for you, even while you're offline.", target = "firm" },
	{ id = "index", title = "The Index", text = "Open INDEX. 150 visitors to collect; every new one gives +0.5% sales forever.", target = "index" },
	{ id = "teleport", title = "Travel", text = "Open TELEPORT. New zones unlock with rebirths and pay way more.", target = "teleport" },
	{ id = "move", title = "Move like a Wolf", text = "Hold SHIFT to sprint, and press jump twice for a flip.", target = "move" },
	{ id = "rebirth", title = "Rebirth", text = "Open REBIRTH. Reset your cash for a permanent multiplier. Brokers and Index stay!", target = "rebirth" },
}

Tutorial.byId = {}
for index, step in Tutorial.Steps do
	step.index = index
	Tutorial.byId[step.id] = step
end

return Tutorial
