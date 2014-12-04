desc "Scrape Mel and check against TADL"
task :scrape_mel => :environment do
require 'mechanize'
require 'open-uri'
require 'memcachier'
require 'dalli'
require 'colorize'

agent = Mechanize.new
page = agent.get('http://mel.org/Databases')
mel_links = []
page.parser.css('#melDatabaseText').each do |r|
	mel_link = r.css('a.melDatabaseTitle').attr('href').to_s
	mel_links.push(mel_link)
end

tadl_links = JSON.parse(open("http://www.tadl.org/export/json/resources").read)['nodes'].map {|i| i['node']}
total_tadl_links = 0
bad_tadl_links = 0
bad_links = []
tadl_links.each do |l|
	if l['terms'].include? 'M - Available to MI residents'
		total_tadl_links += 1
		test = l['url']
		if !mel_links.include?(test)
			bad_tadl_links += 1	
			bad_link ={
				:title => l['title'],
				:url => l['url'],
				:nid => l['nid']
			} 
			bad_links.push(bad_link)
		end
	end
end

puts 'Total TADL Links linking to Mel databases: ' + total_tadl_links.to_s
puts 'Total TADL Links that do not match Mel Links: ' + bad_tadl_links.to_s

if bad_tadl_links > 0
	puts 'Links for the following database did not match what was found on Mel: '
	bad_links.each do |l|
	  puts  l[:title].to_s.colorize(:green) 
	  puts  l[:url].to_s.colorize(:blue)
	  puts '--------------'
	end
  MelmismatchMailer.melmismatch_email(bad_links).deliver
  puts 'Email Sent'.colorize(:green)
else
	puts 'All good!'.colorize(:green)
end

end