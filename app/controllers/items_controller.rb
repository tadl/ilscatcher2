class ItemsController < ApplicationController
  def details
  
  	record_id = params[:record]

  	# default location defined in application controller
  	if params[:loc]
  		location = '?locg='+ params[:loc]
  	else
  		location = '?locg='+ @default_loc
    end
  	record_details_url = '/eg/opac/record/'
  	mech_request = create_agent(record_details_url + record_id + location + '&copy_limit=50')
  	page = mech_request[1].parser
  	item_details = ''
  	page.css('#main-content').each do |detail|
  		item_details =
  		{
  		:author => detail.at_css(".rdetail_authors_div").try(:text).try(:gsub, /\n/, "").try(:strip),
			:title => detail.at_css("#rdetail_title").text,
			:summary => detail.at('td:contains("Summary, etc.:")').try(:next_element).try(:text).try(:strip),
			:contents => detail.at('td:contains("Formatted Contents Note:")').try(:next_element).try(:text).try(:strip),
			:record_id => record_id,
			:availability_scope => detail.css('meta[@property="seller"]').map {|i| i.attr('content')}, 
			:copies_available => detail.css('meta[@property="offerCount"]').map {|i| i.attr('content')},
			:copies_total => clean_totals_holds(detail.at('h2:contains("Current holds")').try(:next_element).try(:text))[1],
			:holds => clean_totals_holds(detail.at('h2:contains("Current holds")').try(:next_element).try(:text))[0],
			:eresource => detail.at('p.rdetail_uri').try(:at, 'a').try(:attr, "href"),
			:image => detail.at_css('#rdetail_image').try(:attr, "src").try(:gsub, /^\//, "https://catalog.tadl.org/").try(:gsub, /medium/, "large"),
			:format => detail.at('div#rdetail_format_label').text.strip,
			:format_icon => detail.at('div#rdetail_format_label').at('img').try(:attr, "src"),
			:record_year => detail.search('span[@property="datePublished"]').try(:text),
			:publisher => detail.search('span[@property="publisher"]').search('span[@property="name"]').try(:text).try(:strip),
			:publication_place => detail.search('span[@property="publisher"]').search('span[@property="location"]').try(:text).gsub(':','').try(:strip),
			:isbn => detail.css('span[@property="isbn"]').map {|i| i.text},
			:physical_description => detail.at('li#rdetail_phys_desc').try(:at, 'span.rdetail_value').try(:text),
			:related => detail.css('.rdetail_subject_value').to_s.split('<br>').reverse.drop(1).reverse.map { |i| clean_related(i)}.uniq,
  		}
  	end

  	copies = page.css('.copy_details_offers_row').map do |copy|
  		{
  			:location => copy.search('td[@headers="copy_header_library"]').try(:text),
  			:call_number => copy.search('td[@headers="copy_header_callnumber"]').try(:text),
  			:shelving_location => copy.search('td[@headers="copy_header_shelfloc"]').try(:text),
  			:status => copy.search('td[@headers="copy_header_status"]').try(:text),
  			:due_date => copy.search('td[@headers="copy_header_due_date"]').try(:text),
  		}
  	end

    copies_on_shelf = []
    copies.each do |copy|
      if copy[:status] == "Available"
        copies_on_shelf.push(copy)
      end 
    end

  	render :json =>{:item_details => item_details, :copies => copies, :copies_on_shelf => copies_on_shelf.compact.uniq }

  end

  #fix to remove unneeded path from related subjects and genres
  def clean_related(subject)
 	subject.gsub!(/\n/, "")
  	subject.gsub!(/<[^<>]*>/, "")
  	subject.to_s
  	subject.split('&gt;')
  end

  def clean_totals_holds(text)
  	totals = text.split('with') rescue nil
  	total_holds = totals[0].gsub('current holds','').strip rescue nil
  	total_copies = totals[1].gsub('total copies.','').strip rescue nil
  	return total_holds, total_copies
  end



end
