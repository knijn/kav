shell.setPath("/.pkg:" .. shell.path())

local get = _G.http.get
local shutdown = _G.os.shutdown
local reboot = _G.os.reboot

local kavServer = "https://raw.githubusercontent.com/knijn/kav/main"

kav = {}
kav.backendVersion = 1.0
kav.advancedMenu = settings.get("kav.advancedMenu") or term.isColor() or false

warn = function(v)
  oldTXT = term.getTextColor()
  term.setTextColor(colors.orange)
  print(v)
  term.setTextColor(oldTXT)
end

local blockedPastebinHandle = get(kavServer .. "/blockedPastebin.json")
if not blockedPastebinHandle then
  kav.blockedPastebin = {}
  warn("WARN: Wasn't able to discover blocked pastebins from the server")
else
  kav.blockedPastebin = textutils.unserialiseJSON(blockedPastebinHandle.readAll())
end
blockedPastebinHandle.close()




local blockedWebHandle = get(kavServer .. "/blockedWeb.json")
if not blockedWebHandle then
  kav.blockedWeb = {}
  warn("WARN: Wasn't able to discover blocked urls from the server")
else
  kav.blockedWeb = textutils.unserialiseJSON(blockedWebHandle.readAll())
  
end
blockedWebHandle.close()

kav.reset = function()
  settings.set("kav.advancedMenu", false)
  settings.set("kav.shutdownPrompt", true)
  settings.set("kav.rebootPrompt", true)
  settings.set("kav.downloadPrompt", true)
  settings.set("kav.pastebinPrompt", true)
  if settings.get("kav.startup") then
    settings.unset("kav.startup")
  end
  settings.save()
end

kav.pastebinCheck = function(id)
  local allowed = true
  for _,o in pairs(kav.blockedPastebin) do
    if o == id then
        allowed = false
        break -- Suggested by Lupus590
    end
  end

  return allowed
end

function drawBlank()
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1,1)
end

kav.beep = function()
  if peripheral.find("speaker") then
    local speaker = peripheral.find("speaker")
    speaker.playNote(chime, 3, 12)
    sleep(0.5)
    speaker.playNote(chime, 3, 12)
  end
end

function drawAdvancedPrompt(type, blocked, name) 
  
  local oldBG = term.getBackgroundColor()
  local oldTXT = term.getTextColor()
  local xSize, ySize = term.getSize()
  
  local bgColor = colors.white
  if blocked then bgColor = colors.red end
  term.setBackgroundColor(bgColor)
  term.setTextColor(colors.black)
  term.setCursorPos(2,2)
  term.clear()

  kav.beep()

  if type == "pastebin" then
    if settings.get("kav.pastebinPrompt") == false then
      drawBlank()
      return
    end
    term.write("> Are you sure you want to download the pastebin " .. name .. "?")
  elseif type == "web" then
    if settings.get("kav.downloadPrompt") == false then
      drawBlank()
      return true
    end
    term.write("> Are you sure you want to download " .. name .. "?")
  elseif type == "shutdown" then
    if settings.get("kav.shutdownPrompt") == false then
      return true
    end
    term.write("> Are you sure you want to shut down?")
  elseif type == "reboot" then
    if settings.get("kav.rebootPrompt") == false then
      drawBlank()
      return
    end
    term.write("> Are you sure you want to reboot?")
  end

  if blocked then -- Check if the program is on the block list and let the user know
    term.setCursorPos(2,ySize - 3)
    warn("!! This program is known to be malicious")
  end
  
  term.setCursorPos(2,ySize - 2)
  term.write("(y/n) > ")

  local input = read()
  local pass
  if input == "y" then
    pass = true
  elseif input == "n" then
    pass = false
  else
    print("Invalid input, cancelling")
    pass = false
  end

  term.setTextColor(oldTXT)
  term.setBackgroundColor(oldBG)
  term.setCursorPos(1,1)
  term.clear()
  return pass

end

function drawNormalPrompt(type, name, blocked)
  print("Are you sure you want to download " .. name .. "?")
  if blocked then
      if term.isColor() then
        local oldTextColor = term.getTextColor()
        term.setTextColor(colors.red)
        print("!! This program is known to be a dangerous program")
        term.setTextColor(oldTextColor)
      else
        print("!! This program is known to be a dangerous program")
      end
  end
  term.write("(y/n) > ")
  local input = read()
  if input == "y" then
    return true
  elseif input == "n" then
    return false
  else
    print("Invalid input, cancelling")
    return false
  end
end

kav.prompt = function(type, name, blocked)
  if kav.advancedMenu then
    return drawAdvancedPrompt(type, name, blocked)
  else
    return drawNormalPrompt(type, name, blocked)
  end
end

-- http override
if http then
  _G.http.get = function(url, headers)
    local blocked = false
    for i,o in pairs(kav.blockedWeb) do
      if o == url then
        blocked = true
        return
      end
    end
    if kav.prompt("web", blocked, url) then
      return get(url, headers)
     else
     return  false, "URL Blocked by kav"
    end
  end
end



_G.os.shutdown = function()
  if kav.prompt("shutdown", false) then
    shutdown()
  else
    return
  end
end

_G.os.reboot = function()
  if kav.prompt("reboot", false) then
    reboot()
  else
    return
  end
end

_G.kav = kav