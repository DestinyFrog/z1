require "z1.tools.svg"
require "z1.tools.error"
require "z1.plugins.plugin"

NO_CARBON_LIGATION_DISTANCE = 6
CARBON_LIGATION_DISTANCE = 0

C_LIGATION_DISTANCES = 3

OrganicPlugin = Plugin:new {
    ATOM_RADIUS = 7,
    C_ATOM_RADIUS = 1,

    carbon_ligation_distance = 0,
    carbon_waves = {{0}, {90, -90}, {90, 0, 90}}
}

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
                    goto continue
                end
            end
        end

        if x > max_x then
            max_x = x
        end
        if y > max_y then
            max_y = y
        end
        if x < min_x then
            min_x = x
        end
        if y < min_y then
            min_y = y
        end

        ::continue::
    end

    local cwidth = max_x + -min_x
    local cheight = max_y + -min_y

    self.width = self.BORDER * 2 + cwidth
    self.height = self.BORDER * 2 + cheight

    self.center_x = self.BORDER + math.abs(min_x)
    self.center_y = self.BORDER + math.abs(min_y)
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
            self.svg:subtext(charge, x + self.ATOM_RADIUS, y - self.ATOM_RADIUS)
        end

        if symbol == "C" then
            goto continue
        end

        if symbol == "H" and charge == 0 then
            for _, lig in ipairs(self.ligations) do
                if lig["atoms"][2] == idx and self.atoms[lig["atoms"][1]]["symbol"] == "C" then
                    goto continue
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
            ligation["eletrons_behaviour"] == "i"        
        then goto continue end

        local ax = self.center_x + from_atom["x"]
        local ay = self.center_y + from_atom["y"]
        local bx = self.center_x + to_atom["x"]
        local by = self.center_y + to_atom["y"]

        local angles = self.carbon_waves[ligation["eletrons"]]

        local a_angle = math.atan((by - ay), (bx - ax))
        local b_angle = math.pi + a_angle

        if ligation["eletrons"] == 1 then
            local nax = ax + math.cos(a_angle) * -0.5
            local nay = ay + math.sin(a_angle) * -0.5
            if from_atom["symbol"] ~= "C" then
                nax = nax + math.cos(a_angle) * NO_CARBON_LIGATION_DISTANCE
                nay = nay + math.sin(a_angle) * NO_CARBON_LIGATION_DISTANCE
            end

            local nbx = bx + math.cos(b_angle) * -0.5
            local nby = by + math.sin(b_angle) * -0.5
            if to_atom["symbol"] ~= "C" then
                nbx = nbx + math.cos(b_angle) * NO_CARBON_LIGATION_DISTANCE
                nby = nby + math.sin(b_angle) * NO_CARBON_LIGATION_DISTANCE
            end

            self.svg:line(nax, nay, nbx, nby)
        elseif ligation["eletrons"] == 2 then
            local pax = ax + math.cos(a_angle)
            local pay = ay + math.sin(a_angle)
            if from_atom["symbol"] ~= "C" then
                pax = pax + math.cos(a_angle) * NO_CARBON_LIGATION_DISTANCE
                pay = pay + math.sin(a_angle) * NO_CARBON_LIGATION_DISTANCE
            end

            local pbx = bx + math.cos(b_angle)
            local pby = by + math.sin(b_angle)
            if to_atom["symbol"] ~= "C" then
                pbx = pbx + math.cos(b_angle) * NO_CARBON_LIGATION_DISTANCE
                pby = pby + math.sin(b_angle) * NO_CARBON_LIGATION_DISTANCE
            end

            local nax = pax + math.cos(a_angle - 90)
            local nay = pay + math.sin(a_angle - 90)

            local nbx = pbx + math.cos(b_angle + 90)
            local nby = pby + math.sin(b_angle + 90)

            self.svg:line(nax, nay, nbx, nby)

            nax = pax + math.cos(a_angle + 90)
            nay = pay + math.sin(a_angle + 90)
            
            nbx = pbx + math.cos(b_angle - 90)
            nby = pby + math.sin(b_angle - 90)

            self.svg:line(nax, nay, nbx, nby)
        elseif ligation["eletrons"] == 3 then
            local pax = ax + math.cos(a_angle)
            local pay = ay + math.sin(a_angle)
            if from_atom["symbol"] ~= "C" then
                pax = pax + math.cos(a_angle) * NO_CARBON_LIGATION_DISTANCE
                pay = pay + math.sin(a_angle) * NO_CARBON_LIGATION_DISTANCE
            end

            local pbx = bx + math.cos(b_angle)
            local pby = by + math.sin(b_angle)
            if to_atom["symbol"] ~= "C" then
                pbx = pbx + math.cos(b_angle) * NO_CARBON_LIGATION_DISTANCE
                pby = pby + math.sin(b_angle) * NO_CARBON_LIGATION_DISTANCE
            end

            local nax = pax + math.cos(a_angle - 90)
            local nay = pay + math.sin(a_angle - 90)

            local nbx = pbx + math.cos(b_angle + 90)
            local nby = pby + math.sin(b_angle + 90)

            self.svg:line(nax, nay, nbx, nby)

            nax = pax + math.cos(a_angle + 90)
            nay = pay + math.sin(a_angle + 90)
            
            nbx = pbx + math.cos(b_angle - 90)
            nby = pby + math.sin(b_angle - 90)

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