require "z1.tools.svg"
require "z1.tools.error"

Plugin = {
    BORDER = 20,
    distance_between_ligations = 16,
    svg = Svg:new()
}

function Plugin:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.waves = {
        {0},
        {self.distance_between_ligations / 2, -self.distance_between_ligations / 2},
        {self.distance_between_ligations, 0, -self.distance_between_ligations}
    }

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
        x = dad_atom["x"] + math.cos(angle_rad) * LIGATION_SIZE
        y = dad_atom["y"] + math.sin(angle_rad) * LIGATION_SIZE
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
    
    self.width = self.BORDER * 2 + cwidth
    self.height = self.BORDER * 2 + cheight
    
    self.center_x = self.BORDER + math.abs(min_x)
    self.center_y = self.BORDER + math.abs(min_y)

    return nil
end