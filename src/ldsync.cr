require "option_parser"
require "./utils/*"
require "./services/*"
require "./commands/*"
require "./models/*"

module LDSync
  def self.exec
    filename = "config/ldconfig.yml"
    project = ""
    environment = ""
    command = ""

    option_parser = OptionParser.parse do |parser|
      parser.banner = "Usage: ldsync [command]"
      parser.on "-v", "--version", "Show version" do
        puts "version 0.2.0"
        exit
      end
      parser.on "-h", "--help", "Show help" do
        puts <<-EOL
    The Launch Darkly Sync Utility

    This utility will manage your Launch Darkly flags using a configuration file. It will create
    the flags if they don't exist and then turn on/off the flags based on the status.
    The default config file is config/ldconfig.yml.

    The following environment variables will overwrite the config file settings:
      LD_TOKEN - Launch Darkly Access Token (required)
      LD_PROJECT - Launch Darkly Project Key
      LD_ENVIRONMENT - Launch Darkly Environment Key

    ------------------------------------
    EOL

        puts parser
        exit
      end
      parser.on "projects", "List all the projects" do
        parser.banner = "Usage: ldsync projects"
        command = "projects"
      end
      parser.on "environments", "List all the environments for a project" do
        parser.banner = "Usage: ldsync -p {project} environments"
        command = "environments"
      end
      parser.on("flags", "List all the flags for a project") do
        parser.banner = "Usage: ldsync -p {project} -e {env} flags"
        command = "flags"
      end
      parser.on "-c FILE", "--config=FILE", "Path to the config file" do |file|
        filename = file
      end
      parser.on "-p PROJECT", "--proejct=PROJECT", "Project" do |proj|
        project = proj
      end
      parser.on "-e ENV", "--environment=ENV", "Environment" do |env|
        environment = env
      end
      parser.on "init", "Initialize a sample config file" do
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

    if command == "projects"
      Projects.exec(filename)
      exit
    end

    if command == "environments"
      Environments.exec(filename, project)
      exit
    end

    if command == "flags"
      Features.exec(filename, project, environment)
      exit
    end

    if command == "init"
      Init.exec(filename)
      exit
    end

    if command == "push"
      Push.exec(filename)
      exit
    end

    if command == "pull"
      Pull.exec(filename)
      exit
    end

    puts "Command not recognized"
  end
end

LDSync.exec
