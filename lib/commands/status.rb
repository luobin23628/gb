require 'sub_command'


module Gb

  class Status < SubCommand

    self.summary = '查看工作分支代码状态'

    self.description = <<-DESC
      查看工作分支代码状态.
    DESC

    def run_in_workspace

      self.gb_config.projects.each do |project|
        project_path = File.expand_path(project.name, './')

        if File.exist?(project_path)
          info "for project '#{project.name}'..."
          g = Git.open(project_path)

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

          else
            info "git工作区无代码要提交"
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