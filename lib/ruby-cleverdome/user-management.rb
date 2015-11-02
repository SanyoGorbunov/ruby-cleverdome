require 'nokogiri'
require 'savon'
require 'uuid'
require 'signed_xml'
require 'mime/types'
require 'ruby-cleverdome/types'

module RubyCleverdome
  class UserManagementClient
    def initialize(config)
      @config = config
      @cert = File.expand_path(@config.cleverDomeCertFile, __FILE__)

      @userManagementClient = Savon.client(
        wsdl: 'http://' + @config.userManagementServicePath + '?wsdl',
        endpoint: 'https://' + @config.userManagementServicePath,
        ssl_ca_cert_file: @cert,
        #ssl_verify_mode: :none,
        #proxy: 'http://127.0.0.1:8888'
      )
    end

    def create_user(external_user)
      response = service_call(:create_user, {
         'apiKey' => @config.apiKey,
         'externalUserID' => external_user.id,
         'firstName' => external_user.first_name,
         'lastName' => external_user.last_name,
         'email' => external_user.primary_email,
         'phone' => external_user.phone_number
       }).to_hash

      response[:create_user_response][:create_user_result]
    end

    def delete_user(external_user_id)
      service_call(:delete_user, {
         'apiKey' => @config.apiKey,
         'externalUserID' => external_user.id
       })
    end

    def get_user_emails(external_user_id)
      resp_doc = service_call(:get_user_emails, {
        'apiKey' => @config.apiKey,
        'externalUserID' => external_user_id
      }).doc

      portal_xmlns = 'http://schemas.datacontract.org/2004/07/PortalManagement'
      list = Array.new
      resp_doc.xpath('//portal:PortalUser.UserEmail', 'portal'=> portal_xmlns).each do |ue|
        list.push(RubyCleverdome::UserEmail.from_xml ue)
      end

      list
    end

    def add_user_email(external_user_id, email, is_primary)
      response = service_call(:add_user_email, {
        'apiKey' => @config.apiKey,
        'externalUserID' => external_user_id,
        'email' => email,
        'isPrimary' => is_primary
      }).to_hash

      response[:add_user_email_response][:add_user_email_result]
    end

    def set_user_primary_email(external_user_id, email_id)
      service_call(:set_user_primary_email, {
        'apiKey' => @config.apiKey,
        'externalUserID' => external_user_id,
        'emailID' => email_id,
      })
    end

    def remove_user_email(external_user_id, email_id)
      service_call(:remove_user_email, {
        'apiKey' => @config.apiKey,
        'externalUserID' => external_user_id,
        'emailID' => email_id,
      })
    end

    def get_cleverdome_user_id(external_user_id)
      response = service_call(:get_clever_dome_user_id, {
         'apiKey' => @config.apiKey,
         'externalUserID' => external_user_id
       }).to_hash

      response[:get_clever_dome_user_id_response][:get_clever_dome_user_id_result]
    end

    def service_call(method, locals)
      @userManagementClient.call(
          method,
          :attributes => { 'xmlns' => 'http://tempuri.org/' },
          message: locals
      )
    end

    private :service_call
  end
end