#!/usr/bin/env lua5.1

local dkr = require "docker"


local handler = function()
  print()
  print(" *** usage_example1: handler(): Hello world!")
  print()
end

dkr.do_with_docker("docker_tests/simple", handler)

