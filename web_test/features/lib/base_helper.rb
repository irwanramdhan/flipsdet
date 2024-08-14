module BaseHelper
    def waiting_for_page_ready
      sleep 1
      waiting_decouple_page_done if page_revamp
      wait_for_page_done
    end
  
    def wait_for_ajax
      max_time = Capybara::Helpers.monotonic_time + Capybara.default_max_wait_time
  
      while Capybara::Helpers.monotonic_time < max_time
        finished = finished_all_ajax_requests?
        finished ? break : sleep(0.1)
      end
      raise 'wait_for_ajax timeout' unless finished
    end
  
    def finished_all_ajax_requests?
      page.evaluate_script(<<~EOS
        ((typeof window.jQuery === 'undefined')
         || (typeof window.jQuery.active === 'undefined')
         || (window.jQuery.active === 0))
        && ((typeof window.injectedJQueryFromNode === 'undefined')
         || (typeof window.injectedJQueryFromNode.active === 'undefined')
         || (window.injectedJQueryFromNode.active === 0))
        && ((typeof window.httpClients === 'undefined')
         || (window.httpClients.every(function (client) { return (client.activeRequestCount === 0); })))
      EOS
                          )
    end
  
    def short_wait(time_out = SHORT_TIMEOUT)
      Selenium::WebDriver::Wait.new(timeout: time_out, interval: 0.2, ignore: Selenium::WebDriver::Error::NoSuchElementError)
    end
  
    def generate_code(number)
      charset = Array('A'..'Z') + Array('a'..'z')
      Array.new(number) { charset.sample }.join
    end
  
    def get_shadow_dom(host, element)
      root = page.driver.browser.find_element(:css, host)
      shadow_root = page.execute_script('return arguments[0].shadowRoot', root)
      shadow_root.find_element(:css, element)
    end
  
    def shadow_dom_exist?(host, element)
      root = page.driver.browser.find_element(:css, host)
      shadow_root = page.execute_script('return arguments[0].shadowRoot', root)
      shadow_root.find_element(:css, element)
      true
    rescue StandardError
      puts 'element not found'
      false
    end
  
    def generate_random_eight_digits
      Faker::Number.number(digits: 4).to_s + Time.now.strftime('%m') + Time.now.strftime('%d')
    end
  
    def element_displayed?(locator, timeout = 3)
      expected = locator =~ /^(xpath|css)/
      if expected.nil?
        locator.visible?
      else
        type_of_element = element_mapper(locator)
        type_of_element[:element_type].eql?('xpath') ? find_xpath(type_of_element[:element_locator], timeout).visible? : find_css(type_of_element[:element_locator], timeout).visible?
      end
    rescue Exception
      false
    end
  
    def element_mapper(element)
      element_map = element.partition(':')
      type = element_map.first
      locator = element_map.last
      { element_type: type, element_locator: locator }
    end
  
    def find_xpath(locator, timeout = 3)
      short_wait.until { find(:xpath, locator, wait: timeout) }
    end
  
    def find_css(locator, timeout = 3)
      short_wait.until { find(:css, locator, wait: timeout) }
    end
  
    def init_report_automation_json_file
      @report_automation_json_root ||= File.absolute_path('./report/report_dashboard')
      @report_automation_json_file ||= File.absolute_path(@report_automation_json_root + "/report_automation#{ENV['TEST_ENV_NUMBER']}.json")
      return if File.file? @report_automation_json_file
  
      puts "=====:: Create report automation file #{@report_automation_json_file}"
      File.new(@report_automation_json_file, 'w+')
      json_format = { 'test_run_results' => [] }
      File.open(@report_automation_json_file, 'w') { |f| f.write(JSON.pretty_generate(json_format)) } if File.read(@report_automation_json_file).empty?
    end
  
    def update_report_automation_json(case_ids, status)
      array = JSON.parse(File.read(@report_automation_json_file)) unless File.read(@report_automation_json_file).empty?
      case_ids = case_ids.split(',')
      case_ids.each do |x|
        c_index = array['test_run_results'].index { |h| h['case_id'] == x }
        array['test_run_results'].delete_at(c_index) unless c_index.nil?
        hash = { 'case_id' => x, 'status' => status }
        array['test_run_results'] << hash
      end
  
      File.open(@report_automation_json_file, 'w') { |f| f.write(JSON.pretty_generate(array)) }
    end
  
    def generate_random_number_stringtype(size)
      Faker::Number.number(digits: size).to_s
    end
  
    def choose_option_dropdown(dropdown_css, option_text)
      # example: choose_option_dropdown('.o-list-container__filter-tax-type select.e-input', 'PPh 21')
      find(dropdown_css).find(:xpath, "//option[contains(text(),'#{option_text}')]").select_option
    end
  
    def read_pdf(file)
      io     = File.open(file)
      reader = PDF::Reader.new(io)
      reader.pages
    end
  
    def clear_downloaded_location
      FileUtils.rm_f(downloaded_location)
    end
  
    def downloaded_location
      Dir[File.absolute_path('./features/data/downloaded/*')]
    end
  
    # def update_import_data_to_empty_or_emoji(file_name, selected_header, selected_row, type)
    #   if file_name.include? 'csv'
    #     csv = Chilkat::CkCsv.new
    #     csv.put_HasColumnNames(true)
    #     success = csv.LoadFile('./features/data/files/' + file_name)
    #     if success != true
    #       print csv.lastErrorText + "\n"
    #       exit
    #     end
  
    #     # set selected header and row to empty or emoji
    #     @current_value = csv.getCellByName(selected_row, selected_header)
    #     csv.SetCellByName(selected_row, selected_header, '') if type.eql? 'empty'
    #     csv.SetCellByName(selected_row, selected_header, @current_value.to_s + '🎈') if type.eql? 'emoji'
  
    #     success = csv.SaveFile('./features/data/files/' + file_name)
    #     print csv.lastErrorText + "\n" if success != true
  
    #     file_name
    #   elsif file_name.include? 'xlsx'
    #     file = RubyXL::Parser.parse('./features/data/files/' + file_name)
    #     current_sheets = file.worksheets[0] # get the first sheet
    #     header_index = select_header_index_for_excel(file_name, selected_header)
    #     @current_value = current_sheets[selected_row][header_index].value
  
    #     (1...current_sheets.sheet_data.rows.size).each do |k|
    #       if type.eql? 'emoji'
    #         current_sheets[k][header_index].change_contents(@current_value.to_s + '🎈')
    #       else
    #         current_sheets[k][header_index].change_contents(nil)
    #       end
    #     end
  
    #     write_sheets_file(file, file_name)
    #   else
    #     temp_file = 'temp_' + file_name
    #     file = Spreadsheet.open('./features/data/files/' + file_name)
    #     current_sheets = file.worksheet 0
    #     header_index = select_header_index_for_excel(file_name, selected_header)
  
    #     @current_value = []
    #     (1...current_sheets.rows.size).each do |k|
    #       @current_value << current_sheets[k, header_index]
    #       current_sheets[k, header_index] = if type.eql? 'empty'
    #                                           ''
    #                                         elsif type.eql? 'emoji'
    #                                           @current_value[k - 1].to_s + '🎈'
    #                                         end
    #     end
  
    #     write_sheets_file(file, temp_file)
    #   end
    # end
  
    def waiting_decouple_page_done
      retries = 0
      begin
        short_wait.until { page.has_no_css?('#loader') }
        short_wait.until { page.has_no_css?('div[data-pixel-component="MpSpinner"]') }
      rescue Exception => e
        p e.message
        retry if (retries += 1) < 5
        raise "wait for decouple page loaded timeout #{retries} times" if retries == 5
      end
    end
  
    def page_revamp
      current_url.include? '/v'
    end
  end
  