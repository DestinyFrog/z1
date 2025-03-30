require "z1.tools.svg"
require "z1.sectioner"

local f = io.open(arg[2], "r")
local content = f:read("*a")
f:close()

local hadled_sections, err = HandleSections(content)
if err ~= nil then
    err:print()
    os.exit(1)
end

local tags, ligations, atoms = table.unpack(hadled_sections)

local already = {}

local function calc_atoms_position(idx, dad_atom, ligation)
    for k, v in ipairs(already) do
        if idx == v then
            return
        end
    end

    local x = 0
    local y = 0

    if dad_atom ~= nil then
        local angle = ligation["angle"]
        local angle_rad = math.pi * angle / 180
        x = dad_atom["x"] + math.cos(angle_rad) * LIGATION_SIZE
        y = dad_atom["y"] + math.sin(angle_rad) * LIGATION_SIZE
    end

    atoms[idx]["x"] = x
    atoms[idx]["y"] = y
    table.insert(already, idx)

    for _, lig in ipairs(ligations) do
        if lig["atoms"][1] == idx then
            if atoms[lig["atoms"][2]] == nil then
                return Error:new{
                    message = "ligation destiny not found at ligation on atom (" .. atoms[idx]["symbol"] .. ": " .. idx ..
                        ")"
                }
            end

            err = calc_atoms_position(lig["atoms"][2], atoms[idx], lig)
            if err ~= nil then
                return err
            end
        end
    end

    return nil
end

err = calc_atoms_position(1)
if err ~= nil then
    err:print()
    os.exit(1)
end

local export_type = arg[1]

local plugin = nil
if export_type == "lewis" then
    require("z1.plugins.lewis")
    plugin = LewisPlugin:new{
        ["tags"] = tags,
        ["atoms"] = atoms,
        ["ligations"] = ligations
    }
elseif export_type == "organic" then
    require("z1.plugins.organic")
    plugin = OrganicPlugin:new{
        ["tags"] = tags,
        ["atoms"] = atoms,
        ["ligations"] = ligations
    }
elseif export_type == "standard" then
    require("z1.plugins.standard")
    plugin = StandardPlugin:new{
        ["tags"] = tags,
        ["atoms"] = atoms,
        ["ligations"] = ligations
    }
end

local svg_content, err = plugin:build()
if err ~= nil then
    err:print()
    os.exit(1)
end

local f = io.open("out.svg", "w")
local content = f:write(svg_content)
f:close()
