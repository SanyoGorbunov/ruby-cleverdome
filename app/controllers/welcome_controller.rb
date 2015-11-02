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
		app_ID = config.applicationID
		@session_id = client.auth(api_key, user_id)
		log('session_id retrieved: ' + @session_id)

		doc_guid = upload_file(client, config)

		template = client.get_templates(@session_id, app_ID)
		log('app template: ' +template.inspect)

		doc_template = client.get_document_template(@session_id, doc_guid)
		log('document template: ' +doc_template.inspect)

    template_types = client.get_template_types(@session_id, app_ID , template.keys.first)
		log('template types: ' + template_types.inspect)

		doc_type = client.get_document_type(@session_id, doc_guid)
		log('document type: ' + doc_type.inspect)

		setDoc =  client.set_document_template_type(@session_id, doc_guid, 0, 3 )
		log('set document template type')

		value_id = client.add_metadata(@session_id, doc_guid, 78, 'new metadata');
		log('Add Metadata : "new metadata"')
		client.add_metadata(@session_id, doc_guid, 78, 'NewMetadata');
		log('Add Metadata : "NewMetadata"')
		metadata = client.get_document_metadata(@session_id, doc_guid);
		log('Document Metadata : ' + metadata.inspect)

		client.remove_metadata(@session_id, doc_guid, value_id);
		log('Remove metadata valueID'+  value_id)
		client.remove_metadata_by_value(@session_id, doc_guid, 78,  'NewMetadata');
		log('Remove metadata value: "NewMetadata"')

		all_tags = client.get_document_tags(@session_id, doc_guid);
		log('All tags : ' + all_tags.inspect)

		tagID =  add_tags(client, doc_guid)
		remove_tag(client,doc_guid, tagID)

		list = client.get_security_group_types(@session_id)
		log('security group types retrieved: ' + list[1].name)
		log('security group types retrieved: ' + list[1].name + list[1].id.inspect)
		list_perm =  client.get_group_permissions(@session_id, doc_guid, list[1].id)

		log('security permissions: ' + list_perm[1].name + list_perm[1].id)

		list = client.get_security_group_types(@session_id)


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

		hash_tags.keys.first
	end

	def remove_tag(client, doc_guid, tag_id)
		log('---TAG REMOVE---')
		client.remove_document_tag(@session_id, doc_guid, tag_id)
		log('tagID:'+ tag_id.inspect+' -- remove')

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
