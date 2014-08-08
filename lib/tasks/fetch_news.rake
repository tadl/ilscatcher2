desc "fetch news feed from web and save to cache"
task :fetch_news => :environment do
require 'mechanize'
require 'open-uri'
require 'memcachier'
require 'dalli'

news = JSON.parse(open("https://www.tadl.org/export/news/json").read)['nodes'].map {|i| i['node']}
Rails.cache.write("news", news)

end