--------------------------------------------------------------------------------
-- docker.lua
-- This file is a part of pk-test library
-- Copyright (c) pk-test authors (see file COPYRIGHT for the license)
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

require 'lua-aplicado.module' -- for import()
require 'lfs' -- for lfs.chdir(), lfs.currentdir()

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

-----------------------------------------------------------------------

local log, dbg, spam, log_error
      = import 'lua-aplicado/log.lua' { 'make_loggers' } (
          'test/docker', 'TDKR'
        )

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
      'string', cfg_dir,
      'function', handler
    )

  log('do_with_docker() is called with arguments: dir=', cfg_dir, 'handler=', handler)

  -- it is not a static variable. functions below
  -- was written to avoid deeply nested ugly 'if' blocks,
  -- so look on functions as on named-blocks-for-using-in-'if'.
  local cur_dir

  local crash = function(err_msg)
    log_error('do_with_docker():', err_msg)
    error(err_msg)
  end

  local log_cwd = function()
    local res, err = lfs.currentdir()
    if not res then
      log_error('lfs.currentdir() failure: ', err)
      return false
    else
      dbg('current work dir is ', res)
      return true
    end
  end

  local enter_cfg_dir = function()
    local res, err = lfs.chdir(cfg_dir)

    if not res then
      log_cwd()
      log_error('cannot enter cfg dir: ', err)
      return false
    else
      return true
    end
  end

  local restore_dir = function()
    local res, err = lfs.chdir(cur_dir)

    if not res then
      log_cwd()
      log_error('cannot return to current dir: ', err)
      return false
    else
      return true
    end
  end

  local remember_cur_dir = function()
    local err
    cur_dir, err = lfs.currentdir()

    if not cur_dir then
      log_error('lfs.currentdir() failure: ', err)
      return false
    else
      return true
    end
  end

  local start_container = function()
    local res = shell_exec('docker-compose', 'up', '-d')
    if res ~= 0 then
      log_cwd()
      log_error('"docker-compose up -d" returned non-zero value')
      return false
    else
      return true
    end
  end

  local stop_container = function()
    local res = shell_exec('docker-compose', 'down')
    if res ~= 0 then
      log_cwd()
      log_error('"docker-compose down" returned non-zero value')
      return false
    else
      return true
    end
  end

  local exec_handler = function()
    local ok, res = pcall(handler)

    if not ok then
      local err = res
      log_error('handler has been crashed with error: ', err)
      return false
    else
      return true
    end
  end

  -- start docker container
  log('do_with_docker(): starting docker container')
  if not remember_cur_dir() then
    crash('cannot remember current dir')
  end
  if not enter_cfg_dir() then
    crash('cannot enter cfg dir')
  end
  if not start_container() then
    restore_dir()
    crash('cannot start container')
  end
  if not restore_dir() then
    stop_container()
    crash('cannot return to current dir')
  end

  -- call handler()
  log('do_with_docker(): executing handler()')
  if not exec_handler() then
    local _ =
          enter_cfg_dir()
      and stop_container()
      and restore_dir()
    crash('handler execution error')
  end

  -- stop container
  log('do_with_docker(): stopping container')
  if not remember_cur_dir() then
    crash('cannot remember current dir 2')
  end
  if not enter_cfg_dir() then
    crash('cannot enter cfg dir 2')
  end
  if not stop_container() then
    restore_dir()
    crash('cannot stop container')
  end
  if not restore_dir() then
    crash('cannot return to current dir 2')
  end

  return true
end

return
{
  do_with_docker = do_with_docker;
}

