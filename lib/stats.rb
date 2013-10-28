module Stats
  def self.geometric_mean(values)
    return 0 unless values.is_a?(Array)
    
    Math.exp ( values.map { |x| Math.log(x) }.reduce(&:+) / values.length )
  end
end