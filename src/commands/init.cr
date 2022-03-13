require "file_utils"

class Init
  def self.exec(project : String, filename : String)
    sample = <<-EOL
    ---
    project: #{project}
    environment: local
    flags:
      example:
        name: "Example Flag"
        status: false

    EOL

    puts "LDSync - creating a sample config file in #{filename}"
    begin
      unless File.exists? filename
        FileUtils.mkdir_p "config" if filename.includes? "config/"
        File.write(filename, sample)
      else
        puts "LDSync - config file already exists"
      end
    rescue
      puts "LDSync - Could not create #{filename}. exiting"
      exit 1
    end
    puts "LDSync - init completed successfully"
  end
end
