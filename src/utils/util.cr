class Util
  def self.humanize(value : String)
    value.gsub(/[-+_\.]/, " ").titleize
  end
end
