module Capacitor
  module Generators
    class InstallGenerator < Rails::Generators::Base
      
      # needed for Thor templates
      source_root File.expand_path("../templates", __FILE__)

      desc "This generator creates the files needed by ClouCapacitor"

      desc "This creates a default configuration file at config/"
      def create_config_file
        template 'capacitor_settings.yml.tt', "config/capacitor.yml"
      end

      desc "This creates a default configuration file at config/"
      def create_settings_class
        template 'settings.rb.tt', "app/settings/cloud_capacitor/settings.rb"
      end

    end
  end
end