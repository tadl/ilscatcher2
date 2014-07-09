class SearchController < ApplicationController

	def basic
		search_url = '/eg/opac/results?'
		query = 'query=' + params[:q].to_s
		sort = '&sort=' + params[:sort].to_s
		qtype = '&qtype=' + params[:qtype].to_s if params[:qtype] else '' 
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
		elsif params[:format]
			media_type = '&fi%3Aformat=' + params[:format] 
		else
			media_type = ''
		end
		
		mech_request = create_agent(search_url + query + sort + media_type + availability + qtype.to_s + facet.to_s)
		page = mech_request[1].parser
		results = page.css(".result_table_row").map do |item|
			{
				:title => item.at_css(".record_title").text.strip,
				:author => item.at_css('[@name="item_author"]').text.strip.try(:squeeze, " "),
				:availability => item.at_css(".result_count").try(:text).split('at')[0].try(:strip),
				:online => item.search('a').text_includes("Connect to this resource online").first.try(:attr, "href"),
				:record_id => item.at_css(".record_title").attr('name').sub!(/record_/, ""),
				:image => item.at_css(".result_table_pic").try(:attr, "src"),
				:abstract => item.at_css('[@name="bib_summary"]').try(:text).try(:strip).try(:squeeze, " "),
				:contents => item.at_css('[@name="bib_contents"]').try(:text).try(:strip).try(:squeeze, " "),
				:record_year => item.at_css(".record_year").try(:text),
				:format_icon => item.at_css(".result_table_title_cell img").try(:attr, "src"),
			}
		end

		facet_list = page.css(".facet_box_temp").map do |item|
			group={}
			group['facet'] = item.at_css('.header/.title').text.strip.try(:squeeze, " ")
			group['sub_facets'] = item.css("div.facet_template:not(.facet_template_selected)").map do |facet|
				child_facet = {}
				child_facet['sub_facet'] = facet.at_css('.facet').text.strip.try(:squeeze, " ")
				child_facet['link'] = facet.css('a').attr('href').text.split('?')[1].split(';').drop(1).each {|i| i.gsub! 'facet=',''}
				child_facet
			end
			group
		end

		selected_facets = page.css("div.facet_template.facet_template_selected").map do |item|
			{
			:facet => item.at_css('.facet').text.strip.try(:squeeze, " "),
			:link => item.at_css('div.facet a').attr('href').to_s.split(';', 5).drop(1).each {|i| i.gsub! 'facet=',''}
			}
		end

		if page.css('.search_page_nav_link:contains(" Next ")').present?
			more_results = 'true'
		else
			more_results = 'false'
		end
		
		render :json =>{:results => results, :facets => facet_list, :selected_facets => selected_facets, :more_results => more_results}
	end



end
