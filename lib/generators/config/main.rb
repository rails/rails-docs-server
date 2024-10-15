module Generators
  module Config
    module Main
      def ruby_version
        '3.2.5'
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
