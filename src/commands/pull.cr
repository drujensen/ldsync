class Pull
  def self.exec(filename : String, project : String, environment : String)
    puts "LDSync - pulling from Launch Darkly"

    # load config file
    config = Config.new(filename)

    # override project
    config.project = project unless project.empty?

    # override environment
    config.environment = environment unless environment.empty?

    # load launch darkly service
    service = LDService.new(config)

    # clear existing flags
    config.clear_flags

    # get list of existing keys
    flags = service.get_flags
    flags.each do |key, values|
      config.add_flag(key, values[0], values[1])
    end

    # save the new config file
    config.save

    puts "LDSync - pull completed successfully"
  end
end
