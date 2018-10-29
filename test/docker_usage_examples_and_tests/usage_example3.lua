#!/usr/bin/env lua5.1

local dkr = require "docker"
local socket = require "socket"

local handler = function()
  local sock = assert(socket.connect("127.0.0.1", 5000))
  assert(sock:send("aaa\nbbb\n\n"))
  assert(sock:settimeout(5))
  local resp = tostring(assert(sock:receive("*a")))
  assert(sock:close())

  print()
  print(string.format(" *** usage_example1: handler(): got response \"\"\"%s\"\"\"", resp))
  print()
end

dkr.do_with_docker("docker_tests/simple", handler)

