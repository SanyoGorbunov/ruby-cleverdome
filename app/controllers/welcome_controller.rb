require 'ruby-cleverdome'
require 'ruby-cleverdome/types'
require 'ruby-cleverdome/user-management'

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

		test_user_management(config)
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

	def test_user_management(config)
		log('start testing user management')
		uuid = SecureRandom.uuid
		external_user_id = 'RubyTestUser' + uuid
		client = RubyCleverdome::UserManagementClient.new(config)
		test_creating_user(client, external_user_id)
		test_email_management(client, external_user_id)
	end

	def test_creating_user(client, external_user_id)
		internal_user_id = client.create_user(RubyCleverdome::ExternalUser.new({
				'id' => external_user_id,
				'first_name' => 'TestFirstName',
				'last_name' => 'TestLastName',
				'primary_email' => 'RubyTest' + SecureRandom.uuid + '@testemail.com',
				'phone_number' => '0000000000'
		}))

		log('created user with cleverdome user id = ' + internal_user_id)
	end

	def test_email_management(client, external_user_id)
		original_email_id = client.get_user_emails(external_user_id).first.id
		list_user_emails(client, external_user_id)

		second_email = 'NewRubyEmail' + SecureRandom.uuid + '@testemail.com'
		second_email_id = client.add_user_email(external_user_id, second_email, true)
		log('added email %s to the user: email_id = %s' % [external_user_id, second_email_id])
		list_user_emails(client, external_user_id)

		client.set_user_primary_email(external_user_id, original_email_id)
		log('set origonal email ''%s'' as primary' % [original_email_id])
		list_user_emails(client, external_user_id)

		client.remove_user_email(external_user_id, second_email_id)
		log('remove email with id = ' + second_email_id)
		list_user_emails(client, external_user_id)
	end

	def list_user_emails(client, external_user_id)
		emails = client.get_user_emails(external_user_id)
		log('current user''s emails: ' + emails.inspect)
	end
end
