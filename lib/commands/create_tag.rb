require 'sub_command'


module Gb

  class CreateTag < SubCommand

    self.summary = '新建tag'

    self.description = <<-DESC
      指定分支上新建tag.
    DESC

    self.arguments = [
        CLAide::Argument.new('branch', true, false),
        CLAide::Argument.new('tag_name', true, false),
    ]

    def self.options
      [
          ["--force", "忽略tag是否存在，强制执行"],
      ].concat(super)
    end

    def initialize(argv)
      @branch = argv.shift_argument
      @tag_name = argv.shift_argument
      @force = argv.flag?('force')
      super
    end

    def validate!
      super
      if @branch.nil?
        help! 'branch is required.'
      end
      if @tag_name.nil?
        help! 'tag_name is required.'
      end
    end

    def run
      # api: https://www.rubydoc.info/gems/gitlab/toplevel
      # document: https://narkoz.github.io/gitlab/cli

      Gitlab.configure do |config|
        # set an API endpoint
        # API endpoint URL, default: ENV['GITLAB_API_ENDPOINT']
        config.endpoint = self.gb_config.gitlab.endpoint

        # set a user private token
        # user's private token or OAuth2 access token, default: ENV['GITLAB_API_PRIVATE_TOKEN']
        config.private_token = self.gb_config.gitlab.private_token

        # user agent
        config.user_agent = "gb ruby gem[#{VERSION}"
      end

      self.gb_config.projects.each do |project|
        gitlab_project = gitlab_search_project(project.name)
        info "find project #{gitlab_project.name} on #{gitlab_project.web_url}."
        begin
          tag = Gitlab.tag(gitlab_project.id, @tag_name)
        rescue Gitlab::Error::NotFound => error
          tag = nil
        rescue Gitlab::Error::Error => error
          raise(error)
        end

        if tag.nil?
          Gitlab.create_tag(gitlab_project.id, @tag_name, @branch)
          info "create tag '#{@tag_name}' success"
        else
          if @force
            info "tag '#{@tag_name}' exist, skip."
          else
            help! "tag '#{@tag_name}' exist."
          end
        end

        puts
      end
    end

    def gitlab_search_project(project_name)
      projects = Gitlab.project_search(project_name)
      if projects.size > 1
        info "find #{projects.size} project named #{project_name}. you means which one?"
        projects.each do |project|
          print project.name + '  '
        end
        print "\n"
        raise Error.new("find #{projects.size} project named #{project_name}")

      elsif projects.size == 1
        project = projects[0];
      else
        raise Error.new("can't find project named '#{project_name}'.")
      end
      project
    end

  end
end