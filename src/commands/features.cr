require "file_utils"

class Features
  def self.exec(filename : String, project : String, environment : String)
    config = Config.new(filename)

    # override project
    config.project = project unless project.empty?

    # override environment
    config.environment = environment unless environment.empty?

    service = LDService.new(config)

    flags = service.get_flags

    puts "LDSync - Flags for #{config.project}"
    puts "------------------------------------------------"
    flags.each do |key, values|
      puts "key: #{key}"
      puts "name: #{values[0]}"
      puts "status: #{values[1]}"
      puts ""
      puts "------------------------------------------------"
    end
  end
end
