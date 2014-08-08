class WebController < ApplicationController
	def locations
		locations = Rails.cache.read('locations')
		render :json =>{:locations => locations}
	end

	def events
		events = Rails.cache.read('events')
		render :json =>{:events => events}
	end
end
