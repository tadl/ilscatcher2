class ApplicationController < ActionController::API
require 'mechanize'
before_filter :load_app_variables
before_filter :set_headers

    def set_headers
        headers['Access-Control-Allow-Origin'] = '*'      
    end  

    def load_app_variables
        @default_loc = '22'
        @opac_base_url = 'https://eg.dev.tadl.org'
        @domain = 'eg.dev.tadl.org'
    end
    
    def create_agent(url = '', post_params = '', token = '')
    	# NOTE NEED to remove SSL VERIFY NONE in production
    	agent = Mechanize.new{|a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE}
    	full_url = @opac_base_url + url
    	if token != ''
    		cookie = Mechanize::Cookie.new('ses', token)
    		cookie.domain = @domain
    		cookie.path = "/"
    		agent.cookie_jar.add!(cookie)
    	end	
        if url != ''
           if post_params != ''
                page = agent.post(full_url, post_params) rescue page = Mechanize::Page.new(uri = nil, response = nil, body = nil, code = '500', mech = nil)
                return agent, page
           else
                page = agent.get(full_url) rescue page = Mechanize::Page.new(uri = nil, response = nil, body = nil, code = '500', mech = nil)
                return agent, page
           end
        else
                return agent
        end
    end
    
    def login_action(username, password)
        # NOTE NEED to remove SSL VERIFY NONE in production
        agent = Mechanize.new{|a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE}
        login = agent.get(@opac_base_url + '/eg/opac/myopac/prefs')
        form = agent.page.forms[1]
        form.field_with(:name => "username").value = username
        form.field_with(:name => "password").value = password
        form.checkbox_with(:name => "persist").check
        agent.submit(form)
        page = agent.page
        return agent, page
    end

end
