require "z1.tools.svg"
require "z1.sectioner"
require "z1.configuration"
local sqlite3 = require "lsqlite3"

local export_type = arg[1]
local uid = arg[2]

local query = "SELECT z1 FROM molecula WHERE uid = ?"

local db = sqlite3.open(DATABASE)
local stmt = assert( db:prepare(query) )
stmt:bind_values(uid)
stmt:step()
local content = stmt:get_uvalues()
stmt:finalize()

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

print(svg_content)