require 'claide'
require 'config/work_space_config'
require 'gb'

module Gb
  class Error < StandardError; end

  class Command < CLAide::Command

    require 'commands/init'
    require 'commands/sync'
    require 'commands/start'
    require 'commands/review'
    require 'commands/create_tag'
    require 'commands/delete_tag'
    require 'commands/create'

    self.abstract_command = true
    self.command = 'gb'
    self.version = VERSION
    self.description = 'gb, the gitlab helper.'

    def self.run(argv)
      help! 'You cannot run gb as root.' if Process.uid == 0 && !Gem.win_platform?
      super(argv)
    end

    def self.handle_exception(command, exception)
      if exception.is_a?(Error) || exception.is_a?(Git::GitExecuteError)
        puts exception.message.red
        if command.nil? || command.verbose?
          puts
          puts(*exception.backtrace)
        end
        exit(1)
      elsif exception.is_a?(Gitlab::Error::ResponseError)
        if command.nil? || command.verbose?
          puts(exception.message.red)
          puts(*exception.backtrace)
        else
          puts exception.message.red
        end
        exit(1)
      else
        super
      end
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

    def info(message)
      puts(message.green)
    end

    def error(message)
      puts(message.red)
    end

  end

end