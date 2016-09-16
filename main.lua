local ray    = require("lib.ray")
local shack  = require("lib.shack")
local Entity = require("entity")
local delay  = require("lib.delay")
local audio  = require("lib.wave")
local http   = require("socket.http")
local ltn12  = require("ltn12")

local g = love.graphics
local fs = love.filesystem
local rand = love.math.random
local fmt = string.format

--Constants
local W,H = g.getDimensions()
local LINE_COLOR    = {0,0,200}
local SHIP_COLOR    = {0,200,0}
local ENEMY_COLOR   = {200,0,0}
local POWERUP_COLOR = {200,200,0}
local POWERUP_SPEED = 2
local STAGE_DIFF    = (W-20)/8 --segment length
local POWERUP_BONUS = 50
local NODEATH_TIME  = 2

local speed = 1

local enemies = {}

local enemyImg
local gameOverImg
local keysImg

local drawGameOver = false
local gameOverToggler
local canRestart = false

local playing = false

local colorScheme = 0

local function changeColors(times)
    for i=1,times do
        print 'time'
        LINE_COLOR, SHIP_COLOR, ENEMY_COLOR, POWERUP_COLOR = POWERUP_COLOR, ENEMY_COLOR, LINE_COLOR, SHIP_COLOR
    end
    colorScheme = (colorScheme + times) % 4
end

