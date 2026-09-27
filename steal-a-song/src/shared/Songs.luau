--!strict
-- Alle songs in de game. min/max zijn de start-streams zonder mutatie; een
-- song die op de loper verschijnt krijgt een willekeurig aantal daartussen.
-- color is de kleur van het label midden op de plaat.

export type SongDef = {
	id: string,
	name: string,
	rarity: string,
	genre: string,
	min: number,
	max: number,
	color: { number },
}

local list: { SongDef } = {
	-- Common
	{ id = "shower_singer", name = "Shower Singer", rarity = "Common", genre = "Pop", min = 1_000, max = 2_000, color = { 120, 200, 255 } },
	{ id = "kazoo_solo", name = "Kazoo Solo", rarity = "Common", genre = "Jazz", min = 1_500, max = 3_000, color = { 255, 150, 60 } },
	{ id = "ringtone_remix", name = "Ringtone Remix", rarity = "Common", genre = "EDM", min = 2_000, max = 4_000, color = { 90, 255, 160 } },
	{ id = "elevator_muzak", name = "Elevator Muzak", rarity = "Common", genre = "Lounge", min = 3_000, max = 5_500, color = { 220, 200, 150 } },
	{ id = "garage_demo", name = "Garage Demo", rarity = "Common", genre = "Rock", min = 4_000, max = 8_000, color = { 255, 90, 90 } },

	-- Rare
	{ id = "lofi_homework", name = "Lo-Fi Homework", rarity = "Rare", genre = "Lo-Fi", min = 20_000, max = 40_000, color = { 170, 150, 255 } },
	{ id = "cat_piano", name = "Cat Piano Concerto", rarity = "Rare", genre = "Classical", min = 30_000, max = 60_000, color = { 255, 210, 230 } },
	{ id = "bedroom_pop", name = "Bedroom Pop Crush", rarity = "Rare", genre = "Pop", min = 45_000, max = 90_000, color = { 255, 120, 200 } },
	{ id = "boombox_bop", name = "Boombox Bop", rarity = "Rare", genre = "Hip-Hop", min = 70_000, max = 150_000, color = { 255, 230, 60 } },

	-- Epic
	{ id = "summer_anthem", name = "Summer Anthem", rarity = "Epic", genre = "Pop", min = 300_000, max = 600_000, color = { 255, 170, 40 } },
	{ id = "banjo_breakdown", name = "Banjo Breakdown", rarity = "Epic", genre = "Country", min = 450_000, max = 900_000, color = { 200, 130, 70 } },
	{ id = "disco_llama", name = "Disco Llama", rarity = "Epic", genre = "Disco", min = 700_000, max = 1_400_000, color = { 255, 80, 255 } },
	{ id = "bass_drop_baby", name = "Bass Drop Baby", rarity = "Epic", genre = "Dubstep", min = 1_000_000, max = 2_000_000, color = { 60, 255, 255 } },

	-- Legendary
	{ id = "neon_nights", name = "Neon Nights", rarity = "Legendary", genre = "Synthwave", min = 5_000_000, max = 9_000_000, color = { 255, 60, 200 } },
	{ id = "trap_goblin", name = "Trap Goblin", rarity = "Legendary", genre = "Trap", min = 7_000_000, max = 14_000_000, color = { 120, 255, 60 } },
	{ id = "kpop_supernova", name = "K-Pop Supernova", rarity = "Legendary", genre = "K-Pop", min = 10_000_000, max = 18_000_000, color = { 255, 140, 220 } },
	{ id = "viral_dance", name = "Viral Dance Craze", rarity = "Legendary", genre = "Dance", min = 14_000_000, max = 25_000_000, color = { 255, 230, 90 } },

	-- Mythic
	{ id = "galaxy_opera", name = "Galaxy Opera", rarity = "Mythic", genre = "Space Opera", min = 60_000_000, max = 110_000_000, color = { 90, 110, 255 } },
	{ id = "dragon_metal", name = "Dragon Metal", rarity = "Mythic", genre = "Metal", min = 90_000_000, max = 160_000_000, color = { 255, 80, 30 } },
	{ id = "stadium_anthem", name = "Stadium Anthem", rarity = "Mythic", genre = "Arena Rock", min = 130_000_000, max = 250_000_000, color = { 255, 255, 255 } },

	-- Chart God
	{ id = "billion_banger", name = "Billion Stream Banger", rarity = "Chart God", genre = "Pop", min = 800_000_000, max = 1_500_000_000, color = { 255, 215, 0 } },
	{ id = "internet_anthem", name = "Anthem Of The Internet", rarity = "Chart God", genre = "Meme", min = 1_200_000_000, max = 2_200_000_000, color = { 0, 255, 170 } },
	{ id = "eternal_number_one", name = "Eternal #1", rarity = "Chart God", genre = "Legend", min = 1_600_000_000, max = 3_000_000_000, color = { 255, 50, 120 } },

	-- Secret
	{ id = "lost_tape", name = "The Lost Tape", rarity = "Secret", genre = "???", min = 8_000_000_000, max = 12_000_000_000, color = { 10, 10, 10 } },
	{ id = "song_of_century", name = "Song Of The Century", rarity = "Secret", genre = "???", min = 12_000_000_000, max = 20_000_000_000, color = { 255, 255, 255 } },
}

local byId: { [string]: SongDef } = {}
local byRarity: { [string]: { SongDef } } = {}
for _, def in list do
	assert(byId[def.id] == nil, "dubbel song-id: " .. def.id)
	byId[def.id] = def
	local group = byRarity[def.rarity]
	if not group then
		group = {}
		byRarity[def.rarity] = group
	end
	table.insert(group, def)
end

return {
	list = list,
	byId = byId,
	byRarity = byRarity,
}
