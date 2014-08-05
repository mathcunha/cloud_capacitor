require "logger"

module Log

  def log
    if !defined?(Rails)
      @logger = Logger.new(STDOUT)
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "- #{msg}\n" 
      end
    else
      @logger = Rails.logger
    end
    @logger
  end
end