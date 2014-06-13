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

def generate_subtree(repo, mod, branch)
  subtree_branch_name = "export/#{mod}/#{branch}"
  `cd #{repo} && git subtree split --prefix #{mod} --branch #{subtree_branch_name}`
end

def main
  if ARGV.length == 2
    talk_repo = ARGV[0]
    output_path = ARGV[1]
    branches = remote_branches(talk_repo)
    # branches = ["develop"]

    modules.each do |mod|
      branches.each do |branch|
        generate_subtree(talk_repo, mod, branch)
      end

      # create_git_repo
    end
  else
    puts 'USAGE: split.rb HOCCER_TALK_REPO OUTPUT_PATH'
  end
end

main
