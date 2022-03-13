require "http/client"
require "json"
require "yaml"

class Push
  def self.exec(filename : String)
    puts "LDSync - pushing to Launch Darkly"

    # load config file
    config = Config.new(filename)

    # load launch darkly service
    service = LDService.new(config)

    # check if project exists
    puts "LDSync - Check if project exists"
    service.get_or_create_project

    # check if environment exists
    puts "LDSync - Check if environment exists"
    service.get_or_create_environment

    # get list of existing flags
    flags = service.get_flags
    keys = [] of String
    flags["items"].as_a.each do |flag|
      keys << flag["key"].as_s
    end

    # create flags that do not exist
    config.flags.each do |key, value|
      unless keys.includes? key
        service.create_flag(key.to_s)
      end
    end

    # update flag status
    config.flags.each do |key, value|
      service.set_flag(key, value)
    end
    puts "LDSync - push completed successfully"
  end
end
