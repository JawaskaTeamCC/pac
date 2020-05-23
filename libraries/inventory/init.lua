---
-- Inventory utility library
---
local lib = {}

-- Returns true if the element is in the table.
local function contains(toFind, table)
  for _, elem in pairs(table) do
    if elem == toFind then return true end
  end
  return false
end

---
-- Finds the slots that contain one of the provided elements
---
function lib.find(idTable)
  local found = {}
  for i=1, 16 do
    local data = turtle.getItemDetail(i)
    if data ~= nil and contains(data.name, idTable) then
      found[#found + 1] = i
    end
  end
  return table.unpack(found)
end

---
-- Selects the inventory slot of the first matching element
-- Returns true on success.
---
function lib.select(idTable)
  local loc = lib.find(idTable)
  if loc ~= nil then
    turtle.select(loc)
    return true
  end
  return false
end

---
-- Finds the items, returns a table where the keys are the IDs of the items,
-- and the value the detail of how many there are, their inventory locations,
-- and per slot detail.
---
function lib.detail(idTable)
  local found = {}
  for _, id in pairs(idTable) do
    local tbl = {
      id = id,
      count = 0,
      details = {},
      locations = {}
    }
    for k, loc in pairs{lib.find{id}} do
      local det = turtle.getItemDetail(loc)
      tbl.details[k] = det
      tbl.locations[k] = loc
      tbl.count = tbl.count + det.count
    end
    found[id] = tbl
  end
  return found
end

---
-- Runs for each item in the inventory.
---
function lib.forEach(fn)
  for i=1, 16 do
    local item = turtle.getItemDetail(i)
    if item ~= nil then fn(item, i) end
  end
end

return lib
