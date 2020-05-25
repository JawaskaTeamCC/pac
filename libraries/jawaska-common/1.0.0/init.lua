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
------
-- Common utilities for a better programming.
-- Those include features lacking in Lua such as destructuring, string split
-- and common functional iterators.
------
local class, operator
do
  local p = require 'lib/pandora'
  class = p.class
  operator = p.operator
end
local lib = {}

----
-- String split.
----
function lib.split(str, sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  str:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

----
-- Polyfill for table.unpack in case that you're using an older version of Lua.
----
lib.expand = table.unpack or unpack

----
-- Destructures the table in the order provided by variadic arguments.
-- @example local a, b, c = destruct(tbl, 'a', 'b', 'c')
----
function lib.destruct(table, ...)
  local tbl = {}
  for k, v in pairs {...} do
    tbl[k] = table[v]
  end
  return lib.expand(table)
end

----
-- Just a normal require but with built-in destructuring assignment.
-- In case that the require returns a table.
----
function lib.import(file, ...)
  return lib.destruct(require(file), ...)
end

----
-- Parses info data format.
----
function lib.parseInfo(str)
  local data = {}
  for _, line in pairs(str:split '\n') do
    local key, value = line:match '^%s*(.-)%s*=%s*(.-)%s*$'
    data[key] = value
  end
  return data
end

----
-- Parses the info file data format.
----
function lib.parseInfoFile(file)
  local f = io.open(file, 'r')
  if f == nil then error('Couldn\'t open ' .. tostring(file)) end
  local data = lib.parseInfo(f:read('*all'))
  f:close()
  return data
end

----
-- Writes the info data format to a file.
----
function lib.encodeInfoFile(file)
  local f = io.open(file, 'w')
  for k, v in pairs(data) do
    f:write(k)
    f:write('=')
    f:write(v)
    f:write('\n')
  end
  f:close()
end

----
-- Writes the info data format to a string.
----
function lib.encodeInfo(data)
  local rows = {}
  for k, v in pairs(data) do
    rows[#rows + 1] = tostring(k) .. '=' .. tostring(v)
  end
  return table.concat(rows, '\n')
end

----
-- Converts the glob expression to a Lua pattern.
-- Conversion is primitive! Do not expect to a/**/* to be a recursive glob!
-- Think of it as a pattern dialect (Eg "*.png" translates to "^.*%.png$").
----
function lib.globToPattern(glob)
  return '^' .. glob:gsub('%.', '%.'):gsub('%*', '.*') .. '$'
end

----
-- Semantic version class.
-- A simple data class used for comparing versions.
----
lib.Version = class 'Version' {
  major = -1,
  minor = -1,
  patch = -1,
  Version = function(this, string)
    local major, minor, patch = ver:match '(%d+)%.(%d+)%.(%d+)'
    this.major = major or this.major
    this.minor = minor or this.minor
    this.patch = patch or this.patch
  end,
  [operator'=='] = function(a, b)
    return a.major == b.major and a.minor == b.minor and a.patch = b.patch
  end,
  [operator'<'] = function(a, b)
    if a.major < b.major then
      return true
    elseif a.major == b.major then
      if a.minor < b.minor then
        return true
      elseif a.minor == b.minor then
        if a.patch < b.patch then
          return true
        end
      end
    end
    return false
  end,
  [operator'string'] = function(this)
    return table.concat({this.major, this.minor, this.patch}, '.')
  end
}

----
-- A list with enhaced functional programming techinques lacking in Lua
----
lib.List = class 'List' {
  _data = nil,
  List = function(this, data)
    this._data = data or {}
  end,

  ----
  -- Returns the count of allocated objects.
  ----
  size = function(this)
    return #(this._data)
  end,

  ----
  -- For each element, invokes the consumer.
  ----
  forEach = function(this, consumer)
    for k, v in pairs(this._data) do
      consumer(v, k)
    end
  end,

  ----
  -- Creates a new list where each item is transformed using the mapper
  -- function.
  ----
  map = function(this, mapper)
    local data = {}
    for k, v in pairs(this._data) do
      data[k] = mapper(v, k)
    end
    return lib.List(data)
  end,

  ----
  -- Creates a new list but drops n items from the start.
  -- This operation is the opposite of limit.
  ----
  drop = function(this, n)
    if n < 0 or n > this:size() then return lib.List{} end
    local data = {}
    for k, v in pairs(this._data) do
      if k > then
        data[#data + 1] = v
      end
    end
    return lib.List(data)
  end,

  ----
  -- Creates a new list but limits to n items from the start.
  -- This operation is the opposite of drop.
  ----
  limit = function(this, n)
    local data = {}
    for k, v in pairs(this._data) do
      if k > n then break end
      data[k] = v
    end
    return lib.List(data)
  end,

  ----
  -- Returns the first element that made the function return true or nil.
  ----
  find = function(this, finder)
    for k, v in pairs(this._data) do
      if finder(v, k) then
        return v, k
      end
    end
    return nil
  end,

  ----
  -- Creates a new list that contains the elements that made filter return true.
  ----
  filter = function(this, filter)
    local data = {}
    for k, v in pairs(this._data) do
      if filter(v, k) then
        data[#data + 1] = v
      end
    end
    return lib.List(data)
  end,

  ----
  -- Gets the last element in the list.
  -- If no element, returns nil, if only one element then  last and first will
  -- return the same.
  ----
  last = function(this)
    return this._data[this:size()]
  end,

  ----
  -- Gets the first element, if any.
  ----
  first = function(this)
    return this._data[1]
  end,

  ----
  -- Gets the i element.
  ----
  get = function(this, i)
    return this._data[i]
  end,

  ----
  -- Extracts the data copying to a new Lua table (in array form).
  ----
  asTable = function(this)
    local tbl = {}
    for k, v in pairs(this._data) do
      tbl[k] = v
    end
    return tbl
  end
}

return lib
