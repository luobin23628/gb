module Glb
  class GlbConfig

    attr_reader :projects
    attr_reader :gitlab
    attr_reader :config_path

    def initialize(config_path, node)
      @config_path = config_path

      gitlab = node['gitlab']
      @gitlab = GitlabConfig.new(gitlab)

      @projects = []
      projects = node['projects']
      projects.each do |project|
        projectConfig = ProjectConfig.new(project)
        @projects << projectConfig
      end
    end

    def self.load_file(config_path)
      node = YAML.load_file(config_path)
      GlbConfig.new(config_path, node)
    end

    def self.load_yml(yml)
      node = YAML.load(yml)
      GlbConfig.new(nil, node)
    end

    def to_dictionary
      projects = self.projects.map do |project|
        project.to_dictionary
      end
      {"projects"=>projects, "gitlab"=>self.gitlab.to_dictionary}
    end

    class ProjectConfig
      attr_reader :name
      attr_reader :git

      def initialize(node)
        @name = node['name']
        @git = node['git']
      end

      def to_dictionary
        {"name"=>self.name, "git"=>self.git}
      end

    end

    class GitlabConfig
      attr_reader :endpoint
      attr_accessor :private_token

      def initialize(node)
        @endpoint = node['endpoint']
        @private_token = node['private_token']
      end

      def to_dictionary
        {"endpoint"=>self.endpoint, "private_token"=>private_token}
      end

    end

  end
end

