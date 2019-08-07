require 'git'


module Git
  def self.clone_without_env(repository, name, opts = {})
    opts = Git::Lib.new.clone_without_env(repository, name, opts)
    Base.new(opts)
  end
end

module Patches
  module Git

    module Base

      def track(remote, branch)
        self.lib.track(remote, branch)
      end

      def pull_opts(remote = 'origin', branch = 'master', opts = {})
        self.lib.pull_opts(remote, branch, opts)
      end

    end
    module Lib
      def initialize(*args)
        super
        # @logger = Logger.new(STDOUT)
      end

      def run_command(git_cmd, &block)
        git_cmd = git_cmd.gsub(/2>&1$/, '')
        return IO.popen(git_cmd, &block) if block_given?

        `#{git_cmd}`.chomp
      end

      def track(remote, branch)
        arr_opts = []
        arr_opts << '-u'
        arr_opts << "#{remote}/#{branch}"
        command('branch', arr_opts)
      end

      def pull_opts(remote='origin', branch='master', opts={})
        arr_opts = []
        arr_opts << remote
        arr_opts << branch
        arr_opts << '--prune' if opts[:p]
        command('pull', arr_opts)
      end

      def clone_without_env(repository, name, opts = {})
        @path = opts[:path] || '.'
        clone_dir = opts[:path] ? File.join(@path, name) : name

        arr_opts = []
        arr_opts << '--bare' if opts[:bare]
        arr_opts << '--branch' << opts[:branch] if opts[:branch]
        arr_opts << '--depth' << opts[:depth].to_i if opts[:depth] && opts[:depth].to_i > 0
        arr_opts << '--config' << opts[:gitl_config] if opts[:gitl_config]
        arr_opts << '--origin' << opts[:remote] || opts[:origin] if opts[:remote] || opts[:origin]
        arr_opts << '--recursive' if opts[:recursive]
        arr_opts << "--mirror" if opts[:mirror]

        arr_opts << '--'

        arr_opts << repository
        arr_opts << clone_dir

        command_without_env('clone', arr_opts)

        (opts[:bare] or opts[:mirror]) ? {:repository => clone_dir} : {:working_directory => clone_dir}
      end

      def command_without_env(cmd, opts = [], chdir = true, redirect = '', &block)
        global_opts = []
        global_opts << "--git-dir=#{@git_dir}" if !@git_dir.nil?
        global_opts << "--work-tree=#{@git_work_dir}" if !@git_work_dir.nil?

        opts = [opts].flatten.map {|s| escape(s) }.join(' ')

        global_opts = global_opts.flatten.map {|s| escape(s) }.join(' ')

        git_cmd = "#{::Git::Base.config.binary_path} #{global_opts} #{cmd} #{opts} #{redirect} 2>&1"

        output = nil

        command_thread = nil;

        exitstatus = nil

        command_thread = Thread.new do
          output = run_command(git_cmd, &block)
          exitstatus = $?.exitstatus
        end
        command_thread.join

        if @logger
          @logger.info(git_cmd)
          @logger.debug(output)
        end

        if exitstatus > 1 || (exitstatus == 1 && output != '')
          raise Git::GitExecuteError.new(git_cmd + ':' + output.to_s)
        end

        return output
      end

    end
  end
end


Git::Lib.prepend(Patches::Git::Lib)
Git::Base.prepend(Patches::Git::Base)
