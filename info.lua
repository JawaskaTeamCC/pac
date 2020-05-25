return {
  author = "sigmasoldier",
  contact = "Contact me at minecraft",
  site = "https://github.com/JawaskaTeamCC/pac",
  support = "https://github.com/JawaskaTeamCC/pac/issues",
  version = "1.0.0",
  install = function()
    shell.run('wget', 'https://raw.githubusercontent.com/JawaskaTeamCC/pac/master/pac.lua', '/pac.lua')
  end,
  update = function()
    shell.run('wget', 'https://raw.githubusercontent.com/JawaskaTeamCC/pac/master/pac.lua', '/pac.lua')
  end,
  remove = function()
    shell.run('rm', '/pac.lua')
  end
}