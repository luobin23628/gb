require 'command'
require 'rubygems'
require 'config/gb_config'
require 'colored2'
require 'gitlab'
require 'ext/git_ext'
require 'yaml'

module Gb
  class SubCommand < Command

    self.ignore_in_command_lookup = true
    attr_reader :gb_config

    def initialize(argv)
      # @yml = argv.option('config')
      if @yml.nil?
        @yml = 'Gb.yml'
      end
      super
    end

    def validate!
      super
    end

    def run
      config_dir = "./"
      find_config = false;
      begin
        result = nil
        Dir.chdir(config_dir) do
          result = Dir.glob('Gb.yml', File::FNM_DOTMATCH)
        end
        if result.length > 0
          find_config = true
          break
        else
          config_dir = File.expand_path("../", config_dir)
        end
      end while config_dir.length > 0 && config_dir != "/"

      if find_config
        Dir.chdir(config_dir) do
          self.run_in_config()
        end
      else
        raise Error.new("Current path is not gb workspace. please run 'gb start' first.")
      end
    end

    def run_in_config

    end

    def gb_config
      if File.exist?(@yml)
        @gb_config = GbConfig.load_file(@yml)
      else
        help! "gb config not found. please run 'gb create' first."
      end
      @gb_config
    end

    def workspace_config
      if @workspace_config.nil?
        filename = '.gb'
        # workspace_config_path = File.expand_path(filename, File.dirname(self.gb_config.config_path))
        workspace_config_path = filename
        if !File.exist?(workspace_config_path)
          help! "workspace config not found. please run 'gb start' first."
        end
        @workspace_config = WorkSpaceConfig.load_file(workspace_config_path)
      end
      @workspace_config
    end

    def save_workspace_config(workspace_config)
      filename = '.gb'
      # workspace_config_path = File.expand_path(filename, File.dirname(self.gb_config.config_path))
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