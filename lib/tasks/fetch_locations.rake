desc "fetch location feeds from web and save to cache"
task :fetch_locations => :environment do
require 'mechanize'
require 'open-uri'
require 'memcachier'
require 'dalli'

woodmere = JSON.parse(open("https://www.tadl.org/mobile/export/locations/wood").read)['nodes'][0]['node']
kingsley = JSON.parse(open("https://www.tadl.org/mobile/export/locations/kbl").read)['nodes'][0]['node']
pcl = JSON.parse(open("https://www.tadl.org/mobile/export/locations/pcl").read)['nodes'][0]['node']
interlochen = JSON.parse(open("https://www.tadl.org/mobile/export/locations/ipl").read)['nodes'][0]['node']
east_bay = JSON.parse(open("https://www.tadl.org/mobile/export/locations/ebb").read)['nodes'][0]['node']
fife_lake = JSON.parse(open("https://www.tadl.org/mobile/export/locations/flpl").read)['nodes'][0]['node']

locations = [woodmere, kingsley, interlochen, pcl, fife_lake, east_bay] 

Rails.cache.write("locations", locations)

end