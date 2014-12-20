require 'target/v4_0_1'

module Target
  class V4_2_0 < V4_0_1

    # The Gemfile in 4.2 uses a :mri_21 platform unknown to older versions.
    def bundler_version
      '1.7.7'
    end

    def install_gems
      # This Gemfile had a dependency that could not be satisfied.
      gemfile = File.read('Gemfile')
      gemfile.sub!(/^.*delayed_job_active_record.*$/, '')
      File.write('Gemfile', gemfile)

      super
    end
  end
end
