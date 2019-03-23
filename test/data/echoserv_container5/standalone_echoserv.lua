#!/usr/bin/env lua

socket = require "socket"

local lsock = assert(socket.bind("*", 5000))
while true do
  local sock = assert(lsock:accept())
  local recverr = false
  while true do
    local line = sock:receive("*l")
    if not line then
      sock:close()
      break
    end
    sock:send(line .. "\n")
  end
end

