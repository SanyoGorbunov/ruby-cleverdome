require 'ruby-cleverdome'

class WelcomeController < ApplicationController
	def index
		client = RubyCleverdome::Client.new(
			'http://sandbox.cleverdome.com/CDSSOService/SSOService.svc/SSO',
			'http://sandbox.cleverdome.com/CDWidgets/Services/Widgets.svc'
			)

		path = Dir.pwd + '/cert/certificate.pem'

		session_id = client.auth('http://tempuri.org/', 4898, path, path)

		content = ''
		File.open('C:/Users/agorbunov/Downloads/Light-01.jpg', 'rb') { |file| content = file.read }

		doc_guid = client.upload_file_binary(session_id, 8, 'Light-01.jpg', content)

		client.add_document_tag(session_id, doc_guid, 'Tag Text 1')
		client.add_document_tag(session_id, doc_guid, 'Tag Text 2')
		client.add_document_tag(session_id, doc_guid, 'Tag Text 3')

		hash_tags = client.get_document_tags(session_id, doc_guid)
		render text: hash_tags.inspect
	end
end
