class UserInfoPage < SitePrism::Page
    set_url ''
  
    element :open_title, '#title'
    elements :choose_title, '#title option'
    element :first_name, '#firstName'
    element :middle_name, '#middleName'
    element :last_name, '#lastName'
    element :email, '#email'
    element :phone_number, '#phone'
    element :dob, '#dob'
    element :gender, 'span.slider.round'
    element :province, '#province'
    elements :choose_province, '#province option'
    element :city, '#city'
    elements :choose_city, '#city option'
    element :submit_btn, :xpath, '//button[contains(text(),"Submit")]'
    elements :error_message, '.text-sm.text-green-500'
    element :user_info_modal, '#modalContent'
    element :close_btn, :xpath, '//button[contains(text(),"Close")]'
  end
  