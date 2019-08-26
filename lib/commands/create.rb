require 'sub_command'
require "open-uri"
require 'pathname'

module Gitl
  class Create < SubCommand

    self.summary = '创建并配置Gitl.yml.'

    self.description = <<-DESC
      创建并配置Gitl.yml.
    DESC

    def self.options
      options = [
          ["--config_url=[url]", "指定配置文件url地址"],
      ].concat(super)
      options.delete_if do |option|
        option[0] =~ /^--config=/
      end
      options
    end

    def initialize(argv)
      @config_url = argv.option('config_url')
      super
    end

    def validate!
      super
    end

    def run
      local_config_path = "./Gitl.yml"
      if File.exist?(local_config_path)
        raise Error.new("'#{local_config_path}' exists.")
      end

      if @config_url.nil?
        path = File.expand_path("../../Gitl.yml", File.dirname(__FILE__))
        if File.exist?(path)
          gitl_config = GitlConfig.load_file(path)
        else
          raise Error.new("'#{path}' not found.")
        end
      else
        yml_response = nil
        open(@config_url) do |http|
          yml_response = http.read
        end
        gitl_config = GitlConfig.load_yml(yml_response)
      end

      begin
        print "Input GitLab private token:  "
        private_token = STDIN.gets.chomp
      end until private_token.length > 0

      gitl_config.gitlab.private_token = private_token

      File.open("./Gitl.yml", 'w') do |file|
        Psych.dump(gitl_config.to_dictionary, file)
      end

    end
  end
end