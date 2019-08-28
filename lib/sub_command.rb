require 'command'
require 'rubygems'
require 'config/glb_config'
require 'colored2'
require 'gitlab'
require 'git_ext'
require 'yaml'

module Glb
  class SubCommand < Command

    self.ignore_in_command_lookup = true
    attr_reader :glb_config

    def self.options
      [
          ['--config=[Glb.yml]', 'glb配置, 默认为Glb.yml'],
      ].concat(super)
    end

    def initialize(argv)
      @yml = argv.option('config')
      if @yml.nil?
        @yml = 'Glb.yml'
      end
      super
    end

    def validate!
      super
    end

    def run
      workspace_path = "./"
      find_workspace = false;
      begin
        result = nil
        Dir.chdir(workspace_path) do
          result = Dir.glob('.glb', File::FNM_DOTMATCH)
        end
        if result.length > 0
          find_workspace = true
          break
        else
          workspace_path = File.expand_path("../", workspace_path)
        end
      end while workspace_path.length > 0 && workspace_path != "/"

      if find_workspace
        Dir.chdir(workspace_path) do
          self.run_in_workspace()
        end
      else
        raise Error.new("Current path is not glb workspace. please run 'glb start' first.")
      end
    end

    def run_in_workspace

    end

    def glb_config
      if File.exist?(@yml)
        @glb_config = GlbConfig.load_file(@yml)
      else
        help! 'config is required.'
      end
      @glb_config
    end

    def workspace_config
      if @workspace_config.nil?
        filename = '.glb'
        # workspace_config_path = File.expand_path(filename, File.dirname(self.glb_config.config_path))
        workspace_config_path = filename
        if !File.exist?(workspace_config_path)
          help! "workspace config not found. please run 'glb start' first."
        end
        @workspace_config = WorkSpaceConfig.load_file(workspace_config_path)
      end
      @workspace_config
    end

    def save_workspace_config(workspace_config)
      filename = '.glb'
      # workspace_config_path = File.expand_path(filename, File.dirname(self.glb_config.config_path))
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