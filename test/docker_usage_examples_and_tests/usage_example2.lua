#!/usr/bin/env lua5.1

local dkr = require "docker"

local handler = function()
  error("force error")
end

print("TEST EXPECTS THAT HANDLER WILL CRASH!")
dkr.do_with_docker("docker_tests/simple", handler)

