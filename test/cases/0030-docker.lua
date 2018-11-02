--------------------------------------------------------------------------------
-- 0030-docker.lua: tests for pk-test/docker.lua
-- This file is a part of pk-test library
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

local socket = require 'socket'

local do_with_docker
      = import 'pk-test/docker.lua'
      {
        'do_with_docker'
      }

local ensure_equals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_equals'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error
     = import 'lua-aplicado/log.lua' { 'make_loggers' } (
         "test/docker", "T003"
       )

--------------------------------------------------------------------------------

local test = (...)('do_with_docker')

--------------------------------------------------------------------------------

local CONTAINER_CFG_DIR = 'test/data/echoserv_container5'
local WRONG_DIR = 'nothing/nowhere/1856916550571289837'

test:case 'run-successfull-handler' (function()
  local handler = function()
    local a = 1 + 2
  end

  do_with_docker(CONTAINER_CFG_DIR, handler)
end)

test:case 'run-handler-which-will-crash' (function()
  local handler = function()
    error('forced error')
  end

  local ok = pcall(do_with_docker, CONTAINER_CFG_DIR, handler)
  ensure_equals('handler() crashed (as expected)', ok, false)
end)

test:case 'run-docker-with-wrong-dir' (function()
  local handler = function()
    local a = 1 + 2
  end

  local ok = pcall(do_with_docker, WRONG_DIR, handler)
  ensure_equals('setting of wrong dir raises an error (as expected)', ok, false)
end)

test:case 'communicate-with-app-inside-contnr-via-tcp' (function()

  local handler = function()
    local sock = assert(socket.connect('127.0.0.1', 5000))
    local msg = 'Lorem ipsum'
    assert(sock:settimeout(5))
    assert(sock:send(msg..'\n'))
    local resp = tostring(assert(sock:receive('*l')))
    ensure_equals('response from echo matches sent message', resp, msg)
    assert(sock:close())
  end

  do_with_docker(CONTAINER_CFG_DIR, handler)
end)

