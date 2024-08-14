require 'capybara/cucumber'
require 'capybara-screenshot/cucumber'
require 'capybara/rspec'
require 'capybara'
require 'selenium-webdriver'
require 'site_prism'
require 'dotenv'
require 'rspec/expectations'
require 'data_magic'
require 'pry'
require 'faker'
require 'active_support/all'
require 'date'
require 'byebug'
require 'data_magic'
require 'yaml'
# require 'simple_xlsx_reader'
require 'roo'
require 'roo-xls'
# require 'rubyXL'
# require 'rubyXL/convenience_methods'
# require 'spreadsheet'
require_relative '../lib/base_helper'
require 'byebug'
# require 'pdf-reader'
# require_relative '../lib/converter_csv_to_excel'

include RSpec::Matchers
include BaseHelper
include DataMagic
# include ConverterCsvToExcel

Dotenv.load
browser = 'chrome'.to_sym
base_url = ENV['BASE_URL'] || 'https://flip-sample-form.onrender.com/'
ENV['BASE_URL_API'] = ENV['BASE_URL'] + '/main/api/'
wait_time = 120
SHORT_TIMEOUT = 30
DEFAULT_TIMEOUT = 60
$failed_scenario_no = 0
DataMagic.yml_directory = './features/config/data/staging'
browser_options = Selenium::WebDriver::Chrome::Options.new
browser_profile = Selenium::WebDriver::Chrome::Profile.new
# Selenium::WebDriver::Chrome::Service.driver_path = '/usr/local/bin/chromedriver'

if ENV['BROWSER'].eql? 'chrome_headless'
  # browser_options.headless!
  browser_options.add_argument('--no-sandbox')
  browser_options.add_argument('--disable-gpu')
  browser_options.add_argument('--disable-dev-shm-usage')
  browser_options.add_argument('--enable-features=NetworkService,NetworkServiceInProcess')
  browser_options.add_argument('--headless=new')
end

browser_options.add_preference('download.default_directory', File.absolute_path('./features/data/downloaded'))
browser_options.add_preference(:download, default_directory: File.absolute_path('./features/data/downloaded'))
browser_options.add_preference('plugins.always_open_pdf_externally', true)
browser_options.add_preference(:plugins, always_open_pdf_externally: true)
# browser_options.add_preference('profile.geolocation.default_content_setting', 1)

# "profile.default_content_settings.geolocation", 2
# browser_profile['geolocation.default_content_setting'] = 2

Capybara.register_driver :chrome do |app|
  browser_options.add_argument('--start-maximized')
  client = Selenium::WebDriver::Remote::Http::Default.new
  client.open_timeout = wait_time
  client.read_timeout = wait_time

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: browser_options,
    http_client: client
    # profile: browser_profile
  )
end

# Capybara.register_driver :chrome_mobile do |app|
#   browser_options.add_argument('--user-agent=Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.114 Mobile Safari/537.36')
#   profile = Selenium::WebDriver::Chrome::Profile.new
#   client = Selenium::WebDriver::Remote::Http::Default.new
#   client.open_timeout = wait_time
#   client.read_timeout = wait_time
#
#   Capybara::Selenium::Driver.new(
#       app,
#       browser: :chrome,
#       options: browser_options,
#       http_client: client,
#       profile: profile
#   )
# end

# clear report files
@report_root = if ENV['JENKINS_JOB_NAME'].nil?
                File.absolute_path('./report')
              else
                File.absolute_path("./report/#{ENV['JENKINS_JOB_NAME']}")
              end

$report_file_time ||= if File.exist?(@report_root)
                        File.ctime(@report_root).strftime('%F%H%M%S')
                      else
                        0.to_s
                      end

ENV['JENKINS_START_TIME'] = Time.now.strftime('%F%H%M%S') if ENV['JENKINS_START_TIME'].nil? || ENV['JENKINS_START_TIME'].empty?

puts "jenkins job name #{ENV['JENKINS_JOB_NAME']}"
puts "job start at #{ENV['JENKINS_START_TIME']}"
puts "folder report at #{$report_file_time}"

if ENV['REPORT_PATH'].nil?
  # remove report directory when run localy,
  # ENV report will initiate from rakefile, or below this
  if ENV['JENKINS_START_TIME'] > $report_file_time
    puts ' ========Deleting old reports ang logs========='
    FileUtils.rm_rf(@report_root, secure: true)
  end
end

ENV['REPORT_PATH'] ||= Time.now.strftime('%F_%H-%M-%S')
path = "#{@report_root}/#{ENV['REPORT_PATH']}"
FileUtils.mkdir_p path

Capybara::Screenshot.register_driver(browser) do |driver, path|
  delete_date = path.split('_').last
  path = path.gsub('_' + delete_date, '.png')
  driver.browser.save_screenshot path
end

if ENV['CI'] == 'true'
  p "about to run on #{browser} remotes #{base_url}"
  Capybara.default_driver = :selenium
else
  p "about to run on #{browser} to #{base_url}"
  Capybara.default_driver = browser
end

Capybara::Screenshot.autosave_on_failure = true
Capybara::Screenshot.prune_strategy = { keep: 50 }
Capybara::Screenshot.append_timestamp = true
Capybara::Screenshot.webkit_options = {
  width: 1366,
  height: 768
}
Faker::Config.locale = 'id'
Capybara.save_path = "#{path}/screenshots"

# $root_directory_api = Dir.pwd.gsub('web', 'api_testing')
# require_relative "#{$root_directory_api}/app/env.rb"
# require_relative "#{$root_directory_api}/app/hook.rb"
# Dir["#{$root_directory_api}/step_definitions/*.rb"].each { |file| require_relative file }
# Dir["#{$root_directory_api}/app/support/*.rb"].each { |file| require_relative file }
# Dir["#{$root_directory_api}/app/models/*.rb"].each { |file| require_relative file }
