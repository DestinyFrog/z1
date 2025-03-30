require "z1.tools.svg"
require "z1.sectioner"
require "z1.configuration"
local sqlite3 = require "lsqlite3"

local uid = arg[2]
local db = sqlite3.open(DATABASE)

local stmt = assert( db:prepare("SELECT z1 FROM molecula WHERE uid = ?") )
stmt:bind_values(uid)
stmt:step()
local content = stmt:get_uvalues()
stmt:finalize()

local hadled_sections, err = HandleSections(content)
if err ~= nil then
	err:print()
	os.exit(1)
end

tags, ligations, atoms = table.unpack(hadled_sections)

local export_type = arg[1]

local plugin = nil

if export_type == "organic" then
	require("z1.plugins.organic")
	plugin = OrganicPlugin
elseif export_type == "lewis" then
	require("z1.plugins.lewis")
	plugin = LewisPlugin
else
	require("z1.plugins.standard")
	plugin = StandardPlugin:new {
		["tags"] = tags,
		["atoms"] = atoms,
		["ligations"] = ligations
	}
end

local svg_content, err = plugin:build(tags, atoms, ligations)
if err ~= nil then
	err:print()
	os.exit(1)
end

print(svg_content)