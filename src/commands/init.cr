require "file_utils"

class Init
  def self.exec(filename : String)
    puts "LDSync - creating an example config file in #{filename}"
    begin
      unless File.exists? filename
        FileUtils.mkdir_p "config" if filename.includes? "config/"
        config = Config.new(filename, "example-project", "example-environment")
        config.add_flag("example-flag", "Example Flag", false)
        config.save
      else
        puts "LDSync - config file already exists. exiting"
        exit 1
      end
    rescue ex
      puts "LDSync - Could not create #{filename}. exiting"
      puts ex.message
      exit 1
    end
    puts "LDSync - init completed successfully"
  end
end
