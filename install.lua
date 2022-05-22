local repoURL = "https://raw.githubusercontent.com/knijn/kav/main/"
shell.run("wget " .. repoURL .. "startup/src/00_kav.lua /startup/00_kav.lua") -- Startup program for all the kav features, kav WILL NOT WORK if this fails
shell.run("wget " .. repoURL .. ".pkg/src/kav.lua /.pkg/kav.lua") -- controller for kav, not strictly neccesery but very useful
shell.run("wget " .. repoURL .. ".pkg/src/pastebin.lua /.pkg/pastebin.lua") -- patched pastebin with check