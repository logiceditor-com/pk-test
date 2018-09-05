--------------------------------------------------------------------------------
-- 0010-testbrowser.lua: self-tests for testbrowser
-- This file is a part of pk-test library
-- Copyright (c) Alexander Gladysh <ag@logiceditor.com>
-- Copyright (c) Dmitry Potapov <dp@logiceditor.com>
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

require 'wsapi.request'
require 'wsapi.response'

local ensure,
      ensure_equals,
      ensure_fails_with_substring,
      ensure_returns,
      ensure_strequals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_fails_with_substring',
        'ensure_returns',
        'ensure_strequals'
      }

local make_testbrowser,
      all
      = import 'pk-test/testbrowser.lua'
      {
        'make_testbrowser'
      }

local make_http_tcp_server_loop
      = import 'pk-test/http_server.lua'
      {
        'make_http_tcp_server_loop'
      }

local make_wsapi_tcp_server_loop
      = import 'pk-test/wsapi_server.lua'
      {
        'make_wsapi_tcp_server_loop'
      }

local BADHOST,
      BADPORT,
      do_with_server
      = import 'pk-test/server.lua'
      {
        'BADHOST',
        'BADPORT',
        'do_with_server'
      }

local check_connect,
      wait_for_server_start
      = import 'pk-test/client.lua'
      {
        'check_connect',
        'wait_for_server_start'
      }

