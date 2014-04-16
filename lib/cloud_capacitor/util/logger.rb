require "logger"

module Log
  def log
    log_output = CloudCapacitor::Settings.logger.log_to_file == 0 ? 
        STDOUT : File.open(File.join( File.expand_path('../..', __FILE__), "cloud_capacitor.log"), "a")
    @logger ||= defined?(Rails) ? Rails.logger : Logger.new(log_output)
  end
end