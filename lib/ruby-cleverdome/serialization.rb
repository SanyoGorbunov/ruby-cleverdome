module RubyCleverdome
  class Serialization
    def self.array_schema
      'http://schemas.microsoft.com/2003/10/Serialization/Arrays'
    end

    def self.portal_management_schema
      'http://schemas.datacontract.org/2004/07/PortalManagement'
    end

    def self.widgets_namespace
      'http://tempuri.org/'
    end

    def self.auth_namespace
      'http://cleverdome.com/apikeys'
    end

    def self.user_management_namespace
      'http://tempuri.org/'
    end

    def self.format_request_array(array, xml_tag)
      result = Array.new
      array.each do |item|
        result.push({xml_tag => item })
      end

      result
    end
  end
end