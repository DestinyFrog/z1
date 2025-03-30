
Error = {
    code = 404,
    message = ""
}

function Error:new(o)
    local obj = o or {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Error:print()
    local str = string.format("%d: %s", self.code, self.message)
    print(str)
end