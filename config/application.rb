require File.expand_path('../boot', __FILE__)

#require 'rails/all'
require "action_controller/railtie"
require "action_mailer/railtie"

Bundler.require(*Rails.groups)

module Ilscatcher2
  class Application < Rails::Application
    config.filter_parameters += [:password]
    config.filter_parameters += [:pass_md5]
  end
end
