
function MergeTables(table1, table2)
    for _, element in ipairs(table2) do
        table.insert(table1, element)
    end
end

function SplitParams(text, separator)
    if separator == nil then separator = "%s" end

	local params = {}
	for param in text:gmatch("[^"..separator.."]+") do
		table.insert(params, param)
	end
	return params
end

function DegreesToRadians(degrees)
	return math.pi * degrees / 180
end