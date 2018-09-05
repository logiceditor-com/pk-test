--------------------------------------------------------------------------------
-- server.lua
-- This file is a part of pk-test library
-- Copyright (c) Alexander Gladysh <ag@logiceditor.com>
-- Copyright (c) Dmitry Potapov <dp@logiceditor.com>
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

local posix = require 'posix'
local socket = require 'socket'
local copas = require 'copas'

--------------------------------------------------------------------------------

local bind_many
      = import 'lua-nucleo/functional.lua'
      {
        'bind_many'
      }

local ensure,
      ensure_error
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_error'
      }

local arguments,
      method_arguments,
      optional_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'method_arguments',
        'optional_arguments'
      }

local timap,
      tremap_to_array
      = import 'lua-nucleo/table.lua'
      {
        'timap',
        'tremap_to_array'
      }

local xfinally
      = import 'lua-aplicado/error.lua'
      {
        'xfinally'
      }

local copas_read_and_handle
      = import 'lua-aplicado/srv/copas_conn.lua'
      {
        'read_and_handle'
      }

local make_loggers
      = import 'lua-aplicado/log.lua'
      {
        'make_loggers'
      }

local update_test_logging_system_pid
      = import 'pk-test/log.lua'
      {
        'update_test_logging_system_pid'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers("test/srv", "TSV")

--------------------------------------------------------------------------------

local TIMEOUT_EPSILON = 0.2 -- Arbitrary value
local LOCALHOST = "127.0.0.1"
local MAX_PORT = 65535

local create_next_host_port_func = function(base_port, port_incr_limit)
  base_port = base_port or 50000
  optional_arguments(
      "number", base_port,
      "number", port_incr_limit
    )

  ensure(
      "PK_TEST_BASE_PORT shouldn't be greater than " .. MAX_PORT,
      base_port < MAX_PORT
    )
  port_incr_limit = math.min(port_incr_limit or (base_port + 10000), MAX_PORT)
  ensure(
      "PK_TEST_PORT_LIMIT should be greater than PK_TEST_BASE_PORT",
      port_incr_limit > base_port
    )

  local next_port = { }

  return function(name, host)
    optional_arguments(
        "string", name,
        "string", host
      )

    host = host or LOCALHOST
    local port = next_port[host] or base_port
    local sock
    while true do
      if port > port_incr_limit then
        port = base_port
      end
      log("trying to allocate test port", port, "at host", host)
      sock = socket.connect(host, port)
      if sock then
        sock:close()
        port = port + 1
      else
        log(
            "allocated test host",
            host,
            "port",
            port,
            (name and "for "..name or "")
          )
        next_port[host] = port + 1
        return host, port
      end
    end
  end
end

-- TODO: https://redmine-tmp.iphonestudio.ru/issues/1587
--       Code working with environment variables should be fully covered by
--       tests.
local PK_TEST_BASE_PORT = os.getenv("PK_TEST_BASE_PORT")
local PK_TEST_PORT_LIMIT = os.getenv("PK_TEST_PORT_LIMIT")

if PK_TEST_BASE_PORT then
  PK_TEST_BASE_PORT = assert(
      tonumber(PK_TEST_BASE_PORT),
      "PK_TEST_BASE_PORT should be a number"
    )
end
if PK_TEST_PORT_LIMIT then
  PK_TEST_PORT_LIMIT = assert(
      tonumber(PK_TEST_PORT_LIMIT),
      "PK_TEST_PORT_LIMIT should be a number"
    )
end

local next_host_port = create_next_host_port_func(
    PK_TEST_BASE_PORT,
    PK_TEST_PORT_LIMIT
  )

-- TODO: https://redmine-tmp.iphonestudio.ru/issues/1541
-- Kept for compatibility with code which does not use next_host_port()
local BADHOST, BADPORT = next_host_port(LOCALHOST)

local allocate_port = function(port_key, default_host, name)
  optional_arguments(
      "string", port_key,
      "string", default_host,
      "string", name
    )

  return function(test_function)
    return function(env)
      port_key = port_key or "port"
      local address = { }
      address.host, address.port = next_host_port(name, default_host)
      env[port_key] = address
      return xfinally(
          bind_many(test_function, env),
          function()
            env[port_key] = nil
          end
        )
    end
  end
end

local spawn_tcp_server
do

  -- TODO: Use Unix Domain Sockets instead! (Or as well.)

  spawn_tcp_server = function(tcp_server_loop)
    local host, port = next_host_port()

    local server_pid = posix.fork()
    if not server_pid then
      error("fork failed")
    elseif server_pid ~= 0 then
      log("forked server to pid", server_pid, "host", host, "port", port)
      return host, port, server_pid
    end

    update_test_logging_system_pid()

    local res, err = xpcall(
        function()
          tcp_server_loop(host, port)
          log("spawn_tcp_server: server loop finished")
          return true
        end,
        function(err)
          err = debug.traceback(err)
          log_error("tcp server loop failed:", err)
          return err
        end
      )

    -- HACK to prevent double tests run if we've got here.
    -- TODO: Call os.exit()?!
    log("spawn_tcp_server: spawning after-server infinite loop")
    if res then
      while true do
        log("spawn_tcp_server: after-server-loop tick")
        socket.sleep(10)
      end
    else
      while true do
        log_error("spawn_tcp_server: SERVER LOOP FAILED (see above)")
        socket.sleep(1)
      end
    end
  end
end

local spawn_server
do
  spawn_server = function(server_loop)

    local server_pid = posix.fork()
    if not server_pid then
      error("fork failed")
    elseif server_pid ~= 0 then
      log("forked server to pid", server_pid)
      return server_pid
    end

    update_test_logging_system_pid()

    local res, err = xpcall(
        function()
          server_loop()
          log("spawn_server: server loop finished")
          return true
        end,
        function(err)
          err = debug.traceback(err)
          log_error("server loop failed:", err)
          return err
        end
      )

    -- HACK to prevent double tests run if we've got here.
    -- TODO: Call os.exit()?!
    log("spawn_server: spawning after-server infinite loop")
    if res then
      while true do
        log("spawn_server: after-server-loop tick")
        socket.sleep(10)
      end
    else
      while true do
        log_error("spawn_server: SERVER LOOP FAILED (see above)")
        socket.sleep(1)
      end
    end
  end
end

-- TODO: Rename to do_with_tcp_server or generalize!
local do_with_server = function(loop_fn, handler_fn)
  log("main pid", posix.getpid("pid"))

  local host, port, server_pid = spawn_tcp_server(loop_fn)

  log("doing with server pid", server_pid, "host", host, "port", port)

  local res, err = xpcall(
      function()
        handler_fn(host, port, server_pid)
      end,
      function(err)
        err = debug.traceback(err)
        log_error(err)
        return err
      end
    )

  log("done with server, killing pid", server_pid)

-- TODO: https://redmine-tmp.iphonestudio.ru/issues/1547
--       Must tell server we're killing it.
  posix.kill(server_pid)
  posix.wait(server_pid)

  assert(res, err)
end

local do_with_servers = function(loop_fns, handler_fn)
  log("main pid", posix.getpid("pid"))

  local pid_list = { }

  local res, err = xpcall(function()
    for i, loop_fn in ipairs(loop_fns) do
      local server_pid = spawn_server(loop_fn)
      pid_list[i] = server_pid
    end
  end, debug.traceback)

  if res then
    res, err = xpcall(function()
      handler_fn(pid_list)
    end, debug.traceback)
  end

  -- First kill all servers
  for i, pid in ipairs(pid_list) do
    -- TODO:  https://redmine-tmp.iphonestudio.ru/issues/1547
    --        Must tell server we're killing it.
    posix.kill(pid)
  end

  -- Then wait for them to finish
  for i, pid in ipairs(pid_list) do
    posix.wait(pid)
  end

  assert(res, err) -- TODO: Enhance error reporting!
end

local make_dumb_server_loop = function(data, spawn_timeout, keep_connection)
  arguments(
      "string", data
    )
  optional_arguments(
      "number", spawn_timeout,
      "boolean", keep_connection
    )

  return function(host, port)
    if spawn_timeout then
      log("waiting", spawn_timeout, "s before spawning dumb server loop")
      socket.sleep(spawn_timeout)
    end

    log("spawning dumb server loop on host", host, "port", port)

    local server = ensure("bind", socket.bind(host, port))

    while true do
      local conn = ensure("accept", server:accept())
      log("got connection for dumb server loop on host", host, "port", port)

      conn:send(data)

      log("handled connection for dumb server loop on host", host, "port", port)

      if not keep_connection then
        log("closing connection")
        conn:close()
        conn = nil
      else
        log("keeping connection")
      end
    end
  end
end

-- TODO: Promote to engine and reuse?
local make_copas_server_loop
do
  local make_connection_handler = function(prefix_length, command_handlers)
    return function(conn)
      local peername, peerport = conn:getpeername()
      log("connected client", peername, peerport)

      while
        assert(copas_read_and_handle(conn, prefix_length, command_handlers))
      do
        dbg("connection tick", peername, peerport)
        -- All is done in handle_command
      end
    end
  end

  make_copas_server_loop = function(prefix_length, command_handlers)
    arguments(
        "number", prefix_length,
        "table", command_handlers
      )

    local handler = make_connection_handler(prefix_length, command_handlers)

    return function(host, port)
      arguments(
          "string", host,
          "number", port
        )

      log("spawning copas server loop on host:", host, "port:", port)
      local server = assert(socket.bind(host, port))

      copas.addserver(server, handler)
      copas.loop()
    end
  end
end

return
{
  BADHOST = BADHOST;
  BADPORT = BADPORT;
  TIMEOUT_EPSILON = TIMEOUT_EPSILON;
  next_host_port = next_host_port;
  allocate_port = allocate_port;
  spawn_tcp_server = spawn_tcp_server;
  do_with_server = do_with_server;
  do_with_servers = do_with_servers;
  make_dumb_server_loop = make_dumb_server_loop;
  make_copas_server_loop = make_copas_server_loop;
  create_next_host_port_func = create_next_host_port_func;
}
