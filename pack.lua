PATTERN_FOLDER = "./pattern"
Z1_TEMP_SVG = "./z1.temp.svg"
Z1_CSS = "./z1.css"

PATTERN_EXT = ".pre.z1"
OUT_SVG_FILE = "out.svg"

DATABASE = "z1.sqlite3"
EXAMPLES_DIR = "./examples"

BORDER = 20

ELETRONS_TYPES = {
	["-"] = 1,
	["="] = 2,
	["%"] = 3
}

-- STANDARD PLUGIN
STANDARD_LIGATION_SIZE = 30
STANDARD_DISTANCE_BETWEEN_LIGATIONS = 15
STANDARD_ATOM_RADIUS = 9
STANDARD_WAVES = {
    { 0 },
    {STANDARD_DISTANCE_BETWEEN_LIGATIONS / 2, -STANDARD_DISTANCE_BETWEEN_LIGATIONS / 2},
    {STANDARD_DISTANCE_BETWEEN_LIGATIONS, 0, -STANDARD_DISTANCE_BETWEEN_LIGATIONS}
}

-- ORGANIC PLUGIN
ORGANIC_NO_CARBON_LIGATION_DISTANCE = 10
ORGANIC_CARBON_LIGATION_DISTANCE = 0
ORGANIC_ATOM_RADIUS = 10
ORGANIC_BETWEEN_LIGATION_DISTANCE = 2

Error = {
    code = 404,
    message = ""
}

