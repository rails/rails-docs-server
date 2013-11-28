require 'target/v3_2_x'

module Target
  class V4_0_0 < V3_2_x
    def generate_api
      # v4.0.0 had a bug, we need a hack.
      rb = File.read('railties/lib/rails/api/task.rb')
      rb.sub!(%q(ENV['HORO_PROJECT_VERSION'] = rails_version), "ENV['HORO_PROJECT_VERSION'] ||= rails_version")
      File.write('railties/lib/rails/api/task.rb', rb)

      super
    end

    def guides_output
      "#{basedir}/guides/output"
    end

    def generate_guides
      Dir.chdir('guides') do
        rake 'guides:generate:html',   'RAILS_VERSION' => target
        rake 'guides:generate:kindle', 'RAILS_VERSION' => target
      end
    end
  end
end
