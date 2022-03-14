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
    flags.each do |key, value|
      config.flags[key] = value
    end

    # save the new config file
    config.save

    puts "LDSync - pull completed successfully"
  end
end
