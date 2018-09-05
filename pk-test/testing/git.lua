--------------------------------------------------------------------------------
-- http_client.lua: test-only utilities for git
-- This file is a part of pk-test library
-- Copyright (c) Alexander Gladysh <ag@logiceditor.com>
-- Copyright (c) Dmitry Potapov <dp@logiceditor.com>
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

local assert, pairs
    = assert, pairs

--------------------------------------------------------------------------------

local arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments'
      }

local write_file,
      join_path
      = import 'lua-aplicado/filesystem.lua'
      {
        'write_file',
        'join_path'
      }

local git_add_path,
      git_commit_with_message,
      git_init
      = import 'lua-aplicado/shell/git.lua'
      {
        'git_add_path',
        'git_commit_with_message',
        'git_init'
      }

local temporary_directory
      = import 'lua-aplicado/testing/decorators.lua'
      {
        'temporary_directory'
      }

--------------------------------------------------------------------------------

local commit_content = function(path, files_content, commit_message)
  arguments(
      "string", path,
      "table", files_content,
      "string", commit_message
    )

  for filename, file_content in pairs(files_content) do
    assert(write_file(join_path(path, filename), file_content))
    git_add_path(path, filename)
  end

  git_commit_with_message(path, commit_message)
end

local create_repo_with_content = function(
    path,
    files_content,
    initial_commit_message
  )
  arguments(
      "string", path,
      "table", files_content,
      "string", initial_commit_message
    )

  git_init(path)
  commit_content(path, files_content, initial_commit_message)
end

return
{
  commit_content = commit_content;
  create_repo_with_content = create_repo_with_content;
}
