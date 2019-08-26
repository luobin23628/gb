require 'sub_command'
require 'gitlab_ext'

module Gitl
  class Review < SubCommand

    self.summary = '创建对应工作分支，并同步到gitlab.'

    self.description = <<-DESC
      创建对应工作分支，并同步到gitlab.
    DESC

    # self.arguments = [
    #     CLAide::Argument.new('working_branch', false, false),
    #     CLAide::Argument.new('remote_branch', false, false),
    # ]

    def self.options
      [
          ["--assignee=[user name]", "指定review用户名称"],
          ["--title", "merge request标题"],
          ["--show-diff", "review前是否显示变更"],
      ].concat(super)
    end

    def initialize(argv)
      # @working_branch = argv.shift_argument
      # @remote_branch = argv.shift_argument
      @assignee = argv.option('assignee')
      @title = argv.option('title')
      @show_diff = argv.flag?('show-diff')
      super
    end

    def validate!
      super
      # if @working_branch.nil?
      #   help! 'working_branch is required.'
      # end
      # if @remote_branch.nil?
      #   help! 'remote_branch is required.'
      # end
      # if @assignee.nil?
      #   help! 'assignee is required.'
      # end
    end

    def run

      @working_branch = self.workspace_config.workspace_branch
      @remote_branch = self.workspace_config.remote_branch

      # api: https://www.rubydoc.info/gems/gitlab/toplevel
      # document: https://narkoz.github.io/gitlab/cli

      Gitlab.configure do |config|
        # set an API endpoint
        # API endpoint URL, default: ENV['GITLAB_API_ENDPOINT']
        config.endpoint = self.gitl_config.gitlab.endpoint

        # set a user private token
        # user's private token or OAuth2 access token, default: ENV['GITLAB_API_PRIVATE_TOKEN']
        config.private_token = self.gitl_config.gitlab.private_token

        # user agent
        config.user_agent = "gitl ruby gem[#{VERSION}"
      end

      if !@assignee.nil?
        user = gitlab_search_user(@assignee)
      end

      self.gitl_config.projects.each_with_index do |project, index|
        project_path = File.expand_path(project.name, './')
        if File.exist?(project_path)
          remote = 'origin'
          info "Create branch '#{@working_branch}' for project '#{project.name}'"
          g = Git.open(project_path)
        else
          g = Git.clone(project.git, project.name, :path => './')
        end

        gitlab_project = gitlab_search_project(project.name)
        info "Find project #{gitlab_project.name} on #{gitlab_project.web_url}."

        unless g.is_remote_branch?(@working_branch)
          raise Error.new("Branch '#{@working_branch}' not exist in remote '#{remote}'.")
        end

        unless g.is_remote_branch?(@remote_branch)
          raise Error.new("Branch '#{@remote_branch}' not exist in remote '#{remote}'.")
        end

        g.checkout(@working_branch)
        # 更新本地代码
        g.fetch(remote, :p => true, :t => true)
        g.pull("origin", @working_branch)
        g.pull("origin", @remote_branch)
        # push到origin
        g.push(remote, @working_branch)

        compare_response = Gitlab.compare(gitlab_project.id, @remote_branch, @working_branch);
        if compare_response.commits.size >= 1
          if @show_diff
            puts "\ncommits"
            compare_response.commits.each_with_index do |commit, index|
              unless index == 0
                puts ""
              end
              puts "  #{index} id:" + commit["id"]
              puts "  author:" + commit["author_name"]
              puts "  create at: " + commit["created_at"]
              puts "  title: " + commit["title"]
            end
            puts ""
          end
        else
          info "Can't find new commit on #{@working_branch} to #{@remote_branch} in project #{project.name}."
          puts
          next
        end

        if compare_response.diffs.size >= 1
          if @show_diff
            puts "Diffs"
            compare_response.diffs.each do |diff|
              if diff["new_file"]
                puts "  created " + diff["new_path"]
              elsif diff["renamed_file"]
                puts "  renamed " + diff["old_path"] + "=>" + diff["new_path"]
              elsif diff["deleted_file"]
                puts "  deleted" + diff["old_path"]
              else
                puts "  edited " + diff["new_path"]
              end

              diff = diff["diff"];
              lines = diff.split("\n")
              lines.each do |line|
                puts "  " + line
              end

            end
          end
        else
          info "Can't find diff between #{@working_branch} and #{@remote_branch} in project #{project.name}."
          puts
          next
        end

        if user.nil?
          users = gitlab_get_team_members(gitlab_project.id)
          begin
            info "\nSelect user name or index for review."
            input_user = STDIN.gets.chomp
            if input_user =~ /[[:digit:]]/
              user = users[input_user.to_i]
            else
              user = gitlab_search_user(input_user)
            end
            if user.nil?
              error "Can not found user '#{input_user}'."
            else
              info "Assign to #{user.username}(#{user.name})"
            end
          end until !user.nil?
        end

        if @title.nil? || @title.empty?
          begin
            info "\nInput merge request title for project '#{project.name}'"
            @title = STDIN.gets.chomp
          end until @title.length > 0
        end

        # 总共 0 （差异 0），复用 0 （差异 0）
        # remote:
        #     remote: To create a merge request for dev-v3.9.0-luobin, visit:
        #     remote:   http://git.tianxiao100.com/tianxiao-ios/tianxiao/tianxiao-base-iphone-sdk/merge_requests/new?merge_request%5Bsource_branch%5D=dev-v3.9.0-luobin
        # remote:
        #     To http://git.tianxiao100.com/tianxiao-ios/tianxiao/tianxiao-base-iphone-sdk.git
        # * [new branch]        dev-v3.9.0-luobin -> dev-v3.9.0-luobin

        begin
          merge_request = Gitlab.create_merge_request(gitlab_project.id, @title,
                                      { source_branch: @working_branch, target_branch: @remote_branch, assignee_id:user ? user.id : "" })
          info "Create merge request for #{project.name} success. see detail url:#{merge_request.web_url}"
          if !Gem.win_platform?
            `open -a "/Applications/Google Chrome.app"    '#{merge_request.web_url}/diffs'`
            exitstatus = $?.exitstatus
            if exitstatus != 0
              raise Error.new("open chrome failed.")
            else
              if index != self.gitl_config.projects.length - 1
                info "Please review diff, then input any to continue."
                STDIN.gets.chomp
              end
            end
          end
        rescue Gitlab::Error::Conflict => error
          # merge exists
          info "Merge request from '#{@working_branch}' to '#{@remote_branch}' exist."
        rescue Gitlab::Error::Error => error
          raise(error)
        end
        puts

      end
    end

    def gitlab_search_user(assignee)
      users = Gitlab.user_search(assignee)
      if users.size > 1
        info "Find more than one user. you means which one?"
        users.each do |user|
          print user.name + '  '
        end
        info ""
        raise Error.new("Find #{users.size} user named #{project.name}")
      elsif users.size == 1
        user = users[0]
      else
        raise Error.new("Can't find user #{assignee}.")
      end
      user
    end

    def gitlab_search_project(project_name)
      projects = Gitlab.project_search(project_name)
      if projects.size > 1
        info "Find #{projects.size} project named #{project_name}. you means which one?"
        projects.each do |project|
          print project.name + '  '
        end
        print "\n"
        raise Error.new("Find #{projects.size} project named #{project_name}")

      elsif projects.size == 1
        project = projects[0];
      else
        raise Error.new("Can't find project named '#{project_name}'.")
      end
      project
    end

    def gitlab_get_team_members(project_id)
      users = Gitlab.project_usesrs(project_id).delete_if { |user|
        user.username == 'root'
      }
      if users.size > 0
        info "Find more than one user."
        users.each_with_index do |user, index|
          puts "#{index + 1}、#{user.username}（#{user.name})".green
        end
      else
        raise Error.new("Can't find members in project '#{project_id}''.")
      end
      users
    end
  end
end