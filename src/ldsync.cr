require "option_parser"
require "yaml"
require "http/client"
require "json"

config_filename = "config/ldsync.yml"

option_parser = OptionParser.parse do |parser|
  parser.banner = "Usage: ldsync"
  parser.on "-v", "--version", "Show version" do
    puts "version 0.1.0"
    exit
  end
  parser.on "-h", "--help", "Show help" do
    puts <<-EOL
    The Launch Darkly Sync Utility

    This utility will manage your Launch Darkly flags using a configuration file.

    This utility will create the flags if they don't exist and then turn on/off the flags based on the status.

    The default config file is config/ldsync.yml.

    Here is an example:
    ------------------------------------

    project: {project-key}
    environment: {environment-key}
    flags:
      EXAMPLE_ON_FLAG:
        name: "Example On Flag"
        status: true
      EXAMPLE_OFF_FLAG:
        name: "Example Off Flag"
        status: false

    ------------------------------------

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
end

# read config/ldsync.yml
yaml = File.open(config_filename) do |file|
  YAML.parse(file)
end

unless token = ENV["LDSYNC_TOKEN"]? || yaml["access_token"]?
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
  puts "#{instruction} for #{key}"
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
end

puts "LDSync - Done!"
