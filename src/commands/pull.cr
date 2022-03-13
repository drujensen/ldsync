class Pull
  def self.exec(filename : String)
    puts "LDSync - pulling from Launch Darkly"

    # load config file
    config = Config.new(filename)

    # load launch darkly service
    service = LDService.new(config)

    # clear existing flags
    config.flags = Hash(String, Bool).new

    # get list of existing keys
    flags = service.get_flags

    flags["items"].as_a.each do |flag|
      key = flag["key"].as_s
      environments = flag["environments"].as_h
      env_values = environments[config.environment].as_h
      status = env_values["on"].as_bool

      config.flags[key] = status
    end

    # dump new config file
    config.dump

    puts "LDSync - pull completed successfully"
  end
end
