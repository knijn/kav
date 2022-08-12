local args = { ... }
local version = 1.0


local printUsage = function()
  print("Usages:")
  print("kav settings list")
  print("kav settings set <id>")
  print("kav info")
  print("kav info blocked")
  print("kav reset")
end

if not args or not args[1] then
  printUsage()
end


if args[1] == "settings" then
  if args[2] == "list" then
    print("[1] Advanced Menu - " .. tostring(settings.get("kav.advancedMenu")))
    --print("[2] Shutdown Prompt - " .. tostring(settings.get("kav.shutdownPrompt")))
    --print("[3] Reboot Prompt - " .. tostring(settings.get("kav.rebootPrompt")))
    --print("[4] Download Prompt - " .. tostring(settings.get("kav.downloadPrompt")))
    --print("[5] Pastebin Prompt - " .. tostring(settings.get("kav.pastebinPrompt")))
  elseif args[2] == "set" then
    local selection = tonumber(args[3])
    local setting = tostring(args[4])
    if not setting == "true" or not setting == "false" then
        error("Wrong setting provided")
    end
    
    if selection  <= 5 and selection > 0 then
      if selection == 1 then
        settings.set("kav.advancedMenu", setting)
        print("Set [1] Advanced Menu to " .. tostring(settings.get("kav.advancedMenu")))
        settings.save()
      elseif selection == 2 then
        settings.set("kav.shutdownPrompt", setting)
        print("Set [2] Shutdown Prompt to " .. tostring(settings.get("kav.shutdownPrompt")))
        settings.save()
      elseif selection == 3 then
        settings.set("kav.rebootPrompt", setting)
        print("Set [2] Reboot Prompt to " .. tostring(settings.get("kav.rebootPrompt")))
        settings.save()
      elseif selection == 4 then
        settings.set("kav.downloadPrompt", setting)
        print("Set [2] Download Prompt to " .. tostring(settings.get("kav.downloadPrompt")))
        settings.save()
      elseif selection == 5 then
        settings.set("kav.pastebinPrompt", setting)
        print("Set [2] Pastebin Prompt to " .. tostring(settings.get("kav.pastebinPrompt")))
        settings.save()
      end
    else print("Invalid Selection")
    end  
  else 
    printUsage()
  end
elseif args[1] == "info" then
  if args[2] == "blocked" then
    print("Items blocked for Pastebin: ")
    for i,o in pairs(kav.blockedItems.blockedPastebin) do
      print("- " .. o.paste)
    end
    print("Items blocked for Web: ")
    for i,o in pairs(kav.blockedItems.blockedWeb) do
      print("- " .. o.url)
    end
    print("Filenames blocked")
    for i,o in pairs(kav.blockedItems.blockedFileNames) do
      print("- " .. o.fileName)
    end
    return
  elseif args[2] == "stored" then
    print(textutils.serialise(kav.blockedItems))
  end
  
  if not kav then
    print("kav is not installed!!")
    return
  end
  print("Frontend Version: " .. tostring(version))
  print("Backend Version: " .. tostring(kav.backendVersion))
elseif args[1] == "reset" then
  kav.reset()
elseif args[1] == "scan" then
  kav.scan(false)
elseif args[1] == "hash" then
  if args[2] and fs.exists(args[2]) then
    local handle = fs.open(args[2],"r")
    local hash = kav.sha256(handle.readAll())
    handle.close()
    print(hash)
    if ccemux then
      ccemux.echo(hash)
    end
  end
  print("File not found...")
elseif args[1] == "scanResults" then
  for i,o in pairs(kav.scanResults) do
    print(o.fileName .. ":")
    print("Reason: " .. o.reason)
    print("Type: " .. o.type)
  end
end

settings.save()