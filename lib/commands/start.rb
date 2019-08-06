require 'sub_command'

module Gitl
  class Start < SubCommand

    self.summary = '创建对应工作分支，并同步到gitlab.'

    self.description = <<-DESC
      创建对应工作分支，并同步到gitlab.
    DESC

    self.arguments = [
        CLAide::Argument.new('working_branch', true, false),
        CLAide::Argument.new('remote_branch', true, false),
    ]

    def self.options
      [
          ["--force", "忽略工作分支是否存在，强制执行"],
      ].concat(super)
    end

    def initialize(argv)
      @working_branch = argv.shift_argument
      @remote_branch = argv.shift_argument
      @force = argv.flag?('force')
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
      remote = 'origin'
      workspace_config = WorkSpaceConfig.new(@remote_branch, @working_branch)

      self.gitl_config.projects.each do |project|
        project_path = File.expand_path(project.name, './')
        if File.exist?(project_path)
          g = Git.open(project_path)
        else
          g = Git.clone(project.git, project.name, :path => './')
        end

        if self.verbose?
          # g.setLogger(Logger.new(STDOUT))
        end

        check_uncommit(g, project.name)

        # 更新本地代码
        # g.pull(remote, g.current_branch)

        if !g.is_remote_branch?(@remote_branch)
          raise Error.new("remote branch '#{@remote_branch}' does not exist for project '#{project.name}'.")
        end

        if g.is_remote_branch?(@working_branch) && !@force
          raise Error.new("branch '#{@working_branch}' exist in remote '#{remote}' for project '#{project.name}'.")
        end

        if g.is_local_branch?(@working_branch) && !@force
          raise Error.new("branch '#{@working_branch}' exist in local for project '#{project.name}'.")
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

        if g.is_local_branch?(@working_branch)
          g.checkout(@working_branch)
          g.pull(remote, @working_branch)
        else
          puts "create branch '#{@working_branch}' for project '#{project.name}'.".green
          # 创建本地工作分支
          g.checkout(@working_branch, :new_branch => true)
        end

        # 跟踪远程分支
        g.track(remote, @remote_branch)

        puts "push branch '#{@working_branch}' to remote for project '#{project.name}'.".green
        # push到origin
        g.push(remote, @working_branch)
      end

      #保存新的workspace配置
      self.save_workspace_config(workspace_config)

      puts "create work branch '#{@working_branch}' from #{@remote_branch} and push to '#{remote}' success.".green
    end
  end
end