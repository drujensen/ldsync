require "../spec_helper"

describe Config do
  it "should load from a config file" do
    config = Config.new "config/ldsync.yml"
    config.project.should eq "example-project"
    config.environment.should eq "example-environment"
    config.flags[0].key.should eq "example-flag"
    config.flags[0].name.should eq "Example Flag"
    config.flags[0].enabled.should eq false
  end

  it "should support loading an empty config file for the init function" do
    config = Config.new "config/ldsync.yml", "example-project", "example-environment"
    config.project.should eq "example-project"
    config.environment.should eq "example-environment"
  end

  it "saves values to a yaml file" do
    config = Config.new "config/ldsync.yml"
    FileUtils.rm "config/ldsync.yml"
    config.save
    File.exists?("config/ldsync.yml").should eq true
  end
end
