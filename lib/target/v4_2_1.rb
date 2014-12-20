require 'target/v4_0_1'

module Target
  # This superclass is correct, V4_2_0 overrides install_gems.
  class V4_2_1 < V4_0_1

    # The Gemfile in 4.2 uses a :mri_21 platform unknown to older versions.
    def bundler_version
      '1.7.7'
    end
  end
end
