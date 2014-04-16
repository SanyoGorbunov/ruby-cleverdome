require 'nokogiri'
require 'savon'
require 'uuid'
require 'signed_xml'
require 'mime/types'
require 'ruby-cleverdome/multipart'
require 'base64'

module RubyCleverdome
	class Client
		def initialize(sso_endpoint, widgets_path)
			@widgets_path = widgets_path

			@sso_client = Savon.client(
	  			endpoint: sso_endpoint,
	  			namespace: 'urn:up-us:sso-service:service:v1',
				# proxy: 'http://127.0.0.1:8888',
				# log_level: :debug
	  			)
			@widgets_client = Savon.client(
				wsdl: widgets_path + '?wsdl',
				# proxy: 'http://127.0.0.1:8888',
				element_form_default: :unqualified,
				# log_level: :debug
			)
		end

	  	def auth(provider, uid, private_key_file, certificate_file)
	  		req = create_request(provider, uid)

			req = sign_request(req, private_key_file, certificate_file)

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

	  	def upload_file(session_id, app_id, file_path)
	  		data, headers = Multipart::Post.prepare_query(
	  			"sessionID" 	=> session_id,
	  			"file" 			=> File.open(file_path),
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

		def create_request(provider, uid)
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
						'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema') {
						xml.AuthnRequest(
							'ID' 				=> '_' + UUID.new.generate,
							'Version' 			=> '2.0',
							'IssueInstant' 		=> Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
							'IsPassive'			=> false,
							'ProtocolBinding' 	=> 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP',
							'ProviderName'		=> provider,
							:xmlns 				=> 'urn:oasis:names:tc:SAML:2.0:protocol') {
							xml.Issuer(
								@provider,
								'Format'	=> 'urn:oasis:names:tc:SAML:2.0:nameidformat:transient',
								:xmlns 		=> 'urn:oasis:names:tc:SAML:2.0:assertion')
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
							xml.Subject( :xmlns => 'urn:oasis:names:tc:SAML:2.0:assertion' ) {
								xml.NameID(
									uid,
									'Format'=>'urn:oasis:names:tc:SAML:2.0:nameid-format:transient')
							}
							xml.NameIDPolicy( 'AllowCreate' => true )
						}
					}
				}
			end

			builder.to_xml
		end

		def sign_request(xml, private_key_file, certificate_file)
			doc = SignedXml::Document(xml)
			private_key = OpenSSL::PKey::RSA.new(File.new private_key_file)
			certificate = OpenSSL::X509::Certificate.new(File.read certificate_file)
			doc.sign(private_key, certificate)
			doc.to_xml
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