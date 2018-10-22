--ssssss
if not GAMEMODE then return end 

local a = a or {}

if next(a) == nil then
	a.endpoint = WS.Client("wss://gateway.discord.gg/?v=6&encoding=json", 443)
	a.json = include("json.lua")
	a.heartbeat_ack = true --true for initial heartbeat
	a.seq = "null"
	a.channel = "501198430031577090"
	a.token = ""
end

if not file.Exists("cfg/relay_bot_token.cfg", "GAME") or file.Read("cfg/relay_bot_token.cfg", "GAME") == nil then
	print("Error! No bot token for Discord relay!")
	a.token = ""
else
	a.token = file.Read("cfg/relay_bot_token.cfg", "GAME"):Trim()
end

local function sendmessage(text)
	local t_post = {
		content = "`".. os.date("%H:%M:%S").."` "..text
	}

	local body = util.TableToJSON(t_post, true)
	local t_struct = {
		failed = function(err)
			MsgC(Color(255, 0, 0), "HTTP error in sending raw message to discord: " .. err .. "\n")
		end,
		success = print,
		method = "POST",
		url = "https://discordapp.com/api/v6/channels/"..a.channel.."/messages",
		parameters = t_post,
		body = body,
		headers = {
			["Authorization"] = "Bot " .. a.token,
			["Content-Type"] = "application/json",
			["Content-Length"] = body:len() or "0",
		},
		type = "application/json"
	}
	HTTP(t_struct)
end

local function senddata(data_send)
	data_send = a.json.encode(data_send)
	a.endpoint:Send(data_send)
	print("We sent: ", data_send)
end

if not a.endpoint:IsActive() then 
	a.endpoint.echo = true
	a.endpoint:Connect()
end

--when a message is recieved
a.endpoint:on("message", function(data_received)
    local data_received_json = util.JSONToTable(data_received)
    print("We recieved: ", data_received_json["op"])
	--PrintTable(util.JSONToTable(data)["op"])
	
	if data_received_json["s"] then 
		seq = data_received_json["s"]
	end
	
	--Hello Opcode
    if data_received_json["op"] == 10 then
		--Send identification
		senddata ({
			["op"]= 2,
			["d"]= {
				["token"]= a.token,
				["properties"]= {
					["$os"] = "windows",
					["$browser"] = "garrysmod",
					["$device"] = "garrysmod"				
				}
			}
		})
		
		--Start heartbeat
		timer.create("heartbeat", data_received_json["d"]["heartbeat_interval"]/1000, 0, function()
			if not heartbeat_ack then 
				timer.remove("heartbeat")
				error("Heartbeat not Acknowledged") 
				return 
			end
	
			senddata({
				["op"]= 1,
				["d"]= seq
			})
			
			heartbeat_ack = false
			heartbeat(delay)
		end)
    end
	
	--Heartbeat Acknowledged Opcode
	if data_received_json["op"] == 11 then
		heartbeat_ack = true
    end
	
	--Opcode whatever
	if data_received_json["op"] == 0 then
		if data_received_json["t"]=="MESSAGE_CREATE" then
			if not data_received_json["d"]["author"]["bot"] then
			PrintTable(data_received_json)
			end
		end
    end
end)


hook.Add("PlayerSay", "Discord_Webhook_Chat", function(ply, text, teamchat)
	local nick = ply:Nick()
	local sid = ply:SteamID()
	local sid64 = ply:SteamID64()

	local text = text:gsub("(@everyone)", "[at]everyone")
	local text = text:gsub("(@here)", "[at]here")
	
	sendmessage("`"..nick.."`: "..text)

	
	-- http.Fetch("http://steamcommunity.com/profiles/" .. sid64 .. "?xml=1", function(content, size)
		-- local avatar = content:match("<avatarFull><!%[CDATA%[(.-)%]%]></avatarFull>")
		-- print(avatar, sid64)
	-- end)
	
end)


hook.Add("ULibCommandCalled", "Discord_UlibCommandCalled", function(ply, cmd, args)
	if not IsValid(ply) then return end
	local argss = ""
	for a,b in pairs(args) do argss = argss .. " " .. b end
	local nick = ply:GetName()
	--sendmessage(os.date("%H:%M:%S") .. ": **" .. nick .. "** ran command **".. cmd .. argss.."**")
end)
