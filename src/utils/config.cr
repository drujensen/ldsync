require "yaml"

class Config
  include YAML::Serializable

  @[YAML::Field(ignore: true)]
  property filename : String
  @[YAML::Field(ignore: true)]
  property token : String
  property project : String
  property environment : String
  property flags : Hash(String, Bool)

  def initialize(@filename, @project, @environment)
    @token = ""
    @flags = Hash(String, Bool).new
  end

  def initialize(filename : String)
    @filename = filename
    @flags = Hash(String, Bool).new

    # read config file
    begin
      yaml = File.open(filename) do |file|
        YAML.parse(file)
      end
    rescue
      puts "LDSync - Could not open #{filename}. exiting."
      exit 1
    end

    unless @token = ENV["LDSYNC_TOKEN"]? || yaml["token"]?.to_s
      puts "LDSync - Access token required. exiting."
      exit 1
    end

    unless @project = ENV["LDSYNC_PROJECT"]? || yaml["project"]?.to_s
      puts "LDSync - Project required. exiting."
      exit 1
    end

    unless @environment = ENV["LDSYNC_ENVIRONMENT"]? || yaml["environment"]?.to_s
      puts "LDSync - Environment required. exiting."
      exit 1
    end

    if yaml_flags = yaml["flags"]?
      yaml_flags.as_h.each { |name, value| @flags[name.to_s] = value.as_bool }
    end
  end

  def dump
    # write new yaml file
    begin
      FileUtils.mkdir_p "config" if @filename.includes? "config/"
      File.write(@filename, self.to_yaml)
    rescue
      puts "LDSync - Could not create #{@filename}. exiting"
      exit 1
    end
  end
end
