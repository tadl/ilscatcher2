class SearchController < ApplicationController
	require 'open-uri'
	def basic
		
		search_url = '/eg/opac/results?'
    	query = 'query=' + params[:query].to_s
		if params[:sort] == 'pubdate.descending'
			search_value = 'pubdateDESC'
		elsif params[:sort] == 'pubdate'
			search_value = 'pubdateASC'
		elsif params[:sort] == 'titlesort'
			search_value = 'titleAZ'
		elsif params[:sort] == 'titlesort.descending'
			search_value = 'titleZA'
		else
			search_value = 'relevancy' 	
		end

		sort = '&sort=' + search_value
		
		if params[:qtype] 
			qtype = '&search_type=' + params[:qtype].to_s 
		else 
			qtype = ''
		end
		
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
		if params[:format] == 'all'
			media_type = ''
		elsif params[:format]
			media_type = '&format_type=' + params[:format] 
	 	else
			media_type = ''
		end
		
		url = 'https://elastic-evergreen.herokuapp.com/main/index.json?' + query + page_param + location + availability + qtype + media_type + sort

		request = JSON.parse(open(url).read)

		results = Array.new

		request.each do |r|
			item_holdings = process_holdings(r["holdings"], params[:loc])
			icon = get_icon(r['type_of_resource'])
			item = Hash.new
			item["title"] = r["title_display"]
			item["author"]= r["author"]
			item["availability"]= [item_holdings[1]]
			item["record_id"]= r["id"]
			if r["electronic"] == true
				item["eresource"]= r["links"][0]
			else
				item["eresouce"] = nil 
			end
			item["image"]= 'https://catalog.tadl.org/opac/extras/ac/jacket/medium/r/' + r["id"].to_s
			item["abstract"]= r["abstract"]
			item["contents"]= r["contents"]
			item["format_icon"]= 'http://catalog.tadl.org/images/format_icons/icon_format/' + icon
			item["format_type"]= r['type_of_resource']
			item["record_year"]= r['record_year']
			item["call_number"]= item_holdings[0]
			results.push(item)
		end

		if results.size > 24
			more_results = 'true'
		else
			more_results = 'false'
		end
		page_number = (page_number.to_i + 1).to_s
		render :json =>{:results => results, :page => page_number, :more_results => more_results}
	end

	def get_icon(record_type)
		icon = nil
		format_to_icon = [['book.png','text'], 
                        ['score2.png','notated music'],  
                        ['map2.png','cartographic'], 
                        ['dvd.png','moving image'], 
                        ['cdaudiobook.png','sound recording-nonmusical'], 
                        ['cdmusic.png','sound recording-musical'], 
                        ['picture.png','still image'], 
                        ['software.png','software, multimedia'], 
                        ['kit.png','kit'], 
                        ['kit.png','mixed-material'], 
                        ['kit.png','three dimensional object']]
        format_to_icon.each do |i|
        	if i[1] == record_type
        		icon = i[0]
        	end
        end
        if icon == nil
        	icon = 'book.png'
        end
        return icon
	end

	def process_holdings(availability, location)
    	location_code = code_to_location(location)
   		if availability != nil or availability != ''
    	  all_available = 0
    	  all_total = 0
    	  location_available = 0
    	  location_total = 0
    	  call_number = Array.new
    	  availability.each do |a|
		  	all_total = all_total + 1
    	  	if a["status"] == "Available" || a["status"] == "Reshelving"
    	    	all_available = all_available + 1
    	    	call_number.push(a["call_number"])
    	  	end
    	  	if location_code != '' && location_code != 'all locations'
    	    	if (a["status"] == "Available" || a["status"] == "Reshelving") && a["circ_lib"] == location_code
    	      		location_available = location_available + 1
    	    	end
    	    	if a["circ_lib"] == location_code
    	      		location_total = location_total + 1
    	      		call_number = Array.new
    	      		call_number.push(a["call_number"])
    	    	end
    	  	else
    	    	location_total = all_total
    	    	location_available = all_available
    	  	end
    	  end
    	  call_number = call_number[0] rescue nil
    	  availability_string = location_available.to_s + ' out of ' + location_total.to_s + ' available at ' + location_code
    	else
    	  call_number = nil
    	  location_available = nil
    	  location_total = nil
    	  all_available = nil
    	  all_total = nil
    	  availability_string = nil
    	end
    	return call_number, availability_string
	end

	def code_to_location(location_code)
    	location = ''
    	if location_code == '22' || location == nil || location_code == ''
    	  location = 'all locations'
    	elsif location_code == '23'
    	  location = 'TADL-WOOD'
    	elsif location_code == '24'
    	  location = 'TADL-IPL'
    	elsif location_code == '25'
    	  location = 'TADL-KBL'
    	elsif location_code == '26'
    	  location = 'TADL-PCL'
    	elsif location_code == '27'
    	  location = 'TADL-FLPL'
    	elsif location_code == '28'
    	  location = 'TADL-EBB'
    	else
    	  location = 'all locations'
    	end
    	return location
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
