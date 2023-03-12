require "file_utils"

class Projects
  def self.exec(filename : String)
    config = Config.new(filename)
    service = LDService.new(config)

    projects = service.get_projects

    puts "LDSync - Projects"
    puts "------------------------------------------------"
    projects.each do |key, name|
      puts "#{key}"
    end
  end
end
