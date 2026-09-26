-- Pitch content: who you are selling to, and what you can say.
--
-- Every line moves the three Straight Line certainty meters:
--   pen  = certainty about the product
--   you  = certainty about the salesperson
--   firm = certainty about the company behind it
-- Customer archetypes like or dislike line tags, which scales the effect.

local PitchData = {}

PitchData.Tags = {
	rapport = "Rapport",
	question = "Qualify",
	product = "Product",
	urgency = "Urgency",
	authority = "Authority",
	hype = "Hype",
	pressure = "Pressure",
	honest = "Honest",
	napkin = "???",
}

-- likes: x1.6 on gains. dislikes: gains become losses.
PitchData.Archetypes = {
	tourist = {
		name = "Lost Tourist",
		budget = 0.8,
		likes = { "rapport", "hype" },
		dislikes = { "pressure", "authority" },
		skin = Color3.fromRGB(255, 205, 170),
		shirt = Color3.fromRGB(255, 120, 170),
		pants = Color3.fromRGB(90, 150, 220),
		greeting = { "Excuse me, which way to the big bull statue?", "I only came here for a hot dog.", "Is this the line for the ferry?" },
	},
	plumber = {
		name = "Tired Plumber",
		budget = 0.9,
		likes = { "question", "honest" },
		dislikes = { "hype" },
		skin = Color3.fromRGB(200, 150, 110),
		shirt = Color3.fromRGB(60, 90, 160),
		pants = Color3.fromRGB(50, 60, 80),
		greeting = { "Make it quick, pal. I got a leak in Queens.", "A pen? I use a carpenter's pencil." },
	},
	dentist = {
		name = "Bored Dentist",
		budget = 1.1,
		likes = { "product", "authority" },
		dislikes = { "pressure" },
		skin = Color3.fromRGB(240, 200, 160),
		shirt = Color3.fromRGB(235, 245, 250),
		pants = Color3.fromRGB(90, 110, 130),
		greeting = { "I have a root canal at three.", "My accountant says I should diversify." },
	},
	mom = {
		name = "Busy Soccer Mom",
		budget = 1,
		likes = { "rapport", "urgency" },
		dislikes = { "pressure", "hype" },
		skin = Color3.fromRGB(230, 180, 140),
		shirt = Color3.fromRGB(120, 200, 180),
		pants = Color3.fromRGB(60, 60, 90),
		greeting = { "I have exactly four minutes.", "Is this going to take long? The minivan is double parked." },
	},
	accountant = {
		name = "Skeptical Accountant",
		budget = 1.3,
		likes = { "question", "product", "honest" },
		dislikes = { "hype", "pressure" },
		skin = Color3.fromRGB(250, 220, 190),
		shirt = Color3.fromRGB(180, 180, 170),
		pants = Color3.fromRGB(70, 70, 70),
		greeting = { "Show me the numbers.", "I've heard every pitch in the book, kid." },
	},
	shoes = {
		name = "Eccentric Shoe Designer",
		budget = 1.5,
		likes = { "hype", "urgency" },
		dislikes = { "honest" },
		skin = Color3.fromRGB(215, 165, 125),
		shirt = Color3.fromRGB(160, 60, 200),
		pants = Color3.fromRGB(30, 30, 30),
		greeting = { "Does it come in platform?", "I'm about to go public. Impress me." },
	},
	intern = {
		name = "Desperate Intern",
		budget = 0.7,
		likes = { "rapport", "authority" },
		dislikes = {},
		skin = Color3.fromRGB(255, 225, 200),
		shirt = Color3.fromRGB(240, 240, 240),
		pants = Color3.fromRGB(40, 40, 60),
		greeting = { "I've lost six pens today. SIX.", "My boss is going to kill me." },
	},
	bro = {
		name = "Hedge Fund Bro",
		budget = 2,
		likes = { "hype", "pressure", "urgency" },
		dislikes = { "honest", "question" },
		skin = Color3.fromRGB(245, 195, 150),
		shirt = Color3.fromRGB(80, 140, 230),
		pants = Color3.fromRGB(25, 25, 35),
		greeting = { "Bro. BRO. Pitch me.", "I closed three deals before breakfast, bro." },
	},
	swiss = {
		name = "Swiss Banker",
		budget = 2.6,
		likes = { "authority", "product" },
		dislikes = { "hype", "pressure" },
		skin = Color3.fromRGB(250, 225, 205),
		shirt = Color3.fromRGB(35, 35, 45),
		pants = Color3.fromRGB(35, 35, 45),
		greeting = { "Discretion is everything.", "We do not ask questions. We also do not buy pens. Usually." },
	},
	duchess = {
		name = "British Duchess",
		budget = 4,
		likes = { "rapport", "authority" },
		dislikes = { "pressure", "urgency" },
		skin = Color3.fromRGB(255, 225, 210),
		shirt = Color3.fromRGB(200, 170, 230),
		pants = Color3.fromRGB(200, 170, 230),
		greeting = { "Darling, I've never held a pen myself.", "Is this vessel yours? How quaint." },
	},
	oil = {
		name = "Oil Tycoon",
		budget = 5,
		likes = { "hype", "urgency", "authority" },
		dislikes = { "question" },
		skin = Color3.fromRGB(215, 160, 120),
		shirt = Color3.fromRGB(240, 230, 210),
		pants = Color3.fromRGB(120, 90, 60),
		greeting = { "I buy things. Big things. Is this big?", "Name your price, boy." },
	},
	fbi = {
		name = "Undercover FBI Agent",
		budget = 3,
		-- Only honesty works on him. Hard sells backfire hard.
		likes = { "honest", "question" },
		dislikes = { "pressure", "hype", "urgency" },
		special = "fbi",
		skin = Color3.fromRGB(235, 190, 150),
		shirt = Color3.fromRGB(60, 70, 60),
		pants = Color3.fromRGB(60, 70, 60),
		greeting = { "Just a regular guy. Buying regular pens.", "Nice firm you got here. Real nice. Be a shame if..." },
	},
}

