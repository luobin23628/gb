require 'command'
require 'rubygems'
require 'config/gitl_config'
require 'colored2'
require 'gitlab'
require 'git_ext'
require 'yaml'

module Gitl
  class SubCommand < Command

    self.ignore_in_command_lookup = true
    attr_reader :gitl_config

    def self.options
      [
          %w(--config=[Gitl.yml] gitl配置, 默认为Gitl.yml)
      # ['--config=[Gitl.yml]', 'gitl配置, 默认为Gitl.yml'],
      ].concat(super)
    end

    def initialize(argv)
      yml = argv.option('config')
      if yml.nil?
        yml = 'Gitl.yml'
      end
      if File.exist?(yml)
        @gitl_config = GitlConfig.load_file(yml)
      else
        help! 'config do not exist.'
      end
      super
    end

    def validate!
      super
      if @gitl_config.nil?
        help! 'config is required.'
      end
    end

    def workspace_config
      if @workspace_config.nil?
        filename = '.gitl'
        # workspace_config_path = File.expand_path(filename, File.dirname(self.gitl_config.config_path))
        workspace_config_path = filename
        if !File.exist?(workspace_config_path)
          help! "workspace config not found. please run 'gitl start' first."
        end
        @workspace_config = WorkSpaceConfig.load_file(workspace_config_path)
      end
      @workspace_config
    end

    def save_workspace_config(workspace_config)
      filename = '.gitl'
      # workspace_config_path = File.expand_path(filename, File.dirname(self.gitl_config.config_path))
      workspace_config_path = filename
      workspace_config.save(workspace_config_path)
      @workspace_config = workspace_config
    end

    def check_uncommit(g, project_name)
      changed = g.status.changed
      added = g.status.added
      deleted = g.status.deleted
      untracked = g.status.untracked

      if !changed.empty?
        alert = true
        puts "modified files:".red
        changed.each do |file, status|
          puts ("        M:        " << file).red
        end
      end

      if !added.empty?
        alert = true
        puts "added files:".red
        added.each do |file, status|
          puts ("        A:        " << file).red
        end
      end

      if !deleted.empty?
        alert = true
        puts "deleted files:".red
        deleted.each do |file, status|
          puts ("        D:        " << file).red
        end
      end

      if !untracked.empty?
        alert = true
        puts "untracked files:".red
        untracked.each do |file, status|
          puts ("        " << file).red
        end
      end

      if alert
        puts "exist uncommit files in current branch '#{g.current_branch}' for '#{project_name}'. ignore it? y/n "
        flag = STDIN.gets.chomp
        unless flag.downcase == "y"
          exit
        end
      end
    end
  end
end