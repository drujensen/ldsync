require "../spec_helper"

describe Config do
  it "should load from a config file" do
    config = Config.new "spec/utils/config/sample.yml"
    config.project.should eq "example-project"
    config.environment.should eq "example-environment"
    config.flags["example-flag"].should eq false
  end

  it "dump values to a yaml file" do
    config = Config.new "spec/utils/config/sample.yml"
    FileUtils.rm "spec/utils/config/sample.yml"
    config.dump
    File.exists?("spec/utils/config/sample.yml").should eq true
  end
end
