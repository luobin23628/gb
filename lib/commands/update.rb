require 'command'
require 'yaml'
require 'config/yml_config'
require 'colored2'

module Gitl

  class Update < Command

    self.summary = '根据yml配置，更新代码'

    self.description = <<-DESC
      根据yml配置，更新代码.
    DESC

    def run
      self.config.projects.each do |project|
        project_path = File.expand_path(project.name, './')
        if File.exist?(project_path)
          puts project.name + ' exists, skip.'
          g = Git.open(project_path)
          g.fetch()
          g.pull()

        else
          g = Git.clone(project.git, project.name, :path => './', :depth => 1)
        end

      end
    end

  end
end