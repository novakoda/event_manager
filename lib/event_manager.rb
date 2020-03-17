require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "date"

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_numbers(phone)
    phone.gsub!(/[^\d]/, "")
    if phone.length < 10 || phone.length > 11
        "Bad Number"
    else
        phone.rjust(11, "0")[1..10]
    end
end

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
    
    begin
        civic_info.representative_info_by_address(
            address: zip,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
        "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
    end
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir("output") unless Dir.exists? "output"

    filename = "output/thanks_#{id}.html"

    File.open(filename,'w') do |file| 
        file.puts form_letter
    end
end

def best_hours(date)
    hour = date.strftime("%H")
    if @hours_count[hour] == nil
        @hours_count[hour] = 1 
    else
        @hours_count[hour] += 1
    end 
end

def best_days(date)
    day = date.strftime("%a")
    if @days_count[day] == nil
        @days_count[day] = 1 
    else
        @days_count[day] += 1
    end 
end

puts "EventManager initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

@hours_count = Hash.new 
@days_count = Hash.new

contents.each do |row|
    id = row[0]
    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])

    phone = clean_phone_numbers(row[:homephone])

    date = DateTime.strptime(row[:regdate], '%m/%d/%y %H:%M')
    
    best_hours(date)
    best_days(date)

    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)
    
    save_thank_you_letter(id, form_letter)
    puts "#{name} #{phone} #{date}"
end

puts ""
puts "-----------------"
puts "Best times"
puts ""

@hours_count.sort_by{|k, v| -v}.each do |hour, count|
    puts "#{count} registered at #{hour}:00"
end

puts ""
puts "-----------------"
puts "Best Days"
puts ""
@days_count.sort_by{|k, v| -v}.each do |day, count|
    puts "#{count} registered on #{day}"
end