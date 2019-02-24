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

local fail
      = import 'lua-aplicado/error.lua'
      {
        'fail'
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
  end
  dbg('current work dir is ', res)
  return true
end

local change_dir = function(dir)
  local ok, descr = lfs.chdir(dir)
  if not ok then
   log_cwd()
   log_error('Can not change dir: ', descr)
   return false
  end
  return true
end

local get_cur_dir = function()
  local cur_dir, descr = lfs.currentdir()
  if not cur_dir then
    log_error('lfs.currentdir() failure: ', descr)
    return nil, "lfs.currentdir() failure"
  end
  return cur_dir
end

local start_container = function()
  local status = shell_exec('docker-compose', 'up', '-d')
  if status ~= 0 then
    log_cwd()
    log_error('"docker-compose up -d" returned non-zero value')
    return false
  end
  return true
end

local stop_container = function()
  local status = shell_exec('docker-compose', 'down')
  if status ~= 0 then
    log_cwd()
    log_error('"docker-compose down" returned non-zero value')
    return false
  end
  return true
end

local exec_handler = function(handler)
  local ok, err = pcall(handler)

  if not ok then
    pcall(log_error, 'handler has been crashed with error: ', err)
    return false
  end
  return true
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
    'do_with_docker() is called with arguments: dir =', cfg_dir,
    'handler =', handler
  )

  -- start docker container --
  log('do_with_docker(): starting docker container')
  local _, cur_dir = xpcall(
    get_cur_dir,
    function()
      return nil
    end
  )
  if not cur_dir then
    fail('ddkr_apdir', 'Can not get app current dir')
  end
  -- change dir
  local _, ok = xpcall(
    function()
      return change_dir(cfg_dir)
    end,
    function()
      return nil
    end
  )
  if not ok then
    fail('ddkr_encfg', 'Can not enter cfg dir')
  end
  -- start container
  local _, ok = xpcall(
    start_container,
    function()
      return nil
    end
  )
  if not ok then
    pcall(change_dir, cur_dir)
    fail('ddkr_rctnr', 'Can not start container')
  end
  -- return to app dir
  local _, ok = xpcall(
    function()
      return change_dir(cur_dir)
    end,
    function()
      return nil
    end
  )
  if not ok then
    pcall(stop_container)
    fail('ddkr_apret', 'Can not return to app current dir')
  end

  -- call handler() --
  log('do_with_docker(): executing handler()')
  if not exec_handler(handler) then
    local _, ok = xpcall(
      function()
        return change_dir(cfg_dir)
      end,
      function()
        return nil
      end
    )
    if ok then
      pcall(stop_container)
      pcall(change_dir, cur_dir)
    end
    fail('ddkr_ehndr', 'handler execution error')
  end

  -- stop container --
  log('do_with_docker(): stopping container')
  local _, cur_dir = xpcall(
    get_cur_dir,
    function()
      return nil
    end
  )
  if not cur_dir then
    fail('ddkr_adir2', 'Can not get app current dir 2')
  end
  -- change to cfg dir
  local _, ok = xpcall(
    function()
      return change_dir(cfg_dir)
    end,
    function()
      return nil
    end
  )
  if not ok then
    fail('ddkr_ecfg2', 'Can not enter cfg dir 2')
  end
  -- stop container
  local _, ok = xpcall(
    stop_container,
    function()
      return nil
    end
  )
  if not ok then
    pcall(change_dir, cur_dir)
    fail('ddkr_tctnr', 'Can not stop container')
  end
  -- change to app dir
  local _, ok = xpcall(
    function()
      return change_dir(cur_dir)
    end,
    function()
      return nil
    end
  )
  if not ok then
    fail('ddkr_aret2', 'Can not return to app current dir 2')
  end

  return true
end

return
{
  log_cwd = log_cwd;
  change_dir = change_dir;
  get_cur_dir = get_cur_dir;
  stop_container = stop_container;
  start_container = start_container;
  exec_handler = exec_handler;
  do_with_docker = do_with_docker;
}

