class LockFile
  def self.acquiring(filename)
    # This idiom is atomic, either your process is able to create and open the
    # lock file or Errno::EEXIST is raised. No race conditions are possible.
    lock_file = File.open(filename, File::CREAT | File::EXCL | File::WRONLY)
    lock_file.write("#{$$}\n")
    log "acquired lock file #{filename}"
    begin
      yield
    ensure
      log "releasing lock file #{filename}")
      lock_file.close
      FileUtils.rm_f(filename)
    end
  rescue Errno::EEXIST
    log "couldn't acquire lock file #{filename}"
  end

  def self.log(msg)
    puts "[#{Time.now.utc}] #{msg}"
  end
end
