require 'ruby-cleverdome/serialization'

module RubyCleverdome
	class SecurityGroup
		def self.from_xml sg
			SecurityGroup.new({
				'id' => sg.at('ID').content,
				'name' => sg.at('Name').content,
				'read_only' => sg.at('ReadOnly').content,
				'type_id' => sg.at('TypeID').content,
				'type_name' => sg.at('TypeName').content
			})
		end

		def initialize params = {}
    		params.each { |key, value| send "#{key}=", value }
		end

		def inspect
			'{id => %s, name => %s, read_only => %s, type_id => %s, type_name => %s, }' %
					[@id, @name, @read_only, @type_id, @type_name]
		end

		attr_accessor :id, :name, :read_only, :type_id, :type_name
	end

	class PermissionData
		def initialize params = {}
    		params.each { |key, value| send "#{key}=", value }
		end

		attr_accessor :id, :name, :allowed
	end

	class UserData
		def self.from_xml ud
			UserData.new({
				'id' => ud.at('ID').content,
				'full_name' => ud.at('FullName').content})
		end

		def initialize params = {}
    		params.each { |key, value| send "#{key}=", value }
		end

		def inspect
			'{id => %s, full_name => %s}' % [@id, @full_name]
		end

		attr_accessor :id, :full_name		
	end

	class SecurityGroupType
		def self.from_xml sgt
			SecurityGroupType.new({
				'id' => sgt.at('ID').content,
				'name' => sgt.at('Name').content
			})
		end

		def initialize params = {}
    		params.each { |key, value| send "#{key}=", value }
		end

		def inspect
			'{id => %s, name => %s}' % [@id, @name]
		end

		attr_accessor :id, :name		
	end

	class MetadataValue
		def self.from_xml dmv
			MetadataValue.new({
				'type_id' => dmv.at('FieldID').content,
				'type_name' => dmv.at('FieldName').content,
				'value_id' => dmv.at('FieldValueID').content,
				'value' => dmv.at('FieldValue').content
			})
		end

			def initialize params = {}
				params.each { |key, value| send "#{key}=", value }
			end

			def inspect
				'{type_id=> %s, type_name=> %s, value_id=> %s, value=> %s}' % [type_id, type_name, value_id, value ]
			end

			attr_accessor :type_id, :type_name, :value_id, :value
		end


  class ExternalUser
		def initialize params = {}
			params.each { |key, value| send "#{key}=", value }
		end

		attr_accessor :id, :first_name, :last_name, :primary_email, :phone_number

	end


  class UserEmail
		def self.from_xml ue
			portal_xmlns = RubyCleverdome::Serialization.portal_management_schema
			email = UserEmail.new({

				'id' => ue.at('./portal:ID', 'portal'=> portal_xmlns).content,
				'email' => ue.at('./portal:Email', 'portal'=> portal_xmlns).content,
				'active' => ue.at('./portal:Active', 'portal'=> portal_xmlns).content,
				'is_primary' => ue.at('./portal:IsPrimary', 'portal'=> portal_xmlns).content,
			})
		end

		def initialize params = {}
			params.each { |key, value| send "#{key}=", value }
		end

		def inspect
			'{id => %s, email => %s, active => %s, is_primary => %s}' % [@id, @email, @active, @is_primary]
		end

		attr_accessor :active, :email, :id, :is_primary
	end

end