local function spawnEnemy()
    local stage = rand(0,7)

    table.insert(enemies, Entity:new(stage, enemyImg, STAGE_DIFF, ray.center.y, H-120))
    if rand(0,14) == 0 then
        --power up!
        enemies[#enemies].powerup = true
    end
end

local hiScore = 0
local score = 0

local ship

local sounds = {}

local VERSION_CHECK_URL = "https://jdev6.github.io/voyage-version"
local VERSION = "1.0"
local outdated = false

function love.load()

    io.stdout:setvbuf("line")

    --LOOK FOR UPDATES
    
    local resp = {}

    local r, c, h, s = http.request {
        url = VERSION_CHECK_URL,
        sink = ltn12.sink.table(resp)
    }

    local v = resp[1]
    
    if v then
        print(fmt("Current version: %s\nLatest version: %s", VERSION, v))
        if v ~= VERSION then
            outdated = true
        end
    else
        print("Can't check for version")
    end

    font = g.newFont("8bitoperator.ttf", 14)

    sounds.gameOver = love.audio.newSource("death.mp3", "static")
    sounds.gameOver:setVolume(0.5)
    sounds.powerup  = love.audio.newSource("powerup.mp3", "static")
    sounds.powerup:setVolume(0.5)
    sounds.bgloop   = audio
        :newSource("bgloop.mp3", "stream")
        :parse()
        :setLooping(true)
        :setIntensity(100)

    love.audio.setVolume(0.5)

    if fs.exists("hiscore") then
        hiScore = tonumber(fs.read("hiscore"), 10) or 0
    else
        hiScore = 0
    end

    if fs.exists("colorscheme") then
        local color = tonumber(fs.read("colorscheme"), 10) or 0
        changeColors(color)
    end

    shack:setDimensions(W, H)
    ray.setCenter(W/2,H/2-100)

    --create ship
    ship = Entity:new(rand(0, 7), g.newImage("ship.png"), STAGE_DIFF)
    ship.nodeathTimer = 0

    enemyImg = g.newImage("enemy.png")
    gameOverImg = g.newImage("gameover.png")
    keysImg = g.newImage("keys.png")
end

local enemyTimer = 0
local enemyTimerMax = 0.1

function love.update(dt)
    shack:update(dt)

    dt = dt * speed --multiply delta by game speed

    delay.update(dt)

    if not gameOver then
        ship:update(dt)
        sounds.bgloop:update(dt)

        if ship.nodeathTimer > 0 then
            --has powerup active
            ship.nodeathTimer = ship.nodeathTimer - dt
            shack:setShear(rand(-1,1),rand(-1,1))
            --shack:shake(10)
        end
        
        if playing then
            score = score + dt
        end
        
        for _,e in pairs(enemies) do
            --update enemies
            e:update(dt)

            if not e.caught and e.moving <= 0.05 and not e.disappearing and e.stage == ship.stage then
                e.caught = true

                if e.powerup then
                    --get powerup
                    print 'powerup'
                    shack:setScale(1.5)
                    shack:rotate(0.1)
                    sounds.powerup:play()

                    ray.setCenter(W/2, H/2-50)

                    speed = POWERUP_SPEED

                    local t = speed * NODEATH_TIME

                    ship.nodeathTimer = t

                    --zoom in when powerup ends

                    if ship.powerupEndTimeout then
                        delay.remove(ship.powerupEndTimeout)
                    end

                    ship.powerupEndTimeout = delay.timeout(t, function()
                        shack:setScale(1.5)
                        speed = 1
                        ray.setCenter(W/2, H/2-100)
                        ship.powerupEndTimeout = nil
                    end)

                    score = score + POWERUP_BONUS

                elseif ship.nodeathTimer <= 0 then
                    --game over
                    shack:shake(100)
                    shack:rotate(1)
                    sounds.bgloop:pause()
                    sounds.gameOver:play()

                    print "game over"
                    if score > hiScore then
                        hiScore = score
                    end
                    gameOver = true
                    gameOverToggler = delay.interval(1, function()
                        drawGameOver = not drawGameOver
                    end)
                    delay.timeout(1.5, function()
                        canRestart = true
                    end)
                end
            end
        end

        enemyTimer = enemyTimer + dt

        if playing and enemyTimer >= enemyTimerMax then
            enemyTimerMax = 0.1
            enemyTimer = 0
            spawnEnemy()
        end
    end
end

function love.draw()
    g.setBackgroundColor(0,0,0)

    shack:apply()

    g.setColor(LINE_COLOR)

    for x=10,W-30,STAGE_DIFF do
        ray.line(x, H-100, x+STAGE_DIFF, H-100)
    end

    g.setColor(SHIP_COLOR)

    local scale = 1--sounds.bgloop:getEnergy()

    ship:draw(ray.center.x, ray.center.y, scale)
    if ship.nodeathTimer > 0 then
        g.circle("line", ship:getX(), ship:getY(), 24)
    end

    for _,e in pairs(enemies) do
        --draw enemies
        if e.powerup then
            g.setColor(POWERUP_COLOR)
        else
            g.setColor(ENEMY_COLOR)
        end
        e:draw(ray.center.x, ray.center.y)
    end

    g.setColor(255,255,255,255)
    g.setFont(font)
    g.print(fmt("SCORE %.2f\nHI SCORE %.2f", score, hiScore), 10,10)

    if not playing then
        g.draw(keysImg, W/2-keysImg:getWidth()/2, H-keysImg:getHeight())
        if true then
            g.print("THERE'S A NEW VERSION AVAILABLE", 100,H/2)
        end
    end

    if gameOver then
        g.print("PRESS TAB TO CHANGE COLORS", W/2-20,10)

        if hiScore > 0 then
            g.print("PRESS R TO RESET HIGH SCORE",10,H-25)
        end
    end

    if drawGameOver then
        g.draw(gameOverImg, W/2-gameOverImg:getWidth()/2, 80)
    end
end

local keyActions = {
    escape = love.event.quit,

    left = function()
        if not playing then
            sounds.bgloop:play()
            playing = true
        end
        shack:shake(10)
        ship:move(ship.stage-1)
    end,

    right = function()
        if not playing then
            sounds.bgloop:play()
            playing = true
        end
        shack:shake(10)
        ship:move(ship.stage+1)
    end,

    tab = function()
        --change colors
        if gameOver or not playing then
            changeColors(1)
        end
    end,

    r = function()
        if gameOver and hiScore > 0 then
            shack:shake(100)
            hiScore = 0
            score = 0
        end
    end
}

function love.keypressed(k)
    if gameOver and canRestart and (
      k == 'left' or k == 'right' or
      k == 'return' or k == 'space'
    ) then
        canRestart = false
        gameOver = false
        drawGameOver = false
        delay.remove(gameOverToggler)
        score = 0
        --speed = 1
        enemies = {}
        sounds.bgloop:resume()
            :setVolume(.5)
            :setTargetVolume(1)
    end

    if keyActions[k] then
        keyActions[k]()
    end
end

function love.resize(w,h)
    W, H = w, h
end

function love.quit()
    fs.write("hiscore", tostring(hiScore))
    fs.write("colorscheme", tostring(colorScheme))
end
