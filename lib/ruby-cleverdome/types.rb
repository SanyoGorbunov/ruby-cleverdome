module RubyCleverdome
	class SecurityGroup
		def self.from_xml sg
			SecurityGroup.new({
				'id' => sg.at('ID'),
				'name' => sg.at('Name'),
				'read_only' => sg.at('ReadOnly'),
				'type_id' => sg.at('TypeID'),
				'type_name' => sg.at('TypeName')})
		end

		def initialize params = {}
    		params.each { |key, value| send "#{key}=", value }
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
				'id' => ud.at('ID'),
				'full_name' => ud.at('FullName')})
		end

		def initialize params = {}
    		params.each { |key, value| send "#{key}=", value }
		end

		attr_accessor :id, :full_name		
	end

	class SecurityGroupType
		def self.from_xml sgt
			SecurityGroupType.new({
				'id' => sgt.at('ID'),
				'name' => sgt.at('Name')})
		end

		def initialize params = {}
    		params.each { |key, value| send "#{key}=", value }
		end

		attr_accessor :id, :name		
	end

	class MetadataValue
		def self.from_xml dmv
			MetadataValue.new({
				'type_id' => dmv.at('FieldID'),
				'type_name' => dmv.at('FieldName'),
				'value_id' => dmv.at('FieldValueID'),
				'value' => dmv.at('FieldValue')})
		end

		def initialize params = {}
			params.each { |key, value| send "#{key}=", value }
		end

		def inspect
			'{type_id=> %s, type_name=> %s, value_id=> %s, value=> %s}' % [type_id, type_name, value_id, value ]
		end

		attr_accessor :type_id, :type_name, :value_id, :value
		end
end