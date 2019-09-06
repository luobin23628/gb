require 'sub_command'


module Gb

  class Workspace < SubCommand

    self.summary = '查看当前工作区信息'

    self.description = <<-DESC
      查看当前工作区信息.
    DESC

    def run_in_workspace

      remote = 'origin'
      workspace_config = self.workspace_config

      info "current work branch '#{workspace_config.work_branch}'"
      info "track remote branch '#{workspace_config.remote_branch}'."
      puts

      self.gb_config.projects.each do |project|
        project_path = File.expand_path(project.name, './')

        if File.exist?(project_path)
          info "Project '#{project.name}'..."
          g = Git.open(project_path)
          info "current branch '#{g.current_branch}'."
          puts
        else
          error "please run 'gb init first."
          break
        end
      end
    end

  end
end