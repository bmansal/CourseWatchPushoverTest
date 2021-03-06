require 'net/http'
require 'net/https'
require 'nokogiri'

application_token = "amvpvyj4r8zadohryj1vo9hdy5ag5s"
user_token = "upf2r6nfm715addg9h9a58uu1rqfxp"

def get_availability_ssl(crn, term)

  http = Net::HTTP.new("selfservice.mypurdue.purdue.edu", 443)
  http.use_ssl = true
  resp, result = http.get("/prod/bwckschd.p_disp_detail_sched?term_in=#{term}&crn_in=#{crn}")
  page = Nokogiri::HTML.parse(resp.body)

  #get class name
  class_name = page.css("table.datadisplaytable")[0].css("th")[0].content
  
  #get open seats 
  data_table = page.css("table.datadisplaytable")[1]
  row = data_table.css("tr")[1]
  remaining = row.css("td")[2].content.to_i
  if remaining > 0
    push_message class_name, remaining
  end

end

def push_message(class_name, open_slots)

  url = URI.parse("https://api.pushover.net/1/messages")
  req = Net::HTTP::Post.new(url.path)
  req.set_form_data({
    :token => application_token,
    :user => user_token,
    :message => "There are #{open_slots} open seats in #{class_name}! Go register!",
  })
  res = Net::HTTP.new(url.host, url.port)
  res.use_ssl = true
  res.verify_mode = OpenSSL::SSL::VERIFY_PEER
  res.start {|http| http.request(req) }

end

course_number = ARGV[0] ? ARGV[0] : "56746"
term_number = ARGV[1] ? ARGV[1] : "201910"

if(!ARGV[0] || !ARGV[1])
  puts "Usage: ruby watch.rb crn term"
  puts "(Term is 201910 for Fall 2019)"
else
  get_availability_ssl(course_number, term_number)
end