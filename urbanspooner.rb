require 'rubygems'
require 'mechanize'

FIRST_NAME = 'FIRST_NAME'
LAST_NAME = 'LAST_NAME'
PHONE = 'PHONE'
EMAIL = 'EMAIL'

PARTY_SIZE = 2
SCHEDULE_RANGE = { :start_time => '19:00', :end_time => '20:30' }

def start_url(restaurant=2086)
	return "http://rez.urbanspoon.com/reservation/start/#{restaurant}"
end

def to_minutes(time)
	hour, minutes = time.split(':')
	raise "Malformed time: #{time}. Should be in the HH:MM format." if hour.nil? || minutes.nil?
	return (hour.to_i * 60) + minutes.to_i
end

url = start_url()
agent = Mechanize.new { |agent|
  agent.user_agent_alias = 'Mac Safari'
}

# Get the start page
start_page = agent.get(url)

# Bail if there are no reservations
exit if start_page.forms.count != 1

# Fill in the details for the reservation
start_form = start_page.forms.first
start_form.size = PARTY_SIZE

# Verify if the available times are in the allowed range
available_times = start_form.field_with(:name => 'seating_time').options

possible_times = available_times.select do |time|
	(to_minutes(SCHEDULE_RANGE[:start_time])..to_minutes(SCHEDULE_RANGE[:end_time])).member?(time.value.to_i)
end

# Select the first of the possible times for the reservation
start_form.seating_time = possible_times.first

# Submit the details and get back the contact form
contact_info_page = start_form.submit

# Check for the existence and get the contact form
exit if contact_info_page.forms.count != 1
contact_form = contact_info_page.forms.first

# Fill in the contact details
contact_form["user[first_name]"] = FIRST_NAME
contact_form["user[last_name]"] = LAST_NAME
contact_form["user[phone]"] = PHONE
contact_form["user[email]"] = EMAIL

# Submit the contact details and get confirmation page
confirmation_page = contact_form.submit

# Confirm the reservation
exit if confirmation_page.forms.count != 1
confirmation_form = confirmation_page.forms.first
final_page = confirmation_form.submit
puts "Got reservation for: #{start_form.seating_time}"
