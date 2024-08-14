class UserInfoRequirement
    include DataMagic
    DataMagic.load 'user_info.yml'
  
    def load_user_info(details)
      data_for "user_info/#{details}"
    end
  end
  