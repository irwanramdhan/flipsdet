Given('the user is on user inform page') do
  @pages.user_info_page.load
end

When ('the user leave all the field blank and insert an {string}') do |invalid_value|
  @pages.user_info_page.submit_btn.click
  page.has_text?('First name is required') #to wait until the error message appears
  expect(@pages.user_info_page.error_message[0]).to have_text 'First name is required'
  expect(@pages.user_info_page.error_message[1]).to have_text 'Middle name is required'
  expect(@pages.user_info_page.error_message[2]).to have_text 'Last name is required'
  expect(@pages.user_info_page.error_message[3]).to have_text 'Email is required'
  expect(@pages.user_info_page.error_message[4]).to have_text 'Phone number is required'
  expect(@pages.user_info_page.error_message[5]).to have_text 'Date of birth is required'
  expect(@pages.user_info_page.error_message[6]).to have_text 'Province is required'
  expect(@pages.user_info_page.error_message[7]).to have_text 'City is required'
  @invalid_data = UserInfoRequirement.new.load_user_info(invalid_value)
  @pages.user_info_page.first_name.set @invalid_data['first_name']
  @pages.user_info_page.middle_name.set @invalid_data['middle_name']
  @pages.user_info_page.last_name.set @invalid_data['last_name']
  @pages.user_info_page.email.set @invalid_data['email']
  @pages.user_info_page.phone_number.set @invalid_data['phone_no']
  page.has_text?('Invalid email format') #to wait until the error message appears
  @pages.user_info_page.submit_btn.click
end

Then ('the system should prevent user to submit the form') do
  expect(@pages.user_info_page.error_message[0]).to have_text 'First name can only consists of letters'
  expect(@pages.user_info_page.error_message[1]).to have_text 'Middle name can only consists of letters'
  expect(@pages.user_info_page.error_message[2]).to have_text 'Last name can only consists of letters'
  expect(@pages.user_info_page.error_message[3]).to have_text 'Invalid email format'
  expect(@pages.user_info_page.error_message[4]).to have_text 'Phone number must be 10-12 digits'
end

When ('the user fill the field with {string} and submit form') do |valid_value|
  @valid_data = UserInfoRequirement.new.load_user_info(valid_value)
  @pages.user_info_page.open_title.click
  @pages.user_info_page.choose_title[1].click
  @pages.user_info_page.first_name.set Faker::Name.first_name
  @user_first_name = @pages.user_info_page.first_name.value
  @pages.user_info_page.middle_name.set Faker::Name.middle_name
  @user_middle_name = @pages.user_info_page.middle_name.value
  @pages.user_info_page.last_name.set Faker::Name.last_name
  @user_last_name = @pages.user_info_page.last_name.value
  @pages.user_info_page.email.set @valid_data['email']
  @pages.user_info_page.phone_number.set @valid_data['phone_no']
  @current_date = Date.today
  @pages.user_info_page.dob.set @current_date.strftime('%d/%m/%Y')
  @formatted_date = @current_date.strftime('%d %B %Y')
  @pages.user_info_page.gender.click
  @pages.user_info_page.province.click
  @pages.user_info_page.choose_province[1].click
  page.has_text?('Select a city') # to wait until the system return with the options
  @pages.user_info_page.city.click
  @pages.user_info_page.choose_city[1].click
  @pages.user_info_page.submit_btn.click
end

Then ('the system should successfully submitted the form') do
  page.has_selector?(:xpath, '//button[contains(text(),"Close")]')
  text = find('#modalContent').text.gsub(/\s+/, ' ') # removing line breaks
  expect(text).to eq("Hello, Mr. " + @user_first_name + ' ' + @user_middle_name + ' ' + @user_last_name + ". You are a Female that were born on " + @formatted_date + ", which means you are now 0 years and 0 days old. If someone want to contact you, they can call you at 12345678901 or through your email at irwanflip@mail.com. Or if you don't mind, they can also come to your house at Jakarta Barat, in DKI Jakarta province.")
  @pages.user_info_page.close_btn.click
end