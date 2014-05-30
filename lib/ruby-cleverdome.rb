require 'nokogiri'
require 'savon'
require 'uuid'
require 'signed_xml'
require 'mime/types'
require 'ruby-cleverdome/multipart'
require 'ruby-cleverdome/types'
require 'base64'

module RubyCleverdome
	class Client
		def initialize(sso_endpoint, widgets_path)
			@widgets_path = widgets_path

			@sso_client = Savon.client(
	  			endpoint: sso_endpoint,
	  			namespace: 'urn:up-us:sso-service:service:v1',
				# proxy: 'http://127.0.0.1:8888',
				# logger: Rails.logger
				# log_level: :debug
	  			)
			@widgets_client = Savon.client(
				wsdl: widgets_path + '?wsdl',
				#proxy: 'http://127.0.0.1:8888',
				element_form_default: :unqualified,
				# logger: Rails.logger
				# log_level: :debug
			)
		end

	  	def auth(provider, uid, private_key_file, certificate_file)
	  		req = create_request(provider, uid)

			req = sign_request(req, private_key_file, certificate_file)

			req = place_to_envelope(req)

			resp = saml_call(req)
			resp_doc = Nokogiri::XML::Document.parse(resp)
	  		resp_doc.remove_namespaces!
			check_resp(resp_doc)

			session_id = resp_doc.xpath('//Assertion//AttributeStatement//Attribute[@Name="SessionID"]//AttributeValue')[0].content
			session_id
	  	end

		def widgets_call(method, locals)
	  		response = @widgets_client.call(
				method,
				:attributes => { 'xmlns' => 'http://tempuri.org/' }, 
				message: locals
				)
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

	  	def get_security_groups(session_id, doc_guid)
	  		resp_doc = widgets_call(
	  			:get_security_groups,
	  			{
	  				'sessionID' => session_id,
	  				'documentGuid' => doc_guid
  				}).doc

	  		check_body(resp_doc)

			list = Array.new
			resp_doc.xpath('//ReturnValue/SecurityGroup').each do |sg|
				list.push(RubyCleverdome::SecurityGroup.from_xml sg)
			end

			list
	  	end

	  	def get_group_permissions(session_id, doc_guid, group_id)
	  		resp_doc = widgets_call(
	  			:get_group_permissions,
	  			{
	  				'sessionID' => session_id,
	  				'documentGuid' => doc_guid,
	  				'groupID' => group_id
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

	  	def append_security_group(session_id, doc_guid, group_id)
	  		resp_doc = widgets_call(
	  			:append_security_group_to_document,
	  			{
	  				'sessionID' => session_id,
	  				'documentGuid' => doc_guid,
	  				'groupID' => group_id
  				}).doc

	  		check_body(resp_doc)	  		
	  	end

	  	def remove_security_group(session_id, doc_guid, group_id)
	  		resp_doc = widgets_call(
	  			:remove_security_group_from_document,
	  			{
	  				'sessionID' => session_id,
	  				'documentGuid' => doc_guid,
	  				'securityGroupID' => group_id
  				}).doc

	  		check_body(resp_doc)	  		
	  	end

	  	def set_security_group_permission(session_id, doc_guid, group_id, permission_id, permission_value)
			resp_doc = widgets_call(
	  			:set_permission_for_group,
	  			{
	  				'sessionID' => session_id,
	  				'documentGuid' => doc_guid,
	  				'groupID' => group_id,
	  				'permissionID' => permission_id,
	  				'permissionValue' => permission_value
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

	  	def create_security_group(session_id, name, desc, type_id, owner_id)
	  		resp_doc = widgets_call(
	  			:create_security_group,
	  			{
	  				'sessionID' => session_id,
	  				'name' => name,
	  				'description' => desc,
	  				'type' => type_id,
	  				'ownerID' => owner_id
  				}).doc

	  		check_body(resp_doc)

	  		RubyCleverdome::SecurityGroup.from_xml resp_doc.xpath('//ReturnValue/SecurityGroup')  		
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

		def create_request(provider, uid)
			builder = Nokogiri::XML::Builder.new do |xml|
				xml['samlp'].AuthnRequest(
					'ID' 				=> '_' + UUID.new.generate,
					'Version' 			=> '2.0',
					'IssueInstant' 		=> Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
					'IsPassive'			=> false,
					'ProtocolBinding' 	=> 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP',
					'ProviderName'		=> provider,
					'xmlns:saml'		=> 'urn:oasis:names:tc:SAML:2.0:assertion',
					'xmlns:xenc'		=> 'http://www.w3.org/2001/04/xmlenc#',
					'xmlns:samlp'		=> 'urn:oasis:names:tc:SAML:2.0:protocol') {
					xml['saml'].Issuer(
						provider,
						'Format'	=> 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient')
					xml.Signature(:xmlns => 'http://www.w3.org/2000/09/xmldsig#') {
						xml.SignedInfo {
							xml.CanonicalizationMethod( 'Algorithm' => 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315' ) { xml.text '' }
							xml.SignatureMethod( 'Algorithm' => 'http://www.w3.org/2000/09/xmldsig#rsa-sha1' ) { xml.text '' }
							xml.Reference( 'URI' => '' ) {
								xml.Transforms {
									xml.Transform( 'Algorithm' => 'http://www.w3.org/2000/09/xmldsig#enveloped-signature' ) { xml.text '' }
									xml.Transform( 'Algorithm' => 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315' ) { xml.text '' }
								}
								xml.DigestMethod( 'Algorithm' => 'http://www.w3.org/2000/09/xmldsig#sha1' ) { xml.text '' }
								xml.DigestValue
							}
						}
						xml.SignatureValue
						xml.KeyInfo {
							xml.X509Data {
								xml.X509Certificate
							}
						}
					}
					xml['saml'].Subject {
						xml['saml'].NameID(
							uid,
							'Format'=>'urn:oasis:names:tc:SAML:2.0:nameid-format:transient')
					}
					xml['samlp'].NameIDPolicy( 'AllowCreate' => true )
				}
			end

			builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
		end

		def sign_request(xml, private_key_file, certificate_file)
			doc = SignedXml::Document(xml)
			private_key = OpenSSL::PKey::RSA.new(File.new private_key_file)
			certificate = OpenSSL::X509::Certificate.new(File.read certificate_file)
			doc.sign(private_key, certificate)
			doc.to_xml
		end

		def place_to_envelope(xml)
			authn_req_node = Nokogiri::XML(xml).root

			builder = Nokogiri::XML::Builder.new do |xml|
				xml['s'].Envelope('xmlns:s' => 'http://schemas.xmlsoap.org/soap/envelope/') {
					xml['s'].Header {
						xml.ActivityId(
							UUID.new.generate, 
							'CorrelationId' => UUID.new.generate,
							:xmlns 			=> 'http://schemas.microsoft.com/2004/09/ServiceModel/Diagnostics')
					}
					xml['s'].Body(
						'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
						'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema')
				}
			end

			req_doc = builder.doc
			body = req_doc.xpath('//s:Body', 's' => 'http://schemas.xmlsoap.org/soap/envelope/')[0]
			body.add_child authn_req_node

			req_doc.to_xml
		end

	  	def saml_call(req)
	  		@sso_client.call( 'GetSSO', soap_action: 'urn:up-us:sso-service:service:v1/ISSOService/GetSSO', xml: req ).to_xml
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

		private :create_request, :sign_request, :saml_call, :check_resp, :check_body
	end
end