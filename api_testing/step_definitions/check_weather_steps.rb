When('user try to check the weather') do
  response = ApiBaseHelper.post(@api_endpoint['checking_the_weather'])
  aggregate_failures('Verifying API response') do
    expect(response.code.to_i).to eql 200
  end
end

Then('system should return with the weather for the next 5 days') do
  response = ApiBaseHelper.get(@api_endpoint['checking_the_weather'])
  aggregate_failures('Verifying API response') do
    expect(response.code.to_i).to eql 200
    expect(response.body['city']['name'].eql?('Jakarta')).to be true
  end
end

