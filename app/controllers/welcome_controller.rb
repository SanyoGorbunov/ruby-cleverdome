require 'ruby-cleverdome'
require 'ruby-cleverdome/types'

class WelcomeController < ApplicationController
	def index
		@output = ''

		config = CleverDomeConfiguration::CDConfig.new()
		client = RubyCleverdome::Client.new(config)

		api_key = config.apiKey
		user_id = config.testUserID
		@session_id = client.auth(api_key, user_id)
		log('session_id retrieved: ' + @session_id)

		doc_guid = upload_file(client, config)
		add_tags(client, doc_guid)

		list = client.get_security_group_types(@session_id)

		log('security group types retrieved: ' + list[1].name)
		render text: @output
	end

	def upload_file(client, config)
		file_path = File.expand_path('../../../files/TestFile.jpeg', __FILE__)
		content = ''
		File.open(file_path, 'rb') { |file| content = file.read }

		doc_guid = client.upload_file_binary(@session_id, config.applicationID, 'TestFile.jpeg', content)
		log('document uploaded: ' + doc_guid)

		doc_guid
	end

	def add_tags(client, doc_guid)
		client.add_document_tag(@session_id, doc_guid, 'Tag Text 1')
		client.add_document_tag(@session_id, doc_guid, 'Tag Text 2')
		client.add_document_tag(@session_id, doc_guid, 'Tag Text 3')
		log('tags added')

		hash_tags = client.get_document_tags(@session_id, doc_guid)
		log('document tags: ' + hash_tags.inspect)
	end

	def log(text)
		@output += text + '<br/>'
	end
end
