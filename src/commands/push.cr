require "http/client"
require "json"
require "yaml"

class Push
  def self.exec(filename : String)
    puts "LDSync - pushing to Launch Darkly"

    # load config file
    config = Config.new(filename)

    # check if project exists
    puts "LDSync - Check if project exists"
    headers = HTTP::Headers.new
    headers["Authorization"] = config.token
    headers["Content-Type"] = "application/json"
    response = HTTP::Client.get("https://app.launchdarkly.com/api/v2/projects/#{config.project}", headers: headers)

    unless response.status_code == 200
      if response.status_code == 404
        puts "LDSync - project not found. creating project #{config.project}"

        # create project
        headers = HTTP::Headers.new
        headers["Authorization"] = config.token
        headers["Content-Type"] = "application/json"
        body = "{\"key\": \"#{config.project}\", \"name\": \"#{Util.humanize(config.project)}\"}"
        response = HTTP::Client.post("https://app.launchdarkly.com/api/v2/projects", headers: headers, body: body)

        unless response.status_code == 201
          puts "LDSync - Failed to create project #{config.project}"
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
    puts "LDSync - Check if environment exists"
    headers = HTTP::Headers.new
    headers["Authorization"] = config.token
    headers["Content-Type"] = "application/json"
    response = HTTP::Client.get("https://app.launchdarkly.com/api/v2/projects/#{config.project}/environments/#{config.environment}", headers: headers)

    unless response.status_code == 200
      if response.status_code == 404
        puts "LDSync - environment not found. creating environment #{config.environment}"

        # create environment
        headers = HTTP::Headers.new
        headers["Authorization"] = config.token
        headers["Content-Type"] = "application/json"
        body = "{\"key\": \"#{config.environment}\", \"name\": \"#{Util.humanize(config.environment)}\", \"color\": \"DADBEE\"}"
        response = HTTP::Client.post("https://app.launchdarkly.com/api/v2/projects/#{config.project}/environments", headers: headers, body: body)

        unless response.status_code == 201
          puts "LDSync - Failed to create environment #{config.environment}"
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
    puts "LDSync - Get existing flags"
    headers = HTTP::Headers.new
    headers["Authorization"] = config.token
    headers["Content-Type"] = "application/json"
    response = HTTP::Client.get("https://app.launchdarkly.com/api/v2/flags/#{config.project}", headers: headers)

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
    config.flags.each do |key, value|
      unless keys.includes? key
        puts "LDSync - Creating flag: #{key}"

        headers = HTTP::Headers.new
        headers["Authorization"] = config.token
        headers["Content-Type"] = "application/json"
        body = "{\"key\": \"#{key.to_s}\", \"name\": \"#{Util.humanize(key.to_s)}\"}"
        response = HTTP::Client.post("https://app.launchdarkly.com/api/v2/flags/#{config.project}", headers: headers, body: body)

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
    config.flags.each do |key, value|
      puts "LDSync - set #{key} to #{value}"
      instruction = value ? "turnFlagOn" : "turnFlagOff"

      headers = HTTP::Headers.new
      headers["Authorization"] = config.token
      headers["Content-Type"] = "application/json; domain-model=launchdarkly.semanticpatch"
      body = "{\"environmentKey\": \"#{config.environment}\", \"instructions\": [ { \"kind\": \"#{instruction}\" } ] }"
      response = HTTP::Client.patch("https://app.launchdarkly.com/api/v2/flags/#{config.project}/#{key}", headers: headers, body: body)

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
