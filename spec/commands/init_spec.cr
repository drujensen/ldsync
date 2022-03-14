require "../spec_helper"

describe Init do
  it "should create a sample config file" do
    filename = "spec/utils/config/init-test.yml"
    FileUtils.rm(filename) if File.exists?(filename)
    Init.exec(filename)
    File.exists?(filename).should eq true
    FileUtils.rm(filename) if File.exists?(filename)
  end
end
