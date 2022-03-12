require "option_parser"
require "yaml"
require "http/client"
require "json"
require "file_utils"

config_filename = "config/ldsync.yml"
command = ""
sample = <<-EOL
  ---
  project: {project-key}
  environment: {environment-key}
  flags:
    EXAMPLE_FLAG:
      name: "Example Flag"
      status: false

  EOL

option_parser = OptionParser.parse do |parser|
  parser.banner = "Usage: ldsync"
  parser.on "-v", "--version", "Show version" do
    puts "version 0.1.1"
    exit
  end
  parser.on "-h", "--help", "Show help" do
    puts <<-EOL
    The Launch Darkly Sync Utility

    This utility will manage your Launch Darkly flags using a configuration file. It will create
    the flags if they don't exist and then turn on/off the flags based on the status.
    The default config file is config/ldsync.yml.

    The following environment variables will overwrite the config file settings:
      LDSYNC_TOKEN - Launch Darkly Access Token (required)
      LDSYNC_PROJECT - Launch Darkly Project Key
      LDSYNC_ENVIRONMENT - Launch Darkly Environment Key

    ------------------------------------
    EOL

    puts parser
    exit
  end
  parser.on "-c FILE", "--config=FILE", "Path to the config file" do |filename|
    config_filename = filename
  end
  parser.on("init", "Initialize a sample config file") do
    parser.banner = "Usage: ldsync init"
    command = "init"
  end
  parser.on("push", "Push flags to Launch Darkly") do
    parser.banner = "Usage: ldsync push"
    command = "push"
  end
  parser.on("pull", "Pull flags from Launch Darkly") do
    parser.banner = "Usage: ldsync pull"
    command = "pull"
  end
end

if command == ""
  puts "LDSync - command not recognized. Try: ldsync --help. exiting"
  exit 1
end

if command == "init"
  puts "LDSync - creating a sample config file in #{config_filename}"
  begin
    unless File.exists? config_filename
      FileUtils.mkdir_p "config" if config_filename.includes? "config/"
      File.write(config_filename, sample)
    else
      puts "LDSync - config file already exists"
    end
  rescue
    puts "LDSync - Could not create #{config_filename}. exiting"
    exit 1
  end
  puts "LDSync - init completed successfully"
end

if command == "push"
  puts "LDSync - pushing to Launch Darkly"
  # read config/ldsync.yml
  begin
    yaml = File.open(config_filename) do |file|
      YAML.parse(file)
    end
  rescue
    puts "LDSync - Could not open #{config_filename}. exiting."
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

  # get list of existing keys
  flags = JSON.parse(response.body)
  keys = [] of String
  flags["items"].as_a.each do |flag|
    keys << flag["key"].as_s
  end

  # create flags that don't exist
  yaml["flags"].as_h.each do |key, value|
    unless keys.includes? key
      # create flag
      puts "Creating Flag: #{key}"
      headers = HTTP::Headers.new
      headers["Authorization"] = token.to_s
      headers["Content-Type"] = "application/json"
      body = "{\"key\": \"#{key.to_s}\", \"name\": \"#{value["name"].to_s}\"}"
      response = HTTP::Client.post("https://app.launchdarkly.com/api/v2/flags/#{project}", headers: headers, body: body)
      unless response.status_code == 201
        puts "LDSync - Failed to create flag #{key}"
        puts response.body.to_s
        exit 1
      end
    end
  end

  # update flag status
  yaml["flags"].as_h.each do |key, value|
    instruction = value["status"].as_bool ? "turnFlagOn" : "turnFlagOff"
    puts "LDSync - #{instruction} for #{key}"
    headers = HTTP::Headers.new
    headers["Authorization"] = token.to_s
    headers["Content-Type"] = "application/json; domain-model=launchdarkly.semanticpatch"
    body = "{\"environmentKey\": \"#{environment.to_s}\", \"instructions\": [ { \"kind\": \"#{instruction}\" } ] }"
    response = HTTP::Client.patch("https://app.launchdarkly.com/api/v2/flags/#{project}/#{key}", headers: headers, body: body)
    unless response.status_code == 200
      puts "LDSync - Failed to #{instruction} for #{key}"
      puts response.body.to_s
      exit 1
    end
    if limit = response.headers["X-Ratelimit-Reset"]?
      limit_sec = ((Time.unix_ms(limit.to_i64) - Time.utc)).to_i
      if limit_sec > 0
        puts "LDSync - rate limit.  waiting #{limit_sec} seconds"
        sleep limit_sec
      end
    end
  end
  puts "LDSync - push completed successfully"
end

if command == "pull"
  puts "LDSync - pulling from Launch Darkly"
  # read config/ldsync.yml
  begin
    yaml = File.open(config_filename) do |file|
      YAML.parse(file)
    end
  rescue
    puts "LDSync - Could not open #{config_filename}. exiting."
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
    FileUtils.mkdir_p "config" if config_filename.includes? "config/"
    File.write(config_filename, YAML.dump(config))
  rescue
    puts "LDSync - Could not create #{config_filename}. exiting"
    exit 1
  end

  puts "LDSync - pull completed successfully"
end
