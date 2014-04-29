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
end