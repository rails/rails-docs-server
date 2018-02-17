require 'logging'
require 'version_number'

module Generators
  # @abstract
  #
  # This class is abstract, there are concrete implementations for release and
  # edge docs generators.
  class Base
    include Logging

    attr_reader :target, :basedir

    # @param target [String] A Git reference like 'v4.2.0' or a SHA1
    # @param basedir [String] A directory in which target has been checked out
    def initialize(target, basedir)
      @target  = target
      @basedir = File.expand_path(basedir)
    end

    # Generates the documentation for target within basedir.
    def generate
      Dir.chdir(basedir) do
        before_generation

        install_gems
        generate_api
        generate_guides
      end
    end

    private

    # Sometimes we need to patch the repo in order to be able to generate docs.
    # That is the purpose of this hook.
    def before_generation
    end

    # @abstract
    def generate_api
      raise 'Abstract method'
    end

    # @abstract
    def generate_guides
      raise 'Abstract method'
    end

    # Installs the gems needed for docs generation. Note that Bundler does not
    # complain about unknown groups, so we can add new groups unconditionally.
    def install_gems
      Dir.chdir(basedir) do
        bundle 'install --without db test job cable storage ujs'
      end
    end

    # Builds a string of shell variable assigns, just for loggin purposes.
    #
    # @param env [Hash{String => String}]
    # @return [String]
    def env_as_assigns(env)
      [].tap do |assigns|
        env.each do |k, v|
          assigns << %(#{k}="#{v}")
        end
      end.join(' ')
    end

    # Runs a system command under the Ruby interpreter given by `ruby_version`,
    # with the given environment variables.
    #
    # @param command [String]
    # @param env [Hash{String => String}]
    def run(command, env={})
      command = "rvm #{ruby_version} do #{command} >/dev/null"
      log "#{env_as_assigns(env)} #{command}"
      system(env, command)
    end

    # Runs `bundle exec rake` with the appropriate Bundler and Ruby versions.
    def rake(command, env={})
      bundle "exec rake #{command}", env
    end

    # Runs the Bundler command with Bundler version `bundler_version`.
    #
    # @param command [String]
    # @param env [Hash{String => String}]
    def bundle(command, env={})
      run "bundle _#{bundler_version}_ #{command}", env
    end

    # Slurps a file, yields its content, and writes whatever the block returns
    # back to the file.
    #
    # @param filename [String]
    def patch(filename)
      original = File.read(filename)
      patched  = yield original

      File.write(filename, patched)
    end
  end
end
