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
-- Simple CLI package manager
-- Installs packages and stuff.
-- Self updating!
------

----
-- Splits
----
function string:split(sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

----
-- Makes the directories and default config files if not present.
----
do
  if not fs.exists '.pac' then fs.makeDir '.pac' end
  if not fs.exists '.pac/repos.info' then
    local f = io.open('.pac/repos.info', 'w')
    f:write 'jawaska=https://raw.githubusercontent.com/JawaskaTeam/computercraft-programs\n'
    f:close()
  end
end

local function decodeString(str)
  local data = {}
  for _, line in pairs(str:split '\n') do
    local key, value = line:match '^%s*(.-)%s*=%s*(.-)%s*$'
    data[key] = value
  end
  return data
end

----
-- Decodes a properties file.
----
local function decode(file)
  local f = io.open(file, 'r')
  if f == nil then error('Couldn\'t open ' .. tostring(file)) end
  local data = decodeString(f:read('*all'))
  f:close()
  return data
end

----
-- Encodes a properties file.
----
local function encode(file, data)
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
-- Higher order function that creates an HTTP resource reader.
----
local function ResourceReader(root)
  return function(sub, headers)
    return http.get(root .. sub, headers)
  end
end

----
-- Looks up repositories and checks package names.
----
local function searchPackage(name)
  local repos = decode '.pac/repos.info'
  for repoName, source in pairs(repos) do
    print('Scanning ' .. repoName)
    local repoRead = ResourceReader(source)
    local resp = repoRead('/index.info')
    if resp == nil then error 'Null response' end
    local index = decodeString(resp:readAll())
    local repoData = index[name]
    if repoData ~= nil then
      local versionData = repoData:split ','
      for k, v in pairs(versionData) do print(k, v) end
      return nil
    end
  end
  return nil
end

searchPackage 'vector'
