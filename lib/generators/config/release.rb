require 'version_number'

module Generators
  module Config
    module Release
      # Always use inequalities and leave an else clause to be forward compatible.
      # New Rails releases should not need this project to be updated, unless new
      # unavoidable breaking dependencies need to be configured.
      def ruby_version
        '2.5.3'
      end

      # Always use inequalities and leave an else clause to be forward compatible.
      # New Rails releases should not need this project to be updated, unless new
      # unavoidable breaking dependencies need to be configured.
      def bundler_version
        '1.16.1'
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
