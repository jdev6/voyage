local class = require("lib.middleclass")
local tween = require("lib.tween")
local delay = require("lib.delay")

local Entity = class('Entity')

--Constants
local g = love.graphics
local MOVE_SPEED = 0.05
local ENEMY_SPEED = 1
local DISAPPEAR_SPEED = 0.5
local W,H = g.getDimensions()

function math.randomchoice(t) --Selects a random item from a table
    local keys = {}
    for key, value in pairs(t) do
        keys[#keys+1] = key --Store keys in another table
    end
    local index = keys[math.random(1, #keys)]
    return t[index]
end

function Entity:initialize(stage, img, diff, startY, endY)
    self.stage = stage
    self.diff = diff

    self.img = img

    self.w, self.h = img:getDimensions()

    self.img:setFilter("nearest", "nearest")

    self.opacity = 255

    self.scale = 1
    self.moving = 0

    if startY then
        --enemies
        self.moving = 1
        self.scale = 0.1
        self.y = startY
        
        self.x = W/2

        self.tween = tween.new(ENEMY_SPEED, self, {y = endY, x = self.stage*self.diff+20 + self.w/2, scale = 1, moving = 0},
            --math.randomchoice(tween.easing)
            'linear'
        )

        delay.timeout(ENEMY_SPEED, function(self)
            self.disappearing = true
            self.tween = tween.new(DISAPPEAR_SPEED, self, {opacity = 0})
        end, self)

        self.scale = 0
    end

    self.y = self.y or H-120
    --self.x = self.x or 

end

function Entity:draw(centerX, centerY)
    local x, y = self:getX(), self:getY()

    --difference between center coords and entity coords
    local dX = x - centerX
    local dY = y - centerY

    local R,G,B = g.getColor()
    g.setColor(R,G,B,self.opacity)

    --local scale = math.max(self.scale, self.scale*intensity)

    g.draw(self.img, x, y, -math.atan2(dX, dY), self.scale, self.scale, self.w/2, self.h/2)
end

function Entity:move(target)
    if target >= 0 and target < 8 and self.moving == 0 then
        --move
        self.moving = 1
        self.tween = tween.new(MOVE_SPEED, self, {stage = target, moving = 0})
    end
end

function Entity:update(dt)
    if self.tween then
        self.tween:update(dt)
    end
end

function Entity:getX()
    return (self.x or self.stage*self.diff+20 + self.w/2) + 5
end

function Entity:getY()
    return self.y
end

return Entity