module DateTimeHelper
  def convert_date(date_string)
    match_data = date_string.match(/(\+|-)(\d).(days|months|years)/)
    if !match_data.nil?
      if date_string.include? 'days'
        if match_data[1] == '+'
          Time.new.to_date.next_day(match_data[2].to_i).strftime('%Y-%m-%d')
        else
          Time.new.to_date.prev_day(match_data[2].to_i).strftime('%Y-%m-%d')
        end
      elsif date_string.include? 'months'
        if match_data[1] == '+'
          Time.new.to_date.next_month(match_data[2].to_i).strftime('%Y-%m-%d')
        else
          Time.new.to_date.prev_month(match_data[2].to_i).strftime('%Y-%m-%d')
        end
      elsif date_string.include? 'years'
        if match_data[1] == '+'
          Time.new.to_date.next_year(match_data[2].to_i).strftime('%Y-%m-%d')
        else
          Time.new.to_date.prev_year(match_data[2].to_i).strftime('%Y-%m-%d')
        end
      else
        raise ArgumentError, "Undefined modifier: #{match_data[3]}"
      end
    else
      case date_string
      when 'yesterday'
        Time.new.to_date.prev_day.strftime('%Y-%m-%d')
      when 'today'
        Time.new.to_date.strftime('%Y-%m-%d')
      when 'tomorrow'
        Time.new.to_date.next_day.strftime('%Y-%m-%d')
      # condition to get period date
      when 'weekly'
        Date.today.at_beginning_of_week.strftime('%Y-%m-%d')
      when 'monthly'
        Date.today.at_beginning_of_month.strftime('%Y-%m-%d')
      when 'yearly'
        Date.today.at_beginning_of_year.strftime('%Y-%m-%d')
      else
        date_string
      end
    end
  end
end