local make_loggers
      = import 'lua-aplicado/log.lua'
      {
        'make_loggers'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers("0010-tetbrowser", "L0010")

--------------------------------------------------------------------------------

local HTTP_DATA =
  {
    ["/foobar/initial"] =
      {
        headers =
          {
            ["Content-Type"] = "text/plain";
            ["Set-Cookie"] = "foobar=42";
          };
        [[BODY for /foobar/initial]]
      };
    ["/foobar/untouched"] =
      {
        headers =
          {
            ["Content-Type"] = "text/plain";
            ["Set-Cookie"] = "bar=33";
          };
        [[BODY for /foobar/unchanged]]
      };
    ["/foobar/same"] =
      {
        headers =
          {
            ["Content-Type"] = "text/plain";
            ["Set-Cookie"] =
              {
                "foobar=42";
                "bar=33";
              };
          };
        [[BODY for /foobar/same]]
      };
    ["/foobar/another"] =
      {
        headers =
          {
            ["Content-Type"] = "text/plain";
            ["Set-Cookie"] =
              {
                "foobar=changed";
                "barfoo=newlyset";
              };
          };
        [[BODY for /foobar/another]]
      };
    ["/foobar/drop"] =
      {
        headers =
          {
            ["Content-Type"] = "text/plain";
            ["Set-Cookie"] =
              {
                "foobar=;exPires=Jan 1 00:00:00 1970 GMT+00";
                "barfoo=   ;max-AGe=0";
              };
          };
        [[BODY for /foobar/drop]]
      };
  }

local wait_for_xavante_start = function(host, port)
  return wait_for_server_start("xavante", host, port)
end

--------------------------------------------------------------------------------

local test = (...)("make_testbrowser", all)

--------------------------------------------------------------------------------

test:group "make_testbrowser"

--------------------------------------------------------------------------------

test:case "GET" (function()
  local test_http_server_loop = make_http_tcp_server_loop(HTTP_DATA)

  do_with_server(
      test_http_server_loop,
      function(host, port, server_pid)
        wait_for_xavante_start(host, port)

        for url, info in pairs(HTTP_DATA) do
          local url = "http://" .. host .. ":" .. port .. url
          local testbrowser = make_testbrowser()

          testbrowser:GET(url)
          testbrowser:ensure_response(
              "GET " .. url .. ". Status is 200, body is " .. info[1],
              200,
              info[1]
            )
          testbrowser:ensure_content_type(
              "content type matches",
              info.headers["Content-Type"]
            )
        end

      end
    )
end)

--------------------------------------------------------------------------------

test:case "POST" (function()
  do_with_server(
      make_wsapi_tcp_server_loop(
          function()
            return function(env)
              local request = wsapi.request.new(env)
              local value = request.POST["value"] or "NONE"
              local response = wsapi.response.new(200, { })
              response:write(value)
              return response:finish()
            end
          end
        ),
      function(host, port, server_pid)
        wait_for_xavante_start(host, port)

        local url = "http://" .. host .. ":" .. port .. "/"
        local testbrowser = make_testbrowser()
        local test_value = "PASSED"

        testbrowser:POST(url, "value=" .. test_value)

        testbrowser:ensure_response("code is 200, body exists", 200, "PASSED")
      end
    )
end)

--------------------------------------------------------------------------------

test:case "cookie-management" (function()
  local test_http_server_loop = make_http_tcp_server_loop(HTTP_DATA)

  do_with_server(
      test_http_server_loop,
      function(host, port, server_pid)
        wait_for_xavante_start(host, port)

        local base_url = "http://"..host..":"..port
        local testbrowser = make_testbrowser()

        -- GET /foobar/initial
        testbrowser:GET(base_url .. "/foobar/initial")
        testbrowser:ensure_cookie_set("cookie 'foobar' set", "foobar")
        ensure_fails_with_substring(
            "ensure_cookie_set must fail when cookie is not set",
            function ()
              testbrowser:ensure_cookie_set(
                  "must have cookie",
                  "foobar1"
                )
            end,
            "must have cookie foobar1"
          )
        testbrowser:ensure_cookie_not_set(
            "cookie 'foobar1' not set",
            "foobar1"
          )
        ensure_fails_with_substring(
            "ensure_cookie_not_set must fail when cookie is set",
            function ()
              testbrowser:ensure_cookie_not_set(
                  "must not have cookie",
                  "foobar"
                )
            end,
            "must not have cookie foobar"
          )
        testbrowser:ensure_cookie_value(
            "cookie 'foobar' is '42'",
            "foobar",
            "42"
          )
        ensure_fails_with_substring(
            "ensure_cookie_value must fail when cookie is not set",
            function ()
              testbrowser:ensure_cookie_value(
                  "must have cookie",
                  "foobar1",
                  "hz"
                )
            end,
            "must have cookie foobar1"
          )

        -- GET /foobar/untouched
        testbrowser:GET(base_url .. "/foobar/untouched")
        testbrowser:ensure_cookie_value(
            "cookie 'foobar' is '42'",
            "foobar",
            "42"
          )
        testbrowser:ensure_cookie_unchanged(
            "cookie 'foobar' not changed",
            "foobar"
          )
        ensure_fails_with_substring(
            "ensure_cookie_set must fail when cookie is unchanged",
            function ()
              testbrowser:ensure_cookie_set(
                  "must not have cookie set",
                  "foobar"
                )
            end,
            "must not have cookie set foobar"
          )
        ensure_fails_with_substring(
            "ensure_cookie_updated must fail when cookie is unchanged",
            function ()
              testbrowser:ensure_cookie_updated(
                  "must not have cookie updated",
                  "foobar"
                )
            end,
            "must not have cookie updated foobar"
          )

        -- GET /foobar/same
        testbrowser:GET(base_url .. "/foobar/same")
        testbrowser:ensure_cookie_value(
            "cookie 'foobar' is '42'",
            "foobar",
            "42"
          )
        testbrowser:ensure_cookie_unchanged(
            "cookie 'foobar' is unchanged",
            "foobar"
          )
        testbrowser:ensure_cookie_value(
            "cookie 'bar' is '33'",
            "bar",
            "33"
          )
        testbrowser:ensure_cookie_unchanged(
            "cookie 'bar' is unchanged",
            "bar"
          )

        -- GET /foobar/another
        testbrowser:GET(base_url .. "/foobar/another")
        testbrowser:ensure_cookie_value(
            "cookie 'foobar' has value 'changed'",
            "foobar",
            "changed"
          )
        testbrowser:ensure_cookie_updated(
            "cookie 'foobar' is updated",
            "foobar"
          )
        ensure_fails_with_substring(
            "ensure_cookie_set must fail when cookie is updated",
            function ()
              testbrowser:ensure_cookie_set(
                  "must not have cookie set",
                  "foobar"
                )
            end,
            "must not have cookie set foobar"
          )
        ensure_fails_with_substring(
            "ensure_cookie_not_set must fail when cookie is updated",
            function ()
              testbrowser:ensure_cookie_not_set(
                  "must not have cookie not set",
                  "foobar"
                )
            end,
            "must not have cookie not set foobar"
          )
        ensure_fails_with_substring(
            "ensure_cookie_unchanged must fail when cookie is updated",
            function ()
              testbrowser:ensure_cookie_unchanged(
                  "must not have cookie unchanged",
                  "foobar"
                )
            end,
            "must not have cookie unchanged foobar"
          )

        -- GET /foobar/drop
        testbrowser:GET(base_url .. "/foobar/drop")
        testbrowser:ensure_cookie_not_set("cookie 'foobar' not set", "foobar")
        testbrowser:ensure_cookie_not_set("cookie 'barfoo' not set", "barfoo")
        testbrowser:ensure_cookie_unchanged("cookie 'bar' unchanged", "bar")

        -- clear state
        testbrowser:clear(true)
        testbrowser:ensure_cookie_not_set("cookie 'bar' not set", "bar")

      end
    )
end)

-- Based on real bug scenario - http://redmine.tech-zeli.in/issues/1765
-- Cookie header is lost with old implementation of testbrowser.
test:case "header-field-name" (function()
  do_with_server(
      make_wsapi_tcp_server_loop(
          function()
            return function(env)
              local request = wsapi.request.new(env)
              local request_cookie_value = request.cookies["foo"]
              local response = wsapi.response.new(200, { })
              if request_cookie_value then
                response:set_cookie("foo", request_cookie_value .. "ok")
              end
              return response:finish()
            end
          end
        ),
      function(host, port, server_pid)
        wait_for_xavante_start(host, port)

        local url = "http://" .. host .. ":" .. port .. "/"
        local testbrowser = make_testbrowser()
        local cookie =
        {
          ["name"] = "foo";
          ["value"] = "42";
          ["domain"] = host .. ":" .. port;
          ["path"] = "/";
        }
        testbrowser.cookie_jar:put(cookie)
        testbrowser:POST(url)
        testbrowser:ensure_cookie_value(
            "cookie foo was processed on server",
            "foo",
            "42ok"
          )
      end
    )
end)
