require "http/client"
require "json"
require "yaml"

class Pull
  def self.exec(filename : String)
    puts "LDSync - pulling from Launch Darkly"
    # read config/ldsync.yml
    begin
      yaml = File.open(filename) do |file|
        YAML.parse(file)
      end
    rescue
      puts "LDSync - Could not open #{filename}. exiting."
      exit 1
    end

    unless token = ENV["LDSYNC_TOKEN"]? || yaml["token"]?
      puts "LDSync - Access token required. exiting."
      exit 1
    end

    unless project = ENV["LDSYNC_PROJECT"]? || yaml["project"]?
      puts "LDSync - Project required. exiting."
      exit 1
    end

    unless environment = ENV["LDSYNC_ENVIRONMENT"]? || yaml["environment"]?
      puts "LDSync - Environment required. exiting."
      exit 1
    end

    # connect to ld
    headers = HTTP::Headers.new
    headers["Authorization"] = token.to_s
    headers["Content-Type"] = "application/json"
    response = HTTP::Client.get("https://app.launchdarkly.com/api/v2/flags/#{project}", headers: headers)

    unless response.status_code == 200
      puts "LDSync - Cannot connect to Launch Darkly.  Check your network and/or access token."
      exit
    end

    config = Hash(String, String | Hash(String, Hash(String, String | Bool))).new
    config["token"] = token.to_s if yaml["token"]?
    config["project"] = project.to_s
    config["environment"] = environment.to_s

    tmp_flags = Hash(String, Hash(String, String | Bool)).new

    # get list of existing keys
    flags = JSON.parse(response.body)
    flags["items"].as_a.each do |flag|
      key = flag["key"].as_s
      name = flag["name"].as_s
      environments = flag["environments"].as_h
      env_values = environments[environment].as_h
      status = env_values["on"].as_bool

      tmp = Hash(String, String | Bool).new
      tmp["name"] = name
      tmp["status"] = status
      tmp_flags[key] = tmp
    end

    config["flags"] = tmp_flags

    # write new yaml file
    begin
      FileUtils.mkdir_p "config" if filename.includes? "config/"
      File.write(filename, YAML.dump(config))
    rescue
      puts "LDSync - Could not create #{filename}. exiting"
      exit 1
    end

    puts "LDSync - pull completed successfully"
  end
end
