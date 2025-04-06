local sqlite3 = require "lsqlite3"
local uuid = require "uuid"
require "z1.configuration"

uuid.set_rng(uuid.rng.urandom())

local db = sqlite3.open(DATABASE)

local sql = [[
    DROP TABLE IF EXISTS molecula;
    CREATE TABLE IF NOT EXISTS molecula (
        `id` INTEGER PRIMARY KEY,
        `uid` TEXT UNIQUE,
        `name` TEXT,
        `organic` TEXT DEFAULT 'inorganic',
        `z1` TEXT,
        `term` TEXT
    )
]]

db:exec(sql)

local names = {}
local comando = string.format('ls "%s"', EXAMPLES_DIR)
local handle = io.popen(comando)
if handle then
    for nomeArquivo in handle:lines() do
        table.insert(names, nomeArquivo)
    end
    handle:close()
else
    print("Erro ao acessar a pasta.")
end

local moleculas = {}
for k, name in ipairs(names) do
    local file = io.open(EXAMPLES_DIR .. "/" .. name, "r")
    if file == nil then
        print(name .. " not found")
        os.exit(0)
    end
    local content = file:read("*a")
    file:close()

    -- NAME
    local rname = name:gsub(".z1", "")

    -- TERM
    local terms = {}

    local params = {}
    for param in content:gmatch("[^$]+") do
        table.insert(params, param)
    end
    local section = params[2]
    for line in section:gmatch("[^\n]+") do
        local s = {}
        for l in line:gmatch("[^%s]+") do
            table.insert(s, l)
        end

        if s[1] ~= 'X' then
            table.insert(terms, s[1])
        end
    end

    -- ORGANIC
    local organic = 'organic'
    if string.find(params[1], "inorganic") then
        organic = 'inorganic'
    end

    table.sort(terms, function(a, b) return a:upper() < b:upper() end)
    local term = table.concat(terms, "")

    local molecula = {
        uid = uuid.v4(),
        name = rname,
        z1 = content,
        organic = organic,
        term = term
    }

    table.insert(moleculas, molecula)
end

for _, molecula in  ipairs(moleculas) do
    local sql = [[
        INSERT INTO molecula (uid, name, z1, organic, term)
        VALUES (:uid, :name, :z1, :organic, :term)
    ]]
    
    local stmt = assert(db:prepare(sql))

    stmt:bind_names(molecula)
    stmt:step()
    stmt:reset()

    print("INSERT: " .. molecula["name"])
end