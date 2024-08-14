Before do |scenario|
  $feature = scenario.feature.name
  $scenario = scenario.name
  # @api_endpoint ||= DataMagic.load 'api_endpoint.yml'
  @api_endpoint ||= api_data_magic_load 'api_endpoint.yml'
  $base_url_api = ENV['BASE_URL_API']
  $step_list = []
  $count_step = 0
  # init_report_automation_json_file unless ENV['TEST_ENV_NUMBER'].nil?
  scenario.test_steps.each { |x| $step_list << x.text unless x.text.include? 'hook' }
  p "Will run scenario #{$scenario} from feature #{$feature}"
end

AfterStep do
  $count_step += 1 unless Dir.pwd.include? 'web'
  $current_step = $step_list[$count_step]
end

After do |scenario|
  scenario_id = scenario.respond_to?('scenario_outline') ? scenario.scenario_outline.cell_values.first : scenario.name.split('-')[0].strip
  scenario_name_updated = if scenario.respond_to?('scenario_outline')
                            scenario.scenario_outline.name.split(', Examples')[0]
                          elsif scenario.name.match(/\d+-/).present?
                            scenario.name.split('-')[1]
                          else
                            scenario.name
                          end

  if scenario.failed?
    p "FAILED in scenario #{scenario.name}"
    p "Getting screen shoot in session #{Capybara.session_name}"

    # check the current url that got issue, whether from WEB it self or combination WEB-API
    # if there scenario WEB-API and get error in the API step return value what endpoint got issue
    url = $response.present? ? $response.uri.to_s : 'send request blocked in failed models/step_definitions'

    if ENV['SEND_NOTIF_FAIL'] == 'true' && ENV['application_type'] == 'api_testing'
      puts 'send notif failed api'
      notif_details = { feature: $feature, scenario: scenario_name_updated, group_test_number: ENV['GROUP_INDEX'], apikey_gchat: select_gchat_notif(ENV['GCHAT_NOTIF']),
                        error_message: scenario.exception.message, workspace_url: ENV['WS_URL'], url: url, error_line: extract_error_line(scenario.exception.backtrace),
                        status: check_flaky_or_env_issue_api($response), jenkins_job: ENV['JENKINS_JOB_NAME'], build_number: ENV['BUILD_NUMBER'],
                        automation_type: ENV['application_type'], error_source: check_error_source(scenario.exception.backtrace), pod_template: ENV['POD_TEMPLATE'] || nil }.with_indifferent_access
      puts notif_details
      send_notif_fail(notif_details)
    end
    $scenario_status = scenario.status.to_s
  end
  puts scenario_id
  puts scenario.status
end
