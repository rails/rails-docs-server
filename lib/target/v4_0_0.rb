require 'target/v3_2_x'

module Target
  class V4_0_0 < V3_2_x
    def generate_api
      # v4.0.0 had a bug, we need a hack.
      patch 'railties/lib/rails/api/task.rb' do |contents|
        contents.sub(%q(ENV['HORO_PROJECT_VERSION'] = rails_version), "ENV['HORO_PROJECT_VERSION'] ||= rails_version")
      end

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
