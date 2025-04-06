require "z1.tools.error"
require "z1.configuration"

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