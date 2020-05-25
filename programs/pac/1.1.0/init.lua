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
local common = require 'lib/jawaska-common'
local class, operator = common.import('lib/pandora', 'class', 'operator')
local Version = common.version
local List = common.List

----
-- Makes the directories and default config files if not present.
----
do
  if not fs.exists '.pac' then fs.makeDir '.pac' end
  if not fs.exists '.pac/repos.info' then
    local f = io.open('.pac/repos.info', 'w')
    f:write 'jawaska=https://raw.githubusercontent.com/JawaskaTeam/computercraft-programs/master\n'
    f:close()
  end
  if not fs.exists '.pac/versions.info' then
    local f = io.open('.pac/versions.info', 'w')
    f:write ''
    f:close()
  end
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
-- Looks up repositories and checks package names by pattern.
-- Input name must be a match ready string.
----
local function fetchPackageData(pattern, requireVersion)
  local repos = common.parseInfoFile '.pac/repos.info'
  local packages = {}
  for repoName, source in pairs(repos) do
    print('Scanning ' .. repoName)
    local repoRead = ResourceReader(source)
    local index = nil
    do
      local res = repoRead('/index.info')
      if res == nil then error('Couldn\'t fetch repository index for ' .. pattern .. ' at ' .. source) end
      index = common.parseInfo(res:readAll())
    end
    for name, dataString in pairs(index) do
      if name:match(pattern) then
        local data = dataString:split ','
        local location = data[1]
        local required = Version(requireVersion)
        local versions = List(data):drop(1):map(Version)
        local version = versions:find(function(v)
          return v == required
        end) or versions:last()
        print('Acquiring ' .. name .. ' v' .. version .. ' info...')
        local path = location .. '/' .. version
        local packageData = nil
        do
          local res = repoRead(path .. '/package.info')
          if res == nil then error('Couldn\'t fetch package data, bad formed repository. Check out ' .. source .. location .. '/' .. version) end
          packageData = common.parseInfo(res:readAll())
        end
        packages[#packages + 1] = {
          name = name,
          repository = {
            name = repoName,
            source = source,
            path = path
          },
          package = packageData
        }
      end
    end
  end
  return packages
end

----
-- Downloads package from data table.
----
local function downloadPackage(data)
  local root = (data.package.install or 'lib') .. '/' .. data.package.name
  if not fs.exists(root) then fs.makeDir(root) end
  for _, file in pairs(data.package.files:split(',')) do
    local url = data.repository.source .. data.repository.path .. '/' .. file
    local res = http.get(url)
    local fout = io.open(root .. '/' .. file, 'w')
    fout:write(res:readAll())
    fout:close()
  end
  if data.package.shortcut ~= nil then
    local fout = io.open(data.package.shortcut, 'w')
    fout:write('-- Shortcut for ' .. data.package.name)
    fout:write '\n'
    fout:write('shell.run("' .. root .. '/init.lua", ...)')
    fout:close()
  end
end


local command = ...
local BAR_SYMBOL = '='
local function drawBar(i, total)
  local width, bottom = term.getSize()
  local countStr = '] ' .. i .. '/' .. total
  local maxWidth = width - countStr:len() + 1
  local stepSize = maxWidth / total
  term.setCursorPos(1, bottom)
  term.write('[' .. BAR_SYMBOL:rep(stepSize * i))
  term.setCursorPos(maxWidth, bottom)
  term.write(countStr)
end

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
  print('Updating ' .. (glob or 'all packages') .. '...')
  local pattern = common.globToPattern(glob or '*')
  local pkgs = fetchPackageData(pattern)
  print('Found #' .. (#pkgs) .. ' package/s')
  print('Updating...')
  local localPkgs = common.decodeInfoFile('.pac/versions.info')
  local updated = 0
  for k, v in pairs(pkgs) do
    drawBar(k - 1, #pkgs)
    local verInfo = localPkgs[v.package.name]
    if verInfo ~= nil then
      if Version(verInfo) < Version(v.package.version) then
        downloadPackage(v)
        localPkgs[v.package.name] = v.package.version
        updated = updated + 1
      end
    end
  end
  common.encodeInfoFile('.pac/versions.info', localPkgs)
  drawBar(#pkgs, #pkgs)
  print()
  print('Done, updated ' .. updated .. ' package/s')
elseif command == 'install' then
  local _, glob, version = ...
  if glob == nil or glob == '*' then
    print 'Error: Install is not permited for targetting all packages!'
    return
  end
  local pattern = common.globToPattern(glob)
  local pkgs = fetchPackageData(pattern, version)
  for i, pkg in pairs(pkgs) do
    print('Installing ' .. pkg.package.name .. '...')
    local deps = {}
    for k, version in pairs(pkg.package) do
      local pkg = k:match('^deps%.(.+)$')
      if pkg ~= nil then
        deps[#deps + 1] = fetchPackageData(pkg, version)[1]
      end
    end
    print('Installing ' .. #deps .. ' additional dependencies')
    local localPkgs = common.decodeInfoFile('.pac/versions.info')
    for _, dep in pairs(deps) do
      local verInfo = localPkgs[dep.package.name]
      if verInfo ~= nil then
        if Version(verInfo) < Version(dep.package.version) then
          downloadPackage(dep)
          localPkgs[dep.package.name] = dep.package.version
        end
      else
        downloadPackage(dep)
        localPkgs[dep.package.name] = dep.package.version
      end
    end
    downloadPackage(pkg)
    localPkgs[pkg.package.name] = pkg.package.version
    common.encodeInfoFile('.pac/versions.info', localPkgs)
  end
elseif command == 'remove' then
  local _, glob = ...
  local localPkgs = common.decodeInfoFile('.pac/versions.info')
  local pattern = common.globToPattern(glob)
  local removed = 0
  for k, v in pairs(localPkgs) do
    if k:match(pattern) then
      print('  Removing ' .. k)
      local info = fetchPackageData(k)[1]
      if info == nil then
        print('ERROR! Cannot find package metadata for ' .. k .. '!')
        print('It will be removed from the registry, but folders and files must be erased manually!')
      else
        local cut = info.package.shortcut
        if cut ~= nil then
          fs.delete(cut)
        end
        fs.delete(info.package.install .. '/' .. info.package.name)
        removed = removed + 1
        localPkgs[info.package.name] = nil
      end
    end
  end
  common.encodeInfoFile('.pac/versions.info', localPkgs)
  print('Removed ' .. removed .. ' packages')
elseif command == 'info' then
  local _, name = ...
  local found = fetchPackageData(common.globToPattern(name))[1]
  if found == nil then
    print('Could not find ' .. name)
    return
  end
  for k, v in pairs(found.package) do
    print(k, ':', v)
  end
else
  print 'Wrong usage, use pac help'
end
