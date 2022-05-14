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

    # create flags that do not exist
    config.flags.each do |flag|
      unless flags.has_key? flag.key
        service.create_flag(flag.key, flag.name)
      end
    end

    # update flag status
    config.flags.each do |flag|
      unless flags[flag.key][1] == flag.enabled
        service.set_flag(flag.key, flag.enabled)
      end
    end
    puts "LDSync - push completed successfully"
  end
end
