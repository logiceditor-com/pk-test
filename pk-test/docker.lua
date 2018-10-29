--------------------------------------------------------------------------------
-- docker.lua
-- This file is a part of pk-test library
-- Authors:
--   architecture:
--     dd@logiceditor.com
--   code:
--     dd@logiceditor.com
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

-- dirty hack for local tests. TODO remove in release
_G.posix = require "posix"

require "lua-aplicado.module"
require "lfs"

-----------------------------------------------------------------------

local shell_exec
      = import 'lua-aplicado/shell.lua'
      {
        'shell_exec'
      }

local arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments'
      }

local make_loggers
      = import 'lua-aplicado/log.lua'
      {
        'make_loggers'
      }

-----------------------------------------------------------------------

--[[ DISABLED
local log, dbg, spam, log_error = make_loggers("test/dkr", "TDKR")
]]

-----------------------------------------------------------------------

--[[
what function does:
  starts docker container, calls handler, stops container after
  handler's end.
how does function handle errors:
  function currently crashes with calling assert() or error() on
  any error. mb, this behvr should be fixed in future.
function returns:
  #1 ok          - boolean, true if all is ok,
  #2 error_descr - string or nil                 ]]
local function do_with_docker (cfg_dir, handler)

  arguments(
      "string", cfg_dir,
      "function", handler
    )

  -- start docker container
  local cur_dir = assert(lfs.currentdir())
  assert(lfs.chdir(cfg_dir))
  local exec_st = shell_exec("docker-compose", "up", "-d")
  if exec_st ~= 0 then
    error("'docker-compose up -d' returned non-zero value")
  end
  assert(lfs.chdir(cur_dir))

  -- call handler()
  local is_h_ok, h_descr = pcall(handler)

  -- stop container
  local cur_dir = assert(lfs.currentdir())
  assert(lfs.chdir(cfg_dir))
  local exec_st = shell_exec("docker-compose", "down")
  if exec_st ~= 0 then
    error("'docker-compose down' returned non-zero value")
  end
  assert(lfs.chdir(cur_dir))

  -- check handler err
  if not is_h_ok then
    error(string.format("handler crashed with error: %s", tostring(h_descr)))
  end

  return true
end

return
{
  do_with_docker = do_with_docker;
}

