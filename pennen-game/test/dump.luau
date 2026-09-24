-- Schrijft alle onderdelen van de map weg als JSON-regels, voor tools/preview.py

local function num(v)
	return string.format("%.3f", v)
end

local function colorOf(p)
	local c = p.Color
	if not c then
		return "[0.6,0.6,0.62]"
	end
	return string.format("[%.4f,%.4f,%.4f]", c.R, c.G, c.B)
end

local CLASSES = { Part = true, WedgePart = true, SpawnLocation = true, MeshPart = true }

local function dump(node)
	for _, child in node:GetChildren() do
		local class = child.ClassName
		if CLASSES[class] then
			local cf = child.CFrame
			local size = child.Size
			local shape = child.Shape and child.Shape.Name or "Block"
			local material = child.Material and child.Material.Name or "Plastic"
			print(string.format(
				'#PART#{"name":"%s","class":"%s","shape":"%s","material":"%s","size":[%s,%s,%s],'
					.. '"pos":[%s,%s,%s],"rot":[%s,%s,%s],"color":%s,"transparency":%s}',
				tostring(child.Name), class, shape, material,
				num(size.X), num(size.Y), num(size.Z),
				num(rawget(cf, "_pos").X), num(rawget(cf, "_pos").Y), num(rawget(cf, "_pos").Z),
				num(rawget(cf, "_pitch")), num(rawget(cf, "_yaw")), num(rawget(cf, "_roll")),
				colorOf(child), num(child.Transparency or 0)
			))
		end
		dump(child)
	end
end

dump(workspace)
