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
    global = response.headers["X-Ratelimit-Global-Remaining"]?
    route = response.headers["X-Ratelimit-Route-Remaining"]?
    limit = response.headers["X-Ratelimit-Reset"]?
    retry_after = response.headers["Retry-After"]?

    return if global && global.to_i > 0
    return if route && route.to_i > 0

    if limit
      limit_sec = ((Time.unix_ms(limit.to_i64) - Time.utc)).to_i + 5
      if limit_sec > 0
        puts "LDSync - rate limit.  waiting #{limit_sec} seconds"
        sleep limit_sec
      end
    end

    if retry_after && retry_after.to_i > 0
      puts "LDSync - ip rate limit.  waiting #{retry_after} seconds"
      sleep retry_after.to_i
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
        puts "LDSync - Cannot connect to Launch Darkly.  Check your network and/or access token. - #{response.status_code}"
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
        puts "LDSync - Cannot connect to Launch Darkly.  Check your network and/or access token. - #{response.status_code}"
        exit 1
      end
    end

    sleep_if_rate_limit(response)
  end

  def get_projects : Hash(String, String)
    response = HTTP::Client.get("#{base_url}/projects?limit=1000", headers: headers)

    unless response.status_code == 200
      puts "LDSync - Cannot connect to Launch Darkly.  Check your network and/or access token. - #{response.status_code}"
      exit
    end

    sleep_if_rate_limit(response)

    projects = JSON.parse(response.body)

    results = Hash(String, String).new
    projects["items"].as_a.each do |project|
      key = project["key"].as_s
      name = project["name"].as_s
      results[key] = name
    end

    return results
  end

  def get_environments : Hash(String, Tuple(String, String, String))
    response = HTTP::Client.get("#{base_url}/projects/#{@config.project}/environments?limit=1000", headers: headers)

    unless response.status_code == 200
      puts "LDSync - Cannot connect to Launch Darkly.  Check your network and/or access token. - #{response.status_code}"
      exit
    end

    sleep_if_rate_limit(response)

    envs = JSON.parse(response.body)

    results = Hash(String, Tuple(String, String, String)).new
    envs["items"].as_a.each do |env|
      key = env["key"].as_s
      name = env["name"].as_s
      api_key = env["apiKey"].as_s
      mobile_key = env["mobileKey"].as_s
      results[key] = {name, api_key, mobile_key}
    end

    return results
  end

  def get_flags : Hash(String, Tuple(String, Bool))
    response = HTTP::Client.get("#{base_url}/flags/#{@config.project}?limit=1000", headers: headers)

    unless response.status_code == 200
      puts "LDSync - Cannot connect to Launch Darkly.  Check your network and/or access token. - #{response.status_code}"
      exit
    end

    sleep_if_rate_limit(response)

    flags = JSON.parse(response.body)

    results = Hash(String, Tuple(String, Bool)).new
    flags["items"].as_a.each do |flag|
      key = flag["key"].as_s
      name = flag["name"].as_s
      environments = flag["environments"].as_h
      env_values = environments[@config.environment].as_h
      value = env_values["on"].as_bool
      results[key] = {name, value}
    end

    return results
  end

  def create_flag(key : String, name : String)
    puts "LDSync - Creating flag: #{key} #{name}"
    body = "{\"key\": \"#{key}\", \"name\": \"#{name}\"}"
    response = HTTP::Client.post("#{base_url}/flags/#{@config.project}", headers: headers, body: body)

    unless response.status_code == 201
      puts "LDSync - Failed to create flag #{key}. - #{response.status_code}"
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