PitchData.Archetypes.crypto = {
	name = "Crypto Kid",
	budget = 1,
	likes = { "hype", "urgency" },
	dislikes = { "honest", "authority" },
	skin = Color3.fromRGB(245, 205, 170),
	shirt = Color3.fromRGB(40, 40, 40),
	pants = Color3.fromRGB(90, 90, 100),
	greeting = { "Can I pay in PenCoin?", "Wen moon, ser?", "Is this pen on the blockchain?" },
}
PitchData.Archetypes.influencer = {
	name = "Influencer",
	budget = 1,
	likes = { "hype", "rapport" },
	dislikes = { "question", "authority" },
	skin = Color3.fromRGB(240, 195, 160),
	shirt = Color3.fromRGB(255, 170, 210),
	pants = Color3.fromRGB(240, 240, 245),
	greeting = { "Hold on, I'm live right now.", "Will this pen look good on camera?" },
}
PitchData.Archetypes.rockstar = {
	name = "Rock Star",
	budget = 1,
	likes = { "hype", "pressure" },
	dislikes = { "authority", "question" },
	skin = Color3.fromRGB(230, 190, 160),
	shirt = Color3.fromRGB(20, 20, 20),
	pants = Color3.fromRGB(30, 30, 60),
	greeting = { "I only sign autographs with the best, man.", "Make it LOUD, dude." },
}
PitchData.Archetypes.prince = {
	name = "Royal",
	budget = 1,
	likes = { "authority", "rapport" },
	dislikes = { "pressure", "hype" },
	skin = Color3.fromRGB(250, 220, 195),
	shirt = Color3.fromRGB(120, 30, 60),
	pants = Color3.fromRGB(240, 235, 220),
	greeting = { "One does not usually buy one's own pens.", "You may approach." },
}
-- The Ultra Exotic. He invented this pitch, so only his own answer works:
-- qualify first, then build real certainty.
PitchData.Archetypes.wolf = {
	name = "The Wolf",
	budget = 1,
	likes = { "question", "authority" },
	dislikes = { "hype", "pressure", "honest" },
	skin = Color3.fromRGB(245, 200, 165),
	shirt = Color3.fromRGB(15, 15, 15),
	pants = Color3.fromRGB(15, 15, 15),
	greeting = { "Sell me this pen.", "Go ahead, kid. Sell me this pen.", "I've heard this pitch before. From myself." },
}

