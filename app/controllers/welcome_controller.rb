require 'ruby-cleverdome'

class WelcomeController < ApplicationController
	def index
		client = RubyCleverdome::Client.new(
			'http://sandbox.cleverdome.com/CDSSOService/SSOService.svc/SSO',
			'http://sandbox.cleverdome.com/CDWidgets/Services/Widgets.svc'
			)

		path = Dir.pwd + '/cert/certificate.pem'

		session_id = client.auth('http://tempuri.org/', 4898, path, path)
		doc_guid = '00f3fb8e-5f49-e311-952f-001d093226d7'
		app_id = 5

		hash_templates = client.get_templates(session_id, app_id)
		hash_tags = client.get_document_tags(session_id, doc_guid)
	end
end
