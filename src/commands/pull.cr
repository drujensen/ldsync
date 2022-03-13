require "http/client"
require "json"

class Pull
  def self.exec(filename : String)
    puts "LDSync - pulling from Launch Darkly"

    config = Config.new(filename)

    # get flags
    headers = HTTP::Headers.new
    headers["Authorization"] = config.token.to_s
    headers["Content-Type"] = "application/json"
    response = HTTP::Client.get("https://app.launchdarkly.com/api/v2/flags/#{config.project}", headers: headers)

    unless response.status_code == 200
      puts "LDSync - Cannot connect to Launch Darkly.  Check your network and/or access token."
      exit
    end

    # clear existing flags
    config.flags = Hash(String, Bool).new

    # get list of existing keys
    flags = JSON.parse(response.body)
    flags["items"].as_a.each do |flag|
      key = flag["key"].as_s
      environments = flag["environments"].as_h
      env_values = environments[config.environment].as_h
      status = env_values["on"].as_bool

      config.flags[key] = status
    end

    # dump new config file
    config.dump

    puts "LDSync - pull completed successfully"
  end
end