function Error:new(o)
    local obj = o or {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Error:print()
    local str = string.format("%d: %s", self.code, self.message)
    print(str)
end

function MergeTables(table1, table2)
    for _, element in ipairs(table2) do
        table.insert(table1, element)
    end
end

function SplitParams(text, separator)
    if separator == nil then separator = "%s" end

	local params = {}
	for param in text:gmatch("[^"..separator.."]+") do
		table.insert(params, param)
	end
	return params
end

function DegreesToRadians(degrees)
	return math.pi * degrees / 180
end

function HandlePattern(params)
	local pattern, repet = table.unpack(params)

	local pattern_file = io.open(PATTERN_FOLDER .. "/" .. pattern .. PATTERN_EXT, "r")
	if pattern_file == nil then
        return nil, Error.new {
			["message"] = "pattern ["..pattern.."] not found"
		}
	end

	local pattern_content = pattern_file:read("*a")
	pattern_file:close()

	if repet == nil then repet = 1 end

	local pattern_ligations = {}
	for i = 1, repet do
		local pat, err = HandleSectionLigations(pattern_content)
		if err ~= nil then return nil, err end

		for _, l in ipairs(pat) do
			table.insert(pattern_ligations, l)
		end
	end

	return pattern_ligations, nil
end

function HandleLigation(params)
	local ligations = {}

	local angle = tonumber(params[1])

	if angle == nil then
		local pattern_ligations, err = HandlePattern(params)
		if err ~= nil then return nil, err end

		MergeTables(ligations, pattern_ligations)
	else
		local eletrons = ELETRONS_TYPES[params[2]]
		local eletrons_behaviour = params[3]

		if eletrons == nil then
			eletrons = 1
			eletrons_behaviour = params[2]
		end

		local ligation = {
			angle = angle,
			eletrons = eletrons,
			eletrons_behaviour = eletrons_behaviour
		}

		table.insert(ligations, ligation)
	end

	return ligations, nil
end

function HandleSectionTags(section)
	local tags = {}
	for line in section:gmatch("[^%s]+") do
		table.insert(tags, line)
	end
	return tags
end

function HandleSectionLigations(section)
	local ligations = {}

	for line in section:gmatch("[^\n]+") do
		local params = SplitParams(line)

		local ligs, err = HandleLigation(params)
		if err ~= nil then return nil, err end

		for _, lig in ipairs(ligs) do
			table.insert(ligations, lig)
		end
	end

	return ligations, nil
end

function HandleSectionAtoms(section, ligations)
	local atoms = {}

	for line in section:gmatch("[^\n]+") do
		local params = SplitParams(line)

		local symbol = params[1]
		if symbol:match("[A-Z][a-z]?") == nil then
            return nil, Error.new {
				message = ("symbol '" .. params[1] .. "' invalid")
			}
		end

		local start_ligation_index = 1
		local charge = 0
		if params[2]:match("[-|+][0-9]") ~= nil then
			start_ligation_index = 2
			charge = tonumber(params[2])
			if charge == nil then
				return nil, Error.new {
					message = ("charge '" .. charge .. "' invalid")
				}
			end
		end

		local ligs = {}
		for k, v in ipairs(params) do
			if k > start_ligation_index then
				local lig = tonumber(v)
				if lig == nil then
					return nil, Error:new {
						message = ("ligation '" .. lig .. "' invalid")
					}
				end

				if ligations[lig] == nil then
					return nil, Error:new {
						message = "ligation missing for atom (" ..symbol.. ": " ..v.. ")" 
					}
				end

				if ligations[lig]["atoms"] == nil then
					ligations[lig]["atoms"] = { #atoms + 1 }
				else
					table.insert(ligations[lig]["atoms"], #atoms + 1)
				end

				table.insert(ligs, lig)
			end
		end

		local atom = {
			symbol = symbol,
			charge = charge,
			ligations = ligs
		}
		table.insert(atoms, atom)
	end

	return atoms, nil
end

function HandleSections(content)
    local sections = SplitParams(content, "$")

    local sections_tags,
          section_atoms,
          section_ligations = table.unpack(sections)

    local tags, err = HandleSectionTags(sections_tags)
    if err ~= nil then return nil, err end

    local ligations, err = HandleSectionLigations(section_ligations)
	if err ~= nil then return nil, err end

	local atoms, err = HandleSectionAtoms(section_atoms, ligations)
    if err ~= nil then return nil, err end

    return { tags, ligations, atoms }, nil
end

Svg = {
    content = ""
}

function Svg:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Svg:line(ax, ay, bx, by, className)
    if className == nil then className = 'svg-ligation' end

    local s = string.format('<line class="%s" x1="%g" y1="%g" x2="%g" y2="%g"></line>', className, ax, ay, bx, by)
    self.content = self.content .. s
end

function Svg:circle(x, y, r)
    local s = string.format('<circle class="svg-eletrons" cx="%g" cy="%g" r="%g"></circle>', x, y, r)
    self.content = self.content .. s
end

function Svg:text(symbol, x, y)
    local s = string.format('<text class="svg-element svg-element-%s" x="%g" y="%g">%s</text>', symbol, x, y, symbol)
    self.content = self.content .. s
end

function Svg:subtext(symbol, x, y)
    local s = string.format('<circle class="svg-element-charge-border" cx="%g" cy="%g"/><text class="svg-element-charge" x="%g" y="%g">%s</text>', x, y, x, y, symbol)
    self.content = self.content .. s
end

function Svg:build(width, height)
    local css_file = io.open(Z1_CSS, "r")
	if css_file == nil then
		return nil, Error:new {
            ["message"] = "Template 'z1.css' não encontrado",
        }
	end

    local css = css_file:read("*a")
    css = css:gsub("[\n|\t]","")
    io.close(css_file)

    local svg_template_file = io.open(Z1_TEMP_SVG, "r")
	if svg_template_file == nil then
        return nil, Error:new {
            ["message"] = "Template 'z1.temp.svg' não encontrado",
        }
	end

    local svg_template = svg_template_file:read("*a")
    io.close(svg_template_file)

    local svg = string.format(svg_template, width, height, css, self.content)
    return svg, nil
end

Plugin = {
    svg = Svg:new()
}

function Plugin:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Plugin:build()
    self:calcAtomsPosition()

    local err = self:measureBounds()
    if err ~= nil then return nil, err end

    local err = self:drawAtom()
    if err ~= nil then return nil, err end

    local err = self:drawLigation()
    if err ~= nil then return nil, err end

    local svg_content, err = self.svg:build(self.width, self.height)
    return svg_content, err
end

function Plugin:calcAtomsPosition(idx, dad_atom, ligation)
    if idx == nil then idx = 1 end
    if self.already == nil then self.already = {} end

    for k, v in ipairs(self.already) do
        if idx == v then
            return
        end
    end
    
    local x = 0
    local y = 0

    if dad_atom ~= nil then
        local angle = ligation["angle"]
        local angle_rad = math.pi * angle / 180
        x = dad_atom["x"] + math.cos(angle_rad) * STANDARD_LIGATION_SIZE
        y = dad_atom["y"] + math.sin(angle_rad) * STANDARD_LIGATION_SIZE
    end

    self.atoms[idx]["x"] = x
    self.atoms[idx]["y"] = y
    table.insert(self.already, idx)
    
    for _, lig in ipairs(self.ligations) do
        if lig["atoms"][1] == idx then
            self:calcAtomsPosition(lig["atoms"][2], self.atoms[idx], lig)
        end
    end
end

function Plugin:drawAtom()
    return Error:new {
        message = "Method drawAtom not Implemented"
    }
end

function Plugin:drawLigation()
    return Error:new {
        message = "Method drawLigation not Implemented"
    }
end

function Plugin:measureBounds()
    local min_x = 0
    local min_y = 0
    local max_x = 0
    local max_y = 0
    
    for _, atom in ipairs(self.atoms) do
        local x = atom["x"]
        local y = atom["y"]
    
        if atom["symbol"] == "X" then
            goto continue
        end
    
        if x > max_x then max_x = x end
        if y > max_y then max_y = y end
        if x < min_x then min_x = x end
        if y < min_y then min_y = y end
    
        ::continue::
    end
    
    local cwidth = max_x + -min_x
    local cheight = max_y + -min_y
    
    self.width = BORDER * 2 + cwidth
    self.height = BORDER * 2 + cheight
    
    self.center_x = BORDER + math.abs(min_x)
    self.center_y = BORDER + math.abs(min_y)

    return nil
end

StandardPlugin = Plugin:new {}

function StandardPlugin:drawAtom()
    for _, atom in ipairs(self.atoms) do
        local symbol = atom["symbol"]
        local x = self.center_x + atom["x"]
        local y = self.center_y + atom["y"]

        if symbol == "X" then
            goto continue
        end

        self.svg:text(atom["symbol"], x, y)

        local charge = atom["charge"]

        if charge ~= 0 then
            if charge == 1 then
                charge = "+"
            end
            if charge == -1 then
                charge = "-"
            end
            self.svg:subtext(charge, x + STANDARD_ATOM_RADIUS, y - STANDARD_ATOM_RADIUS)
        end

        ::continue::
    end

    return nil
end

function StandardPlugin:drawLigation()
    for _, ligation in ipairs(self.ligations) do
        local from_atom = self.atoms[ligation["atoms"][1]]
        local to_atom = self.atoms[ligation["atoms"][2]]

        if to_atom["symbol"] == "X" then
            goto continue
        end

        local ax = self.center_x + from_atom["x"]
        local ay = self.center_y + from_atom["y"]
        local bx = self.center_x + to_atom["x"]
        local by = self.center_y + to_atom["y"]

        local angles = STANDARD_WAVES[ligation["eletrons"]]

        local a_angle = math.atan((by - ay), (bx - ax))
        local b_angle = math.pi + a_angle

        if ligation["eletrons_behaviour"] ~= "i" then
            for _, angle in ipairs(angles) do
                local nax = ax + math.cos(a_angle - (math.pi * angle / 180)) * STANDARD_ATOM_RADIUS
                local nay = ay + math.sin(a_angle - (math.pi * angle / 180)) * STANDARD_ATOM_RADIUS

                local nbx = bx + math.cos(b_angle + (math.pi * angle / 180)) * STANDARD_ATOM_RADIUS
                local nby = by + math.sin(b_angle + (math.pi * angle / 180)) * STANDARD_ATOM_RADIUS

                self.svg:line(nax, nay, nbx, nby)
            end
        end

        ::continue::
    end

    return nil
end

OrganicPlugin = Plugin:new{}

function OrganicPlugin:measureBounds()
    local min_x = 0
    local min_y = 0
    local max_x = 0
    local max_y = 0

    for idx, atom in ipairs(self.atoms) do
        local x = atom["x"]
        local y = atom["y"]

        if atom["symbol"] == "X" then
            goto continue
        end

        if atom["symbol"] == "H" and atom["charge"] == 0 then
            for _, lig in ipairs(self.ligations) do
                if lig["atoms"][2] == idx and self.atoms[lig["atoms"][1]]["symbol"] == "C" then
                    local has_o = false
                    for _, c_ligation in ipairs(self.atoms[lig["atoms"][1]]["ligations"]) do
                        if self.atoms[c_ligation]["symbol"] == "O" then
                            has_o = true
                            break
                        end
                    end

                    if not has_o then
                        goto continue
                    end

                end
            end
        end

        if x > max_x then max_x = x end
        if y > max_y then max_y = y end
        if x < min_x then min_x = x end
        if y < min_y then min_y = y end

        ::continue::
    end

    local cwidth = max_x + -min_x
    local cheight = max_y + -min_y

    self.width = BORDER * 2 + cwidth
    self.height = BORDER * 2 + cheight

    self.center_x = BORDER + math.abs(min_x)
    self.center_y = BORDER + math.abs(min_y)
end

function OrganicPlugin:drawAtom()
    for idx, atom in ipairs(self.atoms) do
        local symbol = atom["symbol"]
        local charge = atom["charge"]
        local x = self.center_x + atom["x"]
        local y = self.center_y + atom["y"]

        if charge ~= 0 then
            if charge == 1 then
                charge = "+"
            end
            if charge == -1 then
                charge = "-"
            end
            self.svg:subtext(charge, x + ORGANIC_ATOM_RADIUS, y - ORGANIC_ATOM_RADIUS)
        end

        if symbol == "C" then
            goto continue
        end

        if symbol == "H" and charge == 0 then
            for _, lig in ipairs(self.ligations) do
                if lig["atoms"][2] == idx and self.atoms[lig["atoms"][1]]["symbol"] == "C" then
                    local has_o = false
                    for _, c_ligation in ipairs(self.atoms[lig["atoms"][1]]["ligations"]) do
                        if self.atoms[c_ligation]["symbol"] == "O" then
                            has_o = true
                            break
                        end
                    end

                    if not has_o then
                        goto continue
                    end

                end
            end
        end

        self.svg:text(atom["symbol"], x, y)
        ::continue::
    end
end

function OrganicPlugin:drawLigation()
    for _, ligation in ipairs(self.ligations) do
        local from_atom = self.atoms[ligation["atoms"][1]]
        local to_atom = self.atoms[ligation["atoms"][2]]

        if to_atom["symbol"] == "H" and to_atom["charge"] == 0 and from_atom["symbol"] == "C" or
            ligation["eletrons_behaviour"] == "i" then

            local has_o = false
            for idx, lig in ipairs(self.ligations) do
                if lig["atoms"][1] == ligation["atoms"][1] and self.atoms[lig["atoms"][2]]["symbol"] == "O" then
                    has_o = true
                    break
                end
            end
    
            if not has_o then
                goto continue
            end
    
        end

        local ax = self.center_x + from_atom["x"]
        local ay = self.center_y + from_atom["y"]
        local bx = self.center_x + to_atom["x"]
        local by = self.center_y + to_atom["y"]

        local a_angle = math.atan((by - ay), (bx - ax))
        local b_angle = math.pi + a_angle

        if ligation["eletrons"] == 1 then
            local nax = ax + math.cos(a_angle) * ORGANIC_CARBON_LIGATION_DISTANCE
            local nay = ay + math.sin(a_angle) * ORGANIC_CARBON_LIGATION_DISTANCE
            if from_atom["symbol"] ~= "C" then
                nax = nax + math.cos(a_angle) * ORGANIC_NO_CARBON_LIGATION_DISTANCE
                nay = nay + math.sin(a_angle) * ORGANIC_NO_CARBON_LIGATION_DISTANCE
            end

            local nbx = bx + math.cos(b_angle) * ORGANIC_CARBON_LIGATION_DISTANCE
            local nby = by + math.sin(b_angle) * ORGANIC_CARBON_LIGATION_DISTANCE
            if to_atom["symbol"] ~= "C" then
                nbx = nbx + math.cos(b_angle) * ORGANIC_NO_CARBON_LIGATION_DISTANCE
                nby = nby + math.sin(b_angle) * ORGANIC_NO_CARBON_LIGATION_DISTANCE
            end

            self.svg:line(nax, nay, nbx, nby)
        elseif ligation["eletrons"] == 2 then
            local pax = ax + math.cos(a_angle)
            local pay = ay + math.sin(a_angle)
            if from_atom["symbol"] ~= "C" then
                pax = pax + math.cos(a_angle) * ORGANIC_NO_CARBON_LIGATION_DISTANCE
                pay = pay + math.sin(a_angle) * ORGANIC_NO_CARBON_LIGATION_DISTANCE
            end

            local pbx = bx + math.cos(b_angle)
            local pby = by + math.sin(b_angle)
            if to_atom["symbol"] ~= "C" then
                pbx = pbx + math.cos(b_angle) * ORGANIC_NO_CARBON_LIGATION_DISTANCE
                pby = pby + math.sin(b_angle) * ORGANIC_NO_CARBON_LIGATION_DISTANCE
            end

            local nax = pax + math.cos(a_angle - 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE
            local nay = pay + math.sin(a_angle - 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE

            local nbx = pbx + math.cos(b_angle + 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE
            local nby = pby + math.sin(b_angle + 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE

            self.svg:line(nax, nay, nbx, nby)

            nax = pax + math.cos(a_angle + 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE
            nay = pay + math.sin(a_angle + 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE

            nbx = pbx + math.cos(b_angle - 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE
            nby = pby + math.sin(b_angle - 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE

            self.svg:line(nax, nay, nbx, nby)
        elseif ligation["eletrons"] == 3 then
            local pax = ax + math.cos(a_angle)
            local pay = ay + math.sin(a_angle)
            if from_atom["symbol"] ~= "C" then
                pax = pax + math.cos(a_angle) * ORGANIC_NO_CARBON_LIGATION_DISTANCE
                pay = pay + math.sin(a_angle) * ORGANIC_NO_CARBON_LIGATION_DISTANCE
            end

            local pbx = bx + math.cos(b_angle)
            local pby = by + math.sin(b_angle)
            if to_atom["symbol"] ~= "C" then
                pbx = pbx + math.cos(b_angle) * ORGANIC_NO_CARBON_LIGATION_DISTANCE
                pby = pby + math.sin(b_angle) * ORGANIC_NO_CARBON_LIGATION_DISTANCE
            end

            local nax = pax + math.cos(a_angle - 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE
            local nay = pay + math.sin(a_angle - 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE

            local nbx = pbx + math.cos(b_angle + 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE
            local nby = pby + math.sin(b_angle + 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE

            self.svg:line(nax, nay, nbx, nby)

            nax = pax + math.cos(a_angle + 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE
            nay = pay + math.sin(a_angle + 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE

            nbx = pbx + math.cos(b_angle - 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE
            nby = pby + math.sin(b_angle - 90) * ORGANIC_BETWEEN_LIGATION_DISTANCE

            self.svg:line(nax, nay, nbx, nby)

            local nax = pax
            local nay = pay

            local nbx = pbx
            local nby = pby

            self.svg:line(nax, nay, nbx, nby)
        end

        ::continue::
    end
end

local export_type = arg[1]
local file_name = arg[2]
local out_file_name = OUT_SVG_FILE
if arg[3] then
    out_file_name = arg[3]
end

local f = io.open(file_name, "r")
local content = f:read("*a")
f:close()

local hadled_sections, err = HandleSections(content)
if err ~= nil then
    err:print()
    os.exit(1)
end

local tags, ligations, atoms = table.unpack(hadled_sections)

PLUGINS = {
    ["standard"] = StandardPlugin,
    ["organic"] = OrganicPlugin
}

local plugin = PLUGINS[export_type]:new {
    ["tags"] = tags,
    ["atoms"] = atoms,
    ["ligations"] = ligations
}

local svg_content, err = plugin:build()
if err ~= nil then
    err:print()
    os.exit(1)
end

local f = io.open(out_file_name, "w")
local content = f:write(svg_content)
f:close()