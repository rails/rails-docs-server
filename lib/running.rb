module Running
  include Logging

  def log_and_system(*args)
    log(args.map(&:to_s).join(' '))
    system(*args).tap { log "Done" }
  end
end
