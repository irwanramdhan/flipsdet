require 'rubygems'
require 'cucumber'
require 'cucumber/rake/task'
require 'report_builder'
require 'parallel_tests'
require 'byebug'

namespace :flip do
  @status = true
  @max_parallel = ENV['MAX_PARALLEL'].to_i

  Cucumber::Rake::Task.new do |t|
    t.cucumber_opts = %w[--format progress]
  end

  Cucumber::Rake::Task.new(:test, 'Run Flip Automation Test') do |t|
    # sample use: rake flip:test t=@login REPORT_NAME=2
    t.cucumber_opts = ["-t #{ENV['t']}"] unless ENV['t'].nil?
    t.cucumber_opts = ["features/#{ENV['f']}"] unless ENV['f'].nil?
    t.profile = 'rake_run'
  end

  desc 'Parallel run'
  task :parallel do
    abort '=====:: Failed to proceed, tags needed for parallel (t=@sometag)' if ENV['t'].nil?
    puts "=====:: Parallel execution tag: #{ENV['t']} about to start "
    

    begin
      @status = system "bundle exec parallel_cucumber features/ -n #{@max_parallel} -o '-t #{ENV['t']}'"
      puts "Testing @status after parallel #{@status}"
    rescue StandardError => exception
      p 'Found error!'
      pp exception
    ensure
      puts '=====::  ::====='
    end
  end

  desc 'Parallel run base on test run id'
  task :parallel_run_id do
    abort '=====:: Failed to proceed, run id needed for parallel (RUN_ID=12345)' if ENV['RUN_ID'].nil?
    puts "=====:: Parallel execution run id: #{ENV['RUN_ID']} about to start "
    puts "=====:: #{@max_parallel} processes"

    begin
      running_file = []
      # ENV['GROUP_INDEX'] = 1.to_s
      target_file = "#{ENV['application_type']}_test_group#{ENV['GROUP_INDEX'].to_i}"
      test_group_path = File.expand_path("#{Dir.pwd}/#{target_file}")
      puts test_group_path
      puts "#{Dir.glob(File.join('*', '**', target_file), File::FNM_DOTMATCH)}"
      running_file = if File.exist?(test_group_path)
                       File.readlines(target_file,chomp:true) 
                     else
                       ['-t @nothing-to-test']
                     end
      threads = []
      results = []
      puts "will running file #{running_file}"
      count = 0
      final_running_file = running_file.each_slice(@max_parallel).to_a
      final_running_file.each do |f_file|
        f_file.each_with_index do |f_line, index|
          ENV['TEST_ENV_NUMBER'] = (index +1).to_s
          puts "ENV NUMBER #{ENV['TEST_ENV_NUMBER']}"
          threads << Thread.new do
             system "cucumber -p rake_run #{f_line}"
          end
          sleep 1 until File.exist?("#{$report_root}/#{ENV['REPORT_PATH']}/cucumber#{ENV['TEST_ENV_NUMBER']}.json")
        end
        results << threads.map(&:value)
        # threads.each(&:join)
      end
      puts "Testing threads status after parallel #{results.to_s}"
    rescue Exception => exception
      p 'Found error!'
      pp exception
    ensure
      puts '=====::  ::====='
    end
  end

  task :clear_report do
    puts '=====:: Delete report directory '
    report_root = File.absolute_path('./report')
    FileUtils.rm_rf(report_root, secure: true)
    FileUtils.mkdir_p report_root
  end

  task :init_report_run_id do
    $report_root = File.absolute_path('./report')
    ENV['REPORT_PATH'] = Time.now.strftime('%F_%H-%M-%S.%N')
    puts "=====:: about to create report #{$report_root}/#{ENV['REPORT_PATH']} "
    FileUtils.mkdir_p "#{$report_root}/#{ENV['REPORT_PATH']}"
  end

  task :init_report do
    puts '=====:: Preparing Flip ::====='
    report_root = File.absolute_path('./report')
    ENV['REPORT_PATH'] = Time.now.strftime('%F_%H-%M-%S.%N')
    puts "=====:: about to create report #{ENV['REPORT_PATH']} "
    FileUtils.mkdir_p "#{report_root}/#{ENV['REPORT_PATH']}"
  end

  task :setup do
    # exec 'bundle install'
    ENV['TZ'] = 'Asia/Jakarta'
    ENV['RUBYOPT'] = '-W0'
    ENV['BROWSER'] = 'chrome_headless'
  end

  task :merge_report do
    output_report = "report/output/test_report_#{ENV['REPORT_PATH']}"
    puts "=====:: Merging report #{output_report}"
    FileUtils.mkdir_p 'report/output'
    options = {
      input_path: "report/#{ENV['REPORT_PATH']}",
      report_path: output_report,
      report_types: %w[retry html json],
      report_title: 'Teletubbies Report',
      color: 'blue',
      additional_info: { 'Browser' => 'Chrome', 'Environment' => ENV['BASE_URL'].to_s, 'Generated report' => Time.now, 'Tags' => ENV['t'] }
    }
    ReportBuilder.build_report options
    puts "After rerun @status in merging report is #{@status}"
  end

  task :run do
    # Before all
    Rake::Task['flip:clear_report'].execute

    # Test 1
    Rake::Task['flip:init_report'].execute
    system 'rake flip:test t=@login'
  end

  task :rerun do
    @temp_status = 1
    puts Dir['.']
    Dir["report/#{ENV['REPORT_PATH']}/*.txt"].each do |f|
      next if File.size(f).zero?

      puts "=====:: will rerun file #{f}"
      FileUtils.cp_r f, './rerun.txt'
      opening_file = open './rerun.txt'
      content_rerun = opening_file.read
      puts "=====:: failed scenarios #{content_rerun}"
      opening_file.close
      file_rerun = f.split('/').last.tr('.txt', '')
      status_rerun = system "bundle exec cucumber @rerun.txt --format pretty --format html --out report/#{ENV['REPORT_PATH']}/features_report_rerun#{file_rerun}.html --format json --out=report/#{ENV['REPORT_PATH']}/cucumber_rerun#{file_rerun}.json"
      @temp_status -= 1 unless status_rerun
    end
    # see :merge_report for exit @status
    puts "Final status #{@temp_status} : #{@temp_status.positive?}"
    @status = true if @temp_status.positive?
  end

  task :parallel_rerun do
    @temp_status = 0
    status_rerun = true
    running_file = []
    puts Dir["report/#{ENV['REPORT_PATH']}"]
    rerun_exception = %w[
      report_general_ledger_mc
      report_general_ledger_non_mc
      report_fifo_inventory_valuation_mc
      report_warehouse_stock_quantity_non_mc
      closing_the_books
      report_sales_order_completion
      report_balance_sheet_non_mc
      report_executive_summary
      report_warehouse_stock_quantity
    ]
    file_contents = {}
    Dir["report/#{ENV['REPORT_PATH']}/*.txt"].each do |file_name|
      content = File.readlines("#{Dir.pwd}/#{file_name}", chomp:true)
      if file_contents.key?(content)
        puts "File '#{file_name}' memiliki konten yang sama dengan file '#{file_contents[content]}'"
      else
        file_contents[content] = file_name
      end
    end  
    puts "#{Dir.glob(File.join('*', '**', "rerun.txt"), File::FNM_DOTMATCH)}"
    Dir["report/#{ENV['REPORT_PATH']}/*.txt"].each do |file_name|       
      begin
          running_file = if !File.size(file_name).zero?
                          final_data = []
                          File.readlines("#{Dir.pwd}/#{file_name}", chomp:true).each do |line|
                            temp_data = line.strip.split(":")
                            temp_data.each_with_index { |x, index| temp_data[index] = x.gsub(/[^0-9]/, '') unless index == 0}
                            final_data << temp_data.join(':')
                          end
                          final_data
                        else
                          ['-t @nothing-to-test']
                        end
          puts "=====:: will rerun file #{file_name}"
          puts "=====:: will rerun scenarios #{running_file}"
          threads = []
          results = []
          file_rerun = file_name.split('/').last.tr('.txt', '')
          ENV['RERUN_FILE'] = file_rerun
          running_file.each_with_index do |data_file, number|
            ENV['TEST_ENV_NUMBER'] = (number +1).to_s
            puts "ENV NUMBER #{ENV['TEST_ENV_NUMBER']}"
            threads << Thread.new do
              if data_file.is_a? (Array)
                puts "data is array #{data_file[number]}"
                status_rerun = system "bundle exec cucumber -p rerun #{data_file[number]}"
              else
                puts "data is not array #{data_file}"
                status_rerun = system "bundle exec cucumber -p rerun #{data_file}"
              end
            end
            sleep 1 until File.exist?("#{$report_root}/#{ENV['REPORT_PATH']}/cucumber_#{ENV['RERUN_FILE']}_#{ENV['TEST_ENV_NUMBER']}.json")
          end
          results << threads.map(&:value)
          @temp_status -= 1 unless status_rerun
      rescue Exception => e
        p e
      end
    end
    # see :merge_report for exit @status
    puts "Final status #{@temp_status}"
    @status = true if @temp_status.positive?
  end

  task :police do
    sh 'bundle exec cuke_sniffer --out html report/cuke_sniffer.html'
  end

  task :install do
    # this task needed in docker to update gems file
    # Gemfile located outside directory of Rakefile, so we add relative path
    puts '=====:: Installing Gems '
    system 'pwd && bundle install --path ../Gemfile'
  end

  task :clear_report_automation_json do
    @report_automation_json_root ||= File.absolute_path('./report/report_dashboard')
    puts "=====:: Delete report automation folder #{@report_automation_json_root}"
    FileUtils.rm_rf(@report_automation_json_root, secure: true)
    FileUtils.mkdir_p @report_automation_json_root
  end

  task :merge_report_automation_json do
    # Create file output for report dashboard
    report_automation_json_ouput = File.absolute_path('./report/report_dashboard/output')
    report_dashboard_out_json_file = report_automation_json_ouput + "/report_dashboard_output_#{ENV['REPORT_PATH']}.json"
    puts "=====:: Merging report dashboard #{report_automation_json_ouput}"
    # File.delete(report_automation_json_root)
    FileUtils.mkdir_p report_automation_json_ouput
    File.new(report_dashboard_out_json_file, 'w+')
    json_format = {
      'automation_product' => 'KP',
      'automation_type' => 'WEB',
      'automation_total_passed' => 0,
      'automation_total_failed' => 0,
      'running_type' => ENV['JENKINS_JOB_NAME'],
      'test_run_id' => ENV['RUN_ID'],
      'test_run_results' => []
    }
    File.open(report_dashboard_out_json_file, 'w') { |f| f.write(JSON.pretty_generate(json_format)) }

    # Update file output for report dashboard test run results base on report_automation.json
    Dir[@report_automation_json_root + '/*.json'].each do |file_name|
      array = JSON.parse(File.read(file_name))
      array['test_run_results'].each { |data| json_format['test_run_results'] << data }
    end

    File.open(report_dashboard_out_json_file, 'w') { |f| f.write(JSON.pretty_generate(json_format)) }

    # Start calculating passed and failed
    hash = JSON.parse(File.read(report_dashboard_out_json_file))
    calculate = hash['test_run_results'].each_with_object(Hash.new { |x, k| x[k] = '0' }) { |x, res| res[x['status']].succ! }
    array = JSON.parse(File.read(report_dashboard_out_json_file))
    array['automation_total_passed'] = calculate['passed'].to_i
    array['automation_total_failed'] = calculate['failed'].to_i

    File.open(report_dashboard_out_json_file, 'w') { |f| f.write(JSON.pretty_generate(array)) }
    hash = JSON.parse(File.read(report_dashboard_out_json_file))
    pp hash
    exit(1) unless @status
  end

  task :copy_report do
    next if ENV['BITBUCKET'].nil? || ENV['BITBUCKET'] == 'false'

    FileUtils.mkdir_p "report/screenshots"
    ['', '/screenshots'].each do |path|
      Dir["report/#{ENV['REPORT_PATH']}#{path}/*.*"].each do |filename|
        next if File.directory?(filename)
    
        name = File.basename(filename)
        dest_folder = "report#{path}/#{name}"
        FileUtils.mv(filename, dest_folder)
      end
    end
  end

  task parallel_run: %i[clear_report init_report parallel rerun merge_report copy_report]
  task parallel_run_with_run_id: %i[clear_report init_report_run_id parallel_run_id parallel_rerun merge_report copy_report]
end
