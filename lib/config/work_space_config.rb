
module Gb
  class WorkSpaceConfig
    attr_reader :remote_branch
    attr_reader :work_branch

    def initialize(remote_branch, work_branch)
      @remote_branch = remote_branch
      @work_branch = work_branch
    end

    def self.load_file(yaml_filename)
      node = YAML.load_file(yaml_filename)
      remote_branch = node['remote_branch']
      work_branch = node['work_branch']
      return WorkSpaceConfig.new(remote_branch, work_branch)
    end

    def save(path)
      File.open(path, 'w') do |file|
        Psych.dump({'remote_branch' => @remote_branch, 'work_branch' => @work_branch}, file)
      end
    end
  end
end
