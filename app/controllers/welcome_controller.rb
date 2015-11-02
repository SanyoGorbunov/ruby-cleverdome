require 'ruby-cleverdome'
require 'ruby-cleverdome/types'

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
end
