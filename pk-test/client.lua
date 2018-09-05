--------------------------------------------------------------------------------
-- client.lua
-- This file is a part of pk-test library
-- Copyright (c) Alexander Gladysh <ag@logiceditor.com>
-- Copyright (c) Dmitry Potapov <dp@logiceditor.com>
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

local posix = require 'posix'
local socket = require 'socket'

--------------------------------------------------------------------------------

local arguments,
      method_arguments,
      optional_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'method_arguments',
        'optional_arguments'
      }

local ensure,
      ensure_equals,
      ensure_strequals,
      ensure_tequals,
      ensure_error
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_strequals',
        'ensure_tequals',
        'ensure_error'
      }

local assert_is_table,
      assert_is_function,
      assert_is_number
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table',
        'assert_is_function',
        'assert_is_number'
      }

local make_loggers
      = import 'lua-aplicado/log.lua'
      {
        'make_loggers'
      }

local make_tcp_connector
      = import 'lua-aplicado/connector.lua'
      {
        'make_tcp_connector'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers("test/client", "TCL")

--------------------------------------------------------------------------------

local try_connect = function(host, port, max_retries, sleep_time)
  max_retries = max_retries or 5
  sleep_time = sleep_time or 0.05

  local conn, err
  for i = 1, max_retries do
    log("connecting to", host, port)

    conn, err = socket.connect(host, port)
    if conn then
      log("connected to", host, port)
      err = nil
      break
    end

    log("connection to", host, port, "failed:", err)
    log("sleeping " .. sleep_time .. " secs before retry", i, "of", max_retries)

    socket.sleep(sleep_time)
  end

  return conn, err
end

local check_connect = function(host, port, max_retries, sleep_time)
  return ensure(
      "connect",
      try_connect(host, port, max_retries, sleep_time)
    )
end

--------------------------------------------------------------------------------

local wait_for_server_start = function(name, host, port)
  arguments(
      "string", name,
      "string", host,
      "number", port
    )
  log("probing if", name, "started")
  ensure(name.." started", try_connect(host, port)):close() -- HACK!
  log(name, "launch detected")
end

local wait_for_servers_start = function(msg, server_addresses)
  for i = 1, #server_addresses do
    local address = server_addresses[i]
    wait_for_server_start(msg.." "..(address.name or i), address.host, address.port)
  end
end

--------------------------------------------------------------------------------

local make_volatile_tcp_connector
do
  local set_host_port = function(self, host, port)
    self.tcp_connector_ = make_tcp_connector(host, port)
  end

  local connect = function(self, ...)
    return self.tcp_connector_:connect(...)
  end

  make_volatile_tcp_connector = function(host, port)
    return
    {
      set_host_port = set_host_port;
      connect = connect;
      --
      tcp_connector_ = make_tcp_connector(host, port);
    }
  end
end

--------------------------------------------------------------------------------

return
{
  check_connect = check_connect;
  try_connect = try_connect;
  wait_for_server_start = wait_for_server_start;
  wait_for_servers_start = wait_for_servers_start;
  make_volatile_tcp_connector = make_volatile_tcp_connector;
}
