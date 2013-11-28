module Logging
  def log(message)
    puts "[#{Time.now.utc}] #{message}"
  end
end
