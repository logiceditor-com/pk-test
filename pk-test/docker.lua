--------------------------------------------------------------------------------
-- docker.lua
-- This file is a part of pk-test library
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

require "lua-aplicado.module" -- for import()
require "lfs" -- for lfs.chdir(), lfs.currentdir()

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

local log, dbg, spam, log_error = make_loggers("test/docker", "TDKR")

-----------------------------------------------------------------------

--[[
what function does:
  starts docker container, calls handler, stops container after
  handler's end.
how does function handle errors:
  function currently crashes with calling error() on
  any error.
function returns true on success. ]]
local function do_with_docker (cfg_dir, handler)
  arguments(
      "string", cfg_dir,
      "function", handler
    )

  local cur_dir

  -- DEBUG
  local log_cwd = function()
    local cwd, descr = lfs.currentdir()
    if not cwd then
      log_error("lfs.currentdir() failure: ", descr)
      return false
    else
      dbg("current work dir is ", cwd)
      return true
    end
  end

  local enter_cfg_dir = function()
    local ok, descr = lfs.chdir(cfg_dir)

    if not ok then
      log_cwd()
      log_error("cannot enter cfg dir: ", descr)
      return false
    else
      return true
    end
  end

  local restore_dir = function()
    local ok, descr = lfs.chdir(cur_dir)

    if not ok then
      log_cwd()
      log_error("cannot return to current dir: ", descr)
      return false
    else
      return true
    end
  end

  local remember_cur_dir = function()
    local descr
    cur_dir, descr = lfs.currentdir()

    if not cur_dir then
      log_error("lfs.currentdir() failure: ", descr)
      return false
    else
      return true
    end
  end

  local start_container = function()
    local exec_st = shell_exec("docker-compose", "up", "-d")
    if exec_st ~= 0 then
      log_cwd()
      log_error("'docker-compose up -d' returned non-zero value")
      return false
    else
      return true
    end
  end

  local stop_container = function()
    local exec_st = shell_exec("docker-compose", "down")
    if exec_st ~= 0 then
      log_cwd()
      log_error("'docker-compose down' returned non-zero value")
      return false
    else
      return true
    end
  end

  local exec_handler = function()
    local ok, descr = pcall(handler)

    if not ok then
      log_error("handler has been crashed with error: ", descr)
      return false
    else
      return true
    end
  end

  -- start docker container
  if not remember_cur_dir() then
    error("cannot remember current dir")
  end
  if not enter_cfg_dir() then
    error("cannot enter cfg dir")
  end
  if not start_container() then
    restore_dir()
    error("cannot start container")
  end
  if not restore_dir() then
    stop_container()
    error("cannot return to current dir")
  end

  -- call handler()
  if not exec_handler() then
    local _ =
      enter_cfg_dir() and
      stop_container() and
      restore_dir()
    error("handler execution error")
  end

  -- stop container
  if not remember_cur_dir() then
    error("cannot remember current dir 2")
  end
  if not enter_cfg_dir() then
    error("cannot enter cfg dir 2")
  end
  if not stop_container() then
    restore_dir()
    error("cannot stop container")
  end
  if not restore_dir() then
    error("cannot return to current dir 2")
  end

  return true
end

return
{
  do_with_docker = do_with_docker;
}

