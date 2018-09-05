--------------------------------------------------------------------------------
-- 0020-git.lua: self-tests for git test utilities
-- This file is a part of pk-test library
-- Copyright (c) Alexander Gladysh <ag@logiceditor.com>
-- Copyright (c) Dmitry Potapov <dp@logiceditor.com>
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

local ensure_equals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_equals'
      }

local make_loggers
      = import 'lua-aplicado/log.lua'
      {
        'make_loggers'
      }

local temporary_directory
      = import 'lua-aplicado/testing/decorators.lua'
      {
        'temporary_directory'
      }

local read_file,
      join_path
      = import 'lua-aplicado/filesystem.lua'
      {
        'read_file',
        'join_path'
      }

local git_clone
      = import 'lua-aplicado/shell/git.lua'
      {
        'git_clone'
      }

local commit_content,
      create_repo_with_content,
      git_exports
      = import 'pk-test/testing/git.lua'
      {
        'commit_content',
        'create_repo_with_content'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers("0020-git", "L0020")

--------------------------------------------------------------------------------

local test = (...)("git", git_exports)

local PROJECT_NAME = "lua-test"

--------------------------------------------------------------------------------

test:tests_for "commit_content" "create_repo_with_content"
test:case "create_repo_and_commit"
  :with(temporary_directory("source_dir", PROJECT_NAME))
  :with(temporary_directory("destination_dir", PROJECT_NAME)) (
function(env)
  create_repo_with_content(
      env.source_dir,
      {
        ["testfile1"] = "test data 1";
      },
      "initial commit"
    )

  commit_content(
      env.source_dir,
      {
        ["testfile2"] = "test data 2";
      },
      "commit2"
    )

  git_clone(env.destination_dir, env.source_dir)

  ensure_equals(
      "contents of the cloned files must match the source",
      read_file(join_path(env.destination_dir, "testfile1")),
      "test data 1"
    )
  ensure_equals(
      "contents of the cloned files must match the source",
      read_file(join_path(env.destination_dir, "testfile2")),
      "test data 2"
    )
end)

--------------------------------------------------------------------------------
