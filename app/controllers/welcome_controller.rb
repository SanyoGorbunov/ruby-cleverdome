require 'ruby-cleverdome'
require 'ruby-cleverdome/types'
require 'ruby-cleverdome/user-management'
require 'ruby-cleverdome/constants'

class WelcomeController < ApplicationController
	def index
		@output = ''

		config = CleverDomeConfiguration::CDConfig.new()
		widgets_client = RubyCleverdome::Client.new(config)

		api_key = config.apiKey
		user_id = config.testUserID
		@session_id = widgets_client.auth(api_key, user_id)
		log('session_id retrieved: ' + @session_id)

		doc_guid = upload_file(widgets_client, config)
		add_tags(widgets_client, doc_guid)

		user_management_client = RubyCleverdome::UserManagementClient.new(config)

		test_user_management(user_management_client)

		test_security_groups(widgets_client, user_management_client, config, doc_guid)

		render text: @output
	end

	def upload_file(client, config)
		file_path = File.expand_path('../../../files/TestFile.jpeg', __FILE__)
		content = ''
		File.open(file_path, 'rb') { |file| content = file.read }

		doc_guid = client.upload_file_binary(@session_id, config.applicationID, 'TestFile.jpeg', content)
		log('<br/>document uploaded: ' + doc_guid)

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

	def test_user_management(client)
		log('<br/>start testing user management')
		uuid = '2328ec50-190d-46c4-b57c-cda34bc8a26a' #SecureRandom.uuid
		@created_external_user_id = 'RubyTestUser' + uuid
		test_creating_user(client, @created_external_user_id)
		#test_email_management(client, @created_external_user_id)
	end

	def test_creating_user(client, external_user_id)
		internal_user_id = client.create_user(RubyCleverdome::ExternalUser.new({
				'id' => external_user_id,
				'first_name' => 'TestFirstName',
				'last_name' => 'TestLastName',
				'primary_email' => 'RubyTest' + SecureRandom.uuid + '@testemail.com',
				'phone_number' => '0000000000'
		}))

		log('created user with cleverdome user id = ' +internal_user_id)
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

	def test_security_groups(widgets_client, user_management_client, config, doc_guid)
		test_cleverdome_user_id = user_management_client.get_cleverdome_user_id(config.testUserID)
		log('get cleverdome user ID by external user ID: external_user_id = %s, internal_user_id = %s' %
			[test_cleverdome_user_id, config.testUserID])

		security_group_id = test_creating_security_group(widgets_client, config, test_cleverdome_user_id)
		test_security_group_membership(widgets_client, user_management_client, security_group_id)
		test_document_security_groups(widgets_client, doc_guid, security_group_id)
		test_removing_security_group(widgets_client, security_group_id)
	end

	def test_creating_security_group(widgets_client, config, cleverdome_user_id)
		group_types = widgets_client.get_security_group_types(@session_id)
		log('got security group types: %s.' % group_types.inspect)

		group_type_id = RubyCleverdome::Constants.security_group_types[:owner]
		security_group = widgets_client.create_security_group(@session_id, 'RubyTest', 'RubyTestGroup' + SecureRandom.uuid,
			group_type_id, cleverdome_user_id, config.applicationID)
		log('<br/>created security group: %s' % security_group.inspect)

		security_group.id
	end

	def test_removing_security_group(widget_client, security_group_id)
		widget_client.remove_security_group(@session_id, security_group_id)
		log('removed security group #%s' % security_group_id)
	end

	def test_security_group_membership(widgets_client, user_management_client, security_group_id)
		print_security_group(widgets_client, security_group_id)
		created_cleverdome_user_id = user_management_client.get_cleverdome_user_id(@created_external_user_id)

		widgets_client.add_user_to_security_group(@session_id, security_group_id, created_cleverdome_user_id)
		log('added user with external_id = %s and cleverdome_id = %s to security group #%s' %
						[@created_external_user_id, created_cleverdome_user_id, security_group_id])
		print_security_group(widgets_client, security_group_id)

		widgets_client.remove_user_from_security_group(@session_id, security_group_id, created_cleverdome_user_id)
		log('removed user with external_id = %s and cleverdome_id = %s from security group #%s' %
						[@created_external_user_id, created_cleverdome_user_id, security_group_id])
		print_security_group(widgets_client, security_group_id)
	end

	def test_document_security_groups(widgets_client, doc_guid, security_group_id)
		log('<br/>start testing security groups on the document')
		list_security_groups_on_document(widgets_client, doc_guid)

		security_level = RubyCleverdome::Constants.security_levels[:modify]
		widgets_client.attach_security_group_to_document(@session_id, doc_guid, security_group_id, security_level)
		log('added security group #%s to document %s. Security level: %s' % [security_group_id, doc_guid, security_level])
		list_security_groups_on_document(widgets_client, doc_guid)

		widgets_client.remove_security_group_from_document(@session_id, doc_guid, security_group_id)
		log('remove security group #%s from document %s.' % [security_group_id, doc_guid])
		list_security_groups_on_document(widgets_client, doc_guid)
	end

	def print_security_group(widgets_client, security_group_id)
		users = widgets_client.get_security_group_users(@session_id, security_group_id)
		log('members of security group #%s: %s' % [security_group_id, users.inspect])
	end

	def list_security_groups_on_document(widgets_client, doc_guid)
		security_groups = widgets_client.get_document_security_groups(@session_id, doc_guid)
		log('security groups on the document: ' + security_groups.inspect)
	end
end
