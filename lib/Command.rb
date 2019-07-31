
require 'claide'
require 'rubygems'
require 'colored2'
require 'git'


module Patches
  module Git
    module Lib
      def initialize(*args)
        super
        @logger = Logger.new(STDOUT)
      end

      def run_command(git_cmd, &block)
        git_cmd = git_cmd.gsub(/2>&1$/, '')
        return IO.popen(git_cmd, &block) if block_given?

        `#{git_cmd}`.chomp
      end
    end
  end
end


Git::Lib.prepend(Patches::Git::Lib)


module Gitl

  class Command < CLAide::Command

    require 'commands/init'

    self.abstract_command = true
    self.command = 'gitl'
    self.version = VERSION
    self.description = 'Gitl, the tianxiao gitlab manager.'

    def self.run(argv)
      help! 'You cannot run gitl as root.' if Process.uid == 0 && !Gem.win_platform?

      super(argv)
    end

    def self.report_error(exception)
      case exception
      when Interrupt
        puts '[!] Cancelled'.red
        exit(1)
      when SystemExit
        raise
      else
        raise exception
      end
    end

  end

end