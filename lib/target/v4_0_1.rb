require 'target/v4_0_0'

module Target
  class V4_0_1 < V4_0_0
    def generate_api
      rake 'rdoc'
    end
  end
end
