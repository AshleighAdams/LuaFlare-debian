#!/usr/bin/env lua5.1

dofile("inc/hooks.lua")
dofile("inc/htmlwriter.lua")
dofile("inc/requesthooks.lua")
dofile("inc/util.lua")
dofile("inc/request.lua")
dofile("inc/response.lua")

local socket = require("socket")
local ssl = require("ssl")


require("lfs")


function handle_client(client)
	local request, err = Request(client)
	if not request then print(err) return end
	
	print(client:getpeername()  .. " " .. request:method()  .. " " .. request:url())
	
	local response = Response(request)
		hook.Call("Request", request, response) -- okay, lets invoke whatever is hooked
	response:send()
end
hook.Add("HandleClient", "default handle client", handle_client)

local function on_error(why, request, response)
	response:set_status(why.type)
	print("error:", why.type, request:url())
end
hook.Add("Error", "log errors", on_error)

local function on_lua_error(err, trace, args)
	print("lua error:", err, trace)
end
hook.Add("LuaError", "log errors", on_lua_error)

local function autorun(dir)
	dir = dir or "lua/"
	for file in lfs.dir("./lua/") do
		if lfs.attributes(dir .. file, "mode") == "file" then
			if file:StartsWith("ar_") and file:EndsWith(".lua") then
				print("autorun: " .. dir .. file)
				dofile(dir .. file)
			end
		elseif file ~= "." and file ~= ".." and lfs.attributes(dir .. file, "mode") == "directory" then
			autorun(dir .. file .. "/")
		end
	end
end
autorun()

local https = false
local params = {
	mode = "server",
--	protocol = "tlsv1",
	protocol = "sslv3",
	key = "keys/key.pem",
	certificate = "keys/certificate.pem",
--	cafile = "keys/request.pem", -- uncomment these lines if you want to verify the client
--	verify = {"peer", "fail_if_no_peer_cert"},
	options = {"all", "no_sslv2"},
	ciphers = "ALL:!ADH:@STRENGTH",
}

function main()
	local server, err = socket.bind("*", 8080)
	assert(server, err)
	-- so we can spawn many processes
	--server:setoption("reuseport", true)
	
	while true do
		local client = server:accept()
		client:settimeout(1)
		
		if https then
			client, err = ssl.wrap(client, params)
			assert(client, err)
			
			local suc, err = client:dohandshake()
			if not suc then print("ssl failed: ", err) end
		end
		
		hook.Call("HandleClient", client)
		client:close()
	end
end

main() -- then let us run in it