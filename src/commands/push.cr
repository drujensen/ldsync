require "http/client"
require "json"
require "yaml"

class Push
  def self.exec(filename : String)
    puts "LDSync - pushing to Launch Darkly"
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

    # check if project exists
    headers = HTTP::Headers.new
    headers["Authorization"] = token.to_s
    headers["Content-Type"] = "application/json"
    response = HTTP::Client.get("https://app.launchdarkly.com/api/v2/projects/#{project}", headers: headers)

    unless response.status_code == 200
      if response.status_code == 404
        puts "LDSync - project not found. creating project #{project}"

        # create project
        headers = HTTP::Headers.new
        headers["Authorization"] = token.to_s
        headers["Content-Type"] = "application/json"
        body = "{\"key\": \"#{project.to_s}\", \"name\": \"#{project.to_s.sub(/[-+_\.]/, " ").titleize}\"}"
        response = HTTP::Client.post("https://app.launchdarkly.com/api/v2/projects", headers: headers, body: body)

        unless response.status_code == 201
          puts "LDSync - Failed to create project #{project}"
          puts response.body.to_s
          exit 1
        end
      else
        puts "LDSync - Cannot connect to Launch Darkly.  Check your network and/or access token."
        exit 1
      end
    end

    if limit = response.headers["X-Ratelimit-Reset"]?
      limit_sec = ((Time.unix_ms(limit.to_i64) - Time.utc)).to_i
      if limit_sec > 0
        puts "LDSync - rate limit.  waiting #{limit_sec} seconds"
        sleep limit_sec
      end
    end

    # check if environment exists
    headers = HTTP::Headers.new
    headers["Authorization"] = token.to_s
    headers["Content-Type"] = "application/json"
    response = HTTP::Client.get("https://app.launchdarkly.com/api/v2/projects/#{project}/environments/#{environment}", headers: headers)

    unless response.status_code == 200
      if response.status_code == 404
        puts "LDSync - environment not found. creating environment #{environment}"

        # create environment
        headers = HTTP::Headers.new
        headers["Authorization"] = token.to_s
        headers["Content-Type"] = "application/json"
        body = "{\"key\": \"#{environment.to_s}\", \"name\": \"#{environment.to_s.sub(/[-+_\.]/, " ").titleize}\", \"color\": \"DADBEE\"}"
        response = HTTP::Client.post("https://app.launchdarkly.com/api/v2/projects/#{project}/environments", headers: headers, body: body)

        unless response.status_code == 201
          puts "LDSync - Failed to create environment #{environment}"
          puts response.body.to_s
          exit 1
        end
      else
        puts "LDSync - Cannot connect to Launch Darkly.  Check your network and/or access token."
        exit 1
      end
    end

    if limit = response.headers["X-Ratelimit-Reset"]?
      limit_sec = ((Time.unix_ms(limit.to_i64) - Time.utc)).to_i
      if limit_sec > 0
        puts "LDSync - rate limit.  waiting #{limit_sec} seconds"
        sleep limit_sec
      end
    end

    # get existing flags
    headers = HTTP::Headers.new
    headers["Authorization"] = token.to_s
    headers["Content-Type"] = "application/json"
    response = HTTP::Client.get("https://app.launchdarkly.com/api/v2/flags/#{project}", headers: headers)

    unless response.status_code == 200
      puts "LDSync - Cannot connect to Launch Darkly.  Check your network and/or access token."
      exit
    end

    if limit = response.headers["X-Ratelimit-Reset"]?
      limit_sec = ((Time.unix_ms(limit.to_i64) - Time.utc)).to_i
      if limit_sec > 0
        puts "LDSync - rate limit.  waiting #{limit_sec} seconds"
        sleep limit_sec
      end
    end

    # get list of existing flags
    flags = JSON.parse(response.body)
    keys = [] of String
    flags["items"].as_a.each do |flag|
      keys << flag["key"].as_s
    end

    # create flags that do not exist
    yaml["flags"].as_h.each do |key, value|
      unless keys.includes? key
        puts "LDSync - Creating flag: #{key}"

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

        if limit = response.headers["X-Ratelimit-Reset"]?
          limit_sec = ((Time.unix_ms(limit.to_i64) - Time.utc)).to_i
          if limit_sec > 0
            puts "LDSync - rate limit.  waiting #{limit_sec} seconds"
            sleep limit_sec
          end
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
end
