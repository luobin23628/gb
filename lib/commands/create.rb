require 'sub_command'
require "open-uri"
require 'pathname'

module Gb
  class Create < SubCommand

    self.summary = '创建并配置Gb.yml.'

    self.description = <<-DESC
      创建并配置Gb.yml.
    DESC

    def self.options
      options = [
          ["--config_url=[url]", "指定配置文件url地址"],
          ["--private_token=[token]", "GitLab private token"],
      ].concat(super)
      options.delete_if do |option|
        option[0] =~ /^--config=/
      end
      options
    end

    def initialize(argv)
      @config_url = argv.option('config_url')
      @private_token = argv.option('private_token')
      super
    end

    def validate!
      super
    end

    def run
      local_config_path = "./Gb.yml"
      if File.exist?(local_config_path)
        raise Error.new("'#{local_config_path}' exists.")
      end

      if @config_url.nil?
        path = File.expand_path("../../Gb.yml", File.dirname(__FILE__))
        if File.exist?(path)
          gb_config = GbConfig.load_file(path)
        else
          raise Error.new("'#{path}' not found.")
        end
      else
        yml_response = nil
        open(@config_url) do |http|
          yml_response = http.read
        end
        gb_config = GbConfig.load_yml(yml_response)
      end

      if @private_token.nil?
        begin
          print "Input GitLab private token:  "
          private_token = STDIN.gets.chomp
        end until private_token.length > 0
        @private_token = private_token
      end

      gb_config.gitlab.private_token = @private_token

      File.open("./Gb.yml", 'w') do |file|
        Psych.dump(gb_config.to_dictionary, file)
      end

    end
  end
end