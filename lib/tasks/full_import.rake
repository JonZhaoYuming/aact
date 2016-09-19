namespace :import do
  namespace :full do
    task :run, [:force] => :environment do |t, args|
      begin
        if [1,4,8,12,16,22,26,30].include? Date.today.day || args[:force]
          $stdout.puts 'Full Import: begin...'
          load_event = ClinicalTrials::LoadEvent.create( event_type: 'full_import')
          all_tables = ActiveRecord::Base.connection.tables

          blacklist = %w(
            schema_migrations
            load_events
            sanity_checks
            statistics
            study_xml_records
          )

          $stdout.puts 'Full Import: truncate tables...'
          tables_to_truncate = all_tables.reject do |table|
            blacklist.include?(table)
          end

          tables_to_truncate.each do |table|
            $stdout.puts "  truncate #{table}"
            ActiveRecord::Base.connection.truncate(table)
          end

          client = ClinicalTrials::Client.new
          $stdout.puts "Full Import: #{Time.now}  download xml files..."
          client.download_xml_files
          $stdout.puts "Full Import: #{Time.now}  populate studies..."
          client.populate_studies

          load_event.update(new_studies: Study.count, changed_studies: 0)
          load_event.complete

          $stdout.puts "Full Import: #{Time.now}  sanity check..."
          SanityCheck.run
          #$stdout.puts 'Daily Import: StudyValidator...'
          #StudyValidator.new.validate_studies
          $stdout.puts "Full Import: #{Time.now}  load notification..."
          LoadMailer.send_notifications(load_event, client.errors)
        else
          puts "Not the first of the month - not running full import"
        end
      rescue StandardError => e
        $stdout.puts "Full Import: #{Time.now}  Error encountered:  #{e}"
        updater.errors << {:name => 'An error was raised during the load.', :first_backtrace_line => e}
        LoadMailer.send_notifications(load_event, updater.errors)
        raise e
      end
    end
  end
end
