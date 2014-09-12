class ApplicationController < ActionController::API
require 'digest/md5'
require 'mechanize'
before_filter :load_app_variables
before_filter :set_headers

    def set_headers
        headers['Access-Control-Allow-Origin'] = '*'      
    end  

    def load_app_variables
        @default_loc = '22'
        @opac_base_url = 'https://mr.tadl.org'
        @domain = 'mr.tadl.org'
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

    def login_refresh_action(username, pass_md5)
        uri = URI.parse(@opac_base_url + "/osrf-gateway-v1")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request_seed = Net::HTTP::Post.new(uri.request_uri)
        request_seed.set_form_data({
            "service" => "open-ils.auth",
            "method" => "open-ils.auth.authenticate.init",
            "param" => '"' + username + '"'
        })

        response = http.request(request_seed)

        # ensure http status ok, ensure json status ok
        if response.code == '200'
            j_content = JSON.parse(response.body)
            if j_content['status'] == 200
                seed = j_content['payload'][0]
            end
        end

        password = Digest::MD5.hexdigest(seed + pass_md5)

        auth_param = {
            "type" => "opac",
            "username" => username,
            "password" => password
        }

        request_complete = Net::HTTP::Post.new(uri.request_uri)
        request_complete.set_form_data({
            "service" => "open-ils.auth",
            "method" => "open-ils.auth.authenticate.complete",
            "param" => JSON.generate(auth_param)
        })

        response = http.request(request_complete)

        if response.code == '200'
            j_content = JSON.parse(response.body)
            if j_content['status'] == 200
                if j_content['payload'][0]['ilsevent'] == 0
                    return j_content['payload'][0]['payload']['authtoken']
                end
            end
        end

    end

    def logout_action(token)
        uri = URI.parse(@opac_base_url + "/osrf-gateway-v1")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({
            "service" => "open-ils.auth",
            "method" => "open-ils.auth.session.delete",
            "param" => '"' + token + '"'
        })

        response = http.request(request)

        return response.code

    end

end
