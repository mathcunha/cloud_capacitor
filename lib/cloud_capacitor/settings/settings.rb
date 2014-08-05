require 'settingslogic'

module CloudCapacitor
  class Settings < Settingslogic
      source File.join( File.expand_path('../../../..', __FILE__), "capacitor_settings.yml" )
    end
  end
end
