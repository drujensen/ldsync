require "yaml"

class Config
  include YAML::Serializable

  @[YAML::Field(ignore: true)]
  property filename : String
  @[YAML::Field(ignore: true)]
  property token : String
  property project : String
  property environment : String
  property flags : Array(Flag)

  def initialize(@filename, @project, @environment)
    @token = ""
    @flags = Array(Flag).new
  end

  def initialize(filename : String)
    @filename = filename
    @flags = Array(Flag).new

    # read config file
    begin
      yaml = File.open(filename) do |file|
        YAML.parse(file)
      end
    rescue
      puts "LDSync - Could not open #{filename}. exiting."
      exit 1
    end

    unless @token = ENV["LD_TOKEN"]?.to_s
      puts "LDSync - Access token required. exiting."
      exit 1
    end

    unless @project = ENV["LD_PROJECT"]? || yaml["project"]?.to_s
      puts "LDSync - Project required. exiting."
      exit 1
    end

    unless @environment = ENV["LD_ENVIRONMENT"]? || yaml["environment"]?.to_s
      puts "LDSync - Environment required. exiting."
      exit 1
    end

    if yaml_flags = yaml["flags"]?
      yaml_flags.as_a.each do |flag|
        add_flag(flag["key"].to_s, flag["name"].to_s, flag["enabled"].as_bool)
      end
    end
  end

  def clear_flags
    @flags = Array(Flag).new
  end

  def add_flag(key : String, name : String, enabled : Bool)
    @flags << Flag.new(key, name, enabled)
  end

  def save
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