-- Effects are { pen, you, firm }.
PitchData.Lines = {
	-- Rapport
	{ tag = "rapport", text = "Nice watch. You look like someone who signs important things.", fx = { 0, 2, 0 } },
	{ tag = "rapport", text = "Before we talk pens: how's your day actually going?", fx = { 0, 2, 1 } },
	{ tag = "rapport", text = "I'll be straight with you. I like you already.", fx = { 0, 2, 0 } },
	{ tag = "rapport", text = "My grandfather sold pens. He'd have loved you.", fx = { 1, 1, 0 } },

	-- Qualify (Belfort's real answer: ask questions first)
	{ tag = "question", text = "When was the last time you needed a pen and didn't have one?", fx = { 2, 1, 0 } },
	{ tag = "question", text = "What do you usually write with? And what do you hate about it?", fx = { 2, 1, 0 } },
	{ tag = "question", text = "How many important contracts will you sign this year?", fx = { 2, 0, 1 } },
	{ tag = "question", text = "What would it cost you to miss one signature?", fx = { 2, 1, 0 } },

	-- Product
	{ tag = "product", text = "It writes upside down, underwater, and in zero gravity.", fx = { 3, 0, 0 } },
	{ tag = "product", text = "Feel that weight. That's a pen that means business.", fx = { 2, 1, 0 } },
	{ tag = "product", text = "Lifetime ink warranty. It will outlive your stapler.", fx = { 2, 0, 1 } },
	{ tag = "product", text = "It's a pen. It... writes?", fx = { -1, -1, 0 }, bad = true },
	{ tag = "product", text = "It's blue. Like the ocean. Or a very sad smurf.", fx = { -1, 0, 0 }, bad = true },

	-- Urgency (supply and demand)
	{ tag = "urgency", text = "I've got three left, and the guy behind you wants all of them.", fx = { 1, 0, 1 } },
	{ tag = "urgency", text = "Price goes up at the closing bell. That's in four minutes.", fx = { 2, 0, 1 } },
	{ tag = "urgency", text = "Limited run. When they're gone, they're gone.", fx = { 2, 0, 0 } },

	-- Authority
	{ tag = "authority", text = "Our firm has moved more pens than anyone on the East Coast.", fx = { 0, 0, 3 } },
	{ tag = "authority", text = "Every CEO on this street signs with one of ours.", fx = { 1, 0, 2 } },
	{ tag = "authority", text = "We're regulated, audited, and frankly, legendary.", fx = { 0, 1, 2 } },

	-- Hype
	{ tag = "hype", text = "This isn't a pen. It's a lifestyle.", fx = { 1, 1, 1 } },
	{ tag = "hype", text = "You're not buying a pen. You're buying the person who owns this pen.", fx = { 1, 2, 0 } },
	{ tag = "hype", text = "Money never sleeps, and neither does this ink.", fx = { 2, 1, 0 } },

	-- Pressure
	{ tag = "pressure", text = "Pick up the pen. PICK. UP. THE. PEN.", fx = { 2, -1, 0 } },
	{ tag = "pressure", text = "I'm not leaving until you say yes.", fx = { 1, 1, -1 } },
	{ tag = "pressure", text = "Yes or yes? Your call.", fx = { 1, 0, 1 } },

	-- Honest
	{ tag = "honest", text = "Honestly? It's a solid pen at a fair price. That's it.", fx = { 1, 1, 1 } },
	{ tag = "honest", text = "If you don't need it, don't buy it. But I think you do.", fx = { 1, 2, 0 } },
}

-- The legendary line from the film's final scene.
PitchData.Napkin = {
	tag = "napkin",
	text = "Do me a favor. Write your name on this napkin for me.",
	fx = { 4, 3, 3 },
	napkin = true,
}

PitchData.CloseSuccess = {
	"Deal. Where do I sign? Oh wait, with THIS.",
	"You know what? I'll take it.",
	"Fine! FINE. Give me the pen.",
	"I don't know what just happened, but I'm buying.",
	"Sold. Tell your boss you're a monster.",
}

PitchData.CloseFail = {
	"Fugazi. It's all fugazi.",
	"Nice try, kid. Not today.",
	"I'm gonna need a minute...",
	"You're pushing too hard, buddy.",
}

PitchData.WalkAway = {
	"I'm late for lunch. Bye.",
	"I'll think about it. (He will not.)",
	"Pens are a scam anyway.",
	"Call my assistant. Actually, don't.",
}

PitchData.Reactions = {
	good = { "Go on...", "Huh. Interesting.", "Okay, okay, I'm listening.", "Now we're talking!" },
	great = { "OH, now I get it.", "Say that again!", "You're good, kid." },
	bad = { "...what?", "That's the worst thing I've heard today.", "Are you new?", "Wow. No." },
}

PitchData.FBI = {
	busted = "FBI! Hard-selling a federal agent? That's a fine, pal.",
	honest = "An honest broker? On THIS street? I'll buy three.",
}

return PitchData
