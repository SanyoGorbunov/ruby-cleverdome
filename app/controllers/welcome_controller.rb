require 'ruby-cleverdome'

class WelcomeController < ApplicationController
	def index
		client = RubyCleverdome::Client.new(
			'http://sandbox.cleverdome.com/CDSSOService/SSOService.svc/SSO',
			'http://sandbox.cleverdome.com/CDWidgets/Services/Widgets.svc'
			)

		path = Dir.pwd + '/cert/certificate.pem'

		session_id = client.auth('http://tempuri.org/', 4898, path, path)
		app_id = 5

		hash_templates = client.get_templates(session_id, app_id)	
	end
end
