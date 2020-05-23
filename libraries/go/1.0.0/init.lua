-- Copyright 2019-2020 Pablo Blanco Celdrán
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy 
-- of this software and associated documentation files (the "Software"), to deal 
-- in the Software without restriction, including without limitation the rights 
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
-- copies of the Software, and to permit persons to whom the Software is 
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in 
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
-- SOFTWARE.
---
-- Coordinate tracker movement system
---
local vector = require 'vector'
local go = {}

-- Static global position of the machine
local pos = vector(0)
local dir = vector(1, 0, 0)
local up = vector(0, 1, 0)

---
-- Sets the global position.
---
function go.locate(_pos)
  pos = _pos
end

function go.getLocation()
  return pos
end

function go.getDirection()
  return dir
end

---
-- Sets the direction vector of the machine.
---
function go.direct(_dir)
  dir = _dir
end

---
-- Goes forward
-- If could, moves the virtual position.
---
function go.forward()
  if turtle.forward() then
    pos = pos + dir
    return true
  end
  return false
end

---
-- Goes backward
---
function go.back()
  if turtle.back() then
    pos = pos - dir
    return true
  end
  return false
end

---
-- Goes up
---
function go.up()
  if turtle.up() then
    pos = pos + up
    return true
  end
  return false
end

---
-- Goes down
---
function go.down()
  if turtle.down() then
    pos = pos - up
    return true
  end
  return false
end

---
-- turns right
---
function go.turnRight()
  if turtle.turnRight() then
    local right = dir * up
    dir = right
    return true
  end
  return false
end

---
-- turns left
---
function go.turnLeft()
  if turtle.turnLeft() then
    local right = dir * up
    dir = -right
    return true
  end
  return false
end

return go
