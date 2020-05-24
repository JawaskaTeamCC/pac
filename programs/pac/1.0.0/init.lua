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

local function parseVersion(ver)
  return ver:match '(%d+)%.(%d+)%.(%d+)'
end

----
-- Compares two semantic versions.
-- @example "1.0.1" > "1.1.0" == false
----
local function compareVersion(aStr, bStr)
  local a = parseVersion(aStr)
  local b = parseVersion(bStr)
  if a[1] > b[1] then
    return 1
  elseif a[1] < b[1] then
    return -1
  else
    if a[2] > b[2] then
      return 1
    elseif a[2] < b[2] then
      return -1
    else
      if a[3] > b[3] then
        return 1
      elseif a[3] < a[3] then
        return -1
      else
        return 0
      end
    end
  end
end

----
-- Looks inside a version array, which first element is ignored.
-- Attempts to retrieve the latest version if no version is provided.
-- In order to speed up, version array MUST be incrementally sorted, otherwise
-- there's no guarantee that the found version is the latest.
----
local function findLatestVersion(versionArray, version)
  if version == nil then
    return versionArray[#versionArray]
  end
  local foundVersion = nil
  for k, v in pairs(versionArray) do
    if k > 1 then
      if compareVersion(v, version) == 0 then
        foundVersion = v
      end
    end
  end
  return foundVersion or error('Couldn\'t find version ' .. version)
end

----
-- Looks up repositories and checks package names by pattern.
-- Input name must be a match ready string.
----
local function fetchPackageData(pattern, requireVersion)
  local repos = decode '.pac/repos.info'
  local packages = {}
  for repoName, source in pairs(repos) do
    print('Scanning ' .. repoName)
    local repoRead = ResourceReader(source)
    local index = nil
    do
      local res = repoRead('/index.info')
      if res == nil then error('Couldn\'t fetch repository index for ' .. pattern .. ' at ' .. source) end
      index = decodeString(res:readAll())
    end
    for name, dataString in pairs(index) do
      if name:match(pattern) then
        local data = dataString:split ','
        local location = data[1]
        local version = findLatestVersion(data, requireVersion)
        print('Acquiring ' .. name .. ' v' .. version .. ' info...')
        local packageData = nil
        do
          local res = repoRead(location .. '/' .. version .. '/package.info')
          if res == nil then error('Couldn\'t fetch package data, bad formed repository. Check out ' .. source .. location .. '/' .. version) end
          packageData = decodeString(res:readAll())
        end
        packages[#packages + 1] = {
          name = name,
          repository = {
            name = repoName,
            source = source
          },
          package = packageData
        }
      end
    end
  end
  return packages
end

----
-- Fetches package from package data, downloads to passed folder.
----
local function downloadPackage(name, version, folder)
  local info = searchPackage(name)
  if not fs.exists(folder) then fs.makeDir(folder) end
end

----
-- Converts the given glob to a Lua pattern.
----
local function globToPattern(glob)
  return '^' .. glob:gsub('%.', '%.'):gsub('%*', '.*') .. '$'
end

local command = ...
local BAR_SYMBOL = '='

if command == 'help' then
  term.setCursorPos(1, 1)
  term.clear()
  print [[USAGE   pac <command> [options]
Where <command> is one of:

  help
    Shows this usage
  
  update <glob>
    Updates the desired package
    <glob> might be a package name or a glob
    representing packages. Updates matching
    names to latest version.

  install <package> [version]
    Installs a package, optionally enforces a
    version. <package> must be a full qualified
    package name.

  
(next)]]
  os.pullEvent 'key'
  term.setCursorPos(1, 1)
  term.clear()
  print [[
  remove <package>
    Removes the package name.
]]
elseif command == 'update' then
  local _, glob = ...
  print('Updating ' .. glob .. '...')
  local pattern = globToPattern(glob)
  local pkgs = fetchPackageData(pattern)
  print('Found #' .. (#pkgs) .. ' package/s')
  print('Updating...')
  do
    local width, bottom = term.getSize()
    local maxWidth = width - 7
    local stepSize = maxWidth / #pkgs
    for k, v in pairs(pkgs) do
      local i = k -1
      term.setCursorPos(1, bottom)
      term.write('[' .. BAR_SYMBOL:rep(stepSize * i))
      term.setCursorPos(width - 6, bottom)
      term.write(']' .. i .. '/' .. #pkgs)
      os.sleep(1)
    end
    term.setCursorPos(1, bottom)
    term.write('[' .. BAR_SYMBOL:rep(maxWidth))
    term.setCursorPos(width - 6, bottom)
    term.write(']' .. #pkgs .. '/' .. #pkgs)
    print()
  end
elseif command == 'install' then

elseif command == 'remove' then
end
