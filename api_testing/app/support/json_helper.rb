require 'yml_reader'
require 'json'
require 'data_magic'

module JsonHelper
  extend YmlReader
  extend DataMagic

  attr_reader :parent
  attr_accessor :yml_directory

  def initialize
    JsonHelper.yml_directory = "#{$root_directory.gsub('web_test', 'api_testing')}/data"
  end

  def self.data_for(key, additional = {})
    data = JsonHelper.yml[key]
    raise ArgumentError, "Undefined key #{key}" unless data

    unless additional.empty?
      additional.each_key do |add_key|
        if additional[add_key].respond_to? :to_ary
          additional[add_key].each_index do |index|
            data[data.keys[0]][add_key][index].merge! additional[add_key][index]
          end
        elsif data[data.keys[0]].respond_to?(:to_hash)
          data[data.keys[0]][add_key] = additional[add_key]
        else
          data[add_key] = additional[add_key]
        end
      end
    end
    prep_data(data)
  end

  def self.from_yml(filename)
    JsonHelper.load filename
  end

  class << self
    attr_accessor :yml

    def default_directory
      './data'
    end

    def add_translator(translator)
      translators << translator
    end

    def translators
      @translators ||= []
    end
  end
end
