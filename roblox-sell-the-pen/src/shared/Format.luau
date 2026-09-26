-- Number formatting shared by server messages and client UI.

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }

function Format.commas(n)
	n = math.floor(n)
	local s = tostring(math.abs(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return (n < 0 and "-" or "") .. out
end

-- 1234 -> "1,234", 1234567 -> "1.23M"
function Format.short(n)
	n = math.floor(n)
	if math.abs(n) < 100_000 then
		return Format.commas(n)
	end
	local tier = 1
	local value = n
	while math.abs(value) >= 1000 and tier < #SUFFIXES do
		value /= 1000
		tier += 1
	end
	local digits = math.abs(value) >= 100 and 0 or (math.abs(value) >= 10 and 1 or 2)
	return string.format("%." .. digits .. "f%s", value, SUFFIXES[tier])
end

function Format.cash(n)
	return "$" .. Format.short(n)
end

-- Like cash, but keeps cents for small per-second rates ($0.42/s).
function Format.rate(n)
	if n > 0 and n < 10 then
		return string.format("$%.2f", n)
	end
	return Format.cash(n)
end

function Format.time(seconds)
	seconds = math.max(0, math.floor(seconds))
	local h = seconds // 3600
	local m = (seconds % 3600) // 60
	local s = seconds % 60
	if h > 0 then
		return string.format("%dh %02dm", h, m)
	end
	return string.format("%d:%02d", m, s)
end

return Format
