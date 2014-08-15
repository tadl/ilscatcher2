class SearchController < ApplicationController
	def basic
		
		search_url = '/eg/opac/results?'
    	query = 'query=' + params[:query].to_s
		sort = '&sort=' + params[:sort].to_s
		qtype = '&qtype=' + params[:qtype].to_s if params[:qtype] else ''
		
		if params[:loc]
  			location = '&locg='+ params[:loc]
  		else
  			location = '&locg='+ @default_loc
    	end

    	if params[:page]
    		page_number = params[:page]
    		page_param = '&page=' + params[:page]
    	else
    		page_number = 0
    		page_param = '&page=0'
    	end


		facet = ''
		if params[:facet]
			params[:facet].each do |f|
				facet += '&facet=' + f
			end
		end
		
		if params[:availability] == 'yes'
			availability = '&modifier=available'
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
	 	end
			media_type = ''
		end
		
		mech_request = create_agent(search_url + query + sort + media_type + availability + qtype.to_s + facet.to_s + location + page_param)
		page = mech_request[1].parser
		results = page.css(".result_table_row").map do |item|
			{
				:title => item.at_css(".record_title").text.strip,
				:author => item.at_css('[@name="item_author"]').text.strip.try(:squeeze, " "),
				:availability => item.css(".result_count").map {|i| i.try(:text).try(:strip)},
				:copies_availabile => item.css(".result_count").map {|i| clean_availablity_counts(i.try(:text))[0]},
				:copies_total => item.css(".result_count").map {|i| clean_availablity_counts(i.try(:text))[1]},
				:online => item.search('a').text_includes("Connect to this resource online").first.try(:attr, "href"),
				:record_id => item.at_css(".record_title").attr('name').sub!(/record_/, ""),
				#hack for dev below
				:image => 'http://catalog.tadl.org' + item.at_css(".result_table_pic").try(:attr, "src"),
				:abstract => item.at_css('[@name="bib_summary"]').try(:text).try(:strip).try(:squeeze, " "),
				:contents => item.at_css('[@name="bib_contents"]').try(:text).try(:strip).try(:squeeze, " "),
				:record_year => item.at_css(".record_year").try(:text),
				#hack for dev below
				:format_icon => 'http://catalog.tadl.org' + item.at_css(".result_table_title_cell img").try(:attr, "src"),
			}
		end

		facet_list = page.css(".facet_box_temp").map do |item|
			group={}
			group['facet'] = item.at_css('.header/.title').text.strip.try(:squeeze, " ")
			group['sub_facets'] = item.css("div.facet_template").map do |facet|
				child_facet = {}
				child_facet['sub_facet'] = facet.at_css('.facet').text.strip.try(:squeeze, " ")
				child_facet['path'] = facet.css('a').attr('href').text.split('?')[1].split(';').drop(1).each {|i| i.gsub! 'facet=',''}
				if facet['class'].include? 'facet_template_selected'
					child_facet['selected'] = 'true'
				end
				child_facet
			end
			group
		end

		if page.css('.search_page_nav_link:contains(" Next ")').present?
			more_results = 'true'
		else
			more_results = 'false'
		end
		
		render :json =>{:results => results, :facets => facet_list, :page => page_number, :more_results => more_results}
	end

	def clean_availablity_counts(text)
		availability_array = text.strip.split('of')
		total_availabe = availability_array[0].strip
		total_copies_scope_arrary = availability_array[1].split('at', 2)
		total_copies = total_copies_scope_arrary[0].gsub('copy', '').gsub('copies', '').gsub('available','').strip 
		availability_scope = total_copies_scope_arrary[1]
		return total_availabe, total_copies, availability_scope
	end

	

end
