require 'target/v4_2_1'

module Target
  class V4_2_3 < V4_2_1
    # The Gemfile and Gemfile.lock have conflicting version specifiers for
    # sprockets, as interpreted by Bundler 1.7.7.
    def bundler_version
      '1.10.5'
    end
  end
end
