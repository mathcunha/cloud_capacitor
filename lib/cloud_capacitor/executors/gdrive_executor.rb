require "google_drive"

module CloudCapacitor
  module Executors
    
    # Emulates an execution by retrieving previous executions results from
    # a Google Drive spreadsheet
    class GDrive_Executor
      def run(configuration:, workload:)
        login
        select_worksheet
        get_result configuration.name, workload
      end

      protected
        def login
          if !ENV.has_key?("GDRIVE_USERNAME") || !ENV.has_key?("GDRIVE_PASSWORD")
            raise StandardError, "DEFINA VARIAVEIS GDRIVE_USERNAME E GDRIVE_PASSWORD!!"
          end
          @session = GoogleDrive.login(ENV["GDRIVE_USERNAME"], ENV["GDRIVE_PASSWORD"])
        end

        def select_worksheet
          @ws = @session.spreadsheet_by_key("0AjTgTUEwBHTGdGRWdjMtZnpMSkRMcFc3bEhJanhSUEE").worksheets[0]
        end

        def get_result(config, workload)
          col  = @ws.rows[1].index(workload.to_s) + 1
          puts "Procurando #{config} na planilha"
          puts "Encontrei na linha #{@ws.rows.index(@ws.rows.detect{ |row| row.include?(config)})}"
          line = @ws.rows.index(@ws.rows.detect{ |row| row.include?(config)}) + 1

          { response_time: @ws[line, col], 
            cpu: @ws[line, col + 4].to_f, 
            mem: @ws[line, col + 5].to_f, 
            errors: @ws[line, col + 3], 
            requests: 1000 }

        end
    end

  end
end
