require "z1.tools.svg"
require "z1.tools.error"
require "z1.plugins.plugin"

local distance_between_eletrons = 20

LewisPlugin = Plugin:new {
    eletrons_radius = 1,
    lewis_atom_radius = 9,

    lewis_waves = {
        { 0 },
        { distance_between_eletrons/2, -distance_between_eletrons/2 },
        { distance_between_eletrons, 0, -distance_between_eletrons }
    }
}

function LewisPlugin:drawAtom(atoms)
    for _, atom in ipairs(atoms) do
        local symbol = atom["symbol"]
        local x = self.center_x + atom["x"]
        local y = self.center_y + atom["y"]

        if symbol == "X" then goto continue end

        self.svg:text(atom["symbol"], x, y)

        local charge = atom["charge"]

        if charge ~= 0 then
            if charge == 1 then charge = "+" end
            if charge == -1 then charge = "-" end
            self.svg:subtext(charge, x + self.lewis_atom_radius, y - self.lewis_atom_radius)
        end

        ::continue::
    end
end

function LewisPlugin:drawLigation(atoms, ligations)
    for _, ligation in ipairs(ligations) do
        local from_atom = atoms[ligation["atoms"][1]]
        local to_atom = atoms[ligation["atoms"][2]]

        local ax = self.center_x + from_atom["x"]
        local ay = self.center_y + from_atom["y"]
        local bx = self.center_x + to_atom["x"]
        local by = self.center_y + to_atom["y"]

        local angles = self.lewis_waves[ ligation["eletrons"] ]

        local a_angle = math.atan((by - ay), (bx - ax))
        local b_angle = math.pi + a_angle

        if ligation["eletrons_behaviour"] ~= "i" then
            for _, angle in ipairs(angles) do
                local nax = ax + math.cos(a_angle - (math.pi * angle / 180)) * self.lewis_atom_radius
                local nay = ay + math.sin(a_angle - (math.pi * angle / 180)) * self.lewis_atom_radius
                self.svg:circle(nax, nay, self.eletrons_radius)

                if to_atom["symbol"] ~= "X" then
                    local nbx = bx + math.cos(b_angle + (math.pi * angle / 180)) * self.lewis_atom_radius
                    local nby = by + math.sin(b_angle + (math.pi * angle / 180)) * self.lewis_atom_radius
                    self.svg:circle(nbx, nby, self.eletrons_radius)
                end
            end
        end

        ::continue::
    end
end