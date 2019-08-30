require 'sub_command'


module Gb

  class Forall < SubCommand

    self.summary = '遍历所有工程执行命令'
    self.description = <<-DESC
      遍历所有工程执行命令.
      gb forall -c="git reset --hard"
    DESC

    def self.options
      [
          ["-c", "执行命令"],
      ].concat(super)
    end

    def initialize(argv)
      @command = argv.option('c')
      super
    end

    def validate!
      super
      if @command.nil?
        help! 'command is required.'
      end
    end

    def run_in_workspace

      self.gb_config.projects.each do |project|
        project_path = File.expand_path(project.name, './')

        if File.exist?(project_path)
          info "For project '#{project.name}'..."
          g = Git.open(project_path)
          Dir.chdir(project_path) do
            result = `#{@command}`
            puts result
          end
          puts
        else
          error "please run 'gb init first."
          break
        end
      end
    end

  end
end