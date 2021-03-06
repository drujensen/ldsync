require "option_parser"
require "./utils/*"
require "./services/*"
require "./commands/*"
require "./models/*"

module LDSync
  def self.exec
    filename = "config/ldsync.yml"
    command = ""

    option_parser = OptionParser.parse do |parser|
      parser.banner = "Usage: ldsync [command]"
      parser.on "-v", "--version", "Show version" do
        puts "version 0.1.5"
        exit
      end
      parser.on "-h", "--help", "Show help" do
        puts <<-EOL
    The Launch Darkly Sync Utility

    This utility will manage your Launch Darkly flags using a configuration file. It will create
    the flags if they don't exist and then turn on/off the flags based on the status.
    The default config file is config/ldsync.yml.

    The following environment variables will overwrite the config file settings:
      LD_TOKEN - Launch Darkly Access Token (required)
      LD_PROJECT - Launch Darkly Project Key
      LD_ENVIRONMENT - Launch Darkly Environment Key

    ------------------------------------
    EOL

        puts parser
        exit
      end
      parser.on "-c FILE", "--config=FILE", "Path to the config file" do |file|
        filename = file
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

    if command == "init"
      Init.exec(filename)
    end

    if command == "push"
      Push.exec(filename)
    end

    if command == "pull"
      Pull.exec(filename)
    end
  end
end

LDSync.exec
