require "z1.configuration"
require "z1.sectioner"

require "z1.plugins.standard"
require "z1.plugins.organic"

local export_type = arg[1]
local file_name = arg[2]

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

local f = io.open(OUT_SVG_FILE, "w")
local content = f:write(svg_content)
f:close()