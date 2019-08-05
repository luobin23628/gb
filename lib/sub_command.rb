require 'command'
require 'rubygems'
require 'config/gitl_config'
require 'colored2'
require 'gitlab'
require 'git_ext'
require 'yaml'

module Gitl
  class SubCommand < Command
    require 'commands/init'

    self.ignore_in_command_lookup = true

    attr_reader :config

    def self.options
      [
          %w(--config=[Gitl.yml] gitl配置, 默认为Gitl.yml)
      # ['--config=[Gitl.yml]', 'gitl配置, 默认为Gitl.yml'],
      ].concat(super)
    end

    def initialize(argv)
      yml = argv.option('config')
      if self.class == Gitl::Command
        super
      else
        if yml.nil?
          yml = 'Gitl.yml'
        end
        if File.exist?(yml)
          @config = GitlConfig.load_file(yml)
        else
          help! 'config do not exist.'
        end
        super
      end
    end

    def validate!
      super
      if @config.nil?
        help! 'config is required.'
      end
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