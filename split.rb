#!/usr/bin/env ruby

require 'English'

def modules
  [
    {:folder => 'android', :remote => 'git@github.com:hoccer/hoccer-xo-android.git'},
    {:folder => 'cli-api', :remote => 'git@github.com:hoccer/better-cli.git'},
    {:folder => 'cli-log4j', :remote => 'git@github.com:hoccer/better-cli-log4j.git'},
    {:folder => 'client', :remote => 'git@github.com:hoccer/talk-client.git'},
    {:folder => 'common', :remote => 'git@github.com:hoccer/talk-common.git'},
    {:folder => 'filecache', :remote => 'git@github.com:hoccer/talk-filecache.git'},
    {:folder => 'integration-tests', :remote => 'git@github.com:hoccer/talk-integration-tests.git'},
    {:folder => 'jsonrpc-annotations', :remote => 'git@github.com:hoccer/better-jsonrpc-annotations.git'},
    {:folder => 'jsonrpc-common', :remote => 'git@github.com:hoccer/better-jsonrpc-common.git'},
    {:folder => 'jsonrpc-websocket', :remote => 'git@github.com:hoccer/better-jsonrpc-websocket.git'},
    {:folder => 'server', :remote => 'git@github.com:hoccer/talk-server.git'},
    {:folder => 'srp', :remote => 'git@github.com:hoccer/talk-srp.git'},
    {:folder => 'tool', :remote => 'git@github.com:hoccer/talk-tool.git'}
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

def remote_tags(repo)
  output = run "cd #{repo} && git tag --list"
  tags = output.lines
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

def add_remote(repo, name, url)
  run "cd #{repo} && git remote add #{name} #{url}"
end

def add_submodule(repo, remote, mod)
  run "cd #{repo} && git submodule add #{remote} #{mod}"
end

def commit_all(repo, message)
  run "cd #{repo} && git add --all"
  run "cd #{repo} && git commit --message=\"#{message}\""
end

def create_branch(repo, branch, source)
  run "cd #{repo} && git branch #{branch} #{source}"
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
    tags = remote_tags(talk_repo)

    create_git_repo(output_path, '.')

    modules.each do |mod|
      create_git_repo(output_path, mod[:folder])

      branches.each do |branch|
        generate_subtree(talk_repo, mod[:folder], branch)
        pull_subtree(talk_repo, output_path, mod[:folder], branch)
        remove_subtree(talk_repo, mod[:folder], branch)
      end

      checkout(module_repo(output_path, mod[:folder]), 'master')
      add_remote(module_repo(output_path, mod[:folder]), 'origin', mod[:remote])

      add_submodule(output_path, mod[:remote], mod[:folder])
    end

    commit_all(output_path, 'Initial commit')

    branches.each do |branch|
      next if branch == 'master'

      modules.each do |mod|
        checkout(module_repo(output_path, mod[:folder]), branch)
      end

      create_branch(output_path, branch, 'master')
      checkout(output_path, branch)
      commit_all(output_path, "Initial commit for branch #{branch}")
    end
  else
    puts 'USAGE: split.rb HOCCER_TALK_REPO OUTPUT_PATH'
  end
end

main
