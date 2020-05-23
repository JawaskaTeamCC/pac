---
-- Coordinate tracker movement system
---
local vector = require './vector'
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
