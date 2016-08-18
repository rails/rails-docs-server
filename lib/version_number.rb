class VersionNumber
  include Comparable

  attr_reader :parts

  def initialize(ref)
    @parts = ref.scan(/\d+/).map(&:to_i)

    @parts[1] ||= 0
    @parts[2] ||= 0
    @parts[3] ||= 0
  end

  def <=>(other)
    if other.is_a?(String)
      self <=> self.class.new(other)
    else
      parts <=> other.parts
    end
  end
end
