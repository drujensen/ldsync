require "file_utils"

class Environments
  def self.exec(filename : String, project : String)
    config = Config.new(filename)

    # override project
    config.project = project unless project.empty?

    service = LDService.new(config)

    environments = service.get_environments

    puts "LDSync - Enviroments for #{config.project}"
    puts "------------------------------------------------"
    environments.each do |key, values|
      puts "key: #{key}"
      puts "name: #{values[0]}"
      puts "api-key: #{values[1]}"
      puts "mobile-key: #{values[2]}"
      puts ""
      puts "------------------------------------------------"
    end
  end
end
