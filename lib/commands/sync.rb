require 'sub_command'


module Gb

  class Sync < SubCommand

    self.summary = '更新工作分支代码'

    self.description = <<-DESC
      根据yml配置，更新代码.
    DESC

    def run_in_config

      remote = 'origin'
      workspace_config = self.workspace_config

      info "current work branch '#{workspace_config.work_branch}', remote branch '#{workspace_config.remote_branch}'."

      self.gb_config.projects.each do |project|
        project_path = File.expand_path(project.name, './')

        if File.exist?(project_path)
          info "sync project '#{project.name}'..."
          g = Git.open(project_path)
          # if workspace_config.workspace_branch != g.current_branch
          #   error "current branch is not work branch(#{workspace_config.workspace_branch})."
          #   exit(1)
          # end
          g.checkout(workspace_config.work_branch)
          g.fetch(remote, :p => true, :t => true)
          g.pull("origin", workspace_config.work_branch)
          g.pull("origin", workspace_config.remote_branch)
          puts

        else
          error "please run 'gb init first."
          break
        end

      end
    end

  end
end