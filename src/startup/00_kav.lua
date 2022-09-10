shell.setPath("/.pkg:" .. shell.path())

local get = _G.http.get
local shutdown = _G.os.shutdown
local reboot = _G.os.reboot

local kavServer = "https://raw.githubusercontent.com/knijn/kav/main"

local kav = {}
kav.backendVersion = 1.0
kav.advancedMenu = settings.get("kav.advancedMenu",false)

local function warn(v)
  local oldTXT = term.getTextColor()
  term.setTextColor(colors.orange)
  print(v)
  term.setTextColor(oldTXT)
end

local function drawBlank()
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1,1)
end

kav.beep = function()
  if peripheral.find("speaker") then
    local speaker = peripheral.find("speaker")
    speaker.playNote("chime", 3, 12)
    sleep(0.5)
    speaker.playNote("chime", 3, 12)
  end
end

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

-- https://github.com/Lupus590-CC/CC-Random-Code/blob/master/src/confirmLoop.lua
-- Unlicense, free use - you can remove this credit if you want.
function confirmLoop(...)
  local prompt = {...}
  if #prompt > 1 then error("Too many args",2) end
  prompt = prompt[1] or ""
  if type(prompt) ~= "string" then error("Bad arg, expected string",2) end
  print(prompt.." (Y/N)")
  local input
  repeat
    local _, i = os.pullEvent("char")
    input = i:lower()
  until input == "y" or input == "n"
  print(input:upper())
  return (input == "y")
end

function string.starts(String,Start) --https://stackoverflow.com/questions/22831701/lua-read-beginning-of-a-string
  return string.sub(String,1,string.len(Start))==Start
end

kav.blockedItems = {}
local blockedHandle = get(kavServer .. "/blocked.json?cb=" .. os.epoch())
if not blockedHandle then
  warn("WARN: Wasn't able to discover blocked urls from the server") -- Instead of fetching this each time you could save it to disk. That way you could use the local copy as a fallback if the server couldn't be reached.
  print("Trying to find blocked items from disk...")
  if not fs.exists(".blocked") then
    warn("WARN: Disk Cache not found... KAV will not work fully without connecting to the internet first")
    return
  end
  local fileHandle = fs.open(".blocked","r")
  kav.blockedItems = textutils.unserialiseJSON(fileHandle.readAll())
  fileHandle.close()
  print("Was able to recover from disk")
else
  local fileHandle = fs.open(".blocked","w")
  local fileData = blockedHandle.readAll()
  fileHandle.write(fileData)
  fileHandle.close()
  kav.blockedItems = textutils.unserialiseJSON(fileData)
end
if blockedHandle then
  blockedHandle.close()
end

kav.pastebinCheck = function(id)
  local allowed = true
  for _,o in pairs(kav.blockedItems.blockedPastebin) do
    if o.paste == id then
        allowed = false
        break -- Suggested by Lupus590
    end
  end

  return allowed
end

local function drawAdvancedPrompt(type, o, blocked)
  if o then
    name = o.url or o.paste or "unknown"
  else
    name = "unknown"
  end
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
    if settings.get("kav.downloadPrompt",true) == false then
      drawBlank()
      return true
    end
    print("> Are you sure you want to download " .. name .. "?")
    local curX, curY = term.getCursorPos()
    term.setCursorPos(curX, curY + 1)
    print("Reason: " .. o.reason)
    print("Severity: " .. o.severity)
    print("Type: " .. o.type)
  elseif type == "shutdown" then
    if settings.get("kav.shutdownPrompt",true) then
      return true
    end
    term.write("> Are you sure you want to shut down?")
  elseif type == "reboot" then
    if settings.get("kav.rebootPrompt,true") == false then
      drawBlank()
      return
    end
    term.write("> Are you sure you want to reboot?")
  end

  term.setCursorPos(2,ySize - 2)
  local pass = confirmLoop("")

  term.setTextColor(oldTXT)
  term.setBackgroundColor(oldBG)
  term.setCursorPos(1,1)
  term.clear()
  return pass

end

local function drawNormalPrompt(type, name, blocked) -- you always assume that you're downloading here bu the other prompt has shutdown and reboot prompts, nothing is checking that this prompt isn't getting used for shutdown and reboot prompting
  if name then
    print("Are you sure you want to download " .. name .. "?")
  end
  if type == "shutdown" then
    print("Do you want to shut down?")
    return confirmLoop("")
  elseif type == "reboot" then
    print("Do you want to reboot?")
    return confirmLoop("")
  end
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
  return confirmLoop("")
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
    if string.starts(url,"https://pastebin.com") then
      return get(url, headers)
    end
    local blocked = false
    local tmpO
    for i,o in pairs(kav.blockedItems.blockedWeb) do
      if o.url == url then
        blocked = true
        tmpO = o
      end
    end
    if not blocked then
      return get(url, headers)
    end
    if blocked and kav.prompt("web", tmpO, blocked) then
      return get(url, headers)
     else
       return  false, "URL Blocked by kav"
    end
  end
end

_G.os.shutdown = function()
  if kav.prompt("shutdown",_, false) then
    shutdown()
  else
    return
  end
end

_G.os.reboot = function()
  if kav.prompt("reboot",_, false) then
    reboot()
  else
    return
  end
end

_G.kav = kav