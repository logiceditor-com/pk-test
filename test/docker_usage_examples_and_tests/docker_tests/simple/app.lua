#!/usr/bin/env lua

socket = require "socket"

local lsock = assert(socket.bind("*", 5000))
while true do
	local sock = assert(lsock:accept())
	local recverr = false
	while true do
		local line = sock:receive("*l")
		if not line then
			recverr = true
			break
		end
		if line == "" then
			break
		end
	end
	if recverr then
		sock:close()
	else
		sock:send("HTTP/1.0 200 OK\r\n")
		sock:send("\r\n")
		sock:send("du fs098dfusdf8 usdfuh23kuhdkejfhskjf\r\n")
		sock:close()
	end
end

