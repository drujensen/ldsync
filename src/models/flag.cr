require "yaml"

class Flag
  include YAML::Serializable

  property key : String
  property name : String
  property enabled : Bool

  def initialize(@key, @name, @enabled)
  end
end
