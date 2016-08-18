require 'version_number'

module Generators
  module Config
    module Release
      # Always use inequalities and leave an else clause to be forward compatible.
      # New Rails releases should not need this project to be updated, unless new
      # unavoidable breaking dependencies need to be configured.
      def ruby_version
        if version_number < '5.0.0'
          '2.0.0-p598-railsexpress'
        else
          '2.2.2'
        end
      end

      # Always use inequalities and leave an else clause to be forward compatible.
      # New Rails releases should not need this project to be updated, unless new
      # unavoidable breaking dependencies need to be configured.
      def bundler_version
        if version_number < '4.1.12'
          '1.3.5'
        elsif version_number < '4.2.0'
          '1.10.5'
        elsif version_number < '4.2.3'
          '1.7.7'
        elsif version_number < '5.0.0'
          '1.10.5'
        else
          '1.11.2'
        end
      end

      def api_output
        "#{basedir}/doc/rdoc"
      end

      def guides_output
        if version_number < '4.0.0'
          "#{basedir}/railties/guides/output"
        else
          "#{basedir}/guides/output"
        end
      end
    end
  end
end
