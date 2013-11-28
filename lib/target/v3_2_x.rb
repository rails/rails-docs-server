require 'target/base'

module Target
  class V3_2_x < Base
    def ruby_version
      '2.0.0-p353-railsexpress'
    end

    def bundler_version
      '1.3.5'
    end

    def api_output
      "#{basedir}/doc/rdoc"
    end

    def guides_output
      "#{basedir}/railties/guides/output"
    end

    def generate_api
      rake 'rdoc', 'HORO_PROJECT_NAME' => 'Ruby on Rails', 'HORO_PROJECT_VERSION' => target
    end

    def generate_guides
      Dir.chdir('railties') do
        rake 'generate_guides', 'RAILS_VERSION' => target
        rake 'generate_guides', 'KINDLE' => '1', 'RAILS_VERSION' => target
      end
    end
  end
end
