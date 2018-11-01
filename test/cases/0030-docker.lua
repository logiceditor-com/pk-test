--------------------------------------------------------------------------------
-- 0030-docker.lua: tests for pk-test/docker.lua
-- This file is a part of pk-test library
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

local socket = require "socket"

local do_with_docker
      = import 'pk-test/docker.lua'
      {
        'do_with_docker'
      }

--------------------------------------------------------------------------------

local test = (...)("do_with_docker")

--------------------------------------------------------------------------------

local CONTAINER_CFG_DIR = "test/data/echoserv_container5"
local WRONG_DIR = "nothing/nowhere/1856916550571289837"

test:case "run-successfull-handler" (function()
  local handler = function()
    local a = 1 + 2
  end

  do_with_docker(CONTAINER_CFG_DIR, handler)
end)

test:case "run-handler-which-will-crash" (function()
  local handler = function()
    error("forced error")
  end

  if pcall(do_with_docker, CONTAINER_CFG_DIR, handler) then
    error("no reaction on handler() crash")
  end
end)

test:case "run-docker-with-wrong-dir" (function()
  local handler = function()
    local a = 1 + 2
  end

  if pcall(do_with_docker, WRONG_DIR, handler) then
    error("no reaction on wrong dir for docker")
  end
end)

test:case "communicate-with-app-inside-contnr-via-tcp" (function()

  local handler = function()
    local sock = assert(socket.connect("127.0.0.1", 5000))
    local msg = "hey, you"
    assert(sock:settimeout(5))
    assert(sock:send(msg.."\n"))
    local resp = tostring(assert(sock:receive("*l")))
    if resp ~= msg then
      error("response doesn't match")
    end
    assert(sock:close())
  end

  do_with_docker(CONTAINER_CFG_DIR, handler)
end)

