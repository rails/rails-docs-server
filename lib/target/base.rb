require 'logging'

module Target
  class Base
    include Logging

    attr_reader :target, :basedir

    def initialize(target, basedir)
      @target  = target
      @basedir = basedir
    end

    def generate
      Dir.chdir(basedir) do
        install_gems
        generate_api
        generate_guides
      end
    end

    private

    def install_gems
      Dir.chdir(basedir) do
        bundle 'install --without db test'
      end
    end

    def env_as_assigns(env)
      ''.tap do |_|
        env.each do |k, v|
          _ << %(#{k}="#{v}" )
        end
      end
    end

    def run(command, env={})
      command = "rvm #{ruby_version} do #{command} >/dev/null"
      log "#{env_as_assigns(env)}#{command}"
      system(env, command)
    end

    def rake(command, env={})
      bundle "exec rake #{command}", env
    end

    def bundle(command, env={})
      run "bundle _#{bundler_version}_ #{command}", env
    end
  end
end
