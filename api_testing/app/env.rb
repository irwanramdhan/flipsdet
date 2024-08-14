# rubocop:disable Style/MixinUsage
require 'dotenv/load'
require 'capybara/cucumber'
require 'capybara/rspec'
require 'rspec/expectations'
require 'pry'
require 'byebug'
# require 'pry-byebug'
require 'os'
require 'imatcher'
require 'data_magic'
require 'yaml'
require 'chilkat'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/core_ext/hash/indifferent_access'
require 'date'
require 'roo'
require 'require_all'
require 'resolv-replace'
require 'open-uri'
require 'pdf/reader'
require 'json'
require_rel './support'
require_rel './models'

include RSpec::Matchers
include DataMagic

$root_directory = Dir.pwd
$download_path = "#{$root_directory}/data/downloads/"

# DataMagic.yml_directory = "#{$root_directory}/app/config"
# JsonHelper.yml_directory = "#{$root_directory.gsub('web', 'api_testing')}/data"

Dir["#{File.join(File.dirname(__FILE__), './models')}/*.rb"].each { |file_name| include self.class.const_get(File.basename(file_name).gsub('.rb', '').split('_').map(&:capitalize).join) }
Dir["#{File.join(File.dirname(__FILE__), './support')}/*.rb"].each { |file_name| include self.class.const_get(File.basename(file_name).gsub('.rb', '').split('_').map(&:capitalize).join) }
