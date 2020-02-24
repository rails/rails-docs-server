module Generators
  module Config
    module Master
      def ruby_version
        '2.5.3'
      end

      def bundler_version
        '2.1.4'
      end

      def api_output
        "#{basedir}/doc/rdoc"
      end

      def guides_output
        "#{basedir}/guides/output"
      end
    end
  end
end
