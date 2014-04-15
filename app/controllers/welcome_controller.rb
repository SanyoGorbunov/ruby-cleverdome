require 'ruby-cleverdome'
require 'ruby-cleverdome/multipart'

class WelcomeController < ApplicationController
	def index
		client = RubyCleverdome::Client.new(
			'http://win7dev6.unitedplanners.com/CDSSOService/SSOService.svc/SSO',
			'http://win7dev6.unitedplanners.com/CDWidgets/Services/Widgets.svc'
			)

		path = Dir.pwd + '/cert/certificate.pem'

		session_id = client.auth('http://tempuri.org/', 4898, path, path)
		
		response = client.upload_file(session_id, 1, 'C:/Users/agorbunov/Pictures/original_trianglemainimg.jpg')
		
		#response = client.widgets_call(:get_document_template, { documentGuid: '1d50dde0-4cd9-11e3-8879-1239b5f79600', sessionID: session_id })

		render text: response
	end
end
