require "logger"

module Log

  def log
    @logger ||= defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "- #{msg}\n"
    end
    @logger
  end
end