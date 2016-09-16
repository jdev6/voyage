local _M = {
    center = {
        x = love.graphics.getWidth()/2,
        y = love.graphics.getHeight()/2
    }
} --module

local l = love.graphics.line
local r = love.graphics.rectangle

function _M.rectangle(mode, x, y, width, height, rx, ry, segments)
    local x1, y1 = x, y
    local x2, y2 = x+width, y
    local x3, y3 = x+width, y+height
    local x4, y4 = x, y+height

    r(mode,x,y,width,height,rx,ry,segments)
    _M.line(x1,y1, x2,y2, x3,y3, x4,y4, x1,y1)
end

function _M.line(...)
    local params = {...}

    if type(params[1]) == "table" then
        params = params[1]
    end

    if #params < 4 then
        --not enough arguments
        error("4 arguments at least expected")
    end
    if #params % 2 == 1 then
        --odd number of arguments
        error("argument count must be an even number")
    end

    l(params)

    for i=1, #params, 2 do
        l(params[i], params[i+1], _M.center.x, _M.center.y)
    end

end

function _M.setCenter(x,y)
    _M.center.x = x
    _M.center.y = y
end

return _M