#!/usr/bin/env ruby

require 'English'

def modules
  [
    'android',
    'cli-api',
    'cli-log4j',
    'client',
    'common',
    'filecache',
    'integration-tests',
    'jsonrpc-annotations',
    'jsonrpc-common',
    'jsonrpc-websocket',
    'server',
    'srp',
    'tool'
  ]
end

def remote_branches(repo)
  output = run "cd #{repo} && git branch --remotes"
  lines = output.lines

  branches = lines.select do |line|
    !line.include?('origin/HEAD')
  end

  branches.map do |branch|
    branch.strip.gsub('origin/', '')
  end
end

def branch_exists?(repo, branch)
  `cd #{repo} && git show-branch #{branch}`
  $CHILD_STATUS.exitstatus == 0
end

def subtree_branch(mod, branch)
  "export/#{mod}/#{branch}"
end

def module_repo(path, mod)
  File.join(path, mod)
end

def run(command)
  puts command
  `#{command}`
end

def generate_subtree(talk_repo, mod, branch)
  subtree = subtree_branch(mod, branch)

  puts "Creating subtree #{subtree}"
  commit = `cd #{talk_repo} && git rev-parse origin/#{branch}`
  run "cd #{talk_repo} && git checkout #{commit}"
  run "cd #{talk_repo} && git subtree split --prefix #{mod} --branch #{subtree} -q"
end

def remove_subtree(talk_repo, mod, branch)
  subtree = subtree_branch(mod, branch)
  puts "Removing subtree #{subtree}"
  run "cd #{talk_repo} && git branch -D #{subtree}"
end

def create_git_repo(path, mod)
  unless File.directory?(File.join(module_repo(path, mod), '.git'))
    run "mkdir -p #{path}"
    run "cd #{path} && git init #{mod}"
  end
end

def checkout(repo, branch)
  run "cd #{repo} && git checkout #{branch}"
end

def pull_subtree(talk_repo, path, mod, branch)
  mod_repo = module_repo(path, mod)
  if branch_exists?(mod_repo, branch)
    run "cd #{mod_repo} && git checkout #{branch}"
    run "cd #{mod_repo} && git pull #{talk_repo} #{subtree_branch(mod, branch)}"
  else
    run "cd #{mod_repo} && git fetch #{talk_repo} #{subtree_branch(mod, branch)}"
    run "cd #{mod_repo} && git branch #{branch} FETCH_HEAD"
  end
end

def main
  if ARGV.length == 2
    talk_repo = File.expand_path(ARGV[0])
    output_path = File.expand_path(ARGV[1])
    branches = remote_branches(talk_repo)

    modules.each do |mod|
      create_git_repo(output_path, mod)

      branches.each do |branch|
        generate_subtree(talk_repo, mod, branch)
        pull_subtree(talk_repo, output_path, mod, branch)
        remove_subtree(talk_repo, mod, branch)
      end

      checkout(module_repo(output_path, mod), 'master')
    end
  else
    puts 'USAGE: split.rb HOCCER_TALK_REPO OUTPUT_PATH'
  end
end

main
