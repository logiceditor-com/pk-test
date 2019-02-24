--------------------------------------------------------------------------------
-- docker.lua
-- This file is a part of pk-test library
-- Copyright (c) pk-test authors (see file COPYRIGHT for the license)
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

require 'lua-nucleo' -- for import()

-- for lfs.chdir(), lfs.currentdir()
-- lfs pollutes global namespace, so
-- this is workaround
local orig_lfs = lfs
require 'lfs' -- for lfs.chdir(), lfs.currentdir()
local new_lfs = lfs
lfs = orig_lfs
local lfs = new_lfs

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

local fail = function(err_msg)
  log_error('do_with_docker():', err_msg)
  error(err_msg)
end

local change_dir_safe = function(dir)
  local ok, res, err = pcall(lfs.chdir, dir)

  if not ok then
    err = res
    pcall(log_cwd)
    pcall(log_error, 'cannot change dir crash: ', err)
    return false
  end

  if not res then
    pcall(log_cwd)
    pcall(log_error, 'cannot change dir: ', err)
    return false
  end

  return true
end

local get_cur_dir_safe = function()
  local ok, dir, err = pcall(lfs.currentdir)

  if not ok then
    err = dir
    pcall(log_error, 'lfs.currentdir() is crashed: ', err)
    return nil, "crash"
  end

  if not dir then
    pcall(log_error, 'lfs.currentdir() failure: ', err)
    return nil, err
  end

  return dir
end

local start_container_safe = function()
  local ok, res = pcall(shell_exec, 'docker-compose', 'up', '-d')

  if not ok then
    local err = res
    pcall(log_cwd)
    pcall(
      log_error,
      'call of shell_exec("docker-compose up -d") is crashed:',
      err
    )
    return false
  end

  if res ~= 0 then
    pcall(log_cwd)
    pcall(log_error, '"docker-compose up -d" returned non-zero value')
    return false
  end

  return true
end

local stop_container_safe = function()
  local ok, res = pcall(shell_exec, 'docker-compose', 'down')

  if not ok then
    local err = res
    pcall(log_cwd)
    pcall(
      log_error,
      'call of shell_exec("docker-compose down") is crashed',
      err
    )
    return false
  end

  if res ~= 0 then
    pcall(log_cwd)
    pcall(log_error, '"docker-compose down" returned non-zero value')
    return false
  end

  return true
end

local exec_handler = function(handler)
  local ok, res = pcall(handler)

  if not ok then
    local err = res
    log_error('handler has been crashed with error: ', err)
    return false
  else
    return true
  end
end

-- starts docker container, calls handler, stops container after
-- handler's end.
-- function currently crashes with calling error() on
-- any error.
-- @return true on success
local do_with_docker = function (cfg_dir, handler)
  arguments(
    'string', cfg_dir,
    'function', handler
  )

  log(
    'do_with_docker() is called with arguments: dir=',
    cfg_dir,
    'handler=',
    handler
  )

  -- it is not a static variable. functions below
  -- was written to avoid deeply nested ugly 'if' blocks,
  -- so look on functions as on named-blocks-for-using-in-'if'.
  local cur_dir

  -- start docker container
  log('do_with_docker(): starting docker container')
  cur_dir = get_cur_dir_safe()
  if not cur_dir then
    fail('cannot remember current dir')
  end
  if not change_dir_safe(cfg_dir) then
    fail('cannot enter cfg dir')
  end
  if not start_container_safe() then
    change_dir_safe(cur_dir)
    fail('cannot start container')
  end
  if not change_dir_safe(cur_dir) then
    stop_container_safe()
    fail('cannot return to current dir')
  end

  -- call handler()
  log('do_with_docker(): executing handler()')
  if not exec_handler(handler) then
    if change_dir_safe(cfg_dir) then
      stop_container_safe()
      change_dir_safe(cur_dir)
    end
    fail('handler execution error')
  end

  -- stop container
  log('do_with_docker(): stopping container')
  cur_dir = get_cur_dir_safe()
  if not cur_dir then
    fail('cannot remember current dir 2')
  end
  if not change_dir_safe(cfg_dir) then
    fail('cannot enter cfg dir 2')
  end
  if not stop_container_safe() then
    change_dir_safe(cur_dir)
    fail('cannot stop container')
  end
  if not change_dir_safe(cur_dir) then
    fail('cannot return to current dir 2')
  end

  return true
end

return
{
  log_cwd = log_cwd;
  fail = fail;
  change_dir_safe = change_dir_safe;
  get_cur_dir_safe = get_cur_dir_safe;
  stop_container_safe = stop_container_safe;
  start_container_safe = start_container_safe;
  exec_handler = exec_handler;
  do_with_docker = do_with_docker;
}

