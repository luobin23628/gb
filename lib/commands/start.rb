require 'command'

module Gitl
  class Start < Command

    self.summary = '创建对应工作分支，并同步到gitlab.'

    self.description = <<-DESC
      创建对应工作分支，并同步到gitlab.
    DESC

    self.arguments = [
        CLAide::Argument.new('working_branch', true, false),
        CLAide::Argument.new('remote_branch', true, false),
    ]

    def initialize(argv)
      @working_branch = argv.shift_argument
      @remote_branch = argv.shift_argument
      super
    end

    def validate!
      super
      if @working_branch.nil?
        help! 'working_branch is required.'
      end
      if @remote_branch.nil?
        help! 'remote_branch is required.'
      end
    end

    def run
      # api: https://www.rubydoc.info/gems/gitlab/toplevel
      # document: https://narkoz.github.io/gitlab/cli

      Gitlab.configure do |config|
        # set an API endpoint
        # API endpoint URL, default: ENV['GITLAB_API_ENDPOINT']
        config.endpoint = self.config.gitlab.endpoint

        # set a user private token
        # user's private token or OAuth2 access token, default: ENV['GITLAB_API_PRIVATE_TOKEN']
        config.private_token = self.config.gitlab.private_token

        # user agent
        config.user_agent = "gitl ruby gem[#{VERSION}"
      end

      self.config.projects.each do |project|
        project_path = File.expand_path(project.name, './')
        if File.exist?(project_path)
          remote = 'origin'
          puts "create branch '#{@working_branch}' for project '#{project.name}'"
          g = Git.open(project_path)
        else
          g = Git.clone(project.git, project.name, :path => './')

        end

        check_uncommit(g, project.name)

        # 更新本地代码
        g.fetch(remote, :p => true, :t => true)

        if !g.is_remote_branch?(@remote_branch)
          raise Error.new("remote branch '#{@remote_branch}' does not exist.")
        end

        if g.is_remote_branch?(@working_branch)
          raise Error.new("branch '#{@working_branch}' exist in remote '#{remote}'.")
        end

        if g.is_local_branch?(@working_branch)
          raise Error.new("branch '#{@working_branch}' exist in local.")
        end

        # g.remote(remote).branch(@remote_branch).checkout()
        # g.branch(@remote_branch).checkout

        # git_cmd = "git remote set-branches #{remote} '#{@remote_branch}'"
        # puts `#{git_cmd}`.chomp
        #
        # git_cmd = "git fetch --depth 1 #{remote} '#{@remote_branch}'"
        # puts `#{git_cmd}`.chomp
        #
        # $ git remote set-branches origin 'remote_branch_name'
        # $ git fetch --depth 1 origin remote_branch_name
        # $ git checkout remote_branch_name

        g.checkout(@remote_branch)

        g.pull(remote, @remote_branch)
        # 创建本地工作分支
        g.checkout(@working_branch, :new_branch => true)

        # 跟踪远程分支
        g.track(remote, @remote_branch)

        # push到origin
        g.push(remote, @working_branch)

        puts "Create branch '#{@working_branch}' from #{@remote_branch} and push to #{remote} success."

      end
    end
  end
end