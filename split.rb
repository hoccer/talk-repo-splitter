#!/usr/bin/env ruby

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
  output = `cd #{repo} && git branch --remotes`
  lines = output.lines

  branches = lines.select do |line|
    !line.include?('origin/HEAD')
  end

  branches.map do |branch|
    branch.strip.gsub('origin/', '')
  end
end

def subtree_branch(mod, branch)
  "export/#{mod}/#{branch}"
end

def module_repo(path, mod)
  File.join(path, mod)
end

def generate_subtree(talk_repo, mod, branch)
  `cd #{talk_repo} && git checkout #{branch}`
  `cd #{talk_repo} && git subtree split --prefix #{mod} --branch #{subtree_branch(mod, branch)}`
end

def remove_subtree(talk_repo, mod, branch)
  `cd #{talk_repo} && git branch -D #{subtree_branch(mod, branch)}`
end

def create_git_repo(path, mod)
  unless File.directory?(File.join(module_repo(path, mod), '.git'))
    `mkdir -p #{path}`
    `cd #{path} && git init #{mod}`
  end
end

def pull_subtree(talk_repo, path, mod, branch)
  mod_repo = module_repo(path, mod)
  `cd #{mod_repo} && git branch #{branch}`
  `cd #{mod_repo} && git checkout #{branch}`
  `cd #{mod_repo} && git pull #{talk_repo} #{subtree_branch(mod, branch)}`
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
    end
  else
    puts 'USAGE: split.rb HOCCER_TALK_REPO OUTPUT_PATH'
  end
end

main
