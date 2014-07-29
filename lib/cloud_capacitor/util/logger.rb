require "logger"

module Log

  def included(mod)
    @log_output ||= CloudCapacitor::Settings.logger.log_to_file == 0 ? 
        STDOUT : File.open(File.join( File.expand_path('../..', __FILE__), "cloud_capacitor.log"), "a")
  end

  def log
    # @logger ||= defined?(Rails) ? Rails.logger : Logger.new(@log_output)
    @logger ||= defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "- #{msg}\n"
    end
    @logger
  end
end