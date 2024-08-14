Before do |scenario|
  # visit ENV['BASE_URL'] + '/logout' unless scenario.source_tag_names.include? '@continue'
  Capybara.app_host = ENV['BASE_URL']
  Capybara.default_max_wait_time = 5
  Capybara.javascript_driver = :chrome
  DataMagic.yml_directory = './features/config/data/staging'
  # if scenario.source_tag_names.include? '@mobile'
  #   Capybara.default_driver = :chrome_mobile
  #   page.driver.browser.manage.window.resize_to(414, 736)
  # else
  #   Capybara.default_driver = :chrome
  #   page.driver.browser.manage.window.resize_to(1440, 877)
  # end
  @driver = page.driver
  @pages = Pages.new
  @count_step = 0
  Selenium::WebDriver.logger.level = :debug
  Selenium::WebDriver.logger.output = 'selenium.log'
  page.driver.browser.manage.window.resize_to(1440, 877)
  @tags = scenario.source_tag_names
  if $feature_name.nil?
    $feature_name = scenario.feature.name
  elsif $feature_name != scenario.feature.name
    $feature_name = scenario.feature.name
    visit "#{ENV['BASE_URL']}/logout"
  end
  @scenario = scenario
  @scenario_name = scenario.name
  copy_screenshot
  # $check_point << $step_list[1]
  # $user_lists << parse_user_detail($step_list[0])
  # init_report_automation_json_file unless ENV['TEST_ENV_NUMBER'].nil?
end

AfterStep do
  @count_step += 1
  # $current_step = $step_list[@count_step]
  DataMagic.yml_directory = './features/config/data/staging'
end

After do |scenario|
  # if ENV['TESTRAIL_RUN_UPDATE'].eql? 'true'
  #   statuses = {
  #     passed: 1,
  #     failed: 5,
  #     pending: 6
  #   }
  #
  #   results = []
  #   case_ids = case_ids(scenario)
  #   case_ids.delete(0)
  #
  #   if case_ids.count > 0
  #     case_ids.each { |case_id| results << set_result(case_id, statuses[scenario.status]) }
  #     add_results_for_cases({ results: results })
  #   end
  # end
  scenario_id = if scenario.respond_to?('scenario_outline')
                  scenario.scenario_outline.cell_values.first
                else
                  scenario.name.split('-')[0].strip
                end

  if scenario.failed?
    $failed_scenario_no += 1
    scenario_name_updated = if scenario.respond_to?('scenario_outline')
                              scenario.scenario_outline.name.split(', Examples')[0]
                            elsif scenario.name.match(/\d+-/).present?
                              scenario.name.split('-')[1]
                            else
                              scenario.name
                            end

    p "FAILED in scenario #{scenario.name}"
    p "Getting screen shoot in session #{Capybara.session_name}"

    ss_file = "screenshot_#{scenario_name_updated.gsub(' ', '_')}_#{Faker::Number.number(digits: 10)}"

    Capybara::Screenshot.register_filename_prefix_formatter(:cucumber) do
      ss_file
    end

    # check the current url that got issue, whether from WEB it self or combination WEB-API
    # if there scenario WEB-API and get error in the API step return value what endpoint got issue
    error_url = if check_error_source(scenario.exception.backtrace) == 'api_testing' && $response.present?
                  $response.uri.to_s
                elsif check_error_source(scenario.exception.backtrace) == 'web'
                  current_url
                else
                  'No return/undefined URL, an error occured in step definitions / model code'
                end
    
    if ENV['SEND_NOTIF_FAIL'] == 'true'
      puts 'send notif failed web'
      
      notif_details = { feature: $feature, scenario: scenario_name_updated, group_test_number: ENV['GROUP_INDEX'], apikey_gchat: select_gchat_notif(ENV['GCHAT_NOTIF']),
                        error_message: scenario.exception.message, url: error_url, error_line: extract_error_line(scenario.exception.backtrace), workspace_url: ENV['WS_URL'],
                        status: check_flaky_or_env_issue_web, jenkins_job: ENV['JENKINS_JOB_NAME'], build_number: ENV['BUILD_NUMBER'], automation_type: ENV['application_type'],
                        report_dir: ENV['REPORT_PATH'], ss_file: ss_file, error_source: check_error_source(scenario.exception.backtrace), pod_template: ENV['POD_TEMPLATE'] || nil }.with_indifferent_access
      puts notif_details
      send_notif_fail(notif_details)
    end
    $scenario_status = scenario.status.to_s
  end 

  close_another_browser_tabs if page.driver.browser.window_handles.size > 1
  Capybara.current_session.instance_variable_set(:@touched, false)
  # if ENV['TESTRAIL_RUN_UPDATE'].eql? 'true'
    # test_rail_integration(ENV['TESTRAIL_RUN'], scenario_id, scenario.status.to_s) unless ENV['TESTRAIL_RUN'].empty? || ENV['TESTRAIL_RUN'].nil?
  # end

  puts scenario_id
  puts scenario.status.to_s
  # update_report_automation_json(scenario_id, scenario.status.to_s) unless ENV['TEST_ENV_NUMBER'].nil?
end

def case_ids(scenario)
  case_ids = scenario.outline? ? scenario.scenario_outline.cell_values : scenario.name.split('-')
  case_ids.first.split(',').map(&:to_i)
end

def set_result(case_id, status_id)
  {
    case_id: case_id,
    comment: 'from automation',
    status_id: status_id
  }
end

def add_results_for_cases(params)
  client = TestRail::APIClient.new(ENV['TESTRAIL_API_CLIENT'])
  client.user = ENV['TESTRAIL_USER']
  client.password = ENV['TESTRAIL_PASSWORD']
  client.send_post("add_results_for_cases/#{ENV['TESTRAIL_RUN']}", params)
end

def close_another_browser_tabs
  while page.driver.browser.window_handles.size > 1
    switch_to_window(windows.last)
    page.driver.browser.close
  end
  switch_to_window(windows.first)
end

def copy_screenshot
  # copy screenshot resources in implementation jenkins pod template, because you can't mounting dir directly yet
  return unless $failed_scenario_no >= 1 && $scenario_status == 'failed' && ENV['POD_TEMPLATE'] && ENV['SEND_NOTIF_FAIL'] == 'true'

  p "copy screenshot in #{ENV['JENKINS_WORKSPACE']}"
  system "ls -la /app/web/report/#{ENV['JENKINS_JOB_NAME']}/#{ENV['REPORT_PATH']}/screenshots/"
  system "cp -r /app/web/report/#{ENV['JENKINS_JOB_NAME']}/#{ENV['REPORT_PATH']}/screenshots/* #{ENV['JENKINS_WORKSPACE']}/screenshot#{ENV['GROUP_INDEX']}"
end