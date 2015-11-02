require 'nokogiri'
require 'savon'
require 'uuid'
require 'signed_xml'
require 'mime/types'
require 'ruby-cleverdome/multipart'
require 'ruby-cleverdome/types'
require 'ruby-cleverdome/config'
require 'base64'

module RubyCleverdome
	class Client
		def initialize(config)
			@config = config
			@cert = File.expand_path(@config.cleverDomeCertFile, __FILE__)
			init_auth_client()
			init_widgets_client()
		end

		def init_auth_client()
			@auth_client = Savon.client(
				wsdl: 'http://' + @config.authServicePath + '?wsdl',
				endpoint: 'https://' + @config.authServicePath,
				namespace: 'http://cleverdome.com/apikeys',
				ssl_ca_cert_file: @cert,
				#ssl_verify_mode: :none,
				#proxy: 'http://127.0.0.1:8888',
			)
		end

		def init_widgets_client()
			@widgets_client = Savon.client(
				wsdl: 'http://' + @config.widgetsServicePath + '?wsdl',
				endpoint: 'https://' + @config.widgetsServicePath + '/basic',
				namespace: 'http://tempuri.org/',
				ssl_ca_cert_file: @cert,
				#ssl_verify_mode: :none,
				#proxy: 'http://127.0.0.1:8888',
			)
		end

		def auth(api_key, user_id)
			responseMessage = auth_call(api_key, user_id).to_hash[:api_key_response_message]

			if !responseMessage[:is_success]
				raise responseMessage[:error_message]
			end

			responseMessage[:session_id]
		end

		def call_widgets_with_attributes(method, locals, attributes)
			response = @widgets_client.call(
					method,
					:attributes => attributes,
					message: locals
			)
		end

		def widgets_call(method, locals)
			call_widgets_with_attributes(method, locals, { 'xmlns' => 'http://tempuri.org/' })
		end

	  	def operations
	  		@widgets_client.operations
	  	end

	  	def upload_file(session_id, app_id, file_path)
	  		data, headers = Multipart::Post.prepare_query(
	  			"sessionID" 	=> session_id,
	  			"file" 			=> File.open(file_path, 'rb'),
	  			'applicationID' => app_id
	  			)

	  		response = @widgets_client.call(
	  			:upload_file,
	  			:attributes => {
	  				'xmlns' => 'http://tempuri.org/'
	  				},
	  			message: {
	  				inputStream: Base64.encode64(data)
	  				})
	  		response.body[:upload_file_response][:upload_file_result]
	  	end

	  	def upload_file_binary(session_id, app_id, filename, binary_data)
	  		data, headers = Multipart::Post.prepare_query(
	  			"sessionID" 	=> session_id,
	  			"file" 			=> { 'filename' => filename, 'data' => binary_data },
	  			'applicationID' => app_id
	  			)

	  		response = @widgets_client.call(
	  			:upload_file,
	  			:attributes => {
	  				'xmlns' => 'http://tempuri.org/'
	  				},
	  			message: {
	  				inputStream: Base64.encode64(data)
	  				})
	  		response.body[:upload_file_response][:upload_file_result]
	  	end

	  	def get_templates(session_id, app_id)
	  		resp_doc = widgets_call(
	  			:get_document_templates,
	  			{
	  				'sessionID' => session_id,
	  				'applicationID' => app_id
	  			}).doc

	  		check_body(resp_doc)

	  		hash = resp_doc.xpath('//ReturnValue')[0]
	  			.element_children.each_with_object(Hash.new) do |e, h|
	  			h[Integer(e.at('ID').content)] = e.at('Name').content
	  		end

	  		hash
	  	end

	  	def get_document_template(session_id, doc_guid)
	  		resp_doc = widgets_call(
	  			:get_document_template,
	  			{
	  				'sessionID' => session_id,
	  				'documentGuid' => doc_guid
	  			}).doc

	  		check_body(resp_doc)

	  		return [Integer(resp_doc.xpath('//ReturnValue/ID')[0].content), resp_doc.xpath('//ReturnValue/Name')[0].content]
	  	end

	  	def get_template_types(session_id, app_id, template_id)
	  		resp_doc = widgets_call(
	  			:get_document_types,
	  			{
					'sessionID' => session_id,
	  				'templateID' => template_id,
	  				'applicationID' => app_id
  				}).doc

	  		check_body(resp_doc)

	  		hash = resp_doc.xpath('//ReturnValue')[0]
	  			.element_children.each_with_object(Hash.new) do |e, h|
	  			h[Integer(e.at('ID').content)] = e.at('Name').content
	  		end

	  		hash
	  	end

	  	def get_document_type(session_id, doc_guid)
	  		resp_doc = widgets_call(
	  			:get_document_type,
	  			{
	  				'sessionID' => session_id,
	  				'documentGuid' => doc_guid
	  			}).doc

	  		check_body(resp_doc)

	  		return [Integer(resp_doc.xpath('//ReturnValue/ID')[0].content), resp_doc.xpath('//ReturnValue/Name')[0].content]
	  	end

	  	def set_document_template_type(session_id, doc_guid, template_id, type_id)
	  		resp_doc = widgets_call(
	  			:set_document_template,
	  			{
					'sessionID' => session_id,
	  				'documentGuid' => doc_guid,
	  				'templateID' => template_id,
	  				'documentTypeID' => type_id
  				}).doc

	  		check_body(resp_doc)

	  	end

	  	def get_document_tags(session_id, doc_guid)
	  		resp_doc = widgets_call(
	  			:get_document_tags,
	  			{
	  				'sessionID' => session_id,
	  				'documentGuid' => doc_guid
	  			}).doc

	  		check_body(resp_doc)

	  		hash = resp_doc.xpath('//ReturnValue')[0]
	  			.element_children.each_with_object(Hash.new) do |e, h|
	  			h[Integer(e.at('ID').content)] = e.at('Name').content
	  		end

	  		hash
	  	end

	  	def add_document_tag(session_id, doc_guid, tag_text)
	  		resp_doc = widgets_call(
	  			:add_document_tag,
	  			{
	  				'sessionID' => session_id,
	  				'documentGuid' => doc_guid,
	  				'tagName' => tag_text
	  			}).doc

	  		check_body(resp_doc)
	  	end

	  	def remove_document_tag(session_id, doc_guid, tag_id)
			resp_doc = widgets_call(
	  			:remove_document_tag,
	  			{
	  				'sessionID' => session_id,
	  				'documentGuid' => doc_guid,
	  				'tagID' => tag_id
	  			}).doc

	  		check_body(resp_doc)
			end

			def get_document_metadata(session_id, doc_guid)
				resp_doc = widgets_call(
				:get_document_metadata_base,
						{
								'sessionID' => session_id,
								'documentGuid' => doc_guid
						}).doc

				check_body(resp_doc)

				list = Array.new
				resp_doc.xpath('//ReturnValue/DocumentMetadataValueBase').each do |dmv|
					list.push(RubyCleverdome::MetadataValue.from_xml dmv)
				end

				list
			end

			def add_metadata(session_id, doc_guid, type_id, value)
				resp_doc = widgets_call(
						:add_document_field,
						{
								'sessionID' => session_id,
								'documentGuid' => doc_guid,
								'fieldID' => type_id,
								'fieldValue' =>  value

						}).doc
				check_body(resp_doc)

				return resp_doc.xpath('//ReturnValue')[0].content
			end

			def remove_metadata(session_id, doc_guid, value_id)
				resp_doc = widgets_call(
						:remove_document_field,
						{
								'sessionID' => session_id,
								'documentGuid' => doc_guid,
								'valueID' => value_id
						}).doc
				check_body(resp_doc)
			end

			def remove_metadata_by_value(session_id, doc_guid, type_id, value)
				resp_doc = widgets_call(
						:remove_document_field_by_value,
						{
								'sessionID' => session_id,
								'documentGuid' => doc_guid,
								'fieldTypeID' => type_id,
								'fieldValue' => value
						}).doc
				check_body(resp_doc)
			end

	  	def get_document_security_groups(session_id, doc_guid)
	  		resp_doc = widgets_call(
	  			:get_security_groups,
	  			{
	  				'sessionID' => session_id,
	  				'documentGuid' => doc_guid
  				}).doc

	  		check_body(resp_doc)

			  list = Array.new
			  resp_doc.xpath('//SecurityGroup').each do |sg|
					list.push(RubyCleverdome::SecurityGroup.from_xml sg)
				end

				list
	  	end

	  	def get_group_permissions(sesson_id, doc_guid, group_id)
	  		resp_doc = widgets_call(
	  			:get_group_permissions,
	  			{
	  				'sessionID' => session_id,
	  				'groupID' => group_id,
	  				'documentGuid' => doc_guid
  				}).doc

	  		check_body(resp_doc)

			list = Array.new
			resp_doc.xpath('//ReturnValue/PermissionData').each do |sg|
				list.push(RubyCleverdome::PermissionData.new({
					'id' => sg.at('ID'),
					'name' => sg.at('Name'),
					'allowed' => sg.at('Allowed')}))
			end

			list
			end

	  	def attach_security_group_to_document(session_id, doc_guid, group_id, security_level)
	  		resp_doc = call_widgets_with_attributes(
	  			:attach_security_groups_to_document,
	  			{
	  				'sessionID' => session_id,
						'documentGuid' => doc_guid,
	  				'securityGroupIDs' => {'a:int' => [group_id]},
						'securityLevel' => security_level
  				}, {
							'xmlns' => 'http://tempuri.org/',
							'xmlns:a' => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'
					}).doc

	  		check_body(resp_doc)	  		
			end

			def remove_security_group_from_document(session_id, doc_guid, group_id)
				resp_doc = widgets_call(
						:remove_security_group_from_document,
						{
								'sessionID' => session_id,
								'documentGuid' => doc_guid,
								'securityGroupID' => group_id
						}).doc

				check_body(resp_doc)
			end

	  	def remove_security_group(session_id, group_id)
	  		resp_doc = widgets_call(
	  			:remove_security_group,
	  			{
	  				'sessionID' => session_id,
	  				'securityGroupID' => group_id
  				}).doc

	  		check_body(resp_doc)	  		
	  	end

	  	def set_security_group_permission(session_id, doc_guid, group_id, permission_id, permission_value)
			resp_doc = widgets_call(
	  			:set_permission_for_group,
	  			{
	  				'sessionID' => session_id,
						'groupID' => group_id,
	  				'permissionID' => permission_id,
	  				'permissionValue' => permission_value,
	  				'documentGuid' => doc_guid
  				}).doc

	  		check_body(resp_doc)
	  	end

	  	def add_user_to_security_group(session_id, group_id, user_id)
	  		resp_doc = widgets_call(
	  			:add_user_to_security_group,
	  			{
	  				'sessionID' => session_id,
	  				'groupID' => group_id,
	  				'userID' => user_id
  				}).doc

	  		check_body(resp_doc)
	  	end

	  	def remove_user_from_security_group(session_id, group_id, user_id)
	  		resp_doc = widgets_call(
	  			:remove_user_from_security_group,
	  			{
	  				'sessionID' => session_id,
	  				'groupID' => group_id,
	  				'userID' => user_id
  				}).doc

	  		check_body(resp_doc)
	  	end

	  	def create_security_group(session_id, name, desc, type_id, owner_user_id, application_id)
	  		resp_doc = widgets_call(
	  			:create_security_group,
	  			{
	  				'sessionID' => session_id,
	  				'name' => name,
	  				'description' => desc,
	  				'type' => type_id,
	  				'ownerID' => owner_user_id,
						'templateApplicationID' => application_id
  				}).doc

	  		check_body(resp_doc)

	  		RubyCleverdome::SecurityGroup.from_xml resp_doc.xpath('//ReturnValue')
	  	end

	  	def get_security_group_users(session_id, group_id)
	  		resp_doc = widgets_call(
	  			:get_users_for_group,
	  			{
	  				'sessionID' => session_id,
	  				'groupID' => group_id
  				}).doc

	  		check_body(resp_doc)

			  list = Array.new
			  resp_doc.xpath('//ReturnValue/UserData').each do |ud|
				list.push(RubyCleverdome::UserData.from_xml ud)
			end

			list
	  	end

	  	def get_security_group_types(session_id)
	  		resp_doc = widgets_call(
	  			:get_security_group_types,
	  			{
	  				'sessionID' => session_id
  				}).doc

	  		check_body(resp_doc)

			list = Array.new
			resp_doc.xpath('//ReturnValue/SecurityGroupType').each do |sgt|
				list.push(RubyCleverdome::SecurityGroupType.from_xml sgt)
			end

			list
	  	end

	  	def auth_call(api_key, user_id)
				response = @auth_client.call(
						:auth,
						:attributes => { 'xmlns' => 'http://cleverdome.com/apikeys' },
						message: {
								'ApiKey' => api_key,
								'UserID' => user_id
								#'IpAddresses'
						}
				)

	  	end

	  	def check_resp(resp_doc)
	  		status = resp_doc.xpath('//Status//StatusCode')[0]['Value']

	  		if status.casecmp('urn:oasis:names:tc:SAML:2.0:status:Success') != 0
	  			raise status
	  		end
	  	end

	  	def check_body(resp)
	  		resp.remove_namespaces!
	  		status = resp.xpath('//Result')[0].content

	  		if status.casecmp('success') != 0
	  			raise resp.xpath('//Message')[0].content
	  		end
	  	end

		private :auth_call, :check_resp, :check_body, :init_auth_client, :init_widgets_client
	end
end