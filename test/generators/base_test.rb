require 'test_helper'
require 'generators/base'

class Generators::BaseTest < Minitest::Test
  class TestGenerator < Generators::Base
    attr_reader :bundle_commands

    def initialize(*)
      super
      @bundle_commands = []
    end

    def generate_api
    end

    def generate_guides
    end

    def bundle(command, env={})
      @bundle_commands << {command: command, env: env}
    end

    public :install_gems
  end

  def test_install_gems_uses_bundle_config_for_bundler_4
    in_tmpdir do
      mkdir_p 'test_target'

      generator = TestGenerator.new('test', 'test_target')
      generator.install_gems

      assert_equal 2, generator.bundle_commands.length
      assert_equal 'config set --local without db:test:job:cable:storage:ujs', generator.bundle_commands[0][:command]
      assert_equal 'install', generator.bundle_commands[1][:command]
    end
  end
end
