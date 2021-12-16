require 'version_number'

module Generators
  module Config
    module Release
      # Always use inequalities and leave an else clause to be forward compatible.
      # New Rails releases should not need this project to be updated, unless new
      # unavoidable breaking dependencies need to be configured.
      def ruby_version
        if version_number < '7.0.0'
          '2.5.3'
        else
          '2.7.2'
        end
      end

      # Always use inequalities and leave an else clause to be forward compatible.
      # New Rails releases should not need this project to be updated, unless new
      # unavoidable breaking dependencies need to be configured.
      def bundler_version
        if version_number < '6.0.3'
          '1.16.1'
        elsif version_number < '6.1.0'
          '2.1.4'
        elsif version_number < '7.0.0'
          '2.2.3'
        else
          nil
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
