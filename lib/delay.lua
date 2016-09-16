-- Copyright (c) 2016 jdev6

-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files(the
-- "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
-- following conditions:

-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
-- OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local delay = {}
local _queue = {}

local function insert(tbl, x)
    --replacement for table.insert, inserts x in first empty slot
    --assumes tbl has only number indexes, else crashes

    local oldk = 1
    for k,v in pairs(tbl) do
        if k > oldk then
            --a key was skipped: found an empty slot
            tbl[oldk] = x
            return oldk
        end
        oldk = k + 1
    end
    --insert at the end otherwise
   table.insert(tbl, x)
   return oldk
end

function delay.timeout(t, func, ...)
    return insert(_queue, {
        t = t, --time in seconds
        paused = false, --if its paused or not
        func = func, --function
        args = {...} --function args
    })
end

function delay.interval(t, func, ...)
    return insert(_queue, {
        t = t,
        st = t, --starting time (used to reset interval)
        paused = false,
        func = func,
        args = {...}
    })
end

function delay.stat(id)
    --returns status
    return _queue[id]
end

function delay.pause(id)
    --pauses
    _queue[id].paused = true
end

function delay.resume(id)
    --resumes
    _queue[id].paused = false
end

function delay.play(id)
    --toggles pause (same as delay.stat(id).paused and delay.play(id) or delay.resume(id))
    _queue[id].paused = not _queue[id].paused
end

function delay.remove(id)
    --removes completely
    _queue[id] = nil
end

--local len = function(tbl) local i = 0; for _,_ in pairs(tbl) do i=i+1 end return i end

function delay.update(dt)
    local toRemove = {}

    --print (len(_queue))

    for id,x in pairs(_queue) do
        if x.t <= 0 then
            x.func(unpack(x.args)) --call func with args
            if not x.st then
                --is timeout
                table.insert(toRemove, id)
            else
                x.t = x.st
            end

        elseif not x.paused then
            x.t = x.t - dt
        end
    end

    for _,id in ipairs(toRemove) do
        delay.remove(id)
    end
end

return delay
