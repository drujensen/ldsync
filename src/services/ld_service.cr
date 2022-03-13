require "http/client"
require "json"

class LDService
  property config : Config
  getter base_url : String = "https://app.launchdarkly.com/api/v2"

  def initialize(@config)
  end

  def headers : HTTP::Headers
    headers = HTTP::Headers.new
    headers["Authorization"] = @config.token
    headers["Content-Type"] = "application/json"
    return headers
  end

  def semantic_headers : HTTP::Headers
    headers = HTTP::Headers.new
    headers["Authorization"] = @config.token
    headers["Content-Type"] = "application/json; domain-model=launchdarkly.semanticpatch"
    return headers
  end

  def sleep_if_rate_limit(response : HTTP::Client::Response)
    if limit = response.headers["X-Ratelimit-Reset"]?
      limit_sec = ((Time.unix_ms(limit.to_i64) - Time.utc)).to_i
      if limit_sec > 0
        puts "LDSync - rate limit.  waiting #{limit_sec} seconds"
        sleep limit_sec
      end
    end
  end

  def get_or_create_project
    response = HTTP::Client.get("#{base_url}/projects/#{@config.project}", headers: headers)

    unless response.status_code == 200
      if response.status_code == 404
        puts "LDSync - project not found. creating project #{@config.project}"

        # create project
        body = "{\"key\": \"#{@config.project}\", \"name\": \"#{Util.humanize(@config.project)}\"}"
        response = HTTP::Client.post("#{base_url}/projects", headers: headers, body: body)

        unless response.status_code == 201
          puts "LDSync - Failed to create project #{@config.project}"
          puts response.body.to_s
          exit 1
        end
      else
        puts "LDSync - Cannot connect to Launch Darkly.  Check your network and/or access token."
        exit 1
      end
    end

    sleep_if_rate_limit(response)
  end

  def get_or_create_environment
    response = HTTP::Client.get("#{base_url}/projects/#{@config.project}/environments/#{@config.environment}", headers: headers)

    unless response.status_code == 200
      if response.status_code == 404
        puts "LDSync - environment not found. creating environment #{@config.environment}"

        # create environment
        body = "{\"key\": \"#{@config.environment}\", \"name\": \"#{Util.humanize(@config.environment)}\", \"color\": \"DADBEE\"}"
        response = HTTP::Client.post("#{base_url}/projects/#{@config.project}/environments", headers: headers, body: body)

        unless response.status_code == 201
          puts "LDSync - Failed to create environment #{@config.environment}"
          puts response.body.to_s
          exit 1
        end
      else
        puts "LDSync - Cannot connect to Launch Darkly.  Check your network and/or access token."
        exit 1
      end
    end

    sleep_if_rate_limit(response)
  end

  def get_flags
    response = HTTP::Client.get("#{base_url}/flags/#{@config.project}", headers: headers)

    unless response.status_code == 200
      puts "LDSync - Cannot connect to Launch Darkly.  Check your network and/or access token."
      exit
    end

    sleep_if_rate_limit(response)
    return JSON.parse(response.body)
  end

  def create_flag(key : String)
    puts "LDSync - Creating flag: #{key}"
    body = "{\"key\": \"#{key}\", \"name\": \"#{Util.humanize(key)}\"}"
    response = HTTP::Client.post("#{base_url}/flags/#{@config.project}", headers: headers, body: body)

    unless response.status_code == 201
      puts "LDSync - Failed to create flag #{key}"
      puts response.body.to_s
      exit 1
    end

    sleep_if_rate_limit(response)
  end

  def set_flag(key : String, value : Bool)
    puts "LDSync - set #{key} to #{value}"
    instruction = value ? "turnFlagOn" : "turnFlagOff"

    body = "{\"environmentKey\": \"#{@config.environment}\", \"instructions\": [ { \"kind\": \"#{instruction}\" } ] }"
    response = HTTP::Client.patch("#{base_url}/flags/#{config.project}/#{key}", headers: semantic_headers, body: body)

    unless response.status_code == 200
      puts "LDSync - Failed to #{instruction} for #{key}"
      puts response.body.to_s
      exit 1
    end

    sleep_if_rate_limit(response)
  end
end
