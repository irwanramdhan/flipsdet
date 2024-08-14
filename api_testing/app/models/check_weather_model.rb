module CheckWeatherModel
  def self.load
    JsonHelper.from_yml 'check_weather.yml'
  end
end
