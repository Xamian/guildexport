GuildExport = CreateFrame("Button", "GuildExportHiddenFrame", UIParent)
local addonName = "GuildExport"
local revision = tonumber(("$Revision: 21 $"):match("%d+"))
local loaded = false
local debugging = false

GuildExportData = GuildExportData or {}

local function debug(msg)
    if debugging then
        if (type(msg) == "table") then
            for k,v in pairs(msg) do
                debug(v)
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("\124cFFFF0000"..addonName.."\124r: "..msg)
        end
    end
end

function GuildExport:Load()
  loaded = true
  local revstr 
  revstr = GetAddOnMetadata("GuildExport", "X-Curse-Packaged-Version")
  if not revstr then
    revstr = GetAddOnMetadata("GuildExport", "Version")
  end
  if not revstr or string.find(revstr, "@") then
    revstr = "r"..tostring(revision)
  end
  --print("GuildExport "..revstr.." loaded.")
end

function GuildExport:Unload()
  loaded = false
  GuildExport:ExportToWtf()
  print("GuildExport unloaded.")
end

function GuildExport:ExportToWtf()
	if IsInGuild() then
		local count = GetNumGuildMembers(true)
		local guildName, guildRankName, guildRankIndex = GetGuildInfo("player");
		if count>0 then
			print("GuildExport exports " .. count .. " members to wtf-file...")
			--clear saved data
			GuildExportData = {
				GuildExport = {
					guild = {
						guildName=guildName,
						members={},
					},
					ExportTime = time(),
				}
			}
			for i=1, count do
				name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile = GetGuildRosterInfo(i);
        years, months, days, hours = GetGuildRosterLastOnline(i);
				debug(name.." "..rank.." "..note)
				GuildExportData.GuildExport.guild.members[classFileName] = GuildExportData.GuildExport.guild.members[classFileName] or {}
				GuildExportData.GuildExport.guild.members[classFileName][name] = {
					rankIndex=rankIndex,
					note=note,
					level=level,
          status=status,
          achievementPoints=achievementPoints,
          achievementRank=achievementRank,
          online=online,
          lastOnline={
            years=years,
            months=months,
            days=days,
            hours=hours,
          },
				}
			end
			print("GuildExport export done.")
		end
		return count
	else
		return false
	end
end

function GuildExport:OLDGetXmlStringHelper(data,inset)
	local result = ""
	for k,v in pairs(data) do
		result = result .. inset .. "<"..k..">" ..
		(
			(type(v) == "table")
			and (GuildExport:GetXmlStringHelper(v,inset.."  ") .. inset)
			or v
		) .. "</"..k..">"
	end
	return result
end

function GuildExport:GetXmlStringHelper(data, levels)
	local result = ""
  if levels < 1 then
    return result
  end
	for k,v in pairs(data) do
		result = result .. "<"..k..">" ..
		(
			(type(v) == "table")
			and (GuildExport:GetXmlStringHelper(v,levels-1))
			or v
		) .. "</"..k..">"
	end
	return result
end

function GuildExport:GetXmlString()
	return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"..GuildExport:GetXmlStringHelper(GuildExportData,10)
end

function GuildExport:GetCSVString()
    local count = GetNumGuildMembers(true)
    if count>0 then
        local t = {}
        t[1] = "name;rank;rankIndex;level;class;zone;note;officernote;status;classFileName;achievementPoints;achievementRank;isMobile;lastonline_years;lastonline_months;lastonline_days;lastonline_hours"
        for i=1, count do
            name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile = GetGuildRosterInfo(i);
            years, months, days, hours = GetGuildRosterLastOnline(i);
            local t2 = {name, rank, rankIndex, level, class, zone, note, officernote, status, classFileName, achievementPoints, achievementRank, tostring(isMobile), years, months, days, hours}
            for k,v in pairs(t2) do
                t2[k] = string.gsub(v,";",",")
            end
            t[i+1] = table.concat(t2,';')
        end
        local result = table.concat(t,"\n")
        return result
    end
    return ""
end

function GuildExport:Export()
    if GuildExport:ExportToWtf() then
        StaticPopup_Show ("GUILDEXPORT", "succes")
    else
        StaticPopup_Show ("GUILDEXPORT", "failed")
    end
end

function GuildExport:ShowCSV()
    local CSV = GuildExport:GetCSVString()
    self.CSV = CSV
	if CSV=="" then
		local popup = StaticPopup_Show ("GUILDEXPORT_CSV", "failed","test2")
        popup.editBox:SetText('test4')
	else
		StaticPopup_Show ("GUILDEXPORT_CSV", "succes")
	end
end

function GuildExport_OnEvent(self, event, arg1)
  if event == "VARIABLES_LOADED" then
	GuildExport:UnregisterEvent("VARIABLES_LOADED")
    GuildExport:Load()
  end
end
GuildExport:SetScript("OnEvent", GuildExport_OnEvent)
GuildExport:RegisterEvent("VARIABLES_LOADED")

SLASH_GUILDEXPORT1 = "/guildexport"
SLASH_GUILDEXPORT2 = "/ge"
SlashCmdList["GUILDEXPORT"] = function(msg)
    local cmd = msg:lower()
    if cmd == "load" or cmd == "on" or cmd == "ver" then
        GuildExport:Load()
    elseif cmd == "unload" or cmd == "off" then
        GuildExport:Unload()
    elseif cmd == "exportwtf" then
        GuildExport:ExportToWtf()
    elseif cmd == "export" then
        GuildExport:Export()
    elseif cmd == "debug" then
        debugging = not debugging
        print("GuildExport debugging "..(debugging and "enabled" or "disabled"))
    elseif cmd == "csv" then
        GuildExport:ShowCSV()
    else
        print("/guildexport [ on | off | export | debug | csv ]")
    end
end

StaticPopupDialogs["GUILDEXPORT"] = {
  text = "GuildExport %s\npress ctrl-a then ctrl-c to copy",
  button1 = "Ok",
--  button2 = "No",
  OnAccept = function()
      GreetTheWorld()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
    self.editBox:SetText(GuildExport:GetXmlString())
  end,
  OnAccept = function (self, data, data2)
    local text = self.editBox:GetText()
    -- do whatever you want with it
  end,
  hasEditBox = true,
  editBoxWidth = 350,
  maxLetters=0,
}

StaticPopupDialogs["GUILDEXPORT_CSV"] = {
  text = "GuildExport %s\npress ctrl-a then ctrl-c to copy",
  button1 = "Ok",
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
    --debug(GuildExport.CSV)
    self.editBox:SetText(GuildExport.CSV)
    --self.editBox:SetText("test3")
  end,
  hasEditBox = true,
  editBoxWidth = 350,
  maxLetters=0,
}
