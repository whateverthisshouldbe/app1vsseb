--!strict
-- Getallen leesbaar maken: 1234567 -> "1.23M", 95 -> "95", 90 sec -> "1:30".

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local function trimZeros(text: string): string
	if string.find(text, ".", 1, true) then
		text = (string.gsub(text, "0+$", ""))
		text = (string.gsub(text, "%.$", ""))
	end
	return text
end

-- Drie significante cijfers, altijd naar beneden afgerond zodat je nooit
-- meer ziet dan je hebt.
function Format.short(n: number): string
	if n ~= n or n == math.huge or n == -math.huge then
		return "0"
	end
	local sign = if n < 0 then "-" else ""
	n = math.abs(n)

	if n < 1000 then
		if n < 10 and math.floor(n) ~= n then
			return sign .. trimZeros(string.format("%.1f", math.floor(n * 10) / 10))
		end
		return sign .. tostring(math.floor(n))
	end

	local tier = math.floor(math.log10(n) / 3)
	local scaled = n / 10 ^ (tier * 3)
	-- log10 kan net onder of boven een macht van 10 uitkomen
	if scaled >= 1000 then
		tier += 1
		scaled /= 1000
	elseif scaled < 1 then
		tier -= 1
		scaled *= 1000
	end
	if tier >= #SUFFIXES then
		return sign .. string.format("%.2e", n)
	end

	local text
	if scaled >= 100 then
		text = tostring(math.floor(scaled))
	elseif scaled >= 10 then
		text = trimZeros(string.format("%.1f", math.floor(scaled * 10) / 10))
	else
		text = trimZeros(string.format("%.2f", math.floor(scaled * 100) / 100))
	end
	return sign .. text .. SUFFIXES[tier + 1]
end

function Format.cash(n: number): string
	return "$" .. Format.short(n)
end

function Format.streams(n: number): string
	return Format.short(n) .. " streams"
end

function Format.perSecond(n: number): string
	return "$" .. Format.short(n) .. "/s"
end

function Format.time(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = seconds // 3600
	local m = (seconds % 3600) // 60
	local s = seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

-- "2h 5m" voor de offline-melding
function Format.duration(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = seconds // 3600
	local m = (seconds % 3600) // 60
	if h > 0 then
		return string.format("%dh %dm", h, m)
	elseif m > 0 then
		return string.format("%dm", m)
	end
	return string.format("%ds", seconds)
end

function Format.multiplier(x: number): string
	return "x" .. trimZeros(string.format("%.2f", x))
end

return Format
