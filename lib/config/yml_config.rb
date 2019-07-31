module Gitl
  class YmlConfig

    attr_reader :projects
    attr_reader :gitlab

    def initialize(node)
      @gitlab = GitlabConfig.new(node)

      @projects = []
      projects = node['projects']
      projects.each do |project|
        projectConfig = ProjectConfig.new(project)
        @projects << projectConfig
      end
    end

    def self.load_file(yaml_filename)
      node = YAML.load_file(yaml_filename)
      return YmlConfig.new(node)
    end

    class ProjectConfig
      attr_reader :name
      attr_reader :git
      attr_reader :branch

      def initialize(node)
        @name = node['name']
        @git = node['git']
        @branch = node['branch']
      end

    end

    class GitlabConfig
      attr_reader :endpoint
      attr_reader :private_token

      def initialize(node)
        @endpoint = node['endpoint']
        @private_token = node['private_token']
      end

    end

  end
end

