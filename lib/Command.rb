require 'claide'
require 'config/work_space_config'

module Gitl
  class Error < StandardError; end

  class Command < CLAide::Command

    require 'commands/init'
    require 'commands/sync'
    require 'commands/start'
    require 'commands/review'
    require 'commands/create_tag'
    require 'commands/delete_tag'

    self.abstract_command = true
    self.command = 'gitl'
    self.version = VERSION
    self.description = 'Gitl, the tianxiao gitlab manager.'

    def self.run(argv)
      help! 'You cannot run gitl as root.' if Process.uid == 0 && !Gem.win_platform?
      super(argv)
    end

    def self.handle_exception(command, exception)
      if exception.is_a?(Error)
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
          puts exception.response_message.red
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