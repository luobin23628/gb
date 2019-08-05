require 'command'
require 'yaml'
require 'config/gitl_config'
require 'colored2'

module Gitl

  class Init < Command

    self.summary = '根据yml配置，更新代码'

    self.description = <<-DESC
      根据yml配置，更新代码.
    DESC

    def run
      threads = []
      self.config.projects.each do |project|
        t = Thread.new do
          puts project.name
          project_path = File.expand_path(project.name, './')
          if File.exist?(project_path)
            puts project.name + ' exists, skip.'
          else
            Git.clone_without_env(project.git, project.name, :path => './')
          end
        end
        threads << t
      end
      threads.each do |t| 
        t.join
      end
    end
  end

end
