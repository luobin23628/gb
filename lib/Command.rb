
require 'claide'
require 'rubygems'
require 'colored2'
require 'gitlab'
require 'git_ext'

module Gitl
  class Error < StandardError; end

  class Command < CLAide::Command

    require 'commands/init'
    require 'commands/update'
    require 'commands/start'
    require 'commands/review'
    require 'commands/tag'

    self.abstract_command = true
    self.command = 'gitl'
    self.version = VERSION
    self.description = 'Gitl, the tianxiao gitlab manager.'

    attr_reader :config

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
      @config = GitlConfig.load_file(yml)
      super
    end

    def validate!
      super
      if @config.nil?
        help! 'config is required.'
      end
    end

    def self.run(argv)
      help! 'You cannot run gitl as root.' if Process.uid == 0 && !Gem.win_platform?

      super(argv)
    end

    def self.report_error(exception)
      case exception
      when Interrupt
        puts '[!] Cancelled'.red
        exit(1)
      when SystemExit
        raise
      else
        raise exception
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