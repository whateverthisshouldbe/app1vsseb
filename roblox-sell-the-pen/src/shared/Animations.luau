-- Roblox's own catalog animation packs (free for any experience to use).
-- IDs from https://create.roblox.com/docs/animation/using

local Animations = {}

Animations.Packs = {
	Stylish = { run = 616140816, walk = 616146177, jump = 616139451, idle = { 616136790, 616138447 }, fall = 616134815, climb = 616133594 },
	Ninja = { run = 656118852, walk = 656121766, jump = 656117878, idle = { 656117400, 656118341 }, fall = 656115606, climb = 656114359 },
	Superhero = { run = 616117076, walk = 616122287, jump = 616115533, idle = { 616111295, 616113536 }, fall = 616108001, climb = 616104706 },
	Toy = { run = 782842708, walk = 782843345, jump = 782847020, idle = { 782841498, 782845736 }, fall = 782846423, climb = 782843869 },
	Cartoony = { run = 742638842, walk = 742640026, jump = 742637942, idle = { 742637544, 742638445 }, fall = 742637151, climb = 742636889 },
	Robot = { run = 616091570, walk = 616095330, jump = 616090535, idle = { 616088211, 616089559 }, fall = 616087089, climb = 616086039 },
	Mage = { run = 707861613, walk = 707897309, jump = 707853694, idle = { 707742142, 707855907 }, fall = 707829716, climb = 707826056 },
	Zombie = { run = 616163682, walk = 616168032, jump = 616161997, idle = { 616158929, 616160636 }, fall = 616157476, climb = 616156119 },
	Levitation = { run = 616010382, walk = 616013216, jump = 616008936, idle = { 616006778, 616008087 }, fall = 616005863, climb = 616003713 },
	Rthro = { run = 2510198475, walk = 2510202577, jump = 2510197830, idle = { 2510197257, 2510196951 }, fall = 2510195892, climb = 2510192778 },
	Elder = { run = 845386501, walk = 845403856, jump = 845398858, idle = { 845397899, 845400520 }, fall = 845396048, climb = 845392038 },
	Pirate = { run = 750783738, walk = 750785693, jump = 750782230, idle = { 750781874, 750782770 }, fall = 750780242, climb = 750779899 },
	Knight = { run = 657564596, walk = 657552124, jump = 658409194, idle = { 657595757, 657568135 }, fall = 657600338, climb = 658360781 },
	Bubbly = { run = 910025107, walk = 910034870, jump = 910016857, idle = { 910004836, 910009958 }, fall = 910001910, climb = 909997997 },
	Vampire = { run = 1083462077, walk = 1083473930, jump = 1083455352, idle = { 1083445855, 1083450166 }, fall = 1083443587, climb = 1083439238 },
}

-- Your walk gets cooler with your suit.
Animations.BySuit = {
	thrift = "Cartoony",
	rack = "Toy",
	tailored = "Ninja",
	silk = "Stylish",
	wolfsuit = "Superhero",
}

-- Visitors walk like who they are.
Animations.ByArchetype = {
	tourist = "Cartoony",
	plumber = "Rthro",
	dentist = "Elder",
	mom = "Bubbly",
	intern = "Zombie",
	accountant = "Robot",
	shoes = "Stylish",
	bro = "Stylish",
	swiss = "Knight",
	duchess = "Levitation",
	oil = "Pirate",
	fbi = "Ninja",
	crypto = "Robot",
	influencer = "Bubbly",
	rockstar = "Toy",
	prince = "Mage",
	wolf = "Superhero",
}

-- Rarest visitors override their archetype's walk.
Animations.ByRarity = {
	exotic = "Levitation",
	ultra = "Superhero",
}

function Animations.id(number)
	return "rbxassetid://" .. tostring(number)
end

return Animations
