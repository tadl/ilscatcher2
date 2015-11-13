class SearchController < ApplicationController
	require 'open-uri'
	def basic
		
		search_url = '/eg/opac/results?'
    	query = 'query=' + params[:query].to_s
		sort = '&sort=' + params[:sort].to_s
		qtype = '&qtype=' + params[:qtype].to_s if params[:qtype] else ''
		
		if params[:loc]
  			location = '&location_code='+ params[:loc]
  		else
  			location = '&location_code='+ @default_loc
    	end

    	if params[:page]
    		page_number = params[:page]
    		page_param = '&page=' + params[:page]
    	else
    		page_number = 0
    		page_param = '&page=0'
    	end

		if params[:availability] == 'yes'
			availability = '&available=true'
		else
			availability = ''
		end
		
		#TADL only stuff here just for video games
		if params[:format] == 'video_games'
			media_type = '&fi%3Aformat=mVG&facet=subject%7Cgenre%5Bgame%5D'
		elsif params[:format] == 'all'
			media_type = ''
		elsif params[:format]
			media_type = '&fi%3Aformat=' + params[:format] 
	 	else
			media_type = ''
		end
		
		url = 'https://elastic-evergreen.herokuapp.com/main/index.json?' + query + page_param + location + availability

		request = JSON.parse(open(url).read)
		results = request.map do |r|
			{
				:title => r["title_display"],
				:author => r["author"],
				#TODO holding processing
				:availability => 'blah',
				:copies_availabile => 'blah',
				:copies_total => 'blah',
				:record_id => r["id"],
                :eresource => r["links"][0],	
				:image => 'https://catalog.tadl.org/opac/extras/ac/jacket/medium/r/' + r["id"].to_s,
				:abstract => r["abstract"],
				:contents => r["contents"],
				#TODO format icon processing
				:format_icon => 'http://catalog.tadl.org/images/format_icons/icon_format/book.png',
				:format_type => r['type_of_resource'],
				:record_year => r['record_year'],
				#TODO process call number
				:call_number => '15',
			}
		end

		if results.size > 24
			more_results = 'true'
		else
			more_results = 'false'
		end
		
		render :json =>{:results => results, :page => page_number, :more_results => more_results}
	end

	def clean_availablity_counts(text)
		availability_array = text.strip.split('of')
		total_availabe = availability_array[0].strip
		total_copies_scope_arrary = availability_array[1].split('at', 2)
		total_copies = total_copies_scope_arrary[0].gsub('copy', '').gsub('copies', '').gsub('available','').strip 
		availability_scope = total_copies_scope_arrary[1]
		return total_availabe, total_copies, availability_scope
	end

	def check_e_resource(item)
		if item.at_css('span.result_place_hold')
			e_resource = false 
		else
			e_resource = true 
		end
		return e_resource
	end

	def scrape_format_year(item)
		format_year = item.css('div#bib_format').try(:text).try(:split, '(')
		format = format_year[0].strip rescue nil
		year = format_year[1].strip.gsub(')', '')	rescue nil
		result = [format, year]
		return result		
	end

end
