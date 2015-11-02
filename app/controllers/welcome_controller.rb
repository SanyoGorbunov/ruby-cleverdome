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

		@session_id = widgets_client.auth(api_key, user_id, config.test_ip_addresses)
		log('session_id retrieved: ' + @session_id)

		doc_guid = upload_file(widgets_client, config)
		test_template(widgets_client, doc_guid, config)
		test_metadata(widgets_client, doc_guid)

		user_management_client = RubyCleverdome::UserManagementClient.new(config)
		test_user_management(user_management_client)
		test_security_groups(widgets_client, user_management_client, config, doc_guid)
		delete_test_user(user_management_client)

		if config.archive_document
			test_archiving(widgets_client, config, doc_guid)
		else
			test_deleting_document(widgets_client, doc_guid)
		end

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
		log('Tags added')

		hash_tags = client.get_document_tags(@session_id, doc_guid)
		log('Document tags: ' + hash_tags.inspect)

		hash_tags.keys.first
	end

	def remove_tag(client, doc_guid, tag_id)
		client.remove_document_tag(@session_id, doc_guid, tag_id)
		log('Removed  tag: tagID = '+ tag_id.inspect)

	end

	def test_metadata(client, doc_guid)
		log('<br/>start testing metadata')
		metadata_type_id = RubyCleverdome::Constants.metadata_types[:tag];

		value_id = client.add_metadata(@session_id, doc_guid, metadata_type_id, 'new metadata');
		log('Add Metadata : "new metadata"')
		client.add_metadata(@session_id, doc_guid, metadata_type_id, 'NewMetadata');
		log('Add Metadata : "NewMetadata"')

		metadata = client.get_document_metadata(@session_id, doc_guid);
		log('All Document Metadata : ' + metadata.inspect)

		client.remove_metadata(@session_id, doc_guid, value_id);
		log('Remove metadata valueID'+  value_id)
		client.remove_metadata_by_value(@session_id, doc_guid, metadata_type_id,  'NewMetadata');
		log('Remove metadata value: "NewMetadata"')

		tagID =  add_tags(client, doc_guid)
		remove_tag(client,doc_guid, tagID)

	end

	def test_template(client, doc_guid, config)
		log('<br/>start testing template')
		app_ID = config.applicationID
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
	end

	def log(text)
		@output += text + '<br/>'
	end


	def test_user_management(client)
		log('<br/>start testing user management')
		uuid = SecureRandom.uuid
		@created_external_user_id = 'RubyTestUser' + uuid
		test_creating_user(client, @created_external_user_id)
		test_email_management(client, @created_external_user_id)

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

	def test_deleting_document(widgets_client, doc_guid)
		widgets_client.delete_documents(@session_id, [doc_guid])
		log('<br/>deleted document %s' % doc_guid)

		widgets_client.restore_documents(@session_id, [doc_guid])
		log('restored document %s' % doc_guid)

		widgets_client.delete_documents(@session_id, [doc_guid])
		log('deleted document %s' % doc_guid)
	end

	def test_archiving(widgets_client, config, doc_guid)
		log('<br/>start testing archiving')
		archive_info = widgets_client.get_documents_archive_info(@session_id, [doc_guid])
		log('archive info for document: ' + archive_info.inspect)

		archived_till = widgets_client.archive_documents(@session_id, [doc_guid], config.archiving_days)
		log('archived document for %s days. Archived till %s' % [config.archiving_days, archived_till])

		archive_info = widgets_client.get_documents_archive_info(@session_id, [doc_guid])
		log('archive info for document: ' + archive_info.inspect)
	end

	def delete_test_user(user_management_client)
		user_management_client.delete_user(@created_external_user_id)
	end
end
