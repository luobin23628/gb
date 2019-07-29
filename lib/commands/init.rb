require 'command'
require 'cocoapods-downloader'
require 'yaml'

module Gitl

  class Init < Command

    self.summary = '初始化gitlab配置，下载代码'

    self.description = <<-DESC
      初始化gitlab配置，下载代码.
    DESC

    self.arguments = [
        CLAide::Argument.new('manifest', false, false),
    ]

    def initialize(argv)
      @manifest = argv.shift_argument
      if @manifest.nil?
        @manifest = 'Gitl.yml'
      end
      super
    end

    def validate!
      super
      if @manifest.nil?
        help! 'manifest is required.'
      end
    end

    def run

      configs = YAML.load_file(@manifest)
      projects = configs['projects']
      projects.each do |project|
        target_path = project['name']
        git_url = project['git']
        options = { :git => git_url }
        options = Pod::Downloader.preprocess_options(options)
        downloader = Pod::Downloader.for_target(target_path, options)
        # downloader.cache_root = '~/Library/Caches/APPNAME'
        # downloader.max_cache_size = 500
        downloader.download
        puts downloader.checkout_options
        downloader.checkout_options #=> { :git => 'example.com', :commit => 'd7f410490dabf7a6bde665ba22da102c3acf1bd9' }
      end

    end

  end

end