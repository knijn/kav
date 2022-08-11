shell.run("wget https://raw.githubusercontent.com/knijn/kav/main/src/startup/00_kav.lua /startup/00_kav.lua") -- Startup program for all the kav features, kav WILL NOT WORK if this fails
shell.run("wget https://raw.githubusercontent.com/knijn/kav/main/src/.pkg/kav.lua /.pkg/kav.lua") -- controller for kav, not strictly neccesery but very useful
shell.run("wget https://raw.githubusercontent.com/knijn/kav/main/src/.pkg/pastebin.lua /.pkg/pastebin.lua") -- patched pastebin with check
shell.run("/startup/00_kav.lua")
print("Rebooting!")
os.reboot()