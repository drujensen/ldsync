require "../spec_helper"

describe Util do
  it "should humanize a string with dashes" do
    Util.humanize("this-is-a-test").should eq "This Is A Test"
  end

  it "should humanize a string with pluses" do
    Util.humanize("this+is+a+test").should eq "This Is A Test"
  end

  it "should humanize a string with underscores" do
    Util.humanize("this_is_a_test").should eq "This Is A Test"
  end

  it "should humanize a string with dots" do
    Util.humanize("this.is.a.test").should eq "This Is A Test"
  end
end
