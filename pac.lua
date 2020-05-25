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
-- Makes the directories and default config files if not present.
----
do
  if not fs.exists '/.pac' then fs.makeDir '/.pac' end
  if not fs.exists '/.pac/default-namespace' then
    local f = io.open('/.pac/default-namespace', 'w')
    f:write 'JawaskaTeamCC'
    f:close()
  end
  if not fs.exists '/.pac/db' then fs.makeDir '/.pac/db' end
end

local function getDefaultNamespace()
  local f = io.open('.pac/default-namespace', 'r')
  assert(f ~= nil, 'pac configuration is corrupted, some program is changing .pac directory contents.')
  local read = f:read('*all')
  f:close()
  return read
end

----
-- Gets the package, either from disk or network.
----
local function getPackage(package, namespace, version, mode, registryFile)
  version = version or 'master'
  local defaultNamesp = namespace == nil
  namespace = namespace or getDefaultNamespace()
  assert(package ~= nil and package:len() > 0, 'Provide a package name!')
  if mode == 'install' then
    local res = http.get('https://raw.githubusercontent.com/' .. namespace .. '/' .. package .. '/' .. version .. '/info.lua')
    if res == nil then
      local name = package
      if defaultNamesp then
        name = '@' .. namespace .. '/' .. name
      end
      error('Couldn\'t get ' .. name)
    end
    local raw = res:readAll()
    local fn = loadstring(raw)
    setfenv(fn, getfenv())
    return fn(), raw
  else
    local f = io.open(registryFile, 'r')
    if f == nil then
      error('Couldn\'t get registry file ' .. registryFile)
    end
    local raw = f:read('*all')
    f:close()
    local fn = loadstring(raw)
    setfenv(fn, getfenv())
    return fn(), raw
  end
end

local function parseTarget(target)
  local namespace, pkg = target:match '@(.-)/(.+)'
  if namespace ~= nil then
    return pkg, namespace
  else
    return target
  end
end

local mode, target, version = ...
local pkg, namesp = parseTarget(target)
local registryFile = target:gsub('[@/]', '__')
local info, rawInfo = getPackage(pkg, namesp, version, mode, '/.pac/db/' .. registryFile)
local toRun = info[mode]
print('Running ' .. mode, pkg, namesp)
assert(toRun ~= nil and type(toRun) == 'function', 'Nothing to be done with "' .. mode .. '"')
local result = toRun(info, ...)
if result == nil then
  if mode == 'remove' then
    shell.run('rm', '/.pac/db/' .. registryFile)
  else
    local f = io.open('/.pac/db/' .. registryFile, 'w')
    f:write(rawInfo)
    f:close()
    print('Installed')
  end
end
