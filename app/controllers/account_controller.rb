class AccountController < ApplicationController
  def login
  	request = login_action(params[:username], params[:password])
  	agent = request[0]
  	page = request[1]
  	token = agent.cookies.detect {|c| c.name == 'ses'}
  	full_name = page.parser.css('span#dash_user').try(:text).strip
  	checkouts = page.parser.css('span#dash_checked').try(:text).strip
  	holds = page.parser.css('span#dash_holds').try(:text).strip
  	holds_ready = page.parser.css('span#dash_pickup').try(:text).strip
  	fines = page.parser.css('span#dash_fines').try(:text).strip.gsub(/\$/, '')
    card = page.at('td:contains("Active Barcode")').try(:next_element).try(:text)
  	if token == nil
  		render :json =>{:message => 'login failed'}
  	else
  		render :json =>{:full_name => full_name, 
  			:checkouts => checkouts, 
  			:holds => holds,
  			:holds_ready => holds_ready,
  			:fine => fines, 
  			:token => token.value,
        :card => card
  		}
  	end
  end

  def login_refresh
    username = params[:username]
    pass_md5 = params[:pass_md5]

    result = login_refresh_action(username, pass_md5)

    params[:token] = result
    check_token
  end

  def logout
    token = params[:token]

    result = logout_action(token)

    render :json => {
        :result => result
    }
  end

  def check_token
    request = create_agent('/eg/opac/myopac/prefs','', params[:token])
    agent = request[0]
    page = request[1].parser
    token = agent.cookies.detect {|c| c.name == 'ses'}
    basic_info = user_basic_info(page, agent)
    if token == nil
      render :json =>{:message => 'failed'}
    else
      render :json => basic_info 
    end
  end

  def password_reset
    user = params["username"]
    request = create_agent('/eg/opac/password_reset','','')
    agent = request[0]
    page = request[1]
    form = page.forms[1]
    if (user =~ /^TADL\d{7,8}$|^90\d{5}$|^91111\d{9}$|^[a-zA-Z]\d{10}/ )
      form.field_with(:name => "barcode").value = user
    else
      form.field_with(:name => "username").value = user
    end
    agent.submit(form)
    render :json =>{:message => 'complete'}
  end

  def checkouts
  	if params[:token] == nil
  		render :json =>{:message => "Active token required"}
  		return
  	end

  	request = create_agent('/eg/opac/myopac/circs','', params[:token])
  	agent = request[0]
  	page = request[1].parser
  	page_title = page.title

  	if page_title == 'Catalog - Account Login'
  		render :json =>{:message => 'Invalid token'}
  		return
  	end

  	checkouts = scrape_checkouts(page)
  	render :json =>{:checkouts => checkouts}
  end

  def holds
  	if params[:token] == nil
  		render :json =>{:message => "Active token required"}
  		return
  	end

    if params[:task] == nil || params[:hold_id] == nil
      action = ''
    else
      action = { "action" => params[:task], "hold_id" =>  params[:hold_id]}
    end

  	request = create_agent('/eg/opac/myopac/holds?limit=41', action, params[:token])
  	page = request[1].parser
    page_title = page.title

  	if page_title == 'Catalog - Account Login'
  		render :json =>{:message => 'Invalid token'}
  		return
  	end

  	holds = scrape_holds(page)
  	render :json =>{:holds => holds, :count => holds.size}
  end



  def place_holds
  	record_ids = params[:record_ids].split(',').reject(&:empty?).map(&:strip).map {|k| "&hold_target=#{k}" }.join

  	if params[:token] == nil
  		render :json =>{:message => "Active token required"}
  		return
  	end


  	request = create_agent('/eg/opac/place_hold?hold_type=T' + record_ids,'', params[:token])
  	agent = request[0]
  	page = request[1].parser
  	page_title = page.title

  	if page_title == 'Catalog - Account Login'
  		render :json =>{:message => 'Invalid token'}
  		return
  	end
  	
  	hold_form = agent.page.forms[1]
  	submitt_holds = agent.submit(hold_form)
  	confirmation_messages = submitt_holds.parser.css('//table#hold-items-list//tr').map do |m|
  		{
  			:record_id => m.at_css("td[1]//input").try(:attr, "value"),
  			:message => m.at_css("td[2]").try(:text).try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip).try(:split, ". ").try(:last),
  		}
  	end

  	render :json =>{:confirmation_messages => confirmation_messages}
  end

  def renew_items
  	circ_ids = params[:circ_ids].split(',').reject(&:empty?).map(&:strip).map {|k| "&circ=#{k}" }.join

  	if params[:token] == nil
  		render :json =>{:message => "you are not logged in"}
  		return
  	end

  	request = create_agent('/eg/opac/myopac/circs?action=renew' + circ_ids,'', params[:token])
  	agent = request[0]
  	page = request[1].parser
  	page_title = page.title

  	if page_title == 'Catalog - Account Login'
  		render :json =>{:message => 'Invalid token'}
  		return
  	end

  	checkouts = scrape_checkouts(page)
  	confirmation = page.at_css('div.renew-summary').try(:text).try(:strip)

  	errors = page.css('table#acct_checked_main_header').css('tr').drop(1).reject{|r| r.search('span[@class="failure-text"]').present? == false}.map do |checkout| 
  		{
  			:message => checkout.css('span.failure-text').text.strip.try(:gsub, /^Copy /, ''),
  			:circ_id => checkout.previous.search('input[@name="circ"]').try(:attr, "value").to_s,
        :title => circ_to_title(page, checkout.previous.search('input[@name="circ"]').try(:attr, "value").to_s).try(:gsub, /:.*/, '').try(:strip),
  		}
  	end	

    render :json =>{:confirmation => confirmation, :errors => errors, :checkouts => checkouts }
  end

  def scrape_checkouts(page)
  	checkouts = page.css('table#acct_checked_main_header').css('tr').drop(1).reject{|r| r.search('span[@class="failure-text"]').present?}.map do |checkout| 
        {
        	:title => checkout.search('td[@name="author"]').css('a')[0].try(:text),
        	:author => checkout.search('td[@name="author"]').css('a')[1].try(:text),
        	:record_id => clean_record(checkout.search('td[@name="author"]').css('a')[0].try(:attr, "href")),
        	:checkout_id => checkout.search('input[@name="circ"]').try(:attr, "value").to_s,
        	:renew_attempts => checkout.search('td[@name="renewals"]').text.to_s.try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip),
        	:due_date => checkout.search('td[@name="due_date"]').text.to_s.try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip),
          :iso_due_date => Date.parse(checkout.search('td[@name="due_date"]').text.to_s.try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip)).to_s,
        	:barcode => checkout.search('td[@name="barcode"]').text.to_s.try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip),
        }
    end
    return checkouts
  end

  def scrape_holds(page)
    holds = page.css('tr#acct_holds_temp').map do |hold|
      {
        :title =>  hold.css('td[2]').css('a').text,
        :author => hold.css('td[3]').css('a').text,
        :record_id => clean_record(hold.css('td[2]').css('a').try(:attr, 'href').to_s),
        :hold_id => hold.search('input[@name="hold_id"]').try(:attr, "value").to_s,
        :hold_status => hold.css('td[8]').text.strip,
        :queue_status => hold.css('/td[9]/div/div[1]').text.strip.gsub(/AvailableExpires/, 'Available, Expires'),
        :queue_state => hold.css('/td[9]/div/div[2]').text.strip,
        :pickup_location => hold.css('td[5]').text.strip,
      }
    end
    sorted_by_hold_id = holds.sort_by {|k| k[:hold_id]}.reverse!
    sorted_by_hold_id.each do |h|
      if h[:queue_status] =~ /Available/
        sorted_by_hold_id.delete(h)
        sorted_by_hold_id.unshift(h) 
      end
    end
    return sorted_by_hold_id
  end

  def clean_record(string)
  	record_id = string.split('?') rescue nil
  	record_id = record_id[0].gsub('/eg/opac/record/','') rescue nil
  	return record_id
  end

  def circ_to_title(page, circ_id)
    look_for = 'input[@value="'+ circ_id +'"]'
    title = page.at(look_for).try(:parent).try(:next).try(:next).try(:css, 'a')[0].try(:text)
    return title  
  end  

  def user_basic_info(page, agent)
    token = agent.cookies.detect {|c| c.name == 'ses'}
    basic_info = page.css('body').map do |p|
      {
        :full_name => p.css('span#dash_user').try(:text).strip,
        :checkouts => p.css('span#dash_checked').try(:text).strip, 
        :holds => p.css('span#dash_holds').try(:text).strip,
        :holds_ready => p.css('span#dash_pickup').try(:text).strip,
        :fine => p.css('span#dash_fines').try(:text).strip.gsub(/\$/, ''), 
        :token => token.try(:value),
        :card => p.at('td:contains("Active Barcode")').try(:next_element).try(:text)
      }
    end

    return basic_info[0]
  end
end
