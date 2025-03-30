require "z1.tools.error"
require "z1.configuration"
require "z1.tools.util"

ELETRONS_TYPES = {
	["-"] = 1,
	["="] = 2,
	["%"] = 3
}

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